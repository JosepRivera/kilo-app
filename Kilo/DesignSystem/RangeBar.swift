import SwiftUI

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
