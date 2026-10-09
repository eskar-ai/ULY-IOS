import Foundation

/// Bigram → unigram fallback next-word prediction.
public final class NGramPredictor {
    private var bigrams: [String: [(String, Int)]] = [:]
    private var unigrams: [(String, Int)] = []

    public init(bigramTuples: [(String, String, Int)], unigrams: [(String, Int)]) {
        var map: [String: [(String, Int)]] = [:]
        for (a, b, c) in bigramTuples {
            let key = ULYNormalizer.lookupKey(a)
            let next = ULYNormalizer.lookupKey(b)
            map[key, default: []].append((next, c))
        }
        for (k, list) in map {
            self.bigrams[k] = list.sorted { $0.1 > $1.1 }
        }
        self.unigrams = unigrams.sorted { $0.1 > $1.1 }
    }

    public func nextWords(after previous: String?, limit: Int = 6) -> [String] {
        if let prev = previous, !prev.isEmpty {
            let key = ULYNormalizer.lookupKey(prev)
            if let list = bigrams[key], !list.isEmpty {
                return Array(list.prefix(limit).map(\.0))
            }
        }
        return Array(unigrams.prefix(limit).map(\.0))
    }
}
