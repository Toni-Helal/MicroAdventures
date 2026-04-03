import Foundation
import CoreLocation

enum Category: String, CaseIterable, Identifiable, Codable, Sendable {
    case nature = "Nature"
    case urban = "Urban"
    case water = "Water"
    case night = "Night"
    case family = "Family"
    var id: String { rawValue }

    var systemIcon: String {
        switch self {
        case .nature:
            return "leaf.fill"
        case .urban:
            return "building.2.fill"
        case .water:
            return "drop.fill"
        case .night:
            return "moon.fill"
        case .family:
            return "figure.2.and.child.holdinghands"
        }
    }
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
    var startLatitude: Double? = nil
    var startLongitude: Double? = nil
    var endLatitude: Double? = nil
    var endLongitude: Double? = nil
    var isCompleted: Bool
    var lastShownAt: Date? = nil
    var lastCompletedAt: Date? = nil

    var coordinate: CLLocationCoordinate2D {
        guard hasDistinctEndpoints else {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }

        return CLLocationCoordinate2D(
            latitude: (startCoordinate.latitude + endCoordinate.latitude) / 2,
            longitude: (startCoordinate.longitude + endCoordinate.longitude) / 2
        )
    }

    var startCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: startLatitude ?? latitude,
            longitude: startLongitude ?? longitude
        )
    }

    var endCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: endLatitude ?? latitude,
            longitude: endLongitude ?? longitude
        )
    }

    var hasDistinctEndpoints: Bool {
        abs(startCoordinate.latitude - endCoordinate.latitude) > 0.0001 ||
        abs(startCoordinate.longitude - endCoordinate.longitude) > 0.0001
    }

    var estimatedDistanceKm: Double {
        let paceKmPerHour: Double
        switch effort {
        case .easy:
            paceKmPerHour = 3.8
        case .moderate:
            paceKmPerHour = 5.0
        case .hard:
            paceKmPerHour = 6.2
        }

        let durationEstimate = paceKmPerHour * Double(durationMinutes) / 60
        let straightLineEstimate: Double

        if hasDistinctEndpoints {
            let start = CLLocation(latitude: startCoordinate.latitude, longitude: startCoordinate.longitude)
            let end = CLLocation(latitude: endCoordinate.latitude, longitude: endCoordinate.longitude)
            straightLineEstimate = (start.distance(from: end) / 1000) * 1.25
        } else {
            straightLineEstimate = 0
        }

        let estimate = max(durationEstimate, straightLineEstimate)
        return max(0.4, (estimate * 10).rounded() / 10)
    }

    var openInMapsURL: URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "maps.apple.com"
        components.queryItems = [
            URLQueryItem(
                name: "daddr",
                value: "\(startCoordinate.latitude),\(startCoordinate.longitude)"
            ),
            URLQueryItem(name: "dirflg", value: "w")
        ]
        return components.url
    }

    var isCoordinateValid: Bool {
        isValid(latitude: latitude, longitude: longitude) &&
        (startLatitude == nil || startLongitude == nil || isValid(latitude: startCoordinate.latitude, longitude: startCoordinate.longitude)) &&
        (endLatitude == nil || endLongitude == nil || isValid(latitude: endCoordinate.latitude, longitude: endCoordinate.longitude))
    }

    private func isValid(latitude: Double, longitude: Double) -> Bool {
        (-90.0...90.0).contains(latitude) &&
        (-180.0...180.0).contains(longitude) &&
        !(latitude == 0 && longitude == 0)
    }
}

