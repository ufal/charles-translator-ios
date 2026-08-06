import Foundation

/// The six languages the backend currently supports translating between.
enum Language: String, CaseIterable, Codable, Identifiable, Sendable {
    case czech = "cs"
    case english = "en"
    case french = "fr"
    case polish = "pl"
    case russian = "ru"
    case ukrainian = "uk"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .czech:
            String(localized: "language.cs", defaultValue: "Czech")
        case .english:
            String(localized: "language.en", defaultValue: "English")
        case .french:
            String(localized: "language.fr", defaultValue: "French")
        case .polish:
            String(localized: "language.pl", defaultValue: "Polish")
        case .russian:
            String(localized: "language.ru", defaultValue: "Russian")
        case .ukrainian:
            String(localized: "language.uk", defaultValue: "Ukrainian")
        }
    }

    /// Drives both `SFSpeechRecognizer(locale:)` and `AVSpeechSynthesisVoice(language:)`.
    var bcp47Locale: String {
        switch self {
        case .czech: "cs-CZ"
        case .english: "en-US"
        case .french: "fr-FR"
        case .polish: "pl-PL"
        case .russian: "ru-RU"
        case .ukrainian: "uk-UA"
        }
    }
}
