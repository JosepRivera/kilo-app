import SwiftUI

struct PurchaseLineRow: View {
    @Binding var line: PurchaseLineDraft
    let engine: Engine
    let openEditor: (_ focusPrice: Bool) -> Void
    let creatingSupply: () -> Void
    let remove: () -> Void

    var body: some View {
        switch line.kind {
        case .resolved(let supply, _):
            if line.quantityQuestion != nil {
                questionRow(supply)
            } else {
                resolvedRow(supply)
            }
        case .ambiguous(let spoken, let candidates):
            ambiguousRow(spoken: spoken, candidates: candidates)
        case .unknown(let spoken):
            unknownRow(spoken)
        }
    }

    @ViewBuilder
    private func resolvedRow(_ supply: SupplyInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                openEditor(false)
            } label: {
                HStack(spacing: 14) {
                    SupplyIcon(supply: supply, size: 36)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(supply.name).font(.headline)
                        Text(summary(supply))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if let flag = line.priceFlag(engine), !line.priceConfirmed {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Revisar", systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.kiloAlert)
                    Text("La \(supply.name.lowercased()) salió a \(money(flag.unitPrice)) por \(supply.unit); normalmente la pagas a \(money(flag.usual)). ¿Es correcto?")
                        .font(.footnote)
                    HStack {
                        Button("Sí, es correcto") { line.priceConfirmed = true }
                            .buttonStyle(.bordered)
                        Button("Corregir") { openEditor(true) }
                            .buttonStyle(.bordered)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func summary(_ supply: SupplyInfo) -> String {
        "\(withUnit(line.quantity, supply.unit)) · \(soles(line.cost)) · vence \(shortDate(line.expiresOn))"
    }

    @ViewBuilder
    private func questionRow(_ supply: SupplyInfo) -> some View {
        HStack(spacing: 14) {
            SupplyIcon(supply: supply, size: 36)
            VStack(alignment: .leading, spacing: 6) {
                Text(supply.name).font(.body.weight(.medium))
                Text(line.quantityQuestion ?? "")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                HStack {
                    TextField("Cantidad", value: $line.quantity, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 90)
                        .onSubmit { confirmQuantity(supply) }
                    Text(supply.unit).foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                    Button("Listo") { confirmQuantity(supply) }
                        .buttonStyle(.bordered)
                        .disabled(line.quantity <= 0)
                }
                if line.quantityPhrase != nil {
                    Text("Kilo lo recordará para la próxima vez.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func ambiguousRow(spoken: String, candidates: [SupplyInfo]) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "questionmark.circle.fill")
                .font(.title2)
                .foregroundStyle(Color.kiloAlert)
            VStack(alignment: .leading, spacing: 6) {
                Text("¿Cuál \(spoken)?").font(.body.weight(.medium))
                Menu {
                    ForEach(candidates) { candidate in
                        Button(candidate.name) { resolve(to: candidate) }
                    }
                } label: {
                    Label("Elegir", systemImage: "chevron.up.chevron.down")
                }
            }
        }
    }

    @ViewBuilder
    private func unknownRow(_ spoken: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "questionmark.circle.fill")
                .font(.title2)
                .foregroundStyle(Color.kiloAlert)
            VStack(alignment: .leading, spacing: 6) {
                Text("\(spoken.prefix(1).uppercased() + spoken.dropFirst()) no está en tu catálogo")
                    .font(.body.weight(.medium))
                HStack {
                    Button("Crear insumo", action: creatingSupply)
                        .buttonStyle(.bordered)
                    Button("Quitar", role: .destructive, action: remove)
                }
            }
        }
    }

    private func confirmQuantity(_ supply: SupplyInfo) {
        guard line.quantity > 0 else { return }
        line.cost = line.quantity * supply.referencePrice
        line.quantityQuestion = nil
    }

    private func resolve(to candidate: SupplyInfo) {
        let isNew = !engine.data.supplies.contains { $0.id == candidate.id }
        line.kind = .resolved(candidate, isNew: isNew)
        line.cost = line.quantity * candidate.referencePrice
        line.expiresOn = addDays(engine.today, candidate.shelfLifeDays)
    }
}
