import XCTest
@testable import CharlesTranslator

final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

final class TranslationAPIClientTests: XCTestCase {
    private func makeClient() -> LiveTranslationAPIClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return LiveTranslationAPIClient(session: URLSession(configuration: config), appVersion: "1.0")
    }

    private func makeRequest(text: String = "Hello", source: Language = .english, target: Language = .czech) -> TranslationRequest {
        TranslationRequest(inputText: text, source: source, target: target, logInput: false, inputType: .keyboard, author: nil)
    }

    func testSuccessfulTranslationJoinsSegments() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let data = try! JSONEncoder().encode(["Ahoj ", "světe."])
            return (response, data)
        }
        let result = try await makeClient().translate(makeRequest())
        XCTAssertEqual(result.joinedText, "Ahoj světe.")
    }

    func testTooLargeMapsTo413() async {
        MockURLProtocol.requestHandler = { request in
            (HTTPURLResponse(url: request.url!, statusCode: 413, httpVersion: nil, headerFields: nil)!, Data())
        }
        await expect(TranslationError.tooLarge) { try await self.makeClient().translate(self.makeRequest()) }
    }

    func testTimeoutMapsTo504() async {
        MockURLProtocol.requestHandler = { request in
            (HTTPURLResponse(url: request.url!, statusCode: 504, httpVersion: nil, headerFields: nil)!, Data())
        }
        await expect(TranslationError.timeout) { try await self.makeClient().translate(self.makeRequest()) }
    }

    func testUnsupportedAPIVersionMapsTo501WithBody() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 501, httpVersion: nil, headerFields: nil)!
            let body = try! JSONEncoder().encode(["title": "Unsupported", "message": "Please update the app."])
            return (response, body)
        }
        do {
            _ = try await makeClient().translate(makeRequest())
            XCTFail("Expected to throw")
        } catch TranslationError.unsupportedAPIVersion(let title, let message) {
            XCTAssertEqual(title, "Unsupported")
            XCTAssertEqual(message, "Please update the app.")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testUnknownStatusCodeMapsToUnknown() async {
        MockURLProtocol.requestHandler = { request in
            (HTTPURLResponse(url: request.url!, statusCode: 418, httpVersion: nil, headerFields: nil)!, Data())
        }
        await expect(TranslationError.unknown(statusCode: 418)) { try await self.makeClient().translate(self.makeRequest()) }
    }

    func testMalformedBodyMapsToDecodingError() async {
        MockURLProtocol.requestHandler = { request in
            (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, Data("not json".utf8))
        }
        await expect(TranslationError.decoding) { try await self.makeClient().translate(self.makeRequest()) }
    }

    func testUnsupportedPairThrowsWithoutHittingNetwork() async {
        MockURLProtocol.requestHandler = nil
        await expect(TranslationError.unsupportedPair) {
            try await self.makeClient().translate(self.makeRequest(source: .french, target: .polish))
        }
    }

    private func expect(_ expected: TranslationError, _ operation: @escaping () async throws -> TranslationResult) async {
        do {
            _ = try await operation()
            XCTFail("Expected \(expected) to be thrown")
        } catch let error as TranslationError {
            XCTAssertEqual(error, expected)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
