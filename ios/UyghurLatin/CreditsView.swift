import SwiftUI

struct CreditsView: View {
    private let text: String

    init() {
        if let url = Bundle.main.url(forResource: "THIRD_PARTY_NOTICES", withExtension: "md"),
           let s = try? String(contentsOf: url, encoding: .utf8) {
            text = s
        } else {
            text = "Third-party notices file not found in app bundle."
        }
    }

    var body: some View {
        ScrollView {
            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .textSelection(.enabled)
        }
        .navigationTitle("Credits")
        .navigationBarTitleDisplayMode(.inline)
    }
}
