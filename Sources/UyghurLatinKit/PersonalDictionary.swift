import Foundation
import Security

/// Snapshot used for export / import / share of personal learning data.
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

/// Words (and n-grams) learned on-device.
/// Persists via Keychain access group when available so the host app and keyboard share data;
/// falls back to UserDefaults (and migrates legacy UserDefaults entries).
public final class PersonalDictionary {
    private let defaults: UserDefaults
    private let useKeychain: Bool
    private let wordsKey = "uyghurlatin.personalWords"
    private let bigramsKey = "uyghurlatin.personalBigrams"
    private let trigramsKey = "uyghurlatin.personalTrigrams"
    private let openersKey = "uyghurlatin.personalOpeners"
    private let keychainService = "com.esqer.uyghurlatin.personal"
    private let keychainWordsAccount = "words"
    private let keychainBigramsAccount = "bigrams"
    private let keychainTrigramsAccount = "trigrams"
    private let keychainOpenersAccount = "openers"
    /// Matches DEVELOPMENT_TEAM + shared keychain group in iOS entitlements.
    private let keychainAccessGroup = "QCZ38FF75B.com.esqer.uyghurlatin.shared"

    private var words: [String: Int]
    private var bigrams: [String: Int]
    private var trigrams: [String: Int]
    private var openers: [String: Int]

    /// - Parameters:
    ///   - defaults: persistence for words/n-grams (and migration source).
    ///   - useKeychain: when true (default), sync via shared Keychain for host↔keyboard.
    ///     Tests should pass `false` with a private `UserDefaults` suite.
    public init(defaults: UserDefaults = .standard, useKeychain: Bool = true) {
        self.defaults = defaults
        self.useKeychain = useKeychain

        self.words = Self.loadScores(
            defaults: defaults,
            defaultsKey: "uyghurlatin.personalWords",
            useKeychain: useKeychain,
            account: "words",
            accessGroup: "QCZ38FF75B.com.esqer.uyghurlatin.shared"
        )
        self.bigrams = Self.loadScores(
            defaults: defaults,
            defaultsKey: "uyghurlatin.personalBigrams",
            useKeychain: useKeychain,
            account: "bigrams",
            accessGroup: "QCZ38FF75B.com.esqer.uyghurlatin.shared"
        )
        self.trigrams = Self.loadScores(
            defaults: defaults,
            defaultsKey: "uyghurlatin.personalTrigrams",
            useKeychain: useKeychain,
            account: "trigrams",
            accessGroup: "QCZ38FF75B.com.esqer.uyghurlatin.shared"
        )
        self.openers = Self.loadScores(
            defaults: defaults,
            defaultsKey: "uyghurlatin.personalOpeners",
            useKeychain: useKeychain,
            account: "openers",
            accessGroup: "QCZ38FF75B.com.esqer.uyghurlatin.shared"
        )
    }

    public func learn(_ word: String, boost: Int = 1) {
        let key = ULYNormalizer.lookupKey(word)
        guard !key.isEmpty else { return }
        softDecayWordsIfNeeded()
        words[key, default: 0] += boost
        persistWords()
    }

    public func add(_ word: String) {
        learn(word, boost: 100)
    }

    public func remove(_ word: String) {
        let key = ULYNormalizer.lookupKey(word)
        guard words.removeValue(forKey: key) != nil else { return }
        persistWords()
    }

    public func learnBigram(previous: String, word: String, boost: Int = 1) {
        let a = ULYNormalizer.lookupKey(previous)
        let b = ULYNormalizer.lookupKey(word)
        guard !a.isEmpty, !b.isEmpty else { return }
        let key = "\(a)\u{1f}\(b)"
        bigrams[key, default: 0] += boost
        persistBigrams()
    }

    public func learnTrigram(w1: String, w2: String, w3: String, boost: Int = 1) {
        let a = ULYNormalizer.lookupKey(w1)
        let b = ULYNormalizer.lookupKey(w2)
        let c = ULYNormalizer.lookupKey(w3)
        guard !a.isEmpty, !b.isEmpty, !c.isEmpty else { return }
        let key = "\(a)\u{1f}\(b)\u{1f}\(c)"
        trigrams[key, default: 0] += boost
        persistTrigrams()
    }

    /// Stronger signal: word used to start a sentence / after punctuation.
    public func learnOpener(_ word: String, boost: Int = 18) {
        let key = ULYNormalizer.lookupKey(word)
        guard key.count >= 2 else { return }
        openers[key, default: 0] += boost
        // Also bump general personal lexicon lightly so prefix completion benefits.
        words[key, default: 0] += max(1, boost / 4)
        persistOpeners()
        persistWords()
    }

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

    public func clear() {
        words.removeAll()
        bigrams.removeAll()
        trigrams.removeAll()
        openers.removeAll()
        persistWords()
        persistBigrams()
        persistTrigrams()
        persistOpeners()
    }

    public func contains(_ word: String) -> Bool {
        words[ULYNormalizer.lookupKey(word)] != nil
    }

    public func rankedPrefix(_ prefix: String, limit: Int) -> [(String, Int)] {
        let p = ULYNormalizer.lookupKey(prefix)
        guard !p.isEmpty else { return [] }
        return words
            .filter { $0.key.hasPrefix(p) }
            .map { ($0.key, $0.value + 100_000) }
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map { $0 }
    }

