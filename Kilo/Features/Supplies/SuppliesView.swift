import SwiftUI

struct SuppliesView: View {
    @Environment(KiloStore.self) private var store
    @State private var query = ""

    var body: some View {
        let engine = store.engine
        let alerts = engine.expiryAlerts()
        let matches = store.data.supplies.filter {
            query.isEmpty || $0.name.localizedStandardContains(query)
        }

        List {
            if query.isEmpty && !alerts.isEmpty {
                Section {
                    ForEach(alerts, id: \.lot.lot.id) { alert in
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

            ForEach(store.data.categories) { category in
                let supplies = matches.filter { $0.categoryId == category.id }
                if !supplies.isEmpty {
                    Section(category.name) {
                        ForEach(supplies) { supply in
                            NavigationLink(value: supply.id) {
                                SupplyRow(
                                    supply: supply,
                                    stock: engine.currentStock(supply.id),
                                    learning: engine.isLearning(supply.id),
                                    expiresIn: alerts.first { $0.supply.id == supply.id }?.daysLeft
                                )
                            }
                        }
                    }
                    .listRowBackground(Color.kiloModule)
                }
            }
        }
        .listStyle(.insetGrouped)
        .kiloScreen()
        .navigationTitle("Insumos")
        .searchable(text: $query, prompt: "Buscar insumo")
        .overlay {
            if matches.isEmpty {
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
