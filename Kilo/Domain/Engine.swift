import Foundation

let coldStartDays = 28
let serviceZ = 1.28
let bufferFloor = 0.10
let bufferCeiling = 0.60
let anomalyFactor = 3.0
let anomalyFloorSoles = 10.0
let priceTolerance = 0.40
let estimatedDayWeight = 0.5
let openingLotPrefix = "opening-"

struct Consumption {
    let amount: Double
    var estimated: Bool = false
    var closed: Bool = false
}

struct Recommendation {
    let supply: SupplyInfo
    let toBuy: Double
    let onHand: Double
    let needed: Double
    let horizonDays: Int
}

struct LotState {
    let lot: Lot
    let remaining: Double
}

struct WasteEvent {
    let date: Date
    let supplyId: String
    let quantity: Double
    let soles: Double
}

struct ExpiryAlert {
    let supply: SupplyInfo
    let lot: LotState
    let daysLeft: Int
}

struct AnomalyFlag {
    let consumed: Double
    let usual: Double
}

struct PriceFlag {
    let unitPrice: Double
    let usual: Double
}

func median(_ xs: [Double]) -> Double {
    if xs.isEmpty { return 0 }
    let s = xs.sorted()
    let m = s.count / 2
    return s.count % 2 == 1 ? s[m] : (s[m - 1] + s[m]) / 2
}

func mean(_ xs: [Double]) -> Double {
    xs.isEmpty ? 0 : xs.reduce(0, +) / Double(xs.count)
}

func roundUpToStep(_ value: Double, unit: String) -> Double {
    let step = (unit == "kg" || unit == "litros") ? 0.5 : 1.0
    return (value / step).rounded(.up) * step
}

final class Engine {
    let data: KiloData
    let today: Date

    private var consumptionCache: [String: [Date: Consumption]] = [:]
    private var lotsCache: [String: (lots: [LotState], waste: [WasteEvent])] = [:]

    init(data: KiloData, today: Date) {
        self.data = data
        self.today = today
    }

    func records(_ id: String) -> [StockRecord] {
        data.stock.filter { $0.supplyId == id }.sorted { $0.date < $1.date }
    }

    func lotsOf(_ id: String) -> [Lot] {
        data.lots.filter { $0.supplyId == id }.sorted { $0.purchasedOn < $1.purchasedOn }
    }

    func purchasesIn(_ id: String, after afterExclusive: Date, until untilInclusive: Date) -> Double {
        data.lots
            .filter { $0.supplyId == id && $0.purchasedOn > afterExclusive && $0.purchasedOn <= untilInclusive }
            .reduce(0.0) { $0 + $1.quantity }
    }

    func consumption(_ id: String) -> [Date: Consumption] {
        if let cached = consumptionCache[id] { return cached }
        var out: [Date: Consumption] = [:]
        let recs = records(id)
        guard let firstIdx = recs.firstIndex(where: { !$0.isClosed }) else {
            consumptionCache[id] = out
            return out
        }
        var prevStock = recs[firstIdx].remaining!
        var prevDate = recs[firstIdx].date
        for r in recs[(firstIdx + 1)...] {
            let bought = purchasesIn(id, after: prevDate, until: r.date)
            if r.isClosed {
                prevStock += bought
                out[r.date] = Consumption(amount: 0, closed: true)
                prevDate = r.date
                continue
            }
            let total = max(0.0, prevStock + bought - r.remaining!)
            let gap = daysBetween(prevDate, r.date)
            if gap <= 1 {
                out[r.date] = Consumption(amount: total)
            } else {
                for k in 1...gap {
                    out[addDays(prevDate, k)] = Consumption(amount: total / Double(gap), estimated: true)
                }
            }
            prevStock = r.remaining!
            prevDate = r.date
        }
        consumptionCache[id] = out
        return out
    }

    func realDays(_ id: String) -> Int {
        let total = consumption(id).values.reduce(0.0) { $0 + ($1.estimated ? estimatedDayWeight : 1.0) }
        return Int(total.rounded(.down))
    }

    func isLearning(_ id: String) -> Bool { realDays(id) < coldStartDays }

