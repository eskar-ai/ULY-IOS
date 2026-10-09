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
    public let trie: PrefixTrie
    public let spellChecker: SpellChecker
    public let predictor: NGramPredictor
    public let vocabulary: [String]
    public let frequencies: [String: Int]

    public init(data: Data) throws {
        let decoded = try JSONDecoder().decode(LexiconFile.self, from: data)
        self.meta = decoded.meta

        var freqs: [String: Int] = [:]
        var vocab: [String] = []
        let trie = PrefixTrie()
        for row in decoded.words {
            guard row.count >= 2,
                  let w = row[0].stringValue,
                  let f = row[1].intValue else { continue }
            let key = ULYNormalizer.lookupKey(w)
            freqs[key] = f
            vocab.append(key)
            trie.insert(key, frequency: f)
        }
        self.trie = trie
        self.vocabulary = vocab
        self.frequencies = freqs

        var bigramTuples: [(String, String, Int)] = []
        for row in decoded.bigrams {
            guard row.count >= 3,
                  let a = row[0].stringValue,
                  let b = row[1].stringValue,
                  let c = row[2].intValue else { continue }
            bigramTuples.append((a, b, c))
        }

        self.spellChecker = SpellChecker(
            trie: trie,
            vocabulary: vocab,
            corrections: decoded.corrections
        )
        self.predictor = NGramPredictor(
            bigramTuples: bigramTuples,
            unigrams: freqs.map { ($0.key, $0.value) }
        )
    }

    public convenience init(url: URL) throws {
        let data = try Data(contentsOf: url)
        try self.init(data: data)
    }

    public convenience init(bundle: Bundle = .main, resource: String = "lexicon") throws {
        guard let url = bundle.url(forResource: resource, withExtension: "json") else {
            throw NSError(
                domain: "UyghurLatinKit",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "lexicon.json not found in bundle"]
            )
        }
        try self.init(url: url)
    }
}
