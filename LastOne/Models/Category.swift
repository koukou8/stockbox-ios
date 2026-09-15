import Foundation
import SwiftData

/// カテゴリ。アイテムをグルーピングする単位。
///
/// プリセット（日用品 / 食品 / ペット用品）は初回起動時に
/// `CategorySeeder` がロケール解決済みの文字列を確定保存する。
@Model
final class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    /// 表示順（0 起点の連番）。
    var sortOrder: Int
    var createdAt: Date

    /// カテゴリを削除すると所属アイテムも削除される（cascade）。
    @Relationship(deleteRule: .cascade, inverse: \Item.category)
    var items: [Item]

    init(
        id: UUID = UUID(),
        name: String,
        sortOrder: Int,
        createdAt: Date = Date(),
        items: [Item] = []
    ) {
        self.id = id
        self.name = name
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.items = items
    }
}
