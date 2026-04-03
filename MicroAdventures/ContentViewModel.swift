 internal import Combine
import CoreLocation
import Foundation

enum TimeBucket: String {
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

final class ContentViewModel: ObservableObject {
    @Published var selectedCategories: Set<Category> = Set(Category.allCases) {
        didSet { handleContextChanged() }
    }
    @Published var selectedEfforts: Set<Effort> = Set(Effort.allCases) {
        didSet { handleContextChanged() }
    }
    @Published var selectedEnergy: EnergyLevel = .medium {
        didSet { handleContextChanged() }
    }
    @Published var selectedWeather: WeatherCondition = .clear {
        didSet { handleContextChanged() }
    }
    @Published var selectedDuration: DurationOption = .thirty {
        didSet { handleContextChanged() }
    }
    @Published var showingFilters = false

    @Published private(set) var timeBucket: TimeBucket = TimeBucket.current(for: Date())
    @Published private(set) var currentAdventureID: UUID?
    @Published private(set) var adventures: [Adventure]

    private var dailyPickDate: Date?
    private var dailyPickAdventureID: UUID?
    private var now: Date = Date()
    private var daySeedValue: Int = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
    private var isBootstrapping = true
    private var isBatchUpdatingContext = false
    private var userCoordinate: CLLocationCoordinate2D?
    private var hasDeferredDailyReselect = false

    private static let storageKey = "micro_adventures_store_v1"
    private static let dailyPickDateKey = "micro_adventures_daily_pick_date_v1"
    private static let dailyPickIdKey = "micro_adventures_daily_pick_id_v1"
    private static let filtersCategoriesKey = "micro_adventures_filters_categories_v1"
    private static let filtersEffortsKey = "micro_adventures_filters_efforts_v1"
    private static let filtersEnergyKey = "micro_adventures_filters_energy_v1"
    private static let filtersWeatherKey = "micro_adventures_filters_weather_v1"
    private static let filtersDurationKey = "micro_adventures_filters_duration_v1"

    init() {
        let initialAdventures = Self.loadStoredAdventures()
        adventures = initialAdventures

        let storedFilters = Self.loadStoredFilters()
        selectedCategories = storedFilters.categories
        selectedEfforts = storedFilters.efforts
        selectedEnergy = storedFilters.energy
        selectedWeather = storedFilters.weather
        selectedDuration = storedFilters.duration

        let storedPick = Self.loadStoredDailyPick()
        dailyPickDate = storedPick.date
        dailyPickAdventureID = storedPick.id

        let today = Calendar.current.startOfDay(for: Date())
        currentAdventureID = storedPick.date.flatMap {
            Calendar.current.isDate($0, inSameDayAs: today) ? storedPick.id : nil
        }
        isBootstrapping = false
    }

    var mapSeedAdventure: Adventure {
        adventures.first ?? AdventureSamples.all.first!
    }

    var currentAdventure: Adventure? {
        if let id = currentAdventureID,
           let match = adventures.first(where: { $0.id == id }),
           selectedCategories.contains(match.category),
           selectedEfforts.contains(match.effort) {
            return match
        }
        return topCandidate()
    }

    var activeFilterCount: Int {
        let removedCategories = max(0, Category.allCases.count - selectedCategories.count)
        let removedEfforts = max(0, Effort.allCases.count - selectedEfforts.count)
        return removedCategories + removedEfforts
    }

    func showFilters() {
        showingFilters = true
    }

    func hideFilters() {
        showingFilters = false
        if hasDeferredDailyReselect {
            hasDeferredDailyReselect = false
            ensureDailyPick(forceReselect: true)
        }
    }

    func applyFilters(
        categories: Set<Category>,
        efforts: Set<Effort>,
        energy: EnergyLevel,
        weather: WeatherCondition,
        duration: DurationOption
    ) {
        performBatchContextUpdate {
            selectedCategories = categories
            selectedEfforts = efforts
            selectedEnergy = energy
            selectedWeather = weather
            selectedDuration = duration
        }
        persistFilters()
    }

    // Explicit product behavior: rerolling replaces today's official pick.
    func rerollTodayPick() {
        now = Date()
        var excludedIDs: Set<UUID> = []
        if let currentAdventureID {
            excludedIDs.insert(currentAdventureID)
        }
        guard let next = topCandidate(excluding: excludedIDs) else { return }
        currentAdventureID = next.id
        dailyPickDate = Calendar.current.startOfDay(for: now)
        dailyPickAdventureID = next.id
        markSeen(next)
        persistAdventures()
        persistDailyPick()
    }

    func updateUserCoordinate(_ coordinate: CLLocationCoordinate2D) {
        if let current = userCoordinate {
            let moved = CLLocation(latitude: current.latitude, longitude: current.longitude)
                .distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
            if moved < 100 {
                return
            }
        }
        userCoordinate = coordinate
    }

