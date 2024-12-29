import Foundation
import CoreLocation
import os.log

@MainActor
class LocationService: NSObject, ObservableObject {
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var locationName: String = ""
    @Published var errorMessage: String?
    
    private let locationManager: CLLocationManager
    private let logger = Logger(subsystem: "com.yoloweather.app", category: "LocationService")
    private let geocoder = CLGeocoder()
    
    override init() {
        locationManager = CLLocationManager()
        authorizationStatus = locationManager.authorizationStatus
        
        super.init()
        
        logger.info("Initializing LocationService")
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.distanceFilter = 1000 // Update if location changes by 1km
        
        // Check initial status
        checkLocationAuthorization()
    }
    
    private func checkLocationAuthorization() {
        logger.info("Checking location authorization: \(self.locationManager.authorizationStatus.rawValue)")
        
        switch self.locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            logger.info("Location authorization already granted")
            startUpdatingLocation()
        case .denied, .restricted:
            logger.warning("Location authorization denied")
            self.errorMessage = "Location access denied. Please enable in Settings."
        case .notDetermined:
            logger.info("Location authorization not determined")
            requestLocationPermission()
        @unknown default:
            logger.error("Unknown location authorization status")
            self.errorMessage = "Unknown location authorization status"
        }
    }
    
    func requestLocationPermission() {
        logger.info("Requesting location permission")
        
        // Check if location services are enabled at the system level
        if !CLLocationManager.locationServicesEnabled() {
            logger.error("Location services are disabled at system level")
            self.errorMessage = "Please enable Location Services in Settings"
            return
        }
        
        logger.info("Current authorization status: \(self.locationManager.authorizationStatus.rawValue)")
        
        // Request permission based on current status
        switch self.locationManager.authorizationStatus {
        case .notDetermined:
            logger.info("Requesting when in use authorization")
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            logger.warning("Location access denied, prompting to open settings")
            self.errorMessage = "Please enable location access in Settings"
        case .authorizedWhenInUse, .authorizedAlways:
            logger.info("Location already authorized, starting updates")
            startUpdatingLocation()
        @unknown default:
            logger.error("Unknown authorization status")
            self.errorMessage = "Unknown location authorization status"
        }
    }
    
    func startUpdatingLocation() {
        logger.info("Starting location updates")
        
        // Force a single update
        locationManager.requestLocation()
        
        // Start continuous updates
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        logger.info("Stopping location updates")
        locationManager.stopUpdatingLocation()
    }
    
    private func updateLocationName(for location: CLLocation) {
        Task {
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                if let placemark = placemarks.first {
                    var name = ""
                    if let locality = placemark.locality {
                        name = locality
                    } else if let administrativeArea = placemark.administrativeArea {
                        name = administrativeArea
                    }
                    
                    if name.isEmpty {
                        name = "Unknown Location"
                    }
                    
                    logger.info("Location name updated: \(name)")
                    await MainActor.run {
                        self.locationName = name
                        self.errorMessage = nil
                    }
                }
            } catch {
                logger.error("Geocoding error: \(error.localizedDescription)")
                await MainActor.run {
                    self.errorMessage = "Failed to get location name"
                }
            }
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { 
            logger.warning("No location received")
            return 
        }
        
        // Only update if accuracy is good enough
        guard location.horizontalAccuracy >= 0 else { 
            logger.warning("Invalid accuracy: \(location.horizontalAccuracy)")
            return 
        }
        guard location.horizontalAccuracy <= 1000 else { 
            logger.warning("Poor accuracy: \(location.horizontalAccuracy)")
            return 
        }
        
        logger.info("Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        self.currentLocation = location
        updateLocationName(for: location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        logger.error("Location error: \(error.localizedDescription)")
        self.errorMessage = "Failed to get location: \(error.localizedDescription)"
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.authorizationStatus = manager.authorizationStatus
        
        logger.info("Authorization status changed to: \(manager.authorizationStatus.rawValue)")
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            logger.info("Location authorization granted")
            self.errorMessage = nil
            startUpdatingLocation()
        case .denied, .restricted:
            logger.warning("Location authorization denied")
            self.errorMessage = "Location access denied. Please enable in Settings."
            stopUpdatingLocation()
        case .notDetermined:
            logger.info("Location authorization not determined")
            requestLocationPermission()
        @unknown default:
            logger.error("Unknown location authorization status")
            self.errorMessage = "Unknown location authorization status"
        }
    }
}
