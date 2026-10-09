import SwiftUI
import UIKit

struct SetupView: View {
    @EnvironmentObject private var language: LanguageStore
    @State private var metaText = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Image("AppIconMarketing")
                                .resizable()
                                .frame(width: 64, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                                )
                                .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(language.string("app_title"))
                                    .font(.title2.weight(.semibold))
                                Text(language.string("app_tagline"))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }

                Section {
                    Picker(selection: Binding(
                        get: { language.language },
                        set: { language.language = $0 }
                    )) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.nativeLabel).tag(lang)
                        }
                    } label: {
                        Text(language.string("section_language"))
                    }
                } footer: {
                    Text(language.string("language_picker_footer"))
                }

                Section(language.string("section_enable")) {
                    labeledStep(1, language.string("enable_step_1"))
                    labeledStep(2, language.string("enable_step_2"))
                    labeledStep(3, language.string("enable_step_3"))
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label(language.string("open_settings"), systemImage: "gear")
                    }
                }

                Section(language.string("section_appearance")) {
                    Text(language.string("appearance_body"))
                    Text(language.string("appearance_hint"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section(language.string("section_typing")) {
                    Text(language.string("typing_1"))
                    Text(language.string("typing_2"))
                    Text(language.string("typing_3"))
                    Text(language.string("typing_4"))
                }

                Section(language.string("section_dictionary")) {
                    Text(metaText.isEmpty ? language.string("meta_fallback") : metaText)
                    Text(language.string("dictionary_privacy"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section(language.string("section_privacy")) {
                    Text(language.string("privacy_body"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    NavigationLink {
                        PrivacyView()
                    } label: {
                        Text(language.string("privacy_open"))
                    }
                }

                Section(language.string("section_about")) {
                    NavigationLink {
                        CreditsView()
                    } label: {
                        Text(language.string("credits_open"))
                    }
                    Text(language.string("about_sources"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                       let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                        Text(language.format("version_format", version, build))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(language.string("nav_keyboard"))
            .navigationBarTitleDisplayMode(.large)
            .onAppear(perform: loadMeta)
            .onChange(of: language.language) { _ in
                loadMeta()
            }
        }
        .environment(\.layoutDirection, language.activeLanguage.layoutDirection)
        .environment(\.locale, language.effectiveLocale)
        .id(language.activeLanguage.rawValue)
    }

    private func labeledStep(_ n: Int, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("\(n).")
                .foregroundStyle(.secondary)
                .frame(width: 20, alignment: .trailing)
            Text(text)
        }
    }

    private func loadMeta() {
        if let url = Bundle.main.url(forResource: "meta", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let count = obj["wordCount"] as? Int,
           let script = obj["script"] as? String,
           let version = obj["version"] as? String {
            metaText = language.format("meta_format", count, script, version)
        } else {
            metaText = language.string("meta_fallback")
        }
    }
}
