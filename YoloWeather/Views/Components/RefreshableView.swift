import SwiftUI

struct RefreshableView<Content: View>: View {
    let content: Content
    let onRefresh: () async -> Void
    @Binding var isRefreshing: Bool
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
                                        dragOffset = 80 // 保持刷新视图可见
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
                    VStack(spacing: 8) {
                        ZStack {
                            // 背景光晕
                            Circle()
                                .fill(.white.opacity(0.15))
                                .frame(width: 60, height: 60)
                                .blur(radius: 5)
                            
                            if showRefreshView {
                                // 刷新动画
                                ZStack {
                                    // 旋转的云
                                    Image("cloudy")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 32, height: 32)
                                        .rotationEffect(.degrees(rotationAngle))
                                    
                                    // 闪电效果
                                    Image("lightning")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)
                                        .opacity(sin(rotationAngle * .pi / 180) * 0.8 + 0.2)
                                        .offset(x: 4, y: 4)
                                }
                                .onAppear {
                                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                                        rotationAngle = 360
                                    }
                                }
                            } else {
                                // 下拉时的动画
                                ZStack {
                                    Image("sunny")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 32, height: 32)
                                        .rotationEffect(.degrees(rotationAngle))
                                        .scaleEffect(min(dragOffset / refreshThreshold, 1.0))
                                    
                                    Image("cloud")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 32, height: 32)
                                        .opacity(min(dragOffset / refreshThreshold, 1.0))
                                        .offset(x: min(dragOffset / 2, 20), y: 0)
                                }
                            }
                        }
                        
                        if !showRefreshView {
                            Text(dragOffset > refreshThreshold ? "释放刷新" : "下拉刷新")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    .frame(width: 80, height: 80)
                    .offset(y: dragOffset > 0 ? dragOffset - 80 : -80)
                }
            }
        }
    }
}
