import Foundation

enum BubblePosition {
    case left
    case right
}

struct ConversationBubble: Identifiable {
    let id: UUID
    var originalText: String
    var translatedText: String
    let spokenLanguage: Language
    let translatedLanguage: Language
    let position: BubblePosition
}
