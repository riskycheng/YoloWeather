import SwiftUI

struct ChineseCalendarView: View {
    @Binding var isShowing: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 半透明背景
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isShowing = false
                        }
                    }
                
                // 日历卡片
                HStack(spacing: 0) {
                    // 日历内容
                    VStack(alignment: .leading, spacing: 20) {
                        // 顶部日期
                        VStack(alignment: .center, spacing: 8) {
                            Text("2025年02月05日")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                            
                            Text("正月初八")
                                .font(.system(size: 28, weight: .medium))
                            
                            Text("乙巳年 戊寅月 乙巳日【属蛇】周三 第5周")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)
                        
                        // 宜忌
                        VStack(alignment: .leading, spacing: 16) {
                            // 宜
                            HStack(alignment: .top, spacing: 12) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 8)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("宜")
                                        .font(.system(size: 15))
                                    Text("作灶 解除 平治道涂")
                                        .font(.system(size: 15))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // 忌
                            HStack(alignment: .top, spacing: 12) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 8)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("忌")
                                        .font(.system(size: 15))
                                    Text("栽种 出行 祈福 行丧 纳畜 安葬\n安门 伐木 作梁 牧养")
                                        .font(.system(size: 15))
                                        .foregroundColor(.secondary)
                                        .lineSpacing(4)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // 分隔线
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 0.5)
                            .padding(.horizontal, 16)
                        
                        // 五行等信息
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("五行")
                                    .font(.system(size: 13))
                                Text("覆灯火")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("冲煞")
                                    .font(.system(size: 13))
                                Text("蛇日冲猪 煞东")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("值神")
                                    .font(.system(size: 13))
                                Text("天德")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // 彭祖百忌
                        VStack(alignment: .leading, spacing: 8) {
                            Text("彭祖百忌")
                                .font(.system(size: 13))
                            Text("乙不栽植千株不长 巳不远行财物伏藏")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        
                        Spacer()
                    }
                    .frame(width: min(geometry.size.width * 0.85, 340))
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 0)
                    )
                    
                    Spacer()
                }
                .padding(.leading, 16)
            }
        }
        .transition(.move(edge: .leading))
    }
}

struct ChineseCalendarView_Previews: PreviewProvider {
    static var previews: some View {
        ChineseCalendarView(isShowing: .constant(true))
    }
}