    func refreshTime(_ date: Date) {
        now = date
        let newDaySeed = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? daySeedValue
        if newDaySeed != daySeedValue {
            daySeedValue = newDaySeed
            if showingFilters {
                hasDeferredDailyReselect = true
            } else {
                ensureDailyPick(forceReselect: true)
            }
        }

        let bucket = TimeBucket.current(for: date)
        if bucket != timeBucket {
            timeBucket = bucket
        }
    }

    func ensureDailyPick(forceReselect: Bool) {
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
        if let pick {
            markSeen(pick)
        }
        persistAdventures()
        persistDailyPick()
    }

    func toggleCompleted(for adventure: Adventure) {
        guard let index = adventures.firstIndex(where: { $0.id == adventure.id }) else { return }
        adventures[index].isCompleted.toggle()
        adventures[index].lastCompletedAt = adventures[index].isCompleted ? now : nil
        persistAdventures()
    }

    func resetFilters() {
        performBatchContextUpdate {
            selectedCategories = Set(Category.allCases)
            selectedEfforts = Set(Effort.allCases)
            selectedEnergy = .medium
            selectedWeather = .clear
            selectedDuration = .thirty
        }
        persistFilters()
    }

    func whyThisText(for adventure: Adventure) -> String {
        let timeContribution = timeScore(for: adventure) * RecommendationWeights.timeMatch
        let energyContribution = energyScore(for: adventure) * RecommendationWeights.energyMatch
        let weatherContribution = weatherScore(for: adventure) * RecommendationWeights.weatherMatch
        let noveltyContribution = noveltyScore(for: adventure) * RecommendationWeights.novelty
        let distanceContribution = distanceScore(for: adventure) * RecommendationWeights.distanceMatch

        let strongThreshold = 0.05
        var candidates: [WhyReason] = []

        if timeContribution > strongThreshold {
            let sentence = adventure.durationMinutes <= selectedDuration.rawValue
                ? "Fits your \(selectedDuration.label) window without rushing."
                : "Close to your \(selectedDuration.label) window and still manageable."
            candidates.append(WhyReason(
                kind: .time,
                score: timeContribution,
                clarityPriority: 3,
                sentence: sentence
            ))
        }

        if energyContribution > strongThreshold {
            candidates.append(WhyReason(
                kind: .energy,
                score: energyContribution,
                clarityPriority: 2,
                sentence: "Matches your \(selectedEnergy.rawValue.lowercased())-energy pace right now."
            ))
        }

        if weatherContribution > strongThreshold {
            candidates.append(WhyReason(
                kind: .weather,
                score: weatherContribution,
                clarityPriority: 1,
                sentence: "Works well for \(selectedWeather.rawValue.lowercased()) weather now."
            ))
        }

        if noveltyContribution > strongThreshold {
            candidates.append(WhyReason(
                kind: .novelty,
                score: noveltyContribution,
                clarityPriority: 0,
                sentence: "You have not seen this pick recently."
            ))
        }

        if distanceContribution > strongThreshold {
            candidates.append(WhyReason(
                kind: .distance,
                score: distanceContribution,
                clarityPriority: 4,
                sentence: distanceReason(for: adventure)
            ))
        }

        guard !candidates.isEmpty else {
            return "Best match for your current context."
        }

        let tieEpsilon = 0.02
        let maxScore = candidates.map(\.score).max() ?? 0
        let timeMustBeIncluded = candidates.contains {
            $0.kind == .time && $0.score >= (maxScore - tieEpsilon)
        }

        let sorted = candidates.sorted { lhs, rhs in
            let diff = lhs.score - rhs.score
            if abs(diff) <= tieEpsilon {
                return lhs.clarityPriority > rhs.clarityPriority
            }
            return diff > 0
        }

        var selected: [WhyReason] = []
        if timeMustBeIncluded, let timeReason = sorted.first(where: { $0.kind == .time }) {
            selected.append(timeReason)
        }

        for candidate in sorted {
            if selected.contains(where: { $0.kind == candidate.kind }) {
                continue
            }
            selected.append(candidate)
            if selected.count == 2 {
                break
            }
        }

        if selected.count == 1 {
            return selected[0].sentence
        }
        return "\(selected[0].sentence) • \(selected[1].sentence)"
    }

    private struct RecommendationWeights {
        static let timeMatch = 0.30
        static let energyMatch = 0.25
        static let weatherMatch = 0.15
        static let novelty = 0.15
        static let distanceMatch = 0.15
        static let completionPenalty = -0.40
        static let eveningLowLongPenalty = -0.30
        static let recentCompletionMultiplier = 0.2
        static let noRepeatWindowHours = 48.0
        static let pickThreshold = 0.35
    }

