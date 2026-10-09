import Foundation

final class TrieNode {
    var children: [Character: TrieNode] = [:]
    var isWord = false
    var frequency: Int = 0
    var word: String?
    /// Max frequency in this subtree — guides best-first completion.
    var bestFrequency: Int = 0
}

/// Frequency-ranked prefix completion over the ULY lexicon.
public final class PrefixTrie {
    private let root = TrieNode()

    public init() {}

    public func insert(_ word: String, frequency: Int) {
        let key = ULYNormalizer.lookupKey(word)
        var node = root
        var path: [TrieNode] = [node]
        for ch in key {
            if node.children[ch] == nil {
                node.children[ch] = TrieNode()
            }
            node = node.children[ch]!
            path.append(node)
        }
        node.isWord = true
        node.frequency = max(node.frequency, frequency)
        node.word = key
        for n in path {
            n.bestFrequency = max(n.bestFrequency, node.frequency)
        }
    }

    /// Returns up to `limit` completions for `prefix`, highest frequency first.
    public func completions(prefix: String, limit: Int = 8) -> [(String, Int)] {
        guard limit > 0 else { return [] }
        let key = ULYNormalizer.lookupKey(prefix)
        guard !key.isEmpty else { return [] }
        var node = root
        for ch in key {
            guard let next = node.children[ch] else { return [] }
            node = next
        }

        // Min-heap of (word, freq) by frequency — keep top `limit`.
        var heap: [(String, Int)] = []
        heap.reserveCapacity(limit)

        func consider(_ word: String, _ freq: Int) {
            if heap.count < limit {
                heap.append((word, freq))
                heap.sort { $0.1 < $1.1 }
            } else if freq > heap[0].1 {
                heap[0] = (word, freq)
                heap.sort { $0.1 < $1.1 }
            }
        }

        var stack: [TrieNode] = [node]
        var visited = 0
        let visitCap = max(limit * 64, 256)
        while let current = stack.popLast(), visited < visitCap {
            visited += 1
            if current.isWord, let w = current.word {
                consider(w, current.frequency)
            }
            let kids = current.children.values.sorted { $0.bestFrequency < $1.bestFrequency }
            for child in kids {
                if heap.count >= limit, child.bestFrequency <= heap[0].1 { continue }
                stack.append(child)
            }
        }

        return heap.sorted { lhs, rhs in
            if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
            return lhs.0 < rhs.0
        }
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
}
