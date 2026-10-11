import XCTest
import UyghurLatinKit

final class PersonalDictionaryTransferTests: XCTestCase {
    func testExportImportRoundTripMergesScores() throws {
        let suiteA = "test.export.a.\(UUID().uuidString)"
        let suiteB = "test.export.b.\(UUID().uuidString)"
        let a = UserDefaults(suiteName: suiteA)!
        let b = UserDefaults(suiteName: suiteB)!
        defer {
            a.removePersistentDomain(forName: suiteA)
            b.removePersistentDomain(forName: suiteB)
        }

        let source = PersonalDictionary(defaults: a, useKeychain: false)
        source.add("esqerlik")
        source.learnBigram(previous: "salam", word: "esqerlik", boost: 5)
        source.learnTrigram(w1: "men", w2: "salam", w3: "esqerlik", boost: 2)
        let data = try source.exportJSONData()

        let dest = PersonalDictionary(defaults: b, useKeychain: false)
        dest.add("esqerlik") // lower score path via add=100 same
        dest.learn("bashqa", boost: 3)
        let merged = try dest.mergeImport(from: data)

        XCTAssertGreaterThan(merged, 0)
        XCTAssertTrue(dest.contains("esqerlik"))
        XCTAssertTrue(dest.contains("bashqa"))
        let next = dest.nextWords(after: "salam", limit: 5).map(\.0)
        XCTAssertTrue(next.contains("esqerlik"))
        let tri = dest.nextWords(after: "salam", beforePrevious: "men", limit: 5).map(\.0)
        XCTAssertTrue(tri.contains("esqerlik"))
    }

    func testUnknownCommitLearnsAggressively() throws {
        let suite = "test.unknown.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let json: [String: Any] = [
            "meta": [
                "version": "t", "script": "uly", "wordCount": 1,
                "correctionCount": 0, "bigramCount": 0, "sources": ["t"],
            ],
            "words": [["yaxshi", 10]],
            "corrections": [:],
            "bigrams": [],
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let engine = SuggestionEngine(
            store: try LexiconStore(data: data),
            personal: PersonalDictionary(defaults: defaults, useKeychain: false)
        )
        engine.learnCommittedWord("özgünsoz", previous: "yaxshi", beforePrevious: "bu")
        let result = engine.suggest(partial: "özgü", previousWord: nil, limit: 5)
        XCTAssertTrue(result.candidates.contains("özgünsoz"))
    }
}
