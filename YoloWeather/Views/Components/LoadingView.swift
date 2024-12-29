import SwiftUI

struct LoadingView: View {
    let isLoading: Bool
    let error: String?
    
    var body: some View {
        VStack(spacing: 20) {
            if isLoading {
                ProgressView()
                    .scaleEffect(2)
                    .tint(.white)
            }
            
            Text(isLoading ? "Fetching weather..." :
                    error ?? "Select a location")
                .foregroundStyle(.secondary)
                .font(.title3)
        }
    }
}
