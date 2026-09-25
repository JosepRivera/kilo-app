import SwiftUI
import UIKit

extension Color {
    private static func dynamic(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) })
    }

    static let kiloGround = dynamic(0xEAF0F7, 0x0B1422)
    static let kiloModule = dynamic(0xFFFFFF, 0x16233A)
    static let kiloTrack = dynamic(0xDCE3EC, 0x24334D)
    static let kiloAlertGround = dynamic(0xFDECEC, 0x3A1A1F)
    static let kiloAlert = dynamic(0xB42318, 0xFF8A80)
    static let kiloGood = dynamic(0x1E7F46, 0x4ADE80)
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

struct KiloScreen: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(Color.kiloGround)
    }
}

extension View {
    func kiloScreen() -> some View { modifier(KiloScreen()) }
}

struct SupplyIcon: View {
    let supply: SupplyInfo
    var size: CGFloat = 32

    var body: some View {
        Image(supply.assetName)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

struct RangeBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { geo in
            let x = geo.size.width * min(max(fraction, 0), 1)
            ZStack(alignment: .leading) {
                Capsule().fill(Color.kiloTrack)
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: max(geo.size.width - x, 0))
                    .offset(x: x)
                Circle()
                    .fill(Color.primary)
                    .frame(width: 8, height: 8)
                    .offset(x: min(max(x - 4, 0), geo.size.width - 8))
            }
        }
        .frame(height: 6)
        .accessibilityHidden(true)
    }
}

func isCountUnit(_ unit: String) -> Bool { unit != "kg" && unit != "litros" }

func formatQuantity(_ value: Double) -> String {
    value.formatted(.number.precision(.fractionLength(0...1)).locale(Locale(identifier: "es_PE")))
}

func withUnit(_ value: Double, _ unit: String) -> String {
    let shown = isCountUnit(unit) ? value.rounded() : value
    let singular = shown == 1 && unit.hasSuffix("s") ? String(unit.dropLast()) : unit
    let label = singular == "unidade" ? "unidad" : singular
    return "\(formatQuantity(shown)) \(label)"
}

func soles(_ value: Double) -> String {
    "S/\(value.formatted(.number.precision(.fractionLength(0)).locale(Locale(identifier: "es_PE"))))"
}

func money(_ value: Double) -> String {
    "S/\(value.formatted(.number.precision(.fractionLength(2)).locale(Locale(identifier: "es_PE"))))"
}

func expiryText(_ days: Int) -> String {
    switch days {
    case ..<0: "venció"
    case 0: "vence hoy"
    case 1: "vence mañana"
    default: "vence en \(days) días"
    }
}

let weekdayShort = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"]

let weekdayLong = ["lunes", "martes", "miércoles", "jueves", "viernes", "sábado", "domingo"]
