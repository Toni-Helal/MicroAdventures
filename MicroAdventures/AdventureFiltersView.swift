import SwiftUI

struct AdventureFiltersView: View {
    @State private var draftCategories: Set<Category>
    @State private var draftEfforts: Set<Effort>
    @State private var draftEnergy: EnergyLevel
    @State private var draftWeather: WeatherCondition
    @State private var draftDuration: DurationOption

    let timeBucket: TimeBucket
    let onCancel: () -> Void
    let onApply: (Set<Category>, Set<Effort>, EnergyLevel, WeatherCondition, DurationOption) -> Void
    private let chipColumns = [GridItem(.adaptive(minimum: 96), spacing: 8)]

    init(
        selectedCategories: Set<Category>,
        selectedEfforts: Set<Effort>,
        selectedEnergy: EnergyLevel,
        selectedWeather: WeatherCondition,
        selectedDuration: DurationOption,
        timeBucket: TimeBucket,
        onCancel: @escaping () -> Void,
        onApply: @escaping (Set<Category>, Set<Effort>, EnergyLevel, WeatherCondition, DurationOption) -> Void
    ) {
        _draftCategories = State(initialValue: selectedCategories)
        _draftEfforts = State(initialValue: selectedEfforts)
        _draftEnergy = State(initialValue: selectedEnergy)
        _draftWeather = State(initialValue: selectedWeather)
        _draftDuration = State(initialValue: selectedDuration)
        self.timeBucket = timeBucket
        self.onCancel = onCancel
        self.onApply = onApply
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Categories") {
                    HStack {
                        Text("\(draftCategories.count) selected")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Select All") { draftCategories = Set(Category.allCases) }
                            .font(.caption)
                        Button("Clear") { draftCategories.removeAll() }
                            .font(.caption)
                    }

                    LazyVGrid(columns: chipColumns, alignment: .leading, spacing: 8) {
                        ForEach(Category.allCases) { category in
                            filterChip(
                                title: category.rawValue,
                                icon: category.icon,
                                isSelected: draftCategories.contains(category),
                                action: { toggleCategory(category) }
                            )
                        }
                    }
                }

                Section("Effort Level") {
                    HStack {
                        Text("\(draftEfforts.count) selected")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Select All") { draftEfforts = Set(Effort.allCases) }
                            .font(.caption)
                        Button("Clear") { draftEfforts.removeAll() }
                            .font(.caption)
                    }

                    LazyVGrid(columns: chipColumns, alignment: .leading, spacing: 8) {
                        ForEach(Effort.allCases) { effort in
                            filterChip(
                                title: effort.rawValue,
                                isSelected: draftEfforts.contains(effort),
                                action: { toggleEffort(effort) }
                            )
                        }
                    }
                }

                Section("Context") {
                    Picker("Energy", selection: $draftEnergy) {
                        ForEach(EnergyLevel.allCases) { energy in
                            Text(energy.rawValue).tag(energy)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Time Available", selection: $draftDuration) {
                        ForEach(DurationOption.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Weather", selection: $draftWeather) {
                        ForEach(WeatherCondition.allCases) { weather in
                            Text(weather.rawValue).tag(weather)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text("Time: \(timeBucket.rawValue)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Filters")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply(draftCategories, draftEfforts, draftEnergy, draftWeather, draftDuration)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func filterChip(title: String, icon: String? = nil, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Group {
                if let icon {
                    Label(title, systemImage: icon)
                } else {
                    Text(title)
                }
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .foregroundStyle(isSelected ? .white : AppColor.textPrimary)
            .background(isSelected ? AppColor.chipSelected : AppColor.chipBackground)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func toggleCategory(_ category: Category) {
        if draftCategories.contains(category) {
            draftCategories.remove(category)
        } else {
            draftCategories.insert(category)
        }
    }

    private func toggleEffort(_ effort: Effort) {
        if draftEfforts.contains(effort) {
            draftEfforts.remove(effort)
        } else {
            draftEfforts.insert(effort)
        }
    }
}
