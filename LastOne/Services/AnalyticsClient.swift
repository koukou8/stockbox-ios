import Foundation
import SwiftUI

/// 計測イベント。
///
/// イベント名は `docs/spec/lastone-app.md`「計測（アナリティクス）」に合わせて固定文字列で持つ。
/// 実際の発火は Sprint 2 以降で各機能から行う。
struct AnalyticsEvent: Equatable, Sendable {
    let name: String
    let properties: [String: String]

    init(name: String, properties: [String: String] = [:]) {
        self.name = name
        self.properties = properties
    }

    // MARK: - コアループ

    /// 「買うものリストに追加」（残りわずかチェック）。
    static let itemMarkedLow = AnalyticsEvent(name: "item_marked_low")
    /// 「買った」タップ。
    static let itemPurchased = AnalyticsEvent(name: "item_purchased")
    /// カウント方式の「開封 −1」。
    static let itemOpened = AnalyticsEvent(name: "item_opened")

    // MARK: - 定着

    static let itemCreated = AnalyticsEvent(name: "item_created")
    static let categoryCreated = AnalyticsEvent(name: "category_created")

    // MARK: - 課金ファネル

    /// Paywall 表示。表示理由を property として付与する。
    static func paywallShown(reason: PaywallReason) -> AnalyticsEvent {
        AnalyticsEvent(name: "paywall_shown", properties: ["reason": reason.rawValue])
    }

    static let proPurchased = AnalyticsEvent(name: "pro_purchased")
}

/// Paywall を開いた理由。表示テキストの出し分けと計測の property を兼ねる。
enum PaywallReason: String, Codable, CaseIterable, Sendable {
    /// アイテム上限に達した。
    case itemLimit = "item_limit"
    /// カテゴリ上限に達した。
    case categoryLimit = "category_limit"
    /// Settings の「Pro を見る」から。
    case settings = "settings"
}

/// 計測クライアントの抽象。
///
/// MVP では実 SDK を導入せず、`LoggingAnalyticsClient` のスタブだけを使う。
///
/// ## 実 SDK（PostHog）への差し替え手順
/// 1. Swift Package で PostHog iOS SDK を追加する。
/// 2. `final class PostHogAnalyticsClient: AnalyticsClient` を新規に作り、
///    `track(_:)` の中で `PostHogSDK.shared.capture(event.name, properties: event.properties)` を呼ぶ。
/// 3. `LastOneApp` で注入するインスタンスを差し替える。View 側の変更は不要。
protocol AnalyticsClient: AnyObject {
    func track(_ event: AnalyticsEvent)
}

/// MVP 用のスタブ実装。標準出力にイベントを流すだけで、ネットワーク送信は行わない。
final class LoggingAnalyticsClient: AnalyticsClient {
    func track(_ event: AnalyticsEvent) {
        if event.properties.isEmpty {
            print("[analytics] \(event.name)")
        } else {
            let props = event.properties
                .sorted { $0.key < $1.key }
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: " ")
            print("[analytics] \(event.name) \(props)")
        }
    }
}

// MARK: - Environment 注入

private struct AnalyticsClientKey: EnvironmentKey {
    static let defaultValue: any AnalyticsClient = LoggingAnalyticsClient()
}

extension EnvironmentValues {
    /// View から計測を発火するための注入口。View は必ずこのプロトコル越しに参照する。
    var analytics: any AnalyticsClient {
        get { self[AnalyticsClientKey.self] }
        set { self[AnalyticsClientKey.self] = newValue }
    }
}
