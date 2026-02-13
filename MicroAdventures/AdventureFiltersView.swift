import SwiftUI

struct AdventureFiltersView: View {
    @Binding var selectedCategories: Set<Category>
    @Binding var selectedEfforts: Set<Effort>
    @Binding var selectedEnergy: EnergyLevel
    @Binding var selectedWeather: WeatherCondition
    @Binding var selectedDuration: DurationOption

    let timeBucket: TimeBucket
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Categories") {
                    HStack {
                        Button("Select All") { selectedCategories = Set(Category.allCases) }
                        Spacer()
                        Button("Clear") { selectedCategories.removeAll() }
                    }

                    ForEach(Category.allCases) { category in
                        Toggle(category.rawValue, isOn: categoryBinding(for: category))
                    }
                }

                Section("Effort Level") {
                    HStack {
                        Button("Select All") { selectedEfforts = Set(Effort.allCases) }
                        Spacer()
                        Button("Clear") { selectedEfforts.removeAll() }
                    }

                    ForEach(Effort.allCases) { effort in
                        Toggle(effort.rawValue, isOn: effortBinding(for: effort))
                    }
                }

                Section("Context") {
                    Picker("Energy", selection: $selectedEnergy) {
                        ForEach(EnergyLevel.allCases) { energy in
                            Text(energy.rawValue).tag(energy)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Time Available", selection: $selectedDuration) {
                        ForEach(DurationOption.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Weather", selection: $selectedWeather) {
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
                    Button("Close") { onClose() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") { onClose() }
                }
            }
        }
    }

    private func categoryBinding(for category: Category) -> Binding<Bool> {
        Binding(
            get: { selectedCategories.contains(category) },
            set: { isOn in
                if isOn {
                    selectedCategories.insert(category)
                } else {
                    selectedCategories.remove(category)
                }
            }
        )
    }

    private func effortBinding(for effort: Effort) -> Binding<Bool> {
        Binding(
            get: { selectedEfforts.contains(effort) },
            set: { isOn in
                if isOn {
                    selectedEfforts.insert(effort)
                } else {
                    selectedEfforts.remove(effort)
                }
            }
        )
    }
}
