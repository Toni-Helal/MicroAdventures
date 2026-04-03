import Foundation

enum AdventureRepository {
    static func loadAdventures(bundle: Bundle = .main) -> [Adventure] {
        let fallback = validated(AdventureSamples.all, source: "AdventureSamples.all")

        guard let url = bundle.url(forResource: "adventures", withExtension: "json") else {
            return fallback
        }

        guard let data = try? Data(contentsOf: url) else {
            debugFailure("Unable to read adventures.json from the app bundle.")
            return fallback
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let adventures = try? decoder.decode([Adventure].self, from: data) else {
            debugFailure("Unable to decode adventures.json. Falling back to AdventureSamples.")
            return fallback
        }

        let validAdventures = validated(adventures, source: "adventures.json")
        return validAdventures.isEmpty ? fallback : validAdventures
    }

    private static func validated(_ adventures: [Adventure], source: String) -> [Adventure] {
        let validAdventures = adventures.filter(\.isCoordinateValid)

        if validAdventures.count != adventures.count {
            let invalidTitles = adventures
                .filter { !$0.isCoordinateValid }
                .map(\.title)
                .joined(separator: ", ")
            debugFailure("Ignored adventures with invalid coordinates from \(source): \(invalidTitles)")
        }

        return validAdventures
    }

    private static func debugFailure(_ message: String) {
        #if DEBUG
        assertionFailure(message)
        #endif
    }
}
