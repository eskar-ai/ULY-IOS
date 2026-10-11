import XCTest
import UyghurLatinKit

final class StarterPreferencesTests: XCTestCase {
    func testScenarioChangesActiveStarters() {
        let suite = "test.starters.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let prefs = StarterPreferences(defaults: defaults, useKeychain: false)
        prefs.setScenario(.greeting)
        XCTAssertTrue(prefs.activeStarters().contains("yaxshimusiz"))

        prefs.setScenario(.writing)
        XCTAssertTrue(prefs.activeStarters().contains("emma") || prefs.activeStarters().contains("lekin"))
        XCTAssertFalse(prefs.activeStarters().prefix(3).contains("yaxshimusiz"))
    }

    func testCustomPinsLeadActiveList() {
        let suite = "test.pins.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let prefs = StarterPreferences(defaults: defaults, useKeychain: false)
        prefs.setCustomStarters(["özüm", "salam"])
        let active = prefs.activeStarters()
        XCTAssertEqual(active.first, "özüm")
        XCTAssertTrue(active.contains("salam"))
    }

    func testOpenerLearningBeatsScenarioAtSentenceStart() throws {
        let suite = "test.opener.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let json: [String: Any] = [
            "meta": [
                "version": "t", "script": "uly", "wordCount": 3,
                "correctionCount": 0, "bigramCount": 0, "sources": ["t"],
            ],
            "words": [["salam", 100], ["men", 100], ["bu", 100]],
            "corrections": [:],
            "bigrams": [],
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let personal = PersonalDictionary(defaults: defaults, useKeychain: false)
        let starters = StarterPreferences(defaults: defaults, useKeychain: false)
        starters.setScenario(.general)
        let engine = SuggestionEngine(
            store: try LexiconStore(data: data),
            personal: personal,
            starterPreferences: starters
        )
        engine.learnCommittedWord("esqerteklip", previous: nil, sentenceStart: true)
        let result = engine.suggest(partial: "", previousWord: nil, sentenceStart: true, limit: 5)
        XCTAssertTrue(
            result.candidates.contains("esqerteklip"),
            "expected learned opener, got \(result.candidates)"
        )
    }
}
