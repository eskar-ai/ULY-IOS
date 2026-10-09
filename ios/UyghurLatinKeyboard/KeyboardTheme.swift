import UIKit

/// Appearance preference for the keyboard. Default follows the system setting.
enum KeyboardThemePreference: String, CaseIterable {
    case system
    case light
    case dark

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    static let storageKey = "uyghurlatin.themePreference"

    static var current: KeyboardThemePreference {
        get {
            let raw = UserDefaults.standard.string(forKey: storageKey) ?? KeyboardThemePreference.system.rawValue
            return KeyboardThemePreference(rawValue: raw) ?? .system
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: storageKey)
        }
    }

    func resolvedStyle(for traits: UITraitCollection) -> UIUserInterfaceStyle {
        switch self {
        case .system:
            return traits.userInterfaceStyle == .dark ? .dark : .light
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    mutating func cycle() {
        switch self {
        case .system: self = .light
        case .light: self = .dark
        case .dark: self = .system
        }
        KeyboardThemePreference.current = self
    }
}

/// Colors matched to the stock iOS keyboard (approximate system QuickType look).
struct KeyboardPalette {
    let background: UIColor
    let candidateBar: UIColor
    let candidateText: UIColor
    let candidateSecondary: UIColor
    let separator: UIColor
    let keyFace: UIColor
    let keySpecial: UIColor
    let keyText: UIColor
    let keyShadow: UIColor
    let popupBackground: UIColor
    let misspelled: UIColor

    static func palette(style: UIUserInterfaceStyle) -> KeyboardPalette {
        if style == .dark {
            return KeyboardPalette(
                background: UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1),
                candidateBar: UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1),
                candidateText: .white,
                candidateSecondary: UIColor(white: 0.75, alpha: 1),
                separator: UIColor(white: 1, alpha: 0.18),
                keyFace: UIColor(red: 0.42, green: 0.42, blue: 0.44, alpha: 1),
                keySpecial: UIColor(red: 0.28, green: 0.28, blue: 0.30, alpha: 1),
                keyText: .white,
                keyShadow: UIColor(white: 0, alpha: 0.45),
                popupBackground: UIColor(red: 0.28, green: 0.28, blue: 0.30, alpha: 1),
                misspelled: UIColor.systemOrange
            )
        }
        return KeyboardPalette(
            background: UIColor(red: 0.82, green: 0.83, blue: 0.85, alpha: 1),
            candidateBar: UIColor(red: 0.82, green: 0.83, blue: 0.85, alpha: 1),
            candidateText: .black,
            candidateSecondary: UIColor(white: 0.25, alpha: 1),
            separator: UIColor(white: 0, alpha: 0.18),
            keyFace: .white,
            keySpecial: UIColor(red: 0.68, green: 0.70, blue: 0.74, alpha: 1),
            keyText: .black,
            keyShadow: UIColor(white: 0, alpha: 0.28),
            popupBackground: UIColor(red: 0.95, green: 0.95, blue: 0.96, alpha: 1),
            misspelled: UIColor.systemOrange
        )
    }
}
