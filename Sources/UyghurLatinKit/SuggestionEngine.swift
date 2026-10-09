import Foundation

public struct SuggestionResult: Sendable {
    public let candidates: [String]
    /// true when current partial/word looks misspelled
    public let isMisspelled: Bool
    public let mode: Mode

    public enum Mode: String, Sendable {
        case completion
        case nextWord
        case correction
        case empty
    }
}

/// Orchestrates personal words → completion → correction → next-word prediction.
public final class SuggestionEngine {
    private let store: LexiconStore
    private let personal: PersonalDictionary

    public init(store: LexiconStore, personal: PersonalDictionary = PersonalDictionary()) {
        self.store = store
        self.personal = personal
    }

    public var lexiconMeta: LexiconMeta { store.meta }

    /// - Parameters:
    ///   - partial: characters of the word currently being typed (may be empty after space)
    ///   - previousWord: last committed word for bigram prediction
    public func suggest(partial: String, previousWord: String?, limit: Int = 3) -> SuggestionResult {
        let p = ULYNormalizer.lookupKey(partial)

        if p.isEmpty {
            let next = store.predictor.nextWords(after: previousWord, limit: limit)
            return SuggestionResult(candidates: next, isMisspelled: false, mode: next.isEmpty ? .empty : .nextWord)
        }

        // Personal + lexicon completions
        var comps = personal.rankedPrefix(p, limit: limit)
        comps.append(contentsOf: store.trie.completions(prefix: p, limit: limit * 3))
        comps.sort { $0.1 > $1.1 }
        var words = uniquePreserveOrder(comps.map(\.0), limit: limit)

        if !words.isEmpty {
            let exact = store.trie.contains(p) || personal.contains(p)
            return SuggestionResult(candidates: words, isMisspelled: !exact && p.count > 2, mode: .completion)
        }

        // No completions — offer corrections
        let corr = store.spellChecker.suggestions(for: p, limit: limit)
        if !corr.isEmpty {
            return SuggestionResult(candidates: corr, isMisspelled: true, mode: .correction)
        }

        return SuggestionResult(candidates: [], isMisspelled: !store.trie.contains(p), mode: .empty)
    }

    public func learnSelection(_ word: String) {
        personal.learn(word, boost: 5)
    }

    public func addToDictionary(_ word: String) {
        personal.add(word)
    }

    public func clearPersonalDictionary() {
        personal.clear()
    }

    public func isKnown(_ word: String) -> Bool {
        store.trie.contains(word) || personal.contains(word)
    }

    private func uniquePreserveOrder(_ items: [String], limit: Int) -> [String] {
        var seen = Set<String>()
        var out: [String] = []
        for i in items {
            let k = ULYNormalizer.lookupKey(i)
            if seen.insert(k).inserted {
                out.append(k)
            }
            if out.count >= limit { break }
        }
        return out
    }

    private func mergeUnique(_ a: [String], _ b: [String], limit: Int) -> [String] {
        uniquePreserveOrder(a + b, limit: limit)
    }
}
