import SwiftData
import SwiftUI

/// Buy List の 1 行カード（`docs/design.md` §2「Buy List（タブ1）」）。
///
/// 左: アイテム名（16/medium）＋ 2 行目にカテゴリチップと最終購入日ラベル。
/// 右: 「買った」カプセルボタン（`#8FB89E` / 白文字 / ボタンシャドウ）。
struct BuyListRow: View {
    let item: Item
    /// 「買った」。実際の状態遷移は `ItemStateService.purchase` が行う。
    var onBought: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text(item.name)
                    .font(LOFont.itemName)
                    .foregroundStyle(LOColor.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    if let categoryName = item.category?.name {
                        LOCategoryChip(name: categoryName)
                    }

                    Text(L.lastPurchasedLabel(item.lastPurchasedAt))
                        .font(LOFont.caption)
                        .foregroundStyle(LOColor.textTertiaryAlt)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            LOPrimaryCapsuleButton(title: L.bought, action: onBought)
                // 「買った」だけでは対象が分からないため、アイテム名を含めて読み上げる。
                .accessibilityLabel(Text(L.a11yBought(item.name)))
                .accessibilityIdentifier("buyList.bought")
        }
        .padding(.leading, 18)
        .padding(.trailing, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: LORadius.card, style: .continuous)
                .fill(LOColor.card)
                .overlay(
                    RoundedRectangle(cornerRadius: LORadius.card, style: .continuous)
                        .stroke(LOColor.borderBuyRow, lineWidth: 1)
                )
        )
        .loCardShadow()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("buyList.row")
    }
}
