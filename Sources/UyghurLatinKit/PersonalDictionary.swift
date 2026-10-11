import Foundation
import Security

/// Snapshot used for export / import / share of personal learning data,
/// and as the on-disk format (`personalV2` blob).
public struct PersonalDictionarySnapshot: Codable, Equatable, Sendable {
    public var version: Int
    public var words: [String: Int]
    /// Bigram keys use `\u{1f}` as separator: `"prev\u{1f}next"`.
    public var bigrams: [String: Int]
    /// Optional trigram keys: `"w1\u{1f}w2\u{1f}w3"`.
    public var trigrams: [String: Int]
    /// Words learned specifically as sentence openers.
    public var openers: [String: Int]

    public init(
        version: Int = 1,
        words: [String: Int] = [:],
        bigrams: [String: Int] = [:],
        trigrams: [String: Int] = [:],
        openers: [String: Int] = [:]
    ) {
        self.version = version
        self.words = words
        self.bigrams = bigrams
        self.trigrams = trigrams
        self.openers = openers
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version = try c.decodeIfPresent(Int.self, forKey: .version) ?? 1
        words = try c.decodeIfPresent([String: Int].self, forKey: .words) ?? [:]
        bigrams = try c.decodeIfPresent([String: Int].self, forKey: .bigrams) ?? [:]
        trigrams = try c.decodeIfPresent([String: Int].self, forKey: .trigrams) ?? [:]
        openers = try c.decodeIfPresent([String: Int].self, forKey: .openers) ?? [:]
    }
}

/// Storage for the personal dictionary blob plus read/delete access to the v1 layout
/// (four separate dictionaries) for one-time migration.
protocol PersonalDictionaryBackend: AnyObject {
    func readBlob() -> Data?
    func writeBlob(_ data: Data) -> Bool
    func readV1(_ name: String) -> [String: Int]?
    func deleteV1(_ name: String)
}

/// Words (and n-grams) learned on-device.
///
/// Mutations only touch memory and mark the dictionary dirty. With a `flushQueue`, writes are
/// debounced onto that queue (callers must mutate on the same queue); without one, every
/// mutation is written immediately (host app / tests).
public final class PersonalDictionary {
    static let v1Names = ["words", "bigrams", "trigrams", "openers"]
    static let separator: Character = "\u{1f}"
    private static let topCapacity = 24
    private static let decayEvery = 50

    private let backend: PersonalDictionaryBackend?
    private let flushQueue: DispatchQueue?
    private let flushDelay: TimeInterval

    private var words: [String: Int] = [:]
    private var openers: [String: Int] = [:]
    /// prev → next → score
    private var bigramsByPrev: [String: [String: Int]] = [:]
    /// "w1\u{1f}w2" → next → score
    private var trigramsByPrefix: [String: [String: Int]] = [:]

    /// Sorted word keys for binary-search prefix lookup; rebuilt lazily after removals.
    private var sortedKeysStorage: [String]?
    /// Highest scoring words, maintained on write.
    private var topWords: [(String, Int)] = []

    private var dirty = false
    private var flushScheduled = false
    private var learnsSinceDecay = 0

    /// Number of times the dictionary was written to storage (for tests / diagnostics).
    public private(set) var persistCount = 0

    /// - Parameters:
    ///   - defaults: storage when `useKeychain` is false (tests); also a v1 migration source.
    ///     `nil` with `useKeychain == false` keeps everything in memory.
    ///   - useKeychain: when true (default), store a single blob in the shared Keychain group so
    ///     the host app and keyboard see the same data.
    ///   - flushQueue: queue all mutations happen on; enables debounced background writes.
    ///   - flushDelay: debounce interval for `flushQueue` writes.
    public init(
        defaults: UserDefaults? = nil,
        useKeychain: Bool = true,
        flushQueue: DispatchQueue? = nil,
        flushDelay: TimeInterval = 1.5
    ) {
        if useKeychain {
            backend = KeychainPersonalBackend(legacyDefaults: defaults ?? .standard)
        } else if let defaults {
            backend = DefaultsPersonalBackend(defaults: defaults)
        } else {
            backend = nil
        }
        self.flushQueue = flushQueue
        self.flushDelay = flushDelay
        load()
    }

    // MARK: - Mutations

    public func learn(_ word: String, boost: Int = 1) {
        let key = ULYNormalizer.lookupKey(word)
        guard !key.isEmpty else { return }
        bumpWord(key, by: boost)
        learnsSinceDecay += 1
        scheduleFlush()
    }

    public func add(_ word: String) {
        learn(word, boost: 100)
    }

    public func remove(_ word: String) {
        let key = ULYNormalizer.lookupKey(word)
        guard words.removeValue(forKey: key) != nil else { return }
        openers.removeValue(forKey: key)
        sortedKeysStorage = nil
        rebuildTopWords()
        scheduleFlush()
    }

