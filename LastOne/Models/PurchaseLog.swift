import Foundation
import SwiftData

/// 購入履歴。MVP では閲覧 UI を持たないが、初日から記録して
/// 将来のカレンダー表示・消費周期予測の学習データとする。
@Model
final class PurchaseLog {
    @Attribute(.unique) var id: UUID
    var purchasedAt: Date
    /// 購入数。二値方式は 1、カウント方式は実際に加算した個数。
    var quantity: Int

    var item: Item?

    init(
        id: UUID = UUID(),
        purchasedAt: Date = Date(),
        quantity: Int = 1,
        item: Item? = nil
    ) {
        self.id = id
        self.purchasedAt = purchasedAt
        self.quantity = quantity
        self.item = item
    }
}
