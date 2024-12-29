import SwiftUI

struct ChineseCalendarView: View {
    let lunarDate: ChineseCalendar.ChineseDateComponents
    let dailyAdvice: (suitable: [String], unsuitable: [String])
    let isAnimating: Bool
    
    var body: some View {
        VStack(spacing: 15) {
            // 农历日期部分
            VStack(spacing: 8) {
                HStack {
                    Text(lunarDate.stemBranch)
                        .font(.title3)
                    Text(lunarDate.zodiac + "年")
                        .font(.title3)
                }
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
                
                Text("\(lunarDate.month)\(lunarDate.day)")
                    .font(.title2.bold())
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
            }
            .padding(.bottom, 5)
            
            // 分隔线
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(.secondary.opacity(0.3))
                .padding(.horizontal)
            
            // 宜忌部分
            HStack(alignment: .top, spacing: 20) {
                // 宜
                VStack(alignment: .leading, spacing: 8) {
                    Text("宜")
                        .font(.headline)
                        .foregroundStyle(.green)
                    
                    ForEach(dailyAdvice.suitable, id: \.self) { item in
                        Text(item)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .opacity(isAnimating ? 1 : 0)
                .offset(x: isAnimating ? 0 : -30)
                
                // 忌
                VStack(alignment: .leading, spacing: 8) {
                    Text("忌")
                        .font(.headline)
                        .foregroundStyle(.red)
                    
                    ForEach(dailyAdvice.unsuitable, id: \.self) { item in
                        Text(item)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .opacity(isAnimating ? 1 : 0)
                .offset(x: isAnimating ? 0 : 30)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(radius: 5)
        }
        .padding(.horizontal)
    }
}
