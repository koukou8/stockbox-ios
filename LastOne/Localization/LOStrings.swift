import Foundation
import SwiftUI

/// UI 文言のキーを 1 箇所に集約したファサード。
///
/// - すべての文言は `LastOne/Resources/Localizable.xcstrings`（String Catalog）に格納する。
///   開発言語は en、翻訳として ja を持つ。
/// - View 側に日本語 / 英語のリテラルを直接書かないこと。必ずこの型を経由する。
/// - 引数を取るものは `String(format:)` で組み立てて `String` を返し、
///   引数を取らないものは `LocalizedStringKey` を返して `Text(_:)` にそのまま渡せるようにする。
enum L {

    // MARK: - タブ / 画面ヘッダー

    static let tabBuy: LocalizedStringKey = "tabBuy"
    static let tabStocks: LocalizedStringKey = "tabStocks"
    static let tabSettings: LocalizedStringKey = "tabSettings"

    static let kickerBuy: LocalizedStringKey = "kickerBuy"
    static let kickerStocks: LocalizedStringKey = "kickerStocks"
    static let kickerSettings: LocalizedStringKey = "kickerSettings"

    /// Settings の右上メタ。両言語とも "Pro" / "Free"。
    static func settingsMeta(isPro: Bool) -> String {
        localized(isPro ? "metaPro" : "metaFree")
    }

    // MARK: - 状態 / 操作

    static let bought: LocalizedStringKey = "bought"
    static let low: LocalizedStringKey = "low"
    static let inStock: LocalizedStringKey = "inStock"
    static let openOne: LocalizedStringKey = "openOne"

    /// 状態チップの文言。
    static func statusChip(_ status: StockStatus) -> LocalizedStringKey {
        switch status {
        case .inStock: return inStock
        case .low: return low
        }
    }

    /// 二値方式の操作ボタン。`low` のときは「買うものリストから除外」。
    static func binaryAction(isLow: Bool) -> LocalizedStringKey {
        isLow ? "binaryActionRemove" : "binaryActionAdd"
    }

    /// カウント方式のヒント（「つストック（閾値 N）」/ "in stock (threshold N)"）。
    static func countHint(threshold: Int) -> String {
        String(format: localized("countHint"), threshold)
    }

    // MARK: - アイテム追加 / 編集シート

    static let addItem: LocalizedStringKey = "addItem"
    static let addSheetTitle: LocalizedStringKey = "addSheetTitle"
    static let namePlaceholder: LocalizedStringKey = "namePlaceholder"
    static let category: LocalizedStringKey = "category"
    static let trackingMode: LocalizedStringKey = "trackingMode"
    static let binary: LocalizedStringKey = "binary"
    static let binaryHint: LocalizedStringKey = "binaryHint"
    static let count: LocalizedStringKey = "count"
    static let countHintShort: LocalizedStringKey = "countHintShort"
    static let addConfirm: LocalizedStringKey = "addConfirm"

    /// 編集シートのタイトルと CTA（追加シートから切り替える）。
    static let editSheetTitle: LocalizedStringKey = "editSheetTitle"
    static let editConfirm: LocalizedStringKey = "editConfirm"

    /// アイテムカードのアクセシビリティヒント。
    static let editHint: LocalizedStringKey = "editHint"

    /// 編集シートのカウント設定（いまのストック数 / 閾値）。
    static let countSettings: LocalizedStringKey = "countSettings"
    static let stockCountLabel: LocalizedStringKey = "stockCountLabel"
    static let threshold: LocalizedStringKey = "threshold"
    static let thresholdHint: LocalizedStringKey = "thresholdHint"

    // MARK: - 削除

    static let deleteItem: LocalizedStringKey = "deleteItem"
    static let deleteItemTitle: LocalizedStringKey = "deleteItemTitle"
    static let deleteItemConfirm: LocalizedStringKey = "deleteItemConfirm"
    static let cancel: LocalizedStringKey = "cancel"

    /// 汎用のダイアログ / シートのボタン。
    static let ok: LocalizedStringKey = "ok"
    static let close: LocalizedStringKey = "close"
    /// スワイプの削除アクション（短いラベル）。
    static let deleteAction: LocalizedStringKey = "deleteAction"

    /// 削除確認の本文（アイテム名を差し込む）。
    static func deleteItemMessage(_ name: String) -> String {
        String(format: localized("deleteItemMessage"), name)
    }

