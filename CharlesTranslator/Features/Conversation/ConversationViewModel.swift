import Foundation

/// Left side is always Czech (matches Android); right side is user-selectable
/// from `LanguagePairCatalog.conversationTargetLanguages`. Voice-only, no text
/// input, no persistence — mirrors Android's Conversation screen exactly.
@MainActor
@Observable
final class ConversationViewModel {
    let leftLanguage: Language = .czech
    private(set) var rightLanguage: Language = .english

    private(set) var bubbles: [ConversationBubble] = []
    private(set) var activeSide: BubblePosition?
    var errorMessage: String?

    private let translationAPIClient: TranslationAPIClient
    private let speechRecognitionService: SpeechRecognitionService
    private let consentStore: ConsentStore

    private var translateTask: Task<Void, Never>?

    /// Only show a per-bubble language tag once more than two distinct
    /// languages have appeared, matching Android's `groupingBy` threshold.
    var showsLanguageLabels: Bool {
        Set(bubbles.map(\.spokenLanguage)).count > 2
    }

    init(
        translationAPIClient: TranslationAPIClient,
        speechRecognitionService: SpeechRecognitionService,
        consentStore: ConsentStore
    ) {
        self.translationAPIClient = translationAPIClient
        self.speechRecognitionService = speechRecognitionService
        self.consentStore = consentStore
    }

    func selectRightLanguage(_ language: Language) {
        guard activeSide == nil else { return }
        rightLanguage = language
    }

    func clear() {
        bubbles.removeAll()
    }

    func toggleMic(_ side: BubblePosition) async {
        if activeSide == side {
            speechRecognitionService.stopListening()
            return
        }
        guard activeSide == nil else { return }

        activeSide = side
        errorMessage = nil

        let spokenLanguage = side == .left ? leftLanguage : rightLanguage
        let targetLanguage = side == .left ? rightLanguage : leftLanguage

        let bubbleID = UUID()
        bubbles.append(
            ConversationBubble(
                id: bubbleID,
                originalText: "",
                translatedText: "",
                spokenLanguage: spokenLanguage,
                translatedLanguage: targetLanguage,
                position: side
            )
        )

        do {
            let finalText = try await speechRecognitionService.startListening(locale: spokenLanguage) { [weak self] partial in
                self?.updateBubbleText(bubbleID, originalText: partial)
                self?.scheduleTranslate(bubbleID: bubbleID, text: partial, source: spokenLanguage, target: targetLanguage)
            }
            updateBubbleText(bubbleID, originalText: finalText)
            scheduleTranslate(bubbleID: bubbleID, text: finalText, source: spokenLanguage, target: targetLanguage)
        } catch is CancellationError {
            // stopped intentionally
        } catch SpeechRecognitionError.permissionDenied {
            errorMessage = String(
                localized: "error.speechPermissionDenied",
                defaultValue: "Enable Microphone and Speech Recognition access in Settings to use voice input."
            )
        } catch {
            errorMessage = String(
                localized: "error.speechUnavailable",
                defaultValue: "Speech recognition isn't available right now."
            )
        }

        activeSide = nil
    }

    private func updateBubbleText(_ id: UUID, originalText: String) {
        guard let index = bubbles.firstIndex(where: { $0.id == id }) else { return }
        bubbles[index].originalText = originalText
    }

    private func scheduleTranslate(bubbleID: UUID, text: String, source: Language, target: Language) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        translateTask?.cancel()
        translateTask = Task {
            let request = TranslationRequest(
                inputText: text,
                source: source,
                target: target,
                logInput: consentStore.dataCollectionConsent,
                inputType: .voice,
                author: consentStore.organizationName
            )
            guard let result = try? await translationAPIClient.translate(request), !Task.isCancelled else { return }
            guard let index = bubbles.firstIndex(where: { $0.id == bubbleID }) else { return }
            bubbles[index].translatedText = result.joinedText
        }
    }
}
