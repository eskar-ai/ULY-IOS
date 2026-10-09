import SwiftUI

@main
struct UyghurLatinApp: App {
    @StateObject private var language = LanguageStore()

    var body: some Scene {
        WindowGroup {
            SetupView()
                .environmentObject(language)
        }
    }
}
