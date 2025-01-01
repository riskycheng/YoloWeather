import SwiftUI

struct TemperatureRangeView: View {
    let lowTemp: Double
    let highTemp: Double
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.down")
                .imageScale(.small)
                .foregroundStyle(.white.opacity(0.9))
            
            Text("\(Int(round(lowTemp)))°")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.white)
            
            Text("—")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, 8)
            
            Image(systemName: "arrow.up")
                .imageScale(.small)
                .foregroundStyle(.white.opacity(0.9))
            
            Text("\(Int(round(highTemp)))°")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background {
            Capsule()
                .fill(.black.opacity(0.3))
        }
        .overlay {
            Capsule()
                .stroke(LinearGradient(
                    colors: [.white.opacity(0.5), .white.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

struct LocationHeaderView: View {
    let location: String
    let isLoading: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "location.fill")
                .imageScale(.small)
                .foregroundStyle(.white.opacity(0.9))
            
            if isLoading {
                Text("正在获取位置...")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .transition(.opacity)
            } else {
                Text(location)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
                    .transition(.opacity)
            }
        }
        .frame(height: 44)
        .padding(.horizontal, 16)
        .background {
            Capsule()
                .fill(.black.opacity(0.3))
                .overlay {
                    Capsule()
                        .stroke(.white.opacity(0.3), lineWidth: 1)
                }
        }
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        .animation(.easeInOut, value: isLoading)
    }
}

struct CurrentWeatherView: View {
    let weather: CurrentWeather
    @ObservedObject private var tagManager = WeatherTagManager.shared
    @Environment(\.weatherTimeOfDay) private var timeOfDay
    
    private var temperatureText: String {
        "\(Int(round(weather.temperature)))"
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // 主温度显示
            VStack(spacing: 8) {
                // 大数字温度显示
                Text(temperatureText)
                    .font(.system(size: 96, weight: .medium, design: .monospaced))
                    .foregroundColor(WeatherThemeManager.shared.textColor(for: timeOfDay))
                    .frame(height: 120)
                    .padding(.vertical, 16)
                    .background {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.black.opacity(0.2))
                    }
                
                // 天气描述
                Text(weather.condition)
                    .font(.title2)
                    .foregroundColor(WeatherThemeManager.shared.textColor(for: timeOfDay))
            }
            
            // 可配置的天气标签
            VStack(spacing: 12) {
                ForEach(tagManager.activeTags) { tag in
                    WeatherTagView(weather: weather, tag: tag)
                        .transition(.opacity)
                }
            }
            
            // 编辑按钮
            Button {
                withAnimation {
                    tagManager.isEditMode.toggle()
                }
            } label: {
                Label(tagManager.isEditMode ? "完成" : "编辑标签", systemImage: tagManager.isEditMode ? "checkmark.circle.fill" : "pencil.circle")
                    .font(.headline)
                    .foregroundColor(WeatherThemeManager.shared.textColor(for: timeOfDay))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background {
                        Capsule()
                            .fill(.black.opacity(0.2))
                    }
            }
            
            if tagManager.isEditMode {
                // 可用标签列表
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(WeatherTag.allCases) { tag in
                            Button {
                                withAnimation {
                                    tagManager.toggleTag(tag)
                                }
                            } label: {
                                Text(tag.name)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background {
                                        Capsule()
                                            .fill(tagManager.activeTags.contains(tag) ? .green.opacity(0.3) : .gray.opacity(0.3))
                                    }
                                    .foregroundColor(WeatherThemeManager.shared.textColor(for: timeOfDay))
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct CurrentWeatherView_Previews: PreviewProvider {
    static var previews: some View {
        CurrentWeatherView(weather: CurrentWeather.mock(temp: 23, condition: "晴", symbol: "sun.max"))
            .background(Color.blue)
    }
}

#Preview {
    ZStack {
        Color.black
        CurrentWeatherView(weather: CurrentWeather(
            date: Date(),
            temperature: 25,
            feelsLike: 28,
            condition: "Sunny",
            symbolName: "sun.max.fill",
            windSpeed: 3.4,
            precipitationChance: 0.2,
            uvIndex: 5,
            humidity: 0.65,
            pressure: 1013,
            visibility: 10,
            airQualityIndex: 75,
            timezone: TimeZone(identifier: "Asia/Shanghai") ?? TimeZone.current
        ))
    }
}
