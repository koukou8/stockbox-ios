import Foundation
import SwiftData

/// ストック管理の対象アイテム。
///
/// `trackingMode` / `status` は raw String で永続化し、enum は computed property で公開する。
@Model
final class Item {
    @Attribute(.unique) var id: UUID
    var name: String

    /// `TrackingMode` の raw value。直接読み書きせず `trackingMode` を使うこと。
    var trackingModeRaw: String
    /// `StockStatus` の raw value。直接読み書きせず `status` を使うこと。
    var statusRaw: String

    /// カウント方式のみ使用。二値方式では nil。
    var stockCount: Int?
    /// `low` に落ちる閾値。既定 1（カウント方式のみ意味を持つ）。
    var threshold: Int

    /// 最終購入日時。未購入は nil。
    var lastPurchasedAt: Date?
    /// カテゴリ内の表示順。
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date

    var category: Category?

    /// アイテムを削除すると購入履歴も削除される（cascade）。
    @Relationship(deleteRule: .cascade, inverse: \PurchaseLog.item)
    var logs: [PurchaseLog]

    init(
        id: UUID = UUID(),
        name: String,
        category: Category? = nil,
        trackingMode: TrackingMode = .binary,
        stockCount: Int? = nil,
        threshold: Int = LOStockDefaults.threshold,
        status: StockStatus = .inStock,
        lastPurchasedAt: Date? = nil,
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        logs: [PurchaseLog] = []
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.trackingModeRaw = trackingMode.rawValue
        self.stockCount = stockCount
        self.threshold = threshold
        self.statusRaw = status.rawValue
        self.lastPurchasedAt = lastPurchasedAt
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.logs = logs
    }

    // MARK: - enum ブリッジ

    var trackingMode: TrackingMode {
        get { TrackingMode(rawValue: trackingModeRaw) ?? .binary }
        set { trackingModeRaw = newValue.rawValue }
    }

    var status: StockStatus {
        get { StockStatus(rawValue: statusRaw) ?? .inStock }
        set { statusRaw = newValue.rawValue }
    }
}

/// アイテム登録時の既定値（正典 §「登録時のデフォルト」）。
enum LOStockDefaults {
    /// 既定の閾値。
    static let threshold = 1
    /// カウント方式を選んだときの初期ストック数。
    static let initialCountStock = 2
    /// 「買った」1 回あたりの既定補充数。
    static let defaultRestockQuantity = 2
}
