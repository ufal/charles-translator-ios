import SwiftUI

/// Top-level `TabView` (Translate / Conversation / History / Settings) — the
/// idiomatic iOS translation of Android's icon-cluster single-screen layout.
/// A tab bar is the correct HIG pattern for this many peer-level destinations.
struct RootView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        @Bindable var environment = environment

        TabView(selection: $environment.selectedTab) {
            NavigationStack {
                TranslateView()
            }
            .tabItem { Label("Translate", systemImage: "character.bubble") }
            .tag(AppTab.translate)

            NavigationStack {
                ConversationView()
            }
            .tabItem { Label("Conversation", systemImage: "bubble.left.and.bubble.right") }
            .tag(AppTab.conversation)

            NavigationStack {
                HistoryView()
            }
            .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
            .tag(AppTab.history)

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
            .tag(AppTab.settings)
        }
        .sheet(isPresented: .constant(!environment.consentStore.hasAnswered)) {
            ConsentSheetView()
                .interactiveDismissDisabled(true)
        }
    }
}
