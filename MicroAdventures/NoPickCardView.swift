import SwiftUI

struct NoPickCardView: View {
    let cardBackground: Color
    let onResetFilters: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No pick for today.")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("No recommendation fits your current filters. Try relaxing constraints or check back tomorrow.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Reset Filters") {
                onResetFilters()
            }
            .buttonStyle(.bordered)
        }
        .padding(14)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
}
