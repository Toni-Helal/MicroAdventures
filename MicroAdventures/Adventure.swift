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
            description: "A quick loop to catch golden hour views and unwind after work.",
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
            description: "Bike to the riverside kiosk for a coffee and back in under an hour.",
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
            description: "A quiet neighborhood walk to spot constellations after dinner.",
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
        )
    ]
}

extension Adventure {
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
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
