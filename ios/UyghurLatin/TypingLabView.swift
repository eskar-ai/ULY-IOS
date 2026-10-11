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
                let store = try LexiconStore(bundle: .main)
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

    private func refreshSuggestions() {
        guard let engine else { return }
        let ctx = parseContext(text)
        let result = engine.suggest(partial: ctx.partial, previousWord: ctx.previous, limit: 8)
        candidates = Array(result.candidates.prefix(5))
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

    private func parseContext(_ full: String) -> (partial: String, previous: String?) {
        let before = full
        var i = before.endIndex
        while i > before.startIndex {
            let prev = before.index(before: i)
            let ch = before[prev]
            guard let scalar = ch.unicodeScalars.first,
                  ULYNormalizer.isWordCharacter(scalar) else { break }
            i = prev
        }
        let partial = String(before[i...])

        var j = i
        while j > before.startIndex {
            let prev = before.index(before: j)
            if !before[prev].isWhitespace { break }
            j = prev
        }
        var k = j
        while k > before.startIndex {
            let prev = before.index(before: k)
            let ch = before[prev]
            guard let scalar = ch.unicodeScalars.first,
                  ULYNormalizer.isWordCharacter(scalar) else { break }
            k = prev
        }
        let previous = k < j ? ULYNormalizer.lookupKey(String(before[k..<j])) : nil
        return (partial, previous)
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
