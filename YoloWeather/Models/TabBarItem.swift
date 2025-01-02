import Foundation

enum TabBarItem: Int, CaseIterable, Identifiable {
    case weather
    case wind
    case thunder
    case profile
    
    var id: Int { rawValue }
    
    var iconName: String {
        switch self {
        case .weather:
            return "cloud.fill"
        case .wind:
            return "wind"
        case .thunder:
            return "bolt.fill"
        case .profile:
            return "person.fill"
        }
    }
}
