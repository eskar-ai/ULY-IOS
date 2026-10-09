import Foundation

/// Words learned inside the keyboard extension (UserDefaults, no Full Access).
public final class PersonalDictionary {
    private let defaults: UserDefaults
    private let key = "uyghurlatin.personalWords"
    private var words: [String: Int]

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let saved = defaults.dictionary(forKey: key) as? [String: Int] {
            self.words = saved
        } else {
            self.words = [:]
        }
    }

    public func learn(_ word: String, boost: Int = 1) {
        let key = ULYNormalizer.lookupKey(word)
        guard !key.isEmpty else { return }
        words[key, default: 0] += boost
        persist()
    }

    public func add(_ word: String) {
        learn(word, boost: 100)
    }

    public func clear() {
        words.removeAll()
        persist()
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

    public var allWords: [String] {
        Array(words.keys)
    }

    private func persist() {
        defaults.set(words, forKey: key)
    }
}
