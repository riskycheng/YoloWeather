import Foundation

extension Notification.Name {
    static let updateWeatherTimeOfDay = Notification.Name("updateWeatherTimeOfDay")
    static let weatherDataDidUpdate = Notification.Name("weatherDataDidUpdate")
}

extension Notification {
    var value: Any? {
        return userInfo?["value"]
    }
}

extension NotificationCenter {
    func post(name: Notification.Name, value: Any?) {
        post(name: name, object: nil, userInfo: ["value": value as Any])
    }
} 