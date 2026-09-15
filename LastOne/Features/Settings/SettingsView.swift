import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// 設定（タブ 3）。
///
/// Pro カード → 白カードのリスト（カテゴリの管理 / エクスポート / インポート /
/// 言語について / プライバシーポリシー）→ 脚注（`docs/design.md` §2「Settings（タブ3）」）。
///
/// Pro カードの「Pro を見る」は `proReason` の Paywall を開き、「リストア」は
/// `EntitlementStore.restore()` を呼ぶ。**リストアは App Store の審査要件のため常に押せる。**
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Environment(\.entitlements) private var entitlements

    @Query(sort: [SortDescriptor(\Category.sortOrder, order: .forward)])
    private var categories: [Category]

    @State private var isShowingCategoryManager = false
    @State private var isShowingLanguageInfo = false

    // 課金
    @State private var paywall: PaywallPresentation?
    @State private var entitlementAlert: EntitlementAlert?
    @State private var isRestoring = false

    // エクスポート
    @State private var exportedFile: LOExportedFile?
    @State private var isShowingExportError = false

    // インポート
    @State private var isImporting = false
    @State private var pendingImport: LOBackup?
    @State private var isConfirmingImport = false
    @State private var importSummary: DataImportSummary?
    @State private var isShowingImportDone = false
    @State private var isShowingImportError = false

    var body: some View {
        LOScreenScaffold(
            kicker: L.kickerSettings,
            title: L.tabSettings,
            meta: L.settingsMeta(isPro: entitlements.isPro)
        ) {
            ProCard(
                isPro: entitlements.isPro,
                isRestoring: isRestoring,
                onSeePro: { paywall = .settings },
                onRestore: { Task { await restorePurchase() } }
            )
            .padding(.top, 2)

            settingsCard

            Text(L.privacyNote)
                .font(LOFont.footnote)
                .lineSpacing(6)
                .foregroundStyle(LOColor.textFootnote)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
        }
        .sheet(isPresented: $isShowingCategoryManager) {
            CategoryManagerSheet()
        }
        .sheet(isPresented: $isShowingLanguageInfo) {
            LanguageInfoSheet()
        }
        .sheet(item: $paywall) { presentation in
            PaywallSheet(reason: presentation.reason)
        }
        .sheet(item: $exportedFile) { file in
            LOShareSheet(url: file.url)
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false,
            onCompletion: handleFileSelection
        )
        .confirmationDialog(
            Text(L.importConfirmTitle),
            isPresented: $isConfirmingImport,
            titleVisibility: .visible,
            presenting: pendingImport
        ) { backup in
            Button(L.importConfirmAction, role: .destructive) { performImport(backup) }
            Button(L.cancel, role: .cancel) { pendingImport = nil }
        } message: { backup in
            Text(L.importConfirmMessage(
                categories: backup.categories.count,
                items: backup.items.count
            ))
        }
        .alert(L.importDoneTitle, isPresented: $isShowingImportDone) {
            Button(L.ok, role: .cancel) {}
        } message: {
            if let importSummary {
                Text(L.importDoneMessage(
                    categories: importSummary.categories,
                    items: importSummary.items,
                    logs: importSummary.purchaseLogs
                ))
            }
        }
        .alert(L.importFailedTitle, isPresented: $isShowingImportError) {
            Button(L.ok, role: .cancel) {}
        } message: {
            Text(L.importFailedMessage)
        }
        .alert(L.exportFailedTitle, isPresented: $isShowingExportError) {
            Button(L.ok, role: .cancel) {}
        } message: {
            Text(L.exportFailedMessage)
        }
        .loEntitlementAlert($entitlementAlert)
        .accessibilityIdentifier("screen.settings")
    }

    // MARK: - 課金

    /// 「リストア」。`EntitlementStore` プロトコル越しにのみ実行する。
    private func restorePurchase() async {
        guard !isRestoring else { return }
        isRestoring = true
        let outcome = await entitlements.restore()
        isRestoring = false

        switch outcome {
        case .purchased, .restored:
            entitlementAlert = .restored
        case .noPurchaseFound:
            entitlementAlert = .noPurchaseFound
        case .failed:
            entitlementAlert = .purchaseFailed
        case .cancelled:
            break
        }
    }

    // MARK: - 設定リスト

    private var settingsCard: some View {
        LOSettingsCard {
            LOSettingsRow(
                label: L.manageCats,
                value: L.catCount(categories.count),
                showsChevron: true
            ) {
                isShowingCategoryManager = true
            }
            .accessibilityIdentifier("settings.manageCategories")

            LOSettingsDivider()

            LOSettingsRow(label: L.settingsExport, value: exportValue) {
                exportData()
            }
            .accessibilityIdentifier("settings.export")

            LOSettingsDivider()

            LOSettingsRow(label: L.settingsImport) {
                isImporting = true
            }
            .accessibilityIdentifier("settings.import")

            LOSettingsDivider()

            LOSettingsRow(label: L.settingsLanguage, value: languageValue) {
                isShowingLanguageInfo = true
            }
            .accessibilityIdentifier("settings.language")

            LOSettingsDivider()

            LOSettingsRow(label: L.settingsPrivacy) {
                openURL(LOURL.privacyPolicy)
            }
            .accessibilityIdentifier("settings.privacy")
        }
    }

    /// 行の右側の値。`LocalizedStringKey` ではなく整形済み文字列を渡すため解決しておく。
    private var exportValue: String { L.settingsExportValueText }

    private var languageValue: String { L.settingsLanguageValueText }

    // MARK: - エクスポート

    /// 全データを JSON にして一時ファイルへ書き出し、共有シートを開く。
    private func exportData() {
        do {
            let url = try DataTransferService.writeBackupFile(context: modelContext)
            exportedFile = LOExportedFile(url: url)
        } catch {
            print("[settings] export failed: \(error)")
            isShowingExportError = true
        }
    }

    // MARK: - インポート

    /// ファイル選択の結果。読み込み・検証まで行い、実行前に確認ダイアログを出す。
    private func handleFileSelection(_ result: Result<[URL], any Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                pendingImport = try DataTransferService.loadBackup(from: url)
                isConfirmingImport = true
            } catch {
                print("[settings] import decode failed: \(error)")
                pendingImport = nil
                isShowingImportError = true
            }

        case .failure(let error):
            // ユーザーがキャンセルした場合もここに来るため、エラー表示はしない。
            print("[settings] file selection cancelled or failed: \(error)")
        }
    }

    /// 「全置換」を実行する。
    private func performImport(_ backup: LOBackup) {
        defer { pendingImport = nil }
        do {
            importSummary = try DataTransferService.replaceAll(with: backup, context: modelContext)
            isShowingImportDone = true
        } catch {
            print("[settings] import failed: \(error)")
            isShowingImportError = true
        }
    }
}
