import SwiftUI

struct NoPickCardView: View {
    let cardBackground: Color
    let title: String
    let message: String
    var showResetButton: Bool = true
    let onResetFilters: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if showResetButton {
                Button("Reset Some Filters") {
                    onResetFilters()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(14)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
}
