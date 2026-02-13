import SwiftUI

struct ContentHeaderView: View {
    let actionColor: Color
    let onCenterMap: () -> Void
    let onOpenFilters: () -> Void

    var body: some View {
        HStack {
            Text("Micro Adventures")
                .font(.title2)
                .bold()
                .foregroundStyle(.primary)

            Spacer()

            Button {
                onCenterMap()
            } label: {
                Image(systemName: "location.circle.fill")
                    .font(.title2)
                    .foregroundStyle(actionColor)
            }
            .accessibilityLabel("Center map on my location")

            Button {
                onOpenFilters()
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    .font(.title2)
                    .foregroundStyle(actionColor)
            }
            .accessibilityLabel("Filter adventures")
        }
        .padding(.horizontal)
        .padding(.top, 6)
    }
}