    func currentStock(_ id: String) -> Double {
        if !lotsOf(id).isEmpty {
            return activeLots(id).reduce(0.0) { $0 + $1.remaining }
        }
        let recs = records(id).filter { !$0.isClosed }
        return recs.isEmpty ? 0 : recs.last!.remaining!
    }

    func coldStartEstimate(_ id: String) -> Double {
        let s = data.supply(id)
        let siblings = data.supplies.filter { $0.categoryId == s.categoryId }.count
        return data.category(s.categoryId).monthlySpend / Double(siblings) / 30 / s.referencePrice
    }

    private func window(_ id: String, _ days: Int) -> [(date: Date, value: Consumption)] {
        let from = addDays(today, -days)
        return consumption(id)
            .map { (date: $0.key, value: $0.value) }
            .filter { $0.date >= from && $0.date < today }
    }

    private func empirical(_ id: String, weekday wd: Int) -> Double {
        let w = window(id, 28)
        let same = w.filter { weekday(of: $0.date) == wd }.map { $0.value.amount }
        if same.count >= 2 { return mean(same) }
        return mean(w.map { $0.value.amount })
    }

    func forecast(_ id: String, _ d: Date) -> Double {
        let real = realDays(id)
        let cold = coldStartEstimate(id)
        if real == 0 { return cold }
        let weight = max(0.0, 1 - Double(real) / Double(coldStartDays))
        return weight * cold + (1 - weight) * empirical(id, weekday: weekday(of: d))
    }

    func errorEstimate(_ id: String) -> Double {
        let w = window(id, 28).filter { !$0.value.closed }
        if w.count < 7 { return 0.3 * forecast(id, today) }
        let residuals = w.map { $0.value.amount - empirical(id, weekday: weekday(of: $0.date)) }
        let m = mean(residuals)
        return sqrt(mean(residuals.map { ($0 - m) * ($0 - m) }))
    }

    func recommend(_ id: String) -> Recommendation {
        let s = data.supply(id)
        let h = data.category(s.categoryId).purchaseIntervalDays
        let demand = (0..<h).reduce(0.0) { $0 + forecast(id, addDays(today, $1)) }
        let rawBuffer = serviceZ * errorEstimate(id) * Double(h).squareRoot()
        let buffer = min(max(rawBuffer, bufferFloor * demand), bufferCeiling * demand)
        let onHand = currentStock(id)
        let raw = demand + buffer - onHand
        return Recommendation(
            supply: s,
            toBuy: raw <= 0 ? 0 : roundUpToStep(raw, unit: s.unit),
            onHand: onHand,
            needed: demand + buffer,
            horizonDays: h
        )
    }

    func lastPurchase(category categoryId: String) -> Date? {
        let ids = Set(data.supplies.filter { $0.categoryId == categoryId }.map { $0.id })
        return data.lots.filter { ids.contains($0.supplyId) }.map { $0.purchasedOn }.max()
    }

    func isDue(_ categoryId: String) -> Bool {
        guard let last = lastPurchase(category: categoryId) else { return true }
        let gap = daysBetween(last, today)
        if gap == 0 { return true }
        return gap >= data.category(categoryId).purchaseIntervalDays
    }

    private func simulateLots(_ id: String) -> (lots: [LotState], waste: [WasteEvent]) {
        if let cached = lotsCache[id] { return cached }
        let lots = lotsOf(id)
        guard !lots.isEmpty else {
            let result: (lots: [LotState], waste: [WasteEvent]) = ([], [])
            lotsCache[id] = result
            return result
        }
        var counted: [Date: Double] = [:]
        for r in records(id) where !r.isClosed {
            counted[r.date] = r.remaining!
        }
        var queue: [(lot: Lot, remaining: Double)] = []
        var waste: [WasteEvent] = []
        var i = 0
        let firstCount = counted.keys.min()
        let start = (firstCount != nil && firstCount! < lots[0].purchasedOn) ? firstCount! : lots[0].purchasedOn

        var d = start
        while d <= today {
            queue.removeAll { entry in
                if entry.lot.expiresOn >= d || entry.remaining <= 0.001 { return false }
                waste.append(WasteEvent(date: d, supplyId: id, quantity: entry.remaining, soles: entry.remaining * entry.lot.unitPrice))
                return true
            }
            while i < lots.count && lots[i].purchasedOn <= d {
                queue.append((lots[i], lots[i].quantity))
                i += 1
            }
            if let remaining = counted[d] {
                var used = queue.reduce(0.0) { $0 + $1.remaining } - remaining
                if used < -0.001 {
                    let price = data.supply(id).referencePrice
                    let openingLot = Lot(
                        id: "\(openingLotPrefix)\(id)-\(dayKey(d))",
                        supplyId: id,
                        purchasedOn: d,
                        quantity: -used,
                        cost: -used * price,
                        expiresOn: farFutureDate
                    )
                    queue.insert((openingLot, -used), at: 0)
                }
                var k = 0
                while k < queue.count && used > 0 {
                    let take = min(used, queue[k].remaining)
                    queue[k].remaining -= take
                    used -= take
                    k += 1
                }
                queue.removeAll { $0.remaining <= 0.001 }
            }
            d = addDays(d, 1)
        }
        let result = (lots: queue.map { LotState(lot: $0.lot, remaining: $0.remaining) }, waste: waste)
        lotsCache[id] = result
        return result
    }

