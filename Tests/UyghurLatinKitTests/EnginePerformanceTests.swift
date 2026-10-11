import XCTest
import UyghurLatinKit

final class EnginePerformanceTests: XCTestCase {
    private func tinyLexiconJSON() -> Data {
        let json: [String: Any] = [
            "meta": [
                "version": "test",
                "script": "uly",
                "wordCount": 3,
                "correctionCount": 1,
                "bigramCount": 1,
                "sources": ["test"],
            ],
            "words": [["uyghur", 100], ["uyghurche", 50], ["bügün", 80]],
            "corrections": ["uygur": "uyghur"],
            "bigrams": [["bügün", "uyghur", 9]],
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    func testCompletionsRankByFrequency() throws {
        let store = try LexiconStore(data: tinyLexiconJSON())
        let hits = store.trie.completions(prefix: "uygh", limit: 5)
        XCTAssertFalse(hits.isEmpty)
        XCTAssertEqual(hits[0].0, "uyghur")
    }

    func testSuggestCompletionAndNextWord() throws {
        let suite = "test.perf.next.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let engine = SuggestionEngine(
            store: try LexiconStore(data: tinyLexiconJSON()),
            personal: PersonalDictionary(defaults: defaults, useKeychain: false)
        )
        let completion = engine.suggest(partial: "uygh", previousWord: nil, limit: 5)
        XCTAssertEqual(completion.mode, .completion)
        XCTAssertTrue(completion.candidates.contains("uyghur"))

        let next = engine.suggest(partial: "", previousWord: "bügün", sentenceStart: false, limit: 3)
        XCTAssertEqual(next.mode, .nextWord)
        XCTAssertEqual(next.candidates.first, "uyghur")
    }

    func testSentenceStartAvoidsRawUnigramHeadwords() throws {
        let suite = "test.perf.starters.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let json: [String: Any] = [
            "meta": [
                "version": "test", "script": "uly", "wordCount": 5,
                "correctionCount": 0, "bigramCount": 0, "sources": ["t"],
            ],
            "words": [
                ["aq", 99_000], ["qara", 98_000], ["ata", 97_000],
                ["salam", 100], ["men", 100],
            ],
            "corrections": [:],
            "bigrams": [],
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let engine = SuggestionEngine(
            store: try LexiconStore(data: data),
            personal: PersonalDictionary(defaults: defaults, useKeychain: false)
        )
        let start = engine.suggest(partial: "", previousWord: nil, sentenceStart: true, limit: 3)
        XCTAssertEqual(start.mode, .nextWord)
        XCTAssertFalse(start.candidates.contains("aq"))
        XCTAssertFalse(start.candidates.contains("qara"))
        XCTAssertTrue(
            start.candidates.contains("salam") || start.candidates.contains("men"),
            "expected sentence starters, got \(start.candidates)"
        )
    }

    func testSpellUsesCorrectionMapAndSkipsTinyPrefixes() throws {
        let store = try LexiconStore(data: tinyLexiconJSON())
        XCTAssertEqual(store.spellChecker.suggestions(for: "uygur", limit: 3).first, "uyghur")
        // len < 3 with no map entry → empty (no edit-distance scan)
        XCTAssertTrue(store.spellChecker.suggestions(for: "xy", limit: 3).isEmpty)
    }

    func testSuggestionCacheInvalidatesOnLearn() throws {
        let suite = "test.perf.cache.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let engine = SuggestionEngine(
            store: try LexiconStore(data: tinyLexiconJSON()),
            personal: PersonalDictionary(defaults: defaults, useKeychain: false)
        )
        let a = engine.suggest(partial: "uygh", previousWord: nil, limit: 5)
        let b = engine.suggest(partial: "uygh", previousWord: nil, limit: 5)
        XCTAssertEqual(a, b)
        engine.learnSelection("uyghurche")
        let c = engine.suggest(partial: "uygh", previousWord: nil, limit: 5)
        XCTAssertFalse(c.candidates.isEmpty)
    }
}
