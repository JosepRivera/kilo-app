import SwiftUI

struct PurchaseLineEditor: View {
    @Binding var line: PurchaseLineDraft
    let engine: Engine
    var focusPrice: Bool = false
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    private enum Field: Hashable { case quantity, price }

    var body: some View {
        NavigationStack {
            Form {
                if let supply = line.supply {
                    Section {
                        LabeledContent("Cantidad") {
                            HStack(spacing: 6) {
                                TextField("0", value: $line.quantity, format: .number)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .focused($focusedField, equals: .quantity)
                                    .onChange(of: line.quantity) { _, _ in line.priceConfirmed = false }
                                Text(supply.unit).foregroundStyle(.secondary)
                            }
                        }
                        LabeledContent("Precio total") {
                            HStack(spacing: 6) {
                                Text("S/").foregroundStyle(.secondary)
                                TextField("0", value: $line.cost, format: .number)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .fixedSize()
                                    .focused($focusedField, equals: .price)
                                    .onChange(of: line.cost) { _, _ in line.priceConfirmed = false }
                            }
                        }
                        DatePicker("Vence", selection: $line.expiresOn, in: engine.today..., displayedComponents: .date)
                    }
                }
            }
            .navigationTitle(line.supply?.name ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo", systemImage: "checkmark", role: .confirm) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            if focusPrice { focusedField = .price }
        }
    }
}
