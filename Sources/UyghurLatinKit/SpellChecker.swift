import Foundation

/// Offline spell check: exact lookup, correction map, then edit-distance ≤ 2.
public final class SpellChecker {
    private let trie: PrefixTrie
    private var corrections: [String: String]
    private var vocabulary: [String]
    private var byLength: [Int: [String]] = [:]

    public init(trie: PrefixTrie, vocabulary: [String], corrections: [String: String]) {
        self.trie = trie
        self.vocabulary = vocabulary
        self.corrections = corrections
        var buckets: [Int: [String]] = [:]
        for w in vocabulary {
            buckets[w.count, default: []].append(w)
        }
        for (len, list) in buckets {
            byLength[len] = list.sorted { trie.frequency(of: $0) > trie.frequency(of: $1) }
        }
    }

    public func isCorrect(_ word: String) -> Bool {
        trie.contains(word)
    }

    public func suggestions(for word: String, limit: Int = 6) -> [String] {
        let key = ULYNormalizer.lookupKey(word)
        if key.isEmpty { return [] }
        if trie.contains(key) { return [key] }

        var ranked: [(String, Int)] = []
        var seen = Set<String>()

        if let mapped = corrections[key], !seen.contains(mapped) {
            seen.insert(mapped)
            ranked.append((mapped, 1_000_000 + trie.frequency(of: mapped)))
        }

        let len = key.count
        let candidates = Array(
            (max(1, len - 2)...(len + 2))
                .flatMap { byLength[$0] ?? [] }
                .prefix(3500)
        )
        for cand in candidates {
            if seen.contains(cand) { continue }
            let d = editDistance(key, cand, max: 2)
            if d < 0 || d > 2 { continue }
            seen.insert(cand)
            let score = trie.frequency(of: cand) - d * 50_000
            ranked.append((cand, score))
        }

        // Diacritic-insensitive near matches (o/ö, u/ü, e/ë) — same-length only
        if ranked.count < limit {
            let folded = foldDiacritics(key)
            for cand in byLength[key.count] ?? [] {
                if seen.contains(cand) { continue }
                if foldDiacritics(cand) == folded {
                    seen.insert(cand)
                    ranked.append((cand, trie.frequency(of: cand) + 10_000))
                }
            }
        }

        ranked.sort { $0.1 > $1.1 }
        return Array(ranked.prefix(limit).map(\.0))
    }

    private func foldDiacritics(_ s: String) -> String {
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
            prev = cur
        }
        let d = prev[m]
        return d > max ? -1 : d
    }
}
