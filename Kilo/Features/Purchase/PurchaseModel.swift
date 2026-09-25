import Foundation

enum PurchaseLineKind {
    case resolved(SupplyInfo, isNew: Bool)
    case ambiguous(spoken: String, candidates: [SupplyInfo])
    case unknown(spoken: String)
}

struct PurchaseLineDraft: Identifiable {
    let id: String
    var kind: PurchaseLineKind
    var heard: String
    var quantity: Double
    var cost: Double
    var expiresOn: Date
    var priceConfirmed = false
    var quantityQuestion: String? = nil
    var quantityPhrase: String? = nil

    var supply: SupplyInfo? {
        if case .resolved(let s, _) = kind { return s }
        return nil
    }

    func priceFlag(_ engine: Engine) -> PriceFlag? {
        guard let supply, quantity > 0 else { return nil }
        return engine.checkPrice(supply.id, unitPrice: cost / quantity)
    }

    func isValid(_ engine: Engine) -> Bool {
        guard supply != nil, quantity > 0 else { return false }
        if quantityQuestion != nil { return false }
        if priceFlag(engine) != nil && !priceConfirmed { return false }
        return true
    }
}

struct PurchaseModel {
    var lines: [PurchaseLineDraft]

    init(engine: Engine, data: KiloData, isBought: (String) -> Bool) {
        let due = data.supplies.filter { engine.isDue($0.categoryId) }
        let recommendations = due.map { engine.recommend($0.id) }.filter { $0.toBuy > 0 }
        let bought = recommendations.filter { isBought($0.supply.id) }
        let base = bought.isEmpty ? Array(recommendations.sorted { $0.toBuy * $0.supply.referencePrice > $1.toBuy * $1.supply.referencePrice }.prefix(1)) : bought

        var lines: [PurchaseLineDraft] = base.map { rec in
            let supply = rec.supply
            let quantity = rec.toBuy
            let cost = supply.id == "onion" ? quantity * supply.referencePrice * 1.6 : quantity * supply.referencePrice
            return PurchaseLineDraft(
                id: supply.id,
                kind: .resolved(supply, isNew: false),
                heard: "\(withUnit(quantity, supply.unit)) de \(supply.name.lowercased())",
                quantity: quantity,
                cost: cost,
                expiresOn: addDays(engine.today, supply.shelfLifeDays)
            )
        }

        if !lines.contains(where: { $0.id == "onion" }) {
            let onion = data.supply("onion")
            let quantity = 2.0
            lines.append(PurchaseLineDraft(
                id: "onion",
                kind: .resolved(onion, isNew: false),
                heard: "\(withUnit(quantity, onion.unit)) de cebolla",
                quantity: quantity,
                cost: quantity * onion.referencePrice * 1.6,
                expiresOn: addDays(engine.today, onion.shelfLifeDays)
            ))
        }

        if let candidates = PurchaseModel.ambiguousLimeCandidates(data: data) {
            let quantity = 0.5
            lines.append(PurchaseLineDraft(
                id: "spoken-limon",
                kind: .ambiguous(spoken: "limón", candidates: candidates),
                heard: "medio kilo de limón",
                quantity: quantity,
                cost: 0,
                expiresOn: addDays(engine.today, 10)
            ))
        }

        lines.append(PurchaseLineDraft(
            id: "spoken-huacatay",
            kind: .unknown(spoken: "huacatay"),
            heard: "un atado de huacatay",
            quantity: 1,
            cost: 0,
            expiresOn: addDays(engine.today, 3)
        ))

        if !lines.contains(where: { $0.id == "tomato" }) {
            let tomato = data.supply("tomato")
            lines.append(PurchaseLineDraft(
                id: "tomato",
                kind: .resolved(tomato, isNew: false),
                heard: "medio balde de tomate",
                quantity: 0,
                cost: 0,
                expiresOn: addDays(engine.today, tomato.shelfLifeDays),
                quantityQuestion: "¿Cuántos kg es «medio balde» de tomate?",
                quantityPhrase: "medio balde"
            ))
        } else if let index = lines.firstIndex(where: { $0.id == "tomato" }) {
            lines[index].heard = "medio balde de tomate"
            lines[index].quantity = 0
            lines[index].cost = 0
            lines[index].quantityQuestion = "¿Cuántos kg es «medio balde» de tomate?"
            lines[index].quantityPhrase = "medio balde"
        }

        self.lines = lines
    }

    private static func ambiguousLimeCandidates(data: KiloData) -> [SupplyInfo]? {
        if case .ambiguous(let candidates) = resolve("limón", in: data) { return candidates }
        return nil
    }
}
