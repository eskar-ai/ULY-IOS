import SwiftUI
import UIKit
import UyghurLatinKit

struct SetupView: View {
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var theme = KeyboardPreferences.theme
    @State private var heightScale = KeyboardPreferences.heightScale
    @State private var soundEnabled = KeyboardPreferences.soundEnabled
    @State private var hapticsEnabled = KeyboardPreferences.hapticsEnabled
    @State private var autocorrectEnabled = KeyboardPreferences.autocorrectEnabled
    @State private var keyboardAdded = false
    @State private var personalWordCount = 0

    private static let keyboardBundleID = "com.esqer.uyghurlatin.app.keyboard"

    var body: some View {
        NavigationStack {
            List {
                header

                Section {
                    Label {
                        Text(language.string(keyboardAdded ? "status_enabled" : "status_disabled"))
                    } icon: {
                        Image(systemName: keyboardAdded ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .foregroundStyle(keyboardAdded ? .green : .orange)
                    }
                    if !keyboardAdded {
                        labeledStep(1, language.string("enable_step_1"))
                        labeledStep(2, language.string("enable_step_2"))
                        labeledStep(3, language.string("enable_step_3"))
                    }
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label(language.string("open_settings"), systemImage: "gear")
                    }
                } header: {
                    Text(language.string("section_status"))
                } footer: {
                    Text(language.string(keyboardAdded ? "status_enabled_footer" : "status_disabled_footer"))
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

                    KeyboardHeightAdjustView(scale: $heightScale, theme: theme)
                        .onChange(of: heightScale) { newValue in
                            KeyboardPreferences.heightScale = newValue
                        }

                    Toggle(language.string("sound_label"), isOn: $soundEnabled)
                        .onChange(of: soundEnabled) { KeyboardPreferences.soundEnabled = $0 }
                    Toggle(language.string("haptics_label"), isOn: $hapticsEnabled)
                        .onChange(of: hapticsEnabled) { KeyboardPreferences.hapticsEnabled = $0 }
                    Toggle(language.string("autocorrect_label"), isOn: $autocorrectEnabled)
                        .onChange(of: autocorrectEnabled) { KeyboardPreferences.autocorrectEnabled = $0 }
                } header: {
                    Text(language.string("section_appearance"))
                } footer: {
                    Text(language.string("appearance_footer") + "\n\n"
                        + language.string("settings_apply_note") + " "
                        + language.string("haptics_note"))
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
                    NavigationLink {
                        DictionaryView()
                    } label: {
                        LabeledContent {
                            Text("\(personalWordCount)")
                                .monospacedDigit()
                        } label: {
                            Label(language.string("dictionary_open"), systemImage: "character.book.closed")
                        }
                    }
                } header: {
                    Text(language.string("section_dictionary"))
                } footer: {
                    Text(language.string("dictionary_privacy"))
                }

                Section {
                    Label(language.string("trust_1"), systemImage: "lock.shield.fill")
                    Label(language.string("trust_2"), systemImage: "wifi.slash")
                    Label(language.string("trust_3"), systemImage: "eye.slash")
                    Label(language.string("trust_4"), systemImage: "checkmark.seal.fill")
                    NavigationLink {
                        PrivacyView()
                    } label: {
                        Text(language.string("privacy_open"))
                    }
                } header: {
                    Text(language.string("section_privacy"))
                } footer: {
                    Text(language.string("privacy_body"))
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
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label(language.string("about_open"), systemImage: "info.circle")
                    }
                } header: {
                    Text(language.string("section_about"))
                } footer: {
                    Text(language.string("language_picker_footer"))
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(language.string("nav_keyboard"))
            .navigationBarTitleDisplayMode(.large)
            .onAppear(perform: refresh)
            .onChange(of: scenePhase) { phase in
                if phase == .active { refresh() }
            }
            .onReceive(NotificationCenter.default.publisher(for: UITextInputMode.currentInputModeDidChangeNotification)) { _ in
                refreshKeyboardAdded()
            }
        }
        .environment(\.layoutDirection, language.activeLanguage.layoutDirection)
        .environment(\.locale, language.effectiveLocale)
        .id(language.activeLanguage.rawValue)
    }

    private var header: some View {
        Section {
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
            .padding(.vertical, 6)
        }
    }

    private func refresh() {
        theme = KeyboardPreferences.theme
        heightScale = KeyboardPreferences.heightScale
        soundEnabled = KeyboardPreferences.soundEnabled
        hapticsEnabled = KeyboardPreferences.hapticsEnabled
        autocorrectEnabled = KeyboardPreferences.autocorrectEnabled
        personalWordCount = PersonalDictionary().wordCount
        refreshKeyboardAdded()
    }

    /// Whether the user has added this keyboard in Settings (no Full Access needed).
    private func refreshKeyboardAdded() {
        let identifier = Selector(("identifier"))
        keyboardAdded = UITextInputMode.activeInputModes.contains { mode in
            guard mode.responds(to: identifier),
                  let id = mode.value(forKey: "identifier") as? String else { return false }
            return id.hasPrefix(Self.keyboardBundleID)
        }
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
}
