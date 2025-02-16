import Foundation
import CoreLocation
import os.log

@MainActor
class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationService()
    private let locationManager = CLLocationManager()
    
    @Published var currentLocation: CLLocation?
    @Published var currentCity: String?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published var locationError: Error?
    
    override private init() {
        authorizationStatus = locationManager.authorizationStatus
        
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.distanceFilter = 5000 // 5公里更新一次
        
        // 检查并请求权限
        checkLocationAuthorization()
    }
    
    private func checkLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdatingLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            locationError = LocationError.permissionDenied
        @unknown default:
            break
        }
    }
    
    func startUpdatingLocation() {
        // 检查是否已经有权限
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        default:
            break
        }
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // 更新位置
        currentLocation = location
        
        // 获取城市名称
        let geocoder = CLGeocoder()
        Task {
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                if let city = placemarks.first?.locality ?? placemarks.first?.administrativeArea {
                    currentCity = city
                }
            } catch {
                print("地理编码失败: \(error.localizedDescription)")
                locationError = error
            }
        }
        
        // 获取到位置后停止更新
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("位置获取失败: \(error.localizedDescription)")
        locationError = error
    }
}

enum LocationError: Error {
    case permissionDenied
    case locationUnavailable
    case geocodingFailed
}
