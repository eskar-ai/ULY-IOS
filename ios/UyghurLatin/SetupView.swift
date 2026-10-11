import SwiftUI
import UIKit
import UyghurLatinKit

struct SetupView: View {
    @EnvironmentObject private var language: LanguageStore
    @State private var metaText = ""
    @State private var theme = KeyboardPreferences.theme
    @State private var height = KeyboardPreferences.height
    @State private var personalWords: [String] = []
    @State private var personalWordCount = 0
    @State private var newPersonalWord = ""
    @State private var exportShareURL: URL?
    @State private var showShareSheet = false
    @State private var showImportPicker = false
    @State private var showExportToFiles = false
    @State private var exportToFilesURL: URL?
    @State private var transferMessage: String?

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
                            Text(pickerLabel(for: lang)).tag(lang)
                        }
                    } label: {
                        Text(language.string("section_language"))
                    }
                } footer: {
                    Text(language.string("language_picker_footer"))
                }

                Section {
                    Label(language.string("trust_1"), systemImage: "lock.shield.fill")
                    Label(language.string("trust_2"), systemImage: "wifi.slash")
                    Label(language.string("trust_3"), systemImage: "eye.slash")
                    Label(language.string("trust_4"), systemImage: "checkmark.seal.fill")
                    if let url = URL(string: "https://github.com/eskar-ai/ULY-IOS") {
                        Link(destination: url) {
                            Label(language.string("github_open"), systemImage: "chevron.left.forwardslash.chevron.right")
                        }
                    }
                } header: {
                    Text(language.string("section_trust"))
                } footer: {
                    Text(language.string("github_footer"))
                }

                Section {
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
                } header: {
                    Text(language.string("section_enable"))
                }

                Section {
                    NavigationLink {
                        TypingLabView()
                    } label: {
                        Label(language.string("lab_open"), systemImage: "text.cursor")
                    }
                } header: {
                    Text(language.string("section_lab"))
                } footer: {
                    Text(language.string("lab_footer"))
                }

                Section {
                    Picker(selection: $theme) {
                        Text(language.string("theme_system")).tag(KeyboardThemePreference.system)
                        Text(language.string("theme_light")).tag(KeyboardThemePreference.light)
                        Text(language.string("theme_dark")).tag(KeyboardThemePreference.dark)
                    } label: {
                        Text(language.string("theme_label"))
                    }
                    .onChange(of: theme) { newValue in
                        KeyboardPreferences.theme = newValue
                    }

                    Picker(selection: $height) {
                        Text(language.string("height_compact")).tag(KeyboardHeightPreference.compact)
                        Text(language.string("height_regular")).tag(KeyboardHeightPreference.regular)
                        Text(language.string("height_tall")).tag(KeyboardHeightPreference.tall)
                    } label: {
                        Text(language.string("height_label"))
                    }
                    .onChange(of: height) { newValue in
                        KeyboardPreferences.height = newValue
                    }
                } header: {
                    Text(language.string("section_appearance"))
                } footer: {
                    Text(language.string("appearance_footer"))
                }

                Section {
                    NavigationLink {
                        StarterSettingsView()
                    } label: {
                        Label(language.string("starters_open"), systemImage: "text.badge.star")
                    }
                } header: {
                    Text(language.string("section_starters"))
                } footer: {
                    Text(language.string("starters_footer"))
                }

                Section {
                    Text(language.string("typing_1"))
                    Text(language.string("typing_2"))
                    Text(language.string("typing_3"))
                    Text(language.string("typing_4"))
                } header: {
                    Text(language.string("section_typing"))
                }

                Section {
                    Text(metaText.isEmpty ? language.string("meta_fallback") : metaText)
                    Text(language.string("dictionary_privacy"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text(language.format("personal_words_count", personalWordCount))
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    HStack {
                        TextField(language.string("personal_word_placeholder"), text: $newPersonalWord)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Button(language.string("personal_word_add")) {
                            addPersonalWord()
                        }
                        .disabled(newPersonalWord.trimmingCharacters(in: .whitespacesAndNewlines).count < 2)
                    }

                    Button {
                        sharePersonalDictionary()
                    } label: {
                        Label(language.string("personal_words_share"), systemImage: "square.and.arrow.up")
                    }
                    .disabled(personalWordCount == 0)

                    Button {
                        exportPersonalDictionaryToFiles()
                    } label: {
                        Label(language.string("personal_words_save_files"), systemImage: "folder.badge.plus")
                    }
                    .disabled(personalWordCount == 0)

                    Button {
                        showImportPicker = true
                    } label: {
                        Label(language.string("personal_words_import"), systemImage: "square.and.arrow.down")
                    }

                    if let transferMessage {
                        Text(transferMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if personalWords.isEmpty {
                        Text(language.string("personal_words_empty"))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(personalWords, id: \.self) { word in
                            Text(word)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        removePersonalWord(word)
                                    } label: {
                                        Text(language.string("personal_word_delete"))
                                    }
                                }
                        }
                        Button(role: .destructive) {
                            clearPersonalWords()
                        } label: {
                            Text(language.string("personal_words_clear"))
                        }
                    }
                } header: {
                    Text(language.string("section_dictionary"))
                } footer: {
                    Text(language.string("personal_words_footer"))
                }

                Section {
                    Text(language.string("future_ai_body"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text(language.string("section_future"))
                } footer: {
                    Text(language.string("future_ai_footer"))
                }

                Section {
                    Text(language.string("privacy_body"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    NavigationLink {
                        PrivacyView()
                    } label: {
                        Text(language.string("privacy_open"))
                    }
                } header: {
                    Text(language.string("section_privacy"))
                }

                Section {
                    Text(language.string("contribute_body"))
                    if let url = URL(string: "https://github.com/eskar-ai/ULY-IOS/blob/main/CONTRIBUTING.md") {
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
                    if let url = URL(string: "https://github.com/eskar-ai/ULY-IOS") {
                        Link(destination: url) {
                            Label(language.string("github_open"), systemImage: "link")
                        }
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
                } header: {
                    Text(language.string("section_about"))
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(language.string("nav_keyboard"))
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadMeta()
                reloadPersonalWords()
            }
            .onChange(of: language.language) { _ in
                loadMeta()
            }
            .sheet(isPresented: $showShareSheet) {
                if let exportShareURL {
                    ActivityShareSheet(items: [exportShareURL])
                }
            }
            .sheet(isPresented: $showImportPicker) {
                PersonalDictionaryImportPicker { result in
                    showImportPicker = false
                    handleImport(result)
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showExportToFiles) {
                if let exportToFilesURL {
                    PersonalDictionaryExportPicker(fileURL: exportToFilesURL) {
                        showExportToFiles = false
                        transferMessage = language.string("personal_words_export_done")
                    }
                    .ignoresSafeArea()
                }
            }
        }
        .environment(\.layoutDirection, language.activeLanguage.layoutDirection)
        .environment(\.locale, language.effectiveLocale)
        .id(language.activeLanguage.rawValue)
    }

    private func pickerLabel(for lang: AppLanguage) -> String {
        switch lang {
        case .system: return language.string("language_system")
        case .english: return language.string("language_en")
        case .chinese: return language.string("language_zh")
        case .uyghurArabic: return language.string("language_ug")
        case .uyghurLatin: return language.string("language_uly")
        }
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

    private func reloadPersonalWords() {
        let dict = PersonalDictionary()
        personalWords = dict.allWords
        personalWordCount = dict.wordCount
    }

    private func addPersonalWord() {
        let word = newPersonalWord.trimmingCharacters(in: .whitespacesAndNewlines)
        guard word.count >= 2 else { return }
        let dict = PersonalDictionary()
        dict.add(word)
        newPersonalWord = ""
        reloadPersonalWords()
    }

    private func removePersonalWord(_ word: String) {
        let dict = PersonalDictionary()
        dict.remove(word)
        reloadPersonalWords()
    }

    private func clearPersonalWords() {
        PersonalDictionary().clear()
        transferMessage = nil
        reloadPersonalWords()
    }

    private func sharePersonalDictionary() {
        do {
            exportShareURL = try PersonalDictionaryTransfer.makeExportURL()
            showShareSheet = true
            transferMessage = nil
        } catch {
            transferMessage = language.string("personal_words_export_failed")
        }
    }

    private func exportPersonalDictionaryToFiles() {
        do {
            exportToFilesURL = try PersonalDictionaryTransfer.makeExportURL()
            showExportToFiles = true
            transferMessage = nil
        } catch {
            transferMessage = language.string("personal_words_export_failed")
        }
    }

    private func handleImport(_ result: Result<URL, Error>) {
        switch result {
        case .failure:
            transferMessage = language.string("personal_words_import_failed")
        case .success(let url):
            do {
                let data = try Data(contentsOf: url)
                let merged = try PersonalDictionary().mergeImport(from: data)
                reloadPersonalWords()
                transferMessage = language.format("personal_words_import_done", merged)
            } catch {
                transferMessage = language.string("personal_words_import_failed")
            }
        }
    }
}

/// UIKit share sheet bridge for exporting files.
private struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
