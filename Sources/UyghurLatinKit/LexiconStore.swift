import Foundation

public struct LexiconMeta: Codable, Sendable {
    public let version: String
    public let script: String
    public let wordCount: Int
    public let correctionCount: Int
    public let bigramCount: Int
    public let sources: [String]
    public let notes: String?
}

struct LexiconFile: Codable {
    let meta: LexiconMeta
    let words: [[LexiconValue]]
    let corrections: [String: String]
    let bigrams: [[LexiconValue]]
}

/// JSON number-or-string helper for [[word, freq]] rows.
enum LexiconValue: Codable {
    case string(String)
    case int(Int)

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let i = try? c.decode(Int.self) {
            self = .int(i)
            return
        }
        if let s = try? c.decode(String.self) {
            self = .string(s)
            return
        }
        throw DecodingError.dataCorruptedError(in: c, debugDescription: "Expected string or int")
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .string(let s): try c.encode(s)
        case .int(let i): try c.encode(i)
        }
    }

    var stringValue: String? {
        if case .string(let s) = self { return s }
        return nil
    }

    var intValue: Int? {
        if case .int(let i) = self { return i }
        return nil
    }
}

public final class LexiconStore {
    public let meta: LexiconMeta
    public let words: WordTable
    public let trie: PrefixTrie
    public let spellChecker: SpellChecker
    public let predictor: NGramPredictor

    private init(binary: LexiconBinary) {
        meta = binary.meta
        words = WordTable(binary: binary)
        trie = PrefixTrie(binary: binary, words: words)
        spellChecker = SpellChecker(trie: trie, binary: binary)
        predictor = NGramPredictor(binary: binary, trie: trie)
    }

    /// Compiled `lexicon.bin` bytes.
    public convenience init(binaryData: Data) throws {
        self.init(binary: try LexiconBinary(data: binaryData))
    }

    /// Memory-mapped `lexicon.bin`.
    public convenience init(binaryURL: URL) throws {
        self.init(binary: try LexiconBinary(contentsOf: binaryURL))
    }

    /// `lexicon.json` bytes (compiled to the binary layout in memory).
    public convenience init(data: Data) throws {
        let decoded = try JSONDecoder().decode(LexiconFile.self, from: data)
        let words: [(String, Int)] = decoded.words.compactMap { row in
            guard row.count >= 2, let w = row[0].stringValue, let f = row[1].intValue else { return nil }
            return (w, f)
        }
        let bigrams: [(String, String, Int)] = decoded.bigrams.compactMap { row in
            guard row.count >= 3,
                  let a = row[0].stringValue,
                  let b = row[1].stringValue,
                  let c = row[2].intValue else { return nil }
            return (a, b, c)
        }
        let bin = try LexiconBinaryBuilder.build(
            meta: decoded.meta,
            words: words,
            corrections: decoded.corrections,
            bigrams: bigrams
        )
        try self.init(binaryData: bin)
    }

    public convenience init(url: URL) throws {
        if url.pathExtension == "bin" {
            try self.init(binaryURL: url)
        } else {
            try self.init(data: Data(contentsOf: url))
        }
    }

    /// Prefers `<resource>.bin` (memory-mapped), falls back to `<resource>.json`.
    public convenience init(bundle: Bundle = .main, resource: String = "lexicon") throws {
        if let bin = bundle.url(forResource: resource, withExtension: "bin") {
            try self.init(binaryURL: bin)
        } else if let json = bundle.url(forResource: resource, withExtension: "json") {
            try self.init(url: json)
        } else {
            throw NSError(
                domain: "UyghurLatinKit",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "lexicon.bin / lexicon.json not found in bundle"]
            )
        }
    }
}
