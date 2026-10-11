import Foundation

/// Offline spell check: exact lookup, correction map, digraph fold, then edit-distance ≤ 2.
public final class SpellChecker {
    private let trie: PrefixTrie
    private var corrections: [String: String]
    private var byLength: [Int: [String]] = [:]
    private var byFolded: [String: [String]] = [:]

    public init(trie: PrefixTrie, vocabulary: [String], corrections: [String: String]) {
        self.trie = trie
        self.corrections = corrections
        var buckets: [Int: [String]] = [:]
        var folded: [String: [String]] = [:]
        for w in vocabulary {
            buckets[w.count, default: []].append(w)
            let f = Self.foldConfusable(w)
            folded[f, default: []].append(w)
        }
        for (len, list) in buckets {
            // Pre-sorted once at load — hot path must not re-sort.
            byLength[len] = list.sorted { trie.frequency(of: $0) > trie.frequency(of: $1) }
        }
        for (key, list) in folded {
            byFolded[key] = list.sorted { trie.frequency(of: $0) > trie.frequency(of: $1) }
        }
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
            if let mapped = corrections[key] { return [mapped] }
            return []
        }

        var ranked: [(String, Int)] = []
        var seen = Set<String>()

        func consider(_ cand: String, _ score: Int) {
            let c = ULYNormalizer.lookupKey(cand)
            guard seen.insert(c).inserted else { return }
            ranked.append((c, score))
        }

        if let mapped = corrections[key] {
            consider(mapped, 1_000_000 + trie.frequency(of: mapped))
        }
        for rewritten in Self.rewriteVariants(key) {
            if let mapped = corrections[rewritten] {
                consider(mapped, 900_000 + trie.frequency(of: mapped))
            }
            if trie.contains(rewritten) {
                consider(rewritten, 850_000 + trie.frequency(of: rewritten))
            }
        }
        if ranked.count >= limit {
            return Array(ranked.sorted { $0.1 > $1.1 }.prefix(limit).map(\.0))
        }

        // Digraph / confusable fold: yahximu ↔ yaxshimu
        let foldedKey = Self.foldConfusable(key)
        if let list = byFolded[foldedKey] {
            for cand in list.prefix(12) {
                consider(cand, trie.frequency(of: cand) + 100_000)
                if ranked.count >= limit * 2 { break }
            }
        }

        let first = key.first
        let cap = key.count <= 4 ? 600 : 1200
        var scanned = 0
        let len = key.count
        for L in max(1, len - 2)...(len + 2) {
            guard let bucket = byLength[L] else { continue }
            for cand in bucket {
                if scanned >= cap { break }
                if let first, cand.first != first, abs(cand.count - len) > 1 {
                    continue
                }
                scanned += 1
                if seen.contains(cand) { continue }
                let d = editDistance(key, cand, max: 2)
                if d < 0 || d > 2 { continue }
                consider(cand, trie.frequency(of: cand) - d * 50_000)
                if ranked.count >= limit * 4 { break }
            }
            if scanned >= cap || ranked.count >= limit * 4 { break }
        }

        if ranked.count < limit {
            let folded = foldDiacritics(key)
            for cand in byLength[key.count] ?? [] {
                if seen.contains(cand) { continue }
                if foldDiacritics(cand) == folded {
                    consider(cand, trie.frequency(of: cand) + 10_000)
                    if ranked.count >= limit { break }
                }
            }
        }

        ranked.sort { $0.1 > $1.1 }
        return Array(ranked.prefix(limit).map(\.0))
    }

    /// Collapse ULY digraphs so informal Latin (yahxi) matches standard (yaxshi).
    public static func foldConfusable(_ s: String) -> String {
        var out = foldDiacriticsStatic(s)
        // Informal → standard digraphs before collapsing tokens.
        out = out.replacingOccurrences(of: "yahx", with: "yaxsh")
        out = out.replacingOccurrences(of: "yahsh", with: "yaxsh")
        out = out.replacingOccurrences(of: "ahx", with: "axsh")
        let replacements = [
            ("xsh", "※"),
            ("gh", "※"),
            ("zh", "※"),
            ("ch", "※"),
            ("ng", "※"),
            ("sh", "※"),
            ("xh", "※"),
        ]
        for (digraph, token) in replacements {
            out = out.replacingOccurrences(of: digraph, with: token)
        }
        return out
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

    private func foldDiacritics(_ s: String) -> String {
        Self.foldDiacriticsStatic(s)
    }

    private static func foldDiacriticsStatic(_ s: String) -> String {
        s
            .replacingOccurrences(of: "ö", with: "o")
            .replacingOccurrences(of: "ü", with: "u")
            .replacingOccurrences(of: "ë", with: "e")
            .replacingOccurrences(of: "é", with: "e")
    }

    /// Returns distance or -1 if > max.
    private func editDistance(_ a: String, _ b: String, max: Int) -> Int {
        let aChars = Array(a)
        let bChars = Array(b)
        let n = aChars.count
        let m = bChars.count
        if abs(n - m) > max { return -1 }
        if n == 0 { return m }
        if m == 0 { return n }

        var prev = Array(0...m)
        var cur = Array(repeating: 0, count: m + 1)
        for i in 1...n {
            cur[0] = i
            var rowMin = cur[0]
            for j in 1...m {
                let cost = aChars[i - 1] == bChars[j - 1] ? 0 : 1
                cur[j] = min(
                    prev[j] + 1,
                    cur[j - 1] + 1,
                    prev[j - 1] + cost
                )
                rowMin = min(rowMin, cur[j])
            }
            if rowMin > max { return -1 }
            swap(&prev, &cur)
        }
        let d = prev[m]
        return d > max ? -1 : d
    }
}
