import SwiftUI

struct CompletionCelebrationView: View {
    let currentStreak: Int
    let longestStreak: Int
    let onDismiss: () -> Void

    private var streakTitle: String {
        currentStreak == 1 ? "1 day streak" : "\(currentStreak) day streak"
    }

    private var milestoneMessage: String {
        switch currentStreak {
        case 30...:
            return "30 days straight. A full month locked in."
        case 14...:
            return "14 days straight. Two full weeks of momentum."
        case 7...:
            return "7 days straight. One full week on the board."
        case 3...:
            return "3 days straight. The routine is taking hold."
        default:
            return "Today counts. Come back tomorrow to keep the streak alive."
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                Label(streakTitle, systemImage: "flame.fill")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer()

                Button("Close", action: onDismiss)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(milestoneMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                streakStat(title: "Current", value: "\(currentStreak)")
                streakStat(title: "Best", value: "\(longestStreak)")
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 10, y: 6)
    }

    @ViewBuilder
    private func streakStat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
