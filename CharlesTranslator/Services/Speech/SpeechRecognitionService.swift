import Foundation

enum SpeechRecognitionError: Error, Equatable, Sendable {
    case permissionDenied
    case recognizerUnavailable
}

@MainActor
protocol SpeechRecognitionService: AnyObject {
    /// Starts listening in the given language's locale, invoking `onPartialTranscript`
    /// with the live-updating transcript (mirrors Android's `EXTRA_PARTIAL_RESULTS`),
    /// and resolving with the final transcript once `stopListening()` is called or the
    /// recognizer detects the end of speech on its own.
    func startListening(
        locale: Language,
        onPartialTranscript: @escaping (String) -> Void
    ) async throws -> String

    func stopListening()

    /// Whether Apple supports speech recognition for the given source language
    /// at all — server-based or on-device. Drives whether the mic affordance is
    /// shown at all, independent of transient availability or whether the
    /// on-device model is downloaded.
    func supportsRecognition(for locale: Language) -> Bool

    /// Whether the on-device dictation model for the given source language is
    /// downloaded, i.e. recognition can run offline. Drives the on-device
    /// indicator on the mic affordance. (`SFSpeechRecognizer` has no public
    /// "is downloaded" flag; `supportsOnDeviceRecognition` is the standard proxy.)
    func supportsOnDeviceRecognition(for locale: Language) -> Bool
}
