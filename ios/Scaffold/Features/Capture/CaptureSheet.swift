import SwiftUI

/// Capture has exactly one job: get the thought out of working memory before it
/// evaporates. Anything that slows that down — categories, due dates, projects —
/// is a reason the thought gets lost, so none of it appears here.
struct CaptureSheet: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss

    @State private var text = ""
    @State private var justSaved = false
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Text("Whatever's in there. It doesn't have to make sense, and you don't have to sort it now.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                TextEditor(text: $text)
                    .focused($isFocused)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .frame(minHeight: 160)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.horizontal, 16)

                if justSaved {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Theme.mint)
                        Text("Saved. Keep going if there's more.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                }

                BigButton(title: "Save and keep going", systemImage: "plus.circle", tint: Theme.sky) {
                    save(keepOpen: true)
                }
                .padding(.horizontal, 16)

                BigButton(title: "Save and close", systemImage: "checkmark", tint: Theme.sky, style: .tonal) {
                    save(keepOpen: false)
                }
                .padding(.horizontal, 16)

                Spacer(minLength: 0)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Brain dump")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear { isFocused = true }
        }
    }

    private func save(keepOpen: Bool) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            if !keepOpen { dismiss() }
            return
        }
        // Each line becomes its own item — people dump in lists, and one blob is
        // far harder to triage later than five separate things.
        for line in trimmed.split(separator: "\n") {
            store.capture(String(line))
        }
        text = ""
        if keepOpen {
            withAnimation { justSaved = true }
            isFocused = true
        } else {
            dismiss()
        }
    }
}
