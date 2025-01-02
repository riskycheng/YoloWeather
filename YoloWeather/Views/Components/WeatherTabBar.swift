import SwiftUI

struct WeatherTabBar: View {
    @Binding var selectedTab: TabBarItem
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabBarItem.allCases) { item in
                Button {
                    selectedTab = item
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.iconName)
                            .font(.title3)
                    }
                    .frame(maxWidth: .infinity)
                }
                .foregroundStyle(selectedTab == item ? .blue : .gray)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
}
