import Foundation
import CoreLocation

struct City: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let location: CLLocation
    
    static let chengdu = City(
        name: "成都",
        location: CLLocation(latitude: 30.572815, longitude: 104.066801)
    )
    
    static let beijing = City(
        name: "北京",
        location: CLLocation(latitude: 39.904202, longitude: 116.407394)
    )
    
    static let shanghai = City(
        name: "上海",
        location: CLLocation(latitude: 31.230416, longitude: 121.473701)
    )
    
    static let guangzhou = City(
        name: "广州",
        location: CLLocation(latitude: 23.129110, longitude: 113.264381)
    )
    
    static let shenzhen = City(
        name: "深圳",
        location: CLLocation(latitude: 22.543096, longitude: 114.057865)
    )
    
    static let allCities = [chengdu, beijing, shanghai, guangzhou, shenzhen]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: City, rhs: City) -> Bool {
        lhs.id == rhs.id
    }
}
