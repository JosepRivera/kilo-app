import SwiftUI

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

struct RootView: View {
    @State private var dictating = false

    var body: some View {
        TabView {
            Tab("Hoy", systemImage: "sun.max.fill") {
                NavigationStack { TodayView() }
            }
            Tab("Insumos", systemImage: "square.stack.3d.up.fill") {
                NavigationStack { SuppliesView() }
            }
            Tab("Ahorro", systemImage: "chart.bar.fill") {
                NavigationStack { SavingsView() }
            }
        }
        .tabViewBottomAccessory {
            Button {
                dictating = true
            } label: {
                Label("Dictar \(VoiceAction.forTime(.now).title.lowercased())", systemImage: "mic.fill")
                    .frame(maxWidth: .infinity)
            }
        }
        .sheet(isPresented: $dictating) {
            DictationSheet(initial: VoiceAction.forTime(.now))
        }
    }
}
