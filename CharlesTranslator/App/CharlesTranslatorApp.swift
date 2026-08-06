import SwiftUI
import SwiftData

@main
struct CharlesTranslatorApp: App {
    @State private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(environment)
        }
        .modelContainer(for: HistoryItem.self)
    }
}
