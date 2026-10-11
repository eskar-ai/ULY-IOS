import Foundation

/// Read-only view over a compiled `lexicon.bin` (memory-mapped in the keyboard).
///
/// Layout (little-endian, every section 4-byte aligned), mirrored by `tools/compile_lexicon_bin.py`:
/// ```
/// header   "ULYB", formatVersion, metaLength, wordCount W, stringCount S, nodeCount N,
///          correctionCount C, bigramCount B, stringBlobLength, reserved   (10 × u32)
/// meta     JSON bytes, zero-padded to 4
/// u32[S+1] string offsets into the blob; ids < W are lexicon words sorted by frequency desc,
///          ids ≥ W are extra strings used only by corrections / bigrams
/// u32[W]   word frequencies
/// u32[N]   node first-child index        (root = 0, children contiguous, BFS order)
/// u32[N]   node label (low 16: unicode scalar of the incoming edge) | child count << 16
/// u32[N]   node word id (0xFFFFFFFF = none)
/// u32[2C]  corrections (wrongId, rightId) sorted by wrong string UTF-8 bytes
/// u32[3B]  bigrams (prevId, nextId, count) sorted by prev string bytes, then count desc
/// bytes    UTF-8 string blob
/// ```
/// Children are sorted by the best frequency in their subtree (desc), so `best(node)` is
/// derived from the first-child chain instead of being stored.
final class LexiconBinary {
    static let magic: [UInt8] = Array("ULYB".utf8)
    static let formatVersion: UInt32 = 2
    static let noWord: UInt32 = 0xFFFF_FFFF
    private static let headerWords = 10

    let meta: LexiconMeta
    let wordCount: Int
    let stringCount: Int
    let nodeCount: Int
    let correctionCount: Int
    let bigramCount: Int

    private let storage: NSData
    private let base: UnsafeRawPointer
    private let offStrings: Int
    private let offFreqs: Int
    private let offFirstChild: Int
    private let offInfo: Int
    private let offWord: Int
    private let offCorrections: Int
    private let offBigrams: Int
    private let offBlob: Int

    init(storage: NSData) throws {
        self.storage = storage
        guard storage.length >= Self.headerWords * 4 else { throw Self.corrupt("short header") }
        base = storage.bytes
        let raw = base
        func header(_ i: Int) -> Int { Int(raw.loadUnaligned(fromByteOffset: i * 4, as: UInt32.self)) }

        let magicOK = (0..<4).allSatisfy { raw.load(fromByteOffset: $0, as: UInt8.self) == Self.magic[$0] }
        guard magicOK else { throw Self.corrupt("bad magic") }
        guard header(1) == Int(Self.formatVersion) else { throw Self.corrupt("unsupported version") }
        let metaLength = header(2)
        wordCount = header(3)
        stringCount = header(4)
        nodeCount = header(5)
        correctionCount = header(6)
        bigramCount = header(7)
        let blobLength = header(8)

        var cursor = Self.headerWords * 4
        let metaData = Data(bytes: raw + cursor, count: metaLength)
        cursor += Self.align4(metaLength)
        offStrings = cursor; cursor += (stringCount + 1) * 4
        offFreqs = cursor; cursor += wordCount * 4
        offFirstChild = cursor; cursor += nodeCount * 4
        offInfo = cursor; cursor += nodeCount * 4
        offWord = cursor; cursor += nodeCount * 4
        offCorrections = cursor; cursor += correctionCount * 8
        offBigrams = cursor; cursor += bigramCount * 12
        offBlob = cursor; cursor += blobLength
        guard cursor <= storage.length, nodeCount > 0 else { throw Self.corrupt("truncated") }
        meta = try JSONDecoder().decode(LexiconMeta.self, from: metaData)
    }

    convenience init(contentsOf url: URL) throws {
        let data = try NSData(contentsOf: url, options: .alwaysMapped)
        try self.init(storage: data)
    }

    convenience init(data: Data) throws {
        try self.init(storage: data as NSData)
    }

    // MARK: Raw access

    @inline(__always)
    private func u32(_ offset: Int, _ index: Int) -> UInt32 {
        base.loadUnaligned(fromByteOffset: offset + index * 4, as: UInt32.self)
    }

    @inline(__always) func frequency(ofWord id: Int) -> Int { Int(u32(offFreqs, id)) }
    @inline(__always) func firstChild(_ node: Int) -> Int { Int(u32(offFirstChild, node)) }
    @inline(__always) func childCount(_ node: Int) -> Int { Int(u32(offInfo, node) >> 16) }
    @inline(__always) func label(_ node: Int) -> UInt32 { u32(offInfo, node) & 0xFFFF }
    @inline(__always) func wordId(atNode node: Int) -> UInt32 { u32(offWord, node) }

