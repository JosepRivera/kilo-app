import SwiftUI

struct TodayView: View {
    @Environment(KiloStore.self) private var store

    var body: some View {
        let engine = store.engine
        let due = store.data.supplies.filter { engine.isDue($0.categoryId) }
        let recommendations = due.map { engine.recommend($0.id) }
        let toBuy = recommendations.filter { $0.toBuy > 0 }
        let covered = recommendations.filter { $0.toBuy <= 0 }
        let alerts = Dictionary(grouping: engine.expiryAlerts(), by: \.supply.id)
            .values
            .map { ExpiryGroup(alerts: $0) }
            .sorted { ($0.daysLeft, $0.supply.name) < ($1.daysLeft, $1.supply.name) }

        List {
            if let urgent = alerts.first {
                Section {
                    ExpiryAlertRow(group: urgent, label: engine.lotLabel(urgent.alerts[0].lot.lot))
                    if alerts.count > 1 {
                        NavigationLink {
                            ExpiringView(groups: alerts)
                        } label: {
                            Text("Ver todo lo que vence (\(alerts.count))")
                                .foregroundStyle(Color.kiloAlert)
                        }
                    }
                }
                .listRowBackground(Color.kiloAlertGround)
            }

            if toBuy.isEmpty {
                Section {
                    ContentUnavailableView(
                        due.isEmpty ? "Hoy no toca ir al mercado" : "Ya tienes todo lo de hoy",
                        systemImage: "checkmark.circle",
                        description: Text("Kilo te avisa cuando toque la próxima compra.")
                    )
                }
                .listRowBackground(Color.kiloModule)
            } else {
                Section {
                    ForEach(toBuy, id: \.supply.id) { rec in
                        PurchaseRow(
                            recommendation: rec,
                            learning: engine.isLearning(rec.supply.id),
                            bought: store.isBought(rec.supply.id)
                        ) {
                            store.toggleBought(rec.supply.id)
                        }
                    }
                } header: {
                    Text("Hasta tu próxima compra")
                } footer: {
                    Label("El punto es lo que tienes; lo azul, lo que falta.", systemImage: "circle.fill")
                        .labelStyle(LegendLabelStyle())
                }
                .listRowBackground(Color.kiloModule)
            }

            if !covered.isEmpty {
                Section("Ya alcanza") {
                    CoveredRow(supplies: covered.map(\.supply))
                }
                .listRowBackground(Color.kiloModule)
            }
        }
        .listStyle(.insetGrouped)
        .kiloScreen()
        .navigationTitle("Compra de hoy")
    }
}

struct ExpiryGroup {
    let alerts: [ExpiryAlert]

    var supply: SupplyInfo { alerts[0].supply }
    var daysLeft: Int { alerts.map(\.daysLeft).min() ?? 0 }
    var remaining: Double { alerts.reduce(0) { $0 + $1.lot.remaining } }
}

struct ExpiryAlertRow: View {
    let group: ExpiryGroup
    let label: String

    var body: some View {
        let title = group.alerts.count == 1
            ? "El lote \(label) \(expiryText(group.daysLeft))"
            : "\(group.alerts.count) lotes \(expiryText(group.daysLeft).replacingOccurrences(of: "vence", with: "vencen"))"
        HStack(spacing: 14) {
            SupplyIcon(supply: group.supply, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.kiloAlert)
                Text("\(group.supply.name) · quedan \(withUnit(group.remaining, group.supply.unit)) · úsalo primero")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.kiloAlert)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

private struct PurchaseRow: View {
    let recommendation: Recommendation
    let learning: Bool
    let bought: Bool
    let toggle: () -> Void

    var body: some View {
        let supply = recommendation.supply
        Button(action: toggle) {
            HStack(spacing: 14) {
                SupplyIcon(supply: supply, size: 36)
                    .opacity(bought ? 0.4 : 1)
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(supply.name)
                            .font(.body.weight(.medium))
                            .strikethrough(bought)
                        Spacer(minLength: 8)
                        Text(withUnit(recommendation.toBuy, supply.unit))
                            .font(.body.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(bought ? Color.secondary : Color.accentColor)
                    }
                    if bought {
                        Text("Comprado")
                            .font(.caption)
                            .foregroundStyle(Color.kiloGood)
                    } else {
                        RangeBar(fraction: recommendation.needed > 0 ? recommendation.onHand / recommendation.needed : 1)
                        if learning {
                            Text("Kilo aún aprende")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Image(systemName: bought ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(bought ? Color.kiloGood : Color.kiloTrack)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(supply.name), comprar \(withUnit(recommendation.toBuy, supply.unit)), tienes \(withUnit(recommendation.onHand, supply.unit))")
        .accessibilityValue(bought ? "Comprado" : "Pendiente")
        .accessibilityAddTraits(.isButton)
        .sensoryFeedback(.selection, trigger: bought)
    }
}

private struct CoveredRow: View {
    let supplies: [SupplyInfo]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 8)], spacing: 12) {
            ForEach(supplies) { supply in
                VStack(spacing: 4) {
                    SupplyIcon(supply: supply, size: 32)
                    Text(supply.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(.vertical, 6)
    }
}

private struct LegendLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.icon.font(.system(size: 6))
            configuration.title
        }
    }
}

struct ExpiringView: View {
    @Environment(KiloStore.self) private var store
    let groups: [ExpiryGroup]

    var body: some View {
        List {
            Section {
                ForEach(groups, id: \.supply.id) { group in
                    ExpiryAlertRow(group: group, label: store.engine.lotLabel(group.alerts[0].lot.lot))
                }
            } footer: {
                Text("Kilo asume que se usa primero lo más antiguo.")
            }
            .listRowBackground(Color.kiloModule)
        }
        .listStyle(.insetGrouped)
        .kiloScreen()
        .navigationTitle("Por vencer")
        .navigationBarTitleDisplayMode(.inline)
    }
}
