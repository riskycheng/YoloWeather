import Foundation
import CoreLocation

struct PresetLocation: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    
    var location: CLLocation {
        CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
    
    static let presets: [PresetLocation] = [
        PresetLocation(name: "Shanghai", coordinate: CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737)),
        PresetLocation(name: "Beijing", coordinate: CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074)),
        PresetLocation(name: "Hong Kong", coordinate: CLLocationCoordinate2D(latitude: 22.3193, longitude: 114.1694)),
        PresetLocation(name: "Tokyo", coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)),
        PresetLocation(name: "Singapore", coordinate: CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198)),
        PresetLocation(name: "San Francisco", coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)),
        PresetLocation(name: "New York", coordinate: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)),
        PresetLocation(name: "London", coordinate: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278))
    ]
}
