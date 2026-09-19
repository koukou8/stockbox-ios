import SwiftData
import SwiftUI
import RevenueCat

@main
struct LastOneApp: App {

    /// 端末内ローカルのみ。CloudKit 設定は付けない（MVP 対象外）。
    private let modelContainer: ModelContainer

    /// 計測クライアント。MVP ではログ出力スタブ。
    /// 実 SDK（PostHog）導入時はここのインスタンスを差し替えるだけでよい。
    private let analytics: any AnalyticsClient = LoggingAnalyticsClient()

    /// RevenueCatが返す購入状態をアプリ全体へ注入する。
    private let entitlements: any EntitlementStore

    init() {
        Purchases.configure(withAPIKey: LORevenueCatConfiguration.publicAPIKey)
        entitlements = RevenueCatEntitlementStore()

        let schema = Schema([Category.self, Item.self, PurchaseLog.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.analytics, analytics)
                .environment(\.entitlements, entitlements)
                .fontDesign(.rounded)
                .tint(LOColor.accent)
                // v1 は Light 固定（ダークモードは対象外）。
                .preferredColorScheme(.light)
                // 固定サイズのトークンで組んだ密なレイアウトが破綻しないよう、
                // 拡大は accessibility1 までに丸める（1〜2 段の拡大は通常どおり効く）。
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        }
        .modelContainer(modelContainer)
    }
}
