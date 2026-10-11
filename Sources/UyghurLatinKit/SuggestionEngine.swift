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

/// Orchestrates personal words → completion → morphology → correction → next-word prediction.
public final class SuggestionEngine {
    private let store: LexiconStore
    private let personal: PersonalDictionary
    private let morphology: MorphologyExpander
    private let starterPrefs: StarterPreferences

    private var cacheKey: String?
    private var cacheValue: SuggestionResult?

    public init(
        store: LexiconStore,
        personal: PersonalDictionary = PersonalDictionary(),
        starterPreferences: StarterPreferences = StarterPreferences()
    ) {
        self.store = store
        self.personal = personal
        self.morphology = MorphologyExpander(trie: store.trie)
        self.starterPrefs = starterPreferences
        store.predictor.updateStarters(starterPreferences.activeStarters())
    }

    public var lexiconMeta: LexiconMeta { store.meta }

    /// Exposed for host-app dictionary management UI.
    public var personalDictionary: PersonalDictionary { personal }

    public var starterPreferences: StarterPreferences { starterPrefs }

    /// Reload scenario / custom starters from Keychain (call when keyboard appears).
    public func reloadStarterPreferences() {
        starterPrefs.reload()
        store.predictor.updateStarters(starterPrefs.activeStarters())
        invalidateCache()
    }

    /// Build spell-check indexes ahead of the first typo. Thread-safe; call off the engine queue.
    public func prewarm() {
        store.spellChecker.prewarm()
    }

    /// Write pending personal learning to storage now.
    public func flushPersonal() {
        personal.flush()
    }

    /// Pick up edits the host app made to the personal dictionary.
    public func reloadPersonal() {
        personal.reloadFromStorage()
        invalidateCache()
    }

    /// - Parameters:
    ///   - partial: characters of the word currently being typed (may be empty after space)
    ///   - previousWord: last committed word for bigram prediction
    ///   - beforePreviousWord: word before that, for personal trigrams
    ///   - sentenceStart: true at empty field or after sentence punctuation
    public func suggest(
        partial: String,
        previousWord: String?,
        beforePreviousWord: String? = nil,
        sentenceStart: Bool = false,
        limit: Int = 3
    ) -> SuggestionResult {
        let p = ULYNormalizer.lookupKey(partial)
        let prevKey = previousWord.map { ULYNormalizer.lookupKey($0) } ?? ""
        let prev2Key = beforePreviousWord.map { ULYNormalizer.lookupKey($0) } ?? ""
        // Next-word / sentence-start uses a rotating predictor — skip cache there.
        let cacheable = !p.isEmpty
        let key = "\(p)|\(prevKey)|\(prev2Key)|\(sentenceStart)|\(limit)"
        if cacheable, let cached = cacheValue, cacheKey == key {
            return cached
        }
        let result = suggestUncached(
            partial: p,
            previousWord: prevKey.isEmpty ? nil : prevKey,
            beforePreviousWord: prev2Key.isEmpty ? nil : prev2Key,
            sentenceStart: sentenceStart,
            limit: limit
        )
        if cacheable {
            cacheKey = key
            cacheValue = result
        }
        return result
    }

    public func invalidateCache() {
        cacheKey = nil
        cacheValue = nil
    }

