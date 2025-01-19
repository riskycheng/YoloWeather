import SwiftUI
import WeatherKit

struct WeatherIndicator: Identifiable {
    let id = UUID()
    let title: String
    var isSelected: Bool
    let type: WeatherIndicatorType
}

enum WeatherIndicatorType {
    case humidity
    case windSpeed
    case precipitationChance
    case uvIndex
    case pressure
    case visibility
}

class WeatherIndicatorViewModel: ObservableObject {
    @Published var indicators: [WeatherIndicator] = [
        WeatherIndicator(title: "湿度", isSelected: false, type: .humidity),
        WeatherIndicator(title: "风速", isSelected: true, type: .windSpeed),
        WeatherIndicator(title: "降水概率", isSelected: false, type: .precipitationChance),
        WeatherIndicator(title: "紫外线", isSelected: false, type: .uvIndex),
        WeatherIndicator(title: "气压", isSelected: true, type: .pressure),
        WeatherIndicator(title: "能见度", isSelected: false, type: .visibility)
    ]
    
    func toggleIndicator(_ type: WeatherIndicatorType) {
        if let index = indicators.firstIndex(where: { $0.type == type }) {
            indicators[index].isSelected.toggle()
        }
    }
}

struct WeatherIndicatorSelectionView: View {
    @StateObject private var viewModel = WeatherIndicatorViewModel()
    @Environment(\.colorScheme) private var colorScheme
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("显示指标")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal)
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.indicators) { indicator in
                    Button(action: {
                        viewModel.toggleIndicator(indicator.type)
                    }) {
                        HStack {
                            Text(indicator.title)
                                .foregroundColor(.primary)
                            Spacer()
                            if indicator.isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Circle()
                                    .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1.5)
                                    .frame(width: 22, height: 22)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
} 