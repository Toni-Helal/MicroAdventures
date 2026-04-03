import Foundation
import CoreLocation

enum Category: String, CaseIterable, Identifiable, Codable, Sendable {
    case nature = "Nature"
    case urban = "Urban"
    case water = "Water"
    case night = "Night"
    case family = "Family"
    var id: String { rawValue }
}

enum Effort: String, CaseIterable, Identifiable, Codable, Sendable {
    case easy = "Easy"
    case moderate = "Moderate"
    case hard = "Hard"
    var id: String { rawValue }
}

enum EnergyLevel: String, CaseIterable, Identifiable, Codable, Sendable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    var id: String { rawValue }
}

enum WeatherCondition: String, CaseIterable, Identifiable, Codable, Sendable {
    case clear = "Clear"
    case cloudy = "Cloudy"
    case rain = "Rain"
    var id: String { rawValue }
}

enum DurationOption: Int, CaseIterable, Identifiable, Codable, Sendable {
    case fifteen = 15
    case thirty = 30
    case sixty = 60
    var id: Int { rawValue }
    var label: String { "\(rawValue) min" }
}

enum BestTimeWindow: String, CaseIterable, Identifiable, Codable, Sendable {
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"
    case night = "Night"
    var id: String { rawValue }
}

struct Adventure: Identifiable, Hashable, Codable, Sendable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var decisionTags: [String]
    var flavorTags: [String]
    var category: Category
    var effort: Effort
    var recommendedEnergy: EnergyLevel
    var bestTimeWindow: BestTimeWindow
    var durationMinutes: Int
    var startPointName: String
    var endPointName: String
    var startLatitude: Double
    var startLongitude: Double
    var endLatitude: Double
    var endLongitude: Double
    var estimatedDistanceKm: Double
    var highlights: [String]
    var tips: [String]
    var locationName: String
    var latitude: Double
    var longitude: Double
    var isCompleted: Bool
    var lastShownAt: Date? = nil
    var lastCompletedAt: Date? = nil

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var startName: String { startPointName }
    var endName: String { endPointName }
    var estimatedDurationMinutes: Int { durationMinutes }

    var startCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: startLatitude, longitude: startLongitude)
    }

    var endCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: endLatitude, longitude: endLongitude)
    }

    var hasDistinctEndpoints: Bool {
        abs(startLatitude - endLatitude) > 0.0001 || abs(startLongitude - endLongitude) > 0.0001
    }
}

