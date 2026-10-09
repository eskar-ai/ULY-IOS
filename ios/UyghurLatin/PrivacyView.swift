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

            Section(language.string("privacy_summary_title")) {
                bullet("privacy_summary_1")
                bullet("privacy_summary_2")
                bullet("privacy_summary_3")
                bullet("privacy_summary_4")
            }

            Section(language.string("privacy_not_collect_title")) {
                Text(language.string("privacy_not_collect_body"))
            }

            Section(language.string("privacy_local_title")) {
                Text(language.string("privacy_local_body"))
            }

            Section(language.string("privacy_network_title")) {
                Text(language.string("privacy_network_body"))
            }

            Section(language.string("privacy_children_title")) {
                Text(language.string("privacy_children_body"))
            }

            Section(language.string("privacy_choices_title")) {
                Text(language.string("privacy_choices_body"))
            }

            Section(language.string("privacy_contact_title")) {
                Text(language.string("privacy_contact_body"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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
