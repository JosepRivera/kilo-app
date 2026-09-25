import Foundation

let historyStart = dateFor(year: 2026, month: 7, day: 1)
let demoDay = dateFor(year: 2026, month: 10, day: 30)
let exceptionalSunday = dateFor(year: 2026, month: 8, day: 2)
let chickenZigzagStart = dateFor(year: 2026, month: 10, day: 2)

let demoCategories: [CategoryInfo] = [
    CategoryInfo(id: "protein", name: "Proteínas", purchaseIntervalDays: 3, monthlySpend: 3000),
    CategoryInfo(id: "produce", name: "Verduras y frutas", purchaseIntervalDays: 3, monthlySpend: 1800),
    CategoryInfo(id: "grocery", name: "Granos y abarrotes", purchaseIntervalDays: 10, monthlySpend: 900),
    CategoryInfo(id: "seasoning", name: "Condimentos y especias", purchaseIntervalDays: 14, monthlySpend: 150),
    CategoryInfo(id: "dairy", name: "Lácteos y huevos", purchaseIntervalDays: 4, monthlySpend: 600),
]

private func supply(
    _ id: String,
    _ name: String,
    _ unit: String,
    _ categoryId: String,
    _ icon: String?,
    _ shelfLifeDays: Int,
    _ referencePrice: Double,
    critical: Bool = true,
    phrases: [String: Double] = [:]
) -> SupplyInfo {
    SupplyInfo(
        id: id,
        name: name,
        unit: unit,
        categoryId: categoryId,
        shelfLifeDays: shelfLifeDays,
        referencePrice: referencePrice,
        icon: icon,
        critical: critical,
        phrases: phrases
    )
}

let chickenInfo = supply("chicken", "Pollo entero", "kg", "protein", "chicken", 3, 9, phrases: ["una jaba": 18])
let beefInfo = supply("beef", "Carne de res", "kg", "protein", "beef", 4, 24)
let fishInfo = supply("fish", "Pescado", "kg", "protein", "fish", 2, 18)
let potatoInfo = supply("potato", "Papa canchán", "kg", "produce", "potato", 14, 2, phrases: ["un saco": 50])
let onionInfo = supply("onion", "Cebolla roja", "kg", "produce", "onion", 20, 2.6)
let tomatoInfo = supply("tomato", "Tomate", "kg", "produce", "tomato", 6, 3.5)
let limeInfo = supply("lime", "Limón sutil", "kg", "produce", "lime", 10, 5)
let cilantroInfo = supply("cilantro", "Culantro", "atados", "produce", "cilantro", 3, 2)
let chiliInfo = supply("chili", "Ají amarillo", "kg", "produce", "chili", 10, 8)
let cornInfo = supply("corn", "Choclo", "unidades", "produce", "corn", 5, 1.2)
let riceInfo = supply("rice", "Arroz", "kg", "grocery", "rice", 365, 4.2, critical: false)
let oilInfo = supply("oil", "Aceite vegetal", "litros", "grocery", "oil", 365, 8, critical: false, phrases: ["una lata": 18])
let legumesInfo = supply("legumes", "Menestras", "kg", "grocery", nil, 365, 7, critical: false)
let saltInfo = supply("salt", "Sal", "kg", "seasoning", "salt", 730, 1.5, critical: false)
let garlicInfo = supply("garlic", "Ajo", "kg", "seasoning", "garlic", 30, 10, critical: false)
let eggInfo = supply("egg", "Huevos", "unidades", "dairy", "egg", 21, 0.5)
let cheeseInfo = supply("cheese", "Queso fresco", "kg", "dairy", "cheese", 7, 18)

let demoSupplies: [SupplyInfo] = [
    chickenInfo, beefInfo, fishInfo,
    potatoInfo, onionInfo, tomatoInfo, limeInfo, cilantroInfo, chiliInfo, cornInfo,
    riceInfo, oilInfo, legumesInfo,
    saltInfo, garlicInfo,
    eggInfo, cheeseInfo,
]

private var lotSequence = 0

private func nextLotId() -> String {
    let id = "demo\(lotSequence)"
    lotSequence += 1
    return id
}

