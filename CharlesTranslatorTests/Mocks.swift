import Foundation
@testable import CharlesTranslator

actor MockTranslationAPIClient: TranslationAPIClient {
    private(set) var callCount = 0
    private var result: Result<TranslationResult, Error> = .success(TranslationResult(segments: ["mock"]))

    func setResult(_ newResult: Result<TranslationResult, Error>) {
        result = newResult
    }

    func translate(_ request: TranslationRequest) async throws -> TranslationResult {
        callCount += 1
        return try result.get()
    }
}

@MainActor
final class MockSpeechRecognitionService: SpeechRecognitionService {
    func startListening(locale: Language, onPartialTranscript: @escaping (String) -> Void) async throws -> String {
        ""
    }
    func stopListening() {}
}

@MainActor
final class MockTextToSpeechService: TextToSpeechService {
    private(set) var isSpeaking = false
    private(set) var lastSpokenText: String?

    func speak(_ text: String, language: Language) {
        lastSpokenText = text
    }
    func stop() {}
}
