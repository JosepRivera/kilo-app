import SwiftUI

struct StockCloseReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(KiloStore.self) private var store

    @State private var values: [String: Double] = [:]
    @State private var confirmedFlags: Set<String> = []
    @State private var suggestionResolved = false
    @State private var resumedFromDraft = false
    @State private var showingNoConsumptionAlert = false
    @State private var showingDiscardDialog = false
    @FocusState private var focusedField: String?

    private var supplies: [SupplyInfo] { store.closeSupplies() }
    private var scenario: HeardScenario { HeardScenario.build(engine: store.engine, supplies: supplies) }
    private var model: StockCloseModel {
        StockCloseModel(engine: store.engine, supplies: supplies, scenario: scenario, values: values)
    }

    private var hasUnsavedEdits: Bool { resumedFromDraft || values != scenario.heard }

    private var canConfirm: Bool {
        guard !model.rows.isEmpty else { return false }
        let flagsResolved = model.rows.allSatisfy { row in
            row.flag == nil || confirmedFlags.contains(row.id)
        }
        let suggestionOK = scenario.mistranscription == nil || suggestionResolved
        let valuesValid = model.rows.allSatisfy { (values[$0.id] ?? -1) >= 0 }
        return flagsResolved && suggestionOK && valuesValid
    }

    var body: some View {
        NavigationStack {
            Group {
                if supplies.isEmpty {
                    ContentUnavailableView(
                        "No hay insumos por cerrar",
                        systemImage: "checkmark.circle",
                        description: Text("Todavía no tienes insumos que registrar hoy.")
                    )
                    .kiloScreen()
                } else {
                    let currentModel = model
                    let currentScenario = scenario
                    List {
                        if resumedFromDraft {
                            Section {
                                HStack {
                                    Text("Retomaste tu cierre sin terminar")
                                        .font(.subheadline)
                                    Spacer()
                                    Button("Empezar de nuevo") { restart() }
                                        .buttonStyle(.borderless)
                                }
                            }
                            .listRowBackground(Color.kiloModule)
                        }

                        Section {
                            Text(currentModel.transcript)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        } header: {
                            Text("Escuché")
                        }
                        .listRowBackground(Color.kiloModule)

                        let flaggedRows = currentModel.rows.filter { $0.flag != nil && !confirmedFlags.contains($0.id) }
                        if !flaggedRows.isEmpty {
                            Section {
                                ForEach(flaggedRows) { row in
                                    FlagRow(
                                        supply: row.supply,
                                        flag: row.flag!,
                                        onConfirm: { confirmedFlags.insert(row.id) },
                                        onCorrect: { focusedField = row.id }
                                    )
                                }
                            } header: {
                                Text("Revisar")
                            }
                            .listRowBackground(Color.kiloAlertGround)
                        }

                        if let suggestion = currentScenario.mistranscription, !suggestionResolved {
                            Section {
                                SuggestionRow(
                                    suggestion: suggestion,
                                    onAcceptSuggested: {
                                        values[suggestion.supplyId] = suggestion.suggestedValue
                                        confirmedFlags.remove(suggestion.supplyId)
                                        suggestionResolved = true
                                    },
                                    onKeepHeard: { suggestionResolved = true }
                                )
                            }
                            .listRowBackground(Color.kiloModule)
                        }

                        Section {
                            ForEach(currentModel.rows) { row in
                                SupplyValueRow(
                                    row: row,
                                    flagged: row.flag != nil && !confirmedFlags.contains(row.id),
                                    value: binding(for: row.id),
                                    focus: $focusedField
                                )
                            }
                        } header: {
                            Text("Lo que queda")
                        }
                        .listRowBackground(Color.kiloModule)

                        Section {
                            Button("Hoy no hubo consumo") { showingNoConsumptionAlert = true }
                        }
                        .listRowBackground(Color.kiloModule)
                    }
                    .listStyle(.insetGrouped)
                    .kiloScreen()
                }
            }
            .navigationTitle("Cierre de hoy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar", systemImage: "xmark", role: .cancel) {
                        if hasUnsavedEdits {
                            showingDiscardDialog = true
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar", systemImage: "checkmark", role: .confirm) {
                        store.saveClose(values)
                        dismiss()
                    }
                    .disabled(!canConfirm)
                }
            }
        }
        .interactiveDismissDisabled(hasUnsavedEdits)
        .confirmationDialog("¿Qué quieres hacer con tu cierre?", isPresented: $showingDiscardDialog, titleVisibility: .visible) {
            Button("Guardar borrador") {
                store.closeDraft = values
                dismiss()
            }
            Button("Descartar cierre", role: .destructive) {
                store.closeDraft = nil
                dismiss()
            }
            Button("Cancelar", role: .cancel) {}
        }
        .alert("¿Hoy no hubo consumo?", isPresented: $showingNoConsumptionAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Marcar sin consumo") {
                store.markNoConsumption()
                dismiss()
            }
        } message: {
            Text("El día queda en cero y cuenta como dato real, no como olvido.")
        }
        .onAppear(perform: setup)
    }

    private func setup() {
        guard values.isEmpty else { return }
        if let draft = store.closeDraft {
            values = draft
            resumedFromDraft = true
        } else {
            values = scenario.heard
        }
    }

    private func restart() {
        values = scenario.heard
        confirmedFlags = []
        suggestionResolved = false
        resumedFromDraft = false
    }

    private func binding(for id: String) -> Binding<Double> {
        Binding(
            get: { values[id] ?? scenario.heard[id] ?? 0 },
            set: { newValue in
                values[id] = newValue
                confirmedFlags.remove(id)
            }
        )
    }
}

private struct SupplyValueRow: View {
    let row: StockCloseModel.Row
    let flagged: Bool
    @Binding var value: Double
    var focus: FocusState<String?>.Binding

    var body: some View {
        HStack(spacing: 12) {
            SupplyIcon(supply: row.supply, size: 32)
            Text(row.supply.name)
                .foregroundStyle(flagged ? Color.kiloAlert : .primary)
            Spacer()
            TextField("Cantidad", value: $value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .focused(focus, equals: row.id)
                .frame(width: 64)
            Text(row.supply.unit)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

private struct FlagRow: View {
    let supply: SupplyInfo
    let flag: AnomalyFlag
    let onConfirm: () -> Void
    let onCorrect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                SupplyIcon(supply: supply, size: 28)
                Text(message)
                    .font(.subheadline)
            }
            HStack(spacing: 10) {
                Button("Sí, es correcto", action: onConfirm)
                    .buttonStyle(.bordered)
                Button("Corregir", action: onCorrect)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(.vertical, 4)
    }

    private var message: String {
        "Según lo que dictaste, hoy se usaron \(withUnit(flag.consumed, supply.unit)) de \(supply.name.lowercased()); normalmente son unos \(withUnit(flag.usual, supply.unit)). ¿Es correcto?"
    }
}

private struct SuggestionRow: View {
    let suggestion: HeardScenario.Mistranscription
    let onAcceptSuggested: () -> Void
    let onKeepHeard: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Escuché «\(suggestion.heardWord)», pero según tu historial quedarían unos \(suggestion.suggestedWord). ¿Quisiste decir \(suggestion.suggestedWord)?")
                .font(.subheadline)
            HStack(spacing: 10) {
                Button("Sí, \(suggestion.suggestedWord)", action: onAcceptSuggested)
                    .buttonStyle(.borderedProminent)
                Button("No, \(suggestion.heardWord)", action: onKeepHeard)
                    .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 4)
    }
}