    func activeLots(_ id: String) -> [LotState] { simulateLots(id).lots }

    func waste() -> [WasteEvent] {
        data.supplies.flatMap { simulateLots($0.id).waste }
    }

    func expiryAlerts() -> [ExpiryAlert] {
        var alerts: [ExpiryAlert] = []
        for s in data.supplies {
            for l in activeLots(s.id) {
                let daysLeft = daysBetween(today, l.lot.expiresOn)
                if daysLeft <= 1 {
                    alerts.append(ExpiryAlert(supply: s, lot: l, daysLeft: daysLeft))
                }
            }
        }
        return alerts.sorted { $0.daysLeft < $1.daysLeft }
    }

    func monthlyWaste() -> [Date: Double] {
        var out: [Date: Double] = [:]
        for w in waste() {
            let c = kiloCalendar.dateComponents([.year, .month], from: w.date)
            let m = kiloCalendar.date(from: c)!
            out[m, default: 0] += w.soles
        }
        return out
    }

    private static let weekdayNames = ["lunes", "martes", "miércoles", "jueves", "viernes", "sábado", "domingo"]

    func lotLabel(_ l: Lot) -> String {
        let ago = daysBetween(l.purchasedOn, today)
        if ago == 0 { return "de hoy" }
        if ago == 1 { return "de ayer" }
        return "del \(Engine.weekdayNames[weekday(of: l.purchasedOn) - 1])"
    }

    func expectedRemainingTonight(_ id: String) -> Double {
        max(0, currentStock(id) - forecast(id, today))
    }

    func checkClose(_ id: String, remaining: Double) -> AnomalyFlag? {
        let recs = records(id).filter { $0.date < today }
        guard let lastReal = recs.lastIndex(where: { !$0.isClosed }) else { return nil }
        let prevDate = recs[lastReal].date
        let prevStock = recs[lastReal].remaining!
        let gap = max(1, daysBetween(prevDate, today))
        let consumed = max(0.0, prevStock + purchasesIn(id, after: prevDate, until: today) - remaining) / Double(gap)
        let w28 = window(id, 28).filter { !$0.value.closed }
        let sameDay = w28.filter { weekday(of: $0.date) == weekday(of: today) }.map { $0.value.amount }
        let usual: Double
        if sameDay.count >= 4 {
            usual = median(sameDay)
        } else {
            usual = median(window(id, 14).filter { !$0.value.closed }.map { $0.value.amount })
        }
        guard usual > 0 else { return nil }
        let excessSoles = (consumed - usual) * data.supply(id).referencePrice
        return (consumed > anomalyFactor * usual && excessSoles >= anomalyFloorSoles) ? AnomalyFlag(consumed: consumed, usual: usual) : nil
    }

    func checkPrice(_ id: String, unitPrice: Double) -> PriceFlag? {
        let prices = lotsOf(id).map { $0.unitPrice }
        guard !prices.isEmpty else { return nil }
        let usual = median(prices)
        return (abs(unitPrice - usual) / usual > priceTolerance) ? PriceFlag(unitPrice: unitPrice, usual: usual) : nil
    }
}
