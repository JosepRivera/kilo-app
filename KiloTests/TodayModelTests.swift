import Testing
@testable import Kilo

struct TodayModelTests {
    let data = demoData()
    var engine: Engine { Engine(data: data, today: demoDay) }

    @Test func expiryAlertsAreGroupedOnePerSupplyWithMostUrgentFirst() {
        let model = TodayModel(engine: engine, data: data, isBought: { _ in false })
        let supplyIds = model.alertGroups.map(\.supply.id)
        #expect(Set(supplyIds).count == supplyIds.count)
        let daysLeft = model.alertGroups.map(\.daysLeft)
        #expect(daysLeft == daysLeft.sorted())
        #expect(model.urgentAlert?.supply.id == model.alertGroups.first?.supply.id)
    }

    @Test func toBuyItemsReflectBoughtState() {
        let e = engine
        let due = data.supplies.filter { e.isDue($0.categoryId) }
        let expectedToBuy = due.map { e.recommend($0.id) }.filter { $0.toBuy > 0 }
        #expect(!expectedToBuy.isEmpty)

        let boughtId = expectedToBuy[0].supply.id
        let model = TodayModel(engine: e, data: data, isBought: { $0 == boughtId })

        #expect(model.toBuy.count == expectedToBuy.count)
        #expect(model.toBuy.allSatisfy { $0.recommendation.toBuy > 0 })
        #expect(model.toBuy.first { $0.recommendation.supply.id == boughtId }?.bought == true)
        #expect(model.toBuy.first { $0.recommendation.supply.id != boughtId }?.bought == false)
    }
}
