import SwiftUI

struct HourlyForecastView: View {
    let forecast: [WeatherInfo]
    let hourFormatter: DateFormatter
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 25) {
                ForEach(forecast, id: \.date) { weather in
                    VStack(spacing: 12) {
                        Text(hourFormatter.string(from: weather.date))
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        
                        Image(systemName: weather.symbolName)
                            .symbolRenderingMode(.multicolor)
                            .font(.title2)
                        
                        Text("\(Int(round(weather.temperature)))°")
                            .font(.title3)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct DailyForecastView: View {
    let forecast: [DayWeatherInfo]
    let dayFormatter: DateFormatter
    
    var body: some View {
        VStack(spacing: 15) {
            ForEach(forecast, id: \.date) { weather in
                HStack {
                    Text(dayFormatter.string(from: weather.date))
                        .frame(width: 45, alignment: .leading)
                    
                    Image(systemName: weather.symbolName)
                        .symbolRenderingMode(.multicolor)
                        .frame(width: 30)
                    
                    Spacer()
                    
                    Text("\(Int(round(weather.lowTemperature)))°")
                        .foregroundStyle(.secondary)
                        .frame(width: 35, alignment: .trailing)
                    
                    TemperatureBar(low: weather.lowTemperature,
                                 high: weather.highTemperature)
                        .frame(width: 80, height: 4)
                    
                    Text("\(Int(round(weather.highTemperature)))°")
                        .frame(width: 35, alignment: .trailing)
                }
                .font(.callout)
            }
        }
        .padding(.horizontal)
    }
}

struct ExpandableWeatherSection<Content: View>: View {
    let title: String
    @Binding var isExpanded: Bool
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack {
            Button {
                withAnimation(.spring(duration: 0.5)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(title)
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 15))
            }
            
            if isExpanded {
                content()
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 5)
            }
        }
    }
}
