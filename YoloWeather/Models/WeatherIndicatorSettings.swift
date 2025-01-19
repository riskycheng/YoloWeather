import Foundation
import SwiftUI

class WeatherIndicatorSettings: ObservableObject {
    static let shared = WeatherIndicatorSettings()
    
    @Published var showHumidity: Bool {
        didSet {
            UserDefaults.standard.set(showHumidity, forKey: "showHumidity")
        }
    }
    
    @Published var showWindSpeed: Bool {
        didSet {
            UserDefaults.standard.set(showWindSpeed, forKey: "showWindSpeed")
        }
    }
    
    @Published var showPrecipitation: Bool {
        didSet {
            UserDefaults.standard.set(showPrecipitation, forKey: "showPrecipitation")
        }
    }
    
    @Published var showUVIndex: Bool {
        didSet {
            UserDefaults.standard.set(showUVIndex, forKey: "showUVIndex")
        }
    }
    
    @Published var showPressure: Bool {
        didSet {
            UserDefaults.standard.set(showPressure, forKey: "showPressure")
        }
    }
    
    @Published var showVisibility: Bool {
        didSet {
            UserDefaults.standard.set(showVisibility, forKey: "showVisibility")
        }
    }
    
    private init() {
        // 从 UserDefaults 加载保存的设置
        self.showHumidity = UserDefaults.standard.bool(forKey: "showHumidity")
        self.showWindSpeed = UserDefaults.standard.bool(forKey: "showWindSpeed")
        self.showPrecipitation = UserDefaults.standard.bool(forKey: "showPrecipitation")
        self.showUVIndex = UserDefaults.standard.bool(forKey: "showUVIndex")
        self.showPressure = UserDefaults.standard.bool(forKey: "showPressure")
        self.showVisibility = UserDefaults.standard.bool(forKey: "showVisibility")
        
        // 如果是第一次运行，设置默认值
        if !UserDefaults.standard.bool(forKey: "hasInitializedSettings") {
            self.showHumidity = true
            self.showWindSpeed = true
            self.showPrecipitation = true
            self.showUVIndex = true
            self.showPressure = true
            self.showVisibility = true
            
            UserDefaults.standard.set(true, forKey: "hasInitializedSettings")
        }
    }
} 