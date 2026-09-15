import SwiftData
import SwiftUI

/// アイテム追加 / 編集シートの表示対象。`.sheet(item:)` に渡す。
enum ItemEditorTarget: Identifiable {
    case add
    case edit(Item)

    var id: String {
        switch self {
        case .add:
            return "add"
        case .edit(let item):
            return item.id.uuidString
        }
    }
}

/// アイテムの追加 / 編集シート（`docs/design.md` §2「アイテム追加シート」）。
///
/// ドラッグハンドル → タイトル → 名前入力 → カテゴリチップ選択 → 管理方式 2 択カード
/// →（編集時のみ）カウントの設定・削除導線 → 主要ボタン → 残り枠ラベル。
///
/// 編集内容は `@State` の下書きに保持し、保存時にだけ `ItemStateService` 経由で
/// SwiftData に書き戻す（シートを閉じただけでは何も変更されない）。
struct ItemEditorSheet: View {
    let target: ItemEditorTarget
    let categories: [Category]
    /// 現在の登録済みアイテム数。残り枠ラベルと上限判定に使う。
    let itemCount: Int
    /// Pro のときは上限なし・残り枠ラベルも「Pro：登録数は無制限です」になる。
    let isPro: Bool
    /// 削除の要求。シートを閉じてから親が実際の削除を行う
    /// （削除済みモデルを body が読んでクラッシュするのを避けるため）。
    var onRequestDelete: (Item) -> Void
    /// 無料枠の上限に達していて追加できなかったときの通知。
    /// 親がシートを閉じきってから Paywall を出す。
    var onLimitReached: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.analytics) private var analytics

    @State private var name: String
    @State private var selectedCategoryID: UUID?
    @State private var trackingMode: TrackingMode
    @State private var threshold: Int
    @State private var stockCount: Int
    @State private var isConfirmingDelete = false
    /// 追加は下からのボトムシート、編集は項目が多いので全高で開く。どちらもドラッグで切り替えられる。
    @State private var detent: PresentationDetent
    @FocusState private var isNameFocused: Bool

    /// 削除確認ダイアログに出す名前。削除後に live なモデルを読まないよう init で控える。
    private let originalName: String

    init(
        target: ItemEditorTarget,
        categories: [Category],
        itemCount: Int,
        isPro: Bool,
        onRequestDelete: @escaping (Item) -> Void,
        onLimitReached: @escaping () -> Void
    ) {
        self.target = target
        self.categories = categories
        self.itemCount = itemCount
        self.isPro = isPro
        self.onRequestDelete = onRequestDelete
        self.onLimitReached = onLimitReached

        switch target {
        case .add:
            // 登録時のデフォルト: 二値方式 / threshold = 1 / カウント方式なら stockCount = 2。
            _name = State(initialValue: "")
            _selectedCategoryID = State(initialValue: categories.first?.id)
            _trackingMode = State(initialValue: .binary)
            _threshold = State(initialValue: LOStockDefaults.threshold)
            _stockCount = State(initialValue: LOStockDefaults.initialCountStock)
            _detent = State(initialValue: .medium)
            originalName = ""

        case .edit(let item):
            _name = State(initialValue: item.name)
            _selectedCategoryID = State(initialValue: item.category?.id ?? categories.first?.id)
            _trackingMode = State(initialValue: item.trackingMode)
            _threshold = State(initialValue: item.threshold)
            _stockCount = State(initialValue: item.stockCount ?? LOStockDefaults.initialCountStock)
            _detent = State(initialValue: .large)
            originalName = item.name
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            dragHandle

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(isEditing ? L.editSheetTitle : L.addSheetTitle)
                        .font(LOFont.sheetTitle)
                        .foregroundStyle(LOColor.textPrimary)

                    nameField
                    categorySection
                    trackingModeSection

                    if trackingMode == .count && isEditing {
                        countSettingsSection
                    }

                    if case .edit(let item) = target {
                        deleteButton(for: item)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 18)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)

            footer
        }
        .background(LOColor.background)
        .presentationDetents([.medium, .large], selection: $detent)
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(LORadius.panel)
        .presentationBackground(LOColor.background)
        .accessibilityIdentifier("sheet.itemEditor")
    }

    // MARK: - パーツ

    private var dragHandle: some View {
        Capsule()
            .fill(LOColor.dragHandle)
            .frame(width: 44, height: 5)
            .padding(.top, 14)
    }

    private var nameField: some View {
        TextField(L.namePlaceholder, text: $name)
            .font(LOFont.textInput)
            .foregroundStyle(LOColor.textPrimary)
            .textInputAutocapitalization(.sentences)
            .submitLabel(.done)
            .focused($isNameFocused)
            .onSubmit { isNameFocused = false }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: LORadius.block, style: .continuous)
                    .fill(LOColor.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: LORadius.block, style: .continuous)
                            .stroke(LOColor.borderInput, lineWidth: 1)
                    )
            )
            .accessibilityIdentifier("sheet.itemName")
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            LOFieldLabel(title: L.category)

            LOFlowLayout(spacing: 8, lineSpacing: 8) {
                ForEach(categories) { category in
                    LOSelectableChip(
                        title: category.name,
                        isSelected: category.id == selectedCategoryID
                    ) {
                        isNameFocused = false
                        withAnimation(.snappy(duration: 0.18)) {
                            selectedCategoryID = category.id
                        }
                    }
                }
            }
        }
    }

    private var trackingModeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            LOFieldLabel(title: L.trackingMode)

            HStack(spacing: 8) {
                LOChoiceCard(
                    title: L.binary,
                    subtitle: L.binaryHint,
                    isSelected: trackingMode == .binary
                ) {
                    isNameFocused = false
                    withAnimation(.snappy(duration: 0.18)) { trackingMode = .binary }
                }
                .accessibilityIdentifier("sheet.modeBinary")

                LOChoiceCard(
                    title: L.count,
                    subtitle: L.countHintShort,
                    isSelected: trackingMode == .count
                ) {
                    isNameFocused = false
                    withAnimation(.snappy(duration: 0.18)) { trackingMode = .count }
                }
                .accessibilityIdentifier("sheet.modeCount")
            }
        }
    }

    /// 編集時のみ表示するカウント方式の詳細（いまのストック数 / 閾値）。
    private var countSettingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            LOFieldLabel(title: L.countSettings)

            LOSubBlock {
                VStack(spacing: 10) {
                    stepperRow(
                        title: L.stockCountLabel,
                        value: $stockCount,
                        range: 0...999,
                        identifier: "sheet.stockCountStepper"
                    )

                    Rectangle()
                        .fill(LOColor.divider)
                        .frame(height: 1)

                    stepperRow(
                        title: L.threshold,
                        value: $threshold,
                        range: 0...99,
                        identifier: "sheet.thresholdStepper"
                    )
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }

            Text(L.thresholdHint)
                .font(LOFont.caption)
                .foregroundStyle(LOColor.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 4)
        }
    }

    private func stepperRow(
        title: LocalizedStringKey,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        identifier: String
    ) -> some View {
        Stepper(value: value, in: range) {
            HStack(spacing: 8) {
                Text(title)
                    .font(LOFont.settingsRow)
                    .foregroundStyle(LOColor.textBody)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 0)

                Text(value.wrappedValue.formatted())
                    .font(LOFont.countValue)
                    .foregroundStyle(LOColor.textPrimary)
                    .contentTransition(.numericText())
            }
        }
        .accessibilityIdentifier(identifier)
    }

    private func deleteButton(for item: Item) -> some View {
        Button {
            isNameFocused = false
            isConfirmingDelete = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "trash")
                    .font(.system(size: 12.5, weight: .regular))
                Text(L.deleteItem)
                    .font(LOFont.subtleButton)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(LOColor.textSecondaryAlt)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
        }
        .background(
            RoundedRectangle(cornerRadius: LORadius.block, style: .continuous)
                .fill(LOColor.card)
                .overlay(
                    RoundedRectangle(cornerRadius: LORadius.block, style: .continuous)
                        .stroke(LOColor.borderInput, lineWidth: 1)
                )
        )
        .buttonStyle(LOPressableButtonStyle())
        .accessibilityIdentifier("sheet.deleteItem")
        .confirmationDialog(
            Text(L.deleteItemTitle),
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button(L.deleteItemConfirm, role: .destructive) {
                onRequestDelete(item)
                dismiss()
            }
            Button(L.cancel, role: .cancel) {}
        } message: {
            Text(L.deleteItemMessage(originalName))
        }
    }

    private var footer: some View {
        VStack(spacing: 12) {
            LOPrimaryWideButton(
                title: isEditing ? L.editConfirm : L.addConfirm,
                font: LOFont.sheetButton,
                isEnabled: canSubmit,
                action: submit
            )
            .accessibilityIdentifier("sheet.submit")

            // 残り枠ラベル（追加時のみ）。Pro なら「Pro：登録数は無制限です」。
            if !isEditing {
                Text(L.quota(isPro: isPro, remaining: remainingFreeSlots))
                    .font(LOFont.caption)
                    .foregroundStyle(LOColor.textFootnote)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .accessibilityIdentifier("sheet.quota")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 34)
        .background(LOColor.background)
    }

    // MARK: - 状態

    private var isEditing: Bool {
        if case .edit = target { return true }
        return false
    }

    private var selectedCategory: Category? {
        categories.first { $0.id == selectedCategoryID }
    }

    /// カテゴリが 1 件も無いと行き先が決まらないため登録させない。
    private var canSubmit: Bool {
        selectedCategory != nil
    }

    /// 無料枠の残り登録可能数（Pro のときは使わない）。
    private var remainingFreeSlots: Int {
        LOLimits.remainingItems(currentCount: itemCount)
    }

    // MARK: - 保存

    private func submit() {
        guard let category = selectedCategory else { return }
        isNameFocused = false

        switch target {
        case .add:
            // 上限判定は**追加操作の実行時点**で行う。
            // 通常は「＋ アイテムを追加」の時点で弾かれるが、ここでも念のため確認する。
            guard LOLimits.canAddItem(currentCount: itemCount, isPro: isPro) else {
                onLimitReached()
                dismiss()
                return
            }

            ItemStateService.create(
                name: name,
                category: category,
                trackingMode: trackingMode,
                context: modelContext,
                analytics: analytics
            )

        case .edit(let item):
            ItemStateService.update(
                item,
                name: name,
                category: category,
                trackingMode: trackingMode,
                threshold: threshold,
                stockCount: stockCount,
                context: modelContext
            )
        }

        dismiss()
    }
}
