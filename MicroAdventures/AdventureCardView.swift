import SwiftUI
import UIKit

struct AdventureCardStyle {
    let cardBackground: Color
    let chipBackground: Color
    let doneButtonBackground: Color
    let doneButtonForeground: Color
}

struct AdventureCardView: View {
    let adventure: Adventure
    let whyText: String
    let style: AdventureCardStyle
    let onAnotherPick: () -> Void
    let onToggleCompleted: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                infoChip(title: adventure.category.rawValue, systemIcon: adventure.category.systemIcon)

                infoChip(title: adventure.effort.rawValue)
            }

            Text(adventure.title)
                .font(.headline)
                .bold()
                .foregroundStyle(.primary)
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
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Array(adventure.flavorTags.prefix(3)), id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.secondary.opacity(0.14))
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                AdventureInfoRow(icon: "bolt.fill", text: "Energy: \(adventure.recommendedEnergy.rawValue)")
                AdventureInfoRow(icon: "clock", text: "Best time: \(adventure.bestTimeWindow.rawValue)")
                AdventureInfoRow(icon: "flag", text: "Start: \(adventure.startPointName)")
                AdventureInfoRow(icon: "flag.checkered", text: "End: \(adventure.endPointName)")
            }

            HStack(spacing: 10) {
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
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

                Spacer()

                Button {
                    if !adventure.isCompleted {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    }
                    onToggleCompleted()
                } label: {
                    Text(adventure.isCompleted ? "Completed" : "Done")
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(adventure.isCompleted ? Color.green.opacity(0.25) : style.doneButtonBackground)
                        .foregroundStyle(style.doneButtonForeground)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(adventure.isCompleted ? "Adventure completed" : "Mark adventure as completed")
            }
        }
        .padding(14)
        .background(style.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }

    @ViewBuilder
    private func infoChip(title: String, systemIcon: String? = nil) -> some View {
        HStack(spacing: 6) {
            if let systemIcon {
                Image(systemName: systemIcon)
                    .font(.caption)
            }
            Text(title)
                .font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(style.chipBackground)
        .clipShape(Capsule())
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
