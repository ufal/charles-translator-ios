import XCTest
@testable import CharlesTranslator

@MainActor
final class ConsentStoreTests: XCTestCase {
    private func makeStore() -> ConsentStore {
        let defaults = UserDefaults(suiteName: "ConsentStoreTests.\(UUID().uuidString)")!
        return ConsentStore(defaults: defaults)
    }

    func testDefaultStateIsNotAnswered() {
        let store = makeStore()
        XCTAssertFalse(store.hasAnswered)
        XCTAssertFalse(store.dataCollectionConsent)
        XCTAssertEqual(store.organizationName, "")
    }

    func testRecordingConsentSetsHasAnswered() {
        let store = makeStore()
        store.recordConsentDecision(agreed: true)
        XCTAssertTrue(store.hasAnswered)
        XCTAssertTrue(store.dataCollectionConsent)
    }

    func testOrganizationNamePersistsIndependentlyOfConsent() {
        let store = makeStore()
        store.organizationName = "UFAL"
        store.recordConsentDecision(agreed: false)
        XCTAssertEqual(store.organizationName, "UFAL")
        XCTAssertFalse(store.dataCollectionConsent)
        XCTAssertTrue(store.hasAnswered)
    }

    func testResetClearsEverything() {
        let store = makeStore()
        store.organizationName = "UFAL"
        store.recordConsentDecision(agreed: true)

        store.reset()

        XCTAssertFalse(store.hasAnswered)
        XCTAssertFalse(store.dataCollectionConsent)
        XCTAssertEqual(store.organizationName, "")
    }
}