private struct WeeklyPlan {
    let supply: SupplyInfo
    let weekly: [Double]
    let overbuy: Double
    let intervalDays: Int
    let start: Date
    let spoilage: [(day: Date, quantity: Double, shelfLife: Int)]
    let avoidRecentPurchase: Bool

    init(
        supply: SupplyInfo,
        weekly: [Double],
        overbuy: Double,
        intervalDays: Int,
        start: Date,
        spoilage: [(day: Date, quantity: Double, shelfLife: Int)] = [],
        avoidRecentPurchase: Bool = false
    ) {
        self.supply = supply
        self.weekly = weekly
        self.overbuy = overbuy
        self.intervalDays = intervalDays
        self.start = start
        self.spoilage = spoilage
        self.avoidRecentPurchase = avoidRecentPurchase
    }
}

private func planTarget(_ plan: WeeklyPlan, _ date: Date) -> Double {
    if weekday(of: date) == 7 {
        return date == exceptionalSunday ? plan.weekly[0] : 0
    }
    return plan.weekly[weekday(of: date) - 1]
}

private func simulateWeeklyPlan(_ plan: WeeklyPlan) -> (stock: [StockRecord], lots: [Lot]) {
    var stock: [StockRecord] = []
    var lots: [Lot] = []
    var queue: [(lot: Lot, remaining: Double)] = []
    var doomed: [(lot: Lot, remaining: Double)] = []
    var lastPurchase: Date? = nil
    var d = plan.start

    while d < demoDay {
        queue.removeAll { $0.lot.expiresOn < d }
        doomed.removeAll { $0.lot.expiresOn < d }

        let isSunday = weekday(of: d) == 7
        let exceptional = d == exceptionalSunday
        let closedToday = isSunday && !exceptional

        let dueOnSchedule = lastPurchase == nil || daysBetween(lastPurchase!, d) >= plan.intervalDays
        let withinAvoidanceWindow = plan.avoidRecentPurchase && daysBetween(d, demoDay) < plan.intervalDays
        let due = dueOnSchedule && !withinAvoidanceWindow
        if due && !closedToday {
            let need = (0..<plan.intervalDays).reduce(0.0) { $0 + planTarget(plan, addDays(d, $1)) }
            let held = queue.reduce(0.0) { $0 + $1.remaining }
            let qty = roundUpToStep(max(0, need * plan.overbuy - held), unit: plan.supply.unit)
            if qty > 0 {
                let lot = Lot(
                    id: nextLotId(),
                    supplyId: plan.supply.id,
                    purchasedOn: d,
                    quantity: qty,
                    cost: qty * plan.supply.referencePrice,
                    expiresOn: addDays(d, plan.supply.shelfLifeDays)
                )
                lots.append(lot)
                queue.append((lot, qty))
            }
            lastPurchase = d
        }

        if let spoiled = plan.spoilage.first(where: { $0.day == d }) {
            let lot = Lot(
                id: nextLotId(),
                supplyId: plan.supply.id,
                purchasedOn: d,
                quantity: spoiled.quantity,
                cost: spoiled.quantity * plan.supply.referencePrice,
                expiresOn: addDays(d, spoiled.shelfLife)
            )
            lots.append(lot)
            doomed.append((lot, spoiled.quantity))
        }

        if closedToday {
            if plan.supply.critical { stock.append(.closed(plan.supply.id, d)) }
            d = addDays(d, 1)
            continue
        }

        var use = planTarget(plan, d)
        var k = 0
        while k < queue.count && use > 0.0001 {
            let take = min(use, queue[k].remaining)
            queue[k].remaining -= take
            use -= take
            k += 1
        }
        queue.removeAll { $0.remaining <= 0.001 }

        let remaining = queue.reduce(0.0) { $0 + $1.remaining } + doomed.reduce(0.0) { $0 + $1.remaining }
        let shouldRecord = plan.supply.critical || weekday(of: d) == 1 || d == plan.start
        if shouldRecord {
            stock.append(StockRecord(supplyId: plan.supply.id, date: d, remaining: remaining))
        }

        d = addDays(d, 1)
    }

    return (stock, lots)
}

private let chickenBase: [Double] = [8, 8, 8.5, 9, 14.5, 15.5, 0]
private let chickenFinalPurchase = dateFor(year: 2026, month: 10, day: 27)

