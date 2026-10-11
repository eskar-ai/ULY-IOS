import Foundation

/// Productive ULY clitic / suffix expansion for IME suggestions.
/// Generates completions and polite/related alternates from a known stem.
public final class MorphologyExpander {
    private let trie: PrefixTrie

    /// Longest-first productive endings (attached to adjective / verb stems).
    private static let suffixes: [String] = [
        "turdigizmu", "turdingizmu", "turdingiz", "turdigiz", "turding",
        "turdum", "turduq", "turdi", "turdu", "tur",
        "digizmu", "dingizmu", "dingiz", "digiz", "gizmu", "izmu",
        "watimen", "watisen", "watisiz", "watidu", "watimiz", "watidilar",
        "uwatimen", "uwatidu", "iwatimen", "iwatidu",
        "ding", "dum", "duq", "di", "du",
        "musiler", "musiz", "misiz", "musen",
        "siler", "siz", "sen", "men", "miz",
        "imen", "isen", "isiz", "idu", "imiz", "idilar",
        "ayli", "eyli", "ay", "ey", "ingiz", "ing", "sun",
        "lar", "ler", "ning", "ni", "gha", "qa", "da", "de", "din", "tin",
        "mu", "chu", "ghu", "ken", "im",
    ]

    /// Suffix families: when the typed remainder matches one member, suggest siblings.
    private static let families: [[String]] = [
        ["mu", "musiz", "misiz", "musen", "musiler"],
        ["siz", "sen", "men", "siler", "miz"],
        ["ding", "dingiz", "dingizmu", "digizmu", "digiz", "gizmu", "izmu"],
        ["di", "du", "dum", "duq", "ding", "dingiz"],
        ["turding", "turdingiz", "turdingizmu", "turdigizmu", "turdigiz", "turdi", "turdu", "turdum", "turduq"],
        ["tur", "turdi", "turdu", "turding", "turdum"],
        ["watimen", "watisen", "watisiz", "watidu", "watimiz", "watidilar"],
        ["imen", "isen", "isiz", "idu", "imiz", "idilar"],
        ["ay", "ey", "ayli", "eyli", "ing", "ingiz", "sun"],
        ["lar", "ler", "ning", "ni", "gha", "qa", "da", "de", "din", "tin"],
        ["chu", "ghu", "ken", "mu"],
    ]

    private static let minStemLength = 3

    public init(trie: PrefixTrie) {
        self.trie = trie
    }

    /// Returns frequency-ranked morphological candidates that continue or relate to `partial`.
    public func expansions(for partial: String, limit: Int) -> [(String, Int)] {
        guard limit > 0 else { return [] }
        let key = ULYNormalizer.lookupKey(partial)
        guard key.count >= Self.minStemLength else { return [] }

        var ranked: [(String, Int)] = []
        var seen = Set<String>()

        func consider(_ word: String, _ score: Int) {
            let w = ULYNormalizer.lookupKey(word)
            guard w != key else { return }
            guard w.hasPrefix(key) || isRelatedAlternate(typed: key, candidate: w) else { return }
            guard seen.insert(w).inserted else { return }
            ranked.append((w, score))
        }

        let chars = Array(key)
        var stemEnd = chars.count
        var stemsFound = 0
        while stemEnd >= Self.minStemLength, stemsFound < 4 {
            let stem = String(chars[..<stemEnd])
            if trie.contains(stem) {
                stemsFound += 1
                let stemFreq = max(1, trie.frequency(of: stem))
                let rem = String(chars[stemEnd...])
                expand(stem: stem, remainder: rem, stemFreq: stemFreq, consider: consider)
            }
            stemEnd -= 1
        }

        if stemsFound == 0 {
            stemEnd = chars.count - 1
            while stemEnd >= Self.minStemLength {
                let stem = String(chars[..<stemEnd])
                if trie.contains(stem) {
                    let stemFreq = max(1, trie.frequency(of: stem))
                    expand(stem: stem, remainder: String(chars[stemEnd...]), stemFreq: stemFreq, consider: consider)
                    break
                }
                stemEnd -= 1
            }
        }

        ranked.sort { lhs, rhs in
            if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
            return lhs.0.count < rhs.0.count
        }
        return Array(ranked.prefix(limit))
    }

    private func expand(
        stem: String,
        remainder: String,
        stemFreq: Int,
        consider: (String, Int) -> Void
    ) {
        for suffix in Self.suffixes {
            let form = stem + suffix
            if remainder.isEmpty {
                let score = stemFreq / 4 - suffix.count * 10
                consider(form, score)
                continue
            }
            if suffix.hasPrefix(remainder) {
                let score = stemFreq / 2 - (suffix.count - remainder.count) * 5
                consider(form, score)
            }
        }

        if !remainder.isEmpty {
            for family in Self.families {
                let matched = family.contains { $0 == remainder || $0.hasPrefix(remainder) || remainder.hasPrefix($0) }
                guard matched else { continue }
                for alt in family {
                    guard alt != remainder else { continue }
                    let form = stem + alt
                    let boost = family.contains(remainder) ? 200 : 0
                    let score = stemFreq / 3 - abs(alt.count - remainder.count) * 8 + boost
                    consider(form, score)
                }
            }
        }
    }

    private func isRelatedAlternate(typed: String, candidate: String) -> Bool {
        guard !candidate.hasPrefix(typed) else { return true }
        let chars = Array(typed)
        var stemEnd = chars.count
        while stemEnd >= Self.minStemLength {
            let stem = String(chars[..<stemEnd])
            if candidate.hasPrefix(stem), trie.contains(stem) {
                let typedRem = String(chars[stemEnd...])
                let candRem = String(candidate.dropFirst(stem.count))
                for family in Self.families {
                    if family.contains(typedRem), family.contains(candRem) {
                        return true
                    }
                }
            }
            stemEnd -= 1
        }
        return false
    }
}
