import SwiftUI

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
