import SwiftUI

struct PrivacyView: View {
    @EnvironmentObject private var language: LanguageStore

    var body: some View {
        List {
            Section {
                Text(language.string("privacy_updated"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                bullet("privacy_summary_1")
                bullet("privacy_summary_2")
                bullet("privacy_summary_3")
                bullet("privacy_summary_4")
            } header: {
                Text(language.string("privacy_summary_title"))
            }

            Section {
                Text(language.string("privacy_not_collect_body"))
            } header: {
                Text(language.string("privacy_not_collect_title"))
            }

            Section {
                Text(language.string("privacy_local_body"))
            } header: {
                Text(language.string("privacy_local_title"))
            }

            Section {
                Text(language.string("privacy_network_body"))
            } header: {
                Text(language.string("privacy_network_title"))
            }

            Section {
                Text(language.string("privacy_children_body"))
            } header: {
                Text(language.string("privacy_children_title"))
            }

            Section {
                Text(language.string("privacy_choices_body"))
            } header: {
                Text(language.string("privacy_choices_title"))
            }

            Section {
                Text(language.string("privacy_contact_body"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text(language.string("privacy_contact_title"))
            }

            Section {
                Text(language.string("privacy_opensource_body"))
                if let url = URL(string: "https://github.com/eskar-ai/ULY-IOS") {
                    Link(destination: url) {
                        Label(language.string("github_open"), systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                }
            } header: {
                Text(language.string("privacy_opensource_title"))
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(language.string("privacy_nav_title"))
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.layoutDirection, language.activeLanguage.layoutDirection)
        .id(language.activeLanguage.rawValue)
    }

    private func bullet(_ key: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("•")
                .foregroundStyle(.secondary)
            Text(language.string(key))
        }
    }
}
