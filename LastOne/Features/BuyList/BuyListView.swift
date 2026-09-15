import SwiftData
import SwiftUI

/// 買うものリスト（タブ 1）。
///
/// `status == low` のアイテムを自動集約して 1 行カードで並べる。
/// 「買った」で `ItemStateService.purchase` を呼び、在庫状態への復帰・最終購入日の更新・
/// `PurchaseLog` の追記をまとめて行う（`docs/design.md` §4）。
/// 0 件のときは空状態パネルを出し、「ストックを見る」で Stocks タブへ切り替える。
struct BuyListView: View {
    /// 空状態の「ストックを見る」から Stocks タブへ切り替えるための参照。
    @Binding var selection: AppTab

    @Environment(\.modelContext) private var modelContext
    @Environment(\.analytics) private var analytics

    @Query(sort: [SortDescriptor(\Item.sortOrder, order: .forward)])
    private var items: [Item]

    /// `status == low` のアイテム。並び順はカテゴリ sortOrder → アイテム sortOrder。
    private var lowItems: [Item] {
        items
            .filter { $0.status == .low }
            .sorted { lhs, rhs in
                let lhsCategory = lhs.category?.sortOrder ?? Int.max
                let rhsCategory = rhs.category?.sortOrder ?? Int.max
                if lhsCategory != rhsCategory { return lhsCategory < rhsCategory }
                return lhs.sortOrder < rhs.sortOrder
            }
    }

    var body: some View {
        LOScreenScaffold(
            kicker: L.kickerBuy,
            title: L.tabBuy,
            meta: L.countLabel(lowItems.count)
        ) {
            if lowItems.isEmpty {
                BuyListEmptyState {
                    withAnimation(.snappy(duration: 0.22)) { selection = .stocks }
                }
            } else {
                // 行間はプロトタイプに合わせて 12（scaffold 既定の 14 より少し詰める）。
                VStack(spacing: 12) {
                    ForEach(lowItems) { item in
                        BuyListRow(item: item) { purchase(item) }
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    }
                }
            }
        }
        .accessibilityIdentifier("screen.buyList")
    }

    /// 「買った」。行が消えるところまで含めて控えめにアニメーションさせる。
    private func purchase(_ item: Item) {
        withAnimation(.snappy(duration: 0.24)) {
            // 戻り値の PurchaseLog は使わない（記録は ItemStateService が済ませている）。
            _ = ItemStateService.purchase(item, context: modelContext, analytics: analytics)
        }
    }
}
