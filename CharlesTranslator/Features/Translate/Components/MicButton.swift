import SwiftUI

/// Follows Apple's own dictation-key convention (system keyboard mic button):
/// a single tap toggles listening, filled red circle while active. The pulse
/// is a simple repeating scale animation for v1 — a real audio-level-driven
/// waveform is a named Phase 2 enhancement, not needed to convey "listening".
struct MicButton: View {
    let isListening: Bool
    var showsOnDeviceIndicator: Bool = false
    let action: () -> Void

    @State private var isPulsing = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isListening ? Color.charlesRed : Color(.secondarySystemBackground))
                    .frame(width: 56, height: 56)
                    .scaleEffect(isListening && isPulsing ? 1.12 : 1.0)

                Image(systemName: isListening ? "mic.fill" : "mic")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(isListening ? .white : .primary)
            }
            // The on-device dot is overlaid on the *whole* 56pt circle (not a
            // ZStack child) so the mic stays centered — using `.bottomTrailing`
            // alignment here doesn't disturb the mic's centering.
            .overlay(alignment: .bottomTrailing) {
                if showsOnDeviceIndicator {
                    Circle()
                        .fill(Color.charlesBlue)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                        .padding(4)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isListening ? Text("Stop listening") : Text("Start voice input"))
        .onChange(of: isListening) { _, newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            } else {
                isPulsing = false
            }
        }
    }
}
