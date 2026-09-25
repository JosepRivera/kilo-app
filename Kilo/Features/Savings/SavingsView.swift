import Charts
import SwiftUI

struct SavingsView: View {
    @Environment(KiloStore.self) private var store

    var body: some View {
        if store.isOwner {
            content
        } else {
            ContentUnavailableView(
                "Solo lo ve el dueño",
                systemImage: "lock.fill",
                description: Text("El ahorro y lo que se pierde en soles es información del dueño.")
            )
            .background(Color.kiloGround)
            .navigationTitle("Ahorro")
        }
    }

    @ViewBuilder private var content: some View {
        let model = SavingsModel(engine: store.engine, data: store.data)
        let thisMonth = model.months.last?.month

        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Este mes perdiste")
                        .foregroundStyle(.secondary)
                    Text(soles(model.current))
                        .font(.system(size: 48, weight: .bold))
                        .monospacedDigit()
                    if model.previous > 0 {
                        let diff = model.previous - model.current
                        Label(
                            diff >= 0 ? "\(soles(diff)) menos que el mes pasado" : "\(soles(-diff)) más que el mes pasado",
                            systemImage: diff >= 0 ? "arrow.down.right" : "arrow.up.right"
                        )
                        .font(.headline)
                        .foregroundStyle(diff >= 0 ? Color.kiloGood : Color.kiloAlert)
                    }
                    Label("Solo lo ve el dueño", systemImage: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)

                Chart(model.months, id: \.month) { item in
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

            if !model.topWasted.isEmpty {
                Section {
                    ForEach(model.topWasted, id: \.supply.id) { item in
                        HStack(spacing: 12) {
                            SupplyIcon(supply: item.supply)
                            Text(item.supply.name)
                            Spacer()
                            Text(soles(item.soles))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    InfoHeader(
                        title: "Lo que más se venció este mes",
                        info: "Es el costo de compra de lo que se venció, no la ganancia perdida."
                    )
                }
                .listRowBackground(Color.kiloModule)
            }
        }
        .listStyle(.insetGrouped)
        .kiloScreen()
        .navigationTitle("Ahorro")
    }
}
