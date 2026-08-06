import Foundation
import SwiftData

/// A single saved translation. `contentKey` gives Room-style dedup-by-content
/// for free at the persistence layer (see `HistoryStore.save`).
@Model
final class HistoryItem {
    @Attribute(.unique) var contentKey: String
    var inputText: String
    var outputText: String
    var sourceLanguageCode: String
    var targetLanguageCode: String
    var isFavourite: Bool
    var insertedAt: Date

    init(
        inputText: String,
        outputText: String,
        source: Language,
        target: Language,
        isFavourite: Bool = false,
        insertedAt: Date = .now
    ) {
        self.contentKey = HistoryItem.makeContentKey(source: source, target: target, inputText: inputText)
        self.inputText = inputText
        self.outputText = outputText
        self.sourceLanguageCode = source.rawValue
        self.targetLanguageCode = target.rawValue
        self.isFavourite = isFavourite
        self.insertedAt = insertedAt
    }

    var sourceLanguage: Language { Language(rawValue: sourceLanguageCode) ?? .czech }
    var targetLanguage: Language { Language(rawValue: targetLanguageCode) ?? .czech }

    static func makeContentKey(source: Language, target: Language, inputText: String) -> String {
        "\(source.rawValue)|\(target.rawValue)|\(inputText)"
    }
}
