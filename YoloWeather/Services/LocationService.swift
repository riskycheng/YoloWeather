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
    private var isUpdatingLocationName = false
    private var retryCount = 0
    private let maxRetries = 3
    
    override init() {
        locationManager = CLLocationManager()
        authorizationStatus = locationManager.authorizationStatus
        
        super.init()
        
        logger.info("Initializing LocationService")
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.distanceFilter = 1000 // Update if location changes by 1km
        
        // 在模拟器上使用默认位置
        #if targetEnvironment(simulator)
        let defaultLocation = CLLocation(latitude: 39.9042, longitude: 116.4074) // 北京
        self.currentLocation = defaultLocation
        updateLocationName(for: defaultLocation)
        #else
        // Check initial status
        checkLocationAuthorization()
        #endif
    }
    
    private func checkLocationAuthorization() {
        logger.info("Checking location authorization: \(self.locationManager.authorizationStatus.rawValue)")
        
        switch self.locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            logger.info("Location authorization already granted")
            startUpdatingLocation()
        case .denied, .restricted:
            logger.warning("Location authorization denied")
            self.errorMessage = "请在设置中允许访问位置信息"
            // 使用默认位置
            useDefaultLocation()
        case .notDetermined:
            logger.info("Location authorization not determined")
            requestLocationPermission()
        @unknown default:
            logger.error("Unknown location authorization status")
            self.errorMessage = "位置服务状态未知"
            // 使用默认位置
            useDefaultLocation()
        }
    }
    
    private func useDefaultLocation() {
        let defaultLocation = CLLocation(latitude: 39.9042, longitude: 116.4074) // 北京
        self.currentLocation = defaultLocation
        updateLocationName(for: defaultLocation)
    }
    
    func requestLocationPermission() {
        logger.info("Requesting location permission")
        
        // Check if location services are enabled at the system level
        if !CLLocationManager.locationServicesEnabled() {
            logger.error("Location services are disabled at system level")
            self.errorMessage = "请在系统设置中开启定位服务"
            useDefaultLocation()
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
            self.errorMessage = "请在设置中允许访问位置信息"
            useDefaultLocation()
        case .authorizedWhenInUse, .authorizedAlways:
            logger.info("Location already authorized, starting updates")
            startUpdatingLocation()
        @unknown default:
            logger.error("Unknown authorization status")
            self.errorMessage = "位置服务状态未知"
            useDefaultLocation()
        }
    }
    
    func startUpdatingLocation() {
        logger.info("Starting location updates")
        retryCount = 0
        locationManager.requestLocation()
    }
    
    func stopUpdatingLocation() {
        logger.info("Stopping location updates")
        locationManager.stopUpdatingLocation()
    }
    
    private func updateLocationName(for location: CLLocation) {
        // 防止重复请求
        guard !isUpdatingLocationName else { return }
        isUpdatingLocationName = true
        
        Task { @MainActor in
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                if let placemark = placemarks.first {
                    var name = ""
                    if let locality = placemark.locality {
                        name = locality
                    } else if let administrativeArea = placemark.administrativeArea {
                        name = administrativeArea
                    } else if let country = placemark.country {
                        name = country
                    }
                    
                    if name.isEmpty {
                        name = "未知位置"
                    }
                    
                    logger.info("Location name updated: \(name)")
                    self.locationName = name
                    self.errorMessage = nil
                    self.isUpdatingLocationName = false
                } else {
                    throw NSError(domain: "LocationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法获取位置信息"])
                }
            } catch {
                logger.error("Geocoding error: \(error.localizedDescription)")
                // 如果地理编码失败，尝试重试
                if self.retryCount < self.maxRetries {
                    self.retryCount += 1
                    self.isUpdatingLocationName = false
                    self.updateLocationName(for: location)
                } else {
                    self.errorMessage = "无法获取位置信息"
                    self.isUpdatingLocationName = false
                    // 如果多次重试失败，使用默认位置
                    self.useDefaultLocation()
                }
            }
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
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
        
        Task { @MainActor in
            logger.info("Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            self.currentLocation = location
            self.retryCount = 0 // 重置重试计数
            self.updateLocationName(for: location)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            logger.error("Location error: \(error.localizedDescription)")
            
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    self.errorMessage = "请在设置中允许访问位置信息"
                    self.useDefaultLocation()
                case .locationUnknown:
                    if self.retryCount < self.maxRetries {
                        self.retryCount += 1
                        self.startUpdatingLocation()
                    } else {
                        self.errorMessage = "无法获取位置信息，请稍后重试"
                        self.useDefaultLocation()
                    }
                case .network:
                    self.errorMessage = "网络错误，请检查网络连接"
                    self.useDefaultLocation()
                default:
                    self.errorMessage = "获取位置信息失败"
                    self.useDefaultLocation()
                }
            } else {
                self.errorMessage = "获取位置信息失败"
                self.useDefaultLocation()
            }
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            
            logger.info("Authorization status changed to: \(manager.authorizationStatus.rawValue)")
            
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                logger.info("Location authorization granted")
                self.errorMessage = nil
                self.startUpdatingLocation()
            case .denied, .restricted:
                logger.warning("Location authorization denied")
                self.errorMessage = "请在设置中允许访问位置信息"
                self.useDefaultLocation()
            case .notDetermined:
                logger.info("Location authorization not determined")
                self.requestLocationPermission()
            @unknown default:
                logger.error("Unknown location authorization status")
                self.errorMessage = "位置服务状态未知"
                self.useDefaultLocation()
            }
        }
    }
}
