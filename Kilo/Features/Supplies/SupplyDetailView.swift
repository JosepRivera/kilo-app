import Charts
import SwiftUI

struct SupplyDetailView: View {
    @Environment(KiloStore.self) private var store
    let supplyId: String

    var body: some View {
        let engine = store.engine
        let supply = store.data.supply(supplyId)
        let real = engine.realDays(supplyId)
        let week = (0..<7).map { offset in
            let date = addDays(engine.today, offset)
            return (label: offset == 0 ? "Hoy" : weekdayShort[weekday(of: date) - 1], amount: engine.forecast(supplyId, date))
        }
        let peaks = (0..<7).map { addDays(engine.today, $0) }
            .sorted { engine.forecast(supplyId, $0) > engine.forecast(supplyId, $1) }
            .prefix(2)
            .map { weekdayLong[weekday(of: $0) - 1] }
        let lots = engine.activeLots(supplyId).filter { !$0.lot.id.hasPrefix(openingLotPrefix) }

        List {
            Section {
                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Quedan")
                            .foregroundStyle(.secondary)
                        Text(withUnit(engine.currentStock(supplyId), supply.unit))
                            .font(.system(.largeTitle, weight: .bold))
                            .monospacedDigit()
                    }
                    Spacer()
                    SupplyIcon(supply: supply, size: 72)
                }
                .padding(.vertical, 6)

                if real < coldStartDays {
                    VStack(alignment: .leading, spacing: 8) {
                        ProgressView(value: Double(real), total: Double(coldStartDays))
                        Text("Kilo aún aprende · \(real) de \(coldStartDays) días")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .listRowBackground(Color.kiloModule)

            Section {
                Chart(week, id: \.label) { day in
                    BarMark(
                        x: .value("Día", day.label),
                        y: .value("Uso", day.amount)
                    )
                    .foregroundStyle(day.label == "Hoy" ? Color.accentColor : Color.accentColor.opacity(0.35))
                    .cornerRadius(4)
                }
                .chartYAxis(.hidden)
                .frame(height: 140)
                .padding(.vertical, 8)
                .accessibilityLabel("Uso esperado por día")

                Text("Se usa más el \(peaks.joined(separator: " y el ")).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Uso esperado esta semana")
            }
            .listRowBackground(Color.kiloModule)

            if !lots.isEmpty {
                Section("Lotes") {
                    ForEach(lots, id: \.lot.id) { state in
                        let days = daysBetween(engine.today, state.lot.expiresOn)
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Lote \(engine.lotLabel(state.lot))")
                                Text("\(money(state.lot.unitPrice)) por \(withUnit(1, supply.unit).dropFirst(2))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(withUnit(state.remaining, supply.unit))
                                    .monospacedDigit()
                                Text(expiryText(days))
                                    .font(.subheadline)
                                    .foregroundStyle(days <= 1 ? Color.kiloAlert : .secondary)
                            }
                        }
                    }
                }
                .listRowBackground(Color.kiloModule)
            }

            Section {
                LabeledContent("Registro", value: supply.critical ? "Diario" : "Semanal")
                LabeledContent("Unidad", value: supply.unit)
                ForEach(supply.phrases.sorted { $0.key < $1.key }, id: \.key) { phrase, amount in
                    LabeledContent("“\(phrase)”", value: withUnit(amount, supply.unit))
                }
            } header: {
                Text("Cómo se registra")
            }
            .listRowBackground(Color.kiloModule)
        }
        .listStyle(.insetGrouped)
        .kiloScreen()
        .navigationTitle(supply.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
