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
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("搜索城市", text: $searchText)
                        .textFieldStyle(.plain)
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top)
                
                // Current Location Button
                if searchText.isEmpty {
                    Button {
                        requestCurrentLocation()
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
                            }
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                }
                
                // City Grid
                if searchText.isEmpty {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(PresetLocation.presets) { location in
                                Button {
                                    selectedLocation = location
                                    isUsingCurrentLocation = false
                                    onLocationSelected(location.location)
                                    dismiss()
                                } label: {
                                    Text(location.name)
                                        .foregroundColor(.primary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(selectedLocation.id == location.id ? 
                                                    Color.blue.opacity(0.2) : 
                                                    Color(uiColor: .secondarySystemBackground))
                                        )
                                }
                            }
                        }
                        .padding()
                    }
                } else {
                    // Search Results
                    List {
                        ForEach(PresetLocation.presets.filter {
                            $0.name.localizedCaseInsensitiveContains(searchText)
                        }) { location in
                            Button {
                                selectedLocation = location
                                isUsingCurrentLocation = false
                                onLocationSelected(location.location)
                                dismiss()
                            } label: {
                                Text(location.name)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("选择城市")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .alert("位置访问错误", isPresented: $showLocationError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(locationErrorMessage)
        }
    }
    
    private func requestCurrentLocation() {
        Task {
            guard !isRequestingLocation else { return }
            isRequestingLocation = true
            
            do {
                // 尝试请求位置
                try await locationService.requestLocation()
                
                // 获取位置成功后的处理
                if let location = locationService.currentLocation,
                   let cityName = locationService.currentCity {
                    print("位置选择器: 成功获取位置 - \(cityName)")
                    let newLocation = PresetLocation(
                        name: cityName,
                        location: location,
                        timeZoneIdentifier: TimeZone.current.identifier
                    )
                    selectedLocation = newLocation
                    isUsingCurrentLocation = true
                    onLocationSelected(location)
                }
            } catch {
                print("位置选择器: 位置请求失败 - \(error.localizedDescription)")
                locationErrorMessage = "无法获取位置信息，请稍后重试"
                showLocationError = true
            }
            
            isRequestingLocation = false
        }
    }
}