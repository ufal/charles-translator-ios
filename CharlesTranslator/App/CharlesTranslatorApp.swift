import SwiftUI
import SwiftData

@main
struct CharlesTranslatorApp: App {
    @State private var environment = AppEnvironment()
    private let modelContainer = Self.makeModelContainer()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(environment)
        }
        .modelContainer(modelContainer)
    }

    /// `.modelContainer(for:)` force-crashes the app if the on-disk store can't
    /// be opened (schema mismatch, corruption, disk issues). History is
    /// non-essential to the app's core function, so fall back to an in-memory
    /// store rather than taking the whole app down with it.
    private static func makeModelContainer() -> ModelContainer {
        do {
            return try ModelContainer(for: HistoryItem.self)
        } catch {
            let fallbackConfig = ModelConfiguration(isStoredInMemoryOnly: true)
            return try! ModelContainer(for: HistoryItem.self, configurations: fallbackConfig)
        }
    }
}
