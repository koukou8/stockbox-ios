import Foundation
import SwiftData

/// アイテムの状態遷移と永続化を 1 箇所に集約したサービス。
///
/// - View は SwiftData への書き込みを直接行わず、必ずこの型を経由する。
/// - Stocks（Sprint 2）と Buy List（Sprint 3）で同じ遷移ロジックを共有する。
/// - `updatedAt` の更新と `ModelContext.save()` もここで行う。
/// - 計測は `AnalyticsClient` プロトコル越しに発火する（View から SDK に触れない）。
///
/// 遷移の定義は `docs/design.md` §4 / `docs/spec.md`「状態遷移」に一致させること。
@MainActor
enum ItemStateService {

    // MARK: - 二値方式

    /// 「買うものリストに追加」。`in_stock` → `low`。
    static func markLow(
        _ item: Item,
        context: ModelContext,
        analytics: (any AnalyticsClient)? = nil
    ) {
        guard item.status != .low else { return }
        item.status = .low
        touch(item)
        analytics?.track(.itemMarkedLow)
        save(context, action: "markLow")
    }

    /// 「買うものリストから除外」。`low` → `in_stock`。
    /// 購入ではないので `lastPurchasedAt` / `PurchaseLog` は更新しない。
    static func unmarkLow(_ item: Item, context: ModelContext) {
        guard item.status != .inStock else { return }
        item.status = .inStock
        touch(item)
        save(context, action: "unmarkLow")
    }

    /// 二値方式の操作行のトグル。ラベルは状態で反転する（`L.binaryAction(isLow:)`）。
    static func toggleBinary(
        _ item: Item,
        context: ModelContext,
        analytics: (any AnalyticsClient)? = nil
    ) {
        if item.status == .low {
            unmarkLow(item, context: context)
        } else {
            markLow(item, context: context, analytics: analytics)
        }
    }

    // MARK: - カウント方式

    /// 「開封 −1」。
    ///
    /// `stockCount = max(0, stockCount - 1)` とし、`stockCount <= threshold` なら `low`、
    /// そうでなければ `in_stock`。`stockCount == 0` でさらに押しても 0 のまま維持しクラッシュしない。
    static func openOne(
        _ item: Item,
        context: ModelContext,
        analytics: (any AnalyticsClient)? = nil
    ) {
        let current = item.stockCount ?? LOStockDefaults.initialCountStock
        let next = max(0, current - 1)
        let didDecrease = next != current

        item.stockCount = next
        item.status = resolvedStatus(stockCount: next, threshold: item.threshold)

        // 実際に減ったときだけ計測・更新日時を動かす（0 での空打ちは計測しない）。
        if didDecrease {
            touch(item)
            analytics?.track(.itemOpened)
        }
        save(context, action: "openOne")
    }

    // MARK: - 買った（Sprint 3 の Buy List から使用）

    /// 「買った」。在庫状態へ復帰させ、購入日時と `PurchaseLog` を記録する。
    ///
    /// カウント方式は `stockCount = max(threshold + 1, stockCount + 2)`（既定購入数 2・必ず閾値超）。
    /// `quantity` には実際に増えた差分を記録する。二値方式は `quantity = 1`。
    @discardableResult
    static func purchase(
        _ item: Item,
        context: ModelContext,
        analytics: (any AnalyticsClient)? = nil,
        now: Date = Date()
    ) -> PurchaseLog {
        var quantity = 1

        if item.trackingMode == .count {
            let current = item.stockCount ?? 0
            let restocked = max(item.threshold + 1, current + LOStockDefaults.defaultRestockQuantity)
            quantity = max(1, restocked - current)
            item.stockCount = restocked
        }

        item.status = .inStock
        item.lastPurchasedAt = now
        item.updatedAt = now

        let log = PurchaseLog(purchasedAt: now, quantity: quantity, item: item)
        context.insert(log)

        analytics?.track(.itemPurchased)
        save(context, action: "purchase")
        return log
    }

    // MARK: - 生成 / 更新 / 削除

    /// アイテムを新規登録する。
    ///
    /// 既定値は正典どおり `trackingMode = binary` / `threshold = 1` / `status = in_stock`、
    /// カウント方式を選んだ場合のみ `stockCount = 2`。
    /// 名前が空（空白のみを含む）のときは「新しいアイテム / New item」を採用する。
    ///
    /// - Note: 無料枠の上限判定は Sprint 4 の担当。ここでは常に登録する。
    @discardableResult
    static func create(
        name rawName: String,
        category: Category?,
        trackingMode: TrackingMode,
        context: ModelContext,
        analytics: (any AnalyticsClient)? = nil,
        now: Date = Date()
    ) -> Item {
        let item = Item(
            name: normalizedName(rawName),
            category: category,
            trackingMode: trackingMode,
            stockCount: trackingMode == .count ? LOStockDefaults.initialCountStock : nil,
            threshold: LOStockDefaults.threshold,
            status: .inStock,
            lastPurchasedAt: nil,
            sortOrder: nextSortOrder(in: category),
            createdAt: now,
            updatedAt: now
        )
        context.insert(item)
        analytics?.track(.itemCreated)
        save(context, action: "create")
        return item
    }

    /// 編集シートからの更新。カテゴリを変えた場合はカテゴリ内の末尾に並べ直す。
    static func update(
        _ item: Item,
        name rawName: String,
        category: Category?,
        trackingMode: TrackingMode,
        threshold: Int,
        stockCount: Int,
        context: ModelContext
    ) {
        let categoryChanged = item.category?.id != category?.id
        item.name = normalizedName(rawName)
        if categoryChanged {
            item.category = category
            item.sortOrder = nextSortOrder(in: category)
        }

        item.trackingMode = trackingMode
        item.threshold = max(0, threshold)

        switch trackingMode {
        case .binary:
            // 二値方式では在庫数を持たない。状態は現状を維持する。
            item.stockCount = nil
        case .count:
            // カウント方式の状態は常に「数と閾値」から導出できるので再計算する。
            let normalized = max(0, stockCount)
            item.stockCount = normalized
            item.status = resolvedStatus(stockCount: normalized, threshold: item.threshold)
        }

        touch(item)
        save(context, action: "update")
    }

    /// アイテムを削除する。紐づく `PurchaseLog` は cascade で消える。
    static func delete(_ item: Item, context: ModelContext) {
        context.delete(item)
        save(context, action: "delete")
    }

    // MARK: - 導出

    /// カウント方式の在庫状態。`stockCount <= threshold` なら `low`。
    static func resolvedStatus(stockCount: Int, threshold: Int) -> StockStatus {
        stockCount <= threshold ? .low : .inStock
    }

    /// 空文字（空白のみ）を既定名に置き換える。
    static func normalizedName(_ rawName: String) -> String {
        let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? L.newItemName : trimmed
    }

    // MARK: - 内部

    /// カテゴリ内の末尾に置くための `sortOrder`。
    private static func nextSortOrder(in category: Category?) -> Int {
        guard let category, let maxOrder = category.items.map(\.sortOrder).max() else { return 0 }
        return maxOrder + 1
    }

    private static func touch(_ item: Item, now: Date = Date()) {
        item.updatedAt = now
    }

    /// 保存。失敗してもアプリは落とさず、メモリ上の変更は保持したままログに残す。
    private static func save(_ context: ModelContext, action: String) {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("[itemState] failed to save after \(action): \(error)")
        }
    }
}
