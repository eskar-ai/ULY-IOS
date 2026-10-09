import Foundation

final class TrieNode {
    var children: [Character: TrieNode] = [:]
    var isWord = false
    var frequency: Int = 0
    var word: String?
}

/// Frequency-ranked prefix completion over the ULY lexicon.
public final class PrefixTrie {
    private let root = TrieNode()

    public init() {}

    public func insert(_ word: String, frequency: Int) {
        let key = ULYNormalizer.lookupKey(word)
        var node = root
        for ch in key {
            if node.children[ch] == nil {
                node.children[ch] = TrieNode()
            }
            node = node.children[ch]!
        }
        node.isWord = true
        node.frequency = max(node.frequency, frequency)
        node.word = key
    }

    /// Returns up to `limit` completions for `prefix`, highest frequency first.
    public func completions(prefix: String, limit: Int = 8) -> [(String, Int)] {
        let key = ULYNormalizer.lookupKey(prefix)
        guard !key.isEmpty else { return [] }
        var node = root
        for ch in key {
            guard let next = node.children[ch] else { return [] }
            node = next
        }
        var results: [(String, Int)] = []
        collect(from: node, into: &results, limit: max(limit * 4, 32))
        results.sort { lhs, rhs in
            if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
            return lhs.0 < rhs.0
        }
        if results.count > limit {
            results = Array(results.prefix(limit))
        }
        return results
    }

    public func contains(_ word: String) -> Bool {
        let key = ULYNormalizer.lookupKey(word)
        var node = root
        for ch in key {
            guard let next = node.children[ch] else { return false }
            node = next
        }
        return node.isWord
    }

    public func frequency(of word: String) -> Int {
        let key = ULYNormalizer.lookupKey(word)
        var node = root
        for ch in key {
            guard let next = node.children[ch] else { return 0 }
            node = next
        }
        return node.isWord ? node.frequency : 0
    }

    private func collect(from node: TrieNode, into results: inout [(String, Int)], limit: Int) {
        if results.count >= limit { return }
        if node.isWord, let w = node.word {
            results.append((w, node.frequency))
        }
        // Visit higher-frequency branches first when possible
        let ordered = node.children.sorted { a, b in
            a.key < b.key
        }
        for (_, child) in ordered {
            collect(from: child, into: &results, limit: limit)
            if results.count >= limit { return }
        }
    }
}
