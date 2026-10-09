import SwiftUI

struct SetupView: View {
    @State private var metaText = "Lexicon bundled offline"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ULY Künupka")
                            .font(.system(size: 36, weight: .bold, design: .serif))
                        Text("Offline Uyghur Latin Yëziqi keyboard for iPhone — suggestions, spell check, and corrections on device.")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)

                    GroupBox("Enable the keyboard") {
                        VStack(alignment: .leading, spacing: 10) {
                            step(1, "Open Settings → General → Keyboard → Keyboards")
                            step(2, "Tap Add New Keyboard…")
                            step(3, "Choose ULY Künupka under Third-Party Keyboards")
                            step(4, "Optional: tap the keyboard → allow Full Access only if you later need shared containers (not required)")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                    }

                    GroupBox("How to type ULY") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Long-press e / o / u for ë ö ü")
                            Text("• Long-press c s z g n for ch sh zh gh ng")
                            Text("• Suggestion bar: completions, next word, and spell fixes")
                            Text("• Tap a suggestion to replace the current word")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    GroupBox("Dictionary") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(metaText)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("Learned words stay inside the keyboard extension (no Full Access / no network). Remove the keyboard in Settings to reset them.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Text("Sources: UyghurEdit++ imla lexicon (MIT), imlalughet (MIT), umsc converter (Apache-2.0). See THIRD_PARTY_NOTICES.md.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.91, green: 0.95, blue: 0.93),
                        Color(red: 0.82, green: 0.90, blue: 0.87),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: loadMeta)
        }
    }

    private func step(_ n: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(n)")
                .font(.caption.weight(.bold))
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color(red: 0.06, green: 0.42, blue: 0.34)))
                .foregroundStyle(.white)
            Text(text)
                .font(.subheadline)
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
            metaText = "120,000-word ULY lexicon bundled in the keyboard extension (offline)."
        }
    }
}
