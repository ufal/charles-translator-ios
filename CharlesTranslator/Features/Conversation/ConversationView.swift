import SwiftUI

struct ConversationView: View {
    @Environment(AppEnvironment.self) private var appEnvironment

    private var viewModel: ConversationViewModel { appEnvironment.conversationViewModel }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.bubbles.isEmpty {
                ContentUnavailableView(
                    "Tap a microphone to start a conversation",
                    systemImage: "bubble.left.and.bubble.right"
                )
                .frame(maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(viewModel.bubbles) { bubble in
                                ConversationBubbleView(bubble: bubble, showsLanguageLabel: viewModel.showsLanguageLabels)
                                    .id(bubble.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.bubbles.count) {
                        if let last = viewModel.bubbles.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            actionsRow
        }
        .navigationTitle("Conversation")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Clear", role: .destructive) { viewModel.clear() }
                    .disabled(viewModel.bubbles.isEmpty)
            }
        }
    }

    private var actionsRow: some View {
        HStack {
            VStack(spacing: 6) {
                MicButton(isListening: viewModel.activeSide == .left) {
                    Task { await viewModel.toggleMic(.left) }
                }
                .disabled(viewModel.activeSide == .right)
                Text(viewModel.leftLanguage.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 6) {
                MicButton(isListening: viewModel.activeSide == .right) {
                    Task { await viewModel.toggleMic(.right) }
                }
                .disabled(viewModel.activeSide == .left)

                Menu {
                    ForEach(LanguagePairCatalog.conversationTargetLanguages) { language in
                        Button(language.displayName) {
                            viewModel.selectRightLanguage(language)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(viewModel.rightLanguage.displayName)
                        Image(systemName: "chevron.down")
                    }
                    .font(.caption)
                }
                .disabled(viewModel.activeSide != nil)
            }
        }
        .padding()
    }
}

private struct ConversationBubbleView: View {
    let bubble: ConversationBubble
    let showsLanguageLabel: Bool

    var body: some View {
        HStack {
            if bubble.position == .right { Spacer(minLength: 40) }

            VStack(alignment: bubble.position == .left ? .leading : .trailing, spacing: 4) {
                if showsLanguageLabel {
                    Text(bubble.spokenLanguage.displayName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(bubble.originalText)
                    .padding(10)
                    .background(
                        bubble.position == .left ? Color(.secondarySystemBackground) : Color.charlesRed.opacity(0.15),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                if !bubble.translatedText.isEmpty {
                    Text(bubble.translatedText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                }
            }

            if bubble.position == .left { Spacer(minLength: 40) }
        }
    }
}
