import SwiftData
import SwiftUI

/// Stocks 一覧のアイテムカード（白・角丸 22・padding 15/16・カードシャドウ）。
///
/// 上段: アイテム名 + 最終購入日 / 右に状態チップ。
/// 下段: 二値方式なら全幅の淡いボタン、カウント方式ならカウントブロック + 「開封 −1」。
/// 上段（＝ボタン以外の余白）をタップすると編集シートが開く。
struct StockItemCard: View {
    let item: Item
    /// 編集シートを開く。
    var onEdit: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.analytics) private var analytics

    var body: some View {
        LOCard {
            VStack(alignment: .leading, spacing: 12) {
                header
                actionRow
            }
        }
        // ボタンの外側をタップしたら編集へ（ボタン領域はボタン側が優先して消費する）。
        .contentShape(RoundedRectangle(cornerRadius: LORadius.card, style: .continuous))
        .onTapGesture(perform: onEdit)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stocks.item")
    }

    // MARK: - 上段

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(LOFont.itemName)
                    .foregroundStyle(LOColor.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(L.lastPurchasedLabel(item.lastPurchasedAt))
                    .font(LOFont.caption)
                    .foregroundStyle(LOColor.textTertiaryAlt)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            LOStatusChip(status: item.status)
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text(L.editHint))
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - 下段

    @ViewBuilder
    private var actionRow: some View {
        switch item.trackingMode {
        case .binary:
            LOSubtleWideButton(title: L.binaryAction(isLow: item.status == .low)) {
                withAnimation(.snappy(duration: 0.22)) {
                    ItemStateService.toggleBinary(item, context: modelContext, analytics: analytics)
                }
            }
            // ボタンだけを触ったときに、どのアイテムをどうするのかが読み上げで分かるようにする。
            .accessibilityLabel(Text(L.a11yBinaryAction(isLow: item.status == .low, name: item.name)))
            .accessibilityIdentifier("stocks.binaryAction")

        case .count:
            countBlock
        }
    }

    private var countBlock: some View {
        LOSubBlock {
            HStack(spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(displayedStockCount.formatted())
                        .font(LOFont.countValue)
                        .foregroundStyle(LOColor.textPrimary)
                        .contentTransition(.numericText())
                        .accessibilityIdentifier("stocks.stockCount")

                    Text(L.countHint(threshold: item.threshold))
                        .font(LOFont.caption)
                        .foregroundStyle(LOColor.textTertiary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                LOQuietCapsuleButton(title: L.openOne) {
                    withAnimation(.snappy(duration: 0.22)) {
                        ItemStateService.openOne(item, context: modelContext, analytics: analytics)
                    }
                }
                .accessibilityLabel(Text(L.a11yOpenOne(item.name)))
                .accessibilityIdentifier("stocks.openOne")
            }
            .padding(.leading, 14)
            .padding(.trailing, 10)
            .padding(.vertical, 8)
        }
    }

    /// カウント方式で万一 `stockCount` が nil のときも 0 として描画し、クラッシュさせない。
    private var displayedStockCount: Int {
        item.stockCount ?? 0
    }
}
