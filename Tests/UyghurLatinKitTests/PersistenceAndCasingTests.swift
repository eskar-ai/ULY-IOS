import XCTest
import UyghurLatinKit

final class CasingPolicyTests: XCTestCase {
    func testSentenceStartCapitalizesEmptyPartial() {
        XCTAssertEqual(CasingPolicy.apply(word: "salam", partial: "", sentenceStart: true), "Salam")
        XCTAssertEqual(CasingPolicy.apply(word: "salam", partial: "", sentenceStart: false), "salam")
    }

    func testFollowsTypedCase() {
        XCTAssertEqual(CasingPolicy.apply(word: "yaxshimu", partial: "Yax", sentenceStart: false), "Yaxshimu")
        XCTAssertEqual(CasingPolicy.apply(word: "yaxshimu", partial: "YAX", sentenceStart: false), "YAXSHIMU")
        XCTAssertEqual(CasingPolicy.apply(word: "yaxshimu", partial: "yax", sentenceStart: true), "yaxshimu")
        XCTAssertEqual(CasingPolicy.apply(word: "shundaq", partial: "Sh", sentenceStart: false), "Shundaq")
    }

    func testSingleCapitalLetterIsCapitalizedNotUpper() {
        XCTAssertEqual(CasingPolicy.apply(word: "ëytish", partial: "Ë", sentenceStart: false), "Ëytish")
        XCTAssertEqual(CasingPolicy.style(partial: "Ö", sentenceStart: false), .capitalized)
    }
}

final class PersonalPersistenceTests: XCTestCase {
    private func makeDefaults() -> (UserDefaults, String) {
        let suite = "test.persist.\(UUID().uuidString)"
        return (UserDefaults(suiteName: suite)!, suite)
    }

    func testImmediateModeWritesEachMutation() {
        let (defaults, suite) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let dict = PersonalDictionary(defaults: defaults, useKeychain: false)
        dict.learn("salam")
        dict.learn("rehmet")
        XCTAssertEqual(dict.persistCount, 2)
    }

    func testDebouncedFlushWritesOnce() {
        let (defaults, suite) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let queue = DispatchQueue(label: "test.flush")
        var dict: PersonalDictionary!
        queue.sync {
            dict = PersonalDictionary(defaults: defaults, useKeychain: false, flushQueue: queue, flushDelay: 0.05)
            for i in 0..<30 {
                dict.learn("soz\(i)")
                dict.learnBigram(previous: "men", word: "soz\(i)")
            }
            XCTAssertEqual(dict.persistCount, 0)
        }
        let done = expectation(description: "flushed")
        queue.asyncAfter(deadline: .now() + 0.3) { done.fulfill() }
        wait(for: [done], timeout: 2)
        queue.sync {
            XCTAssertEqual(dict.persistCount, 1)
        }

        let reloaded = PersonalDictionary(defaults: defaults, useKeychain: false)
        XCTAssertEqual(reloaded.wordCount, 30)
        XCTAssertEqual(reloaded.nextWords(after: "men", limit: 50).count, 30)
    }

    func testExplicitFlushWritesPendingChanges() {
        let (defaults, suite) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let queue = DispatchQueue(label: "test.flush.explicit")
        queue.sync {
            let dict = PersonalDictionary(defaults: defaults, useKeychain: false, flushQueue: queue, flushDelay: 60)
            dict.add("qelem")
            dict.flush()
            XCTAssertEqual(dict.persistCount, 1)
            dict.flush()
            XCTAssertEqual(dict.persistCount, 1, "clean dictionary must not rewrite")
        }
        XCTAssertTrue(PersonalDictionary(defaults: defaults, useKeychain: false).contains("qelem"))
    }

    func testMigratesV1DictionariesIntoSingleBlob() {
        let (defaults, suite) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(["salam": 40, "dostum": 12], forKey: "uyghurlatin.personalWords")
        defaults.set(["salam\u{1f}dostum": 7], forKey: "uyghurlatin.personalBigrams")
        defaults.set(["men\u{1f}salam\u{1f}dostum": 3], forKey: "uyghurlatin.personalTrigrams")
        defaults.set(["salam": 30], forKey: "uyghurlatin.personalOpeners")

        let dict = PersonalDictionary(defaults: defaults, useKeychain: false)
        XCTAssertEqual(dict.wordScores["salam"], 40)
        XCTAssertEqual(dict.nextWords(after: "salam", limit: 3).first?.0, "dostum")
        XCTAssertEqual(dict.nextWords(after: "salam", beforePrevious: "men", limit: 3).first?.0, "dostum")
        XCTAssertEqual(dict.rankedOpeners(limit: 1).first?.0, "salam")

        XCTAssertNotNil(defaults.data(forKey: "uyghurlatin.personalV2"))
        for key in ["Words", "Bigrams", "Trigrams", "Openers"] {
            XCTAssertNil(defaults.object(forKey: "uyghurlatin.personal\(key)"), "v1 \(key) should be removed")
        }

        let again = PersonalDictionary(defaults: defaults, useKeychain: false)
        XCTAssertEqual(again.snapshot(), dict.snapshot())
    }

    func testPrefixLookupAndTopWordsStayInSync() {
        let dict = PersonalDictionary(defaults: nil, useKeychain: false)
        dict.learn("bala", boost: 5)
        dict.learn("baliliq", boost: 9)
        dict.learn("bazar", boost: 2)
        dict.learn("alma", boost: 50)
        XCTAssertEqual(dict.rankedPrefix("bal", limit: 5).map(\.0), ["baliliq", "bala"])
        dict.learn("bazar", boost: 20)
        XCTAssertEqual(dict.rankedPrefix("ba", limit: 1).first?.0, "bazar")
        XCTAssertEqual(dict.topWords(limit: 2).map(\.0), ["alma", "bazar"])
        dict.remove("alma")
        XCTAssertEqual(dict.topWords(limit: 1).first?.0, "bazar")
        XCTAssertTrue(dict.rankedPrefix("al", limit: 3).isEmpty)
    }
}
