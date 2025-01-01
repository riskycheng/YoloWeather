import Foundation
import CoreLocation

struct PresetLocation: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let location: CLLocation
    
    static func == (lhs: PresetLocation, rhs: PresetLocation) -> Bool {
        lhs.id == rhs.id
    }
    
    static let presets: [PresetLocation] = [
        PresetLocation(name: "上海市", location: CLLocation(latitude: 31.2304, longitude: 121.4737)),
        PresetLocation(name: "北京市", location: CLLocation(latitude: 39.9042, longitude: 116.4074)),
        PresetLocation(name: "香港", location: CLLocation(latitude: 22.3193, longitude: 114.1694)),
        PresetLocation(name: "东京", location: CLLocation(latitude: 35.6762, longitude: 139.6503)),
        PresetLocation(name: "新加坡", location: CLLocation(latitude: 1.3521, longitude: 103.8198)),
        PresetLocation(name: "旧金山", location: CLLocation(latitude: 37.7749, longitude: -122.4194)),
        PresetLocation(name: "冰岛", location: CLLocation(latitude: 64.9631, longitude: -19.0208))
    ]
}
