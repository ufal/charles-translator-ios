import XCTest
@testable import CharlesTranslator

final class LanguagePairCatalogTests: XCTestCase {
    func testAllSixteenConfirmedPairsAreSupported() {
        let pairs: [(Language, Language)] = [
            (.czech, .english), (.english, .czech),
            (.czech, .french), (.french, .czech),
            (.czech, .russian), (.russian, .czech),
            (.czech, .ukrainian), (.ukrainian, .czech),
            (.english, .french), (.french, .english),
            (.english, .polish), (.polish, .english),
            (.english, .russian), (.russian, .english),
            (.english, .ukrainian), (.ukrainian, .english),
        ]
        XCTAssertEqual(pairs.count, 16)
        for (source, target) in pairs {
            XCTAssertTrue(LanguagePairCatalog.isSupported(source, target), "\(source) -> \(target) should be supported")
        }
    }

    func testInvalidPairIsNotSupported() {
        XCTAssertFalse(LanguagePairCatalog.isSupported(.french, .polish))
        XCTAssertFalse(LanguagePairCatalog.isSupported(.polish, .french))
    }

    func testReachableTargetsFromCzech() {
        let targets = Set(LanguagePairCatalog.reachableTargets(from: .czech))
        XCTAssertEqual(targets, [.english, .french, .russian, .ukrainian])
    }

    func testAllSourceLanguagesIsNonEmptyAndStable() {
        let sources = LanguagePairCatalog.allSourceLanguages
        XCTAssertFalse(sources.isEmpty)
        XCTAssertEqual(Set(sources), Set(LanguagePairCatalog.allSourceLanguages))
    }
}
