import Foundation

/// Offline spell check: exact lookup, correction map, digraph fold, then edit-distance ≤ 2.
///
/// The length / fold indexes are built on first use (or by `prewarm()` in the background),
/// not at lexicon load. Word ids are already frequency-sorted, so buckets need no sorting.
public final class SpellChecker {
    private let trie: PrefixTrie
    private let words: WordTable
    private let bin: LexiconBinary

    private let indexLock = NSLock()
    private var indexesBuilt = false
    private var byLength: [Int: [UInt32]] = [:]
    /// (hash of folded scalars, word id) sorted by hash then id. Hits are re-verified,
    /// so hash collisions are harmless; ids within a hash stay frequency-ordered.
    private var foldHashes: [Int] = []
    private var foldIds: [UInt32] = []

    init(trie: PrefixTrie, binary: LexiconBinary) {
        self.trie = trie
        self.words = trie.words
        self.bin = binary
    }

    /// Build lookup indexes now (safe to call from any queue).
    public func prewarm() {
        ensureIndexes()
    }

    public func isCorrect(_ word: String) -> Bool {
        trie.contains(word)
    }

    public func suggestions(for word: String, limit: Int = 6) -> [String] {
        let key = ULYNormalizer.lookupKey(word)
        if key.isEmpty { return [] }
        if trie.contains(key) { return [key] }

        // Short tokens: correction map only (edit-distance over 120k words is too slow for IME).
        if key.count < 3 {
            if let mapped = bin.correction(for: key) { return [mapped] }
            return []
        }

        var ranked: [(String, Int)] = []
        var seen = Set<String>()

        func consider(_ cand: String, _ score: Int) {
            let c = ULYNormalizer.lookupKey(cand)
            guard seen.insert(c).inserted else { return }
            ranked.append((c, score))
        }

        if let mapped = bin.correction(for: key) {
            consider(mapped, 1_000_000 + trie.frequency(of: mapped))
        }
        for rewritten in Self.rewriteVariants(key) {
            if let mapped = bin.correction(for: rewritten) {
                consider(mapped, 900_000 + trie.frequency(of: mapped))
            }
            if trie.contains(rewritten) {
                consider(rewritten, 850_000 + trie.frequency(of: rewritten))
            }
        }
        if ranked.count >= limit {
            return Array(ranked.sorted { $0.1 > $1.1 }.prefix(limit).map(\.0))
        }

        ensureIndexes()

        // Digraph / confusable fold: yahximu ↔ yaxshimu
        let folded = Self.foldScalars(key)
        let hash = Self.hashKey(folded)
        var lo = 0
        var hi = foldHashes.count
        while lo < hi {
            let mid = (lo + hi) / 2
            if foldHashes[mid] < hash { lo = mid + 1 } else { hi = mid }
        }
        var taken = 0
        while lo < foldHashes.count, foldHashes[lo] == hash, taken < 12, ranked.count < limit * 2 {
            let id = Int(foldIds[lo])
            lo += 1
            let cand = words.word(at: id)
            guard Self.foldScalars(cand) == folded else { continue }
            consider(cand, words.frequency(at: id) + 100_000)
            taken += 1
        }

        let keyScalars = key.unicodeScalars.map(\.value)
        let len = keyScalars.count
        let first = keyScalars.first
        let cap = len <= 4 ? 600 : 1200
        var scanned = 0
        for L in max(1, len - 2)...(len + 2) {
            guard let bucket = byLength[L] else { continue }
            for id in bucket {
                if scanned >= cap { break }
                let cand = words.word(at: Int(id))
                let candScalars = cand.unicodeScalars.map(\.value)
                if let first, candScalars.first != first, abs(candScalars.count - len) > 1 {
                    continue
                }
                scanned += 1
                if seen.contains(cand) { continue }
                let d = Self.editDistance(keyScalars, candScalars, max: 2)
                if d < 0 { continue }
                consider(cand, words.frequency(at: Int(id)) - d * 50_000)
                if ranked.count >= limit * 4 { break }
            }
            if scanned >= cap || ranked.count >= limit * 4 { break }
        }

        if ranked.count < limit {
            let target = keyScalars.map(Self.foldDiacritic)
            var checked = 0
            for id in byLength[len] ?? [] {
                checked += 1
                if checked > 4000 { break }
                let cand = words.word(at: Int(id))
                if seen.contains(cand) { continue }
                if cand.unicodeScalars.map({ Self.foldDiacritic($0.value) }) == target {
                    consider(cand, words.frequency(at: Int(id)) + 10_000)
                    if ranked.count >= limit { break }
                }
            }
        }

        ranked.sort { $0.1 > $1.1 }
        return Array(ranked.prefix(limit).map(\.0))
    }

