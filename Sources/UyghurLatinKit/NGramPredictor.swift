import Foundation

/// Bigram → sentence-start / curated fallback next-word prediction.
///
/// Empty context used to fall back to raw lexicon unigram tops (`aq`, `qara`, …),
/// which are dictionary headwords — not natural sentence openers. This predictor
/// uses a curated starter list + light rotation instead.
public final class NGramPredictor {
    private let bin: LexiconBinary
    private let trie: PrefixTrie
    private var starters: [(String, Int)] = []
    /// Recently suggested next-words (for light diversity across opens).
    private var recentRing: [String] = []
    private let recentCap = 24

    /// Natural ULY openers / high-utility next words (not imla color lemmas).
    public static let defaultSentenceStarters: [String] = SuggestionScenario.general.bundledStarters

    init(
        binary: LexiconBinary,
        trie: PrefixTrie,
        sentenceStarters: [String] = NGramPredictor.defaultSentenceStarters
    ) {
        self.bin = binary
        self.trie = trie
        updateStarters(sentenceStarters)
    }

    /// Replace the active starter list (scenario / custom pins from host app).
    public func updateStarters(_ sentenceStarters: [String]) {
        starters = sentenceStarters.enumerated().compactMap { idx, raw in
            let w = ULYNormalizer.lookupKey(raw)
            guard !w.isEmpty else { return nil }
            let lex = trie.frequency(of: w)
            return (w, 1_000_000 - idx * 1_000 + min(lex, 50_000))
        }
    }

    /// - Parameters:
    ///   - previous: last committed word, if any
    ///   - sentenceStart: true after empty field / sentence punctuation
    ///   - limit: max candidates
    public func nextWords(
        after previous: String?,
        sentenceStart: Bool = false,
        limit: Int = 6
    ) -> [String] {
        var ranked: [(String, Int)] = []

        if sentenceStart || previous == nil || previous?.isEmpty == true {
            ranked.append(contentsOf: starters)
        } else if let prev = previous {
            let key = ULYNormalizer.lookupKey(prev)
            ranked.append(contentsOf: bin.bigrams(after: key).map { ($0.0, $0.1 + 200_000) })
            // Soft back-off: a few starters so prediction never feels stuck.
            if ranked.count < limit {
                ranked.append(contentsOf: starters.prefix(limit).map { ($0.0, $0.1 / 20) })
            }
        }

        // Avoid dumping raw unigram headwords (`aq`/`qara`) unless we have nothing.
        if ranked.isEmpty {
            ranked = usefulUnigramFallback(limit: limit * 3)
        }

        ranked = applyDiversityPenalty(ranked)
        ranked.sort { lhs, rhs in
            if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
            return lhs.0 < rhs.0
        }

        var out: [String] = []
        var seen = Set<String>()
        for (w, _) in ranked {
            let k = ULYNormalizer.lookupKey(w)
            if seen.insert(k).inserted {
                out.append(k)
            }
            if out.count >= limit { break }
        }
        remember(out)
        return out
    }

    /// Words that are fine as cold-start fillers (pronouns / connectors), not color lemmas.
    private func usefulUnigramFallback(limit: Int) -> [(String, Int)] {
        let allow: Set<String> = [
            "men", "sen", "siz", "biz", "ular", "bu", "u", "shu", "bir",
            "we", "emma", "lekin", "hem", "yene", "bolidu", "bar", "yoq",
        ]
        var hits: [(String, Int)] = allow.compactMap { w in
            let f = trie.frequency(of: w)
            return f > 0 ? (w, f) : nil
        }
        hits.sort { $0.1 > $1.1 }
        if hits.count < limit {
            // Last resort: mid-frequency content words, skip the ultra-head of the list
            // (word ids are frequency-sorted).
            let words = trie.words
            var id = 80
            while id < words.count, hits.count < limit {
                let w = words.word(at: id)
                if w.count >= 3 {
                    hits.append((w, words.frequency(at: id) / 100))
                }
                id += 1
            }
        }
        return Array(hits.prefix(limit))
    }

    private func applyDiversityPenalty(_ ranked: [(String, Int)]) -> [(String, Int)] {
        guard !recentRing.isEmpty else { return ranked }
        var recentScore: [String: Int] = [:]
        for (i, w) in recentRing.enumerated() {
            // Older entries in the ring get smaller penalty.
            recentScore[w, default: 0] += (i + 1) * 3_000
        }
        return ranked.map { w, score in
            (w, score - (recentScore[w] ?? 0))
        }
    }

    private func remember(_ words: [String]) {
        for w in words.reversed() {
            recentRing.removeAll { $0 == w }
            recentRing.append(w)
        }
        if recentRing.count > recentCap {
            recentRing.removeFirst(recentRing.count - recentCap)
        }
    }
}
