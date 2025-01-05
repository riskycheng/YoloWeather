import SwiftUI

struct RefreshableView<Content: View>: View {
    let content: Content
    let onRefresh: () async -> Void
    @Binding var isRefreshing: Bool
    @Environment(\.weatherTimeOfDay) private var timeOfDay
    @State private var dragOffset: CGFloat = 0
    @State private var rotationAngle: Double = 0
    @State private var showRefreshView: Bool = false
    private let refreshThreshold: CGFloat = 100
    
    init(isRefreshing: Binding<Bool>,
         onRefresh: @escaping () async -> Void,
         @ViewBuilder content: () -> Content) {
        self.content = content()
        self.onRefresh = onRefresh
        self._isRefreshing = isRefreshing
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                content
                    .offset(y: max(dragOffset, 0))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if !isRefreshing {
                                    dragOffset = value.translation.height
                                    rotationAngle = Double(dragOffset / refreshThreshold) * 360
                                }
                            }
                            .onEnded { value in
                                if dragOffset > refreshThreshold && !isRefreshing {
                                    withAnimation {
                                        showRefreshView = true
                                        dragOffset = 60
                                    }
                                    Task {
                                        await onRefresh()
                                        withAnimation {
                                            showRefreshView = false
                                            dragOffset = 0
                                        }
                                    }
                                } else {
                                    withAnimation {
                                        dragOffset = 0
                                    }
                                }
                            }
                    )
                
                if dragOffset > 0 || showRefreshView {
                    VStack(spacing: 12) {
                        ZStack {
                            // Glowing effect
                            Circle()
                                .fill(timeOfDay == .day ? Color.yellow.opacity(0.3) : Color.white.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .blur(radius: 10)
                            
                            Group {
                                if timeOfDay == .night {
                                    // Night mode - use full_moon animation
                                    Image("full_moon")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 32, height: 32)
                                        .rotationEffect(.degrees(rotationAngle))
                                } else {
                                    // Day mode - use sunny animation
                                    Image("sunny")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 32, height: 32)
                                        .rotationEffect(.degrees(rotationAngle))
                                }
                            }
                            .onAppear {
                                if showRefreshView {
                                    withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                                        rotationAngle = 360
                                    }
                                }
                            }
                        }
                        
                        Text("正在刷新...")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .opacity(showRefreshView ? 0.9 : 0.0)
                    }
                    .frame(width: 100, height: 100)
                    .offset(y: dragOffset > 0 ? dragOffset - 100 : -100)
                }
            }
        }
    }
}
