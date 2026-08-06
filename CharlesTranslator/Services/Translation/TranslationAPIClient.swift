import Foundation

protocol TranslationAPIClient: Sendable {
    func translate(_ request: TranslationRequest) async throws -> TranslationResult
}
