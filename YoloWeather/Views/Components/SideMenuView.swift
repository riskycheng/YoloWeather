import SwiftUI

struct SideMenuView: View {
    @Binding var isShowing: Bool
    @Binding var selectedLocation: PresetLocation
    let locations: [PresetLocation]
    var onLocationSelected: (PresetLocation) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .trailing) {
                if isShowing {
                    Color.black
                        .opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                isShowing = false
                            }
                        }
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("城市列表")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.top, 60)
                            .padding(.horizontal, 20)
                        
                        ScrollView {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(locations) { location in
                                    Button(action: {
                                        selectedLocation = location
                                        onLocationSelected(location)
                                        withAnimation {
                                            isShowing = false
                                        }
                                    }) {
                                        HStack {
                                            Text(location.name)
                                                .font(.title3)
                                                .foregroundColor(.white)
                                            
                                            Spacer()
                                            
                                            if selectedLocation.id == location.id {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 20)
                                    }
                                    
                                    Divider()
                                        .background(Color.white.opacity(0.2))
                                }
                            }
                            .padding(.top, 20)
                        }
                    }
                    .frame(width: min(geometry.size.width * 0.75, 300))
                    .background(
                        ZStack {
                            Color(red: 0.1, green: 0.1, blue: 0.2)  // 深色背景
                            
                            // 毛玻璃效果
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.1),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 0)
                    .transition(.move(edge: .trailing))
                    .gesture(
                        DragGesture()
                            .onEnded { gesture in
                                if gesture.translation.width > 50 {
                                    withAnimation(.easeInOut) {
                                        isShowing = false
                                    }
                                }
                            }
                    )
                }
            }
        }
    }
} 