    /// Highest word frequency in the subtree under `node`.
    func best(_ node: Int) -> Int {
        var n = node
        var result = 0
        while true {
            let w = wordId(atNode: n)
            if w != Self.noWord { result = max(result, frequency(ofWord: Int(w))) }
            guard childCount(n) > 0 else { return result }
            n = firstChild(n)
        }
    }

    private func stringRange(_ id: Int) -> (start: Int, count: Int) {
        let start = Int(u32(offStrings, id))
        let end = Int(u32(offStrings, id + 1))
        return (offBlob + start, end - start)
    }

    func string(_ id: Int) -> String {
        let r = stringRange(id)
        let buffer = UnsafeRawBufferPointer(start: base + r.start, count: r.count)
        return String(decoding: buffer, as: UTF8.self)
    }

    /// UTF-8 byte length of string `id` (cheap; no decoding).
    func byteLength(_ id: Int) -> Int { stringRange(id).count }

    /// memcmp-style compare of string `id` against `needle` bytes.
    private func compare(_ id: Int, _ needle: [UInt8]) -> Int {
        let r = stringRange(id)
        let n = min(r.count, needle.count)
        let c = needle.withUnsafeBytes { memcmp(base + r.start, $0.baseAddress!, n) }
        if c != 0 { return Int(c) }
        return r.count - needle.count
    }

    // MARK: Corrections / bigrams

    func correction(for key: String) -> String? {
        guard correctionCount > 0 else { return nil }
        let needle = Array(key.utf8)
        var lo = 0
        var hi = correctionCount
        while lo < hi {
            let mid = (lo + hi) / 2
            let c = compare(Int(u32(offCorrections, mid * 2)), needle)
            if c == 0 { return string(Int(u32(offCorrections, mid * 2 + 1))) }
            if c < 0 { lo = mid + 1 } else { hi = mid }
        }
        return nil
    }

    /// Bigram continuations of `previous`, highest count first.
    func bigrams(after previous: String) -> [(String, Int)] {
        guard bigramCount > 0 else { return [] }
        let needle = Array(previous.utf8)
        var lo = 0
        var hi = bigramCount
        while lo < hi {
            let mid = (lo + hi) / 2
            if compare(Int(u32(offBigrams, mid * 3)), needle) < 0 { lo = mid + 1 } else { hi = mid }
        }
        var out: [(String, Int)] = []
        var i = lo
        while i < bigramCount, compare(Int(u32(offBigrams, i * 3)), needle) == 0 {
            out.append((string(Int(u32(offBigrams, i * 3 + 1))), Int(u32(offBigrams, i * 3 + 2))))
            i += 1
        }
        return out
    }

    // MARK: Helpers

    static func align4(_ n: Int) -> Int { (n + 3) & ~3 }

    static func corrupt(_ why: String) -> NSError {
        NSError(domain: "UyghurLatinKit", code: 2, userInfo: [NSLocalizedDescriptionKey: "lexicon.bin: \(why)"])
    }

    /// Scalar sequence used as trie path for a lookup key.
    static func pathScalars(_ key: String) -> [UInt32]? {
        var out: [UInt32] = []
        out.reserveCapacity(key.unicodeScalars.count)
        let needsCompose = key.unicodeScalars.contains { $0.value >= 0x300 && $0.value < 0x370 }
        let source = needsCompose ? key.precomposedStringWithCanonicalMapping : key
        for s in source.unicodeScalars {
            guard s.value <= 0xFFFF else { return nil }
            out.append(s.value)
        }
        return out
    }
}

// MARK: - Builder (JSON fallback; mirrors tools/compile_lexicon_bin.py)

