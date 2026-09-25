import Testing
@testable import Kilo

private func testSupply(
    _ id: String,
    unit: String = "kg",
    categoryId: String = "c",
    shelfLifeDays: Int = 10,
    referencePrice: Double = 1
) -> SupplyInfo {
    SupplyInfo(
        id: id,
        name: id,
        unit: unit,
        categoryId: categoryId,
        shelfLifeDays: shelfLifeDays,
        referencePrice: referencePrice,
        icon: nil,
        critical: true,
        phrases: [:]
    )
}

private let testCategory = CategoryInfo(id: "c", name: "Cat", purchaseIntervalDays: 3, monthlySpend: 300)

struct EngineTests {
    @Test func consumptionAccountsForPurchaseInWindow() {
        let d0 = dateFor(year: 2026, month: 1, day: 1)
        let d1 = addDays(d0, 1)
        let supply = testSupply("x")
        let lot = Lot(id: "l1", supplyId: "x", purchasedOn: d1, quantity: 5, cost: 5, expiresOn: addDays(d1, 10))
        let data = KiloData(
            categories: [testCategory],
            supplies: [supply],
            stock: [
                StockRecord(supplyId: "x", date: d0, remaining: 10),
                StockRecord(supplyId: "x", date: d1, remaining: 6),
            ],
            lots: [lot]
        )
        let engine = Engine(data: data, today: addDays(d1, 1))
        let entry = engine.consumption("x")[d1]
        #expect(entry?.amount == 9)
        #expect(entry?.estimated == false)
    }

    @Test func missingCloseSpreadsConsumptionAsEstimated() {
        let d0 = dateFor(year: 2026, month: 1, day: 1)
        let d1 = addDays(d0, 1)
        let d2 = addDays(d0, 2)
        let supply = testSupply("x")
        let data = KiloData(
            categories: [testCategory],
            supplies: [supply],
            stock: [
                StockRecord(supplyId: "x", date: d0, remaining: 10),
                StockRecord(supplyId: "x", date: d2, remaining: 4),
            ],
            lots: []
        )
        let engine = Engine(data: data, today: addDays(d2, 1))
        let consumption = engine.consumption("x")
        #expect(consumption[d1]?.amount == 3)
        #expect(consumption[d1]?.estimated == true)
        #expect(consumption[d2]?.amount == 3)
        #expect(consumption[d2]?.estimated == true)
    }

    @Test func closedDayRecordsZeroRealConsumption() {
        let d0 = dateFor(year: 2026, month: 1, day: 1)
        let d1 = addDays(d0, 1)
        let d2 = addDays(d0, 2)
        let supply = testSupply("x")
        let data = KiloData(
            categories: [testCategory],
            supplies: [supply],
            stock: [
                StockRecord(supplyId: "x", date: d0, remaining: 10),
                StockRecord.closed("x", d1),
                StockRecord(supplyId: "x", date: d2, remaining: 6),
            ],
            lots: []
        )
        let engine = Engine(data: data, today: addDays(d2, 1))
        let consumption = engine.consumption("x")
        #expect(consumption[d1]?.amount == 0)
        #expect(consumption[d1]?.closed == true)
        #expect(consumption[d2]?.amount == 4)
        #expect(consumption[d2]?.estimated == false)
        #expect(consumption[d2]?.closed == false)
    }

    @Test func recommendClampsBufferToFloor() {
        let category = CategoryInfo(id: "bf", name: "BF", purchaseIntervalDays: 4, monthlySpend: 400)
        let supply = testSupply("y", categoryId: "bf")
        let start = dateFor(year: 2026, month: 1, day: 1)
        var stock: [StockRecord] = []
        var level = 1000.0
        for i in 0...40 {
            stock.append(StockRecord(supplyId: "y", date: addDays(start, i), remaining: level))
            level -= 5
        }
        let today = addDays(start, 40)
        let data = KiloData(categories: [category], supplies: [supply], stock: stock, lots: [])
        let engine = Engine(data: data, today: today)
        let demand = (0..<4).reduce(0.0) { $0 + engine.forecast("y", addDays(today, $1)) }
        let recommendation = engine.recommend("y")
        #expect(engine.errorEstimate("y") == 0)
        #expect(abs((recommendation.needed - demand) - bufferFloor * demand) < 0.001)
    }

