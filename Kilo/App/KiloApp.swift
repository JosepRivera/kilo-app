import SwiftUI

@main
struct KiloApp: App {
    @State private var store = KiloStore.demo()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(\.locale, Locale(identifier: "es_PE"))
        }
    }
}
