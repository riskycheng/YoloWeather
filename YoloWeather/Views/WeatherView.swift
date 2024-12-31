import SwiftUI
import CoreLocation

struct WeatherView: View {
    @StateObject private var weatherService = WeatherService()
    @StateObject private var locationService = LocationService()
    @State private var selectedLocation: PresetLocation = PresetLocation.presets[0]
    @State private var showingLocationPicker = false
    
    var body: some View {
        ZStack {
            TimeBasedBackground()
            
            if let currentWeather = weatherService.currentWeather {
                VStack(spacing: 0) {
                    // Top section with main weather info
                    CurrentWeatherView(
                        location: locationService.locationName.isEmpty ? selectedLocation.name : locationService.locationName,
                        weather: currentWeather,
                        isAnimating: false,
                        dailyForecast: weatherService.dailyForecast
                    )
                    
                    Spacer()
                    
                    // Bottom section with hourly forecast
                    if !weatherService.hourlyForecast.isEmpty {
                        HourlyTemperatureTrendView(forecast: weatherService.hourlyForecast)
                            .padding(.vertical, 24)
                            .padding(.horizontal, 16)
                    }
                }
            } else {
                VStack {
                    LoadingView(
                        isLoading: weatherService.isLoading,
                        error: weatherService.errorMessage
                    )
                    
                    if !weatherService.isLoading {
                        Button("Select Location") {
                            showingLocationPicker = true
                        }
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .padding(.top, 20)
                    }
                }
            }
        }
        .sheet(isPresented: $showingLocationPicker) {
            NavigationView {
                List(PresetLocation.presets) { location in
                    Button(location.name) {
                        selectedLocation = location
                        Task {
                            await weatherService.requestWeatherData(for: location.location)
                        }
                        showingLocationPicker = false
                    }
                }
                .navigationTitle("Select Location")
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium])
        }
        .onAppear {
            if locationService.authorizationStatus == .authorizedWhenInUse {
                locationService.startUpdatingLocation()
            } else {
                // If location services are not authorized, use the default location
                Task {
                    await weatherService.requestWeatherData(for: selectedLocation.location)
                }
            }
        }
        .onChange(of: locationService.currentLocation) { newLocation in
            if let location = newLocation {
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
    }
}

#Preview {
    WeatherView()
}
