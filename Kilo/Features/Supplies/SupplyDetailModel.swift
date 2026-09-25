import Foundation

struct DayUsage {
    let label: String
    let amount: Double
}

struct LotDisplay {
    let state: LotState
    let daysLeft: Int
}

struct RecentDay {
    enum Kind { case real, estimated, closed, missing }

    let date: Date
    let amount: Double
    let kind: Kind
}

struct SupplyDetailModel {
    let supply: SupplyInfo
    let stock: Double
    let realDays: Int
    let week: [DayUsage]
    let peaks: [String]
    let lots: [LotDisplay]
    let recent: [RecentDay]

    init(engine: Engine, data: KiloData, supplyId: String) {
        supply = data.supply(supplyId)
        stock = engine.currentStock(supplyId)
        realDays = engine.realDays(supplyId)
        week = (0..<7).map { offset in
            let date = addDays(engine.today, offset)
            return DayUsage(
                label: offset == 0 ? "Hoy" : weekdayShort[weekday(of: date) - 1],
                amount: engine.forecast(supplyId, date)
            )
        }
        peaks = (0..<7)
            .map { addDays(engine.today, $0) }
            .sorted { engine.forecast(supplyId, $0) > engine.forecast(supplyId, $1) }
            .prefix(2)
            .map { weekdayLong[weekday(of: $0) - 1] }
        lots = engine.activeLots(supplyId)
            .filter { !$0.lot.id.hasPrefix(openingLotPrefix) }
            .map { LotDisplay(state: $0, daysLeft: daysBetween(engine.today, $0.lot.expiresOn)) }
        let consumption = engine.consumption(supplyId)
        recent = (1...7).map { back in
            let date = addDays(engine.today, -back)
            guard let entry = consumption[date] else { return RecentDay(date: date, amount: 0, kind: .missing) }
            let kind: RecentDay.Kind = entry.closed ? .closed : entry.estimated ? .estimated : .real
            return RecentDay(date: date, amount: entry.amount, kind: kind)
        }
    }
}
