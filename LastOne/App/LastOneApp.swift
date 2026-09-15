import SwiftData
import SwiftUI

@main
struct LastOneApp: App {

    /// 端末内ローカルのみ。CloudKit 設定は付けない（MVP 対象外）。
    private let modelContainer: ModelContainer

    /// 計測クライアント。MVP ではログ出力スタブ。
    /// 実 SDK（PostHog）導入時はここのインスタンスを差し替えるだけでよい。
    private let analytics: any AnalyticsClient = LoggingAnalyticsClient()

    /// 課金状態。MVP では `UserDefaults` スタブ。
    /// 実 SDK（RevenueCat / StoreKit 2）導入時もここのインスタンスを差し替えるだけでよい
    /// （差し替え手順は `EntitlementStore.swift` のコメントを参照）。
    private let entitlements: any EntitlementStore = LocalEntitlementStore()

    init() {
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