    private enum WhyReasonKind {
        case time
        case energy
        case weather
        case novelty
        case distance
    }

    private struct WhyReason {
        let kind: WhyReasonKind
        let score: Double
        let clarityPriority: Int
        let sentence: String
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

    private var daySeed: Int {
        daySeedValue
    }

    private func handleContextChanged() {
        guard !isBootstrapping, !isBatchUpdatingContext else { return }
        ensureDailyPick(forceReselect: true)
    }

    private func performBatchContextUpdate(_ updates: () -> Void) {
        isBatchUpdatingContext = true
        updates()
        isBatchUpdatingContext = false
        handleContextChanged()
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

    private func distanceInKilometers(to adventure: Adventure) -> Double? {
        guard let userCoordinate else { return nil }
        let userLocation = CLLocation(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)
        let destination = CLLocation(latitude: adventure.latitude, longitude: adventure.longitude)
        return userLocation.distance(from: destination) / 1000
    }

    private func distanceScore(for adventure: Adventure) -> Double {
        guard let distance = distanceInKilometers(to: adventure) else { return 0.6 }
        switch distance {
        case ..<2:
            return 1.0
        case ..<5:
            return 0.75
        case ..<10:
            return 0.45
        default:
            return 0.2
        }
    }

    private func distanceReason(for adventure: Adventure) -> String {
        guard let distance = distanceInKilometers(to: adventure) else {
            return "Practical distance for a quick outing."
        }
        let formatted = String(format: "%.1f", distance)
        return "\(formatted) km away, so it is easy to start quickly."
    }

    private func score(_ adventure: Adventure) -> Double {
        let timeValue = timeScore(for: adventure) * RecommendationWeights.timeMatch
        let energyValue = energyScore(for: adventure) * RecommendationWeights.energyMatch
        let weatherValue = weatherScore(for: adventure) * RecommendationWeights.weatherMatch
        let noveltyValue = noveltyScore(for: adventure) * RecommendationWeights.novelty
        let distanceValue = distanceScore(for: adventure) * RecommendationWeights.distanceMatch

        var total = timeValue + energyValue + weatherValue + noveltyValue + distanceValue

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

    private func topCandidate(excluding excludedIDs: Set<UUID>) -> Adventure? {
        let candidate = scoredAdventures().first { !excludedIDs.contains($0.adventure.id) }
        guard let candidate, candidate.score >= RecommendationWeights.pickThreshold else {
            return nil
        }
        return candidate.adventure
    }

    private func markSeen(_ adventure: Adventure) {
        guard let index = adventures.firstIndex(where: { $0.id == adventure.id }) else { return }
        adventures[index].lastShownAt = now
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

    private func persistFilters() {
        let defaults = UserDefaults.standard
        defaults.set(selectedCategories.map(\.rawValue), forKey: Self.filtersCategoriesKey)
        defaults.set(selectedEfforts.map(\.rawValue), forKey: Self.filtersEffortsKey)
        defaults.set(selectedEnergy.rawValue, forKey: Self.filtersEnergyKey)
        defaults.set(selectedWeather.rawValue, forKey: Self.filtersWeatherKey)
        defaults.set(selectedDuration.rawValue, forKey: Self.filtersDurationKey)
    }

    private static func loadStoredFilters() -> (
        categories: Set<Category>,
        efforts: Set<Effort>,
        energy: EnergyLevel,
        weather: WeatherCondition,
        duration: DurationOption
    ) {
        let defaults = UserDefaults.standard

        let defaultCategories = Set(Category.allCases)
        let storedCategoryValues = defaults.array(forKey: filtersCategoriesKey) as? [String]
        let storedCategories = Set((storedCategoryValues ?? []).compactMap(Category.init(rawValue:)))
        let categories = storedCategoryValues == nil ? defaultCategories : storedCategories

        let defaultEfforts = Set(Effort.allCases)
        let storedEffortValues = defaults.array(forKey: filtersEffortsKey) as? [String]
        let storedEfforts = Set((storedEffortValues ?? []).compactMap(Effort.init(rawValue:)))
        let efforts = storedEffortValues == nil ? defaultEfforts : storedEfforts

        let energy = defaults.string(forKey: filtersEnergyKey).flatMap(EnergyLevel.init(rawValue:)) ?? .medium
        let weather = defaults.string(forKey: filtersWeatherKey).flatMap(WeatherCondition.init(rawValue:)) ?? .clear

        let storedDurationRaw = defaults.object(forKey: filtersDurationKey) as? Int
        let duration = storedDurationRaw.flatMap(DurationOption.init(rawValue:)) ?? .thirty

        return (
            categories: categories,
            efforts: efforts,
            energy: energy,
            weather: weather,
            duration: duration
        )
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
                existing.decisionTags = sample.decisionTags
                existing.flavorTags = sample.flavorTags
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
}
