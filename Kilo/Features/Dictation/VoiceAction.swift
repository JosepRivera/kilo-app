import Foundation

enum VoiceAction: String, CaseIterable, Identifiable {
    case stockClose
    case purchase

    var id: Self { self }

    var title: String {
        switch self {
        case .stockClose: "Cierre de hoy"
        case .purchase: "Compra"
        }
    }

    static func forTime(_ date: Date) -> VoiceAction {
        let hour = Calendar.current.component(.hour, from: date)
        return hour >= 17 || hour < 6 ? .stockClose : .purchase
    }
}
