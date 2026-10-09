import SwiftUI
import UIKit

struct SetupView: View {
    @State private var metaText = String(localized: String.LocalizationValue("meta_fallback"))

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
                                Text("app_title")
                                    .font(.title2.weight(.semibold))
                                Text("app_tagline")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }

                Section("section_enable") {
                    labeledStep(1, String(localized: "enable_step_1"))
                    labeledStep(2, String(localized: "enable_step_2"))
                    labeledStep(3, String(localized: "enable_step_3"))
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("open_settings", systemImage: "gear")
                    }
                }

                Section("section_appearance") {
                    Text("appearance_body")
                    Text("appearance_hint")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("section_typing") {
                    Text("typing_1")
                    Text("typing_2")
                    Text("typing_3")
                    Text("typing_4")
                }

                Section("section_dictionary") {
                    Text(metaText)
                    Text("dictionary_privacy")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("section_privacy") {
                    Text("privacy_body")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("section_about") {
                    Text("about_sources")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                       let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                        Text("Version \(version) (\(build))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("nav_keyboard")
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
            metaText = String(format: String(localized: "meta_format"), locale: .current, count, script, version)
        }
    }
}