    private func suggestUncached(
        partial p: String,
        previousWord: String?,
        beforePreviousWord: String?,
        sentenceStart: Bool,
        limit: Int
    ) -> SuggestionResult {
        if p.isEmpty {
            var ranked: [(String, Int)] = []
            if sentenceStart || previousWord == nil {
                // Personal openers dominate sentence start.
                ranked.append(contentsOf: personal.rankedOpeners(limit: limit * 2))
                // Light boost for general personal words the user types often.
                let topPersonal = personal.topWords(limit: limit)
                    .map { ($0.0, $0.1 + 40_000) }
                ranked.append(contentsOf: topPersonal)
            } else {
                ranked.append(contentsOf: personal.nextWords(
                    after: previousWord,
                    beforePrevious: beforePreviousWord,
                    limit: limit
                ))
            }
            let staticNext = store.predictor.nextWords(
                after: sentenceStart ? nil : previousWord,
                sentenceStart: sentenceStart || previousWord == nil,
                limit: limit * 2
            )
            for (idx, w) in staticNext.enumerated() {
                ranked.append((w, 10_000 - idx))
            }
            ranked.sort { $0.1 > $1.1 }
            let words = uniquePreserveOrder(ranked.map(\.0), limit: limit)
            return SuggestionResult(candidates: words, isMisspelled: false, mode: words.isEmpty ? .empty : .nextWord)
        }

        // Completions first — never pay for spell-check while the trie still matches.
        var comps = personal.rankedPrefix(p, limit: limit)
        comps.append(contentsOf: store.trie.completions(prefix: p, limit: limit * 3))
        if comps.count < limit {
            comps.append(contentsOf: morphology.expansions(for: p, limit: limit * 2))
        }
        comps.sort { $0.1 > $1.1 }
        var words = uniquePreserveOrder(comps.map(\.0), limit: limit)

        if !words.isEmpty {
            let exact = store.trie.contains(p) || personal.contains(p)
            return SuggestionResult(candidates: words, isMisspelled: !exact && p.count > 2, mode: .completion)
        }

        if p.count >= 3 {
            let corr = store.spellChecker.suggestions(for: p, limit: limit)
            var ranked: [(String, Int)] = []
            for (idx, c) in corr.enumerated() {
                ranked.append((c, 500_000 - idx * 10))
                let morph = morphology.expansions(for: c, limit: limit)
                for (m, score) in morph {
                    ranked.append((m, score + 100_000 - idx * 10))
                }
            }
            ranked.sort { $0.1 > $1.1 }
            words = uniquePreserveOrder(ranked.map(\.0), limit: limit)
            if !words.isEmpty {
                return SuggestionResult(candidates: words, isMisspelled: true, mode: .correction)
            }
        }

        return SuggestionResult(candidates: [], isMisspelled: !store.trie.contains(p) && !personal.contains(p), mode: .empty)
    }

    public func learnSelection(
        _ word: String,
        previous: String? = nil,
        beforePrevious: String? = nil,
        sentenceStart: Bool = false
    ) {
        personal.learn(word, boost: 6)
        if sentenceStart || previous == nil || previous?.isEmpty == true {
            personal.learnOpener(word, boost: 22)
        } else if let previous, !previous.isEmpty {
            personal.learnBigram(previous: previous, word: word, boost: 4)
            if let beforePrevious, !beforePrevious.isEmpty {
                personal.learnTrigram(w1: beforePrevious, w2: previous, w3: word, boost: 3)
            }
        }
        invalidateCache()
    }

    /// Learn a word the user finished typing (space / return).
    public func learnCommittedWord(
        _ word: String,
        previous: String?,
        beforePrevious: String? = nil,
        sentenceStart: Bool = false
    ) {
        let key = ULYNormalizer.lookupKey(word)
        guard key.count >= 2 else { return }
        let boost: Int
        if personal.contains(key) {
            boost = 2
        } else if store.trie.contains(key) {
            boost = 1
        } else {
            boost = 12
        }
        personal.learn(key, boost: boost)
        if sentenceStart || previous == nil || previous?.isEmpty == true {
            // Strong opener learning — this is what makes cold-start feel personal.
            personal.learnOpener(key, boost: sentenceStart ? 24 : 14)
        } else if let previous, !previous.isEmpty {
            personal.learnBigram(previous: previous, word: key, boost: boost >= 12 ? 4 : 2)
            if let beforePrevious, !beforePrevious.isEmpty {
                personal.learnTrigram(w1: beforePrevious, w2: previous, w3: key, boost: 2)
            }
        }
        invalidateCache()
    }

    public func addToDictionary(_ word: String) {
        personal.add(word)
        invalidateCache()
    }

    public func removeFromDictionary(_ word: String) {
        personal.remove(word)
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
