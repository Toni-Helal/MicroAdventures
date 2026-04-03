internal import Combine
import CoreLocation
import Foundation

final class UserLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var coordinate: CLLocationCoordinate2D?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()

    private static let lastLatKey = "micro_adventures_last_lat_v1"
    private static let lastLngKey = "micro_adventures_last_lng_v1"

    var isAccessDeniedOrRestricted: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = manager.authorizationStatus
        if let restored = Self.loadStoredCoordinate() {
            coordinate = restored
        }
    }

    func requestPermissionAndLocation() {
        authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        coordinate = locations.last?.coordinate
        if let coord = coordinate {
            persistCoordinate(coord)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Keep fallback map behavior if location is unavailable.
    }

    private func persistCoordinate(_ coord: CLLocationCoordinate2D) {
        UserDefaults.standard.set(coord.latitude,  forKey: Self.lastLatKey)
        UserDefaults.standard.set(coord.longitude, forKey: Self.lastLngKey)
    }

    private static func loadStoredCoordinate() -> CLLocationCoordinate2D? {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: lastLatKey) != nil,
              defaults.object(forKey: lastLngKey) != nil
        else { return nil }
        return CLLocationCoordinate2D(
            latitude:  defaults.double(forKey: lastLatKey),
            longitude: defaults.double(forKey: lastLngKey)
        )
    }
}
