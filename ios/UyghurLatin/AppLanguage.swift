import Foundation
import SwiftUI

/// In-app UI language (software chrome only — not typing script).
enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case english = "en"
    case chinese = "zh-Hans"
    case uyghurArabic = "ug"
    case uyghurLatin = "ug-Latn"

    var id: String { rawValue }

    /// Bundle `.lproj` folder name used for string lookup.
    var lprojName: String? {
        switch self {
        case .system: return nil
        case .english: return "en"
        case .chinese: return "zh-Hans"
        case .uyghurArabic: return "ug"
        case .uyghurLatin: return "ug-Latn"
        }
    }

    var locale: Locale {
        switch self {
        case .system: return .autoupdatingCurrent
        case .english: return Locale(identifier: "en")
        case .chinese: return Locale(identifier: "zh-Hans")
        case .uyghurArabic: return Locale(identifier: "ug")
        case .uyghurLatin: return Locale(identifier: "ug_Latn")
        }
    }

    var layoutDirection: LayoutDirection {
        switch self {
        case .uyghurArabic: return .rightToLeft
        case .system:
            return Locale.Language(identifier: Locale.current.identifier).characterDirection == .rightToLeft
                ? .rightToLeft : .leftToRight
        default: return .leftToRight
        }
    }

    /// Native name shown in the language picker (always self-describing).
    var nativeLabel: String {
        switch self {
        case .system: return "System / 系统 / سىستېما"
        case .english: return "English"
        case .chinese: return "简体中文"
        case .uyghurArabic: return "ئۇيغۇرچە"
        case .uyghurLatin: return "Uyghurche (ULY)"
        }
    }
}

@MainActor
final class LanguageStore: ObservableObject {
    static let storageKey = "app_ui_language"

    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: Self.storageKey)
        }
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: Self.storageKey) ?? AppLanguage.system.rawValue
        language = AppLanguage(rawValue: raw) ?? .system
    }

    var effectiveLocale: Locale {
        if language == .system {
            return resolvedSystemLanguage.locale
        }
        return language.locale
    }

    /// When following system, map to the closest supported UI language.
    var resolvedSystemLanguage: AppLanguage {
        let preferred = Locale.preferredLanguages.first ?? "en"
        if preferred.hasPrefix("zh") { return .chinese }
        if preferred.hasPrefix("ug") {
            let id = preferred.lowercased()
            if id.contains("latn") || id.contains("latin") { return .uyghurLatin }
            return .uyghurArabic
        }
        return .english
    }

    var activeLanguage: AppLanguage {
        language == .system ? resolvedSystemLanguage : language
    }

    var stringsBundle: Bundle {
        let name = activeLanguage.lprojName ?? "en"
        if let path = Bundle.main.path(forResource: name, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return .main
    }

    func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: nil, bundle: stringsBundle, value: key, comment: "")
    }

    func format(_ key: String, _ args: CVarArg...) -> String {
        let format = string(key)
        return String(format: format, locale: effectiveLocale, arguments: args)
    }
}
