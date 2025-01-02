import SwiftUI

struct WeatherHeaderView: View {
    let locationName: String
    let timeOfDay: WeatherTimeOfDay
    let onLocationTap: () -> Void
    
    var body: some View {
        HStack {
            Text(locationName)
                .font(.title2.bold())
            
            Spacer()
            
            Button {
                onLocationTap()
            } label: {
                Image(systemName: "location.circle.fill")
                    .font(.title2)
            }
        }
        .foregroundStyle(WeatherThemeManager.shared.textColor(for: timeOfDay))
        .padding(.horizontal)
    }
}
