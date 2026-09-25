import Foundation

struct ExpiryGroup {
    let alerts: [ExpiryAlert]

    var supply: SupplyInfo { alerts[0].supply }
    var daysLeft: Int { alerts.map(\.daysLeft).min() ?? 0 }
    var remaining: Double { alerts.reduce(0) { $0 + $1.lot.remaining } }
}

struct PurchaseItem {
    let recommendation: Recommendation
    let bought: Bool
}

struct TodayModel {
    let due: [SupplyInfo]
    let toBuy: [PurchaseItem]
    let covered: [SupplyInfo]
    let alertGroups: [ExpiryGroup]
    let urgentAlert: ExpiryGroup?

    init(engine: Engine, data: KiloData, isBought: (String) -> Bool) {
        due = data.supplies.filter { engine.isDue($0.categoryId) }
        let recommendations = due.map { engine.recommend($0.id) }
        toBuy = recommendations
            .filter { $0.toBuy > 0 }
            .map { PurchaseItem(recommendation: $0, bought: isBought($0.supply.id)) }
        covered = recommendations.filter { $0.toBuy <= 0 }.map(\.supply)
        alertGroups = Dictionary(grouping: engine.expiryAlerts(), by: \.supply.id)
            .values
            .map { ExpiryGroup(alerts: $0) }
            .sorted { ($0.daysLeft, $0.supply.name) < ($1.daysLeft, $1.supply.name) }
        urgentAlert = alertGroups.first
    }
}
