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

struct Adventure: Identifiable, Hashable, Codable, Sendable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var category: Category
    var effort: Effort
    var durationMinutes: Int
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
            durationMinutes: 30,
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
            durationMinutes: 45,
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
            durationMinutes: 60,
            locationName: "Neighborhood Park",
            latitude: 37.3230,
            longitude: -122.0322,
            isCompleted: true
        )
    ]
}
