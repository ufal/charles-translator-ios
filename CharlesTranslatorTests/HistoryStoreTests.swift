import XCTest
import SwiftData
@testable import CharlesTranslator

@MainActor
final class HistoryStoreTests: XCTestCase {
    private func makeStore() throws -> SwiftDataHistoryStore {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: HistoryItem.self, configurations: config)
        return SwiftDataHistoryStore(modelContext: ModelContext(container))
    }

    func testSaveThenFetchRoundTrip() throws {
        let store = try makeStore()
        try store.save(inputText: "Ahoj", outputText: "Hello", source: .czech, target: .english)

        let all = try store.all()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.inputText, "Ahoj")
        XCTAssertEqual(all.first?.outputText, "Hello")
    }

    func testSavingSameContentTwiceUpdatesRatherThanDuplicates() throws {
        let store = try makeStore()
        try store.save(inputText: "Ahoj", outputText: "Hello", source: .czech, target: .english)
        try store.save(inputText: "Ahoj", outputText: "Hello there", source: .czech, target: .english)

        let all = try store.all()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.outputText, "Hello there")
    }

    func testToggleFavouriteAndFilter() throws {
        let store = try makeStore()
        try store.save(inputText: "Ahoj", outputText: "Hello", source: .czech, target: .english)
        try store.save(inputText: "Dobrý den", outputText: "Good day", source: .czech, target: .english)

        let item = try store.all().first { $0.inputText == "Ahoj" }!
        XCTAssertFalse(item.isFavourite)
        try store.toggleFavourite(item)
        XCTAssertTrue(item.isFavourite)

        let favourites = try store.favourites()
        XCTAssertEqual(favourites.count, 1)
        XCTAssertEqual(favourites.first?.inputText, "Ahoj")
    }

    func testDeleteRemovesItem() throws {
        let store = try makeStore()
        try store.save(inputText: "Ahoj", outputText: "Hello", source: .czech, target: .english)
        let item = try store.all()[0]

        try store.delete(item)
        XCTAssertTrue(try store.all().isEmpty)
    }
}
