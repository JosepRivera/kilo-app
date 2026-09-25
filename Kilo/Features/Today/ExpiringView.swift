import SwiftUI

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
