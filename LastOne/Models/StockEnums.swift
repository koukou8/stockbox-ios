import Foundation

/// アイテムごとの管理方式。
///
/// SwiftData には `Item.trackingModeRaw`（String）として保存し、
/// Swift 側では `Item.trackingMode` の computed property 経由で扱う。
/// これにより将来 case を追加してもストアのスキーマ変更が不要になる。
enum TrackingMode: String, Codable, CaseIterable, Identifiable, Sendable {
    /// 在庫数を持たず「在庫あり ⇄ のこり1つ」だけを管理する（既定）。
    case binary
    /// ストック数と閾値を持ち、開封のたびに −1 する。
    case count

    var id: String { rawValue }
}

/// 在庫状態。
///
/// 正典（`docs/spec/lastone-app.md`）の「将来 `out`（品切れ）状態を分けたくなった場合に備え、
/// status は文字列 enum とし拡張可能にしておく」という要求に従い、raw value を String で持つ。
/// 追加時は `case out = "out"` を足すだけでよく、既存レコードの移行も不要。
enum StockStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case inStock = "in_stock"
    case low

    var id: String { rawValue }

    /// 買うものリストに集約される状態かどうか。
    var isOnBuyList: Bool { self == .low }
}
