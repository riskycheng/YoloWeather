import SwiftUI
import CoreLocation

struct LocationPickerView: View {
    @Binding var selectedLocation: PresetLocation
    let locationService: LocationService
    @Binding var isUsingCurrentLocation: Bool
    let onLocationSelected: (CLLocation?) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var isRequestingLocation = false
    @State private var showLocationError = false
    @State private var locationErrorMessage = ""
    
    private let predefinedLocations = [
        "北京市",
        "上海市",
        "广州市",
        "深圳市",
        "杭州市",
        "成都市",
        "武汉市",
        "西安市",
        "南京市",
        "重庆市",
        "冰岛"
    ]
    
    var filteredLocations: [PresetLocation] {
        if searchText.isEmpty {
            return PresetLocation.presets
        }
        return PresetLocation.presets.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        List {
            Section {
                Button {
                    Task {
                        // 防止重复请求
                        guard !isRequestingLocation else { return }
                        isRequestingLocation = true
                        
                        // 检查权限状态
                        switch locationService.authorizationStatus {
                        case .notDetermined:
                            // 首次请求权限
                            locationService.requestLocationPermission()
                            // 等待用户授权
                            try? await Task.sleep(nanoseconds: 1_000_000_000)
                            
                        case .denied, .restricted:
                            // 用户拒绝或受限
                            locationErrorMessage = "请在设置中允许访问位置信息"
                            showLocationError = true
                            isRequestingLocation = false
                            return
                            
                        case .authorizedWhenInUse, .authorizedAlways:
                            break
                            
                        @unknown default:
                            return
                        }
                        
                        // 开始更新位置
                        locationService.startUpdatingLocation()
                        
                        // 等待位置更新（最多5秒）
                        for _ in 0..<5 {
                            if let location = locationService.currentLocation {
                                await MainActor.run {
                                    isUsingCurrentLocation = true
                                    onLocationSelected(location)
                                    dismiss()
                                }
                                return
                            }
                            try? await Task.sleep(nanoseconds: 1_000_000_000)
                        }
                        
                        // 超时处理
                        await MainActor.run {
                            locationErrorMessage = "获取位置信息超时，请重试"
                            showLocationError = true
                            isRequestingLocation = false
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundStyle(.blue)
                        Text("使用当前位置")
                            .foregroundStyle(.primary)
                        Spacer()
                        if isUsingCurrentLocation && locationService.currentLocation != nil {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        } else if isRequestingLocation {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }
                .disabled(locationService.authorizationStatus == .denied || 
                         locationService.authorizationStatus == .restricted)
            }
            
            Section("已保存的位置") {
                ForEach(filteredLocations) { location in
                    Button {
                        selectedLocation = location
                        onLocationSelected(nil)
                        dismiss()
                    } label: {
                        HStack {
                            Text(location.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            if location.id == selectedLocation.id && !isUsingCurrentLocation {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("选择位置")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "搜索城市")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("完成") {
                    dismiss()
                }
            }
        }
        .alert("位置获取失败", isPresented: $showLocationError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(locationErrorMessage)
        }
    }
} 