import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(AppEnvironment.self) private var appEnvironment
    @Environment(\.modelContext) private var modelContext

    @State private var showEraseConfirmation = false

    var body: some View {
        @Bindable var consentStore = appEnvironment.consentStore

        Form {
            Section {
                Toggle("Allow data collection", isOn: $consentStore.dataCollectionConsent)
            } header: {
                Text("Privacy")
            } footer: {
                Text("""
                I am giving the Institute of Formal and Applied Linguistics, Faculty of Mathematics and Physics, \
                Charles University (UFAL MFF UK) consent to collect my inputs and translations. The texts will be \
                anonymized and may be used for future development of the system.
                """)
            }

            Section {
                TextField("Organization name", text: $consentStore.organizationName)
                    .autocorrectionDisabled()
            } header: {
                Text("Identification")
            } footer: {
                Text("If your organization has an agreement with us to track its traffic, provide its name here.")
            }

            Section {
                NavigationLink("About") {
                    AboutView()
                }
            }

            Section {
                Button(role: .destructive) {
                    showEraseConfirmation = true
                } label: {
                    Text("Erase app data")
                }
            }
        }
        .navigationTitle("Settings")
        .confirmationDialog(
            "Erase all app data?",
            isPresented: $showEraseConfirmation,
            titleVisibility: .visible
        ) {
            Button("Erase", role: .destructive) { eraseAllData() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This deletes your saved history and resets your privacy choices. This can't be undone.")
        }
    }

    private func eraseAllData() {
        try? modelContext.delete(model: HistoryItem.self)
        appEnvironment.consentStore.reset()
    }
}

private struct AboutView: View {
    var body: some View {
        List {
            Section {
                LabeledContent("Version", value: Bundle.main.shortVersionString)
            }
            Section {
                Link("UFAL MFF UK", destination: URL(string: "https://ufal.mff.cuni.cz")!)
                Link("LINDAT/CLARIAH-CZ", destination: URL(string: "https://lindat.mff.cuni.cz")!)
                Link("Contact support", destination: URL(string: "mailto:lindat-help@ufal.mff.cuni.cz")!)
            }
        }
        .navigationTitle("About")
    }
}
