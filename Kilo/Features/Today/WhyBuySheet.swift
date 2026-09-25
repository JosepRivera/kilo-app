import SwiftUI

struct WhyBuySheet: View {
    @Environment(KiloStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let supplyId: String

    var body: some View {
        let engine = store.engine
        let rec = engine.recommend(supplyId)
        let supply = rec.supply
        let unit = supply.unit
        let days = (0..<rec.horizonDays).map { addDays(engine.today, $0) }
        let realDays = engine.realDays(supplyId)

        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        SupplyIcon(supply: supply, size: 48)
                        Text("Hasta tu próxima compra se usarán unos \(withUnit(rec.demand, unit)). Kilo suma un colchón por si acaso y resta lo que ya tienes.")
                            .font(.callout)
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.kiloModule)

                Section {
                    DisclosureGroup {
                        ForEach(days, id: \.self) { day in
                            let amount = engine.forecast(supplyId, day)
                            LabeledContent(
                                weekdayLong[weekday(of: day) - 1].capitalized,
                                value: amount > 0 ? withUnit(amount, unit) : "cerrado"
                            )
                            .monospacedDigit()
                        }
                    } label: {
                        Term(title: "Se usarán", detail: "Próximos \(rec.horizonDays) días", value: withUnit(rec.demand, unit))
                    }
                    Term(
                        title: "Colchón por si acaso",
                        detail: "Kilo suele fallar por unos \(withUnit(engine.errorEstimate(supplyId), unit)) al día",
                        value: "+ \(withUnit(rec.buffer, unit))"
                    )
                    Term(title: "Ya tienes", detail: nil, value: "− \(withUnit(rec.onHand, unit))")
                } footer: {
                    if realDays < coldStartDays {
                        Text("Kilo aún aprende: lleva \(realDays) de \(coldStartDays) días de datos reales de \(supply.name.lowercased()). Mientras tanto se apoya en tu gasto mensual declarado.")
                    }
                }
                .listRowBackground(Color.kiloModule)

                Section {
                    Term(title: "Comprar", detail: rec.toBuy > 0 ? "Redondeado para el mercado" : nil, value: rec.toBuy > 0 ? withUnit(rec.toBuy, unit) : "nada")
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.accentColor)
                }
                .listRowBackground(Color.kiloModule)
            }
            .listStyle(.insetGrouped)
            .kiloScreen()
            .navigationTitle("¿Por qué \(withUnit(rec.toBuy, unit))?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo", systemImage: "checkmark", role: .confirm) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

private struct Term: View {
    let title: String
    let detail: String?
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 12)
            Text(value)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}
