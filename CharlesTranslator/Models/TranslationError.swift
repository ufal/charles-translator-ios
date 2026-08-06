import Foundation

/// Mapped 1:1 to the HTTP semantics confirmed against the live backend.
enum TranslationError: Error, Equatable, Sendable {
    /// HTTP 413 — input text too large.
    case tooLarge
    /// HTTP 504 — translation timed out.
    case timeout
    /// HTTP 501 — client's API usage is no longer supported by the backend.
    case unsupportedAPIVersion(title: String, message: String)
    /// Transport-level failure (offline, DNS, TLS, etc).
    case network(underlying: String)
    /// Response body wasn't the expected `[String]` JSON array.
    case decoding
    /// Any other non-200 status code.
    case unknown(statusCode: Int)
    /// The requested language pair isn't in `LanguagePairCatalog`.
    case unsupportedPair
}

extension TranslationError {
    var userMessage: String {
        switch self {
        case .tooLarge:
            String(localized: "error.tooLarge", defaultValue: "This text is too long to translate.")
        case .timeout:
            String(localized: "error.timeout", defaultValue: "Translation took too long and timed out.")
        case .unsupportedAPIVersion(_, let message) where !message.isEmpty:
            message
        case .unsupportedAPIVersion:
            String(localized: "error.unsupportedApiVersion", defaultValue: "This app version is no longer supported. Please update.")
        case .network:
            String(localized: "error.network", defaultValue: "Couldn't reach the translation service. Check your connection.")
        case .decoding:
            String(localized: "error.decoding", defaultValue: "The translation service returned an unexpected response.")
        case .unknown:
            String(localized: "error.unknown", defaultValue: "Something went wrong while translating.")
        case .unsupportedPair:
            String(localized: "error.unsupportedPair", defaultValue: "Cannot translate between these two languages.")
        }
    }
}
