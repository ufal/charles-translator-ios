import Foundation
import AVFoundation

@MainActor
protocol TextToSpeechService: AnyObject {
    var isSpeaking: Bool { get }
    func speak(_ text: String, language: Language)
    func stop()

    /// Whether a usable voice exists for the given language — server-provided
    /// or on-device. Drives whether the speech-output affordance is offered.
    func hasVoice(for locale: Language) -> Bool

    /// Whether a high-quality (enhanced/premium) voice exists for the given
    /// language — the on-device/offline tier. Drives the on-device indicator.
    /// (`AVSpeechSynthesisVoice` has no public "is downloaded" flag; presence of
    /// an `.enhanced`/`.premium` voice for the locale is the standard proxy.)
    func supportsOnDeviceVoice(for locale: Language) -> Bool
}

@MainActor
@Observable
final class LiveTextToSpeechService: NSObject, TextToSpeechService {
    private let synthesizer = AVSpeechSynthesizer()
    private(set) var isSpeaking = false

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String, language: Language) {
        guard !text.isEmpty else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: .duckOthers)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language.bcp47Locale)
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    func hasVoice(for locale: Language) -> Bool {
        AVSpeechSynthesisVoice(language: locale.bcp47Locale) != nil
    }

    func supportsOnDeviceVoice(for locale: Language) -> Bool {
        AVSpeechSynthesisVoice.speechVoices().contains { voice in
            voice.language == locale.bcp47Locale
                && (voice.quality == .premium || voice.quality == .enhanced)
        }
    }
}

extension LiveTextToSpeechService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in self.isSpeaking = true }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.isSpeaking = false }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in self.isSpeaking = false }
    }
}