    private func ensureIndexes() {
        indexLock.lock()
        defer { indexLock.unlock() }
        guard !indexesBuilt else { return }
        var lengths: [Int: [UInt32]] = [:]
        var pairs: [(Int, UInt32)] = []
        pairs.reserveCapacity(words.count)
        for id in 0..<words.count {
            let w = words.word(at: id)
            lengths[w.unicodeScalars.count, default: []].append(UInt32(id))
            pairs.append((Self.hashKey(Self.foldScalars(w)), UInt32(id)))
        }
        pairs.sort { $0.0 != $1.0 ? $0.0 < $1.0 : $0.1 < $1.1 }
        byLength = lengths
        foldHashes = pairs.map(\.0)
        foldIds = pairs.map(\.1)
        indexesBuilt = true
    }

    // MARK: - Folding

    private static func scalars(_ s: String) -> [UInt32] { s.unicodeScalars.map(\.value) }

    private static let informalRewrites: [([UInt32], [UInt32])] = [
        (scalars("yahx"), scalars("yaxsh")),
        (scalars("yahsh"), scalars("yaxsh")),
        (scalars("ahx"), scalars("axsh")),
    ]
    private static let digraphToken: [UInt32] = [0x203B] // ※
    private static let digraphs: [[UInt32]] = ["xsh", "gh", "zh", "ch", "ng", "sh", "xh"].map(scalars)

    /// Collapse ULY digraphs so informal Latin (yahxi) matches standard (yaxshi).
    public static func foldConfusable(_ s: String) -> String {
        var view = String.UnicodeScalarView()
        for v in foldScalars(s) {
            if let u = Unicode.Scalar(v) { view.append(u) }
        }
        return String(view)
    }

    static func foldScalars(_ s: String) -> [UInt32] {
        var a = s.unicodeScalars.map { foldDiacritic($0.value) }
        for (wrong, right) in informalRewrites { replaceAll(&a, wrong, right) }
        for d in digraphs { replaceAll(&a, d, digraphToken) }
        return a
    }

    /// Left-to-right, non-overlapping replacement (same semantics as `replacingOccurrences`).
    private static func replaceAll(_ a: inout [UInt32], _ pattern: [UInt32], _ replacement: [UInt32]) {
        let p = pattern.count
        guard a.count >= p, let head = pattern.first, a.contains(head) else { return }
        var out: [UInt32] = []
        out.reserveCapacity(a.count + 2)
        var i = 0
        var changed = false
        while i < a.count {
            if a[i] == head, i + p <= a.count, a[i..<(i + p)].elementsEqual(pattern) {
                out.append(contentsOf: replacement)
                i += p
                changed = true
            } else {
                out.append(a[i])
                i += 1
            }
        }
        if changed { a = out }
    }

    @inline(__always)
    private static func foldDiacritic(_ v: UInt32) -> UInt32 {
        switch v {
        case 0xF6: return 0x6F // ö → o
        case 0xFC: return 0x75 // ü → u
        case 0xEB, 0xE9: return 0x65 // ë, é → e
        default: return v
        }
    }

    private static func hashKey(_ a: [UInt32]) -> Int {
        var h = Hasher()
        h.combine(a)
        return h.finalize()
    }

    /// Lightweight rewrite rules for common informal Latin spellings.
    static func rewriteVariants(_ key: String) -> [String] {
        var out: [String] = []
        let rules: [(String, String)] = [
            ("yahx", "yaxsh"),
            ("yahsh", "yaxsh"),
            ("ahx", "axsh"),
            ("xh", "xsh"),
        ]
        for (wrong, right) in rules {
            if key.contains(wrong) {
                out.append(key.replacingOccurrences(of: wrong, with: right))
            }
        }
        return out
    }

    /// Returns distance or -1 if > max.
    private static func editDistance(_ a: [UInt32], _ b: [UInt32], max: Int) -> Int {
        let n = a.count
        let m = b.count
        if abs(n - m) > max { return -1 }
        if n == 0 { return m }
        if m == 0 { return n }

        var prev = Array(0...m)
        var cur = Array(repeating: 0, count: m + 1)
        for i in 1...n {
            cur[0] = i
            var rowMin = cur[0]
            for j in 1...m {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                cur[j] = min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost)
                rowMin = min(rowMin, cur[j])
            }
            if rowMin > max { return -1 }
            swap(&prev, &cur)
        }
        let d = prev[m]
        return d > max ? -1 : d
    }
}
