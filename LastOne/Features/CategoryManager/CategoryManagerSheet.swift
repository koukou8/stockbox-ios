import SwiftData
import SwiftUI

/// カテゴリ管理シート（`docs/design.md` §2「カテゴリ管理シート」）。
///
/// 行（ハンドルアイコン + 名前 + 件数）のリスト ＋ 破線の「＋ カテゴリを追加」。
/// - 追加: 末尾に「新しいカテゴリ N」を作り、そのままインライン改名に入る。
/// - 名称変更: 行をタップするとその行が `TextField` に変わる（インライン編集）。
/// - 並べ替え: 行を長押ししてドラッグ。`sortOrder` を 0 起点の連番で永続化する。
/// - 削除: 左スワイプ。所属アイテムがあるときは確認を出し、cascade で一緒に消えることを明示する。
///   最後の 1 カテゴリはアイテムの行き先が無くなるため削除させない。
///
/// 無料枠のカテゴリ上限に達している状態で「＋ カテゴリを追加」を押すと、
/// 追加せずに Paywall（`limitCats`）を開く。
struct CategoryManagerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.analytics) private var analytics
    @Environment(\.entitlements) private var entitlements

    @Query(sort: [SortDescriptor(\Category.sortOrder, order: .forward)])
    private var categories: [Category]

    @Query private var items: [Item]

    /// インライン編集中のカテゴリ。nil なら編集していない。
    @State private var editingCategoryID: UUID?
    @State private var draftName: String = ""
    @FocusState private var isNameFocused: Bool

    /// 削除確認。削除済みモデルを読まないよう、名前と件数を控えたスナップショットで持つ。
    @State private var pendingDeletion: PendingCategoryDeletion?
    @State private var isConfirmingDeletion = false
    /// 最後の 1 カテゴリを消そうとしたときの説明。
    @State private var isShowingLastCategoryAlert = false
    /// 無料枠の上限に達したときに開く Paywall。
    @State private var paywall: PaywallPresentation?

    var body: some View {
        VStack(spacing: 0) {
            header
            list
        }
        .background(LOColor.background)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(LORadius.panel)
        .presentationBackground(LOColor.background)
        // シートが閉じるときに編集途中の名前を取りこぼさない。
        .onDisappear(perform: endRename)
        .confirmationDialog(
            Text(L.deleteCategoryTitle),
            isPresented: $isConfirmingDeletion,
            titleVisibility: .visible,
            presenting: pendingDeletion
        ) { pending in
            Button(L.deleteItemConfirm, role: .destructive) { confirmDeletion(pending) }
            Button(L.cancel, role: .cancel) { pendingDeletion = nil }
        } message: { pending in
            Text(L.deleteCategoryMessage(name: pending.name, itemCount: pending.itemCount))
        }
        .alert(L.lastCategoryTitle, isPresented: $isShowingLastCategoryAlert) {
            Button(L.ok, role: .cancel) {}
        } message: {
            Text(L.lastCategoryMessage)
        }
        .sheet(item: $paywall) { presentation in
            PaywallSheet(reason: presentation.reason)
        }
        .accessibilityIdentifier("sheet.categoryManager")
    }

    // MARK: - ヘッダー

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Capsule()
                .fill(LOColor.dragHandle)
                .frame(width: 44, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 14)

            Text(L.manageCats)
                .font(LOFont.sheetTitle)
                .foregroundStyle(LOColor.textPrimary)

            Text(L.reorderCategoryHint)
                .font(LOFont.caption)
                .foregroundStyle(LOColor.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }

    // MARK: - リスト

    private var list: some View {
        List {
            ForEach(categories) { category in
                row(category)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 20))
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            requestDeletion(of: category)
                        } label: {
                            Label(L.deleteAction, systemImage: "trash")
                        }
                    }
            }
            .onMove(perform: move)

            LODashedAddButton(title: L.addCat, cornerRadius: LORadius.categoryRow) {
                addCategory()
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 9, leading: 20, bottom: 24, trailing: 20))
            .moveDisabled(true)
            .accessibilityIdentifier("categoryManager.add")
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .environment(\.defaultMinListRowHeight, 10)
        .background(LOColor.background)
    }

    /// 1 行（ハンドルアイコン + 名前 or 入力欄 + 件数）。
    private func row(_ category: Category) -> some View {
        let isEditingThisRow = editingCategoryID == category.id

        return HStack(spacing: 12) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(LOColor.listHandle)

            Group {
                if isEditingThisRow {
                    TextField(L.categoryNamePlaceholder, text: $draftName)
                        .font(LOFont.settingsRow)
                        .foregroundStyle(LOColor.textBody)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .focused($isNameFocused)
                        .onSubmit(endRename)
                        .accessibilityIdentifier("categoryManager.nameField")
                } else {
                    Text(category.name)
                        .font(LOFont.settingsRow)
                        .foregroundStyle(LOColor.textBody)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(L.countLabel(itemCount(of: category)))
                .font(LOFont.settingsValue)
                .foregroundStyle(LOColor.textTertiaryAlt)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: LORadius.categoryRow, style: .continuous)
                .fill(LOColor.card)
        )
        .shadow(color: LOColor.shadowCard, radius: 8, x: 0, y: 3)
        .contentShape(RoundedRectangle(cornerRadius: LORadius.categoryRow, style: .continuous))
        .onTapGesture {
            guard !isEditingThisRow else { return }
            beginRename(category)
        }
        .accessibilityElement(children: .contain)
        .accessibilityHint(Text(L.renameCategoryHint))
        .accessibilityIdentifier("categoryManager.row")
    }

    // MARK: - 操作

    /// 「＋ カテゴリを追加」。無料枠の上限に達していたら追加せずに Paywall を出す。
    private func addCategory() {
        endRename()

        guard LOLimits.canAddCategory(currentCount: categories.count, isPro: entitlements.isPro) else {
            paywall = .categoryLimit
            return
        }

        let created = CategoryService.create(
            in: categories,
            context: modelContext,
            analytics: analytics
        )
        // 追加直後にそのまま名前を入力できるようにする。
        beginRename(created)
    }

    private func beginRename(_ category: Category) {
        endRename()
        editingCategoryID = category.id
        draftName = category.name
        isNameFocused = true
    }

    /// 編集中の名前を確定して入力欄を閉じる。空文字なら元の名前を維持する。
    private func endRename() {
        guard let editingCategoryID else { return }
        if let category = categories.first(where: { $0.id == editingCategoryID }) {
            CategoryService.rename(category, to: draftName, context: modelContext)
        }
        self.editingCategoryID = nil
        draftName = ""
        isNameFocused = false
    }

    private func move(from source: IndexSet, to destination: Int) {
        endRename()
        withAnimation(.snappy(duration: 0.22)) {
            CategoryService.move(categories, from: source, to: destination, context: modelContext)
        }
    }

    private func requestDeletion(of category: Category) {
        endRename()

        guard CategoryService.canDelete(currentCount: categories.count) else {
            isShowingLastCategoryAlert = true
            return
        }

        let count = itemCount(of: category)
        guard count > 0 else {
            // 空のカテゴリはそのまま削除する（消えて困るものが無いため）。
            performDeletion(of: category)
            return
        }

        // 所属アイテムがある場合は「一緒に削除される」ことを明示して確認する。
        pendingDeletion = PendingCategoryDeletion(
            id: category.id,
            name: category.name,
            itemCount: count
        )
        isConfirmingDeletion = true
    }

    private func confirmDeletion(_ pending: PendingCategoryDeletion) {
        defer { pendingDeletion = nil }
        guard let category = categories.first(where: { $0.id == pending.id }) else { return }
        performDeletion(of: category)
    }

    private func performDeletion(of category: Category) {
        withAnimation(.snappy(duration: 0.22)) {
            CategoryService.delete(category, remaining: categories, context: modelContext)
        }
    }

    // MARK: - 導出

    /// カテゴリ内のアイテム数。`StocksView` と同じく `@Query` の結果から数える。
    private func itemCount(of category: Category) -> Int {
        items.filter { $0.category?.id == category.id }.count
    }
}

/// 削除確認のスナップショット。削除後に live なモデルを読まないよう値で持つ。
private struct PendingCategoryDeletion: Identifiable {
    let id: UUID
    let name: String
    let itemCount: Int
}
