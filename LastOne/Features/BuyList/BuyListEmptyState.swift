import SwiftUI

/// Buy List が 0 件のときの空状態パネル（`docs/design.md` §2「Buy List（タブ1）」）。
///
/// 角丸 30・`#FDFAF5` → `#F8F2E9` のグラデーション・枠 `#F0E7DA` 1.5px のパネルに、
/// 「空のかご」の幾何イラスト → タイトル → 本文 → 「ストックを見る」ボタンを縦に積む。
struct BuyListEmptyState: View {
    /// 「ストックを見る」。Stocks タブへ切り替える。
    var onGoToStocks: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            EmptyBasketIllustration()

            Text(L.emptyTitle)
                .font(LOFont.emptyTitle)
                .foregroundStyle(LOColor.emptyTitle)
                .multilineTextAlignment(.center)

            Text(L.emptyBody)
                .font(LOFont.body)
                .lineSpacing(6)
                .foregroundStyle(LOColor.textTertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 230)

            LOQuietCapsuleButton(
                title: L.emptyCta,
                horizontalPadding: 20,
                verticalPadding: 11,
                action: onGoToStocks
            )
            .padding(.top, 2)
            .accessibilityLabel(Text(L.emptyCta))
            .accessibilityIdentifier("buyList.goToStocks")
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 34)
        .padding(.horizontal, 24)
        .padding(.bottom, 38)
        .background(
            RoundedRectangle(cornerRadius: LORadius.panel, style: .continuous)
                .fill(LOColor.emptyPanelGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: LORadius.panel, style: .continuous)
                        .stroke(LOColor.borderPanel, lineWidth: 1.5)
                )
        )
        .padding(.top, 16)
        .accessibilityIdentifier("buyList.emptyState")
    }
}

#Preview {
    BuyListEmptyState(onGoToStocks: {})
        .padding(18)
        .background(LOColor.background)
}
