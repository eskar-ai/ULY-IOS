import SwiftUI

struct AboutView: View {
    @EnvironmentObject private var language: LanguageStore

    private static let repoURL = URL(string: "https://github.com/eskar-ai/ULY-IOS")
    private static let contributingURL = URL(string: "https://github.com/eskar-ai/ULY-IOS/blob/main/CONTRIBUTING.md")

    var body: some View {
        List {
            Section {
                Text(language.string("typing_1"))
                Text(language.string("typing_2"))
                Text(language.string("typing_3"))
                Text(language.string("typing_4"))
            } header: {
                Text(language.string("section_typing"))
            }

            Section {
                Text(language.string("contribute_body"))
                if let url = Self.contributingURL {
                    Link(destination: url) {
                        Label(language.string("contribute_open"), systemImage: "person.3")
                    }
                }
            } header: {
                Text(language.string("section_contribute"))
            } footer: {
                Text(language.string("contribute_footer"))
            }

            Section {
                NavigationLink {
                    CreditsView()
                } label: {
                    Text(language.string("credits_open"))
                }
                Text(language.string("about_sources"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if let url = Self.repoURL {
                    Link(destination: url) {
                        Label(language.string("github_open"), systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                }
            } header: {
                Text(language.string("section_about"))
            } footer: {
                Text(language.string("github_footer"))
            }

            Section {
                Text(language.string("future_ai_body"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text(language.string("section_future"))
            }

            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
               let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                Section {
                    Text(language.format("version_format", version, build))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(language.string("about_nav_title"))
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.layoutDirection, language.activeLanguage.layoutDirection)
    }
}
