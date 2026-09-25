import Foundation

let kiloTimeZone = TimeZone(identifier: "America/Lima")!

let kiloCalendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = kiloTimeZone
    return calendar
}()

func startOfDay(_ date: Date) -> Date {
    kiloCalendar.startOfDay(for: date)
}

func businessDate(_ date: Date) -> Date {
    let hour = kiloCalendar.component(.hour, from: date)
    let base = hour < 6 ? kiloCalendar.date(byAdding: .day, value: -1, to: date)! : date
    return startOfDay(base)
}

func addDays(_ date: Date, _ days: Int) -> Date {
    kiloCalendar.date(byAdding: .day, value: days, to: startOfDay(date))!
}

func daysBetween(_ a: Date, _ b: Date) -> Int {
    kiloCalendar.dateComponents([.day], from: startOfDay(a), to: startOfDay(b)).day!
}

func dateFor(year: Int, month: Int, day: Int) -> Date {
    kiloCalendar.date(from: DateComponents(year: year, month: month, day: day))!
}

func dayKey(_ date: Date) -> String {
    let c = kiloCalendar.dateComponents([.year, .month, .day], from: date)
    return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
}

func weekday(of date: Date) -> Int {
    let raw = kiloCalendar.component(.weekday, from: date)
    return raw == 1 ? 7 : raw - 1
}

let farFutureDate = dateFor(year: 9999, month: 1, day: 1)

struct CategoryInfo: Identifiable, Hashable {
    let id: String
    let name: String
    let purchaseIntervalDays: Int
    let monthlySpend: Double
}

struct SupplyInfo: Identifiable, Hashable {
    let id: String
    let name: String
    let unit: String
    let categoryId: String
    let shelfLifeDays: Int
    let referencePrice: Double
    let icon: String?
    var critical: Bool = true
    var phrases: [String: Double]

    var assetName: String {
        guard let icon, !icon.isEmpty else { return "Supplies/generic" }
        return "Supplies/\(icon)"
    }
}

struct StockRecord: Hashable {
    let supplyId: String
    let date: Date
    let remaining: Double?

    var isClosed: Bool { remaining == nil }

    static func closed(_ supplyId: String, _ date: Date) -> StockRecord {
        StockRecord(supplyId: supplyId, date: date, remaining: nil)
    }
}

struct Lot: Identifiable, Hashable {
    let id: String
    let supplyId: String
    let purchasedOn: Date
    let quantity: Double
    let cost: Double
    let expiresOn: Date

    var unitPrice: Double { cost / quantity }
}

struct KiloData {
    var categories: [CategoryInfo]
    var supplies: [SupplyInfo]
    var stock: [StockRecord]
    var lots: [Lot]
    var boughtByDay: [String: Set<String>] = [:]

    func supply(_ id: String) -> SupplyInfo {
        supplies.first { $0.id == id }!
    }

    func category(_ id: String) -> CategoryInfo {
        categories.first { $0.id == id }!
    }
}
