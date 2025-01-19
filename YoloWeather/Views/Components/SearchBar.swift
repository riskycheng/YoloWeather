import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color.white.opacity(0.4))
            
            TextField("搜索城市", text: $text)
                .textFieldStyle(.plain)
                .submitLabel(.search)
                .foregroundColor(.white)
                .accentColor(.white)
                .placeholder(when: text.isEmpty) {
                    Text("搜索城市")
                        .foregroundColor(Color.white.opacity(0.4))
                }
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.white.opacity(0.4))
                }
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.08))
        .cornerRadius(8)
        .padding(.horizontal)
    }
} 