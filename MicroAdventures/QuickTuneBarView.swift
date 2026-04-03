import SwiftUI

struct QuickTuneBarView: View {
    @Binding var duration: DurationOption
    @Binding var energy: EnergyLevel
    @Binding var prefersNearby: Bool

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(DurationOption.allCases) { option in
                    QuickTuneChip(
                        label: option.label,
                        isSelected: duration == option
                    ) { duration = option }
                    .accessibilityLabel("\(option.label) duration")
                    .accessibilityAddTraits(duration == option ? .isSelected : [])
                }

                tuneDivider

                ForEach(EnergyLevel.allCases) { level in
                    QuickTuneChip(
                        label: level.rawValue,
                        isSelected: energy == level
                    ) { energy = level }
                    .accessibilityLabel("\(level.rawValue) energy")
                    .accessibilityAddTraits(energy == level ? .isSelected : [])
                }

                tuneDivider

                QuickTuneChip(
                    label: "Nearby",
                    systemImage: "location.fill",
                    isSelected: prefersNearby
                ) { prefersNearby.toggle() }
                .accessibilityLabel("Prefer nearby adventures")
                .accessibilityAddTraits(prefersNearby ? .isSelected : [])
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }

    private var tuneDivider: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.12))
            .frame(width: 1, height: 14)
            .padding(.horizontal, 2)
    }
}

private struct QuickTuneChip: View {
    let label: String
    var systemImage: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.caption2)
                }
                Text(label)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.primary.opacity(0.22) : Color.primary.opacity(0.08))
            .foregroundStyle(.primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.12), value: isSelected)
    }
}
