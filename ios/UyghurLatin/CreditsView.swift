import SwiftUI

struct CreditsView: View {
    @EnvironmentObject private var language: LanguageStore

    private var noticeText: String {
        // Prefer the active UI language's .lproj copy (reliable in the app bundle).
        if let url = language.stringsBundle.url(forResource: "THIRD_PARTY_NOTICES", withExtension: "md"),
           let s = try? String(contentsOf: url, encoding: .utf8) {
            return s
        }
        // Fallback: Resources/notices/<lang>.md or root English copy.
        let name = language.activeLanguage.lprojName
            ?? language.resolvedSystemLanguage.lprojName
            ?? "en"
        if let url = Bundle.main.url(forResource: name, withExtension: "md", subdirectory: "notices"),
           let s = try? String(contentsOf: url, encoding: .utf8) {
            return s
        }
        if let url = Bundle.main.url(forResource: "THIRD_PARTY_NOTICES", withExtension: "md"),
           let s = try? String(contentsOf: url, encoding: .utf8) {
            return s
        }
        return language.string("credits_missing")
    }

    var body: some View {
        ScrollView {
            Text(noticeText)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .textSelection(.enabled)
        }
        .navigationTitle(language.string("credits_title"))
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.layoutDirection, language.activeLanguage.layoutDirection)
        .id(language.activeLanguage.rawValue)
    }
}
