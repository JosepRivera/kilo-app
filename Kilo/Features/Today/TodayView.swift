import SwiftUI

struct TodayView: View {
    @Environment(KiloStore.self) private var store
    @State private var explained: ExplainedSupply?
    @State private var showingSettings = false

    var body: some View {
        let engine = store.engine
        let model = TodayModel(engine: engine, data: store.data, isBought: store.isBought)

        List {
            if let urgent = model.urgentAlert {
                Section {
                    ExpiryAlertRow(group: urgent, label: engine.lotLabel(urgent.alerts[0].lot.lot))
                    if model.alertGroups.count > 1 {
                        NavigationLink {
                            ExpiringView(groups: model.alertGroups)
                        } label: {
                            Text("Ver todo lo que vence (\(model.alertGroups.count))")
                                .foregroundStyle(Color.kiloAlert)
                        }
                    }
                }
                .listRowBackground(Color.kiloAlertGround)
            }

            if model.toBuy.isEmpty {
                Section {
                    ContentUnavailableView(
                        model.due.isEmpty ? "Hoy no toca ir al mercado" : "Ya tienes todo lo de hoy",
                        systemImage: "checkmark.circle",
                        description: Text("Kilo te avisa cuando toque la próxima compra.")
                    )
                }
                .listRowBackground(Color.kiloModule)
            } else {
                Section {
                    ForEach(model.toBuy, id: \.recommendation.supply.id) { item in
                        PurchaseRow(
                            recommendation: item.recommendation,
                            learning: engine.isLearning(item.recommendation.supply.id),
                            bought: item.bought
                        ) {
                            store.toggleBought(item.recommendation.supply.id)
                        } explain: {
                            explained = ExplainedSupply(id: item.recommendation.supply.id)
                        }
                    }
                } header: {
                    InfoHeader(
                        title: "Hasta tu próxima compra",
                        info: "El punto es lo que tienes; lo azul, lo que falta. Toca una fila para ver cómo se calculó."
                    )
                }
                .listRowBackground(Color.kiloModule)
            }

            if !model.covered.isEmpty {
                Section("Ya alcanza") {
                    CoveredRow(supplies: model.covered)
                }
                .listRowBackground(Color.kiloModule)
            }
        }
        .listStyle(.insetGrouped)
        .kiloScreen()
        .navigationTitle("Compra de hoy")
        .navigationSubtitle(store.today.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "es_PE"))))
        .sheet(item: $explained) { WhyBuySheet(supplyId: $0.id) }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Ajustes", systemImage: "gearshape") { showingSettings = true }
            }
        }
        .sheet(isPresented: $showingSettings) { SettingsView() }
    }
}

private struct ExplainedSupply: Identifiable {
    let id: String
}