    public func learnBigram(previous: String, word: String, boost: Int = 1) {
        let a = ULYNormalizer.lookupKey(previous)
        let b = ULYNormalizer.lookupKey(word)
        guard !a.isEmpty, !b.isEmpty else { return }
        bigramsByPrev[a, default: [:]][b, default: 0] += boost
        scheduleFlush()
    }

    public func learnTrigram(w1: String, w2: String, w3: String, boost: Int = 1) {
        let a = ULYNormalizer.lookupKey(w1)
        let b = ULYNormalizer.lookupKey(w2)
        let c = ULYNormalizer.lookupKey(w3)
        guard !a.isEmpty, !b.isEmpty, !c.isEmpty else { return }
        trigramsByPrefix["\(a)\(Self.separator)\(b)", default: [:]][c, default: 0] += boost
        scheduleFlush()
    }

    /// Stronger signal: word used to start a sentence / after punctuation.
    public func learnOpener(_ word: String, boost: Int = 18) {
        let key = ULYNormalizer.lookupKey(word)
        guard key.count >= 2 else { return }
        openers[key, default: 0] += boost
        // Also bump general personal lexicon lightly so prefix completion benefits.
        bumpWord(key, by: max(1, boost / 4))
        scheduleFlush()
    }

    public func clear() {
        words.removeAll()
        bigramsByPrev.removeAll()
        trigramsByPrefix.removeAll()
        openers.removeAll()
        sortedKeysStorage = nil
        topWords.removeAll()
        scheduleFlush()
    }

    // MARK: - Queries

    /// Ranked personal sentence openers (high score first).
    public func rankedOpeners(limit: Int) -> [(String, Int)] {
        guard limit > 0 else { return [] }
        return openers
            .map { ($0.key, $0.value + 120_000) }
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map { $0 }
    }

    public var openerCount: Int { openers.count }

    public func contains(_ word: String) -> Bool {
        words[ULYNormalizer.lookupKey(word)] != nil
    }

    /// Most used personal words (maintained incrementally).
    public func topWords(limit: Int) -> [(String, Int)] {
        Array(topWords.prefix(limit))
    }

    public func rankedPrefix(_ prefix: String, limit: Int) -> [(String, Int)] {
        let p = ULYNormalizer.lookupKey(prefix)
        guard !p.isEmpty, limit > 0 else { return [] }
        let keys = sortedKeys
        var lo = 0
        var hi = keys.count
        while lo < hi {
            let mid = (lo + hi) / 2
            if keys[mid] < p { lo = mid + 1 } else { hi = mid }
        }
        var out: [(String, Int)] = []
        var i = lo
        while i < keys.count, keys[i].hasPrefix(p) {
            out.append((keys[i], (words[keys[i]] ?? 0) + 100_000))
            i += 1
        }
        out.sort { $0.1 > $1.1 }
        return Array(out.prefix(limit))
    }

    /// Next words after `previous`, using trigrams (when `beforePrevious` set) then bigrams.
    public func nextWords(after previous: String?, beforePrevious: String? = nil, limit: Int) -> [(String, Int)] {
        guard let previous, !previous.isEmpty, limit > 0 else { return [] }
        let prev = ULYNormalizer.lookupKey(previous)
        var scores: [String: Int] = [:]

        if let beforePrevious, !beforePrevious.isEmpty {
            let prev2 = ULYNormalizer.lookupKey(beforePrevious)
            for (next, count) in trigramsByPrefix["\(prev2)\(Self.separator)\(prev)"] ?? [:] {
                scores[next] = count + 80_000
            }
        }
        for (next, count) in bigramsByPrev[prev] ?? [:] {
            if let existing = scores[next] {
                scores[next] = existing + count
            } else {
                scores[next] = count + 50_000
            }
        }
        return scores
            .map { ($0.key, $0.value) }
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map { $0 }
    }

    public var allWords: [String] { sortedKeys }

    public var wordScores: [String: Int] { words }

    public var wordCount: Int { words.count }

    // MARK: - Export / import

    public func snapshot() -> PersonalDictionarySnapshot {
        var flatBigrams: [String: Int] = [:]
        for (prev, nexts) in bigramsByPrev {
            for (next, score) in nexts {
                flatBigrams["\(prev)\(Self.separator)\(next)"] = score
            }
        }
        var flatTrigrams: [String: Int] = [:]
        for (prefix, nexts) in trigramsByPrefix {
            for (next, score) in nexts {
                flatTrigrams["\(prefix)\(Self.separator)\(next)"] = score
            }
        }
        return PersonalDictionarySnapshot(
            version: 2,
            words: words,
            bigrams: flatBigrams,
            trigrams: flatTrigrams,
            openers: openers
        )
    }

