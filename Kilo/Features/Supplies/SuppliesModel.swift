import Foundation

struct SupplyRowInfo {
    let supply: SupplyInfo
    let stock: Double
    let learning: Bool
    let expiresIn: Int?
}

struct SuppliesSection {
    let category: CategoryInfo
    let supplies: [SupplyRowInfo]
}

struct SuppliesModel {
    let alerts: [ExpiryAlert]
    let sections: [SuppliesSection]
    let hasMatches: Bool

    init(engine: Engine, data: KiloData, query: String) {
        let currentAlerts = engine.expiryAlerts()
        let matches = data.supplies.filter { query.isEmpty || $0.name.localizedStandardContains(query) }
        alerts = currentAlerts
        hasMatches = !matches.isEmpty
        sections = data.categories.compactMap { category in
            let supplies = matches
                .filter { $0.categoryId == category.id }
                .map { supply in
                    SupplyRowInfo(
                        supply: supply,
                        stock: engine.currentStock(supply.id),
                        learning: engine.isLearning(supply.id),
                        expiresIn: currentAlerts.first { $0.supply.id == supply.id }?.daysLeft
                    )
                }
            return supplies.isEmpty ? nil : SuppliesSection(category: category, supplies: supplies)
        }
    }
}
