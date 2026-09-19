import SwiftUI

/// `docs/design.md` §1「タイポグラフィ」のトークン。
///
/// プロトタイプの Zen Maru Gothic / Quicksand は同梱せず、
/// SF Rounded（`.fontDesign(.rounded)` 相当）で代替する。
enum LOFont {
    /// 画面 kicker（12 / medium・letterSpacing 0.14em・uppercase）。
    static let kicker = Font.system(size: 12, weight: .medium, design: .rounded)
    /// kicker の字間（0.14em × 12pt）。
    static let kickerTracking: CGFloat = 12 * 0.14

    /// 画面タイトル（27 / bold）。
    static let screenTitle = Font.system(size: 27, weight: .bold, design: .rounded)
    /// 画面メタ（右上・12 / regular）。
    static let screenMeta = Font.system(size: 12, weight: .regular, design: .rounded)

    /// セクション見出し（カテゴリ名・13 / medium）。
    static let sectionTitle = Font.system(size: 13, weight: .medium, design: .rounded)
    /// セクション件数（11 / semibold）。
    static let sectionCount = Font.system(size: 11, weight: .semibold, design: .rounded)

    /// アイテム名（16 / medium）。
    static let itemName = Font.system(size: 16, weight: .medium, design: .rounded)
    /// 最終購入日・補足（11.5 / regular）。
    static let caption = Font.system(size: 11.5, weight: .regular, design: .rounded)
    /// チップ（11.5 / medium）。
    static let chip = Font.system(size: 11.5, weight: .medium, design: .rounded)

    /// 主要ボタン（13.5 / medium）。
    static let primaryButton = Font.system(size: 13.5, weight: .medium, design: .rounded)
    /// 小さめのカプセルボタン（12.5 / medium）。
    static let smallButton = Font.system(size: 12.5, weight: .medium, design: .rounded)
    /// カード内の淡いボタン（13 / medium）。
    static let subtleButton = Font.system(size: 13, weight: .medium, design: .rounded)

    /// 設定行ラベル（14.5 / medium）。
    static let settingsRow = Font.system(size: 14.5, weight: .medium, design: .rounded)
    /// 設定行の右側の値（12.5 / regular）。
    static let settingsValue = Font.system(size: 12.5, weight: .regular, design: .rounded)

    /// シートタイトル（20 / bold）。
    static let sheetTitle = Font.system(size: 20, weight: .bold, design: .rounded)
    /// シート内のフィールド見出し（「カテゴリ」「管理方式」・11.5 / medium）。
    static let fieldLabel = Font.system(size: 11.5, weight: .medium, design: .rounded)
    /// シート内のテキスト入力（15 / regular）。
    static let textInput = Font.system(size: 15, weight: .regular, design: .rounded)
    /// シート内の主要ボタン（15 / medium）。
    static let sheetButton = Font.system(size: 15, weight: .medium, design: .rounded)
    /// 選択チップ（13 / medium）。
    static let chipSelectable = Font.system(size: 13, weight: .medium, design: .rounded)
    /// 2 択カードのタイトル（13 / medium）。
    static let choiceCardTitle = Font.system(size: 13, weight: .medium, design: .rounded)
    /// 2 択カードのサブテキスト（10.5 / regular）。
    static let choiceCardSubtitle = Font.system(size: 10.5, weight: .regular, design: .rounded)
    /// カウント数値（20 / bold）。
    static let countValue = Font.system(size: 20, weight: .bold, design: .rounded)

    /// 空状態パネルのタイトル（16 / medium）。
    static let emptyTitle = Font.system(size: 16, weight: .medium, design: .rounded)

    /// Pro カードの PRO バッジ（10.5 / semibold・字間 0.12em）。
    static let proBadge = Font.system(size: 10.5, weight: .semibold, design: .rounded)
    static let proBadgeTracking: CGFloat = 10.5 * 0.12
    /// Pro カードの購入状態ラベル（14 / medium）。
    static let proStatus = Font.system(size: 14, weight: .medium, design: .rounded)
    /// Pro カードの見出し（19 / bold）。
    static let proHead = Font.system(size: 19, weight: .bold, design: .rounded)

    /// Paywall のタイトル「StockBox Pro」（22 / bold）。
    static let paywallTitle = Font.system(size: 22, weight: .bold, design: .rounded)
    /// Paywall の表示理由テキスト（13 / regular・行間広め）。
    static let paywallReason = Font.system(size: 13, weight: .regular, design: .rounded)
    /// Paywall の特典 1 行（13 / regular）。
    static let perk = Font.system(size: 13, weight: .regular, design: .rounded)
    /// 「購入をリストア」（12.5 / regular）。
    static let restoreLink = Font.system(size: 12.5, weight: .regular, design: .rounded)

    /// タブラベル（10.5 / medium）。
    static let tabLabel = Font.system(size: 10.5, weight: .medium, design: .rounded)
    /// 脚注（11.5 / regular・行間広め）。
    static let footnote = Font.system(size: 11.5, weight: .regular, design: .rounded)
    /// 本文（12.5 / regular）。
    static let body = Font.system(size: 12.5, weight: .regular, design: .rounded)
}
