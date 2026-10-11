import SwiftUI
import UyghurLatinKit

/// Offline scenario + custom sentence-start pins (shared with keyboard via Keychain).
struct StarterSettingsView: View {
    @EnvironmentObject private var language: LanguageStore
    @State private var prefs = StarterPreferences()
    @State private var scenario: SuggestionScenario = .general
    @State private var custom: [String] = []
    @State private var newWord = ""

    var body: some View {
        List {
            Section {
                Picker(selection: $scenario) {
                    Text(language.string("scenario_general")).tag(SuggestionScenario.general)
                    Text(language.string("scenario_greeting")).tag(SuggestionScenario.greeting)
                    Text(language.string("scenario_chat")).tag(SuggestionScenario.chat)
                    Text(language.string("scenario_writing")).tag(SuggestionScenario.writing)
                } label: {
                    Text(language.string("scenario_label"))
                }
                .onChange(of: scenario) { newValue in
                    prefs.setScenario(newValue)
                }
            } header: {
                Text(language.string("section_scenario"))
            } footer: {
                Text(language.string("scenario_footer"))
            }

            Section {
                Text(previewLine)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text(language.string("scenario_preview"))
            }

            Section {
                HStack {
                    TextField(language.string("starter_pin_placeholder"), text: $newWord)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button(language.string("starter_pin_add")) {
                        addPin()
                    }
                    .disabled(newWord.trimmingCharacters(in: .whitespacesAndNewlines).count < 2)
                }

                if custom.isEmpty {
                    Text(language.string("starter_pins_empty"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(custom, id: \.self) { word in
                        Text(word)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    prefs.removeCustomStarter(word)
                                    reload()
                                } label: {
                                    Text(language.string("personal_word_delete"))
                                }
                            }
                    }
                }
            } header: {
                Text(language.string("section_starter_pins"))
            } footer: {
                Text(language.string("starter_pins_footer"))
            }
        }
        .navigationTitle(language.string("starters_nav_title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: reload)
    }

    private var previewLine: String {
        let words = Array(prefs.activeStarters().prefix(8))
        return words.isEmpty ? "—" : words.joined(separator: " · ")
    }

    private func reload() {
        prefs.reload()
        scenario = prefs.scenario
        custom = prefs.customStarters
    }

    private func addPin() {
        let word = newWord.trimmingCharacters(in: .whitespacesAndNewlines)
        guard word.count >= 2 else { return }
        prefs.addCustomStarter(word)
        newWord = ""
        reload()
    }
}
