import SwiftUI
import CoreLocation

struct WeatherView: View {
    @StateObject private var weatherService = WeatherService.shared
    @StateObject private var locationService = LocationService()
    @State private var selectedLocation: PresetLocation = PresetLocation.presets[0]
    @State private var showingLocationPicker = false
    @State private var isRefreshing = false
    @State private var lastRefreshTime: Date = Date()
    @State private var isUsingCurrentLocation = false
    @State private var timeOfDay: WeatherTimeOfDay = .night
    @AppStorage("showDailyForecast") private var showDailyForecast = false
    
    private func updateTimeOfDay() {
        if let weather = weatherService.currentWeather {
            timeOfDay = WeatherThemeManager.shared.determineTimeOfDay(for: Date(), in: weather.timezone)
        }
    }
    
    private func refreshWeather() async {
        isRefreshing = true
        defer { isRefreshing = false }
        
        if let location = locationService.currentLocation {
            await weatherService.updateWeather(for: location)
            lastRefreshTime = Date()
            updateTimeOfDay()
        }
    }
    
    private func updateLocation(_ location: CLLocation?) async {
        if let location = location {
            isUsingCurrentLocation = true
            locationService.currentLocation = location
            await weatherService.updateWeather(for: location)
        } else {
            isUsingCurrentLocation = false
            locationService.locationName = selectedLocation.name
            locationService.currentLocation = selectedLocation.location
            await weatherService.updateWeather(for: selectedLocation.location)
        }
        lastRefreshTime = Date()
        updateTimeOfDay()
    }
    
    var body: some View {
        ZStack {
            // 背景渐变
            WeatherBackgroundView(timeOfDay: timeOfDay)
            
            VStack(spacing: 0) {
                // Top bar with controls
                HStack(spacing: 20) {
                    // Left controls
                    HStack(spacing: 12) {
                        Button(action: {
                            Task {
                                if let location = locationService.currentLocation {
                                    await updateLocation(location)
                                }
                            }
                        }) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(.brown)
                                .frame(width: 44, height: 44)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        
                        Button(action: {
                            showingLocationPicker = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 22))
                                .foregroundStyle(.brown)
                                .frame(width: 44, height: 44)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                    }
                    
                    Spacer()
                    
                    // Right control - Day/Night toggle
                    Button(action: {
                        withAnimation {
                            timeOfDay = timeOfDay == .day ? .night : .day
                        }
                    }) {
                        Image(systemName: timeOfDay == .day ? "sun.max.fill" : "moon.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(timeOfDay == .day ? .yellow : .gray)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                // Weather information
                VStack(spacing: 8) {
                    // Location name
                    Text(locationService.locationName)
                        .font(.system(size: 34, weight: .medium))
                        .foregroundStyle(.primary)
                    
                    if let weather = weatherService.currentWeather {
                        // Weather condition
                        Text(weather.condition)
                            .font(.system(size: 20))
                            .foregroundStyle(.secondary)
                        
                        // Large temperature display
                        Text("\(Int(round(weather.temperature)))°")
                            .font(.system(size: 120, weight: .thin))
                            .foregroundStyle(.primary)
                            .padding(.top, -20)
                    }
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Hourly forecast
                if !weatherService.hourlyForecast.isEmpty {
                    HourlyTemperatureTrendView(forecast: weatherService.hourlyForecast)
                        .frame(height: 100)
                        .padding(.horizontal)
                        .padding(.bottom, 30)
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
                            await updateLocation(location)
                            showingLocationPicker = false
                        }
                    }
                )
            }
        }
        .task {
            await updateLocation(selectedLocation.location)
        }
        .onChange(of: selectedLocation) { oldValue, newValue in
            Task {
                await updateLocation(selectedLocation.location)
            }
        }
    }
    
    @ViewBuilder
    private func toolbarButton(_ systemName: String) -> some View {
        let textColor = WeatherThemeManager.shared.textColor(for: timeOfDay)
        Image(systemName: systemName)
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(textColor)
            .frame(width: 44, height: 44)
            .background {
                Circle()
                    .fill(.black.opacity(0.3))
                    .overlay {
                        Circle()
                            .stroke(textColor.opacity(0.3), lineWidth: 1)
                    }
            }
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}
