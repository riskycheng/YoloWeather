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
        locationManager.pausesLocationUpdatesAutomatically = false
        
        // 检查并请求权限
        checkLocationAuthorization()
    }
    
    private func checkLocationAuthorization() {
        print("\n=== 检查位置权限状态 ===")
        let status = locationManager.authorizationStatus
        print("当前权限状态：\(status.rawValue)")
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            print("已获得位置权限，开始更新位置")
            startUpdatingLocation()
        case .notDetermined:
            print("位置权限未确定，请求权限中...")
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            print("位置权限被拒绝或受限")
            locationError = NSError(domain: "LocationServiceError", 
                                  code: 1, 
                                  userInfo: [NSLocalizedDescriptionKey: "需要位置权限才能获取当前位置"])
        @unknown default:
            print("未知的权限状态")
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
        
        // 取消之前的请求
        cleanupCurrentRequest()
        
        // 开始新的请求
        isRequestingLocation = true
        hasResumedContinuation = false
        
        do {
            let status = locationManager.authorizationStatus
            print("当前位置权限状态：\(status.rawValue)")
            
            if status == .notDetermined {
                print("权限未确定，请求位置权限...")
                await MainActor.run {
                    locationManager.requestWhenInUseAuthorization()
                }
                
                // 等待权限更新
                for i in 0..<10 {
                    print("等待权限更新，尝试次数：\(i + 1)")
                    if locationManager.authorizationStatus != .notDetermined {
                        break
                    }
                    try await Task.sleep(nanoseconds: 500_000_000)
                }
            }
            
            guard locationManager.authorizationStatus == .authorizedWhenInUse ||
                  locationManager.authorizationStatus == .authorizedAlways else {
                print("没有足够的位置权限，当前状态：\(locationManager.authorizationStatus.rawValue)")
                throw LocationError.permissionDenied
            }
            
            print("开始请求一次性位置更新...")
            // 确保定位服务已开启
            if !CLLocationManager.locationServicesEnabled() {
                print("系统定位服务未开启")
                throw LocationError.locationUnavailable
            }
            
            // 先停止之前的更新
            locationManager.stopUpdatingLocation()
            
            // 重新配置并开始新的请求
            locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
            locationManager.distanceFilter = kCLDistanceFilterNone
            
            // 使用 withTimeout 包装整个位置请求过程
            try await withTimeout(seconds: 15) { [weak self] in
                guard let self = self else { throw LocationError.unknown }
                
                try await withCheckedThrowingContinuation { continuation in
                    print("发起位置请求...")
                    self.locationContinuation = continuation
                    self.locationManager.requestLocation()
                }
            }
            
            // 确保我们有位置和城市信息
            guard currentLocation != nil, currentCity != nil else {
                print("位置请求完成但信息不完整")
                throw LocationError.locationUnavailable
            }
            
            print("位置请求成功完成")
            
        } catch {
            print("位置请求失败：\(error.localizedDescription)")
            cleanupCurrentRequest()
            throw error
        }
    }
    
    private func cleanupCurrentRequest() {
        // 取消超时任务
        timeoutTask?.cancel()
        timeoutTask = nil
        
        // 取消当前的地理编码请求
        geocoder?.cancelGeocode()
        geocoder = nil
        
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
        isRequestingLocation = false
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
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("\n=== 位置权限状态改变 ===")
        print("新的权限状态：\(manager.authorizationStatus.rawValue)")
        authorizationStatus = manager.authorizationStatus
        checkLocationAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("\n=== 收到位置更新 ===")
        guard let location = locations.last else {
            print("没有有效的位置信息")
            if !hasResumedContinuation, let continuation = locationContinuation {
                hasResumedContinuation = true
                continuation.resume(throwing: LocationError.locationUnavailable)
                locationContinuation = nil
            }
            cleanupCurrentRequest()
            return
        }
        
        print("位置信息：纬度 \(location.coordinate.latitude), 经度 \(location.coordinate.longitude)")
        currentLocation = location
        
        // 获取城市名称
        print("开始反向地理编码...")
        geocoder = CLGeocoder()
        geocoder?.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            if let error = error {
                print("反向地理编码失败：\(error.localizedDescription)")
                self.locationError = error
                if !self.hasResumedContinuation, let continuation = self.locationContinuation {
                    self.hasResumedContinuation = true
                    continuation.resume(throwing: LocationError.geocodingFailed)
                    self.locationContinuation = nil
                }
                self.cleanupCurrentRequest()
                return
            }
            
            if let city = placemarks?.first?.locality {
                print("成功获取城市名称：\(city)")
                Task { @MainActor in
                    self.currentCity = city
                    // 立即恢复continuation，不等待清理
                    if !self.hasResumedContinuation, let continuation = self.locationContinuation {
                        self.hasResumedContinuation = true
                        continuation.resume()
                        self.locationContinuation = nil
                    }
                }
            } else if let placemark = placemarks?.first,
                      let adminArea = placemark.administrativeArea {
                print("未能获取城市名称，使用行政区域：\(adminArea)")
                Task { @MainActor in
                    self.currentCity = adminArea
                    // 立即恢复continuation，不等待清理
                    if !self.hasResumedContinuation, let continuation = self.locationContinuation {
                        self.hasResumedContinuation = true
                        continuation.resume()
                        self.locationContinuation = nil
                    }
                }
            } else {
                print("未能获取任何有效的地理位置信息")
                if !self.hasResumedContinuation, let continuation = self.locationContinuation {
                    self.hasResumedContinuation = true
                    continuation.resume(throwing: LocationError.geocodingFailed)
                    self.locationContinuation = nil
                }
                self.cleanupCurrentRequest()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("\n=== 位置更新失败 ===")
        print("错误详情：\(error.localizedDescription)")
        if let error = error as? CLError {
            print("CLError代码：\(error.code.rawValue)")
            switch error.code {
            case .denied:
                print("位置权限被拒绝")
            case .locationUnknown:
                print("位置未知")
            case .network:
                print("网络错误")
            default:
                print("其他CoreLocation错误")
            }
        }
        locationError = error
        if !hasResumedContinuation, let continuation = locationContinuation {
            hasResumedContinuation = true
            continuation.resume(throwing: error)
            locationContinuation = nil
        }
        cleanupCurrentRequest()
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
