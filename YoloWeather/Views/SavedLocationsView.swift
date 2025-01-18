import SwiftUI
import CoreLocation

struct SavedLocationsView: View {
    @ObservedObject var citySearchService: CitySearchService
    @Binding var selectedLocation: PresetLocation
    let onLocationSelected: (CLLocation?) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.weatherTimeOfDay) private var timeOfDay
    @State private var editMode = EditMode.inactive
    @State private var selectedForDelete: PresetLocation?
    @State private var showingDeleteAlert = false
    @GestureState private var isDetectingLongPress = false
    @State private var completedLongPress = false
    
    var body: some View {
        List {
            ForEach(citySearchService.recentSearches) { location in
                Button(action: {
                    print("Button tapped for: \(location.name)")
                    if !completedLongPress {
                        selectedLocation = location
                        onLocationSelected(location.location)
                        dismiss()
                    }
                }) {
                    locationRow(for: location)
                }
                .buttonStyle(PlainButtonStyle())
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .updating($isDetectingLongPress) { currentState, gestureState, transaction in
                            print("Long press updating for: \(location.name), state: \(currentState)")
                            gestureState = currentState
                        }
                        .onEnded { _ in
                            print("Long press ended for: \(location.name)")
                            completedLongPress = true
                            selectedForDelete = location
                            showingDeleteAlert = true
                            
                            // 重置状态
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                completedLongPress = false
                            }
                        }
                )
                .scaleEffect(isDetectingLongPress ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isDetectingLongPress)
                .listRowBackground(Color.clear)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        print("Swipe delete action triggered for: \(location.name)")
                        deleteLocation(location)
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                }
            }
            .onMove { from, to in
                print("Move action triggered from: \(from) to: \(to)")
                citySearchService.recentSearches.move(fromOffsets: from, toOffset: to)
            }
        }
        .navigationTitle("收藏城市")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            EditButton()
        }
        .environment(\.editMode, $editMode)
        .background(Color(uiColor: .systemGroupedBackground))
        .alert("删除城市", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { 
                print("Delete cancelled for: \(selectedForDelete?.name ?? "unknown")")
            }
            Button("删除", role: .destructive) {
                if let location = selectedForDelete {
                    print("Delete confirmed for: \(location.name)")
                    deleteLocation(location)
                }
            }
        } message: {
            if let location = selectedForDelete {
                Text("确定要删除\(location.name)吗？")
            }
        }
    }
    
    private func locationRow(for location: PresetLocation) -> some View {
        HStack {
            Text(location.name)
                .font(.title3)
                .padding(.leading, 16)
            
            Spacer()
            
            if selectedLocation.id == location.id {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
            
            Text("\(Int(round(location.currentTemperature ?? 0)))°")
                .font(.title3)
                .foregroundStyle(.secondary)
                .padding(.trailing, 16)
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
    
    private func deleteLocation(_ location: PresetLocation) {
        print("Deleting location: \(location.name)")
        if let index = citySearchService.recentSearches.firstIndex(where: { $0.id == location.id }) {
            citySearchService.recentSearches.remove(at: index)
            print("Successfully deleted location at index: \(index)")
        }
        selectedForDelete = nil
    }
} 