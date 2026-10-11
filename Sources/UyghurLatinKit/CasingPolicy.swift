import Foundation

/// Display/insert casing for candidates. The engine always works on lowercase keys;
/// this maps a candidate back to the case the user is typing in.
public enum CasingPolicy {
    public enum Style: Equatable, Sendable {
        case lower
        case capitalized
        case upper
    }

    /// - Parameters:
    ///   - partial: the raw (un-normalized) characters the user typed for the current word
    ///   - sentenceStart: true when the word starts a sentence / empty field
    public static func style(partial: String, sentenceStart: Bool) -> Style {
        let letters = partial.filter { $0.isLetter }
        if letters.isEmpty {
            return sentenceStart ? .capitalized : .lower
        }
        if letters.count >= 2, letters.allSatisfy({ $0.isUppercase }) {
            return .upper
        }
        if let first = letters.first, first.isUppercase {
            return .capitalized
        }
        return .lower
    }

    public static func apply(word: String, partial: String, sentenceStart: Bool) -> String {
        apply(word: word, style: style(partial: partial, sentenceStart: sentenceStart))
    }

    public static func apply(word: String, style: Style) -> String {
        switch style {
        case .lower:
            return word
        case .upper:
            return word.uppercased()
        case .capitalized:
            guard let first = word.first else { return word }
            return String(first).uppercased() + word.dropFirst()
        }
    }
}
