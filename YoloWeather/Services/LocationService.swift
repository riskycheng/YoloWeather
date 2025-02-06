import Foundation
import CoreLocation
import os.log

@MainActor
class LocationService: NSObject, ObservableObject {
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var locationName: String = ""
    @Published var errorMessage: String?
    @Published var isLocating: Bool = false
    var onLocationUpdated: ((CLLocation) -> Void)?
    
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
        let defaultLocation = CLLocation(latitude: 31.2304, longitude: 121.4737) // 上海
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
        let defaultLocation = CLLocation(latitude: 31.2304, longitude: 121.4737) // 上海
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
        isLocating = true
        errorMessage = nil
        locationManager.requestLocation()
    }
    
    func stopUpdatingLocation() {
        logger.info("Stopping location updates")
        isLocating = false
        locationManager.stopUpdatingLocation()
    }
    
    func waitForLocationNameUpdate() async {
        // 最多等待3秒钟
        let startTime = Date()
        while isUpdatingLocationName {
            try? await Task.sleep(nanoseconds: 100_000_000) // 等待0.1秒
            if Date().timeIntervalSince(startTime) > 3.0 {
                break
            }
        }
    }
    
    func updateLocationName(for location: CLLocation) {
        guard !isUpdatingLocationName else { return }
        isUpdatingLocationName = true
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            Task { @MainActor in
                defer { self?.isUpdatingLocationName = false }
                
                if let error = error {
                    self?.logger.error("Geocoding error: \(error.localizedDescription)")
                    self?.errorMessage = "无法获取位置信息"
                    return
                }
                
                if let placemark = placemarks?.first {
                    // 中国城市的特殊处理
                    if placemark.isoCountryCode == "CN" {
                        if let locality = placemark.locality {
                            // 如果城市名不以"市"结尾，添加"市"后缀
                            let cityName = locality.hasSuffix("市") ? locality : "\(locality)市"
                            self?.locationName = cityName
                        } else if let administrativeArea = placemark.administrativeArea {
                            // 如果没有城市名但有行政区划（省份），使用行政区划
                            self?.locationName = administrativeArea
                        } else {
                            self?.locationName = "未知位置"
                        }
                    } else {
                        // 非中国城市，使用locality或administrativeArea
                        if let locality = placemark.locality {
                            self?.locationName = locality
                        } else if let administrativeArea = placemark.administrativeArea {
                            self?.locationName = administrativeArea
                        } else {
                            self?.locationName = "未知位置"
                        }
                    }
                    self?.logger.info("Location name updated: \(self?.locationName ?? "")")
                } else {
                    self?.locationName = "未知位置"
                    self?.logger.warning("No placemark found")
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
            self.onLocationUpdated?(location)
            self.isLocating = false
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
