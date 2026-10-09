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
        let engine = SuggestionEngine(store: try LexiconStore(data: tinyLexiconJSON()))
        let completion = engine.suggest(partial: "uygh", previousWord: nil, limit: 5)
        XCTAssertEqual(completion.mode, .completion)
        XCTAssertTrue(completion.candidates.contains("uyghur"))

        let next = engine.suggest(partial: "", previousWord: "bügün", limit: 3)
        XCTAssertEqual(next.mode, .nextWord)
        XCTAssertEqual(next.candidates.first, "uyghur")
    }

    func testSpellUsesCorrectionMapAndSkipsTinyPrefixes() throws {
        let store = try LexiconStore(data: tinyLexiconJSON())
        XCTAssertEqual(store.spellChecker.suggestions(for: "uygur", limit: 3).first, "uyghur")
        // len < 3 with no map entry → empty (no edit-distance scan)
        XCTAssertTrue(store.spellChecker.suggestions(for: "xy", limit: 3).isEmpty)
    }

    func testSuggestionCacheInvalidatesOnLearn() throws {
        let engine = SuggestionEngine(store: try LexiconStore(data: tinyLexiconJSON()))
        let a = engine.suggest(partial: "uygh", previousWord: nil, limit: 5)
        let b = engine.suggest(partial: "uygh", previousWord: nil, limit: 5)
        XCTAssertEqual(a, b)
        engine.learnSelection("uyghurche")
        let c = engine.suggest(partial: "uygh", previousWord: nil, limit: 5)
        XCTAssertFalse(c.candidates.isEmpty)
    }
}
