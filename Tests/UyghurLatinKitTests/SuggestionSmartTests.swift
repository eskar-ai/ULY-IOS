import XCTest
import UyghurLatinKit

final class SuggestionSmartTests: XCTestCase {
    private func lexiconJSON() -> Data {
        let json: [String: Any] = [
            "meta": [
                "version": "test",
                "script": "uly",
                "wordCount": 8,
                "correctionCount": 3,
                "bigramCount": 1,
                "sources": ["test"],
            ],
            "words": [
                ["yaxshi", 50_000],
                ["yaxshimu", 20_000],
                ["yaxshimusiz", 15_000],
                ["yaxshiturding", 8_000],
                ["yaxshiturdigizmu", 7_000],
                ["uyghur", 100],
                ["uyghurche", 50],
                ["bügün", 80],
            ],
            "corrections": [
                "uygur": "uyghur",
                "yahxi": "yaxshi",
                "yahximu": "yaxshimu",
                "yahximusiz": "yaxshimusiz",
            ],
            "bigrams": [["bügün", "uyghur", 9]],
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    private func engine(suite: String) throws -> SuggestionEngine {
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let store = try LexiconStore(data: lexiconJSON())
        return SuggestionEngine(
            store: store,
            personal: PersonalDictionary(defaults: defaults, useKeychain: false)
        )
    }

    func testYahximuSuggestsYaxshimusiz() throws {
        let suite = "test.yahximu.\(UUID().uuidString)"
        let engine = try engine(suite: suite)
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let result = engine.suggest(partial: "yahximu", previousWord: nil, limit: 8)
        XCTAssertTrue(
            result.candidates.contains("yaxshimusiz") || result.candidates.contains("yaxshimu"),
            "expected correction/morph candidates, got \(result.candidates)"
        )
        XCTAssertTrue(result.isMisspelled)
    }

    func testYaxshiturdingSuggestsYaxshiturdigizmu() throws {
        let suite = "test.turding.\(UUID().uuidString)"
        let engine = try engine(suite: suite)
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let result = engine.suggest(partial: "yaxshiturding", previousWord: nil, limit: 8)
        XCTAssertTrue(
            result.candidates.contains("yaxshiturdigizmu"),
            "expected morph alternate, got \(result.candidates)"
        )
    }

    func testMorphPrefixCompletesMusiz() throws {
        let suite = "test.musiz.\(UUID().uuidString)"
        let engine = try engine(suite: suite)
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let result = engine.suggest(partial: "yaxshimu", previousWord: nil, limit: 8)
        XCTAssertTrue(result.candidates.contains("yaxshimusiz"))
    }

    func testPersonalAddAppearsInPrefix() throws {
        let suite = "test.personal.\(UUID().uuidString)"
        let engine = try engine(suite: suite)
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        engine.addToDictionary("esqerlik")
        let result = engine.suggest(partial: "esqe", previousWord: nil, limit: 5)
        XCTAssertTrue(result.candidates.contains("esqerlik"))
    }

    func testLearnCommittedBoostsRanking() throws {
        let suite = "test.learn.\(UUID().uuidString)"
        let engine = try engine(suite: suite)
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        engine.learnCommittedWord("uyghurche", previous: "bügün")
        let next = engine.suggest(partial: "", previousWord: "bügün", limit: 5)
        XCTAssertTrue(next.candidates.contains("uyghurche"))
    }

    func testMorphologyExpansionsRespectLimit() throws {
        let store = try LexiconStore(data: lexiconJSON())
        let morph = MorphologyExpander(trie: store.trie)
        let hits = morph.expansions(for: "yaxshi", limit: 3)
        XCTAssertLessThanOrEqual(hits.count, 3)
        XCTAssertTrue(hits.allSatisfy { $0.0.hasPrefix("yaxshi") || $0.0.contains("yaxshi") })
    }

    func testDigraphFoldMatchesInformalLatin() {
        XCTAssertEqual(
            SpellChecker.foldConfusable("yahximu"),
            SpellChecker.foldConfusable("yaxshimu")
        )
    }
}