    @Test func recommendClampsBufferToCeiling() {
        let category = CategoryInfo(id: "bc", name: "BC", purchaseIntervalDays: 4, monthlySpend: 400)
        let supply = testSupply("z", categoryId: "bc")
        let start = dateFor(year: 2026, month: 1, day: 1)
        var stock: [StockRecord] = []
        var level = 1000.0
        for i in 0...40 {
            let use = i % 2 == 0 ? 50.0 : 0.0
            stock.append(StockRecord(supplyId: "z", date: addDays(start, i), remaining: level))
            level -= use
        }
        let today = addDays(start, 40)
        let data = KiloData(categories: [category], supplies: [supply], stock: stock, lots: [])
        let engine = Engine(data: data, today: today)
        let demand = (0..<4).reduce(0.0) { $0 + engine.forecast("z", addDays(today, $1)) }
        let recommendation = engine.recommend("z")
        #expect(abs((recommendation.needed - demand) - bufferCeiling * demand) < 0.001)
    }

    @Test func expiredLotBecomesWasteAndLeavesQueueEmpty() {
        let category = CategoryInfo(id: "wc", name: "WC", purchaseIntervalDays: 3, monthlySpend: 300)
        let supply = testSupply("w", categoryId: "wc", shelfLifeDays: 2, referencePrice: 4)
        let d0 = dateFor(year: 2026, month: 1, day: 1)
        let d3 = addDays(d0, 3)
        let lot = Lot(id: "l1", supplyId: "w", purchasedOn: d0, quantity: 10, cost: 40, expiresOn: addDays(d0, 2))
        let data = KiloData(
            categories: [category],
            supplies: [supply],
            stock: [
                StockRecord(supplyId: "w", date: d0, remaining: 10),
                StockRecord(supplyId: "w", date: d3, remaining: 0),
            ],
            lots: [lot]
        )
        let engine = Engine(data: data, today: d3)
        let waste = engine.waste()
        #expect(waste.count == 1)
        #expect(waste.first?.quantity == 10)
        #expect(waste.first?.soles == 40)
        #expect(engine.activeLots("w").isEmpty)
        #expect(engine.currentStock("w") == 0)
    }

    @Test func anomalyRequiresBothFactorAndSolesFloor() {
        let start = dateFor(year: 2026, month: 1, day: 1)
        let today = addDays(start, 31)

        let lowCategory = CategoryInfo(id: "lc", name: "LC", purchaseIntervalDays: 3, monthlySpend: 60)
        let lowSupply = testSupply("lo", unit: "atados", categoryId: "lc", referencePrice: 2)
        var lowStock: [StockRecord] = []
        for i in 0...30 {
            lowStock.append(StockRecord(supplyId: "lo", date: addDays(start, i), remaining: 100 - Double(i)))
        }
        let lowData = KiloData(categories: [lowCategory], supplies: [lowSupply], stock: lowStock, lots: [])
        let lowEngine = Engine(data: lowData, today: today)
        let notFlagged = lowEngine.checkClose("lo", remaining: 100 - 30 - 3.4)
        #expect(notFlagged == nil)

        let highCategory = CategoryInfo(id: "hc", name: "HC", purchaseIntervalDays: 3, monthlySpend: 300)
        let highSupply = testSupply("hi", categoryId: "hc", referencePrice: 24)
        var highStock: [StockRecord] = []
        for i in 0...30 {
            highStock.append(StockRecord(supplyId: "hi", date: addDays(start, i), remaining: 1000 - Double(i) * 4))
        }
        let highData = KiloData(categories: [highCategory], supplies: [highSupply], stock: highStock, lots: [])
        let highEngine = Engine(data: highData, today: today)
        let flagged = highEngine.checkClose("hi", remaining: 1000 - 30 * 4 - 13)
        #expect(flagged?.consumed == 13)
        #expect(flagged?.usual == 4)
    }

    @Test func priceFlagUsesFortyPercentTolerance() {
        let category = CategoryInfo(id: "pc", name: "PC", purchaseIntervalDays: 3, monthlySpend: 300)
        let supply = testSupply("pr", categoryId: "pc", referencePrice: 5)
        let start = dateFor(year: 2026, month: 1, day: 1)
        let lots = [
            Lot(id: "pl1", supplyId: "pr", purchasedOn: start, quantity: 10, cost: 50, expiresOn: addDays(start, 10)),
            Lot(id: "pl2", supplyId: "pr", purchasedOn: addDays(start, 1), quantity: 10, cost: 50, expiresOn: addDays(start, 11)),
        ]
        let data = KiloData(categories: [category], supplies: [supply], stock: [], lots: lots)
        let engine = Engine(data: data, today: addDays(start, 5))
        #expect(engine.checkPrice("pr", unitPrice: 6.9) == nil)
        #expect(engine.checkPrice("pr", unitPrice: 7.1) != nil)
    }
}
