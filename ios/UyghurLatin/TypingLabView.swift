import SwiftUI
import UyghurLatinKit

/// Simple in-app playground: type ULY text and see live offline suggestions.
struct TypingLabView: View {
    @EnvironmentObject private var language: LanguageStore

    @State private var text = ""
    @State private var engine: SuggestionEngine?
    @State private var loadError: String?
    @State private var candidates: [String] = []
    @State private var misspelled = false
    @State private var modeLabel = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(language.string("lab_intro"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            TextEditor(text: $text)
                .font(.system(size: 22, design: .default))
                .frame(minHeight: 140)
                .padding(10)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onChange(of: text) { _ in
                    refreshSuggestions()
                }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(language.string("lab_suggestions"))
                        .font(.headline)
                    Spacer()
                    if !modeLabel.isEmpty {
                        Text(modeLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let loadError {
                    Text(loadError)
                        .font(.footnote)
                        .foregroundStyle(.orange)
                } else if engine == nil {
                    Text(language.string("lab_loading"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else if candidates.isEmpty {
                    Text(language.string("lab_empty"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    FlowCandidateRow(words: candidates, misspelled: misspelled) { word in
                        applyCandidate(word)
                    }
                }
            }

            Text(language.string("lab_hint"))
                .font(.footnote)
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)
        }
        .padding()
        .navigationTitle(language.string("lab_title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadEngine)
        .environment(\.layoutDirection, language.activeLanguage.layoutDirection)
    }

    private func loadEngine() {
        guard engine == nil else {
            refreshSuggestions()
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let store = try LexiconStore(bundle: Self.lexiconBundle)
                let loaded = SuggestionEngine(store: store)
                DispatchQueue.main.async {
                    self.engine = loaded
                    self.loadError = nil
                    self.refreshSuggestions()
                }
            } catch {
                DispatchQueue.main.async {
                    self.loadError = language.string("lab_load_failed")
                }
            }
        }
    }

    /// The lexicon ships only inside the keyboard extension; the host reads it from there.
    private static var lexiconBundle: Bundle {
        if let plugins = Bundle.main.builtInPlugInsURL,
           let appex = Bundle(url: plugins.appendingPathComponent("UyghurLatinKeyboard.appex")) {
            return appex
        }
        return .main
    }

    private func refreshSuggestions() {
        guard let engine else { return }
        let ctx = parseContext(text)
        let result = engine.suggest(
            partial: ctx.partial,
            previousWord: ctx.previous,
            beforePreviousWord: ctx.beforePrevious,
            sentenceStart: ctx.sentenceStart,
            limit: 8
        )
        candidates = result.candidates.prefix(5).map {
            CasingPolicy.apply(word: $0, partial: ctx.partial, sentenceStart: ctx.sentenceStart)
        }
        misspelled = result.isMisspelled
        switch result.mode {
        case .completion: modeLabel = language.string("lab_mode_completion")
        case .nextWord: modeLabel = language.string("lab_mode_next")
        case .correction: modeLabel = language.string("lab_mode_correction")
        case .empty: modeLabel = ""
        }
    }

    private func applyCandidate(_ word: String) {
        let ctx = parseContext(text)
        if !ctx.partial.isEmpty, text.hasSuffix(ctx.partial) {
            text.removeLast(ctx.partial.count)
        }
        text += word + " "
        engine?.learnSelection(word, previous: ctx.previous)
        refreshSuggestions()
    }

    private struct LabContext {
        var partial: String
        var previous: String?
        var beforePrevious: String?
        var sentenceStart: Bool
    }

    private static func isWordCharacter(_ ch: Character) -> Bool {
        guard let scalar = ch.unicodeScalars.first else { return false }
        return ULYNormalizer.isWordCharacter(scalar)
    }

    /// Mirrors the keyboard: the current partial word, up to two previous words in the
    /// same sentence, and whether the partial starts a sentence.
    private func parseContext(_ full: String) -> LabContext {
        var i = full.endIndex
        while i > full.startIndex, Self.isWordCharacter(full[full.index(before: i)]) {
            i = full.index(before: i)
        }
        let partial = String(full[i...])
        let before = full[..<i]

        let sentence: Substring
        if let end = before.lastIndex(where: { ".!?\n".contains($0) }) {
            sentence = before[before.index(after: end)...]
        } else {
            sentence = before
        }
        let words = sentence
            .split(whereSeparator: { !Self.isWordCharacter($0) })
            .map { ULYNormalizer.lookupKey(String($0)) }

        return LabContext(
            partial: partial,
            previous: words.last,
            beforePrevious: words.count >= 2 ? words[words.count - 2] : nil,
            sentenceStart: words.isEmpty
        )
    }
}

private struct FlowCandidateRow: View {
    let words: [String]
    let misspelled: Bool
    let onTap: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(words.enumerated()), id: \.offset) { idx, word in
                    Button {
                        onTap(word)
                    } label: {
                        Text(word)
                            .font(.system(size: 17, weight: idx == 0 ? .semibold : .regular))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color(.tertiarySystemBackground))
                            .foregroundStyle(misspelled && idx == 0 ? Color.orange : Color.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