// Sample data
struct AdventureSamples {
    static let all: [Adventure] = [
        Adventure(
            id: UUID(uuidString: "242FE86A-C759-4C70-8932-7C3E175FD048")!,
            title: "Parc Pierre Lagravere Sunset Loop",
            description: "Walk one calm riverside loop at Parc Pierre Lagravere, then pause once to notice a new detail.",
            decisionTags: ["low-energy", "evening", "walkable", "outdoor"],
            flavorTags: ["calm", "micro-hook", "grounding"],
            category: .nature,
            effort: .easy,
            recommendedEnergy: .low,
            bestTimeWindow: .evening,
            durationMinutes: 30,
            startPointName: "Parc Pierre Lagravere - Entree Nord",
            endPointName: "Parc Pierre Lagravere - Entree Nord",
            startLatitude: 48.9304,
            startLongitude: 2.2327,
            endLatitude: 48.9304,
            endLongitude: 2.2327,
            estimatedDistanceKm: 2.0,
            highlights: ["Quiet riverside path", "Golden-hour views over the Seine"],
            tips: ["Wear comfortable shoes", "Bring a light layer for evening wind"],
            locationName: "Parc Pierre Lagravere, Colombes",
            latitude: 48.9304,
            longitude: 2.2327,
            isCompleted: false
        ),
        Adventure(
            id: UUID(uuidString: "F0E50D15-E1A6-4329-83AD-810933EECD5E")!,
            title: "Berges de Seine Coffee Loop",
            description: "Do one short out-and-back on the Berges de Seine in Colombes, then turn back after 20 minutes.",
            decisionTags: ["medium-energy", "morning", "outdoor", "short"],
            flavorTags: ["rhythm", "micro-hook", "simple"],
            category: .urban,
            effort: .moderate,
            recommendedEnergy: .medium,
            bestTimeWindow: .morning,
            durationMinutes: 45,
            startPointName: "Pont de Colombes",
            endPointName: "Berges de Seine Cafe Stop",
            startLatitude: 48.9238,
            startLongitude: 2.2468,
            endLatitude: 48.9264,
            endLongitude: 2.2412,
            estimatedDistanceKm: 3.4,
            highlights: ["Quick coffee stop midpoint", "Steady riverbank rhythm"],
            tips: ["Take water if it is warm", "Set a turnaround timer at 20 minutes"],
            locationName: "Berges de Seine, Colombes",
            latitude: 48.9238,
            longitude: 2.2468,
            isCompleted: false
        ),
        Adventure(
            id: UUID(uuidString: "F11361E2-983B-4A70-8B0C-D0488C47D4B8")!,
            title: "Ile Marante Night Stroll",
            description: "Walk slowly around Ile Marante in Colombes and stop after exactly 10 minutes to look up once.",
            decisionTags: ["low-energy", "night", "walkable", "outdoor"],
            flavorTags: ["quiet", "micro-hook", "reset"],
            category: .night,
            effort: .easy,
            recommendedEnergy: .low,
            bestTimeWindow: .night,
            durationMinutes: 60,
            startPointName: "Ile Marante Entrance",
            endPointName: "Ile Marante Entrance",
            startLatitude: 48.9189,
            startLongitude: 2.2521,
            endLatitude: 48.9189,
            endLongitude: 2.2521,
            estimatedDistanceKm: 2.6,
            highlights: ["Low-noise night walk", "Open sky viewpoints"],
            tips: ["Wear reflective clothing", "Keep phone battery above 20%"],
            locationName: "Ile Marante, Colombes",
            latitude: 48.9189,
            longitude: 2.2521,
            isCompleted: true
        ),
        Adventure(
            id: UUID(uuidString: "C5440FF4-8D1B-40E5-AADE-F0031AACA222")!,
            title: "Colombes Morning Home Reset",
            description: "Set a 12-minute timer and do a short breathing and stretch reset at home, then stop.",
            decisionTags: ["low-energy", "morning", "indoor", "no-walk"],
            flavorTags: ["micro-hook", "quick-win", "grounding"],
            category: .family,
            effort: .easy,
            recommendedEnergy: .low,
            bestTimeWindow: .morning,
            durationMinutes: 12,
            startPointName: "Home (Colombes)",
            endPointName: "Home (Colombes)",
            startLatitude: 48.9281,
            startLongitude: 2.2685,
            endLatitude: 48.9281,
            endLongitude: 2.2685,
            estimatedDistanceKm: 0.8,
            highlights: ["Quick morning reset", "Very low friction start"],
            tips: ["Keep the route short", "Use a 12-minute timer"],
            locationName: "Home - Colombes Centre",
            latitude: 48.9281,
            longitude: 2.2685,
            isCompleted: false
        ),
        Adventure(
            id: UUID(uuidString: "6118B4B8-9D2A-4FA1-BD62-0054DAEAD5D2")!,
            title: "Parc Pierre Lagravere Photo Trio",
            description: "Walk toward the Seine edge at Parc Pierre Lagravere and capture exactly three morning photos.",
            decisionTags: ["morning", "medium-energy", "outdoor", "walkable"],
            flavorTags: ["fresh-start", "micro-hook", "visual"],
            category: .urban,
            effort: .moderate,
            recommendedEnergy: .medium,
            bestTimeWindow: .morning,
            durationMinutes: 20,
            startPointName: "Parc Pierre Lagravere - Entree Sud",
            endPointName: "Parc Pierre Lagravere - Entree Sud",
            startLatitude: 48.9034,
            startLongitude: 2.2415,
            endLatitude: 48.9034,
            endLongitude: 2.2415,
            estimatedDistanceKm: 1.7,
            highlights: ["Three-photo challenge", "Morning light scouting"],
            tips: ["Start with camera ready", "Stop after the third photo"],
            locationName: "Parc Pierre Lagravere, Colombes",
            latitude: 48.9034,
            longitude: 2.2415,
            isCompleted: false
        ),
        Adventure(
            id: UUID(uuidString: "75E8ED4B-8A8E-4C93-9043-5176BEA6A3FD")!,
            title: "Colombes Covered Passage Hunt",
            description: "Stay under covered passages near Gare de Colombes and note five details before the timer ends.",
            decisionTags: ["low-energy", "bad-weather", "sheltered", "walkable"],
            flavorTags: ["cozy", "micro-hook", "observation"],
            category: .urban,
            effort: .easy,
            recommendedEnergy: .low,
            bestTimeWindow: .afternoon,
            durationMinutes: 25,
            startPointName: "Gare de Colombes (Sortie Principale)",
            endPointName: "Passage Saint-Denis",
            startLatitude: 48.9235,
            startLongitude: 2.2529,
            endLatitude: 48.9251,
            endLongitude: 2.2546,
            estimatedDistanceKm: 1.9,
            highlights: ["Sheltered route in central Colombes", "Detail-spotting micro challenge"],
            tips: ["Take a small umbrella", "Use covered passages only"],
            locationName: "Centre-ville de Colombes",
            latitude: 48.9235,
            longitude: 2.2529,
            isCompleted: false
        ),
        Adventure(
            id: UUID(uuidString: "9A49A20D-72A0-467B-9CC5-00F98A24E07A")!,
            title: "Stade Yves-du-Manoir Steps Burst",
            description: "Do 4 rounds near Stade Yves-du-Manoir: 90-second stair climb, 2-minute fast walk, then stop.",
            decisionTags: ["high-energy", "short", "outdoor", "stairs"],
            flavorTags: ["challenge", "micro-hook", "quick-win"],
            category: .urban,
            effort: .hard,
            recommendedEnergy: .high,
            bestTimeWindow: .evening,
            durationMinutes: 22,
            startPointName: "Stade Yves-du-Manoir Steps",
            endPointName: "Stade Yves-du-Manoir Steps",
            startLatitude: 48.8919,
            startLongitude: 2.2370,
            endLatitude: 48.8919,
            endLongitude: 2.2370,
            estimatedDistanceKm: 2.2,
            highlights: ["Short high-intensity circuit", "Clear round-based structure"],
            tips: ["Warm up for 2 minutes first", "Keep one round in reserve if tired"],
            locationName: "Stade Yves-du-Manoir, Colombes",
            latitude: 48.8919,
            longitude: 2.2370,
            isCompleted: false
        )
    ]
}

