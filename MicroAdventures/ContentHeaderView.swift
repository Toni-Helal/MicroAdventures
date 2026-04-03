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
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(5)
                                .background(Color.red, in: Circle())
                                .offset(x: 10, y: -10)
                        }
                    }
            }
            .accessibilityLabel("Filter adventures")
            .accessibilityValue(activeFilterCount > 0 ? "\(activeFilterCount) active filters" : "No active filters")
        }
        .padding(.horizontal)
        .padding(.top, 6)
    }
}
