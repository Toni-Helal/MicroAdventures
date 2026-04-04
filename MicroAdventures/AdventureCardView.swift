import SwiftUI

struct AdventureCardStyle {
    let cardBackground: Color
    let chipBackground: Color
    let doneButtonBackground: Color
    let doneButtonForeground: Color
}

struct AdventureCardView: View {
    let adventure: Adventure
    let whyText: String
    let distanceText: String?
    let style: AdventureCardStyle
    let onOpenDetails: () -> Void
    let onAnotherPick: () -> Void
    let onToggleCompleted: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Label(adventure.category.rawValue, systemImage: adventure.category.icon)
                        .font(AppFont.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(adventure.category.tintColor, in: Capsule())

                    Text(adventure.effort.rawValue)
                        .font(AppFont.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppColor.chipBackground, in: Capsule())

                    if let dist = distanceText {
                        Label(dist, systemImage: "location.fill")
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.accent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AppColor.accentSubtle, in: Capsule())
                    }
                }

                Text(adventure.title)
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(2)

                Text("Why this? \(whyText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Text(adventure.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)

                if !adventure.flavorTags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(adventure.flavorTags.prefix(3), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.secondary.opacity(0.1), in: Capsule())
                        }
                        Spacer()
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    AdventureInfoRow(icon: "bolt.fill", text: "Energy: \(adventure.recommendedEnergy.rawValue)")
                    AdventureInfoRow(icon: "clock", text: "Best time: \(adventure.bestTimeWindow.rawValue)")
                    AdventureInfoRow(icon: "flag", text: "Start: \(adventure.startPointName)")
                    AdventureInfoRow(icon: "flag.checkered", text: "End: \(adventure.endPointName)")
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Energy \(adventure.recommendedEnergy.rawValue), best time \(adventure.bestTimeWindow.rawValue), start at \(adventure.startPointName), end at \(adventure.endPointName)")

                HStack {
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(AppColor.textTertiary)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onOpenDetails()
            }

            HStack(spacing: 10) {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onAnotherPick()
                } label: {
                    Text("Reroll Today")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(style.chipBackground)
                        .foregroundStyle(.primary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Reroll today's adventure")
                .accessibilityHint("Double tap to get a different adventure suggestion")

                Spacer()

                Button {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(adventure.isCompleted ? .warning : .success)
                    onToggleCompleted()
                } label: {
                    Text(adventure.isCompleted ? "Completed" : "Done")
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(adventure.isCompleted ? AppColor.successSubtle : style.doneButtonBackground)
                        .foregroundStyle(adventure.isCompleted ? AppColor.success : style.doneButtonForeground)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(adventure.isCompleted ? "Adventure completed" : "Mark adventure as completed")
                .accessibilityHint(adventure.isCompleted ? "Double tap to mark as not completed" : "Double tap to record this adventure as done")
            }
        }
        .padding(AppSpacing.md - 2)
        .background(style.cardBackground, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .appShadow(AppShadow.card)
    }
}

private struct AdventureInfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}
