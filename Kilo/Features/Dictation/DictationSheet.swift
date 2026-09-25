import SwiftUI

struct DictationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var action: VoiceAction

    init(initial: VoiceAction) {
        _action = State(initialValue: initial)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Picker("Qué registras", selection: $action) {
                    ForEach(VoiceAction.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)

                Spacer(minLength: 0)

                Image(systemName: "mic.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.tint)
                    .symbolEffect(.pulse)

                VStack(spacing: 6) {
                    Text("Te escucho")
                        .font(.title2.weight(.semibold))
                    Text(action == .stockClose ? "Di cuánto queda de cada insumo." : "Di qué compraste, cuánto y a qué precio.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer(minLength: 0)

                Button {
                    dismiss()
                } label: {
                    Text("Listo").frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar", systemImage: "xmark", role: .cancel) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
