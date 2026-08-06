import Foundation

struct LanguagePair: Hashable, Codable, Sendable {
    let source: Language
    let target: Language
}

/// Hardcoded, client-side matrix of directed language pairs the backend actually
/// serves today — confirmed live against the production translator.cuni.cz bundle.
/// None of the existing clients (Android/web) discover this dynamically via the
/// API's `/languages/` or `/models/` listing endpoints; every one of them hardcodes
/// this same matrix, so we do too. Add a pair here the moment the backend adds one.
enum LanguagePairCatalog {
    static let supportedPairs: Set<LanguagePair> = [
        LanguagePair(source: .czech, target: .english),
        LanguagePair(source: .english, target: .czech),
        LanguagePair(source: .czech, target: .french),
        LanguagePair(source: .french, target: .czech),
        LanguagePair(source: .czech, target: .russian),
        LanguagePair(source: .russian, target: .czech),
        LanguagePair(source: .czech, target: .ukrainian),
        LanguagePair(source: .ukrainian, target: .czech),
        LanguagePair(source: .english, target: .french),
        LanguagePair(source: .french, target: .english),
        LanguagePair(source: .english, target: .polish),
        LanguagePair(source: .polish, target: .english),
        LanguagePair(source: .english, target: .russian),
        LanguagePair(source: .russian, target: .english),
        LanguagePair(source: .english, target: .ukrainian),
        LanguagePair(source: .ukrainian, target: .english),
    ]

    /// Czech -> Ukrainian, matching the Android app's default pair.
    static let defaultPair = LanguagePair(source: .czech, target: .ukrainian)

    /// The subset of languages that also appear on the "right" mic in Conversation
    /// mode, where the left side is always fixed to Czech (matches Android).
    static let conversationTargetLanguages: [Language] = [.english, .french, .ukrainian, .russian]

    static func isSupported(_ source: Language, _ target: Language) -> Bool {
        supportedPairs.contains(LanguagePair(source: source, target: target))
    }

    /// Valid targets for a given source — used to pre-filter the target picker so
    /// invalid pairs are unreachable in the UI rather than merely rejected later.
    static func reachableTargets(from source: Language) -> [Language] {
        supportedPairs
            .filter { $0.source == source }
            .map(\.target)
            .sorted { $0.displayName < $1.displayName }
    }

    static var allSourceLanguages: [Language] {
        Set(supportedPairs.map(\.source))
            .sorted { $0.displayName < $1.displayName }
    }
}
