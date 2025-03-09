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
    
    // 添加通知名称，用于通知位置更新
    static let locationUpdatedNotification = Notification.Name("LocationUpdatedNotification")
    
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
                try? await Task.sleep(nanoseconds: 20_000_000_000) // 增加到20秒超时
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
        
        // 清理错误信息
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
    
    // 开始更新位置
    func startUpdatingLocation() {
        print("LocationService: 开始更新位置")
        locationManager.startUpdatingLocation()
    }
    
    // 停止更新位置
    func stopUpdatingLocation() {
        print("LocationService: 停止更新位置")
        locationManager.stopUpdatingLocation()
    }
    
    // 实现CLLocationManagerDelegate方法
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // 只有当位置显著变化时才更新
        if currentLocation == nil || 
           currentLocation!.distance(from: location) > 100 || 
           currentLocation!.timestamp.timeIntervalSinceNow < -300 { // 5分钟更新一次
            
            print("LocationService: 位置已更新 - \(location.coordinate.latitude), \(location.coordinate.longitude)")
            currentLocation = location
            
            // 发送位置更新通知
            NotificationCenter.default.post(name: Self.locationUpdatedNotification, object: nil)
            
            // 尝试获取城市名称
            reverseGeocodeLocation(location)
        }
    }
    
    // 反向地理编码获取城市名称
    private func reverseGeocodeLocation(_ location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            if let error = error {
                print("LocationService: 反向地理编码失败 - \(error.localizedDescription)")
                return
            }
            
            if let placemark = placemarks?.first,
               let city = placemark.locality ?? placemark.administrativeArea {
                print("LocationService: 获取到城市名称 - \(city)")
                self.currentCity = city
            }
        }
    }
    
    // 处理位置权限变化
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("LocationService: 位置权限已授权，开始更新位置")
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            print("LocationService: 位置权限被拒绝或受限")
            locationError = LocationError.permissionDenied
        case .notDetermined:
            print("LocationService: 位置权限未确定")
        @unknown default:
            break
        }
    }
    
    // 处理位置错误
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationService: 获取位置失败 - \(error.localizedDescription)")
        locationError = error
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
        
        // 首先检查是否在预设城市附近
        if let nearestCity = findNearestPresetCity(to: processedLocation) {
            let distance = processedLocation.distance(from: CLLocation(
                latitude: cityCoordinates[nearestCity]?.latitude ?? 0,
                longitude: cityCoordinates[nearestCity]?.longitude ?? 0
            ))
            
            // 如果在50公里范围内，直接使用预设城市
            if distance < 50000 {
                self.currentCity = nearestCity
                self.currentLocation = processedLocation
                
                if !self.hasResumedContinuation {
                    self.hasResumedContinuation = true
                    self.locationContinuation?.resume(returning: ())
                    self.locationContinuation = nil
                    self.isRequestingLocation = false
                }
                return
            }
        }
        
        // 如果不在预设城市附近，进行反向地理编码
        geocoder?.reverseGeocodeLocation(processedLocation, preferredLocale: Locale(identifier: "zh_CN")) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            if let error = error {
                print("反向地理编码失败：\(error.localizedDescription)")
                // 尝试使用最近的预设城市
                if let nearestCity = self.findNearestPresetCity(to: processedLocation) {
                    self.currentCity = nearestCity
                } else {
                    // 如果实在找不到，使用坐标
                    let coordinateString = String(format: "%.3f, %.3f", processedLocation.coordinate.latitude, processedLocation.coordinate.longitude)
                    self.currentCity = "位置：\(coordinateString)"
                }
                self.currentLocation = processedLocation
                
                if !self.hasResumedContinuation {
                    self.hasResumedContinuation = true
                    self.locationContinuation?.resume(returning: ())
                    self.locationContinuation = nil
                    self.isRequestingLocation = false
                }
                return
            }
            
            if let placemark = placemarks?.first {
                // 优先使用行政区
                var locationName = ""
                if let administrativeArea = placemark.administrativeArea {
                    locationName = administrativeArea
                    // 如果是直辖市，直接使用
                    if administrativeArea.hasSuffix("市") {
                        self.currentCity = administrativeArea
                        self.currentLocation = processedLocation
                        
                        if !self.hasResumedContinuation {
                            self.hasResumedContinuation = true
                            self.locationContinuation?.resume(returning: ())
                            self.locationContinuation = nil
                            self.isRequestingLocation = false
                        }
                        return
                    }
                }
                
                // 然后使用城市名
                if let locality = placemark.locality {
                    locationName = locality
                } else if let subAdministrativeArea = placemark.subAdministrativeArea {
                    locationName = subAdministrativeArea
                }
                
                // 确保地名以"市"结尾
                if !locationName.isEmpty && !locationName.hasSuffix("市") {
                    locationName += "市"
                }
                
                if locationName.isEmpty {
                    locationName = placemark.name ?? "未知位置"
                }
                
                print("地理位置名称：\(locationName)")
                self.currentCity = locationName
                self.currentLocation = processedLocation
                
                if !self.hasResumedContinuation {
                    self.hasResumedContinuation = true
                    self.locationContinuation?.resume(returning: ())
                    self.locationContinuation = nil
                    self.isRequestingLocation = false
                }
            } else {
                // 如果没有找到地标信息，尝试使用最近的预设城市
                if let nearestCity = self.findNearestPresetCity(to: processedLocation) {
                    self.currentCity = nearestCity
                } else {
                    let coordinateString = String(format: "%.3f, %.3f", processedLocation.coordinate.latitude, processedLocation.coordinate.longitude)
                    self.currentCity = "位置：\(coordinateString)"
                }
                self.currentLocation = processedLocation
                
                if !self.hasResumedContinuation {
                    self.hasResumedContinuation = true
                    self.locationContinuation?.resume(returning: ())
                    self.locationContinuation = nil
                    self.isRequestingLocation = false
                }
            }
        }
    }
    
    // 预设城市坐标
    private let cityCoordinates: [String: CLLocationCoordinate2D] = [
        "上海市": CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737),
        "北京市": CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074),
        "广州市": CLLocationCoordinate2D(latitude: 23.1291, longitude: 113.2644),
        "深圳市": CLLocationCoordinate2D(latitude: 22.5431, longitude: 114.0579),
        "西安市": CLLocationCoordinate2D(latitude: 34.3416, longitude: 108.9398)
    ]
    
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
    case cityNotFound
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
        case .cityNotFound:
            return "无法找到匹配的城市"
        case .unknown:
            return "未知错误"
        }
    }
}
