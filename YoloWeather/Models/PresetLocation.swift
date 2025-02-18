import Foundation
import CoreLocation

struct PresetLocation: Identifiable, Codable, Hashable {
    private let _id: UUID
    var id: UUID { _id }
    let name: String
    let location: CLLocation
    let timeZoneIdentifier: String
    var currentTemperature: Double?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case latitude
        case longitude
        case timeZoneIdentifier
        case currentTemperature
    }
    
    init(name: String, location: CLLocation, timeZoneIdentifier: String = TimeZone.current.identifier, currentTemperature: Double? = nil) {
        self._id = UUID()
        self.name = name
        self.location = location
        self.timeZoneIdentifier = timeZoneIdentifier
        self.currentTemperature = currentTemperature
    }
    
    // 实现 Encodable
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(location.coordinate.latitude, forKey: .latitude)
        try container.encode(location.coordinate.longitude, forKey: .longitude)
        try container.encode(timeZoneIdentifier, forKey: .timeZoneIdentifier)
        try container.encode(currentTemperature, forKey: .currentTemperature)
    }
    
    // 实现 Decodable
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        location = CLLocation(latitude: latitude, longitude: longitude)
        timeZoneIdentifier = try container.decode(String.self, forKey: .timeZoneIdentifier)
        currentTemperature = try container.decode(Double?.self, forKey: .currentTemperature)
    }
    
    // 便捷访问坐标的计算属性
    var latitude: CLLocationDegrees {
        location.coordinate.latitude
    }
    
    var longitude: CLLocationDegrees {
        location.coordinate.longitude
    }
    
    // 实现 Hashable，只基于城市名称
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    // 实现 Equatable，只基于城市名称
    static func == (lhs: PresetLocation, rhs: PresetLocation) -> Bool {
        lhs.name == rhs.name
    }
    
    static let presets: [PresetLocation] = [
        PresetLocation(name: "上海市", location: CLLocation(latitude: 31.2304, longitude: 121.4737), timeZoneIdentifier: "Asia/Shanghai"),
        PresetLocation(name: "北京市", location: CLLocation(latitude: 39.9042, longitude: 116.4074), timeZoneIdentifier: "Asia/Shanghai"),
        PresetLocation(name: "香港", location: CLLocation(latitude: 22.3193, longitude: 114.1694), timeZoneIdentifier: "Asia/Hong_Kong"),
        PresetLocation(name: "东京", location: CLLocation(latitude: 35.6762, longitude: 139.6503), timeZoneIdentifier: "Asia/Tokyo"),
        PresetLocation(name: "新加坡", location: CLLocation(latitude: 1.3521, longitude: 103.8198), timeZoneIdentifier: "Asia/Singapore"),
        PresetLocation(name: "旧金山", location: CLLocation(latitude: 37.7749, longitude: -122.4194), timeZoneIdentifier: "America/Los_Angeles"),
        PresetLocation(name: "冰岛", location: CLLocation(latitude: 64.9631, longitude: -19.0208), timeZoneIdentifier: "Atlantic/Reykjavik")
    ]
}
