import Foundation
import SwiftData

/// カテゴリの生成・改名・並べ替え・削除を 1 箇所に集約したサービス。
///
/// `ItemStateService` と同じ方針で、View は SwiftData への書き込みを直接行わず
/// 必ずこの型を経由する。`sortOrder` の連番維持もここが責任を持つ。
///
/// - Note: 無料枠（カテゴリ 5 個）の上限判定と Paywall は Sprint 4 の担当。
///   ここでは常に登録し、上限では止めない。
@MainActor
enum CategoryService {

    /// 最後の 1 カテゴリは削除させない（アイテムの行き先が無くなるため）。
    static let minimumCategoryCount = 1

    // MARK: - 生成

    /// カテゴリを新規作成し、末尾（`sortOrder` の最大値 + 1）に置く。
    ///
    /// 名前は「新しいカテゴリ N / New category N」を仮で入れ、
    /// 呼び出し側がそのままインライン改名に入れるようにする。
    @discardableResult
    static func create(
        name rawName: String? = nil,
        in categories: [Category],
        context: ModelContext,
        analytics: (any AnalyticsClient)? = nil,
        now: Date = Date()
    ) -> Category {
        let fallbackName = L.newCategoryName(categories.count + 1)
        let category = Category(
            name: normalizedName(rawName ?? "", fallback: fallbackName),
            sortOrder: (categories.map(\.sortOrder).max() ?? -1) + 1,
            createdAt: now
        )
        context.insert(category)
        analytics?.track(.categoryCreated)
        save(context, action: "create")
        return category
    }

    // MARK: - 改名

    /// インライン編集からの改名。空文字（空白のみ）のときは元の名前を維持する。
    static func rename(_ category: Category, to rawName: String, context: ModelContext) {
        let name = normalizedName(rawName, fallback: category.name)
        guard name != category.name else { return }
        category.name = name
        save(context, action: "rename")
    }

    // MARK: - 並べ替え

    /// ドラッグ並べ替え。並べ替え後の配列順で `sortOrder` を 0 起点の連番に振り直す。
    static func move(
        _ categories: [Category],
        from source: IndexSet,
        to destination: Int,
        context: ModelContext
    ) {
        var reordered = categories
        reordered.move(fromOffsets: source, toOffset: destination)
        applySortOrder(to: reordered, context: context)
    }

    /// 表示順を配列順どおりに永続化する。
    static func applySortOrder(to categories: [Category], context: ModelContext) {
        var didChange = false
        for (index, category) in categories.enumerated() where category.sortOrder != index {
            category.sortOrder = index
            didChange = true
        }
        guard didChange else { return }
        save(context, action: "reorder")
    }

    // MARK: - 削除

    /// 削除できるか。最後の 1 カテゴリは残す。
    static func canDelete(currentCount: Int) -> Bool {
        currentCount > minimumCategoryCount
    }

    /// カテゴリを削除する。所属アイテムと、その購入履歴は cascade で消える。
    ///
    /// 呼び出し側は `canDelete(currentCount:)` を満たすことと、
    /// 所属アイテムがある場合に確認を取ることを保証すること。
    static func delete(
        _ category: Category,
        remaining categories: [Category],
        context: ModelContext
    ) {
        context.delete(category)
        // 削除で空いた番号を詰めて 0 起点の連番に戻す。
        let rest = categories.filter { $0.id != category.id }
        for (index, other) in rest.enumerated() where other.sortOrder != index {
            other.sortOrder = index
        }
        save(context, action: "delete")
    }

    // MARK: - 内部

    private static func normalizedName(_ rawName: String, fallback: String) -> String {
        let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }

    /// 保存。失敗してもアプリは落とさず、メモリ上の変更は保持したままログに残す。
    private static func save(_ context: ModelContext, action: String) {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("[category] failed to save after \(action): \(error)")
        }
    }
}
