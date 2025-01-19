import SwiftUI

struct WeatherBubbleSettingsView: View {
    @StateObject private var settings = WeatherBubbleSettings.shared
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("显示指标")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(settings.bubbleItems) { item in
                    Button {
                        settings.toggleBubble(id: item.id)
                    } label: {
                        HStack {
                            Text(item.title)
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                            Spacer()
                            Circle()
                                .fill(item.isEnabled ? Color.green : Color.gray.opacity(0.3))
                                .frame(width: 20, height: 20)
                                .overlay {
                                    if item.isEnabled {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(white: 0.2, opacity: 0.3))
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

private struct CustomToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: { configuration.isOn.toggle() }) {
            HStack {
                configuration.label
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(configuration.isOn ? Color.green.opacity(0.5) : Color.gray.opacity(0.3))
                        .frame(width: 24, height: 24)
                    
                    if configuration.isOn {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(8)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
    }
} 