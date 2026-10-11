import Foundation
import Security

/// Built-in offline scenarios for sentence-start suggestions.
public enum SuggestionScenario: String, CaseIterable, Codable, Sendable, Identifiable {
    case general
    case greeting
    case chat
    case writing

    public var id: String { rawValue }

    /// Curated ULY openers for this scenario (offline, bundled).
    public var bundledStarters: [String] {
        switch self {
        case .general:
            return [
                "salam", "men", "bu", "u", "biz", "siz", "ular", "bügün",
                "yaxshi", "shu", "bir", "emma", "lekin", "we", "qandaq",
            ]
        case .greeting:
            return [
                "salam", "yaxshimusiz", "essalamu'eleykum", "yaxshi", "rehmet",
                "kechürüng", "xosh", "qandaq", "ehwallar", "bügün", "hawa",
                "men", "siz", "biz",
            ]
        case .chat:
            return [
                "he'e", "yaq", "bolidu", "qandaq", "nime", "emishu", "toghrimu",
                "men", "sen", "u", "bu", "shu", "andaq", "undaq", "yaxshi",
                "chüshendim", "saqla", "kel",
            ]
        case .writing:
            return [
                "birinchi", "ikkinchi", "shuñdin", "emma", "lekin", "shunga",
                "mesilen", "umumiy", "asasiy", "bu", "u", "biz", "dölet",
                "til", "yeziq", "tarix", "medeniyet",
            ]
        }
    }
}

/// Scenario + custom starters, shared host↔keyboard via Keychain (offline only).
public final class StarterPreferences {
    private let useKeychain: Bool
    private let defaults: UserDefaults
    private let defaultsKey = "uyghurlatin.starterPrefs"
    private let keychainService = "com.esqer.uyghurlatin.prefs"
    private let keychainAccount = "starterPrefs"
    private let accessGroup = "QCZ38FF75B.com.esqer.uyghurlatin.shared"

    public private(set) var scenario: SuggestionScenario
    /// Extra openers the user pinned (always merged ahead of scenario list).
    public private(set) var customStarters: [String]

    public struct Snapshot: Codable, Equatable, Sendable {
        public var scenario: String
        public var customStarters: [String]

        public init(scenario: String = SuggestionScenario.general.rawValue, customStarters: [String] = []) {
            self.scenario = scenario
            self.customStarters = customStarters
        }
    }

    public init(defaults: UserDefaults = .standard, useKeychain: Bool = true) {
        self.defaults = defaults
        self.useKeychain = useKeychain
        if let snap = Self.load(defaults: defaults, useKeychain: useKeychain) {
            self.scenario = SuggestionScenario(rawValue: snap.scenario) ?? .general
            self.customStarters = snap.customStarters.map { ULYNormalizer.lookupKey($0) }.filter { !$0.isEmpty }
        } else {
            self.scenario = .general
            self.customStarters = []
        }
    }

    /// Active starter list: custom pins first, then scenario bundled words (deduped).
    public func activeStarters() -> [String] {
        var out: [String] = []
        var seen = Set<String>()
        for w in customStarters + scenario.bundledStarters {
            let k = ULYNormalizer.lookupKey(w)
            guard !k.isEmpty, seen.insert(k).inserted else { continue }
            out.append(k)
        }
        return out
    }

    public func setScenario(_ scenario: SuggestionScenario) {
        self.scenario = scenario
        persist()
    }

    public func setCustomStarters(_ words: [String]) {
        var seen = Set<String>()
        customStarters = words.compactMap { raw in
            let k = ULYNormalizer.lookupKey(raw)
            guard k.count >= 2, seen.insert(k).inserted else { return nil }
            return k
        }
        persist()
    }

    public func addCustomStarter(_ word: String) {
        let k = ULYNormalizer.lookupKey(word)
        guard k.count >= 2, !customStarters.contains(k) else { return }
        customStarters.insert(k, at: 0)
        persist()
    }

    public func removeCustomStarter(_ word: String) {
        let k = ULYNormalizer.lookupKey(word)
        customStarters.removeAll { $0 == k }
        persist()
    }

    public func reload() {
        if let snap = Self.load(defaults: defaults, useKeychain: useKeychain) {
            scenario = SuggestionScenario(rawValue: snap.scenario) ?? .general
            customStarters = snap.customStarters.map { ULYNormalizer.lookupKey($0) }.filter { !$0.isEmpty }
        }
    }

    private func persist() {
        let snap = Snapshot(scenario: scenario.rawValue, customStarters: customStarters)
        guard let data = try? JSONEncoder().encode(snap) else { return }
        defaults.set(data, forKey: defaultsKey)
        guard useKeychain else { return }
        var base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecAttrAccessGroup as String: accessGroup,
        ]
        SecItemDelete(base as CFDictionary)
        var add = base
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        _ = SecItemAdd(add as CFDictionary, nil)
    }

    private static func load(defaults: UserDefaults, useKeychain: Bool) -> Snapshot? {
        if useKeychain {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: "com.esqer.uyghurlatin.prefs",
                kSecAttrAccount as String: "starterPrefs",
                kSecAttrAccessGroup as String: "QCZ38FF75B.com.esqer.uyghurlatin.shared",
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne,
            ]
            var item: CFTypeRef?
            if SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
               let data = item as? Data,
               let snap = try? JSONDecoder().decode(Snapshot.self, from: data) {
                return snap
            }
        }
        if let data = defaults.data(forKey: "uyghurlatin.starterPrefs"),
           let snap = try? JSONDecoder().decode(Snapshot.self, from: data) {
            return snap
        }
        return nil
    }
}
