import XCTest
@testable import CharlesTranslator

@MainActor
final class TranslateViewModelDebounceTests: XCTestCase {
    func testRapidTypingOnlyTranslatesOnce() async throws {
        let mockClient = MockTranslationAPIClient()
        let viewModel = TranslateViewModel(
            translationAPIClient: mockClient,
            speechRecognitionService: MockSpeechRecognitionService(),
            textToSpeechService: MockTextToSpeechService(),
            consentStore: ConsentStore(defaults: UserDefaults(suiteName: "debounce.\(UUID().uuidString)")!)
        )

        viewModel.setInputText("H", inputType: .keyboard)
        viewModel.setInputText("He", inputType: .keyboard)
        viewModel.setInputText("Hel", inputType: .keyboard)
        viewModel.setInputText("Hell", inputType: .keyboard)
        viewModel.setInputText("Hello", inputType: .keyboard)

        try await Task.sleep(for: .milliseconds(800))

        let callCount = await mockClient.callCount
        XCTAssertEqual(callCount, 1)
        XCTAssertEqual(viewModel.outputText, "mock")
    }

    func testEmptyInputSkipsTranslationEntirely() async throws {
        let mockClient = MockTranslationAPIClient()
        let viewModel = TranslateViewModel(
            translationAPIClient: mockClient,
            speechRecognitionService: MockSpeechRecognitionService(),
            textToSpeechService: MockTextToSpeechService(),
            consentStore: ConsentStore(defaults: UserDefaults(suiteName: "debounce.\(UUID().uuidString)")!)
        )

        viewModel.setInputText("   ", inputType: .keyboard)
        try await Task.sleep(for: .milliseconds(800))

        let callCount = await mockClient.callCount
        XCTAssertEqual(callCount, 0)
        XCTAssertEqual(viewModel.outputText, "")
    }
}
