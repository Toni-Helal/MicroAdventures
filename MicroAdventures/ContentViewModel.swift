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

enum FallbackTier {
    case exact
    case nearMatch
    case bestAvailable
}

struct RecommendationResult {
    let adventure: Adventure
    let tier: FallbackTier
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
    @Published private(set) var currentTier: FallbackTier?
    @Published private(set) var adventures: [Adventure]

    private var dailyPickDate: Date?
    private var dailyPickAdventureID: UUID?
    private var dailyPickLocationAwareDate: Date?
    private var now: Date = Date()
    private var daySeedValue: Int = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
    private var isBootstrapping = true
    private var isBatchUpdatingContext = false
    private var userCoordinate: CLLocationCoordinate2D?
    private var hasDeferredDailyReselect = false

    private static let storageKey = "micro_adventures_store_v1"
    private static let dailyPickDateKey = "micro_adventures_daily_pick_date_v1"
    private static let dailyPickIdKey = "micro_adventures_daily_pick_id_v1"
    private static let dailyPickLocationAwareDateKey = "micro_adventures_daily_pick_location_aware_date_v1"

    init() {
        let initialAdventures = Self.loadStoredAdventures()
        adventures = initialAdventures

        let storedPick = Self.loadStoredDailyPick()
        dailyPickDate = storedPick.date
        dailyPickAdventureID = storedPick.id
        dailyPickLocationAwareDate = storedPick.locationAwareDate

        let today = Calendar.current.startOfDay(for: Date())
        currentAdventureID = storedPick.date.flatMap {
            Calendar.current.isDate($0, inSameDayAs: today) ? storedPick.id : nil
        }
        isBootstrapping = false
    }

    var mapSeedAdventure: Adventure {
        adventures.first ?? AdventureSamples.all.first!
    }

    var hasFilteredAdventures: Bool {
        !filteredAdventures.isEmpty
    }

    var bestAvailableAdventure: Adventure? {
        selectAdventure(excluding: [])?.adventure
    }

    var currentAdventure: Adventure? {
        guard !adventures.isEmpty else { return nil }
        return adventures.first(where: { $0.id == currentAdventureID })
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
    }

    // Explicit product behavior: rerolling replaces today's official pick.
    func rerollTodayPick() {
        now = Date()
        var excludedIDs: Set<UUID> = []
        if let currentAdventureID {
            excludedIDs.insert(currentAdventureID)
        }
        guard let result = selectAdventure(excluding: excludedIDs) else { return }
        currentAdventureID = result.adventure.id
        currentTier = result.tier
        dailyPickDate = Calendar.current.startOfDay(for: now)
        dailyPickAdventureID = result.adventure.id
        dailyPickLocationAwareDate = userCoordinate != nil ? dailyPickDate : nil
        markSeen(result.adventure)
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
        applyLocationAwareDailyPickIfNeeded()
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

        let result = selectAdventure(excluding: [])
        dailyPickDate = today
        dailyPickAdventureID = result?.adventure.id
        dailyPickLocationAwareDate = (result != nil && userCoordinate != nil) ? today : nil
        currentAdventureID = result?.adventure.id
        currentTier = result?.tier
        if let adventure = result?.adventure {
            markSeen(adventure)
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
    }

    func whyThisText(for adventure: Adventure, tier: FallbackTier) -> String {
        switch tier {
        case .bestAvailable:
            return "Best available option right now."
        case .nearMatch:
            return "Good option with a small compromise."
        case .exact:
            break
        }

        // Context-aware explanation for exact-tier picks
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
            return "Best fit for your current context."
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
        static let nearMatchThreshold = 0.20
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

    private func scoredAdventures(from source: [Adventure], excluding excludedIDs: Set<UUID> = []) -> [(adventure: Adventure, score: Double)] {
        let scored = source
            .filter { !excludedIDs.contains($0.id) }
            .map { adventure in
            (adventure: adventure, score: score(adventure) + dailyJitter(adventure))
        }
        return scored.sorted { $0.score > $1.score }
    }

    /// 3-tier fallback selection. Returns nil only if the dataset is entirely empty.
    private func selectAdventure(excluding excludedIDs: Set<UUID>) -> RecommendationResult? {
        let eligible = scoredAdventures(from: eligibleAdventures, excluding: excludedIDs)
        let filtered = scoredAdventures(from: filteredAdventures, excluding: excludedIDs)

        // Tier 1: filtered + not recently seen, score meets quality bar
        if let best = eligible.first, best.score >= RecommendationWeights.pickThreshold {
            return RecommendationResult(adventure: best.adventure, tier: .exact)
        }

        // Tier 2: filtered (recently seen allowed), still a reasonable match
        if let best = filtered.first, best.score >= RecommendationWeights.nearMatchThreshold {
            return RecommendationResult(adventure: best.adventure, tier: .nearMatch)
        }

        // Tier 3: best available within filters, then across all adventures
        if let best = filtered.first {
            return RecommendationResult(adventure: best.adventure, tier: .bestAvailable)
        }

        let all = scoredAdventures(from: adventures, excluding: excludedIDs)
        if let best = all.first {
            return RecommendationResult(adventure: best.adventure, tier: .bestAvailable)
        }

        return nil
    }

    private func markSeen(_ adventure: Adventure) {
        guard let index = adventures.firstIndex(where: { $0.id == adventure.id }) else { return }
        adventures[index].lastShownAt = now
    }

    private func applyLocationAwareDailyPickIfNeeded() {
        guard userCoordinate != nil else { return }

        let today = Calendar.current.startOfDay(for: Date())
        let hasTodayPick = dailyPickDate.map { Calendar.current.isDate($0, inSameDayAs: today) } ?? false
        guard hasTodayPick, dailyPickAdventureID != nil else { return }

        let isAlreadyLocationAware = dailyPickLocationAwareDate.map {
            Calendar.current.isDate($0, inSameDayAs: today)
        } ?? false
        guard !isAlreadyLocationAware else { return }

        if showingFilters {
            hasDeferredDailyReselect = true
            return
        }

        ensureDailyPick(forceReselect: true)
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

        if let locationAwareDate = dailyPickLocationAwareDate {
            defaults.set(locationAwareDate.timeIntervalSince1970, forKey: Self.dailyPickLocationAwareDateKey)
        } else {
            defaults.removeObject(forKey: Self.dailyPickLocationAwareDateKey)
        }
    }

    private static func loadStoredDailyPick() -> (date: Date?, id: UUID?, locationAwareDate: Date?) {
        let defaults = UserDefaults.standard
        let dailyPickTimestamp = defaults.double(forKey: dailyPickDateKey)
        let date = dailyPickTimestamp > 0 ? Date(timeIntervalSince1970: dailyPickTimestamp) : nil
        let id = defaults.string(forKey: dailyPickIdKey).flatMap { UUID(uuidString: $0) }
        let locationAwareTimestamp = defaults.double(forKey: dailyPickLocationAwareDateKey)
        let locationAwareDate = locationAwareTimestamp > 0 ? Date(timeIntervalSince1970: locationAwareTimestamp) : nil
        return (date, id, locationAwareDate)
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
                existing.startLatitude = sample.startLatitude
                existing.startLongitude = sample.startLongitude
                existing.endLatitude = sample.endLatitude
                existing.endLongitude = sample.endLongitude
                existing.estimatedDistanceKm = sample.estimatedDistanceKm
                existing.highlights = sample.highlights
                existing.tips = sample.tips
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
