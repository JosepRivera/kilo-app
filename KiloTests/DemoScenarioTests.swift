import Foundation
import Testing
@testable import Kilo

struct DemoScenarioTests {
    let data = demoData()
    var engine: Engine { Engine(data: data, today: demoDay) }

    @Test func morningPurchaseListShowsTheDemoCases() {
        let e = engine

        #expect(e.realDays("chicken") >= coldStartDays)
        #expect(e.isLearning("chicken") == false)
        #expect(e.isDue("protein") == true)

        let demand = (0..<3).reduce(0.0) { $0 + e.forecast("chicken", addDays(demoDay, $1)) }
        #expect((28...32).contains(demand))
        #expect((3.0...5.0).contains(e.errorEstimate("chicken")))
        #expect((10.0...14.0).contains(e.currentStock("chicken")))

        let recommendation = e.recommend("chicken")
        #expect((24.0...30.0).contains(recommendation.toBuy))

        #expect(e.realDays("fish") == 12)
        #expect(e.isLearning("fish") == true)

        #expect(e.isDue("produce") == true)
        #expect(e.recommend("potato").toBuy == 0)

        #expect(e.isDue("grocery") == false)
        #expect(e.isDue("seasoning") == false)

        #expect(e.isDue("dairy") == true)

        let alerts = e.expiryAlerts()
        let chickenToday = alerts.filter { $0.supply.id == "chicken" && $0.daysLeft == 0 }
        #expect(chickenToday.count == 2)
        let uniquePrices = Set(chickenToday.map { $0.lot.lot.unitPrice })
        #expect(uniquePrices.count == 2)
        #expect(alerts.contains { $0.supply.id != "chicken" && $0.daysLeft == 1 })
    }

    @Test func reviewFlagsFollowTheRules() {
        let e = engine

        var freshData = data
        for s in data.supplies where e.isDue(s.categoryId) {
            let recommendation = e.recommend(s.id)
            guard recommendation.toBuy > 0 else { continue }
            freshData.lots.append(
                Lot(
                    id: "test-\(s.id)",
                    supplyId: s.id,
                    purchasedOn: demoDay,
                    quantity: recommendation.toBuy,
                    cost: recommendation.toBuy * s.referencePrice,
                    expiresOn: addDays(demoDay, s.shelfLifeDays)
                )
            )
        }
        let freshEngine = Engine(data: freshData, today: demoDay)
        let stockAfterPurchase = freshEngine.currentStock("beef")
        let flag = freshEngine.checkClose("beef", remaining: stockAfterPurchase - 13)
        #expect(flag != nil)
        #expect(flag?.consumed == 13)
        #expect((3.0...5.0).contains(flag?.usual ?? 0))

        #expect(e.checkClose("cilantro", remaining: e.currentStock("cilantro") - 3.4) == nil)

        let usual = median(data.lots.filter { $0.supplyId == "onion" }.map { $0.unitPrice })
        #expect(e.checkPrice("onion", unitPrice: usual * 1.6) != nil)
        #expect(e.checkPrice("onion", unitPrice: usual) == nil)
    }

    @Test func historyHasGapsClosedDaysAndPerishableWaste() {
        let e = engine

        let tue = dateFor(year: 2026, month: 10, day: 27)
        let wed = dateFor(year: 2026, month: 10, day: 28)
        #expect(e.consumption("tomato")[tue]?.estimated == true)
        #expect(e.consumption("tomato")[wed]?.estimated == true)

        let windowStart = addDays(demoDay, -28)
        for supply in data.supplies where supply.critical && supply.id != "tomato" {
            let hasEstimated = e.consumption(supply.id)
                .filter { $0.key >= windowStart && $0.key < demoDay }
                .contains { $0.value.estimated }
            #expect(hasEstimated == false)
        }

        #expect(daysBetween(exceptionalSunday, demoDay) > 28)
        let regularSundays = [
            dateFor(year: 2026, month: 8, day: 9),
            dateFor(year: 2026, month: 9, day: 6),
            dateFor(year: 2026, month: 10, day: 25),
        ]
        for supply in data.supplies where supply.critical && supply.id != "fish" {
            for sunday in regularSundays {
                #expect(e.consumption(supply.id)[sunday]?.closed == true)
            }
            #expect(e.consumption(supply.id)[exceptionalSunday]?.closed == false)
        }

        let waste = e.monthlyWaste()
        let july = waste[dateFor(year: 2026, month: 7, day: 1)] ?? 0
        let august = waste[dateFor(year: 2026, month: 8, day: 1)] ?? 0
        let september = waste[dateFor(year: 2026, month: 9, day: 1)] ?? 0
        let october = waste[dateFor(year: 2026, month: 10, day: 1)] ?? 0

        #expect((342.0...418.0).contains(july))
        #expect((225.0...275.0).contains(september))
        #expect((180.0...220.0).contains(october))
        #expect(july > august)
        #expect(august > september)
        #expect(september > october)

        let longLife: Set<String> = ["rice", "oil", "legumes", "salt", "garlic"]
        var wasteBySupply: [String: Double] = [:]
        var octoberWasteBySupply: [String: Double] = [:]
        for w in e.waste() {
            wasteBySupply[w.supplyId, default: 0] += w.soles
            if kiloCalendar.isDate(w.date, equalTo: dateFor(year: 2026, month: 10, day: 1), toGranularity: .month) {
                octoberWasteBySupply[w.supplyId, default: 0] += w.soles
            }
        }
        for id in longLife {
            #expect((wasteBySupply[id] ?? 0) < 1.0)
        }

        let octoberTopThree = octoberWasteBySupply.sorted { $0.value > $1.value }.prefix(3).map { $0.key }
        #expect(octoberTopThree.allSatisfy { !longLife.contains($0) })
        #expect(!data.lots.contains { $0.purchasedOn == demoDay })

        for supply in data.supplies {
            let lotsTotal = e.activeLots(supply.id).reduce(0.0) { $0 + $1.remaining }
            let current = e.currentStock(supply.id)
            #expect(abs(lotsTotal - current) < 0.05)
        }
    }
}
