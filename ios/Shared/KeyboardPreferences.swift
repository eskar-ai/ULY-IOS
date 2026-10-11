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

/// Named presets that map onto ``KeyboardPreferences/heightScale``.
enum KeyboardHeightPreference: String, CaseIterable, Identifiable {
    case compact
    case regular
    case tall

    var id: String { rawValue }

    var scale: CGFloat {
        switch self {
        case .compact: return 0.82
        case .regular: return 1.0
        case .tall: return 1.22
        }
    }

    static func nearest(to scale: CGFloat) -> KeyboardHeightPreference {
        allCases.min(by: { abs($0.scale - scale) < abs($1.scale - scale) }) ?? .regular
    }
}

enum KeyboardPreferences {
    private static let themeKey = "theme"
    private static let heightKey = "height"
    private static let heightScaleKey = "heightScale"

    /// Continuous scale applied to the system-like base keyboard height.
    /// Range is clamped so keys stay usable on all phones.
    static let minHeightScale: CGFloat = 0.78
    static let maxHeightScale: CGFloat = 1.38
    static let defaultHeightScale: CGFloat = 1.0

    static var theme: KeyboardThemePreference {
        get {
            KeyboardThemePreference(rawValue: read(themeKey) ?? "") ?? .system
        }
        set {
            write(themeKey, newValue.rawValue)
        }
    }

    /// Custom continuous height (preferred). Persisted as a decimal string in Keychain.
    static var heightScale: CGFloat {
        get {
            if let raw = read(heightScaleKey), let value = Double(raw) {
                return clampScale(CGFloat(value))
            }
            // Migrate from the older compact/regular/tall enum if present.
            if let preset = KeyboardHeightPreference(rawValue: read(heightKey) ?? "") {
                return clampScale(preset.scale)
            }
            return defaultHeightScale
        }
        set {
            let clamped = clampScale(newValue)
            write(heightScaleKey, String(format: "%.4f", Double(clamped)))
            // Keep enum in sync for any UI that still shows presets.
            write(heightKey, KeyboardHeightPreference.nearest(to: clamped).rawValue)
        }
    }

    /// Discrete preset — writing it also updates ``heightScale``.
    static var height: KeyboardHeightPreference {
        get {
            if let preset = KeyboardHeightPreference(rawValue: read(heightKey) ?? "") {
                return preset
            }
            if let raw = read(heightScaleKey), let value = Double(raw) {
                return KeyboardHeightPreference.nearest(to: clampScale(CGFloat(value)))
            }
            return .regular
        }
        set {
            write(heightKey, newValue.rawValue)
            write(heightScaleKey, String(format: "%.4f", Double(newValue.scale)))
        }
    }

    /// Key click sound (`playInputClick`; iOS still honours the system "Keyboard Clicks" switch).
    static var soundEnabled: Bool {
        get { readBool("sound", default: true) }
        set { write("sound", newValue ? "1" : "0") }
    }

    /// Light haptic on key press. iOS may withhold haptics from keyboards without Full Access.
    static var hapticsEnabled: Bool {
        get { readBool("haptics", default: true) }
        set { write("haptics", newValue ? "1" : "0") }
    }

    /// Replace an obvious misspelling with the top correction when space is pressed.
    static var autocorrectEnabled: Bool {
        get { readBool("autocorrect", default: true) }
        set { write("autocorrect", newValue ? "1" : "0") }
    }

    private static func readBool(_ account: String, default fallback: Bool) -> Bool {
        guard let raw = read(account) else { return fallback }
        return raw == "1"
    }

    static func clampScale(_ value: CGFloat) -> CGFloat {
        min(max(value, minHeightScale), maxHeightScale)
    }

    /// Base shell height before applying ``heightScale`` (points).
    /// - Parameter landscape: iPad keeps a regular vertical size class in both orientations,
    ///   so callers that know the screen orientation pass it here.
    static func baseKeyboardHeight(traits: UITraitCollection, landscape: Bool? = nil) -> CGFloat {
        let isLandscape = landscape ?? (traits.verticalSizeClass == .compact)
        if traits.horizontalSizeClass == .regular {
            // iPad — stock keyboard is taller in landscape (wider keys, same aspect).
            return isLandscape ? 400 : 348
        }
        // iPhone — tuned to stock English keyboard + QuickType bar (~32 pt rows in landscape).
        return isLandscape ? 206 : 292
    }

    static func resolvedKeyboardHeight(
        traits: UITraitCollection,
        landscape: Bool? = nil,
        scale: CGFloat? = nil
    ) -> CGFloat {
        let s = clampScale(scale ?? heightScale)
        return (baseKeyboardHeight(traits: traits, landscape: landscape) * s).rounded()
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
