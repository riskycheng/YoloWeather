import SwiftUI
import CoreLocation

struct WeatherView: View {
    @StateObject private var weatherService = WeatherService()
    @StateObject private var locationService = LocationService()
    @State private var selectedLocation: PresetLocation = PresetLocation.presets[0]
    @State private var showingLocationPicker = false
    @State private var isRefreshing = false
    @State private var lastRefreshTime: Date = Date()
    @State private var isUsingCurrentLocation = false
    
    private func refreshWeather() async {
        isRefreshing = true
        defer { isRefreshing = false }
        
        if isUsingCurrentLocation, let currentLocation = locationService.currentLocation {
            await weatherService.requestWeatherData(for: currentLocation)
        } else {
            locationService.locationName = selectedLocation.name
            await weatherService.requestWeatherData(for: selectedLocation.location)
        }
        lastRefreshTime = Date()
    }
    
    var body: some View {
        ZStack {
            TimeBasedBackground()
            
            VStack(spacing: 0) {
                // Top toolbar
                HStack(alignment: .center) {
                    Button {
                        showingLocationPicker = true
                    } label: {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background {
                                Circle()
                                    .fill(.black.opacity(0.3))
                                    .overlay {
                                        Circle()
                                            .stroke(.white.opacity(0.3), lineWidth: 1)
                                    }
                            }
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    
                    Spacer()
                    
                    Button {
                        Task {
                            await refreshWeather()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background {
                                Circle()
                                    .fill(.black.opacity(0.3))
                                    .overlay {
                                        Circle()
                                            .stroke(.white.opacity(0.3), lineWidth: 1)
                                    }
                            }
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                            .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                if let currentWeather = weatherService.currentWeather {
                    // Weather content
                    CurrentWeatherView(
                        location: locationService.locationName,
                        weather: currentWeather,
                        isLoading: weatherService.isLoading,
                        dailyForecast: weatherService.dailyForecast
                    )
                    .padding(.top, -44) // 向上移动位置文本，与按钮水平对齐
                    
                    // Bottom section with hourly forecast
                    if !weatherService.hourlyForecast.isEmpty {
                        HourlyTemperatureTrendView(forecast: weatherService.hourlyForecast)
                            .padding(.vertical, 24)
                            .padding(.horizontal, 16)
                    }
                } else {
                    Spacer()
                    WeatherLoadingView()
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showingLocationPicker) {
            NavigationView {
                LocationPickerView(
                    selectedLocation: $selectedLocation,
                    locationService: locationService,
                    isUsingCurrentLocation: $isUsingCurrentLocation,
                    onLocationSelected: { location in
                        Task {
                            if let location = location {
                                isUsingCurrentLocation = true
                                await weatherService.requestWeatherData(for: location)
                            } else {
                                isUsingCurrentLocation = false
                                locationService.locationName = selectedLocation.name
                                locationService.currentLocation = nil
                                await weatherService.requestWeatherData(for: selectedLocation.location)
                            }
                        }
                        showingLocationPicker = false
                    }
                )
            }
            .presentationDetents([.medium, .large])
        }
        .onAppear {
            if locationService.authorizationStatus == .authorizedWhenInUse {
                isUsingCurrentLocation = true
                locationService.startUpdatingLocation()
            } else {
                isUsingCurrentLocation = false
                locationService.locationName = selectedLocation.name
                Task {
                    await weatherService.requestWeatherData(for: selectedLocation.location)
                }
            }
        }
        .onChange(of: locationService.currentLocation) { newLocation in
            if isUsingCurrentLocation, let location = newLocation {
                Task {
                    await weatherService.requestWeatherData(for: location)
                }
            }
        }
        .alert("位置错误", isPresented: .constant(locationService.errorMessage != nil)) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(locationService.errorMessage ?? "")
        }
        .refreshable {
            await refreshWeather()
        }
    }
}

#Preview {
    WeatherView()
}
