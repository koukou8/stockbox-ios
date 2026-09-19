import Foundation
import Observation
import SwiftUI

/// 課金（Pro 権利）の識別子。実 SDK に差し替えるときもここだけを見ればよい。
enum LOEntitlement {
    /// RevenueCat の entitlement 識別子（`docs/spec/lastone-app.md`「課金」）。
    static let identifier = "pro"
    /// App Store Connect の非消耗型プロダクト ID。
    static let productIdentifier = "com.kokiyoshida.stockbox.pro"
    /// スタブ実装が購入状態を保存する `UserDefaults` キー。
    static let userDefaultsKey = "com.kokiyoshida.stockbox.entitlement.pro"
}

/// 購入 / リストアの結果。実 SDK でも同じ粒度で扱えるようにしてある。
enum EntitlementOutcome: Equatable, Sendable {
    /// 購入が完了して Pro になった。
    case purchased
    /// 過去の購入が復元されて Pro になった。
    case restored
    /// ユーザーが購入をキャンセルした（エラー表示しない）。
    case cancelled
    /// 復元対象の購入が見つからなかった。
    case noPurchaseFound
    /// 失敗（ネットワーク・ストア側のエラーなど）。
    case failed
}

/// 課金状態の抽象。**View は必ずこのプロトコル越しに参照し、SDK に直接触れない。**
///
/// MVP では実 SDK を導入せず、`LocalEntitlementStore`（`UserDefaults` スタブ）だけを使う。
///
/// ## 実 SDK（RevenueCat / StoreKit 2）への差し替え手順
///
/// 1. Swift Package で RevenueCat（`https://github.com/RevenueCat/purchases-ios`）を追加する。
/// 2. `LastOneApp.init()` の先頭で `Purchases.configure(withAPIKey: "<公開 SDK キー>")` を呼ぶ。
/// 3. 本ファイルの隣に `RevenueCatEntitlementStore` を新規作成する（既存ファイルは編集しない）:
///
///    ```swift
///    @Observable
///    final class RevenueCatEntitlementStore: EntitlementStore {
///        private(set) var isPro = false
///
///        init() {
///            Task { await refresh() }   // Purchases.shared.customerInfo() で初期化
///        }
///
///        @MainActor func purchase() async -> EntitlementOutcome {
///            guard let package = try? await Purchases.shared.offerings().current?.availablePackages.first
///            else { return .failed }
///            do {
///                let result = try await Purchases.shared.purchase(package: package)
///                if result.userCancelled { return .cancelled }
///                isPro = result.customerInfo.entitlements[LOEntitlement.identifier]?.isActive == true
///                return isPro ? .purchased : .failed
///            } catch { return .failed }
///        }
///
///        @MainActor func restore() async -> EntitlementOutcome {
///            do {
///                let info = try await Purchases.shared.restorePurchases()
///                isPro = info.entitlements[LOEntitlement.identifier]?.isActive == true
///                return isPro ? .restored : .noPurchaseFound
///            } catch { return .failed }
///        }
///    }
///    ```
///
/// 4. `LastOneApp` の `entitlements` プロパティのインスタンスを差し替える。
///    Paywall / Settings / Stocks / 各シートは `\.entitlements` を読むだけなので **View 側の変更は不要**。
/// 5. `Purchases.shared.delegate` で `customerInfo` の更新を受け取り、`isPro` に反映する
///    （家族共有・返金・別端末での購入に追従するため）。
///
/// - Note: `Observable` を継承しているので、`isPro` の変化は SwiftUI がそのまま再描画に反映する。
protocol EntitlementStore: AnyObject, Observable {
    /// Pro を保有しているか。`true` の間は無料枠の上限を適用しない。
    var isPro: Bool { get }
    /// 購入する。UI は結果に応じて Paywall を閉じる / エラーを出す。
    func purchase() async -> EntitlementOutcome
    /// 購入をリストアする。**App Store の審査要件のため、UI から必ず到達できる位置に置くこと。**
    func restore() async -> EntitlementOutcome
}

/// MVP 用のスタブ実装。`UserDefaults` に購入状態を保存するだけで、課金も通信も行わない。
///
/// - `purchase()` は必ず成功し、Pro を有効にする。
/// - `restore()` は、スタブ内に購入済み状態がある場合だけ Pro を復元する。
///   購入状態がなければ `.noPurchaseFound` を返し、無料版のままにする。
///   実 SDK では `Purchases.restorePurchases()` の結果を見て同じ判断を行う。
/// - 状態は `Library/Preferences/com.kokiyoshida.stockbox.plist` の
///   `LOEntitlement.userDefaultsKey` に入る。検証で Pro を解除したいときはこのキーを消す。
@Observable
final class LocalEntitlementStore: EntitlementStore {

    /// ストアとの往復を模した待ち時間。UI のローディング表示を実機と同じ経路で確認するために置く。
    private static let simulatedLatency = Duration.milliseconds(260)

    private let defaults: UserDefaults

    private(set) var isPro: Bool

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.isPro = defaults.bool(forKey: LOEntitlement.userDefaultsKey)
    }

    @MainActor
    func purchase() async -> EntitlementOutcome {
        await Self.simulateStoreRoundTrip()
        applyPro(true)
        return .purchased
    }

    @MainActor
    func restore() async -> EntitlementOutcome {
        guard isPro else { return .noPurchaseFound }
        await Self.simulateStoreRoundTrip()
        return .restored
    }

    // MARK: - 内部

    private func applyPro(_ newValue: Bool) {
        // 外部から plist を消された場合にも書き戻せるよう、値が同じでも必ず永続化する。
        defaults.set(newValue, forKey: LOEntitlement.userDefaultsKey)
        guard isPro != newValue else { return }
        isPro = newValue
    }

    private static func simulateStoreRoundTrip() async {
        try? await Task.sleep(for: simulatedLatency)
    }
}

// MARK: - Environment 注入

private struct EntitlementStoreKey: EnvironmentKey {
    static let defaultValue: any EntitlementStore = LocalEntitlementStore()
}

extension EnvironmentValues {
    /// View から課金状態を読むための注入口。View は必ずこのプロトコル越しに参照する。
    var entitlements: any EntitlementStore {
        get { self[EntitlementStoreKey.self] }
        set { self[EntitlementStoreKey.self] = newValue }
    }
}
