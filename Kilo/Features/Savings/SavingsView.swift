import Charts
import SwiftUI

struct SavingsView: View {
    @Environment(KiloStore.self) private var store

    var body: some View {
        let engine = store.engine
        let byMonth = engine.monthlyWaste()
        let thisMonth = monthStart(engine.today)
        let months = (0..<4).reversed().map { back in
            let month = kiloCalendar.date(byAdding: .month, value: -back, to: thisMonth)!
            return (month: month, soles: byMonth[month] ?? 0)
        }
        let now = months.last!.soles
        let before = months[months.count - 2].soles
        let top = Dictionary(
            grouping: engine.waste().filter { monthStart($0.date) == thisMonth },
            by: \.supplyId
        )
        .map { (supply: store.data.supply($0.key), soles: $0.value.reduce(0) { $0 + $1.soles }) }
        .sorted { $0.soles > $1.soles }
        .prefix(5)

        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Este mes perdiste")
                        .foregroundStyle(.secondary)
                    Text(soles(now))
                        .font(.system(size: 48, weight: .bold))
                        .monospacedDigit()
                    if before > 0 {
                        let diff = before - now
                        Label(
                            diff >= 0 ? "\(soles(diff)) menos que el mes pasado" : "\(soles(-diff)) más que el mes pasado",
                            systemImage: diff >= 0 ? "arrow.down.right" : "arrow.up.right"
                        )
                        .font(.headline)
                        .foregroundStyle(diff >= 0 ? Color.kiloGood : Color.kiloAlert)
                    }
                }
                .padding(.vertical, 6)

                Chart(months, id: \.month) { item in
                    BarMark(
                        x: .value("Mes", item.month, unit: .month),
                        y: .value("Perdido", item.soles)
                    )
                    .foregroundStyle(item.month == thisMonth ? Color.accentColor : Color.accentColor.opacity(0.35))
                    .cornerRadius(4)
                    .annotation(position: .top) {
                        Text(soles(item.soles))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) {
                        AxisValueLabel(format: .dateTime.month(.abbreviated), centered: true)
                    }
                }
                .chartYAxis(.hidden)
                .frame(height: 160)
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.kiloModule)

            if !top.isEmpty {
                Section("Lo que más se venció este mes") {
                    ForEach(top, id: \.supply.id) { item in
                        HStack(spacing: 12) {
                            SupplyIcon(supply: item.supply)
                            Text(item.supply.name)
                            Spacer()
                            Text(soles(item.soles))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .listRowBackground(Color.kiloModule)
            }

            Section {
            } footer: {
                Label("Solo lo ve el dueño. Es el costo de compra de lo que se venció, no la ganancia.", systemImage: "lock.fill")
            }
        }
        .listStyle(.insetGrouped)
        .kiloScreen()
        .navigationTitle("Ahorro")
    }

    private func monthStart(_ date: Date) -> Date {
        kiloCalendar.date(from: kiloCalendar.dateComponents([.year, .month], from: date))!
    }
}