    public func exportJSONData() throws -> Data {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try enc.encode(snapshot())
    }

    /// Merge imported snapshot: scores take `max(existing, imported)`.
    @discardableResult
    public func mergeImport(from data: Data) throws -> Int {
        let snap = try JSONDecoder().decode(PersonalDictionarySnapshot.self, from: data)
        return mergeImport(snapshot: snap)
    }

    @discardableResult
    public func mergeImport(snapshot snap: PersonalDictionarySnapshot) -> Int {
        let changed = merge(snap)
        sortedKeysStorage = nil
        rebuildTopWords()
        scheduleFlush()
        return changed
    }

    // MARK: - Persistence

    /// Write pending changes now (call from the flush queue when one is configured).
    public func flush() {
        flushScheduled = false
        guard dirty else { return }
        if learnsSinceDecay >= Self.decayEvery {
            learnsSinceDecay = 0
            softDecayWords()
        }
        dirty = false
        guard let backend,
              let data = try? JSONEncoder().encode(snapshot())
        else { return }
        if backend.writeBlob(data) {
            persistCount += 1
        } else {
            dirty = true
        }
    }

    /// Re-read storage (e.g. after the host app edited the dictionary). Pending changes are
    /// written first so nothing learned in this session is lost.
    public func reloadFromStorage() {
        flush()
        load()
    }

    private func scheduleFlush() {
        dirty = true
        guard let flushQueue else {
            flush()
            return
        }
        guard !flushScheduled else { return }
        flushScheduled = true
        flushQueue.asyncAfter(deadline: .now() + flushDelay) { [weak self] in
            self?.flush()
        }
    }

    private func load() {
        words.removeAll()
        bigramsByPrev.removeAll()
        trigramsByPrefix.removeAll()
        openers.removeAll()
        sortedKeysStorage = nil

        guard let backend else {
            rebuildTopWords()
            return
        }
        if let data = backend.readBlob(),
           let snap = try? JSONDecoder().decode(PersonalDictionarySnapshot.self, from: data) {
            _ = merge(snap)
        } else {
            migrateV1(from: backend)
        }
        rebuildTopWords()
    }

    private func migrateV1(from backend: PersonalDictionaryBackend) {
        var snap = PersonalDictionarySnapshot(version: 2)
        var found = false
        for name in Self.v1Names {
            guard let dict = backend.readV1(name) else { continue }
            found = true
            switch name {
            case "words": snap.words = dict
            case "bigrams": snap.bigrams = dict
            case "trigrams": snap.trigrams = dict
            default: snap.openers = dict
            }
        }
        guard found else { return }
        _ = merge(snap)
        if let data = try? JSONEncoder().encode(snapshot()), backend.writeBlob(data) {
            persistCount += 1
            for name in Self.v1Names { backend.deleteV1(name) }
        }
    }

    @discardableResult
    private func merge(_ snap: PersonalDictionarySnapshot) -> Int {
        var changed = 0
        for (w, score) in snap.words {
            let key = ULYNormalizer.lookupKey(w)
            guard !key.isEmpty else { continue }
            let before = words[key] ?? 0
            let next = max(before, score)
            if next != before { changed += 1 }
            words[key] = next
        }
        for (k, score) in snap.bigrams {
            let parts = k.split(separator: Self.separator, omittingEmptySubsequences: false)
            guard parts.count == 2, !parts[0].isEmpty, !parts[1].isEmpty else { continue }
            let before = bigramsByPrev[String(parts[0])]?[String(parts[1])] ?? 0
            if before == 0 { changed += 1 }
            bigramsByPrev[String(parts[0]), default: [:]][String(parts[1])] = max(before, score)
        }
        for (k, score) in snap.trigrams {
            let parts = k.split(separator: Self.separator, omittingEmptySubsequences: false)
            guard parts.count == 3, parts.allSatisfy({ !$0.isEmpty }) else { continue }
            let prefix = "\(parts[0])\(Self.separator)\(parts[1])"
            let before = trigramsByPrefix[prefix]?[String(parts[2])] ?? 0
            if before == 0 { changed += 1 }
            trigramsByPrefix[prefix, default: [:]][String(parts[2])] = max(before, score)
        }
        for (w, score) in snap.openers {
            let key = ULYNormalizer.lookupKey(w)
            guard !key.isEmpty else { continue }
            let before = openers[key] ?? 0
            let next = max(before, score)
            if next != before { changed += 1 }
            openers[key] = next
        }
        return changed
    }

