import Foundation

// 扩展 Bundle 来提供配置信息
extension Bundle {
    // 位置权限描述
    var locationWhenInUseUsageDescription: String {
        return "需要访问您的位置以提供准确的天气信息"
    }
    
    var locationAlwaysAndWhenInUseUsageDescription: String {
        return "需要访问您的位置以提供准确的天气信息"
    }
}
