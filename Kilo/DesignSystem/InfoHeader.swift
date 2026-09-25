import SwiftUI

struct InfoHeader: View {
    let title: String
    let info: String

    @State private var showingInfo = false

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Button {
                showingInfo = true
            } label: {
                Image(systemName: "info.circle")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Más información")
            .popover(isPresented: $showingInfo, arrowEdge: .top) {
                Text(info)
                    .font(.footnote)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: 260, alignment: .leading)
                    .padding()
                    .presentationCompactAdaptation(.popover)
            }
        }
    }
}
