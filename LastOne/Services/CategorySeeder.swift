import Foundation
import SwiftData

/// 初回起動時のプリセットカテゴリ投入。
///
/// `Category` が 1 件も無いときだけ実行するため、2 回目以降の起動で重複投入されない。
enum CategorySeeder {

    /// プリセットカテゴリが未投入なら投入する。
    /// - Returns: 実際に投入したカテゴリ数（既に存在する場合は 0）。
    @discardableResult
    static func seedIfNeeded(in context: ModelContext) -> Int {
        guard !hasAnyCategory(in: context) else { return 0 }

        let now = Date()
        for (index, key) in L.presetCategoryKeys.enumerated() {
            // 投入時点のロケールで解決した文字列を確定保存する（以降は端末言語を変えても変化しない）。
            let category = Category(
                name: L.presetCategoryName(key),
                sortOrder: index,
                createdAt: now
            )
            context.insert(category)
        }

        do {
            try context.save()
        } catch {
            // 保存に失敗しても起動は継続する（次回起動時に再試行される）。
            print("[seeder] failed to save preset categories: \(error)")
            return 0
        }
        return L.presetCategoryKeys.count
    }

    /// カテゴリが 1 件でも存在するか。`fetchLimit = 1` で全件読み込みを避ける。
    private static func hasAnyCategory(in context: ModelContext) -> Bool {
        var descriptor = FetchDescriptor<Category>()
        descriptor.fetchLimit = 1
        do {
            return try !context.fetch(descriptor).isEmpty
        } catch {
            print("[seeder] failed to fetch categories: \(error)")
            // 判定できないときは投入しない（重複投入より未投入のほうが安全）。
            return true
        }
    }
}
