import SwiftUI

struct SettingsView: View {
    @Environment(KiloStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var confirmingNextDay = false

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            List {
                Section {
                    NavigationLink("Compras y gasto por categoría") { RestaurantView() }
                    NavigationLink("Cómo se registra cada insumo") { RecordingModeView() }
                    LabeledContent("Días que no abres", value: "Domingo")
                } header: {
                    Text("Tu restaurante")
                }
                .listRowBackground(Color.kiloModule)

                Section {
                    Picker("Ver como", selection: $store.isOwner) {
                        Text("Dueño").tag(true)
                        Text("Encargado").tag(false)
                    }
                    Button("Pasar al día siguiente", systemImage: "moon.stars") {
                        confirmingNextDay = true
                    }
                    LabeledContent("Hoy es", value: store.today.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "es_PE"))))
                } header: {
                    Text("Demostración")
                } footer: {
                    Text("Los datos de Doña Rosa son de ejemplo y vuelven a empezar cada vez que abres la app.")
                }
                .listRowBackground(Color.kiloModule)
            }
            .listStyle(.insetGrouped)
            .kiloScreen()
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo", systemImage: "checkmark", role: .confirm) { dismiss() }
                }
            }
            .alert("¿Pasar al día siguiente?", isPresented: $confirmingNextDay) {
                Button("Cancelar", role: .cancel) {}
                Button("Pasar de día") {
                    store.advanceDay()
                    dismiss()
                }
            } message: {
                Text("Kilo procesa la noche: recalcula lo que se usará y qué comprar con lo que registraste hoy.")
            }
        }
    }
}

private struct RestaurantView: View {
    @Environment(KiloStore.self) private var store

    var body: some View {
        List {
            ForEach(store.data.categories) { category in
                Section(category.name) {
                    Stepper(value: binding(category, \.purchaseIntervalDays), in: 1...30) {
                        LabeledContent("Compras cada", value: category.purchaseIntervalDays == 1 ? "1 día" : "\(category.purchaseIntervalDays) días")
                    }
                    LabeledContent("Gasto al mes", value: soles(category.monthlySpend))
                }
                .listRowBackground(Color.kiloModule)
            }
        }
        .listStyle(.insetGrouped)
        .kiloScreen()
        .navigationTitle("Tu restaurante")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func binding(_ category: CategoryInfo, _ keyPath: WritableKeyPath<CategoryInfo, Int>) -> Binding<Int> {
        Binding(
            get: { category[keyPath: keyPath] },
            set: { value in
                var updated = category
                updated[keyPath: keyPath] = value
                store.updateCategory(updated)
            }
        )
    }
}

private struct RecordingModeView: View {
    @Environment(KiloStore.self) private var store

    var body: some View {
        List {
            Section {
            } footer: {
                Text("Activa los insumos caros o que se malogran rápido. Los demás se cuentan una vez por semana.")
            }
            ForEach(store.data.categories) { category in
                let supplies = store.data.supplies.filter { $0.categoryId == category.id }
                if !supplies.isEmpty {
                    Section(category.name) {
                        ForEach(supplies) { supply in
                            Toggle(isOn: Binding(
                                get: { supply.critical },
                                set: { store.setCritical(supply.id, critical: $0) }
                            )) {
                                HStack(spacing: 12) {
                                    SupplyIcon(supply: supply, size: 28)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(supply.name)
                                        Text(supply.critical ? "Se cuenta cada noche" : "Se cuenta los lunes")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .listRowBackground(Color.kiloModule)
                }
            }
        }
        .listStyle(.insetGrouped)
        .kiloScreen()
        .navigationTitle("Registro diario")
        .navigationBarTitleDisplayMode(.inline)
    }
}
