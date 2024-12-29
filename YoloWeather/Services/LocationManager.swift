import Foundation
import CoreLocation
import os.log

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus?
    @Published var locationError: String?
    @Published var permissionRequested = false
    
    private let logger = Logger(subsystem: "com.yoloweather.app", category: "LocationManager")
    
    override init() {
        super.init()
        logger.info("Initializing LocationManager")
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers // Less precise but faster for weather
        locationManager.distanceFilter = 3000 // Update location every 3km is sufficient for weather
        
        // Log initial authorization status
        self.authorizationStatus = locationManager.authorizationStatus
        logger.info("Initial authorization status: \(self.authorizationStatus?.rawValue ?? -1)")
    }
    
    func requestLocation() {
        logger.info("Requesting location")
        self.locationError = nil
        
        let status = locationManager.authorizationStatus
        logger.info("Current authorization status: \(status.rawValue)")
        
        switch status {
        case .notDetermined:
            if !self.permissionRequested {
                logger.info("Authorization not determined, requesting permission")
                self.permissionRequested = true
                locationManager.requestWhenInUseAuthorization()
            }
        case .restricted:
            logger.error("Location access restricted")
            self.locationError = "Location access is restricted. Please check your device settings."
        case .denied:
            logger.error("Location access denied")
            self.locationError = "Please enable location access in Settings to get weather for your current location."
        case .authorizedWhenInUse, .authorizedAlways:
            logger.info("Location authorized, requesting location update")
            // For simulator testing, set a default location if no location is available
            #if targetEnvironment(simulator)
            if self.location == nil {
                logger.info("Running in simulator, using default location")
                // San Francisco coordinates
                self.location = CLLocation(latitude: 37.7749, longitude: -122.4194)
            } else {
                locationManager.requestLocation()
            }
            #else
            locationManager.requestLocation()
            #endif
        @unknown default:
            logger.error("Unknown authorization status: \(status.rawValue)")
            self.locationError = "Unknown location authorization status."
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            logger.error("No location received in update")
            return
        }
        
        logger.info("Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        logger.info("Location accuracy: \(location.horizontalAccuracy)m")
        
        self.location = location
        self.locationError = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        logger.error("Location error: \(error.localizedDescription)")
        
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                logger.error("Location access denied")
                self.locationError = "Location access denied. Please enable it in Settings."
            case .locationUnknown:
                logger.error("Location unknown")
                self.locationError = "Unable to determine location. Please try again."
            case .network:
                logger.error("Network error")
                self.locationError = "Network error. Please check your internet connection."
            default:
                logger.error("Other location error: \(clError.code.rawValue)")
                self.locationError = "Error getting location: \(error.localizedDescription)"
            }
        } else {
            logger.error("Unexpected location error: \(error.localizedDescription)")
            self.locationError = "Error getting location: \(error.localizedDescription)"
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        logger.info("Authorization status changed to: \(status.rawValue)")
        self.authorizationStatus = status
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            logger.info("Location authorized, requesting location")
            locationManager.requestLocation()
        case .denied:
            logger.error("Location access denied")
            self.locationError = "Please enable location access in Settings to get weather for your current location."
        case .restricted:
            logger.error("Location access restricted")
            self.locationError = "Location access is restricted. Please check your device settings."
        case .notDetermined:
            if !self.permissionRequested {
                logger.info("Authorization not determined, requesting permission")
                self.permissionRequested = true
                locationManager.requestWhenInUseAuthorization()
            }
        @unknown default:
            logger.error("Unknown authorization status: \(status.rawValue)")
            self.locationError = "Unknown location authorization status."
        }
    }
}
