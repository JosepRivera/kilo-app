import Charts
import SwiftUI

struct SupplyDetailView: View {
    @Environment(KiloStore.self) private var store
    let supplyId: String

    var body: some View {
        let model = SupplyDetailModel(engine: store.engine, data: store.data, supplyId: supplyId)

        List {
            Section {
                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Quedan")
                            .foregroundStyle(.secondary)
                        Text(withUnit(model.stock, model.supply.unit))
                            .font(.system(.largeTitle, weight: .bold))
                            .monospacedDigit()
                    }
                    Spacer()
                    SupplyIcon(supply: model.supply, size: 72)
                }
                .padding(.vertical, 6)

                if model.realDays < coldStartDays {
                    VStack(alignment: .leading, spacing: 8) {
                        ProgressView(value: Double(model.realDays), total: Double(coldStartDays))
                        Text("Kilo aún aprende · \(model.realDays) de \(coldStartDays) días")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .listRowBackground(Color.kiloModule)

            Section {
                Chart(model.week, id: \.label) { day in
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

                Text("Se usa más el \(model.peaks.joined(separator: " y el ")).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Uso esperado esta semana")
            }
            .listRowBackground(Color.kiloModule)

            if !model.lots.isEmpty {
                Section("Lotes") {
                    ForEach(model.lots, id: \.state.lot.id) { display in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Lote \(store.engine.lotLabel(display.state.lot))")
                                Text("\(money(display.state.lot.unitPrice)) por \(withUnit(1, model.supply.unit).dropFirst(2))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(withUnit(display.state.remaining, model.supply.unit))
                                    .monospacedDigit()
                                Text(expiryText(display.daysLeft))
                                    .font(.subheadline)
                                    .foregroundStyle(display.daysLeft <= 1 ? Color.kiloAlert : .secondary)
                            }
                        }
                    }
                }
                .listRowBackground(Color.kiloModule)
            }

            Section {
                ForEach(model.recent, id: \.date) { day in
                    HStack {
                        Text(day.date.formatted(.dateTime.weekday(.wide).day().locale(Locale(identifier: "es_PE"))).capitalized)
                        Spacer()
                        switch day.kind {
                        case .real:
                            Text(withUnit(day.amount, model.supply.unit)).monospacedDigit()
                        case .estimated:
                            Text("~\(withUnit(day.amount, model.supply.unit)) · estimado")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        case .closed:
                            Text("cerrado").foregroundStyle(.secondary)
                        case .missing:
                            Text("sin dato").foregroundStyle(.tertiary)
                        }
                    }
                }
            } header: {
                InfoHeader(
                    title: "Últimos días",
                    info: "«Estimado» es un día sin cierre: Kilo repartió la diferencia y lo cuenta a medias mientras aprende."
                )
            }
            .listRowBackground(Color.kiloModule)

            Section {
                LabeledContent("Registro", value: model.supply.critical ? "Diario" : "Semanal")
                LabeledContent("Unidad", value: model.supply.unit)
                ForEach(model.supply.phrases.sorted { $0.key < $1.key }, id: \.key) { phrase, amount in
                    LabeledContent("“\(phrase)”", value: withUnit(amount, model.supply.unit))
                }
            } header: {
                Text("Cómo se registra")
            }
            .listRowBackground(Color.kiloModule)
        }
        .listStyle(.insetGrouped)
        .kiloScreen()
        .navigationTitle(model.supply.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
