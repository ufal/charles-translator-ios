import Foundation

enum AppTab: Hashable {
    case translate
    case conversation
    case history
    case settings
}

/// Composes every service once at launch and is injected into the SwiftUI
/// environment. Deliberately not a DI framework — five services don't need one.
@MainActor
@Observable
final class AppEnvironment {
    let translationAPIClient: TranslationAPIClient
    let textToSpeechService: TextToSpeechService
    let consentStore: ConsentStore
    let offlineSpeechStatusStore: OfflineSpeechStatusStore

    /// Owned here (rather than created fresh per-appearance in the view) so
    /// in-progress text and results survive switching tabs.
    let translateViewModel: TranslateViewModel
    let conversationViewModel: ConversationViewModel

    var selectedTab: AppTab = .translate

    /// Set by `HistoryViewModel` when the user taps a row; observed by
    /// `TranslateViewModel` to reload it and switch tabs — the one cross-tab
    /// intent in the app, so a full router/coordinator isn't warranted.
    var pendingTranslateReload: HistoryItem?

    init(
        translationAPIClient: TranslationAPIClient = LiveTranslationAPIClient(),
        translateSpeechRecognitionService: SpeechRecognitionService = LiveSpeechRecognitionService(),
        conversationSpeechRecognitionService: SpeechRecognitionService = LiveSpeechRecognitionService(),
        textToSpeechService: TextToSpeechService = LiveTextToSpeechService(),
        consentStore: ConsentStore = ConsentStore()
    ) {
        self.translationAPIClient = translationAPIClient
        self.textToSpeechService = textToSpeechService
        self.consentStore = consentStore
        self.offlineSpeechStatusStore = OfflineSpeechStatusStore(
            recognition: translateSpeechRecognitionService,
            textToSpeech: textToSpeechService
        )
        self.translateViewModel = TranslateViewModel(
            translationAPIClient: translationAPIClient,
            speechRecognitionService: translateSpeechRecognitionService,
            textToSpeechService: textToSpeechService,
            consentStore: consentStore
        )
        self.conversationViewModel = ConversationViewModel(
            translationAPIClient: translationAPIClient,
            speechRecognitionService: conversationSpeechRecognitionService,
            consentStore: consentStore
        )
    }

    func reloadIntoTranslate(_ item: HistoryItem) {
        pendingTranslateReload = item
        selectedTab = .translate
    }
}
