import SwiftUI

struct DictationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var action: VoiceAction
    @State private var processing = false
    @State private var startDate = Date()
    let onFinish: (VoiceAction) -> Void

    init(initial: VoiceAction, onFinish: @escaping (VoiceAction) -> Void) {
        _action = State(initialValue: initial)
        self.onFinish = onFinish
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Picker("Qué registras", selection: $action) {
                    ForEach(VoiceAction.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .disabled(processing)

                Spacer(minLength: 0)

                if processing {
                    VStack(spacing: 16) {
                        ProgressView()
                            .controlSize(.large)
                        Text("Procesando…")
                            .font(.title2.weight(.semibold))
                    }
                } else {
                    listeningState
                }

                Spacer(minLength: 0)

                Button {
                    startProcessing()
                } label: {
                    Text("Listo").frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .disabled(processing)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar", systemImage: "xmark", role: .cancel) { dismiss() }
                        .disabled(processing)
                }
            }
        }
        .interactiveDismissDisabled(processing)
        .presentationDetents([.medium])
    }

    private var listeningState: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(.tint)
                .symbolEffect(.variableColor.iterative, isActive: !reduceMotion)

            TimelineView(.periodic(from: startDate, by: 1)) { context in
                Text(elapsedLabel(context.date.timeIntervalSince(startDate)))
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 6) {
                Text("Te escucho")
                    .font(.title2.weight(.semibold))
                Text(action == .stockClose ? "Di cuánto queda de cada insumo." : "Di qué compraste, cuánto y a qué precio.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func elapsedLabel(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(interval))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private func startProcessing() {
        processing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            dismiss()
            onFinish(action)
        }
    }
}
