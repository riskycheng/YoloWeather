import SwiftUI
import CoreLocation

struct CityPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.weatherTimeOfDay) private var timeOfDay
    let onLocationSelected: (PresetLocation) -> Void
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(PresetLocation.presets) { location in
                        Button {
                            onLocationSelected(location)
                            dismiss()
                        } label: {
                            CityCell(name: location.name)
                        }
                    }
                }
                .padding()
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
            .background(Color.black.opacity(0.1))
        }
    }
}

struct CityCell: View {
    let name: String
    @Environment(\.weatherTimeOfDay) private var timeOfDay
    
    var body: some View {
        Text(name)
            .font(.title3)
            .fontWeight(.medium)
            .foregroundStyle(WeatherThemeManager.shared.textColor(for: timeOfDay))
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background {
                RoundedRectangle(cornerRadius: 15)
                    .fill(.ultraThinMaterial)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 15)
                    .stroke(LinearGradient(
                        colors: [.white.opacity(0.5), .white.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ), lineWidth: 1)
            }
    }
}

#Preview {
    CityPickerView { location in
        print("Selected: \(location.name)")
    }
    .environment(\.weatherTimeOfDay, .day)
}
