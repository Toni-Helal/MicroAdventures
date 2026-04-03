internal import Combine
import CoreLocation
import Foundation

final class UserLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var coordinate: CLLocationCoordinate2D?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus

    private let manager = CLLocationManager()
    private static let lastKnownLatitudeKey = "micro_adventures_last_known_latitude_v1"
    private static let lastKnownLongitudeKey = "micro_adventures_last_known_longitude_v1"
    private(set) var lastKnownCoordinate: CLLocationCoordinate2D?

    override init() {
        authorizationStatus = .notDetermined
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = manager.authorizationStatus
        lastKnownCoordinate = Self.loadLastKnownCoordinate()
        coordinate = lastKnownCoordinate
    }

    func requestPermissionAndLocation() {
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
        guard let latest = locations.last?.coordinate else { return }
        lastKnownCoordinate = latest
        coordinate = latest
        Self.persistLastKnownCoordinate(latest)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Keep fallback map behavior if location is unavailable.
    }

    private static func persistLastKnownCoordinate(_ coordinate: CLLocationCoordinate2D) {
        let defaults = UserDefaults.standard
        defaults.set(coordinate.latitude, forKey: lastKnownLatitudeKey)
        defaults.set(coordinate.longitude, forKey: lastKnownLongitudeKey)
    }

    private static func loadLastKnownCoordinate() -> CLLocationCoordinate2D? {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: lastKnownLatitudeKey) != nil,
              defaults.object(forKey: lastKnownLongitudeKey) != nil else {
            return nil
        }
        let latitude = defaults.double(forKey: lastKnownLatitudeKey)
        let longitude = defaults.double(forKey: lastKnownLongitudeKey)
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
