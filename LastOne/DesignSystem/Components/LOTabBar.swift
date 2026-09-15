import SwiftUI

/// 下部固定のカスタムタブバー。
///
/// 選択タブのみ背景 `rgba(143,184,158,.16)`・角丸 18・文字色 `#5E7F62`、
/// 非選択は `#BDB1A2`（`docs/design.md` §2「共通シェル」）。
struct LOTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 6) {
            ForEach(AppTab.allCases) { tab in
                LOTabBarItem(tab: tab, isSelected: tab == selection) {
                    guard selection != tab else { return }
                    withAnimation(.snappy(duration: 0.22)) {
                        selection = tab
                    }
                }
            }
        }
        .padding(.top, 8)
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
        .background(alignment: .top) {
            LOColor.backgroundTop
                .opacity(0.96)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(LOColor.borderPanel)
                        .frame(height: 1)
                }
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

private struct LOTabBarItem: View {
    let tab: AppTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: tab.symbolName)
                    .font(.system(size: 21, weight: .regular))
                    .frame(height: 23)
                Text(tab.title)
                    .font(LOFont.tabLabel)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(isSelected ? LOColor.accentDeep : LOColor.textTabInactive)
            .frame(maxWidth: .infinity)
            .padding(.top, 9)
            .padding(.bottom, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background {
            RoundedRectangle(cornerRadius: LORadius.tabSelection, style: .continuous)
                .fill(isSelected ? LOColor.tabSelectedBackground : Color.clear)
        }
        .accessibilityIdentifier(tab.accessibilityIdentifier)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}