    /// 名前が空のまま登録されたときの既定名。
    static var newItemName: String { localized("newItem") }

    /// 新規カテゴリの既定名。
    static func newCategoryName(_ index: Int) -> String {
        String(format: localized("newCategory"), index)
    }

    // MARK: - カテゴリ管理

    static let addCat: LocalizedStringKey = "addCat"
    static let manageCats: LocalizedStringKey = "manageCats"
    static let categoryNamePlaceholder: LocalizedStringKey = "categoryNamePlaceholder"
    static let renameCategoryHint: LocalizedStringKey = "renameCategoryHint"
    static let reorderCategoryHint: LocalizedStringKey = "reorderCategoryHint"

    static let deleteCategoryTitle: LocalizedStringKey = "deleteCategoryTitle"
    /// 所属アイテムごと消えることを明示する確認本文（カテゴリ名 / アイテム件数）。
    static func deleteCategoryMessage(name: String, itemCount: Int) -> String {
        String(format: localized("deleteCategoryMessage"), name, itemCount)
    }

    /// 最後の 1 カテゴリは削除させない（アイテムの行き先が無くなるため）。
    static let lastCategoryTitle: LocalizedStringKey = "lastCategoryTitle"
    static let lastCategoryMessage: LocalizedStringKey = "lastCategoryMessage"

    // MARK: - 件数

    /// 「N件」/ "N items"。
    static func countLabel(_ count: Int) -> String {
        String(format: localized("countLabel"), count)
    }

    /// 「N カテゴリ」/ "N categories"。
    static func catCount(_ count: Int) -> String {
        String(format: localized("catCount"), count)
    }

    // MARK: - 最終購入日

    /// 「8/15 に購入」/ "Bought Aug 15"。日付部分はロケール準拠フォーマッタで生成する。
    static func lastPurchased(_ date: Date) -> String {
        String(format: localized("last"), LODateFormat.shortMonthDay(date))
    }

    static let noLast: LocalizedStringKey = "noLast"

    /// 最終購入日ラベル（未購入なら「まだ購入記録なし」）。
    static func lastPurchasedLabel(_ date: Date?) -> String {
        guard let date else { return localized("noLast") }
        return lastPurchased(date)
    }

    // MARK: - Stocks 空状態

    /// カテゴリにアイテムが 1 件も無いときの案内（画面が真っ白にならないようにする）。
    static let stocksEmptyHint: LocalizedStringKey = "stocksEmptyHint"

    // MARK: - Buy List 空状態

    static let emptyTitle: LocalizedStringKey = "emptyTitle"
    static let emptyBody: LocalizedStringKey = "emptyBody"
    static let emptyCta: LocalizedStringKey = "emptyCta"

    // MARK: - Settings

    static let settingsExport: LocalizedStringKey = "settingsExport"
    static let settingsExportValue: LocalizedStringKey = "settingsExportValue"
    static let settingsImport: LocalizedStringKey = "settingsImport"
    static let settingsLanguage: LocalizedStringKey = "settingsLanguage"
    static let settingsLanguageValue: LocalizedStringKey = "settingsLanguageValue"
    static let settingsPrivacy: LocalizedStringKey = "settingsPrivacy"
    static let privacyNote: LocalizedStringKey = "privacyNote"

    /// 設定行の右側の値。整形済み文字列として渡す必要があるため解決して返す。
    static var settingsExportValueText: String { localized("settingsExportValue") }
    static var settingsLanguageValueText: String { localized("settingsLanguageValue") }

    // MARK: - 言語について

    static let languageSheetBody: LocalizedStringKey = "languageSheetBody"
    static let openSettings: LocalizedStringKey = "openSettings"

    // MARK: - エクスポート / インポート

    static let exportFailedTitle: LocalizedStringKey = "exportFailedTitle"
    static let exportFailedMessage: LocalizedStringKey = "exportFailedMessage"

    static let importConfirmTitle: LocalizedStringKey = "importConfirmTitle"
    static let importConfirmAction: LocalizedStringKey = "importConfirmAction"
    static let importFailedTitle: LocalizedStringKey = "importFailedTitle"
    static let importFailedMessage: LocalizedStringKey = "importFailedMessage"
    static let importDoneTitle: LocalizedStringKey = "importDoneTitle"

    /// 「全置換」の確認本文。読み込んだファイルの中身の件数を出す。
    static func importConfirmMessage(categories: Int, items: Int) -> String {
        String(format: localized("importConfirmMessage"), categories, items)
    }

