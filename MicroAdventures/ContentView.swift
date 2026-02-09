//
//  ContentView.swift
//  MicroAdventures
//
//  Created by Antoun Helal on 05/02/2026.
//

import SwiftUI
import MapKit
internal import Combine

private enum TimeBucket: String {
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"
    case night = "Night"

    static func current(for date: Date) -> TimeBucket {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 6..<12:
            return .morning
        case 12..<17:
            return .afternoon
        case 17..<21:
            return .evening
        default:
            return .night
        }
    }
}

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedCategories: Set<Category> = Set(Category.allCases)
    @State private var selectedEfforts: Set<Effort> = Set(Effort.allCases)
    @State private var selectedEnergy: EnergyLevel = .medium
    @State private var selectedWeather: WeatherCondition = .clear
    @State private var selectedDuration: DurationOption = .thirty
    @State private var showingFilters = false

    @State private var adventures: [Adventure]
    @State private var currentAdventureID: UUID? = nil
    @State private var dailyPickDate: Date? = nil
    @State private var dailyPickAdventureID: UUID? = nil
    @State private var now: Date = Date()
    @State private var timeBucket: TimeBucket = TimeBucket.current(for: Date())
    @State private var daySeedValue: Int = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0

    @State private var cameraPosition: MapCameraPosition
    private let timeTicker = Timer.publish(every: 300, on: .main, in: .common).autoconnect()

    private static let storageKey = "micro_adventures_store_v1"
    private static let dailyPickDateKey = "micro_adventures_daily_pick_date_v1"
    private static let dailyPickIdKey = "micro_adventures_daily_pick_id_v1"

    init() {
        let initialAdventures = ContentView.loadStoredAdventures()
        let storedPick = ContentView.loadStoredDailyPick()
        _adventures = State(initialValue: initialAdventures)
        _dailyPickDate = State(initialValue: storedPick.date)
        _dailyPickAdventureID = State(initialValue: storedPick.id)
        let today = Calendar.current.startOfDay(for: Date())
        let initialPickId = storedPick.date.flatMap {
            Calendar.current.isDate($0, inSameDayAs: today) ? storedPick.id : nil
        }
        _currentAdventureID = State(initialValue: initialPickId)
        let start = initialAdventures.first ?? AdventureSamples.all.first!
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: start.latitude, longitude: start.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
        _cameraPosition = State(initialValue: .region(region))
    }

    private static func loadStoredDailyPick() -> (date: Date?, id: UUID?) {
        let defaults = UserDefaults.standard
        let timestamp = defaults.double(forKey: dailyPickDateKey)
        let date = timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
        let id = defaults.string(forKey: dailyPickIdKey).flatMap { UUID(uuidString: $0) }
        return (date, id)
    }

    private static func loadStoredAdventures() -> [Adventure] {
        let defaults = UserDefaults.standard
        guard let data = defaults.data(forKey: storageKey) else { return AdventureSamples.all }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let stored = try? decoder.decode([Adventure].self, from: data) else {
            return AdventureSamples.all
        }
        return mergeSamples(with: stored)
    }

    private static func mergeSamples(with stored: [Adventure]) -> [Adventure] {
        let storedById = Dictionary(uniqueKeysWithValues: stored.map { ($0.id, $0) })
        let storedIds = Set(storedById.keys)
        let sampleIds = Set(AdventureSamples.all.map { $0.id })
        if storedIds.intersection(sampleIds).isEmpty {
            return AdventureSamples.all
        }
        var merged: [Adventure] = []

        for sample in AdventureSamples.all {
            if var existing = storedById[sample.id] {
                existing.title = sample.title
                existing.description = sample.description
                existing.category = sample.category
                existing.effort = sample.effort
                existing.recommendedEnergy = sample.recommendedEnergy
                existing.bestTimeWindow = sample.bestTimeWindow
                existing.durationMinutes = sample.durationMinutes
                existing.startPointName = sample.startPointName
                existing.endPointName = sample.endPointName
                existing.locationName = sample.locationName
                existing.latitude = sample.latitude
                existing.longitude = sample.longitude
                merged.append(existing)
            } else {
                merged.append(sample)
            }
        }

        for extra in stored where !sampleIds.contains(extra.id) {
            merged.append(extra)
        }

        return merged
    }

    private struct RecommendationWeights {
        static let timeMatch = 0.35
        static let energyMatch = 0.25
        static let weatherMatch = 0.15
        static let novelty = 0.15
        static let completionPenalty = -0.40
        static let eveningLowLongPenalty = -0.30
        static let recentCompletionMultiplier = 0.2
        static let noRepeatWindowHours = 48.0
        static let pickThreshold = 0.35
    }

    private var cardBackground: Color {
        colorScheme == .dark ? Color.black.opacity(0.65) : Color.white.opacity(0.9)
    }

    private var chipBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.gray.opacity(0.15)
    }

    private var doneButtonBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.2) : Color.gray.opacity(0.25)
    }

    private var doneButtonForeground: Color {
        colorScheme == .dark ? Color.white.opacity(0.9) : Color.gray.opacity(0.9)
    }

    private var filterIconColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.9) : Color.gray.opacity(0.85)
    }

    private var pinColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.85) : Color.gray
    }

    private var filteredAdventures: [Adventure] {
        adventures.filter { adventure in
            selectedCategories.contains(adventure.category) && selectedEfforts.contains(adventure.effort)
        }
    }

    private var eligibleAdventures: [Adventure] {
        filteredAdventures.filter { adventure in
            !isRecentlyShown(adventure)
        }
    }

    private var rankedAdventures: [Adventure] {
        scoredAdventures().map { $0.adventure }
    }

    private var currentAdventure: Adventure? {
        if let id = currentAdventureID,
           let match = adventures.first(where: { $0.id == id }),
           selectedCategories.contains(match.category),
           selectedEfforts.contains(match.effort) {
            return match
        }
        return topCandidate()
    }

    private var daySeed: Int {
        daySeedValue
    }

    private func isRecentlyShown(_ adventure: Adventure) -> Bool {
        guard let lastShownAt = adventure.lastShownAt else { return false }
        return now.timeIntervalSince(lastShownAt) < RecommendationWeights.noRepeatWindowHours * 3600
    }

    private func hoursSince(_ date: Date?) -> Double? {
        guard let date else { return nil }
        return max(0, now.timeIntervalSince(date) / 3600)
    }

    private func timeScore(for adventure: Adventure) -> Double {
        let delta = adventure.durationMinutes - selectedDuration.rawValue
        if delta <= 0 { return 1.0 }
        if delta <= 15 { return 0.4 }
        return 0.0
    }

    private func energyScore(for adventure: Adventure) -> Double {
        switch selectedEnergy {
        case .low:
            return adventure.effort == .easy ? 1.0 : adventure.effort == .moderate ? 0.4 : 0.0
        case .medium:
            return adventure.effort == .moderate ? 1.0 : 0.5
        case .high:
            return adventure.effort == .hard ? 1.0 : adventure.effort == .moderate ? 0.6 : 0.2
        }
    }

    private func weatherScore(for adventure: Adventure) -> Double {
        switch selectedWeather {
        case .clear:
            return adventure.category == .water ? 1.0 : adventure.category == .nature ? 0.7 : 0.4
        case .cloudy:
            return adventure.category == .urban ? 1.0 : 0.5
        case .rain:
            return adventure.category == .urban ? 1.0 : adventure.category == .water ? 0.0 : 0.4
        }
    }

    private func noveltyScore(for adventure: Adventure) -> Double {
        guard let hours = hoursSince(adventure.lastShownAt) else { return 1.0 }
        let normalized = min(1.0, hours / RecommendationWeights.noRepeatWindowHours)
        return normalized
    }

    private func score(_ adventure: Adventure) -> Double {
        let timeValue = timeScore(for: adventure) * RecommendationWeights.timeMatch
        let energyValue = energyScore(for: adventure) * RecommendationWeights.energyMatch
        let weatherValue = weatherScore(for: adventure) * RecommendationWeights.weatherMatch
        let noveltyValue = noveltyScore(for: adventure) * RecommendationWeights.novelty

        var total = timeValue + energyValue + weatherValue + noveltyValue

        if adventure.isCompleted {
            total += RecommendationWeights.completionPenalty
        }

        if timeBucket == .evening && selectedEnergy == .low && adventure.durationMinutes >= 60 {
            total += RecommendationWeights.eveningLowLongPenalty
        }

        if let hours = hoursSince(adventure.lastCompletedAt), hours < RecommendationWeights.noRepeatWindowHours {
            total *= RecommendationWeights.recentCompletionMultiplier
        }

        return total
    }

    private func dailyJitter(_ adventure: Adventure) -> Double {
        let base = adventure.id.uuidString.unicodeScalars.reduce(0) { partial, scalar in
            (partial &* 31) &+ Int(scalar.value)
        }
        let mixed = base ^ daySeed
        let normalized = Double(abs(mixed % 1000)) / 1000.0
        return (normalized - 0.5) * 0.02
    }

    private func scoredAdventures() -> [(adventure: Adventure, score: Double)] {
        let scored = eligibleAdventures.map { adventure in
            (adventure: adventure, score: score(adventure) + dailyJitter(adventure))
        }
        return scored.sorted { $0.score > $1.score }
    }

    private func topCandidate() -> Adventure? {
        guard let top = scoredAdventures().first, top.score >= RecommendationWeights.pickThreshold else {
            return nil
        }
        return top.adventure
    }

    private func whyThis(_ adventure: Adventure) -> String {
        var reasons: [(text: String, weight: Double)] = []

        let timeContribution = timeScore(for: adventure) * RecommendationWeights.timeMatch
        if timeContribution > 0.05 {
            let timeText = adventure.durationMinutes <= selectedDuration.rawValue
                ? "fits \(selectedDuration.label)"
                : "close to \(selectedDuration.label)"
            reasons.append((timeText, timeContribution))
        }

        let energyContribution = energyScore(for: adventure) * RecommendationWeights.energyMatch
        if energyContribution > 0.05 {
            reasons.append(("matches \(selectedEnergy.rawValue.lowercased()) energy", energyContribution))
        }

        let weatherContribution = weatherScore(for: adventure) * RecommendationWeights.weatherMatch
        if weatherContribution > 0.05 {
            reasons.append(("works for \(selectedWeather.rawValue.lowercased()) weather", weatherContribution))
        }

        let noveltyContribution = noveltyScore(for: adventure) * RecommendationWeights.novelty
        if noveltyContribution > 0.05 {
            reasons.append(("fresh pick", noveltyContribution))
        }

        let sorted = reasons.sorted { $0.weight > $1.weight }
        let top = sorted.prefix(2).map { $0.text }
        if top.isEmpty {
            return "best match for your filters"
        }
        return top.joined(separator: " • ")
    }

    private func infoRow(icon: String, text: String) -> some View {
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

    private func focusOn(_ adventure: Adventure) {
        cameraPosition = .region(MKCoordinateRegion(
            center: adventure.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        ))
    }

    private func ensureDailyPick(forceReselect: Bool) {
        let referenceDate = Date()
        now = referenceDate
        let newDaySeed = Calendar.current.ordinality(of: .day, in: .year, for: referenceDate) ?? daySeedValue
        if newDaySeed != daySeedValue {
            daySeedValue = newDaySeed
        }
        let today = Calendar.current.startOfDay(for: referenceDate)
        let isSameDay = dailyPickDate.map { Calendar.current.isDate($0, inSameDayAs: today) } ?? false
        let hasValidPick = dailyPickAdventureID.flatMap { id in
            adventures.first(where: { $0.id == id })
        } != nil

        if !forceReselect, isSameDay, hasValidPick {
            currentAdventureID = dailyPickAdventureID
            return
        }

        let pick = topCandidate()
        dailyPickDate = today
        dailyPickAdventureID = pick?.id
        currentAdventureID = pick?.id
        if let pick { markSeen(pick) }
        persistDailyPick()
        if let pick { focusOn(pick) }
    }

    private func toggleCompleted(for adventure: Adventure) {
        guard let index = adventures.firstIndex(where: { $0.id == adventure.id }) else { return }
        adventures[index].isCompleted.toggle()
        adventures[index].lastCompletedAt = adventures[index].isCompleted ? now : nil
        persistAdventures()
    }

    private func markSeen(_ adventure: Adventure) {
        guard let index = adventures.firstIndex(where: { $0.id == adventure.id }) else { return }
        adventures[index].lastShownAt = now
        persistAdventures()
    }

    private func persistAdventures() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(adventures) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    private func persistDailyPick() {
        let defaults = UserDefaults.standard
        if let date = dailyPickDate {
            defaults.set(date.timeIntervalSince1970, forKey: Self.dailyPickDateKey)
        } else {
            defaults.removeObject(forKey: Self.dailyPickDateKey)
        }
        if let id = dailyPickAdventureID {
            defaults.set(id.uuidString, forKey: Self.dailyPickIdKey)
        } else {
            defaults.removeObject(forKey: Self.dailyPickIdKey)
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $cameraPosition) {
                if let adventure = currentAdventure {
                    Annotation(adventure.locationName, coordinate: adventure.coordinate) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title2)
                            .foregroundStyle(pinColor)
                            .shadow(radius: 2)
                    }
                }
            }
        }
        .safeAreaInset(edge: .top) {
            VStack(spacing: 12) {
                HStack {
                    Text("Micro Adventures")
                        .font(.title2)
                        .bold()
                        .foregroundStyle(.primary)
                    Spacer()
                    Button {
                        showingFilters = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .font(.title2)
                            .foregroundStyle(filterIconColor)
                    }
                    .accessibilityLabel("Filter adventures")
                }
                .padding(.horizontal)

                if let adventure = currentAdventure {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Text(adventure.category.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(chipBackground)
                                .clipShape(Capsule())

                            Text(adventure.effort.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(chipBackground)
                                .clipShape(Capsule())
                        }

                    Text(adventure.title)
                        .font(.headline)
                        .bold()
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Text("Why this? \(whyThis(adventure))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    Text(adventure.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)

                        VStack(alignment: .leading, spacing: 4) {
                            infoRow(icon: "bolt.fill", text: "Energy: \(adventure.recommendedEnergy.rawValue)")
                            infoRow(icon: "clock", text: "Best time: \(adventure.bestTimeWindow.rawValue)")
                            infoRow(icon: "flag", text: "Start: \(adventure.startPointName)")
                            infoRow(icon: "flag.checkered", text: "End: \(adventure.endPointName)")
                        }

                        HStack {
                            Spacer()
                            Button {
                                toggleCompleted(for: adventure)
                            } label: {
                                Text(adventure.isCompleted ? "Completed" : "Done")
                                    .font(.subheadline)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(adventure.isCompleted ? Color.green.opacity(0.25) : doneButtonBackground)
                                    .foregroundStyle(doneButtonForeground)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(adventure.isCompleted ? "Adventure completed" : "Mark adventure as completed")
                        }
                    }
                    .padding(14)
                    .background(cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                    .padding(.horizontal)
                    .padding(.top, 50)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No pick for today.")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("No recommendation fits your current filters. Try relaxing constraints or check back tomorrow.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("Reset Filters") {
                            selectedCategories = Set(Category.allCases)
                            selectedEfforts = Set(Effort.allCases)
                            selectedEnergy = .medium
                            selectedWeather = .clear
                            selectedDuration = .thirty
                            ensureDailyPick(forceReselect: true)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(14)
                    .background(cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                    .padding(.horizontal)
                    .padding(.top, 50)
                }
            }
            .padding(.top, 120)
            .padding(.bottom, 6)
        }
        .mapStyle(.standard)
        .ignoresSafeArea()
        .onAppear { ensureDailyPick(forceReselect: false) }
        .onReceive(timeTicker) { date in
            now = date
            let newDaySeed = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? daySeedValue
            if newDaySeed != daySeedValue {
                daySeedValue = newDaySeed
                ensureDailyPick(forceReselect: true)
            }
            let bucket = TimeBucket.current(for: date)
            if bucket != timeBucket {
                timeBucket = bucket
            }
        }
        .onChange(of: selectedCategories) { ensureDailyPick(forceReselect: true) }
        .onChange(of: selectedEfforts) { ensureDailyPick(forceReselect: true) }
        .onChange(of: selectedEnergy) { ensureDailyPick(forceReselect: true) }
        .onChange(of: selectedWeather) { ensureDailyPick(forceReselect: true) }
        .onChange(of: selectedDuration) { ensureDailyPick(forceReselect: true) }
        .sheet(isPresented: $showingFilters) {
            NavigationStack {
                Form {
                    Section("Categories") {
                        HStack {
                            Button("Select All") { selectedCategories = Set(Category.allCases) }
                            Spacer()
                            Button("Clear") { selectedCategories.removeAll() }
                        }
                        ForEach(Category.allCases) { category in
                            Toggle(category.rawValue, isOn: Binding(
                                get: { selectedCategories.contains(category) },
                                set: { isOn in
                                    if isOn { selectedCategories.insert(category) } else { selectedCategories.remove(category) }
                                }
                            ))
                        }
                    }
                    Section("Effort Level") {
                        HStack {
                            Button("Select All") { selectedEfforts = Set(Effort.allCases) }
                            Spacer()
                            Button("Clear") { selectedEfforts.removeAll() }
                        }
                        ForEach(Effort.allCases) { effort in
                            Toggle(effort.rawValue, isOn: Binding(
                                get: { selectedEfforts.contains(effort) },
                                set: { isOn in
                                    if isOn { selectedEfforts.insert(effort) } else { selectedEfforts.remove(effort) }
                                }
                            ))
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
                        Button("Close") { showingFilters = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Apply") { showingFilters = false }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
