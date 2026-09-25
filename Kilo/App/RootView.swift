import SwiftUI

enum AppTab: Hashable {
    case today, supplies, savings, dictate
}

struct RootView: View {
    @State private var tab = AppTab.today
    @State private var dictating = false

    var body: some View {
        TabView(selection: $tab) {
            Tab("Hoy", systemImage: "sun.max.fill", value: .today) {
                NavigationStack { TodayView() }
            }
            Tab("Insumos", systemImage: "square.stack.3d.up.fill", value: .supplies) {
                NavigationStack { SuppliesView() }
            }
            Tab("Ahorro", systemImage: "chart.bar.fill", value: .savings) {
                NavigationStack { SavingsView() }
            }
            Tab("Dictar", systemImage: "mic.fill", value: .dictate, role: .search) {
                Color.clear
            }
        }
        .tabViewSearchActivation(.searchTabSelection)
        .onChange(of: tab) { previous, current in
            guard current == .dictate else { return }
            tab = previous
            dictating = true
        }
        .sheet(isPresented: $dictating) {
            DictationSheet(initial: VoiceAction.forTime(.now))
        }
    }
}
