import SwiftUI

struct ClothingRecommendationView: View {
    let recommendation: ClothingRecommendation
    let isAnimating: Bool
    
    var body: some View {
        VStack(spacing: 15) {
            // 3D Character Model
            CharacterModelView(
                modelName: recommendation.modelName,
                isAnimating: isAnimating
            )
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            
            // Outfit recommendation with slide animation
            Text(recommendation.outfit)
                .font(.title2.bold())
                .foregroundStyle(.primary)
                .opacity(isAnimating ? 1 : 0)
                .offset(x: isAnimating ? 0 : -50)
            
            // Description with fade animation
            Text(recommendation.description)
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .opacity(isAnimating ? 1 : 0)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(radius: 10)
        }
        .padding(.horizontal)
    }
}
