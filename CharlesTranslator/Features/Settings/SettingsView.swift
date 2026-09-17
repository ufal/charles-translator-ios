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
                ForEach(appEnvironment.offlineSpeechStatusStore.statuses, id: \.language) { status in
                    HStack {
                        Text(status.language.displayName)
                        Spacer()
                        CapabilityBadge(
                            systemImage: "mic",
                            onDevice: status.dictationOnDevice,
                            supported: status.recognitionSupported,
                            language: status.language,
                            capability: String(localized: "settings.offline.dictation", defaultValue: "dictation")
                        )
                        CapabilityBadge(
                            systemImage: "speaker.wave.2",
                            onDevice: status.synthesisOnDevice,
                            supported: status.voiceAvailable,
                            language: status.language,
                            capability: String(localized: "settings.offline.speech", defaultValue: "speech")
                        )
                    }
                }
            } header: {
                Text("Offline speech models")
            } footer: {
                Text("Indicates languages whose dictation and speech models are downloaded for offline use.")
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
        .task {
            appEnvironment.offlineSpeechStatusStore.refresh()
        }
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

/// A single capability indicator in the "Offline speech models" section — the
/// mic symbol (dictation) or speaker symbol (speech). On-device renders filled
/// blue; supported-but-server-only renders outlined gray; unsupported renders
/// gray with a slash. State is also conveyed via `accessibilityLabel` so it
/// isn't color-only (HIG).
private struct CapabilityBadge: View {
    let systemImage: String
    let onDevice: Bool
    let supported: Bool
    let language: Language
    let capability: String

    var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(symbolColor)
            .frame(width: 32)
            .accessibilityLabel(accessibilityText)
    }

    private var symbolName: String {
        guard supported || onDevice else { return "\(systemImage).slash" }
        return onDevice ? "\(systemImage).fill" : systemImage
    }

    private var symbolColor: Color {
        onDevice ? Color.charlesBlue : Color(.tertiaryLabel)
    }

    private var accessibilityText: Text {
        let status: String
        if onDevice {
            status = String(
                localized: "settings.offline.onDevice",
                defaultValue: "on device"
            )
        } else if supported {
            status = String(
                localized: "settings.offline.onlineOnly",
                defaultValue: "online only"
            )
        } else {
            status = String(
                localized: "settings.offline.unavailable",
                defaultValue: "unavailable"
            )
        }
        return Text("\(language.displayName): \(capability) \(status)")
    }
}
