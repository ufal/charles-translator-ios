import SwiftUI
import UIKit

struct TranslateView: View {
    @Environment(AppEnvironment.self) private var appEnvironment
    @Environment(\.modelContext) private var modelContext

    @State private var isPickingSource = false
    @State private var isPickingTarget = false
    @State private var didCopy = false
    @FocusState private var isInputFocused: Bool

    private var viewModel: TranslateViewModel { appEnvironment.translateViewModel }

    var body: some View {
        VStack(spacing: 0) {
            languageBar

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    inputSection
                    Divider()
                    outputSection
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("Charles Translator")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { isInputFocused = false }
            }
        }
        .task {
            if viewModel.historyStore == nil {
                viewModel.historyStore = SwiftDataHistoryStore(modelContext: modelContext)
            }
        }
        .onChange(of: appEnvironment.pendingTranslateReload) { _, item in
            guard let item else { return }
            viewModel.consumeHistoryReload(item)
            appEnvironment.pendingTranslateReload = nil
        }
        .sheet(isPresented: $isPickingSource) {
            LanguagePickerSheet(
                title: String(localized: "picker.sourceLanguage", defaultValue: "Translate from"),
                languages: LanguagePairCatalog.allSourceLanguages,
                selected: viewModel.sourceLanguage,
                onSelect: viewModel.selectSourceLanguage
            )
        }
        .sheet(isPresented: $isPickingTarget) {
            LanguagePickerSheet(
                title: String(localized: "picker.targetLanguage", defaultValue: "Translate to"),
                languages: viewModel.reachableTargetLanguages,
                selected: viewModel.targetLanguage,
                onSelect: viewModel.selectTargetLanguage
            )
        }
        .sensoryFeedback(.success, trigger: didCopy)
    }

    private var languageBar: some View {
        HStack(spacing: 12) {
            LanguagePillView(language: viewModel.sourceLanguage) { isPickingSource = true }
            SwapButton { viewModel.swapLanguages() }
            LanguagePillView(language: viewModel.targetLanguage) { isPickingTarget = true }
            Spacer()
        }
        .padding()
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                if viewModel.inputText.isEmpty {
                    Text("Enter text")
                        .foregroundStyle(.tertiary)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                }
                TextEditor(text: Binding(
                    get: { viewModel.inputText },
                    set: { viewModel.setInputText($0, inputType: .keyboard) }
                ))
                .focused($isInputFocused)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 120)
            }

            HStack {
                if viewModel.isOverCharacterLimit {
                    Text("\(viewModel.inputText.count)/\(TranslateViewModel.maxCharacters)")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                Spacer()
                MicButton(isListening: viewModel.isListening) {
                    Task { await viewModel.toggleMic() }
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }

    private var outputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.isTranslating {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if !viewModel.outputText.isEmpty {
                Text(viewModel.outputText)
                    .font(.title3)
                    .textSelection(.enabled)

                HStack(spacing: 24) {
                    Button {
                        viewModel.speakOutput()
                    } label: {
                        Image(systemName: "speaker.wave.2")
                    }

                    Button {
                        UIPasteboard.general.string = viewModel.outputText
                        didCopy.toggle()
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                }
                .font(.system(size: 18))
                .foregroundStyle(Color.charlesRed)
            }
        }
    }
}
