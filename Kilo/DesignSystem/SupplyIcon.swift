import SwiftUI

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
