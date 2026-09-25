import Foundation
import Observation

struct PurchaseLine {
    let supplyId: String
    let quantity: Double
    let cost: Double
    let expiresOn: Date
}

@Observable
final class KiloStore {
    private(set) var data: KiloData
    var closeDraft: [String: Double]?
    private let clock: @MainActor () -> Date
    private var cachedEngine: Engine?

    init(data: KiloData, clock: @escaping @MainActor () -> Date = { Date() }) {
        self.data = data
        self.clock = clock
    }

    static func demo(clock: @escaping @MainActor () -> Date = defaultDemoClock) -> KiloStore {
        KiloStore(data: demoData(), clock: clock)
    }

    var today: Date { businessDate(clock()) }

    var engine: Engine {
        if let cached = cachedEngine, cached.today == today { return cached }
        let created = Engine(data: data, today: today)
        cachedEngine = created
        return created
    }

    private func changed() {
        cachedEngine = nil
    }

    func isBought(_ supplyId: String) -> Bool {
        data.boughtByDay[dayKey(today)]?.contains(supplyId) ?? false
    }

    func toggleBought(_ supplyId: String) {
        var set = data.boughtByDay[dayKey(today)] ?? []
        if set.contains(supplyId) {
            set.remove(supplyId)
        } else {
            set.insert(supplyId)
        }
        data.boughtByDay[dayKey(today)] = set
        changed()
    }

    func closeSupplies() -> [SupplyInfo] {
        data.supplies.filter { $0.critical || daysSinceRecorded($0.id) >= 7 }
    }

    private func daysSinceRecorded(_ supplyId: String) -> Int {
        let real = engine.records(supplyId).filter { !$0.isClosed }
        guard let last = real.last else { return 999 }
        return daysBetween(last.date, today)
    }

    func saveClose(_ remaining: [String: Double]) {
        closeDraft = nil
        data.stock.removeAll { $0.date == today && remaining[$0.supplyId] != nil }
        data.stock.append(contentsOf: remaining.map { StockRecord(supplyId: $0.key, date: today, remaining: $0.value) })
        changed()
    }

    func markNoConsumption() {
        data.stock.removeAll { $0.date == today }
        data.stock.append(contentsOf: data.supplies.map { StockRecord.closed($0.id, today) })
        changed()
    }

    func savePurchase(_ lines: [PurchaseLine]) {
        let stamp = Int(clock().timeIntervalSince1970 * 1_000_000)
        let newLots = lines.enumerated().map { index, line in
            Lot(
                id: "p\(stamp)-\(index)",
                supplyId: line.supplyId,
                purchasedOn: today,
                quantity: line.quantity,
                cost: line.cost,
                expiresOn: line.expiresOn
            )
        }
        data.lots.append(contentsOf: newLots)
        var set = data.boughtByDay[dayKey(today)] ?? []
        set.formUnion(lines.map { $0.supplyId })
        data.boughtByDay[dayKey(today)] = set
        changed()
    }

    func setCritical(_ supplyId: String, critical: Bool) {
        guard let index = data.supplies.firstIndex(where: { $0.id == supplyId }) else { return }
        data.supplies[index].critical = critical
        changed()
    }

    func addSupply(_ supply: SupplyInfo) {
        guard !data.supplies.contains(where: { $0.id == supply.id }) else { return }
        data.supplies.append(supply)
        changed()
    }

    func setPhrase(_ phrase: String, amount: Double, for supplyId: String) {
        guard let index = data.supplies.firstIndex(where: { $0.id == supplyId }) else { return }
        data.supplies[index].phrases[phrase] = amount
        changed()
    }
}
