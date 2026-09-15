import SwiftUI

/// 白いカードコンテナ（角丸 22・padding 15/16・カードシャドウ）。
struct LOCard<Content: View>: View {
    var cornerRadius: CGFloat = LORadius.card
    var horizontalPadding: CGFloat = 16
    var verticalPadding: CGFloat = 15
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(LOColor.card, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .loCardShadow()
    }
}

/// カード内の淡い操作ブロック（背景 `#FBF6EF` / 枠 `#EEE3D4` / 角丸 16）。
struct LOSubBlock<Content: View>: View {
    var cornerRadius: CGFloat = LORadius.block
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(LOColor.subBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(LOColor.borderSubtle, lineWidth: 1)
                    )
            )
    }
}
