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
    
    private var lastLocation: CLLocation?
    private var lastGeocodingErrorLocation: CLLocationCoordinate2D?
    
    override private init() {
        authorizationStatus = locationManager.authorizationStatus
        
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest  // 提高精确度
        locationManager.distanceFilter = kCLDistanceFilterNone     // 任何距离变化都更新
        locationManager.pausesLocationUpdatesAutomatically = false
        
        // 检查并请求权限
        checkLocationAuthorization()
    }
    
    private func checkLocationAuthorization() {
        let status = locationManager.authorizationStatus
        
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            print("位置权限被拒绝或受限")
        @unknown default:
            break
        }
    }
    
    private var locationContinuation: CheckedContinuation<Void, Error>?
    private var isRequestingLocation = false
    private var timeoutTask: Task<Void, Never>?
    private var geocoder: CLGeocoder?
    private var hasResumedContinuation = false
    
    func requestLocation() async throws {
        print("\n=== 请求位置更新 ===")
        
        // 重置状态
        hasResumedContinuation = false
        locationError = nil
        
        // 如果已经在请求中，就不要重复请求了
        guard !isRequestingLocation else {
            print("已经在请求位置更新中，跳过重复请求")
            return
        }
        
        isRequestingLocation = true
        
        // 取消之前的请求
        cleanupCurrentRequest()
        
        // 检查权限
        let status = locationManager.authorizationStatus
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            isRequestingLocation = false
            throw LocationError.permissionDenied
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            
            // 设置超时
            timeoutTask = Task {
                try? await Task.sleep(nanoseconds: 10_000_000_000) // 10秒超时
                if !hasResumedContinuation {
                    print("位置更新请求超时")
                    cleanupCurrentRequest()
                    locationContinuation?.resume(throwing: LocationError.timeout)
                    locationContinuation = nil
                    isRequestingLocation = false
                }
            }
            
            // 开始更新位置
            startUpdatingLocation()
        }
    }
    
    internal func cleanupCurrentRequest() {
        // 取消超时任务
        timeoutTask?.cancel()
        timeoutTask = nil
        
        // 取消当前的地理编码请求
        geocoder?.cancelGeocode()
        geocoder = nil
        
        // 停止位置更新
        stopUpdatingLocation()
        
        // 重置状态
        isRequestingLocation = false
        hasResumedContinuation = false
        print("请求状态已清理和重置")
        
        // 如果有未完成的continuation，并且还没有被resumed，用取消错误结束它
        if !hasResumedContinuation, let continuation = locationContinuation {
            hasResumedContinuation = true
            continuation.resume(throwing: LocationError.requestCancelled)
            locationContinuation = nil
        }
        
        // 清理位置信息
        currentLocation = nil
        currentCity = nil
        locationError = nil
    }
    
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            // 添加主操作
            group.addTask {
                try await operation()
            }
            
            // 添加超时任务
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw LocationError.timeout
            }
            
            // 等待第一个完成的任务
            guard let result = try await group.next() else {
                throw LocationError.unknown
            }
            
            // 取消所有其他任务
            group.cancelAll()
            
            return result
        }
    }
    
    internal func startUpdatingLocation() {
        print("开始更新位置...")
        locationManager.startUpdatingLocation()
    }
    
    internal func stopUpdatingLocation() {
        print("停止更新位置...")
        locationManager.stopUpdatingLocation()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // 如果已经在处理中，就不要重复处理
        guard !isRequestingLocation else {
            print("正在处理位置更新，跳过新的更新")
            return
        }
        
        // 标记正在处理
        isRequestingLocation = true
        
        print("收到位置更新：\(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        // 更新位置信息
        self.lastLocation = location
        self.currentLocation = location
        
        // 立即停止位置更新，避免重复接收
        stopUpdatingLocation()
        
        // 开始反向地理编码
        reverseGeocode(location: location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("位置更新失败：\(error.localizedDescription)")
        locationError = error
        
        // 停止更新
        stopUpdatingLocation()
        
        // 如果有等待的 continuation，用错误恢复它
        if !hasResumedContinuation {
            hasResumedContinuation = true
            locationContinuation?.resume(throwing: error)
            locationContinuation = nil
        }
        
        isRequestingLocation = false
    }
    
    private func reverseGeocode(location: CLLocation) {
        // 取消之前的地理编码请求
        geocoder?.cancelGeocode()
        geocoder = CLGeocoder()
        
        print("开始反向地理编码...")
        
        // 创建一个新的位置对象，确保坐标精度适中
        let roundedLat = round(location.coordinate.latitude * 1000) / 1000
        let roundedLon = round(location.coordinate.longitude * 1000) / 1000
        let processedLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: roundedLat, longitude: roundedLon),
            altitude: location.altitude,
            horizontalAccuracy: location.horizontalAccuracy,
            verticalAccuracy: location.verticalAccuracy,
            timestamp: location.timestamp
        )
        
        geocoder?.reverseGeocodeLocation(processedLocation) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            // 函数结束时重置状态
            defer { 
                self.isRequestingLocation = false
                print("位置请求状态已重置")
            }
            
            if let error = error {
                print("反向地理编码失败：\(error.localizedDescription)")
                // 如果地理编码失败，尝试使用预设城市信息
                if let matchedCity = self.findNearestPresetCity(to: processedLocation) {
                    print("使用预设城市信息：\(matchedCity)")
                    self.currentCity = matchedCity
                    
                    if !self.hasResumedContinuation {
                        self.hasResumedContinuation = true
                        self.locationContinuation?.resume(returning: ())
                        self.locationContinuation = nil
                    }
                } else {
                    // 如果实在找不到，使用默认值
                    self.currentCity = "上海市"
                    if !self.hasResumedContinuation {
                        self.hasResumedContinuation = true
                        self.locationContinuation?.resume(returning: ())
                        self.locationContinuation = nil
                    }
                }
                return
            }
            
            if let placemark = placemarks?.first {
                let city = placemark.locality ?? placemark.administrativeArea ?? "未知城市"
                print("城市名称：\(city)")
                
                self.currentCity = city
                
                if !self.hasResumedContinuation {
                    self.hasResumedContinuation = true
                    self.locationContinuation?.resume(returning: ())
                    self.locationContinuation = nil
                }
            }
        }
    }
    
    // 查找最近的预设城市
    private func findNearestPresetCity(to location: CLLocation) -> String? {
        let cityCoordinates: [String: CLLocationCoordinate2D] = [
            "上海市": CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737),
            "北京市": CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074),
            "广州市": CLLocationCoordinate2D(latitude: 23.1291, longitude: 113.2644),
            "深圳市": CLLocationCoordinate2D(latitude: 22.5431, longitude: 114.0579)
        ]
        
        var nearestCity: String?
        var shortestDistance: CLLocationDistance = .infinity
        
        for (city, coordinate) in cityCoordinates {
            let cityLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let distance = location.distance(from: cityLocation)
            
            if distance < shortestDistance {
                shortestDistance = distance
                nearestCity = city
            }
        }
        
        return nearestCity
    }
}

enum LocationError: Error {
    case permissionDenied
    case locationUnavailable
    case geocodingFailed
    case timeout
    case requestCancelled
    case unknown
    
    var localizedDescription: String {
        switch self {
        case .permissionDenied:
            return "需要位置权限才能获取当前位置"
        case .locationUnavailable:
            return "无法获取位置信息"
        case .geocodingFailed:
            return "无法解析地理位置信息"
        case .timeout:
            return "位置请求超时"
        case .requestCancelled:
            return "位置请求被取消"
        case .unknown:
            return "未知错误"
        }
    }
}
