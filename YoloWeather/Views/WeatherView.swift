import SwiftUI
import CoreLocation

struct WeatherView: View {
    @StateObject private var weatherService = WeatherService()
    @StateObject private var locationService = LocationService()
    @State private var selectedLocation: PresetLocation = PresetLocation.presets[0]
    @State private var showHourlyForecast = false
    @State private var showDailyForecast = false
    @State private var isAnimating = false
    
    private let hourFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            ZStack {
                TimeBasedBackground()
                
                if let currentWeather = weatherService.currentWeather {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            // Current Weather Section
                            CurrentWeatherView(
                                location: locationService.locationName.isEmpty ? selectedLocation.name : locationService.locationName,
                                weather: currentWeather,
                                isAnimating: isAnimating,
                                dailyForecast: weatherService.dailyForecast
                            )
                            
                            Spacer(minLength: 40)
                            
                            // Expandable Forecasts
                            VStack(spacing: 15) {
                                // Hourly Forecast Button
                                ExpandableWeatherSection(
                                    title: "Hourly Forecast",
                                    isExpanded: $showHourlyForecast
                                ) {
                                    if !weatherService.hourlyForecast.isEmpty {
                                        HourlyForecastView(
                                            forecast: weatherService.hourlyForecast,
                                            hourFormatter: hourFormatter
                                        )
                                    }
                                }
                                
                                // Daily Forecast Button
                                ExpandableWeatherSection(
                                    title: "7-Day Forecast",
                                    isExpanded: $showDailyForecast
                                ) {
                                    if !weatherService.dailyForecast.isEmpty {
                                        DailyForecastView(
                                            forecast: weatherService.dailyForecast,
                                            dayFormatter: dayFormatter
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 30)
                    }
                } else {
                    LoadingView(
                        isLoading: weatherService.isLoading,
                        error: weatherService.errorMessage
                    )
                }
            }
            .foregroundStyle(.white)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            locationService.requestLocationPermission()
                        } label: {
                            Label("使用当前位置", systemImage: "location.fill")
                        }
                        
                        Divider()
                        
                        ForEach(PresetLocation.presets) { location in
                            Button(location.name) {
                                selectedLocation = location
                                Task {
                                    await weatherService.requestWeatherData(for: location.location)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: locationService.currentLocation != nil ? "location.fill.circle.fill" : "location.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.white)
                            .font(.system(size: 28))
                    }
                }
            }
            .task {
                // 如果已经有位置权限，使用当前位置
                if locationService.authorizationStatus == .authorizedWhenInUse || 
                   locationService.authorizationStatus == .authorizedAlways {
                    locationService.requestLocationPermission()
                } else {
                    // 否则使用默认位置
                    await weatherService.requestWeatherData(for: selectedLocation.location)
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
            .onAppear {
                withAnimation(.spring(duration: 1.5)) {
                    isAnimating = true
                }
            }
        }
    }
}

#Preview {
    WeatherView()
}
