import SwiftUI

struct ExpiryAlertRow: View {
    let group: ExpiryGroup
    let label: String

    var body: some View {
        let title = group.alerts.count == 1
            ? "El lote \(label) \(expiryText(group.daysLeft))"
            : "\(group.alerts.count) lotes \(expiryText(group.daysLeft).replacingOccurrences(of: "vence", with: "vencen"))"
        HStack(spacing: 14) {
            SupplyIcon(supply: group.supply, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.kiloAlert)
                Text("\(group.supply.name) · quedan \(withUnit(group.remaining, group.supply.unit)) · úsalo primero")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.kiloAlert)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

struct PurchaseRow: View {
    let recommendation: Recommendation
    let learning: Bool
    let bought: Bool
    let toggle: () -> Void
    let explain: () -> Void

    var body: some View {
        let supply = recommendation.supply
        HStack(spacing: 14) {
            Button(action: explain) {
            HStack(spacing: 14) {
                SupplyIcon(supply: supply, size: 36)
                    .opacity(bought ? 0.4 : 1)
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(supply.name)
                            .font(.body.weight(.medium))
                            .strikethrough(bought)
                        Spacer(minLength: 8)
                        Text(withUnit(recommendation.toBuy, supply.unit))
                            .font(.body.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(bought ? Color.secondary : Color.accentColor)
                    }
                    if bought {
                        Text("Comprado")
                            .font(.caption)
                            .foregroundStyle(Color.kiloGood)
                    } else {
                        RangeBar(fraction: recommendation.needed > 0 ? recommendation.onHand / recommendation.needed : 1)
                        if learning {
                            Text("Kilo aún aprende")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(supply.name), comprar \(withUnit(recommendation.toBuy, supply.unit)), tienes \(withUnit(recommendation.onHand, supply.unit))")
            .accessibilityHint("Explica por qué")
            .accessibilityAddTraits(.isButton)

            Button(action: toggle) {
                Image(systemName: bought ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(bought ? Color.kiloGood : Color.kiloTrack)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(bought ? "Comprado" : "Marcar como comprado")
            .sensoryFeedback(.selection, trigger: bought)
        }
    }
}

struct CoveredRow: View {
    let supplies: [SupplyInfo]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 8)], spacing: 12) {
            ForEach(supplies) { supply in
                VStack(spacing: 4) {
                    SupplyIcon(supply: supply, size: 32)
                    Text(supply.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(.vertical, 6)
    }
}
