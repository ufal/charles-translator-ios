import Foundation

/// Talks to the confirmed live endpoint: `POST /services/translation/api/v2/languages/`
/// (the HAL-documented `/models/{pair}` endpoint is discovery-only — no real client
/// ever calls it to translate). Form-encoded body, `[String]` JSON response.
final class LiveTranslationAPIClient: TranslationAPIClient {
    private let session: URLSession
    private let endpoint = URL(string: "https://lindat.mff.cuni.cz/services/translation/api/v2/languages/")!
    private let appVersion: String

    init(session: URLSession = .shared, appVersion: String = Bundle.main.shortVersionString) {
        self.session = session
        self.appVersion = appVersion
    }

    func translate(_ request: TranslationRequest) async throws -> TranslationResult {
        guard LanguagePairCatalog.isSupported(request.source, request.target) else {
            throw TranslationError.unsupportedPair
        }

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.setValue("charles-ios", forHTTPHeaderField: "X-Frontend")
        urlRequest.setValue(appVersion, forHTTPHeaderField: "X-App-Version")
        urlRequest.httpBody = Self.formBody(for: request)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            if (error as? URLError)?.code == .cancelled {
                throw CancellationError()
            }
            throw TranslationError.network(underlying: error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw TranslationError.decoding
        }

        switch http.statusCode {
        case 200:
            guard let segments = try? JSONDecoder().decode([String].self, from: data) else {
                throw TranslationError.decoding
            }
            return TranslationResult(segments: segments)
        case 413:
            throw TranslationError.tooLarge
        case 504:
            throw TranslationError.timeout
        case 501:
            let body = try? JSONDecoder().decode(UnsupportedAPIBody.self, from: data)
            throw TranslationError.unsupportedAPIVersion(title: body?.title ?? "", message: body?.message ?? "")
        default:
            throw TranslationError.unknown(statusCode: http.statusCode)
        }
    }

    private struct UnsupportedAPIBody: Decodable {
        let title: String
        let message: String
    }

    private static func formBody(for request: TranslationRequest) -> Data {
        var pairs: [(String, String)] = [
            ("input_text", request.inputText),
            ("src", request.source.rawValue),
            ("tgt", request.target.rawValue),
            ("logInput", request.logInput ? "true" : "false"),
            ("inputType", request.inputType.rawValue),
        ]
        if let author = request.author, !author.isEmpty {
            pairs.append(("author", author))
        }
        let body = pairs
            .map { "\($0.0)=\($0.1.formURLEncoded)" }
            .joined(separator: "&")
        return Data(body.utf8)
    }
}

extension StringProtocol {
    /// `application/x-www-form-urlencoded` encoding (space -> `+`), matching what
    /// the web client's `URLSearchParams` produces against the same backend.
    var formURLEncoded: String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        let percentEncoded = String(self).addingPercentEncoding(withAllowedCharacters: allowed) ?? String(self)
        return percentEncoded.replacingOccurrences(of: " ", with: "+")
    }
}
