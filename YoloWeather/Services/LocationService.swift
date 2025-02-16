import Foundation
import CoreLocation
import os.log

@MainActor
class LocationService: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    @Published var locationError: Error?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentCity: String?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers // 城市级别精度足够
        
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
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        checkLocationAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // 更新位置
        currentLocation = location
        
        // 反向地理编码获取城市名
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.locationError = error
                    return
                }
                
                if let placemark = placemarks?.first,
                   let city = placemark.locality ?? placemark.administrativeArea {
                    // 确保城市名以"市"结尾
                    let cityName = city.hasSuffix("市") ? city : city + "市"
                    self?.currentCity = cityName
                    self?.stopUpdatingLocation() // 获取到城市后停止更新
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = error
    }
}

enum LocationError: Error {
    case permissionDenied
    case locationUnavailable
    case geocodingFailed
}
