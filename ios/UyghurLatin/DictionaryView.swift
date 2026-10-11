import SwiftUI
import UIKit
import UyghurLatinKit

/// One shared `PersonalDictionary` for the whole dictionary page (host app, immediate writes).
@MainActor
final class PersonalDictionaryModel: ObservableObject {
    let dictionary = PersonalDictionary()
    @Published private(set) var words: [String] = []

    init() {
        refresh()
    }

    var count: Int { words.count }

    /// Re-read storage (the keyboard may have learned words since).
    func reload() {
        dictionary.reloadFromStorage()
        refresh()
    }

    func add(_ word: String) {
        dictionary.add(word)
        refresh()
    }

    func remove(_ word: String) {
        dictionary.remove(word)
        refresh()
    }

    func clear() {
        dictionary.clear()
        refresh()
    }

    func mergeImport(from data: Data) throws -> Int {
        let merged = try dictionary.mergeImport(from: data)
        refresh()
        return merged
    }

    func filtered(_ query: String) -> [String] {
        let q = ULYNormalizer.lookupKey(query.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !q.isEmpty else { return words }
        return words.filter { $0.contains(q) }
    }

    private func refresh() {
        words = dictionary.allWords
    }
}

struct DictionaryView: View {
    @EnvironmentObject private var language: LanguageStore
    @StateObject private var model = PersonalDictionaryModel()
    @State private var metaText = ""
    @State private var query = ""
    @State private var newWord = ""
    @State private var exportShareURL: URL?
    @State private var showShareSheet = false
    @State private var showImportPicker = false
    @State private var showExportToFiles = false
    @State private var exportToFilesURL: URL?
    @State private var transferMessage: String?
    @State private var confirmClear = false

    var body: some View {
        List {
            Section {
                Text(metaText.isEmpty ? language.string("meta_fallback") : metaText)
                Text(language.format("personal_words_count", model.count))
                    .foregroundStyle(.secondary)
            } footer: {
                Text(language.string("dictionary_privacy"))
            }

            Section {
                HStack {
                    TextField(language.string("personal_word_placeholder"), text: $newWord)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onSubmit(addWord)
                    Button(language.string("personal_word_add"), action: addWord)
                        .disabled(newWord.trimmingCharacters(in: .whitespacesAndNewlines).count < 2)
                }

                let shown = model.filtered(query)
                if model.words.isEmpty {
                    Text(language.string("personal_words_empty"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else if shown.isEmpty {
                    Text(language.string("dictionary_no_match"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(shown, id: \.self) { word in
                        Text(word)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    model.remove(word)
                                } label: {
                                    Text(language.string("personal_word_delete"))
                                }
                            }
                    }
                }
            } header: {
                Text(language.string("section_personal_words"))
            } footer: {
                Text(language.string("personal_words_footer"))
            }

            Section {
                Button {
                    share()
                } label: {
                    Label(language.string("personal_words_share"), systemImage: "square.and.arrow.up")
                }
                .disabled(model.count == 0)

                Button {
                    exportToFiles()
                } label: {
                    Label(language.string("personal_words_save_files"), systemImage: "folder.badge.plus")
                }
                .disabled(model.count == 0)

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

                if model.count > 0 {
                    Button(role: .destructive) {
                        confirmClear = true
                    } label: {
                        Text(language.string("personal_words_clear"))
                    }
                }
            } header: {
                Text(language.string("section_transfer"))
            } footer: {
                Text(language.string("future_ai_footer"))
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $query, prompt: language.string("dictionary_search"))
        .navigationTitle(language.string("dictionary_nav_title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            model.reload()
            loadMeta()
        }
        .confirmationDialog(
            language.string("personal_words_clear"),
            isPresented: $confirmClear,
            titleVisibility: .visible
        ) {
            Button(language.string("personal_words_clear"), role: .destructive) {
                model.clear()
                transferMessage = nil
            }
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
        .environment(\.layoutDirection, language.activeLanguage.layoutDirection)
    }

    private func addWord() {
        let word = newWord.trimmingCharacters(in: .whitespacesAndNewlines)
        guard word.count >= 2 else { return }
        model.add(word)
        newWord = ""
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

    private func share() {
        do {
            exportShareURL = try PersonalDictionaryTransfer.makeExportURL(from: model.dictionary)
            showShareSheet = true
            transferMessage = nil
        } catch {
            transferMessage = language.string("personal_words_export_failed")
        }
    }

    private func exportToFiles() {
        do {
            exportToFilesURL = try PersonalDictionaryTransfer.makeExportURL(from: model.dictionary)
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
                let merged = try model.mergeImport(from: Data(contentsOf: url))
                transferMessage = language.format("personal_words_import_done", merged)
            } catch {
                transferMessage = language.string("personal_words_import_failed")
            }
        }
    }
}

/// UIKit share sheet bridge for exporting files.
struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