    /// Next words after `previous`, using trigrams (when `beforePrevious` set) then bigrams.
    public func nextWords(after previous: String?, beforePrevious: String? = nil, limit: Int) -> [(String, Int)] {
        guard let previous, !previous.isEmpty, limit > 0 else { return [] }
        let prev = ULYNormalizer.lookupKey(previous)
        var ranked: [(String, Int)] = []
        var seen = Set<String>()

        if let beforePrevious, !beforePrevious.isEmpty {
            let prev2 = ULYNormalizer.lookupKey(beforePrevious)
            let tNeedle = "\(prev2)\u{1f}\(prev)\u{1f}"
            for (key, count) in trigrams where key.hasPrefix(tNeedle) {
                let next = String(key.dropFirst(tNeedle.count))
                guard !next.isEmpty, seen.insert(next).inserted else { continue }
                ranked.append((next, count + 80_000))
            }
        }

        let needle = "\(prev)\u{1f}"
        for (key, count) in bigrams where key.hasPrefix(needle) {
            let next = String(key.dropFirst(needle.count))
            guard !next.isEmpty else { continue }
            if seen.insert(next).inserted {
                ranked.append((next, count + 50_000))
            } else if let idx = ranked.firstIndex(where: { $0.0 == next }) {
                ranked[idx].1 += count
            }
        }

        ranked.sort { $0.1 > $1.1 }
        return Array(ranked.prefix(limit))
    }

    public var allWords: [String] {
        words.keys.sorted()
    }

    public var wordScores: [String: Int] {
        words
    }

    public var wordCount: Int {
        words.count
    }

    // MARK: - Export / import

    public func snapshot() -> PersonalDictionarySnapshot {
        PersonalDictionarySnapshot(
            version: 2,
            words: words,
            bigrams: bigrams,
            trigrams: trigrams,
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
        var addedOrBoosted = 0
        for (w, score) in snap.words {
            let key = ULYNormalizer.lookupKey(w)
            guard !key.isEmpty else { continue }
            let before = words[key] ?? 0
            let next = max(before, score)
            if next != before { addedOrBoosted += 1 }
            words[key] = next
        }
        for (k, score) in snap.bigrams {
            let before = bigrams[k] ?? 0
            bigrams[k] = max(before, score)
            if before == 0 { addedOrBoosted += 1 }
        }
        for (k, score) in snap.trigrams {
            let before = trigrams[k] ?? 0
            trigrams[k] = max(before, score)
            if before == 0 { addedOrBoosted += 1 }
        }
        for (w, score) in snap.openers {
            let key = ULYNormalizer.lookupKey(w)
            guard !key.isEmpty else { continue }
            let before = openers[key] ?? 0
            let next = max(before, score)
            if next != before { addedOrBoosted += 1 }
            openers[key] = next
        }
        persistWords()
        persistBigrams()
        persistTrigrams()
        persistOpeners()
        return addedOrBoosted
    }

    // MARK: - Persistence

    /// Soft-decay rarely used personal words so ranking stays fresh.
    private func softDecayWordsIfNeeded() {
        guard words.count > 400 else { return }
        // Every ~50 learns when large: shave 1 off scores below 20 that aren't pinned (add=100+).
        var changed = false
        for (k, v) in words where v > 0 && v < 20 {
            words[k] = v - 1
            if words[k] == 0 { words.removeValue(forKey: k) }
            changed = true
        }
        if changed { /* caller persists via learn */ }
    }

    private func persistWords() {
        defaults.set(words, forKey: wordsKey)
        if useKeychain {
            Self.writeKeychainDict(words, service: keychainService, account: keychainWordsAccount, accessGroup: keychainAccessGroup)
        }
    }

    private func persistBigrams() {
        defaults.set(bigrams, forKey: bigramsKey)
        if useKeychain {
            Self.writeKeychainDict(bigrams, service: keychainService, account: keychainBigramsAccount, accessGroup: keychainAccessGroup)
        }
    }

    private func persistTrigrams() {
        defaults.set(trigrams, forKey: trigramsKey)
        if useKeychain {
            Self.writeKeychainDict(trigrams, service: keychainService, account: keychainTrigramsAccount, accessGroup: keychainAccessGroup)
        }
    }

    private func persistOpeners() {
        defaults.set(openers, forKey: openersKey)
        if useKeychain {
            Self.writeKeychainDict(openers, service: keychainService, account: keychainOpenersAccount, accessGroup: keychainAccessGroup)
        }
    }

    private static func loadScores(
        defaults: UserDefaults,
        defaultsKey: String,
        useKeychain: Bool,
        account: String,
        accessGroup: String
    ) -> [String: Int] {
        if useKeychain,
           let kc = readKeychainDict(
            service: "com.esqer.uyghurlatin.personal",
            account: account,
            accessGroup: accessGroup
           ) {
            return kc
        }
        if let saved = defaults.dictionary(forKey: defaultsKey) as? [String: Int] {
            if useKeychain {
                writeKeychainDict(
                    saved,
                    service: "com.esqer.uyghurlatin.personal",
                    account: account,
                    accessGroup: accessGroup
                )
            }
            return saved
        }
        return [:]
    }

    private static func readKeychainDict(service: String, account: String, accessGroup: String) -> [String: Int]? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        query[kSecAttrAccessGroup as String] = accessGroup
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return (try? JSONDecoder().decode([String: Int].self, from: data))
    }

    @discardableResult
    private static func writeKeychainDict(
        _ dict: [String: Int],
        service: String,
        account: String,
        accessGroup: String
    ) -> Bool {
        guard let data = try? JSONEncoder().encode(dict) else { return false }
        var base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        base[kSecAttrAccessGroup as String] = accessGroup
        SecItemDelete(base as CFDictionary)
        var legacy = base
        legacy.removeValue(forKey: kSecAttrAccessGroup as String)
        SecItemDelete(legacy as CFDictionary)
        var add = base
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        return SecItemAdd(add as CFDictionary, nil) == errSecSuccess
    }
}