    /// Soft-decay rarely used personal words so ranking stays fresh.
    /// Only words below 20 decay, so explicitly added words (100+) stay.
    private func softDecayWords() {
        guard words.count > 400 else { return }
        var removedAny = false
        for (k, v) in words where v > 0 && v < 20 {
            if v == 1 {
                words.removeValue(forKey: k)
                removedAny = true
            } else {
                words[k] = v - 1
            }
        }
        if removedAny { sortedKeysStorage = nil }
        rebuildTopWords()
    }

    // MARK: - Indexes

    private var sortedKeys: [String] {
        if let sortedKeysStorage { return sortedKeysStorage }
        let keys = words.keys.sorted()
        sortedKeysStorage = keys
        return keys
    }

    private func bumpWord(_ key: String, by boost: Int) {
        let isNew = words[key] == nil
        let score = (words[key] ?? 0) + boost
        words[key] = score
        if isNew, sortedKeysStorage != nil {
            var lo = 0
            var hi = sortedKeysStorage!.count
            while lo < hi {
                let mid = (lo + hi) / 2
                if sortedKeysStorage![mid] < key { lo = mid + 1 } else { hi = mid }
            }
            sortedKeysStorage!.insert(key, at: lo)
        }
        updateTopWords(key, score: score)
    }

    private func updateTopWords(_ key: String, score: Int) {
        if let idx = topWords.firstIndex(where: { $0.0 == key }) {
            topWords[idx].1 = score
        } else if topWords.count < Self.topCapacity {
            topWords.append((key, score))
        } else if let last = topWords.last, score > last.1 {
            topWords[topWords.count - 1] = (key, score)
        } else {
            return
        }
        topWords.sort { $0.1 > $1.1 }
    }

    private func rebuildTopWords() {
        topWords = words
            .sorted { $0.value > $1.value }
            .prefix(Self.topCapacity)
            .map { ($0.key, $0.value) }
    }
}

// MARK: - Backends

/// Single JSON blob in the shared Keychain access group.
final class KeychainPersonalBackend: PersonalDictionaryBackend {
    private let service = "com.esqer.uyghurlatin.personal"
    private let blobAccount = "personalV2"
    /// Matches DEVELOPMENT_TEAM + shared keychain group in iOS entitlements.
    private let accessGroup = "QCZ38FF75B.com.esqer.uyghurlatin.shared"
    private let legacyDefaults: UserDefaults

    init(legacyDefaults: UserDefaults) {
        self.legacyDefaults = legacyDefaults
    }

    func readBlob() -> Data? {
        read(account: blobAccount, group: accessGroup)
    }

    func writeBlob(_ data: Data) -> Bool {
        let query = baseQuery(account: blobAccount, group: accessGroup)
        let update: [String: Any] = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, update as CFDictionary)
        if status == errSecSuccess { return true }
        guard status == errSecItemNotFound else { return false }
        var add = query
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        return SecItemAdd(add as CFDictionary, nil) == errSecSuccess
    }

    func readV1(_ name: String) -> [String: Int]? {
        if let data = read(account: name, group: accessGroup) ?? read(account: name, group: nil),
           let dict = try? JSONDecoder().decode([String: Int].self, from: data) {
            return dict
        }
        return legacyDefaults.dictionary(forKey: Self.defaultsKey(name)) as? [String: Int]
    }

    func deleteV1(_ name: String) {
        SecItemDelete(baseQuery(account: name, group: accessGroup) as CFDictionary)
        SecItemDelete(baseQuery(account: name, group: nil) as CFDictionary)
        legacyDefaults.removeObject(forKey: Self.defaultsKey(name))
    }

    static func defaultsKey(_ name: String) -> String {
        "uyghurlatin.personal\(name.prefix(1).uppercased())\(name.dropFirst())"
    }

    private func baseQuery(account: String, group: String?) -> [String: Any] {
        var q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        if let group { q[kSecAttrAccessGroup as String] = group }
        return q
    }

    private func read(account: String, group: String?) -> Data? {
        var q = baseQuery(account: account, group: group)
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(q as CFDictionary, &item) == errSecSuccess else { return nil }
        return item as? Data
    }
}

/// Blob + v1 dictionaries in an injected `UserDefaults` (tests, previews).
final class DefaultsPersonalBackend: PersonalDictionaryBackend {
    static let blobKey = "uyghurlatin.personalV2"
    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    func readBlob() -> Data? {
        defaults.data(forKey: Self.blobKey)
    }

    func writeBlob(_ data: Data) -> Bool {
        defaults.set(data, forKey: Self.blobKey)
        return true
    }

    func readV1(_ name: String) -> [String: Int]? {
        defaults.dictionary(forKey: KeychainPersonalBackend.defaultsKey(name)) as? [String: Int]
    }

    func deleteV1(_ name: String) {
        defaults.removeObject(forKey: KeychainPersonalBackend.defaultsKey(name))
    }
}
