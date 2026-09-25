import SwiftUI

struct SuppliesView: View {
    @Environment(KiloStore.self) private var store
    @State private var query = ""

    var body: some View {
        let engine = store.engine
        let model = SuppliesModel(engine: engine, data: store.data, query: query)

        List {
            if query.isEmpty && !model.alerts.isEmpty {
                Section {
                    ForEach(model.alerts, id: \.lot.lot.id) { alert in
                        NavigationLink(value: alert.supply.id) {
                            HStack(spacing: 12) {
                                SupplyIcon(supply: alert.supply)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(alert.supply.name), lote \(engine.lotLabel(alert.lot.lot))")
                                    Text("\(withUnit(alert.lot.remaining, alert.supply.unit)) · \(expiryText(alert.daysLeft))")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.kiloAlert)
                                }
                            }
                        }
                    }
                } header: {
                    Label("Por vencer", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.kiloAlert)
                }
                .listRowBackground(Color.kiloModule)
            }

            ForEach(model.sections, id: \.category.id) { section in
                Section(section.category.name) {
                    ForEach(section.supplies, id: \.supply.id) { item in
                        NavigationLink(value: item.supply.id) {
                            SupplyRow(supply: item.supply, stock: item.stock, learning: item.learning, expiresIn: item.expiresIn)
                        }
                    }
                }
                .listRowBackground(Color.kiloModule)
            }
        }
        .listStyle(.insetGrouped)
        .kiloScreen()
        .navigationTitle("Insumos")
        .searchable(text: $query, prompt: "Buscar insumo")
        .overlay {
            if !model.hasMatches {
                ContentUnavailableView.search(text: query)
            }
        }
        .navigationDestination(for: String.self) { SupplyDetailView(supplyId: $0) }
    }
}

private struct SupplyRow: View {
    let supply: SupplyInfo
    let stock: Double
    let learning: Bool
    let expiresIn: Int?

    var body: some View {
        HStack(spacing: 12) {
            SupplyIcon(supply: supply)
            VStack(alignment: .leading, spacing: 2) {
                Text(supply.name)
                Group {
                    let cadence = supply.critical ? "Diario" : "Semanal"
                    if let expiresIn {
                        let expiry = Text(expiryText(expiresIn).prefix(1).uppercased() + expiryText(expiresIn).dropFirst())
                            .foregroundStyle(Color.kiloAlert)
                        Text("\(expiry) · \(cadence)")
                    } else {
                        Text(learning ? "\(cadence) · Kilo aún aprende" : cadence)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Text(withUnit(stock, supply.unit))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }
}
