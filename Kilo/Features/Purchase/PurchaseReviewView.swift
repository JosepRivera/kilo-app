import SwiftUI

struct PurchaseReviewView: View {
    @Environment(KiloStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var lines: [PurchaseLineDraft] = []
    @State private var showDiscardConfirm = false
    @State private var creatingSupplyFor: String? = nil
    @FocusState private var focusedCostField: String?

    var body: some View {
        let engine = store.engine

        NavigationStack {
            List {
                Section("Escuché") {
                    Text("«Compré \(lines.map(\.heard).formatted(.list(type: .and).locale(Locale(identifier: "es_PE"))))».")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.kiloModule)

                ForEach(lines.indices, id: \.self) { index in
                    let lineId = lines[index].id
                    Section {
                        PurchaseLineRow(
                            line: $lines[index],
                            engine: engine,
                            focusedCostField: $focusedCostField,
                            creatingSupply: { creatingSupplyFor = lineId },
                            remove: { lines.removeAll { $0.id == lineId } }
                        )
                    }
                    .listRowBackground(Color.kiloModule)
                }

                Section {
                    LabeledContent("Total", value: money(lines.reduce(0) { $0 + $1.cost }))
                        .fontWeight(.semibold)
                }
                .listRowBackground(Color.kiloModule)
            }
            .listStyle(.insetGrouped)
            .kiloScreen()
            .navigationTitle("Compra")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar", systemImage: "xmark", role: .cancel) {
                        showDiscardConfirm = true
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirmar", systemImage: "checkmark", role: .confirm) {
                        save(engine)
                    }
                    .disabled(!allLinesValid(engine))
                }
            }
            .interactiveDismissDisabled()
            .confirmationDialog("Descartar compra", isPresented: $showDiscardConfirm) {
                Button("Descartar compra", role: .destructive) { dismiss() }
                Button("Seguir editando", role: .cancel) {}
            }
            .sheet(item: Binding(
                get: { creatingSupplyFor.map { IdentifiedString(value: $0) } },
                set: { creatingSupplyFor = $0?.value }
            )) { target in
                if let index = lines.firstIndex(where: { $0.id == target.value }),
                   case .unknown(let spoken) = lines[index].kind {
                    CreateSupplySheet(spokenName: spoken, categories: store.data.categories) { newSupply in
                        let unitPrice = lines[index].quantity > 0 ? lines[index].cost / lines[index].quantity : 0
                        let supply = SupplyInfo(
                            id: newSupply.id,
                            name: newSupply.name,
                            unit: newSupply.unit,
                            categoryId: newSupply.categoryId,
                            shelfLifeDays: newSupply.shelfLifeDays,
                            referencePrice: unitPrice > 0 ? unitPrice : newSupply.referencePrice,
                            icon: newSupply.icon,
                            critical: newSupply.critical,
                            phrases: newSupply.phrases
                        )
                        lines[index].kind = .resolved(supply, isNew: true)
                        lines[index].expiresOn = addDays(engine.today, supply.shelfLifeDays)
                        if lines[index].quantity == 0 { lines[index].quantity = 1 }
                        if lines[index].cost == 0 { lines[index].cost = lines[index].quantity * supply.referencePrice }
                    }
                }
            }
        }
        .onAppear {
            if lines.isEmpty {
                lines = PurchaseModel(engine: engine, data: store.data, isBought: store.isBought).lines
            }
        }
    }

    private func allLinesValid(_ engine: Engine) -> Bool {
        !lines.isEmpty && lines.allSatisfy { $0.isValid(engine) }
    }

    private func save(_ engine: Engine) {
        var purchaseLines: [PurchaseLine] = []
        for line in lines {
            guard let supply = line.supply else { continue }
            if case .resolved(_, let isNew) = line.kind, isNew {
                store.addSupply(supply)
            }
            if let phrase = line.quantityPhrase {
                store.setPhrase(phrase, amount: line.quantity, for: supply.id)
            }
            purchaseLines.append(PurchaseLine(
                supplyId: supply.id,
                quantity: line.quantity,
                cost: line.cost,
                expiresOn: line.expiresOn
            ))
        }
        store.savePurchase(purchaseLines)
        dismiss()
    }
}

private struct IdentifiedString: Identifiable {
    let value: String
    var id: String { value }
}
