import SwiftUI

struct LanguagePillView: View {
    let language: Language
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(language.displayName)
                .font(.headline)
                .lineLimit(1)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.thinMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct SwapButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 32)
                .background(Color(.tertiarySystemBackground), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Swap languages"))
    }
}

struct LanguagePickerSheet: View {
    let title: String
    let languages: [Language]
    let selected: Language
    let onSelect: (Language) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(languages) { language in
                Button {
                    onSelect(language)
                    dismiss()
                } label: {
                    HStack {
                        Text(language.displayName)
                        Spacer()
                        if language == selected {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.charlesRed)
                        }
                    }
                }
                .foregroundStyle(.primary)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
