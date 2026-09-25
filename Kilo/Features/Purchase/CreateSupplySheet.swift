import SwiftUI

private let creatableUnits = ["kg", "litros", "unidades", "atados", "docenas"]

struct CreateSupplySheet: View {
    @Environment(\.dismiss) private var dismiss
    let spokenName: String
    let categories: [CategoryInfo]
    let onCreate: (SupplyInfo) -> Void

    @State private var name: String
    @State private var categoryId: String
    @State private var unit = "kg"
    @State private var shelfLifeDays = 5

    init(spokenName: String, categories: [CategoryInfo], onCreate: @escaping (SupplyInfo) -> Void) {
        self.spokenName = spokenName
        self.categories = categories
        self.onCreate = onCreate
        _name = State(initialValue: spokenName.prefix(1).uppercased() + spokenName.dropFirst())
        _categoryId = State(initialValue: categories.first?.id ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nombre", text: $name)
                    Picker("Categoría", selection: $categoryId) {
                        ForEach(categories) { category in
                            Text(category.name).tag(category.id)
                        }
                    }
                }

                Section {
                    Picker("Unidad", selection: $unit) {
                        ForEach(creatableUnits, id: \.self) { Text($0.capitalized).tag($0) }
                    }
                } footer: {
                    Text("La unidad no se puede cambiar después.")
                }

                Section {
                    Stepper("Vence en \(shelfLifeDays) días", value: $shelfLifeDays, in: 1...60)
                }
            }
            .navigationTitle("Nuevo insumo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar", systemImage: "xmark", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Crear", role: .confirm) {
                        onCreate(SupplyInfo(
                            id: catalogSupplyId(name),
                            name: name,
                            unit: unit,
                            categoryId: categoryId,
                            shelfLifeDays: shelfLifeDays,
                            referencePrice: 0,
                            icon: nil,
                            critical: true,
                            phrases: [:]
                        ))
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || categoryId.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
