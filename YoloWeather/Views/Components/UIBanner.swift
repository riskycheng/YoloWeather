import SwiftUI

enum UIBannerType {
    case success
    case error
    case warning
    case info
    
    var backgroundColor: Color {
        switch self {
        case .success: return Color.green.opacity(0.9)
        case .error: return Color.red.opacity(0.9)
        case .warning: return Color.orange.opacity(0.9)
        case .info: return Color.blue.opacity(0.9)
        }
    }
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

struct UIBanner: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let type: UIBannerType
}

class UIBannerPresenter: ObservableObject {
    static let shared = UIBannerPresenter()
    @Published var currentBanner: UIBanner?
    private var timer: Timer?
    
    private init() {}
    
    func show(_ banner: UIBanner) {
        currentBanner = banner
        // 3秒后自动隐藏
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            withAnimation {
                self?.currentBanner = nil
            }
        }
    }
}

struct UIBannerView: View {
    let banner: UIBanner
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: banner.type.icon)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(banner.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(banner.subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(banner.type.backgroundColor)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct BannerContainerView<Content: View>: View {
    @StateObject private var bannerPresenter = UIBannerPresenter.shared
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            content
            
            if let banner = bannerPresenter.currentBanner {
                VStack {
                    UIBannerView(banner: banner)
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    
                    Spacer()
                }
                .padding(.top, 44)
            }
        }
        .animation(.spring(), value: bannerPresenter.currentBanner != nil)
    }
} 