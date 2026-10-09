import SwiftUI

struct SetupView: View {
    @State private var metaText = "Lexicon bundled offline"

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ULY Künupka")
                            .font(.title.weight(.semibold))
                        Text("Uyghur Latin Yëziqi keyboard — offline suggestions and spell check.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("Enable") {
                    labeledStep(1, "Settings → General → Keyboard → Keyboards")
                    labeledStep(2, "Add New Keyboard…")
                    labeledStep(3, "ULY Künupka")
                }

                Section("Appearance") {
                    Text("Default follows your iPhone appearance (Light / Dark).")
                    Text("On the keyboard suggestion bar, tap ◐ to cycle System → Light → Dark. The override is stored on-device inside the keyboard.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Typing") {
                    Text("Long-press e / o / u for ë ö ü")
                    Text("Long-press c / s / z / g / n for ch / sh / zh / gh / ng")
                    Text("ëöü opens digraphs and apostrophe (')")
                    Text("Suggestion bar matches system QuickType: tap to complete or correct")
                }

                Section("Dictionary") {
                    Text(metaText)
                    Text("Personal words stay in the keyboard sandbox (no Full Access, no network).")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("About") {
                    Text("Lexicon sources are listed in THIRD_PARTY_NOTICES.md (MIT / Apache-2.0).")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Keyboard")
            .navigationBarTitleDisplayMode(.large)
            .onAppear(perform: loadMeta)
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
            metaText = "\(count) words · \(script) · v\(version)"
        } else {
            metaText = "120,000-word ULY lexicon bundled offline in the keyboard."
        }
    }
}