extension Adventure {
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case decisionTags = "decision_tags"
        case flavorTags = "flavor_tags"
        case category
        case effort
        case recommendedEnergy
        case bestTimeWindow
        case durationMinutes
        case startPointName
        case endPointName
        case startLatitude
        case startLongitude
        case endLatitude
        case endLongitude
        case estimatedDistanceKm
        case highlights
        case tips
        case locationName
        case latitude
        case longitude
        case isCompleted
        case lastShownAt
        case lastCompletedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        decisionTags = try container.decodeIfPresent([String].self, forKey: .decisionTags) ?? []
        flavorTags = try container.decodeIfPresent([String].self, forKey: .flavorTags) ?? []
        category = try container.decode(Category.self, forKey: .category)
        effort = try container.decode(Effort.self, forKey: .effort)
        recommendedEnergy = try container.decodeIfPresent(EnergyLevel.self, forKey: .recommendedEnergy) ?? .medium
        bestTimeWindow = try container.decodeIfPresent(BestTimeWindow.self, forKey: .bestTimeWindow) ?? .evening
        let decodedDurationMinutes = try container.decode(Int.self, forKey: .durationMinutes)
        durationMinutes = decodedDurationMinutes
        let decodedLocationName = try container.decode(String.self, forKey: .locationName)
        locationName = decodedLocationName
        startPointName = try container.decodeIfPresent(String.self, forKey: .startPointName) ?? decodedLocationName
        endPointName = try container.decodeIfPresent(String.self, forKey: .endPointName) ?? decodedLocationName
        let decodedLatitude = try container.decode(Double.self, forKey: .latitude)
        let decodedLongitude = try container.decode(Double.self, forKey: .longitude)
        latitude = decodedLatitude
        longitude = decodedLongitude
        let decodedStartLatitude = try container.decodeIfPresent(Double.self, forKey: .startLatitude) ?? decodedLatitude
        let decodedStartLongitude = try container.decodeIfPresent(Double.self, forKey: .startLongitude) ?? decodedLongitude
        let decodedEndLatitude = try container.decodeIfPresent(Double.self, forKey: .endLatitude) ?? decodedLatitude
        let decodedEndLongitude = try container.decodeIfPresent(Double.self, forKey: .endLongitude) ?? decodedLongitude
        startLatitude = decodedStartLatitude
        startLongitude = decodedStartLongitude
        endLatitude = decodedEndLatitude
        endLongitude = decodedEndLongitude
        highlights = try container.decodeIfPresent([String].self, forKey: .highlights) ?? []
        tips = try container.decodeIfPresent([String].self, forKey: .tips) ?? []
        let fallbackDistanceKm = {
            let start = CLLocation(latitude: decodedStartLatitude, longitude: decodedStartLongitude)
            let end = CLLocation(latitude: decodedEndLatitude, longitude: decodedEndLongitude)
            let linearDistance = start.distance(from: end) / 1000
            if linearDistance >= 0.2 {
                return linearDistance
            }
            return max(0.8, Double(decodedDurationMinutes) * 0.06)
        }()
        estimatedDistanceKm = try container.decodeIfPresent(Double.self, forKey: .estimatedDistanceKm) ?? fallbackDistanceKm
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        lastShownAt = try container.decodeIfPresent(Date.self, forKey: .lastShownAt)
        lastCompletedAt = try container.decodeIfPresent(Date.self, forKey: .lastCompletedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(decisionTags, forKey: .decisionTags)
        try container.encode(flavorTags, forKey: .flavorTags)
        try container.encode(category, forKey: .category)
        try container.encode(effort, forKey: .effort)
        try container.encode(recommendedEnergy, forKey: .recommendedEnergy)
        try container.encode(bestTimeWindow, forKey: .bestTimeWindow)
        try container.encode(durationMinutes, forKey: .durationMinutes)
        try container.encode(startPointName, forKey: .startPointName)
        try container.encode(endPointName, forKey: .endPointName)
        try container.encode(startLatitude, forKey: .startLatitude)
        try container.encode(startLongitude, forKey: .startLongitude)
        try container.encode(endLatitude, forKey: .endLatitude)
        try container.encode(endLongitude, forKey: .endLongitude)
        try container.encode(estimatedDistanceKm, forKey: .estimatedDistanceKm)
        try container.encode(highlights, forKey: .highlights)
        try container.encode(tips, forKey: .tips)
        try container.encode(locationName, forKey: .locationName)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encodeIfPresent(lastShownAt, forKey: .lastShownAt)
        try container.encodeIfPresent(lastCompletedAt, forKey: .lastCompletedAt)
    }
}