// Sample data
struct AdventureSamples {
    static let all: [Adventure] = [
        Adventure(
            id: UUID(uuidString: "242FE86A-C759-4C70-8932-7C3E175FD048")!,
            title: "Parc Pierre Lagravere Sunset Loop",
            description: "Walk one calm riverside loop in Parc Pierre Lagravere, then pause once to notice a new detail.",
            decisionTags: ["low-energy", "evening", "walkable", "outdoor"],
            flavorTags: ["calm", "micro-hook", "grounding"],
            category: .nature,
            effort: .easy,
            recommendedEnergy: .low,
            bestTimeWindow: .evening,
            durationMinutes: 30,
            startPointName: "Parc Pierre Lagravere North Gate",
            endPointName: "Parc Pierre Lagravere North Gate",
            locationName: "Parc Pierre Lagravere North Gate",
            latitude: 48.9304,
            longitude: 2.2327,
            isCompleted: false
        ),
        Adventure(
            id: UUID(uuidString: "F0E50D15-E1A6-4329-83AD-810933EECD5E")!,
            title: "Berges de Seine Coffee Loop",
            description: "Walk from Pont de Colombes to a riverside cafe, order something simple, then head back at an easy pace.",
            decisionTags: ["medium-energy", "morning", "outdoor", "coffee"],
            flavorTags: ["rhythm", "micro-hook", "simple"],
            category: .urban,
            effort: .moderate,
            recommendedEnergy: .medium,
            bestTimeWindow: .morning,
            durationMinutes: 45,
            startPointName: "Pont de Colombes",
            endPointName: "Berges Cafe Kiosk",
            locationName: "Berges de Seine South Bank",
            latitude: 48.9238,
            longitude: 2.2468,
            startLatitude: 48.9252,
            startLongitude: 2.2453,
            endLatitude: 48.9238,
            endLongitude: 2.2468,
            isCompleted: false
        ),
        Adventure(
            id: UUID(uuidString: "F11361E2-983B-4A70-8B0C-D0488C47D4B8")!,
            title: "Ile Marante Night Stroll",
            description: "Walk slowly around Ile Marante and stop after exactly 10 minutes to look up once.",
            decisionTags: ["low-energy", "night", "walkable", "outdoor"],
            flavorTags: ["quiet", "micro-hook", "reset"],
            category: .night,
            effort: .easy,
            recommendedEnergy: .low,
            bestTimeWindow: .night,
            durationMinutes: 30,
            startPointName: "Ile Marante Footbridge",
            endPointName: "Ile Marante Footbridge",
            locationName: "Ile Marante Riverside Path",
            latitude: 48.9189,
            longitude: 2.2521,
            isCompleted: false
        ),
        Adventure(
            id: UUID(uuidString: "C5440FF4-8D1B-40E5-AADE-F0031AACA222")!,
            title: "Home Reset",
            description: "Stay indoors, set a 12-minute timer, tidy one surface, stretch once, then stop.",
            decisionTags: ["low-energy", "morning", "indoor", "home"],
            flavorTags: ["micro-hook", "quick-win", "grounding"],
            category: .family,
            effort: .easy,
            recommendedEnergy: .low,
            bestTimeWindow: .morning,
            durationMinutes: 12,
            startPointName: "Home",
            endPointName: "Home",
            locationName: "Home",
            latitude: 48.9281,
            longitude: 2.2685,
            isCompleted: false
        ),
        Adventure(
            id: UUID(uuidString: "6118B4B8-9D2A-4FA1-BD62-0054DAEAD5D2")!,
            title: "Parc Pierre Lagravere Photo Trio",
            description: "Walk to the river edge in Parc Pierre Lagravere and capture exactly three morning-light photos.",
            decisionTags: ["morning", "medium-energy", "outdoor", "walkable"],
            flavorTags: ["fresh-start", "micro-hook", "visual"],
            category: .water,
            effort: .moderate,
            recommendedEnergy: .medium,
            bestTimeWindow: .morning,
            durationMinutes: 20,
            startPointName: "Parc Pierre Lagravere South Gate",
            endPointName: "Parc Pierre Lagravere South Gate",
            locationName: "Parc Pierre Lagravere River Edge",
            latitude: 48.9274,
            longitude: 2.2415,
            isCompleted: false
        ),
        Adventure(
            id: UUID(uuidString: "75E8ED4B-8A8E-4C93-9043-5176BEA6A3FD")!,
            title: "Colombes Covered Passage Hunt",
            description: "Stay under covered passages in central Colombes and note five details before the timer ends.",
            decisionTags: ["low-energy", "rain-friendly", "sheltered", "walkable"],
            flavorTags: ["cozy", "micro-hook", "observation"],
            category: .urban,
            effort: .easy,
            recommendedEnergy: .low,
            bestTimeWindow: .afternoon,
            durationMinutes: 25,
            startPointName: "Colombes Train Station",
            endPointName: "Rue Saint-Denis Arcade",
            locationName: "Central Colombes Arcade",
            latitude: 48.9235,
            longitude: 2.2529,
            startLatitude: 48.9226,
            startLongitude: 2.2544,
            endLatitude: 48.9235,
            endLongitude: 2.2529,
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
            locationName: "Stade Yves-du-Manoir",
            latitude: 48.8919,
            longitude: 2.2370,
            isCompleted: false
        ),
        Adventure(
            id: UUID(uuidString: "2A2E69DD-0675-4C13-B6A6-5F6A38D4B901")!,
            title: "Parc des Bruyeres Stretch and Sketch",
            description: "Walk one loop through Parc des Bruyeres, pause halfway for a 60-second stretch, then sketch one shape you notice.",
            decisionTags: ["medium-energy", "morning", "outdoor", "creative"],
            flavorTags: ["fresh-start", "observation", "gentle-push"],
            category: .nature,
            effort: .moderate,
            recommendedEnergy: .medium,
            bestTimeWindow: .morning,
            durationMinutes: 28,
            startPointName: "Parc des Bruyeres East Gate",
            endPointName: "Parc des Bruyeres East Gate",
            locationName: "Parc des Bruyeres Meadow Path",
            latitude: 48.9048,
            longitude: 2.2456,
            isCompleted: false
        ),
        Adventure(
            id: UUID(uuidString: "7D572A21-7B0E-4C60-96B4-45A9E4C1D102")!,
            title: "Seine Bench Breathing Stop",
            description: "Walk to a quiet bench along the Seine, do five slow breaths, then walk home without checking your phone.",
            decisionTags: ["low-energy", "evening", "outdoor", "waterfront"],
            flavorTags: ["calm", "reset", "simple"],
            category: .water,
            effort: .easy,
            recommendedEnergy: .low,
            bestTimeWindow: .evening,
            durationMinutes: 18,
            startPointName: "Seine Riverside Bench",
            endPointName: "Seine Riverside Bench",
            locationName: "Seine Riverside Bench",
            latitude: 48.9217,
            longitude: 2.2392,
            isCompleted: false
        ),
        Adventure(
            id: UUID(uuidString: "A4F8F73E-0C16-4235-8D14-3C3D495B1C03")!,
            title: "Square Colbert Scooter Loop",
            description: "Do three playful loops around Square Colbert, switching pace at each corner, then stop while it still feels fun.",
            decisionTags: ["medium-energy", "afternoon", "outdoor", "family"],
            flavorTags: ["playful", "movement", "quick-win"],
            category: .family,
            effort: .moderate,
            recommendedEnergy: .medium,
            bestTimeWindow: .afternoon,
            durationMinutes: 24,
            startPointName: "Square Colbert Entrance",
            endPointName: "Square Colbert Entrance",
            locationName: "Square Colbert",
            latitude: 48.9268,
            longitude: 2.2507,
            isCompleted: false
        ),
        Adventure(
            id: UUID(uuidString: "BE1A0E55-8292-4F32-99F5-51CBE390D404")!,
            title: "Pont de Levallois Light Hunt",
            description: "Walk until dusk near Pont de Levallois and spot six different light reflections before turning back.",
            decisionTags: ["medium-energy", "evening", "outdoor", "lights"],
            flavorTags: ["urban-glow", "observation", "micro-hook"],
            category: .night,
            effort: .moderate,
            recommendedEnergy: .medium,
            bestTimeWindow: .evening,
            durationMinutes: 35,
            startPointName: "Pont de Levallois Riverside",
            endPointName: "Pont de Levallois Riverside",
            locationName: "Pont de Levallois Riverside",
            latitude: 48.9006,
            longitude: 2.2584,
            isCompleted: false
        ),
        Adventure(
            id: UUID(uuidString: "CC837708-2B60-45BA-8C49-2B1D73EE7A05")!,
            title: "Parc Pierre Lagravere Power Intervals",
            description: "Alternate three fast runs and three slow recoveries on the riverside path, then cool down for two minutes.",
            decisionTags: ["high-energy", "afternoon", "outdoor", "intervals"],
            flavorTags: ["challenge", "sweat", "focus"],
            category: .nature,
            effort: .hard,
            recommendedEnergy: .high,
            bestTimeWindow: .afternoon,
            durationMinutes: 26,
            startPointName: "Parc Pierre Lagravere Running Path",
            endPointName: "Parc Pierre Lagravere Running Path",
            locationName: "Parc Pierre Lagravere Running Path",
            latitude: 48.9292,
            longitude: 2.2366,
            isCompleted: false
        ),
        Adventure(
            id: UUID(uuidString: "D0F2B8E4-8C5A-4DDE-9070-687466149706")!,
            title: "Seine Bridge Fast Finish",
            description: "Do five fast segments between two bridge lights, recover while walking back, then finish at the water.",
            decisionTags: ["high-energy", "night", "outdoor", "waterfront"],
            flavorTags: ["challenge", "night-air", "tempo"],
            category: .water,
            effort: .hard,
            recommendedEnergy: .high,
            bestTimeWindow: .night,
            durationMinutes: 25,
            startPointName: "Seine Bridge Overlook",
            endPointName: "Seine Bridge Overlook",
            locationName: "Seine Bridge Overlook",
            latitude: 48.9198,
            longitude: 2.2434,
            isCompleted: false
        ),
        Adventure(
            id: UUID(uuidString: "E1A749B9-4F3A-4A41-A6D5-943AC6717807")!,
            title: "Living Room Ladder Burst",
            description: "Set a 15-minute timer and cycle through squats, stairs, and dance breaks at home without opening another app.",
            decisionTags: ["high-energy", "night", "indoor", "family"],
            flavorTags: ["indoor", "momentum", "quick-win"],
            category: .family,
            effort: .hard,
            recommendedEnergy: .high,
            bestTimeWindow: .night,
            durationMinutes: 15,
            startPointName: "Home",
            endPointName: "Home",
            locationName: "Home",
            latitude: 48.9281,
            longitude: 2.2685,
            isCompleted: false
        ),
        Adventure(
            id: UUID(uuidString: "F2C54A08-6E7D-43AF-BBCF-08D28A134D08")!,
            title: "Colombes Window-Lit Detour",
            description: "Take one short detour through the brightest residential street you know and count warm windows on the way.",
            decisionTags: ["low-energy", "night", "outdoor", "walkable"],
            flavorTags: ["quiet", "urban-glow", "simple"],
            category: .urban,
            effort: .easy,
            recommendedEnergy: .low,
            bestTimeWindow: .night,
            durationMinutes: 20,
            startPointName: "Rue Saint-Denis Corner",
            endPointName: "Rue Saint-Denis Corner",
            locationName: "Central Colombes Evening Walk",
            latitude: 48.9246,
            longitude: 2.2537,
            isCompleted: false
        ),
        Adventure(
            id: UUID(uuidString: "0C3E21F4-5AF9-4A59-8D0B-A6F29F452809")!,
            title: "Parc de l'Ile Marante Tree ID Pause",
            description: "Walk slowly through Parc de l'Ile Marante and identify three different tree shapes before you leave.",
            decisionTags: ["low-energy", "afternoon", "outdoor", "nature"],
            flavorTags: ["observation", "calm", "micro-hook"],
            category: .nature,
            effort: .easy,
            recommendedEnergy: .low,
            bestTimeWindow: .afternoon,
            durationMinutes: 22,
            startPointName: "Parc de l'Ile Marante Gate",
            endPointName: "Parc de l'Ile Marante Gate",
            locationName: "Parc de l'Ile Marante",
            latitude: 48.9176,
            longitude: 2.2514,
            isCompleted: false
        ),
        Adventure(
            id: UUID(uuidString: "1D94B620-344A-4EDC-A442-942CE0AA920A")!,
            title: "Quay Reflection Audio Walk",
            description: "Play one favorite song, walk the quay until it ends, then spend the next song walking back in silence.",
            decisionTags: ["medium-energy", "night", "outdoor", "waterfront"],
            flavorTags: ["reflective", "rhythm", "night-air"],
            category: .water,
            effort: .moderate,
            recommendedEnergy: .medium,
            bestTimeWindow: .night,
            durationMinutes: 18,
            startPointName: "Seine Quay Promenade",
            endPointName: "Seine Quay Promenade",
            locationName: "Seine Quay Promenade",
            latitude: 48.9209,
            longitude: 2.2448,
            isCompleted: false
        ),
        Adventure(
            id: UUID(uuidString: "3955A8D4-28D3-4ED7-8C6E-35F6BB2F1E0B")!,
            title: "Kitchen Timer Dance Reset",
            description: "Put on two songs at home, clean as you move, then end with one silly stretch together.",
            decisionTags: ["medium-energy", "evening", "indoor", "family"],
            flavorTags: ["playful", "reset", "home"],
            category: .family,
            effort: .moderate,
            recommendedEnergy: .medium,
            bestTimeWindow: .evening,
            durationMinutes: 16,
            startPointName: "Home",
            endPointName: "Home",
            locationName: "Home",
            latitude: 48.9281,
            longitude: 2.2685,
            isCompleted: false
        ),
        Adventure(
            id: UUID(uuidString: "4EA5C17C-AB34-4C2A-8D43-FE7A84B6630C")!,
            title: "Blue Hour Canal Pause",
            description: "Step out at blue hour, walk until the sky shifts darker, then stop for one minute without taking a photo.",
            decisionTags: ["low-energy", "evening", "outdoor", "lights"],
            flavorTags: ["quiet", "blue-hour", "grounding"],
            category: .night,
            effort: .easy,
            recommendedEnergy: .low,
            bestTimeWindow: .evening,
            durationMinutes: 20,
            startPointName: "Canal Walk Entrance",
            endPointName: "Canal Walk Entrance",
            locationName: "Blue Hour Canal Path",
            latitude: 48.9157,
            longitude: 2.2496,
            isCompleted: false
        ),
        Adventure(
            id: UUID(uuidString: "5F6D0B91-1E57-461B-B9F8-6A6E1D7CB70D")!,
            title: "Tram Stop Sprint Circuit",
            description: "Sprint between three tram markers, walk back each time, and end with one slow lap to reset your breathing.",
            decisionTags: ["high-energy", "afternoon", "outdoor", "sprints"],
            flavorTags: ["tempo", "challenge", "quick-win"],
            category: .urban,
            effort: .hard,
            recommendedEnergy: .high,
            bestTimeWindow: .afternoon,
            durationMinutes: 21,
            startPointName: "Victor Basch Tram Stop",
            endPointName: "Victor Basch Tram Stop",
            locationName: "Victor Basch Tram Corridor",
            latitude: 48.9181,
            longitude: 2.2476,
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
        case startLatitude
        case startLongitude
        case endLatitude
        case endLongitude
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
        startLatitude = try container.decodeIfPresent(Double.self, forKey: .startLatitude)
        startLongitude = try container.decodeIfPresent(Double.self, forKey: .startLongitude)
        endLatitude = try container.decodeIfPresent(Double.self, forKey: .endLatitude)
        endLongitude = try container.decodeIfPresent(Double.self, forKey: .endLongitude)
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
        try container.encodeIfPresent(startLatitude, forKey: .startLatitude)
        try container.encodeIfPresent(startLongitude, forKey: .startLongitude)
        try container.encodeIfPresent(endLatitude, forKey: .endLatitude)
        try container.encodeIfPresent(endLongitude, forKey: .endLongitude)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encodeIfPresent(lastShownAt, forKey: .lastShownAt)
        try container.encodeIfPresent(lastCompletedAt, forKey: .lastCompletedAt)
    }
}
