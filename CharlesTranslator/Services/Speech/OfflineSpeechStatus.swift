import Foundation

/// Per-language capability snapshot used by Settings' "Offline speech models"
/// section. Each flag answers a distinct question about a language:
///
/// - `recognitionSupported`: Apple supports dictation for this language at all
///   (server-based or on-device). If false, the mic affordance is hidden.
/// - `dictationOnDevice`: the on-device dictation model is downloaded, so
///   recognition works offline. If true, the mic shows the on-device dot.
/// - `voiceAvailable`: a usable speech-synthesis voice exists (server or on-device).
/// - `synthesisOnDevice`: a high-quality (enhanced/premium) voice exists — the
///   offline-capable tier.
struct LanguageOfflineStatus: Equatable {
    let language: Language
    let recognitionSupported: Bool
    let dictationOnDevice: Bool
    let voiceAvailable: Bool
    let synthesisOnDevice: Bool
}

/// Computed, not persisted: it reads live capability state from the speech
/// services. Mirror of the `ConsentStore` `@Observable` pattern, minus the
/// `UserDefaults` backing (there's nothing to store — the state is whatever the
/// device currently has downloaded).
@MainActor
@Observable
final class OfflineSpeechStatusStore {
    private let recognition: SpeechRecognitionService
    private let textToSpeech: TextToSpeechService

    private(set) var statuses: [LanguageOfflineStatus] = []

    init(
        recognition: SpeechRecognitionService,
        textToSpeech: TextToSpeechService
    ) {
        self.recognition = recognition
        self.textToSpeech = textToSpeech
    }

    /// Re-queries both services for every language. Model downloads can change
    /// over the app's lifetime, so the Settings view calls this on `.task`.
    func refresh() {
        statuses = Language.allCases.map { language in
            LanguageOfflineStatus(
                language: language,
                recognitionSupported: recognition.supportsRecognition(for: language),
                dictationOnDevice: recognition.supportsOnDeviceRecognition(for: language),
                voiceAvailable: textToSpeech.hasVoice(for: language),
                synthesisOnDevice: textToSpeech.supportsOnDeviceVoice(for: language)
            )
        }
    }
}