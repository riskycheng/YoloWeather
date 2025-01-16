import Foundation
import CoreLocation

struct PresetLocation: Identifiable, Codable, Hashable {
    private let _id: UUID
    var id: UUID { _id }
    let name: String
    let location: CLLocation
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case latitude
        case longitude
    }
    
    init(name: String, location: CLLocation) {
        self._id = UUID()
        self.name = name
        self.location = location
    }
    
    // 实现 Encodable
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(location.coordinate.latitude, forKey: .latitude)
        try container.encode(location.coordinate.longitude, forKey: .longitude)
    }
    
    // 实现 Decodable
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        location = CLLocation(latitude: latitude, longitude: longitude)
    }
    
    // 实现 Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(_id)
        hasher.combine(name)
        hasher.combine(location.coordinate.latitude)
        hasher.combine(location.coordinate.longitude)
    }
    
    // 实现 Equatable
    static func == (lhs: PresetLocation, rhs: PresetLocation) -> Bool {
        return lhs._id == rhs._id &&
               lhs.name == rhs.name &&
               lhs.location.coordinate.latitude == rhs.location.coordinate.latitude &&
               lhs.location.coordinate.longitude == rhs.location.coordinate.longitude
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
