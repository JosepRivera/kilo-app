import Foundation

struct MonthWaste {
    let month: Date
    let soles: Double
}

struct WastedSupply {
    let supply: SupplyInfo
    let soles: Double
}

struct SavingsModel {
    let months: [MonthWaste]
    let current: Double
    let previous: Double
    let topWasted: [WastedSupply]

    init(engine: Engine, data: KiloData) {
        let byMonth = engine.monthlyWaste()
        let thisMonth = SavingsModel.monthStart(engine.today)
        months = (0..<4).reversed().map { back in
            let month = kiloCalendar.date(byAdding: .month, value: -back, to: thisMonth)!
            return MonthWaste(month: month, soles: byMonth[month] ?? 0)
        }
        current = months.last?.soles ?? 0
        previous = months.count >= 2 ? months[months.count - 2].soles : 0
        topWasted = Array(
            Dictionary(
                grouping: engine.waste().filter { SavingsModel.monthStart($0.date) == thisMonth },
                by: \.supplyId
            )
            .map { WastedSupply(supply: data.supply($0.key), soles: $0.value.reduce(0) { $0 + $1.soles }) }
            .sorted { $0.soles > $1.soles }
            .prefix(5)
        )
    }

    static func monthStart(_ date: Date) -> Date {
        kiloCalendar.date(from: kiloCalendar.dateComponents([.year, .month], from: date))!
    }
}
