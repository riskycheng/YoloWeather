import Foundation

struct ClothingRecommendation {
    let outfit: String
    let description: String
    let modelName: String  // Name of the 3D model file
    
    static func getRecommendation(temperature: Double, condition: String) -> ClothingRecommendation {
        // Temperature ranges for different clothing recommendations
        switch temperature {
        case ...5:  // Very cold
            return ClothingRecommendation(
                outfit: "冬季全套",
                description: "今天很冷，建议穿羽绒服、围巾、帽子和保暖靴子",
                modelName: "character_winter"
            )
        case 5..<10:  // Cold
            return ClothingRecommendation(
                outfit: "厚外套",
                description: "天气较冷，建议穿厚外套、毛衣和长裤",
                modelName: "character_coat"
            )
        case 10..<15:  // Cool
            return ClothingRecommendation(
                outfit: "轻便外套",
                description: "温度适中偏凉，建议穿夹克或轻便外套",
                modelName: "character_jacket"
            )
        case 15..<20:  // Mild
            return ClothingRecommendation(
                outfit: "长袖衣服",
                description: "天气舒适，建议穿长袖衬衫或薄毛衣",
                modelName: "character_longsleeve"
            )
        case 20..<25:  // Warm
            return ClothingRecommendation(
                outfit: "短袖",
                description: "天气温暖，建议穿短袖T恤和轻便裤子",
                modelName: "character_tshirt"
            )
        case 25..<30:  // Hot
            return ClothingRecommendation(
                outfit: "清凉装扮",
                description: "天气炎热，建议穿轻薄透气的衣服",
                modelName: "character_summer"
            )
        default:  // Very hot
            return ClothingRecommendation(
                outfit: "防晒装备",
                description: "非常热，请注意防晒，穿轻薄透气的衣物",
                modelName: "character_sunprotect"
            )
        }
    }
}