enum LexiconBinaryBuilder {
    static func build(
        meta: LexiconMeta,
        words rawWords: [(String, Int)],
        corrections: [String: String],
        bigrams rawBigrams: [(String, String, Int)]
    ) throws -> Data {
        // Lexicon words: normalized, deduped (max freq), sorted by freq desc then bytes.
        var freqByKey: [String: Int] = [:]
        for (w, f) in rawWords {
            let key = ULYNormalizer.lookupKey(w).precomposedStringWithCanonicalMapping
            guard !key.isEmpty, LexiconBinary.pathScalars(key) != nil else { continue }
            freqByKey[key] = max(freqByKey[key] ?? 0, f)
        }
        let words = freqByKey.sorted {
            $0.value != $1.value ? $0.value > $1.value : Array($0.key.utf8).lexicographicallyPrecedes(Array($1.key.utf8))
        }
        var strings = words.map(\.key)
        var idOf: [String: Int] = [:]
        for (i, s) in strings.enumerated() { idOf[s] = i }
        func intern(_ s: String) -> Int {
            if let id = idOf[s] { return id }
            idOf[s] = strings.count
            strings.append(s)
            return strings.count - 1
        }

        var correctionPairs: [(Int, Int)] = []
        for (wrong, right) in corrections {
            let w = ULYNormalizer.lookupKey(wrong).precomposedStringWithCanonicalMapping
            let r = ULYNormalizer.lookupKey(right).precomposedStringWithCanonicalMapping
            guard !w.isEmpty, !r.isEmpty else { continue }
            correctionPairs.append((intern(w), intern(r)))
        }
        var bigramTriples: [(Int, Int, Int)] = []
        for (a, b, c) in rawBigrams {
            let ka = ULYNormalizer.lookupKey(a).precomposedStringWithCanonicalMapping
            let kb = ULYNormalizer.lookupKey(b).precomposedStringWithCanonicalMapping
            guard !ka.isEmpty, !kb.isEmpty else { continue }
            bigramTriples.append((intern(ka), intern(kb), c))
        }
        let bytes = strings.map { Array($0.utf8) }
        correctionPairs.sort { bytes[$0.0].lexicographicallyPrecedes(bytes[$1.0]) }
        // Dedupe corrections by wrong key (keep first).
        var dedupedCorrections: [(Int, Int)] = []
        for p in correctionPairs where dedupedCorrections.last.map({ bytes[$0.0] != bytes[p.0] }) ?? true {
            dedupedCorrections.append(p)
        }
        bigramTriples.sort {
            if bytes[$0.0] != bytes[$1.0] { return bytes[$0.0].lexicographicallyPrecedes(bytes[$1.0]) }
            if $0.2 != $1.2 { return $0.2 > $1.2 }
            return bytes[$0.1].lexicographicallyPrecedes(bytes[$1.1])
        }

        // Temporary trie.
        var children: [[UInt32: Int]] = [[:]]
        var nodeWord: [UInt32] = [LexiconBinary.noWord]
        var nodeBest: [Int] = [0]
        for (id, entry) in words.enumerated() {
            var node = 0
            nodeBest[0] = max(nodeBest[0], entry.value)
            for s in LexiconBinary.pathScalars(entry.key)! {
                if let next = children[node][s] {
                    node = next
                } else {
                    children.append([:])
                    nodeWord.append(LexiconBinary.noWord)
                    nodeBest.append(0)
                    children[node][s] = children.count - 1
                    node = children.count - 1
                }
                nodeBest[node] = max(nodeBest[node], entry.value)
            }
            nodeWord[node] = UInt32(id)
        }

        // BFS layout; children ordered by best desc, then label asc.
        let n = children.count
        var order: [Int] = [0]
        var labelOf = [UInt32](repeating: 0, count: n)
        var firstChild = [UInt32](repeating: 0, count: n)
        var head = 0
        while head < order.count {
            let old = order[head]
            head += 1
            let kids = children[old].sorted {
                nodeBest[$0.value] != nodeBest[$1.value] ? nodeBest[$0.value] > nodeBest[$1.value] : $0.key < $1.key
            }
            firstChild[old] = UInt32(order.count)
            for (label, child) in kids {
                labelOf[child] = label
                order.append(child)
            }
        }
        var out = Data()
        func put(_ v: UInt32) { withUnsafeBytes(of: v.littleEndian) { out.append(contentsOf: $0) } }
        func pad() { while out.count % 4 != 0 { out.append(0) } }

        let metaData = try JSONEncoder().encode(meta)
        var blob: [UInt8] = []
        var offsets: [UInt32] = [0]
        for b in bytes {
            blob.append(contentsOf: b)
            offsets.append(UInt32(blob.count))
        }

        out.append(contentsOf: LexiconBinary.magic)
        for v in [
            LexiconBinary.formatVersion, UInt32(metaData.count), UInt32(words.count), UInt32(strings.count),
            UInt32(n), UInt32(dedupedCorrections.count), UInt32(bigramTriples.count), UInt32(blob.count), 0,
        ] { put(v) }
        out.append(metaData)
        pad()
        offsets.forEach(put)
        words.forEach { put(UInt32(clamping: $0.value)) }
        for old in order { put(firstChild[old]) }
        for old in order { put(labelOf[old] | (UInt32(children[old].count) << 16)) }
        for old in order { put(nodeWord[old]) }
        for (w, r) in dedupedCorrections { put(UInt32(w)); put(UInt32(r)) }
        for (a, b, c) in bigramTriples { put(UInt32(a)); put(UInt32(b)); put(UInt32(clamping: c)) }
        out.append(contentsOf: blob)
        return out
    }
}
