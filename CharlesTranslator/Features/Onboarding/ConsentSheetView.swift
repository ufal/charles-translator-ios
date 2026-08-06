import SwiftUI

/// Non-dismissable first-launch gate — reuses the Android app's actual approved
/// consent copy verbatim rather than inventing new legal language. Two buttons
/// (Agree/Disagree) rather than the web client's data+cookies split, since iOS
/// has no cookie-consent surface to fold in.
struct ConsentSheetView: View {
    @Environment(AppEnvironment.self) private var appEnvironment

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.charlesRed)
                .padding(.top, 40)

            Text("Data processing")
                .font(.title2.bold())

            Text("""
            I am giving the Institute of Formal and Applied Linguistics, Faculty of Mathematics and Physics, \
            Charles University (UFAL MFF UK) consent to collect my inputs and translations. The texts will be \
            anonymized and may be used for future development of the system.
            """)
            .font(.body)
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
            .padding(.horizontal)

            Text("You can change this decision anytime in Settings.")
                .font(.footnote)
                .foregroundStyle(.tertiary)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    appEnvironment.consentStore.recordConsentDecision(agreed: true)
                } label: {
                    Text("Agree")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.charlesRed)

                Button {
                    appEnvironment.consentStore.recordConsentDecision(agreed: false)
                } label: {
                    Text("Disagree")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .controlSize(.large)
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .padding()
    }
}
