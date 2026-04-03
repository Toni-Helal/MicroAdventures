import SwiftUI

struct ContentHeaderView: View {
    let actionColor: Color
    let activeFilterCount: Int
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
                    .overlay(alignment: .topTrailing) {
                        if activeFilterCount > 0 {
                            Text("\(activeFilterCount)")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(3)
                                .background(Color.red, in: Circle())
                                .offset(x: 6, y: -6)
                        }
                    }
            }
            .accessibilityLabel(
                activeFilterCount > 0
                    ? "Filter adventures, \(activeFilterCount) active filter\(activeFilterCount == 1 ? "" : "s")"
                    : "Filter adventures"
            )
        }
        .padding(.horizontal)
        .padding(.top, 6)
    }
}
