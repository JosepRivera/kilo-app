import Foundation

struct CatalogEntry: Identifiable, Hashable {
    let name: String
    let unit: String
    let categoryId: String
    let icon: String?
    let shelfLifeDays: Int
    let referencePrice: Double

    var id: String { catalogSupplyId(name) }
}

let masterCatalog: [CatalogEntry] = [
    CatalogEntry(name: "Limón sutil", unit: "kg", categoryId: "produce", icon: "lime", shelfLifeDays: 10, referencePrice: 5),
    CatalogEntry(name: "Limón tahití", unit: "kg", categoryId: "produce", icon: "lime", shelfLifeDays: 14, referencePrice: 4),
    CatalogEntry(name: "Lima persa", unit: "kg", categoryId: "produce", icon: "lime", shelfLifeDays: 14, referencePrice: 4.5),
    CatalogEntry(name: "Papa canchán", unit: "kg", categoryId: "produce", icon: "potato", shelfLifeDays: 14, referencePrice: 2),
    CatalogEntry(name: "Cebolla roja", unit: "kg", categoryId: "produce", icon: "onion", shelfLifeDays: 20, referencePrice: 2.6),
    CatalogEntry(name: "Tomate", unit: "kg", categoryId: "produce", icon: "tomato", shelfLifeDays: 6, referencePrice: 3.5),
    CatalogEntry(name: "Ají amarillo", unit: "kg", categoryId: "produce", icon: "chili", shelfLifeDays: 10, referencePrice: 8),
    CatalogEntry(name: "Culantro", unit: "atados", categoryId: "produce", icon: "cilantro", shelfLifeDays: 3, referencePrice: 2),
]

private let ambiguousCatalogGroups: [String: [String]] = [
    "limon": ["Limón sutil", "Limón tahití", "Lima persa"],
]

func normalizedTerm(_ text: String) -> String {
    text
        .folding(options: .diacriticInsensitive, locale: Locale(identifier: "es_PE"))
        .lowercased()
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

func catalogSupplyId(_ name: String) -> String {
    normalizedTerm(name)
        .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
        .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
}

func catalogSupply(_ entry: CatalogEntry) -> SupplyInfo {
    SupplyInfo(
        id: catalogSupplyId(entry.name),
        name: entry.name,
        unit: entry.unit,
        categoryId: entry.categoryId,
        shelfLifeDays: entry.shelfLifeDays,
        referencePrice: entry.referencePrice,
        icon: entry.icon,
        critical: true,
        phrases: [:]
    )
}

enum Resolution {
    case exact(SupplyInfo)
    case ambiguous([SupplyInfo])
    case unknown(String)
}

func resolve(_ spoken: String, in data: KiloData) -> Resolution {
    let term = normalizedTerm(spoken)

    if let existing = data.supplies.first(where: { normalizedTerm($0.name) == term }) {
        return .exact(existing)
    }
    if let entry = masterCatalog.first(where: { normalizedTerm($0.name) == term }) {
        return .exact(catalogSupply(entry))
    }

    for (key, names) in ambiguousCatalogGroups where term.contains(key) || key.contains(term) {
        let candidates = names.compactMap { name -> SupplyInfo? in
            if let existing = data.supplies.first(where: { normalizedTerm($0.name) == normalizedTerm(name) }) {
                return existing
            }
            return masterCatalog.first { normalizedTerm($0.name) == normalizedTerm(name) }.map(catalogSupply)
        }
        if candidates.count > 1 { return .ambiguous(candidates) }
    }

    let existingMatches = data.supplies.filter { normalizedTerm($0.name).contains(term) }
    let catalogMatches = masterCatalog.filter { normalizedTerm($0.name).contains(term) }.map(catalogSupply)
    let combined = existingMatches + catalogMatches.filter { candidate in !existingMatches.contains { $0.id == candidate.id } }

    switch combined.count {
    case 0: return .unknown(spoken)
    case 1: return .exact(combined[0])
    default: return .ambiguous(combined)
    }
}
