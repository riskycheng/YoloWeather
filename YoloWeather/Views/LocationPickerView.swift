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
            
            switch locationService.authorizationStatus {
            case .notDetermined:
                locationService.requestLocationPermission()
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                
            case .denied, .restricted:
                locationErrorMessage = "请在设置中允许访问位置信息"
                showLocationError = true
                isRequestingLocation = false
                return
                
            case .authorizedWhenInUse, .authorizedAlways:
                break
                
            @unknown default:
                return
            }
            
            locationService.startUpdatingLocation()
            
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
            
            await MainActor.run {
                locationErrorMessage = "获取位置信息超时，请重试"
                showLocationError = true
                isRequestingLocation = false
            }
        }
    }
}