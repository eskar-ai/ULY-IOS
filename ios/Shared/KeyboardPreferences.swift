import Foundation
import UIKit

/// Theme + height preferences shared between the host app and keyboard via
/// the shared Keychain access group (see SharedKeychain / entitlements).
enum KeyboardThemePreference: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

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
}

enum KeyboardHeightPreference: String, CaseIterable, Identifiable {
    case compact
    case regular
    case tall

    var id: String { rawValue }

    /// Multiplier applied to the base keyboard height (kept distinct so the change is obvious).
    var multiplier: CGFloat {
        switch self {
        case .compact: return 0.82
        case .regular: return 1.0
        case .tall: return 1.22
        }
    }
}

enum KeyboardPreferences {
    private static let themeKey = "theme"
    private static let heightKey = "height"

    static var theme: KeyboardThemePreference {
        get {
            KeyboardThemePreference(rawValue: read(themeKey) ?? "") ?? .system
        }
        set {
            write(themeKey, newValue.rawValue)
        }
    }

    static var height: KeyboardHeightPreference {
        get {
            KeyboardHeightPreference(rawValue: read(heightKey) ?? "") ?? .regular
        }
        set {
            write(heightKey, newValue.rawValue)
        }
    }

    private static func read(_ account: String) -> String? {
        if let value = SharedKeychain.readString(service: SharedKeychain.prefsService, account: account) {
            return value
        }
        if account == themeKey,
           let legacy = UserDefaults.standard.string(forKey: "uyghurlatin.themePreference") {
            write(themeKey, legacy)
            return legacy
        }
        return nil
    }

    private static func write(_ account: String, _ value: String) {
        _ = SharedKeychain.writeString(
            service: SharedKeychain.prefsService,
            account: account,
            value: value
        )
    }
}
