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
}
