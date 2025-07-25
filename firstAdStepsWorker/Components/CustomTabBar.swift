import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let tabBarItems: [(icon: String, label: String)]
    @Namespace private var animation

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabBarItems.enumerated()), id: \ .offset) { (offset, item) in
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        selectedTab = offset
                    }
                }) {
                    VStack(spacing: 4) {
                        ZStack {
                            if selectedTab == offset {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Theme.primary)
                                    .frame(width: 24, height: 5)
                                    .matchedGeometryEffect(id: "highlight", in: animation)
                                    .offset(y: -39)
                            }
                            VStack(spacing: 5) {
                                Image(item.icon)
                                    .renderingMode(.template)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: selectedTab == offset ? 28 : 24, height: selectedTab == offset ? 28 : 24)
                                    .foregroundColor(selectedTab == offset ? Theme.primary : Color.gray.opacity(0.7))
                                    .scaleEffect(selectedTab == offset ? 1.18 : 1.0)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selectedTab == offset)
                                Text(item.label)
                                    .font(.caption2)
                                    .fontWeight(selectedTab == offset ? .semibold : .regular)
                                    .foregroundColor(selectedTab == offset ? Theme.primary : Color.gray.opacity(0.7))
                                    .padding(.top, 2)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 4)
        )
        .padding(.horizontal)
    }
}



