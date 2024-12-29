import Foundation

struct ChineseCalendar {
    // 天干
    static let heavenlyStems = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"]
    // 地支
    static let earthlyBranches = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"]
    // 生肖
    static let zodiacAnimals = ["鼠", "牛", "虎", "兔", "龙", "蛇", "马", "羊", "猴", "鸡", "狗", "猪"]
    // 农历月份
    static let chineseMonths = ["正月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "冬月", "腊月"]
    // 农历日期
    static let chineseDays = ["初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
                             "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
                             "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"]
    
    struct ChineseDateComponents {
        let year: String  // 农历年份
        let month: String // 农历月份
        let day: String   // 农历日期
        let zodiac: String // 生肖
        let stemBranch: String // 干支纪年
    }
    
    // 获取农历信息
    static func getLunarDate(for date: Date = Date()) -> ChineseDateComponents {
        let calendar = Calendar(identifier: .chinese)
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        
        let year = components.year ?? 1
        let month = components.month ?? 1
        let day = components.day ?? 1
        
        // 计算生肖
        let zodiacIndex = (year - 1) % 12
        let zodiac = zodiacAnimals[zodiacIndex]
        
        // 计算干支纪年
        let stemIndex = (year - 1) % 10
        let branchIndex = (year - 1) % 12
        let stemBranch = "\(heavenlyStems[stemIndex])\(earthlyBranches[branchIndex])年"
        
        return ChineseDateComponents(
            year: String(year),
            month: chineseMonths[month - 1],
            day: chineseDays[day - 1],
            zodiac: zodiac,
            stemBranch: stemBranch
        )
    }
    
    // 获取今日宜忌
    static func getDailyAdvice(for date: Date = Date()) -> (suitable: [String], unsuitable: [String]) {
        // 基于日期的伪随机选择，这样每天的建议都是固定的
        let calendar = Calendar(identifier: .gregorian)
        let day = calendar.component(.day, from: date)
        
        let allSuitable = ["出行", "谈生意", "签合同", "装修", "开业", "结婚", "搬家", "旅游", "理财"]
        let allUnsuitable = ["动土", "开张", "交易", "入宅", "安葬", "诉讼", "开市", "动工"]
        
        // 使用日期作为随机种子
        var suitableItems: [String] = []
        var unsuitableItems: [String] = []
        
        // 选择3-4个宜做的事
        let suitableCount = 3 + (day % 2)
        for i in 0..<suitableCount {
            let index = (day + i) % allSuitable.count
            suitableItems.append(allSuitable[index])
        }
        
        // 选择2-3个忌做的事
        let unsuitableCount = 2 + (day % 2)
        for i in 0..<unsuitableCount {
            let index = (day + i) % allUnsuitable.count
            unsuitableItems.append(allUnsuitable[index])
        }
        
        return (suitable: suitableItems, unsuitable: unsuitableItems)
    }
}
