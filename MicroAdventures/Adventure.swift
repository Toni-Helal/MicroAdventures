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
    var locationName: String
    var latitude: Double
    var longitude: Double
    var isCompleted: Bool
    var lastShownAt: Date? = nil
    var lastCompletedAt: Date? = nil

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// Sample data
struct AdventureSamples {
    static let all: [Adventure] = [
        Adventure(
            id: UUID(uuidString: "242FE86A-C759-4C70-8932-7C3E175FD048")!,
            title: "Sunset Hill Walk",
            description: "Walk one loop only, then stop once to notice one new detail.",
            decisionTags: ["low-energy", "evening", "walkable", "outdoor"],
            flavorTags: ["calm", "micro-hook", "grounding"],
            category: .nature,
            effort: .easy,
            recommendedEnergy: .low,
            bestTimeWindow: .evening,
            durationMinutes: 30,
            startPointName: "Panama Park Entrance",
            endPointName: "Panama Park Entrance",
            locationName: "Apple Park Hill",
            latitude: 37.3349,
            longitude: -122.0090,
            isCompleted: false
        ),
        Adventure(
            id: UUID(uuidString: "F0E50D15-E1A6-4329-83AD-810933EECD5E")!,
            title: "Riverside Coffee Dash",
            description: "Do one short out-and-back only, and turn back after 20 minutes.",
            decisionTags: ["medium-energy", "morning", "outdoor", "short"],
            flavorTags: ["rhythm", "micro-hook", "simple"],
            category: .urban,
            effort: .moderate,
            recommendedEnergy: .medium,
            bestTimeWindow: .morning,
            durationMinutes: 45,
            startPointName: "Main Street Bridge",
            endPointName: "Creekside Kiosk",
            locationName: "Creekside Kiosk",
            latitude: 37.3317,
            longitude: -122.0307,
            isCompleted: false
        ),
        Adventure(
            id: UUID(uuidString: "F11361E2-983B-4A70-8B0C-D0488C47D4B8")!,
            title: "Night Sky Stroll",
            description: "Walk slowly and stop after exactly 10 minutes to look up once.",
            decisionTags: ["low-energy", "night", "walkable", "outdoor"],
            flavorTags: ["quiet", "micro-hook", "reset"],
            category: .night,
            effort: .easy,
            recommendedEnergy: .low,
            bestTimeWindow: .night,
            durationMinutes: 60,
            startPointName: "Neighborhood Park Gate",
            endPointName: "Neighborhood Park Gate",
            locationName: "Neighborhood Park",
            latitude: 37.3230,
            longitude: -122.0322,
            isCompleted: true
        ),
        Adventure(
            id: UUID(uuidString: "C5440FF4-8D1B-40E5-AADE-F0031AACA222")!,
            title: "Morning Entry Reset",
            description: "Set a 12-minute timer and reset one small home zone, then stop.",
            decisionTags: ["low-energy", "morning", "indoor", "no-walk"],
            flavorTags: ["micro-hook", "quick-win", "grounding"],
            category: .family,
            effort: .easy,
            recommendedEnergy: .low,
            bestTimeWindow: .morning,
            durationMinutes: 12,
            startPointName: "Home",
            endPointName: "Home",
            locationName: "Home Entry",
            latitude: 37.3230,
            longitude: -122.0322,
            isCompleted: false
        ),
        Adventure(
            id: UUID(uuidString: "6118B4B8-9D2A-4FA1-BD62-0054DAEAD5D2")!,
            title: "First-Light Photo Trio",
            description: "Walk one short loop and capture exactly three morning-light photos.",
            decisionTags: ["morning", "medium-energy", "outdoor", "walkable"],
            flavorTags: ["fresh-start", "micro-hook", "visual"],
            category: .urban,
            effort: .moderate,
            recommendedEnergy: .medium,
            bestTimeWindow: .morning,
            durationMinutes: 20,
            startPointName: "Rue Saint-Denis Corner",
            endPointName: "Rue Saint-Denis Corner",
            locationName: "Colombes Center Loop",
            latitude: 48.9226,
            longitude: 2.2524,
            isCompleted: false
        ),
        Adventure(
            id: UUID(uuidString: "75E8ED4B-8A8E-4C93-9043-5176BEA6A3FD")!,
            title: "Rain Shelter Detail Hunt",
            description: "Stay under covered spots and note five details before timer ends.",
            decisionTags: ["low-energy", "bad-weather", "sheltered", "walkable"],
            flavorTags: ["cozy", "micro-hook", "observation"],
            category: .urban,
            effort: .easy,
            recommendedEnergy: .low,
            bestTimeWindow: .afternoon,
            durationMinutes: 25,
            startPointName: "Covered Bus Stop",
            endPointName: "Nearby Passage Exit",
            locationName: "Sheltered Streets, Colombes",
            latitude: 48.9240,
            longitude: 2.2572,
            isCompleted: false
        ),
        Adventure(
            id: UUID(uuidString: "9A49A20D-72A0-467B-9CC5-00F98A24E07A")!,
            title: "Stair Burst Circuit",
            description: "Do 4 rounds: 90-second stair climb, 2-minute fast walk, then stop.",
            decisionTags: ["high-energy", "short", "outdoor", "stairs"],
            flavorTags: ["challenge", "micro-hook", "quick-win"],
            category: .urban,
            effort: .hard,
            recommendedEnergy: .high,
            bestTimeWindow: .evening,
            durationMinutes: 22,
            startPointName: "Hotel de Ville Steps",
            endPointName: "Hotel de Ville Steps",
            locationName: "Colombes Civic Plaza",
            latitude: 48.9221,
            longitude: 2.2548,
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
        durationMinutes = try container.decode(Int.self, forKey: .durationMinutes)
        locationName = try container.decode(String.self, forKey: .locationName)
        startPointName = try container.decodeIfPresent(String.self, forKey: .startPointName) ?? locationName
        endPointName = try container.decodeIfPresent(String.self, forKey: .endPointName) ?? locationName
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
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
        try container.encode(locationName, forKey: .locationName)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encodeIfPresent(lastShownAt, forKey: .lastShownAt)
        try container.encodeIfPresent(lastCompletedAt, forKey: .lastCompletedAt)
    }
}
