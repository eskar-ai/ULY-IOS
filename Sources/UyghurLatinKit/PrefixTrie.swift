import Foundation

/// Lexicon words by id (ids are sorted by frequency, highest first). Shared by trie, spell
/// checker and predictor so the vocabulary exists once, inside the mapped lexicon.
public final class WordTable {
    let binary: LexiconBinary

    init(binary: LexiconBinary) {
        self.binary = binary
    }

    public var count: Int { binary.wordCount }

    public func word(at id: Int) -> String { binary.string(id) }

    public func frequency(at id: Int) -> Int { binary.frequency(ofWord: id) }
}

/// Binary heap; `above(a, b)` means `a` sits closer to the top than `b`.
struct BinaryHeap<Element> {
    private var items: [Element] = []
    private let above: (Element, Element) -> Bool

    init(above: @escaping (Element, Element) -> Bool) {
        self.above = above
    }

    var isEmpty: Bool { items.isEmpty }
    var count: Int { items.count }

    mutating func push(_ e: Element) {
        items.append(e)
        var i = items.count - 1
        while i > 0 {
            let parent = (i - 1) / 2
            guard above(items[i], items[parent]) else { break }
            items.swapAt(i, parent)
            i = parent
        }
    }

    mutating func pop() -> Element? {
        guard !items.isEmpty else { return nil }
        let top = items[0]
        let last = items.removeLast()
        if !items.isEmpty {
            items[0] = last
            var i = 0
            while true {
                let l = 2 * i + 1
                let r = l + 1
                var best = i
                if l < items.count, above(items[l], items[best]) { best = l }
                if r < items.count, above(items[r], items[best]) { best = r }
                if best == i { break }
                items.swapAt(i, best)
                i = best
            }
        }
        return top
    }
}

/// Frequency-ranked prefix completion over the compiled lexicon trie.
public final class PrefixTrie {
    private let bin: LexiconBinary
    public let words: WordTable

    init(binary: LexiconBinary, words: WordTable) {
        self.bin = binary
        self.words = words
    }

    private func node(for key: String) -> Int? {
        guard let path = LexiconBinary.pathScalars(key) else { return nil }
        var node = 0
        for s in path {
            let first = bin.firstChild(node)
            let count = bin.childCount(node)
            var found = -1
            for c in first..<(first + count) where bin.label(c) == s {
                found = c
                break
            }
            if found < 0 { return nil }
            node = found
        }
        return node
    }

    /// Lexicon word id for `word`, if it is a lexicon word.
    public func wordId(_ word: String) -> Int? {
        guard let n = node(for: ULYNormalizer.lookupKey(word)) else { return nil }
        let id = bin.wordId(atNode: n)
        return id == LexiconBinary.noWord ? nil : Int(id)
    }

    /// Returns up to `limit` completions for `prefix`, highest frequency first.
    public func completions(prefix: String, limit: Int = 8) -> [(String, Int)] {
        guard limit > 0 else { return [] }
        let key = ULYNormalizer.lookupKey(prefix)
        guard !key.isEmpty, let start = node(for: key) else { return [] }

        // Best-first search. Entries are subtree nodes (priority = best freq in subtree)
        // or finished words (priority = own freq). Popping a word means nothing left can beat it.
        struct Entry {
            let priority: Int
            let isWord: Bool
            let index: Int
        }
        var heap = BinaryHeap<Entry> { a, b in
            if a.priority != b.priority { return a.priority > b.priority }
            if a.isWord != b.isWord { return a.isWord }
            return a.index < b.index
        }
        heap.push(Entry(priority: bin.best(start), isWord: false, index: start))
        var out: [(String, Int)] = []
        var pops = 0
        let popCap = max(limit * 96, 512)
        while out.count < limit, pops < popCap, let e = heap.pop() {
            pops += 1
            if e.isWord {
                out.append((words.word(at: e.index), e.priority))
                continue
            }
            let w = bin.wordId(atNode: e.index)
            if w != LexiconBinary.noWord {
                heap.push(Entry(priority: bin.frequency(ofWord: Int(w)), isWord: true, index: Int(w)))
            }
            let first = bin.firstChild(e.index)
            for c in first..<(first + bin.childCount(e.index)) {
                heap.push(Entry(priority: bin.best(c), isWord: false, index: c))
            }
        }
        return out
    }

    public func contains(_ word: String) -> Bool {
        wordId(word) != nil
    }

    public func frequency(of word: String) -> Int {
        guard let id = wordId(word) else { return 0 }
        return words.frequency(at: id)
    }
}
