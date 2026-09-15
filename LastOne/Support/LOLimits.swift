import Foundation

/// 無料枠の上限（`docs/spec.md`「無料枠と上限判定」）。
///
/// TBD の仮値。変更するときはここ 1 箇所だけを直す。
/// Pro（`EntitlementStore.isPro == true`）では上限なしとして扱う。
enum LOLimits {
    /// 無料枠で登録できるカテゴリ数。
    static let freeCategoryLimit = 5
    /// 無料枠で登録できるアイテム数。
    static let freeItemLimit = 30

    /// 無制限を表す表示記号（Stocks の右上メタ用）。
    static let unlimitedSymbol = "∞"

    /// Stocks の右上メタ「<アイテム数> / <上限 or ∞>」。
    static func stocksMeta(itemCount: Int, isPro: Bool) -> String {
        "\(itemCount) / \(isPro ? unlimitedSymbol : String(freeItemLimit))"
    }

    /// 無料枠の残り登録可能数（下限 0）。
    static func remainingItems(currentCount: Int) -> Int {
        max(0, freeItemLimit - currentCount)
    }

    // MARK: - 上限判定

    /// アイテムを追加できるか。Pro は無制限。
    ///
    /// 判定は**追加操作の実行時点**で行う（`docs/spec.md` Sprint 4「無料枠の上限判定」）。
    static func canAddItem(currentCount: Int, isPro: Bool) -> Bool {
        isPro || currentCount < freeItemLimit
    }

    /// カテゴリを追加できるか。Pro は無制限。
    static func canAddCategory(currentCount: Int, isPro: Bool) -> Bool {
        isPro || currentCount < freeCategoryLimit
    }
}
