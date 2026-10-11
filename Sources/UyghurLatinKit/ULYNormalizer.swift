import Foundation

/// Normalizes Uyghur Latin Yëziqi (2008): é→ë, curly apostrophe→', lowercase for lookup.
public enum ULYNormalizer {
    public static func normalize(_ text: String) -> String {
        var s = text
        s = s.replacingOccurrences(of: "É", with: "Ë")
        s = s.replacingOccurrences(of: "é", with: "ë")
        s = s.replacingOccurrences(of: "ʼ", with: "'")
        s = s.replacingOccurrences(of: "\u{2019}", with: "'")
        return s
    }

    public static func lookupKey(_ text: String) -> String {
        normalize(text).lowercased()
    }

    /// Characters considered part of a ULY word (letters + apostrophe).
    public static func isWordCharacter(_ scalar: UnicodeScalar) -> Bool {
        if scalar == "'" || scalar == "\u{2019}" || scalar == "ʼ" { return true }
        if CharacterSet.letters.contains(scalar) { return true }
        // Explicit ULY extras
        switch scalar {
        case "ö", "ü", "ë", "Ö", "Ü", "Ë", "é", "É":
            return true
        default:
            return false
        }
    }
}
