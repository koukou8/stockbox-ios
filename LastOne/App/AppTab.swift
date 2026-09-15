import SwiftUI

/// 下部タブバーの 3 タブ。
enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case buyList
    case stocks
    case settings

    var id: String { rawValue }

    /// タブバーのラベル（＝画面タイトル）。
    var title: LocalizedStringKey {
        switch self {
        case .buyList: return L.tabBuy
        case .stocks: return L.tabStocks
        case .settings: return L.tabSettings
        }
    }

    /// 画面ヘッダーの kicker（英語表記固定）。
    var kicker: LocalizedStringKey {
        switch self {
        case .buyList: return L.kickerBuy
        case .stocks: return L.kickerStocks
        case .settings: return L.kickerSettings
        }
    }

    /// SF Symbols（カート / 箱 / 歯車）。線幅 1.7 相当の線画になるよう weight は regular。
    var symbolName: String {
        switch self {
        case .buyList: return "cart"
        case .stocks: return "shippingbox"
        case .settings: return "gearshape"
        }
    }

    /// UI テスト用の識別子。
    var accessibilityIdentifier: String { "tab.\(rawValue)" }
}
