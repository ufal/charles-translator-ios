import Foundation

/// Mirrors the `inputType` values both existing clients send, used for the
/// backend's own analytics of how text arrived (not surfaced to the user).
enum TranslationInputMethod: String, Sendable {
    case keyboard
    case voice
    case clipboard
    case history
    case swapLanguages = "swap-languages"
    case languageChanged = "language-changed"
    case translation
}

struct TranslationRequest: Sendable {
    let inputText: String
    let source: Language
    let target: Language
    let logInput: Bool
    let inputType: TranslationInputMethod
    let author: String?
}

struct TranslationResult: Sendable, Equatable {
    let segments: [String]

    var joinedText: String { segments.joined() }
}
