import Foundation

public struct SuggestionResult: Sendable, Equatable {
    public let candidates: [String]
    /// true when current partial/word looks misspelled
    public let isMisspelled: Bool
    public let mode: Mode

    public enum Mode: String, Sendable, Equatable {
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

    private var cacheKey: String?
    private var cacheValue: SuggestionResult?

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
        let prevKey = previousWord.map { ULYNormalizer.lookupKey($0) } ?? ""
        let key = "\(p)|\(prevKey)|\(limit)"
        if let cached = cacheValue, cacheKey == key {
            return cached
        }
        let result = suggestUncached(partial: p, previousWord: prevKey.isEmpty ? nil : prevKey, limit: limit)
        cacheKey = key
        cacheValue = result
        return result
    }

    public func invalidateCache() {
        cacheKey = nil
        cacheValue = nil
    }

    private func suggestUncached(partial p: String, previousWord: String?, limit: Int) -> SuggestionResult {
        if p.isEmpty {
            let next = store.predictor.nextWords(after: previousWord, limit: limit)
            return SuggestionResult(candidates: next, isMisspelled: false, mode: next.isEmpty ? .empty : .nextWord)
        }

        // Completions first — never pay for spell-check while the trie still matches.
        var comps = personal.rankedPrefix(p, limit: limit)
        comps.append(contentsOf: store.trie.completions(prefix: p, limit: limit * 3))
        comps.sort { $0.1 > $1.1 }
        let words = uniquePreserveOrder(comps.map(\.0), limit: limit)

        if !words.isEmpty {
            let exact = store.trie.contains(p) || personal.contains(p)
            return SuggestionResult(candidates: words, isMisspelled: !exact && p.count > 2, mode: .completion)
        }

        if p.count >= 3 {
            let corr = store.spellChecker.suggestions(for: p, limit: limit)
            if !corr.isEmpty {
                return SuggestionResult(candidates: corr, isMisspelled: true, mode: .correction)
            }
        }

        return SuggestionResult(candidates: [], isMisspelled: !store.trie.contains(p), mode: .empty)
    }

    public func learnSelection(_ word: String) {
        personal.learn(word, boost: 5)
        invalidateCache()
    }

    public func addToDictionary(_ word: String) {
        personal.add(word)
        invalidateCache()
    }

    public func clearPersonalDictionary() {
        personal.clear()
        invalidateCache()
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
}
