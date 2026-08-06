import SwiftUI
import SwiftData

/// Backed directly by `@Query` for live SwiftData reactivity rather than going
/// through `HistoryStore` here — the store protocol exists for `TranslateViewModel`
/// (testable saves) and for the "erase all data" bulk delete in Settings.
struct HistoryView: View {
    @Environment(AppEnvironment.self) private var appEnvironment
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HistoryItem.insertedAt, order: .reverse) private var allItems: [HistoryItem]

    @State private var selectedTab: HistoryTab = .all

    private enum HistoryTab: String, CaseIterable {
        case all = "All"
        case favourites = "Favourites"
    }

    private var visibleItems: [HistoryItem] {
        switch selectedTab {
        case .all: allItems
        case .favourites: allItems.filter(\.isFavourite)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("History filter", selection: $selectedTab) {
                ForEach(HistoryTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding()

            if visibleItems.isEmpty {
                ContentUnavailableView(
                    selectedTab == .all ? "No history yet" : "No favourites yet",
                    systemImage: "clock"
                )
            } else {
                List {
                    ForEach(visibleItems) { item in
                        HistoryRow(item: item, onSpeak: { speak(item) })
                            .contentShape(Rectangle())
                            .onTapGesture { appEnvironment.reloadIntoTranslate(item) }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    delete(item)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    toggleFavourite(item)
                                } label: {
                                    Label(
                                        item.isFavourite ? "Unfavourite" : "Favourite",
                                        systemImage: item.isFavourite ? "star.slash" : "star"
                                    )
                                }
                                .tint(.yellow)
                            }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("History")
    }

    private func delete(_ item: HistoryItem) {
        modelContext.delete(item)
        try? modelContext.save()
    }

    private func toggleFavourite(_ item: HistoryItem) {
        item.isFavourite.toggle()
        try? modelContext.save()
    }

    private func speak(_ item: HistoryItem) {
        appEnvironment.textToSpeechService.speak(item.outputText, language: item.targetLanguage)
    }
}

private struct HistoryRow: View {
    let item: HistoryItem
    let onSpeak: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(item.sourceLanguage.displayName)
                Image(systemName: "arrow.right").font(.caption2)
                Text(item.targetLanguage.displayName)
                if item.isFavourite {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                }
                Spacer()
                Button(action: onSpeak) {
                    Image(systemName: "speaker.wave.2")
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.charlesRed)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text(item.inputText)
                .font(.body)
                .lineLimit(2)
            Text(item.outputText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}
