import XCTest
import UyghurLatinKit

/// Checks the compiled `lexicon.bin` (tools/compile_lexicon_bin.py) against the JSON path
/// (Swift builder), and keeps an eye on load time.
final class LexiconBinaryTests: XCTestCase {
    private var repoRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private var resources: URL {
        repoRoot.appendingPathComponent("ios/UyghurLatinKeyboard/Resources")
    }

    private func bundledStores() throws -> (bin: LexiconStore, json: LexiconStore) {
        let binURL = resources.appendingPathComponent("lexicon.bin")
        let jsonURL = repoRoot.appendingPathComponent("data/generated/lexicon.json")
        guard FileManager.default.fileExists(atPath: binURL.path),
              FileManager.default.fileExists(atPath: jsonURL.path) else {
            throw XCTSkip("bundled lexicon not present")
        }
        return (try LexiconStore(binaryURL: binURL), try LexiconStore(url: jsonURL))
    }

    func testCompiledBinaryMatchesJSONBuilder() throws {
        let (bin, json) = try bundledStores()
        XCTAssertEqual(bin.words.count, json.words.count)
        XCTAssertEqual(bin.meta.version, json.meta.version)
        for prefix in ["a", "ya", "yax", "uygh", "sh", "kë", "ö", "bol", "mek", "qan"] {
            XCTAssertEqual(
                bin.trie.completions(prefix: prefix, limit: 12).map(\.0),
                json.trie.completions(prefix: prefix, limit: 12).map(\.0),
                "completions differ for \(prefix)"
            )
        }
        for w in ["yaxshi", "kërek", "uyghur", "notaword"] {
            XCTAssertEqual(bin.trie.frequency(of: w), json.trie.frequency(of: w), w)
        }
        for typo in ["kandaq", "yurak", "yahximu", "uygur"] {
            XCTAssertEqual(
                bin.spellChecker.suggestions(for: typo, limit: 5),
                json.spellChecker.suggestions(for: typo, limit: 5),
                typo
            )
        }
        XCTAssertEqual(
            bin.predictor.nextWords(after: "biz", limit: 6),
            json.predictor.nextWords(after: "biz", limit: 6)
        )
    }

    func testCompletionsAreFrequencySortedAndPrefixed() throws {
        let (bin, _) = try bundledStores()
        let hits = bin.trie.completions(prefix: "ya", limit: 20)
        XCTAssertEqual(hits.count, 20)
        XCTAssertTrue(hits.allSatisfy { $0.0.hasPrefix("ya") })
        XCTAssertEqual(hits.map(\.1), hits.map(\.1).sorted(by: >))
        XCTAssertEqual(bin.spellChecker.suggestions(for: "kandaq", limit: 1).first, "qandaq")
    }

    func testMappedLoadIsFast() throws {
        let binURL = resources.appendingPathComponent("lexicon.bin")
        guard FileManager.default.fileExists(atPath: binURL.path) else {
            throw XCTSkip("bundled lexicon.bin not present")
        }
        let footprintBefore = Self.physFootprint()
        let start = CFAbsoluteTimeGetCurrent()
        let store = try LexiconStore(binaryURL: binURL)
        let engine = SuggestionEngine(
            store: store,
            personal: PersonalDictionary(defaults: nil, useKeychain: false),
            starterPreferences: StarterPreferences(
                defaults: UserDefaults(suiteName: "test.load.\(UUID().uuidString)")!,
                useKeychain: false
            )
        )
        _ = engine.suggest(partial: "yax", previousWord: nil, limit: 8)
        _ = engine.suggest(partial: "", previousWord: nil, sentenceStart: true, limit: 8)
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        XCTAssertLessThan(elapsed, 0.3, "cold load + first suggestions took \(elapsed)s")

        let warmStart = CFAbsoluteTimeGetCurrent()
        engine.prewarm()
        let warm = CFAbsoluteTimeGetCurrent() - warmStart
        _ = engine.suggest(partial: "yahximu", previousWord: nil, limit: 8)
        XCTAssertLessThan(warm, 2.0, "spell index build took \(warm)s")
        let grownMB = Double(Self.physFootprint() - footprintBefore) / 1_048_576
        XCTAssertLessThan(grownMB, 25, "engine footprint grew \(grownMB) MB")
        print("lexicon.bin load+suggest: \(Int(elapsed * 1000)) ms, spell prewarm: \(Int(warm * 1000)) ms, footprint +\(String(format: "%.1f", grownMB)) MB")
    }

    private static func physFootprint() -> Int64 {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)
        let kr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        return kr == KERN_SUCCESS ? Int64(info.phys_footprint) : 0
    }
}
