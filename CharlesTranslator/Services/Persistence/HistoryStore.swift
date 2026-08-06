import Foundation
import SwiftData

@MainActor
protocol HistoryStore: AnyObject {
    /// Insert-or-update by content key, mirroring Android's Room dedup behavior.
    func save(inputText: String, outputText: String, source: Language, target: Language) throws
    func toggleFavourite(_ item: HistoryItem) throws
    func delete(_ item: HistoryItem) throws
    func all() throws -> [HistoryItem]
    func favourites() throws -> [HistoryItem]
}

@MainActor
final class SwiftDataHistoryStore: HistoryStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func save(inputText: String, outputText: String, source: Language, target: Language) throws {
        let key = HistoryItem.makeContentKey(source: source, target: target, inputText: inputText)
        var descriptor = FetchDescriptor<HistoryItem>(predicate: #Predicate { $0.contentKey == key })
        descriptor.fetchLimit = 1

        if let existing = try modelContext.fetch(descriptor).first {
            existing.outputText = outputText
            existing.insertedAt = .now
        } else {
            let item = HistoryItem(inputText: inputText, outputText: outputText, source: source, target: target)
            modelContext.insert(item)
        }
        try modelContext.save()
    }

    func toggleFavourite(_ item: HistoryItem) throws {
        item.isFavourite.toggle()
        try modelContext.save()
    }

    func delete(_ item: HistoryItem) throws {
        modelContext.delete(item)
        try modelContext.save()
    }

    func all() throws -> [HistoryItem] {
        let descriptor = FetchDescriptor<HistoryItem>(sortBy: [SortDescriptor(\.insertedAt, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }

    func favourites() throws -> [HistoryItem] {
        let descriptor = FetchDescriptor<HistoryItem>(
            predicate: #Predicate { $0.isFavourite },
            sortBy: [SortDescriptor(\.insertedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
}