private func chickenTarget(_ d: Date) -> Double {
    if weekday(of: d) == 7 { return 0 }
    if d < chickenZigzagStart { return chickenBase[weekday(of: d) - 1] }
    let weekIndex = daysBetween(chickenZigzagStart, d) / 7
    let sign: Double = weekIndex % 2 == 0 ? 1 : -1
    return chickenBase[weekday(of: d) - 1] + sign * 4
}

private func buildChicken() -> (stock: [StockRecord], lots: [Lot]) {
    var stock: [StockRecord] = []
    var lots: [Lot] = []
    var queue: [(lot: Lot, remaining: Double)] = []
    var doomed: [(lot: Lot, remaining: Double)] = []
    var lastPurchase: Date? = nil
    var d = historyStart

    while d < demoDay {
        queue.removeAll { $0.lot.expiresOn < d }
        doomed.removeAll { $0.lot.expiresOn < d }

        let due = lastPurchase == nil || daysBetween(lastPurchase!, d) >= 3
        if d == chickenFinalPurchase {
            queue.removeAll()
            let lotA = Lot(id: nextLotId(), supplyId: chickenInfo.id, purchasedOn: d, quantity: 15, cost: 15 * 8.5, expiresOn: addDays(d, 3))
            let lotB = Lot(id: nextLotId(), supplyId: chickenInfo.id, purchasedOn: d, quantity: 10.5, cost: 10.5 * 9.6, expiresOn: addDays(d, 3))
            lots.append(lotA)
            lots.append(lotB)
            queue.append((lotA, 15))
            queue.append((lotB, 10.5))
            lastPurchase = d
        } else if due {
            let need = (0..<3).reduce(0.0) { $0 + chickenTarget(addDays(d, $1)) }
            let held = queue.reduce(0.0) { $0 + $1.remaining }
            let qty = roundUpToStep(max(0, need - held), unit: "kg")
            if qty > 0 {
                let lot = Lot(id: nextLotId(), supplyId: chickenInfo.id, purchasedOn: d, quantity: qty, cost: qty * chickenInfo.referencePrice, expiresOn: addDays(d, 3))
                lots.append(lot)
                queue.append((lot, qty))
            }
            lastPurchase = d
        }

        if let spoiled = chickenSpoilage.first(where: { $0.day == d }) {
            let lot = Lot(id: nextLotId(), supplyId: chickenInfo.id, purchasedOn: d, quantity: spoiled.quantity, cost: spoiled.quantity * chickenInfo.referencePrice, expiresOn: addDays(d, spoiled.shelfLife))
            lots.append(lot)
            doomed.append((lot, spoiled.quantity))
        }

        let isSunday = weekday(of: d) == 7
        let exceptional = d == exceptionalSunday
        if isSunday && !exceptional {
            stock.append(.closed(chickenInfo.id, d))
            d = addDays(d, 1)
            continue
        }

        var use = exceptional ? chickenBase[0] : chickenTarget(d)
        var k = 0
        while k < queue.count && use > 0.0001 {
            let take = min(use, queue[k].remaining)
            queue[k].remaining -= take
            use -= take
            k += 1
        }
        queue.removeAll { $0.remaining <= 0.001 }
        let remaining = queue.reduce(0.0) { $0 + $1.remaining } + doomed.reduce(0.0) { $0 + $1.remaining }
        stock.append(StockRecord(supplyId: chickenInfo.id, date: d, remaining: remaining))

        d = addDays(d, 1)
    }

    return (stock, lots)
}

private let fishStart = dateFor(year: 2026, month: 10, day: 17)

