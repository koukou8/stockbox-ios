import SwiftData
import SwiftUI

/// ストック一覧（タブ 2）。
///
/// カテゴリ別セクション（見出し + 件数 + グラデ罫線）→ アイテムカード
/// → 末尾に破線の「＋ アイテムを追加」。
/// 二値トグルと「開封 −1」はカード側（`StockItemCard`）が `ItemStateService` 経由で行う。
///
/// 無料枠のアイテム上限に達している状態で「＋ アイテムを追加」を押すと、
/// 追加シートではなく Paywall（`limitItems`）を開く。
struct StocksView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.entitlements) private var entitlements

    @Query(sort: [SortDescriptor(\Category.sortOrder, order: .forward)])
    private var categories: [Category]

    @Query(sort: [SortDescriptor(\Item.sortOrder, order: .forward)])
    private var items: [Item]

    @State private var editorTarget: ItemEditorTarget?
    /// シートを閉じきってから削除する（削除済みモデルを描画しないため）。
    @State private var pendingDeletion: Item?
    /// 追加シートが上限で弾かれたとき、シートを閉じきってから Paywall を出す。
    @State private var pendingPaywall: PaywallPresentation?
    @State private var paywall: PaywallPresentation?

    var body: some View {
        LOScreenScaffold(
            kicker: L.kickerStocks,
            title: L.tabStocks,
            // Pro のときは「N / ∞」。
            meta: LOLimits.stocksMeta(itemCount: items.count, isPro: entitlements.isPro)
        ) {
            ForEach(sections) { section in
                categorySection(section)
            }

            // カテゴリが 1 つも無い / アイテムが 1 件も無いときに画面が空白にならないようにする。
            if sections.isEmpty {
                Text(L.stocksEmptyHint)
                    .font(LOFont.body)
                    .lineSpacing(6)
                    .foregroundStyle(LOColor.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 6)
                    .padding(.top, 8)
                    .accessibilityIdentifier("stocks.emptyHint")
            }

            LODashedAddButton(title: L.addItem, action: requestAddItem)
                .padding(.top, 2)
                .accessibilityIdentifier("stocks.addItem")
        }
        .sheet(item: $editorTarget, onDismiss: handleEditorDismiss) { target in
            ItemEditorSheet(
                target: target,
                categories: categories,
                itemCount: items.count,
                isPro: entitlements.isPro,
                onRequestDelete: { pendingDeletion = $0 },
                onLimitReached: { pendingPaywall = .itemLimit }
            )
        }
        .sheet(item: $paywall) { presentation in
            PaywallSheet(reason: presentation.reason)
        }
        .accessibilityIdentifier("screen.stocks")
    }

    // MARK: - 追加（上限判定）

    /// 「＋ アイテムを追加」。無料枠の上限に達していたら追加シートを開かず Paywall を出す。
    private func requestAddItem() {
        guard LOLimits.canAddItem(currentCount: items.count, isPro: entitlements.isPro) else {
            paywall = .itemLimit
            return
        }
        editorTarget = .add
    }

    // MARK: - セクション

    /// 表示するセクション。**アイテムが 1 件以上あるカテゴリだけ**を描画する
    /// （デザイン試作の `groups.filter(g => g.items.length > 0)` と同じ挙動）。
    ///
    /// カテゴリ内のアイテムはリレーション（`category.items`）ではなく `@Query` の結果から
    /// 絞り込む。追加・削除・カテゴリ変更が確実に一覧へ反映されるようにするため。
    private var sections: [StocksSection] {
        categories.compactMap { category in
            let categoryItems = items.filter { $0.category?.id == category.id }
            guard !categoryItems.isEmpty else { return nil }
            return StocksSection(category: category, items: categoryItems)
        }
    }

    /// カテゴリ 1 件分（見出し + アイテムカード）。
    @ViewBuilder
    private func categorySection(_ section: StocksSection) -> some View {
        LOSectionHeader(
            title: section.category.name,
            countLabel: L.countLabel(section.items.count)
        )
        .accessibilityIdentifier("stocks.section")

        ForEach(section.items) { item in
            StockItemCard(item: item) {
                editorTarget = .edit(item)
            }
        }
    }

    // MARK: - シートを閉じたあとの処理

    /// 削除と Paywall はどちらも「シートが閉じきってから」行う
    /// （削除済みモデルの描画と、シートの多重表示を避けるため）。
    private func handleEditorDismiss() {
        if let item = pendingDeletion {
            pendingDeletion = nil
            withAnimation(.snappy(duration: 0.22)) {
                ItemStateService.delete(item, context: modelContext)
            }
        }

        if let pendingPaywall {
            self.pendingPaywall = nil
            paywall = pendingPaywall
        }
    }
}

/// Stocks 一覧のセクション 1 件分（アイテムを 1 件以上持つカテゴリ）。
private struct StocksSection: Identifiable {
    let category: Category
    let items: [Item]

    var id: UUID { category.id }
}
