import SwiftUI
import CoreLocation

// 单独的列表项视图
private struct LocationRowView: View {
    let location: PresetLocation
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            Text(location.name)
                .font(.title3)
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
            
            Text("\(Int(round(location.currentTemperature ?? 0)))°")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

struct SavedLocationsView: View {
    @ObservedObject var citySearchService: CitySearchService
    @Binding var selectedLocation: PresetLocation
    let onLocationSelected: (CLLocation?) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.weatherTimeOfDay) private var timeOfDay
    
    var body: some View {
        List {
            ForEach(citySearchService.recentSearches) { location in
                LocationRowView(
                    location: location,
                    isSelected: selectedLocation.id == location.id,
                    onTap: {
                        selectedLocation = location
                        onLocationSelected(location.location)
                        dismiss()
                    }
                )
            }
            .onMove { from, to in
                citySearchService.recentSearches.move(fromOffsets: from, toOffset: to)
            }
            .onDelete { indexSet in
                citySearchService.recentSearches.remove(atOffsets: indexSet)
            }
        }
        .navigationTitle("收藏城市")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            EditButton()
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }
} 