import Foundation

@MainActor
@Observable
final class TranslateViewModel {
    static let maxCharacters = 1000

    private(set) var sourceLanguage: Language = LanguagePairCatalog.defaultPair.source
    private(set) var targetLanguage: Language = LanguagePairCatalog.defaultPair.target
    private(set) var inputText: String = ""
    private(set) var outputText: String = ""
    private(set) var isTranslating = false
    private(set) var isListening = false
    var errorMessage: String?

    /// Set by the view once `@Environment(\.modelContext)` is available.
    var historyStore: HistoryStore?

    private let translationAPIClient: TranslationAPIClient
    private let speechRecognitionService: SpeechRecognitionService
    private let textToSpeechService: TextToSpeechService
    private let consentStore: ConsentStore

    private var translateTask: Task<Void, Never>?
    private var saveTask: Task<Void, Never>?

    var reachableTargetLanguages: [Language] {
        LanguagePairCatalog.reachableTargets(from: sourceLanguage)
    }

    var isOverCharacterLimit: Bool {
        inputText.count > Self.maxCharacters
    }

    var canSpeakOutput: Bool {
        !outputText.isEmpty
    }

    init(
        translationAPIClient: TranslationAPIClient,
        speechRecognitionService: SpeechRecognitionService,
        textToSpeechService: TextToSpeechService,
        consentStore: ConsentStore
    ) {
        self.translationAPIClient = translationAPIClient
        self.speechRecognitionService = speechRecognitionService
        self.textToSpeechService = textToSpeechService
        self.consentStore = consentStore
    }

    /// The single write path for user-driven text changes (typing or voice) —
    /// updates the text and (re)schedules a debounced translate.
    func setInputText(_ text: String, inputType: TranslationInputMethod) {
        inputText = text
        scheduleTranslate(inputType: inputType)
    }

    func selectSourceLanguage(_ language: Language) {
        guard language != sourceLanguage else { return }
        sourceLanguage = language
        if !reachableTargetLanguages.contains(targetLanguage) {
            targetLanguage = reachableTargetLanguages.first ?? targetLanguage
        }
        scheduleTranslate(inputType: .languageChanged)
    }

    func selectTargetLanguage(_ language: Language) {
        guard language != targetLanguage else { return }
        targetLanguage = language
        scheduleTranslate(inputType: .languageChanged)
    }

    /// Always safe: every pair in `LanguagePairCatalog` exists in both directions.
    func swapLanguages() {
        swap(&sourceLanguage, &targetLanguage)
        inputText = outputText
        scheduleTranslate(inputType: .swapLanguages)
    }

    /// Repopulates from a tapped History row without re-hitting the network —
    /// both input and output text are already known.
    func consumeHistoryReload(_ item: HistoryItem) {
        translateTask?.cancel()
        errorMessage = nil
        sourceLanguage = item.sourceLanguage
        targetLanguage = item.targetLanguage
        inputText = item.inputText
        outputText = item.outputText
    }

    private func scheduleTranslate(inputType: TranslationInputMethod) {
        translateTask?.cancel()
        errorMessage = nil

        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            outputText = ""
            return
        }
        guard !isOverCharacterLimit else {
            errorMessage = TranslationError.tooLarge.userMessage
            return
        }

        translateTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await self.performTranslate(inputType: inputType)
        }
    }

    private func performTranslate(inputType: TranslationInputMethod) async {
        isTranslating = true
        defer { isTranslating = false }

        let request = TranslationRequest(
            inputText: inputText,
            source: sourceLanguage,
            target: targetLanguage,
            logInput: consentStore.dataCollectionConsent,
            inputType: inputType,
            author: consentStore.organizationName
        )

        do {
            let result = try await translationAPIClient.translate(request)
            guard !Task.isCancelled else { return }
            outputText = result.joinedText
            errorMessage = nil
            scheduleSave()
        } catch is CancellationError {
            // Superseded by a newer request — not a user-facing error.
        } catch let error as TranslationError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = TranslationError.unknown(statusCode: -1).userMessage
        }
    }

    private func scheduleSave() {
        guard let historyStore else { return }
        saveTask?.cancel()
        let text = inputText
        let output = outputText
        let source = sourceLanguage
        let target = targetLanguage
        saveTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            try? historyStore.save(inputText: text, outputText: output, source: source, target: target)
        }
    }

    func toggleMic() async {
        if isListening {
            speechRecognitionService.stopListening()
            return
        }
        isListening = true
        errorMessage = nil
        do {
            let finalText = try await speechRecognitionService.startListening(locale: sourceLanguage) { [weak self] partial in
                self?.setInputText(partial, inputType: .voice)
            }
            isListening = false
            setInputText(finalText, inputType: .voice)
        } catch is CancellationError {
            isListening = false
        } catch SpeechRecognitionError.permissionDenied {
            isListening = false
            errorMessage = String(
                localized: "error.speechPermissionDenied",
                defaultValue: "Enable Microphone and Speech Recognition access in Settings to use voice input."
            )
        } catch {
            isListening = false
            errorMessage = String(
                localized: "error.speechUnavailable",
                defaultValue: "Speech recognition isn't available right now."
            )
        }
    }

    func speakOutput() {
        textToSpeechService.speak(outputText, language: targetLanguage)
    }
}