    /// インポート完了の本文。
    static func importDoneMessage(categories: Int, items: Int, logs: Int) -> String {
        String(format: localized("importDoneMessage"), categories, items, logs)
    }

    // MARK: - Pro / Paywall

    /// Pro カードのバッジ（両言語とも "PRO"。View にリテラルを書かないためキー化する）。
    static let proBadge: LocalizedStringKey = "proBadge"
    static let proHead: LocalizedStringKey = "proHead"
    static let proSub: LocalizedStringKey = "proSub"
    static let seePro: LocalizedStringKey = "seePro"
    static let restoreShort: LocalizedStringKey = "restoreShort"
    static let restore: LocalizedStringKey = "restore"
    static let priceCta: LocalizedStringKey = "priceCta"
    static let perks: [LocalizedStringKey] = ["perk1", "perk2", "perk3"]

    /// 「購入済み・ありがとうございます」/「未購入」。
    static func proStatus(isPro: Bool) -> LocalizedStringKey {
        isPro ? "proStatusPurchased" : "proStatusFree"
    }

    /// 残り枠ラベル。Pro なら「Pro：登録数は無制限です」。
    static func quota(isPro: Bool, remaining: Int) -> String {
        isPro ? localized("quotaPro") : String(format: localized("quotaFree"), remaining)
    }

    static func limitItems(_ limit: Int) -> String {
        String(format: localized("limitItems"), limit)
    }

    static func limitCats(_ limit: Int) -> String {
        String(format: localized("limitCats"), limit)
    }

    /// 上限値は必ず `LOLimits` から渡す（文言に数値を直書きしない）。
    static func proReason(categoryLimit: Int, itemLimit: Int) -> String {
        String(format: localized("proReason"), categoryLimit, itemLimit)
    }

    // MARK: - Paywall

    /// Paywall の見出し（プロダクト名なので両言語とも "LastOne Pro"）。
    static let paywallTitle: LocalizedStringKey = "paywallTitle"

    /// Pro カードの CTA を購入済み表示に切り替えるときのラベル。
    static let proActive: LocalizedStringKey = "proActive"

    /// Paywall の表示理由テキスト（`docs/design.md` §3 の 3 種を出し分ける）。
    static func paywallReason(_ reason: PaywallReason) -> String {
        switch reason {
        case .itemLimit:
            return limitItems(LOLimits.freeItemLimit)
        case .categoryLimit:
            return limitCats(LOLimits.freeCategoryLimit)
        case .settings:
            return proReason(
                categoryLimit: LOLimits.freeCategoryLimit,
                itemLimit: LOLimits.freeItemLimit
            )
        }
    }

    // MARK: - 購入 / リストアの結果

    static let purchaseFailedTitle: LocalizedStringKey = "purchaseFailedTitle"
    static let purchaseFailedMessage: LocalizedStringKey = "purchaseFailedMessage"
    static let restoreDoneTitle: LocalizedStringKey = "restoreDoneTitle"
    static let restoreDoneMessage: LocalizedStringKey = "restoreDoneMessage"
    static let restoreNoneTitle: LocalizedStringKey = "restoreNoneTitle"
    static let restoreNoneMessage: LocalizedStringKey = "restoreNoneMessage"

    // MARK: - VoiceOver 用ラベル

    /// Buy List の「買った」ボタン。ボタンだけを触ったときにどのアイテムか分かるようにする。
    static func a11yBought(_ name: String) -> String {
        String(format: localized("a11yBought"), name)
    }

    /// Stocks の二値方式の操作行。
    static func a11yBinaryAction(isLow: Bool, name: String) -> String {
        String(format: localized(isLow ? "a11yUnmarkLow" : "a11yMarkLow"), name)
    }

    /// Stocks の「開封 −1」。記号だけでは読み上げが伝わらないため文にする。
    static func a11yOpenOne(_ name: String) -> String {
        String(format: localized("a11yOpenOne"), name)
    }

    // MARK: - プリセットカテゴリ

    /// 初回起動時に投入するプリセットカテゴリ名（実行時のロケールで確定保存する）。
    static let presetCategoryKeys = ["presetDaily", "presetFood", "presetPet"]

    static func presetCategoryName(_ key: String) -> String { localized(key) }

    // MARK: - 内部

    /// String Catalog からの取得。キーは変数で渡すため `NSLocalizedString` を使う。
    private static func localized(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }
}