private func buildFish() -> (stock: [StockRecord], lots: [Lot]) {
    var stock: [StockRecord] = []
    var lots: [Lot] = []
    var queue: [(lot: Lot, remaining: Double)] = []
    var doomed: [(lot: Lot, remaining: Double)] = []
    var lastPurchase: Date? = nil
    var d = fishStart

    func target(_ date: Date) -> Double { weekday(of: date) == 7 ? 0 : 2 }

    while d < demoDay {
        queue.removeAll { $0.lot.expiresOn < d }
        doomed.removeAll { $0.lot.expiresOn < d }

        let dueOnSchedule = lastPurchase == nil || daysBetween(lastPurchase!, d) >= 2
        let due = dueOnSchedule && daysBetween(d, demoDay) >= 3
        if due {
            let need = (0..<2).reduce(0.0) { $0 + target(addDays(d, $1)) }
            let held = queue.reduce(0.0) { $0 + $1.remaining }
            let qty = roundUpToStep(max(0, need * 1.1 - held), unit: "kg")
            if qty > 0 {
                let lot = Lot(id: nextLotId(), supplyId: fishInfo.id, purchasedOn: d, quantity: qty, cost: qty * fishInfo.referencePrice, expiresOn: addDays(d, 2))
                lots.append(lot)
                queue.append((lot, qty))
            }
            lastPurchase = d
        }

        if let spoiled = fishSpoilage.first(where: { $0.day == d }) {
            let lot = Lot(id: nextLotId(), supplyId: fishInfo.id, purchasedOn: d, quantity: spoiled.quantity, cost: spoiled.quantity * fishInfo.referencePrice, expiresOn: addDays(d, spoiled.shelfLife))
            lots.append(lot)
            doomed.append((lot, spoiled.quantity))
        }

        var use = target(d)
        var k = 0
        while k < queue.count && use > 0.0001 {
            let take = min(use, queue[k].remaining)
            queue[k].remaining -= take
            use -= take
            k += 1
        }
        queue.removeAll { $0.remaining <= 0.001 }
        let remaining = queue.reduce(0.0) { $0 + $1.remaining } + doomed.reduce(0.0) { $0 + $1.remaining }
        stock.append(StockRecord(supplyId: fishInfo.id, date: d, remaining: remaining))

        d = addDays(d, 1)
    }

    return (stock, lots)
}

private let cilantroSpoilage: [(day: Date, quantity: Double, shelfLife: Int)] = [
    (dateFor(year: 2026, month: 7, day: 8), 20, 2),
    (dateFor(year: 2026, month: 7, day: 22), 20, 2),
    (dateFor(year: 2026, month: 8, day: 5), 15, 2),
    (dateFor(year: 2026, month: 8, day: 19), 15, 2),
    (dateFor(year: 2026, month: 9, day: 2), 10, 2),
    (dateFor(year: 2026, month: 9, day: 16), 10, 2),
    (dateFor(year: 2026, month: 9, day: 28), 8, 2),
]

private let tomatoSpoilage: [(day: Date, quantity: Double, shelfLife: Int)] = [
    (dateFor(year: 2026, month: 7, day: 15), 30, 2),
    (dateFor(year: 2026, month: 8, day: 12), 25, 2),
    (dateFor(year: 2026, month: 9, day: 9), 18, 2),
    (dateFor(year: 2026, month: 9, day: 28), 12, 2),
]

private let cornSpoilage: [(day: Date, quantity: Double, shelfLife: Int)] = [
    (dateFor(year: 2026, month: 10, day: 26), 20, cornInfo.shelfLifeDays),
]

private let chickenSpoilage: [(day: Date, quantity: Double, shelfLife: Int)] = [
    (dateFor(year: 2026, month: 7, day: 25), 21, 2),
    (dateFor(year: 2026, month: 8, day: 24), 17, 2),
    (dateFor(year: 2026, month: 9, day: 23), 16, 2),
    (dateFor(year: 2026, month: 9, day: 29), 11, 1),
]

private let fishSpoilage: [(day: Date, quantity: Double, shelfLife: Int)] = [
    (dateFor(year: 2026, month: 10, day: 22), 4, 2),
]

func demoData() -> KiloData {
    lotSequence = 0
    var stock: [StockRecord] = []
    var lots: [Lot] = []

    let chicken = buildChicken()
    stock.append(contentsOf: chicken.stock)
    lots.append(contentsOf: chicken.lots)

    let fish = buildFish()
    stock.append(contentsOf: fish.stock)
    lots.append(contentsOf: fish.lots)

    let genericPlans: [WeeklyPlan] = [
        WeeklyPlan(supply: beefInfo, weekly: [3, 3, 3, 3, 4, 4.5, 0], overbuy: 1.0, intervalDays: 3, start: historyStart, avoidRecentPurchase: true),
        WeeklyPlan(supply: potatoInfo, weekly: [5, 5, 5, 5.5, 6, 6.5, 0], overbuy: 1.15, intervalDays: 14, start: historyStart),
        WeeklyPlan(supply: onionInfo, weekly: [3, 3, 3, 3, 3.5, 4, 0], overbuy: 1.0, intervalDays: 3, start: historyStart, avoidRecentPurchase: true),
        WeeklyPlan(supply: tomatoInfo, weekly: [2, 2, 2, 2, 2.5, 2.5, 0], overbuy: 1.0, intervalDays: 3, start: historyStart, spoilage: tomatoSpoilage, avoidRecentPurchase: true),
        WeeklyPlan(supply: limeInfo, weekly: [1.5, 1.5, 1.5, 1.5, 2, 2, 0], overbuy: 1.0, intervalDays: 3, start: historyStart, avoidRecentPurchase: true),
        WeeklyPlan(supply: cilantroInfo, weekly: [1, 1, 1, 1, 1, 1, 0], overbuy: 1.0, intervalDays: 3, start: historyStart, spoilage: cilantroSpoilage, avoidRecentPurchase: true),
        WeeklyPlan(supply: chiliInfo, weekly: [0.5, 0.5, 0.5, 0.5, 1, 1, 0], overbuy: 1.0, intervalDays: 3, start: historyStart, avoidRecentPurchase: true),
        WeeklyPlan(supply: cornInfo, weekly: [6, 6, 6, 6, 8, 8, 0], overbuy: 1.0, intervalDays: 3, start: historyStart, spoilage: cornSpoilage, avoidRecentPurchase: true),
        WeeklyPlan(supply: riceInfo, weekly: [4, 4, 4, 4, 5, 5, 0], overbuy: 1.0, intervalDays: 10, start: dateFor(year: 2026, month: 7, day: 3)),
        WeeklyPlan(supply: oilInfo, weekly: [1.5, 1.5, 1.5, 1.5, 2, 2.5, 0], overbuy: 1.0, intervalDays: 10, start: dateFor(year: 2026, month: 7, day: 3)),
        WeeklyPlan(supply: legumesInfo, weekly: [1, 1, 1, 1, 1, 1, 0], overbuy: 1.0, intervalDays: 10, start: dateFor(year: 2026, month: 7, day: 3)),
        WeeklyPlan(supply: saltInfo, weekly: [0.5, 0.5, 0.5, 0.5, 0.5, 1, 0], overbuy: 1.0, intervalDays: 14, start: historyStart),
        WeeklyPlan(supply: garlicInfo, weekly: [0.5, 0.5, 0.5, 0.5, 0.5, 1, 0], overbuy: 1.0, intervalDays: 14, start: historyStart),
        WeeklyPlan(supply: eggInfo, weekly: [20, 20, 20, 20, 25, 30, 0], overbuy: 1.0, intervalDays: 4, start: dateFor(year: 2026, month: 7, day: 2), avoidRecentPurchase: true),
        WeeklyPlan(supply: cheeseInfo, weekly: [0.5, 0.5, 0.5, 0.5, 0.5, 1, 0], overbuy: 1.0, intervalDays: 4, start: dateFor(year: 2026, month: 7, day: 2), avoidRecentPurchase: true),
    ]

    for plan in genericPlans {
        let result = simulateWeeklyPlan(plan)
        stock.append(contentsOf: result.stock)
        lots.append(contentsOf: result.lots)
    }

    let tomatoGapDays: Set<Date> = [
        dateFor(year: 2026, month: 10, day: 27),
        dateFor(year: 2026, month: 10, day: 28),
    ]
    stock.removeAll { $0.supplyId == tomatoInfo.id && tomatoGapDays.contains($0.date) }

    return KiloData(categories: demoCategories, supplies: demoSupplies, stock: stock, lots: lots)
}

func defaultDemoClock() -> Date {
    let now = Date()
    var comps = kiloCalendar.dateComponents([.hour, .minute, .second, .nanosecond], from: now)
    comps.hour = max(6, comps.hour ?? 6)
    let dayComps = kiloCalendar.dateComponents([.year, .month, .day], from: demoDay)
    comps.year = dayComps.year
    comps.month = dayComps.month
    comps.day = dayComps.day
    return kiloCalendar.date(from: comps)!
}
