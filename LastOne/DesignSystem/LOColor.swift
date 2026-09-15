import SwiftUI

/// `docs/design.md` §1「カラー」のトークン。
///
/// v1 は Light 固定のため、ダークモード用のバリアントは定義しない
/// （ルートで `.preferredColorScheme(.light)` を指定している）。
enum LOColor {

    // MARK: - 背景

    /// アプリ全体 / シートの背景（生成りの紙色）。
    static let background = Color(hex: 0xFAF5EE)
    /// ヘッダー背景グラデーションの上端。
    static let backgroundTop = Color(hex: 0xFDFAF5)
    /// カード背景。
    static let card = Color(hex: 0xFFFFFF)
    /// カード内の操作ブロック背景。
    static let subBackground = Color(hex: 0xFBF6EF)

    // MARK: - テキスト

    /// 見出し・アイテム名。
    static let textPrimary = Color(hex: 0x413830)
    /// 設定行ラベル。
    static let textBody = Color(hex: 0x4A4038)
    /// 説明文。
    static let textSecondary = Color(hex: 0x8C8073)
    /// ボタン文字（淡いボタン上）。
    static let textSecondaryAlt = Color(hex: 0x8A7D6E)
    /// 補足。
    static let textTertiary = Color(hex: 0xA79C91)
    /// 最終購入日。
    static let textTertiaryAlt = Color(hex: 0xB0A496)
    /// kicker。
    static let textFaint = Color(hex: 0xC0B4A5)
    /// 脚注。
    static let textFootnote = Color(hex: 0xB5A996)
    /// 非選択タブ。
    static let textTabInactive = Color(hex: 0xBDB1A2)
    /// セクション見出し（カテゴリ名）。
    static let sectionTitle = Color(hex: 0x9A8D7E)
    /// セクション件数。
    static let sectionCount = Color(hex: 0xC4B8A8)
    /// 空状態パネルのタイトル。
    static let emptyTitle = Color(hex: 0x6E6357)

    // MARK: - アクセント

    /// 主要アクション（「買った」「追加する」）。
    static let accent = Color(hex: 0x8FB89E)
    /// 主要アクションの押下時。
    static let accentPressed = Color(hex: 0x7FA588)
    /// 選択タブの文字色。
    static let accentDeep = Color(hex: 0x5E7F62)
    /// 選択タブの背景 `rgba(143,184,158,.16)`。
    static let tabSelectedBackground = Color(hex: 0x8FB89E, opacity: 0.16)

    // MARK: - 状態チップ（赤系の警告色は使わない）

    static let chipInStockBackground = Color(hex: 0xEAF2E9)
    static let chipInStockText = Color(hex: 0x688B6D)
    static let chipLowBackground = Color(hex: 0xFCEADC)
    static let chipLowText = Color(hex: 0xC4713C)
    /// Buy List 行のカテゴリチップ。
    static let chipCategoryBackground = Color(hex: 0xF4EEE5)
    static let chipCategoryText = Color(hex: 0x9A8D7E)

    // MARK: - Pro（ゴールド）

    static let pro = Color(hex: 0xC99A56)
    static let proPressed = Color(hex: 0xB98A47)
    static let proCardTop = Color(hex: 0xFDF3E2)
    static let proCardBottom = Color(hex: 0xF8E7CF)
    static let proHeading = Color(hex: 0x6E4F26)
    static let proBody = Color(hex: 0x9A7A4C)
    static let proLabel = Color(hex: 0xB08344)
    /// Pro カードの購入状態ラベル。
    static let proStatusText = Color(hex: 0x8A6634)
    /// PRO バッジの背景（白 75%）。
    static let proBadgeBackground = Color.white.opacity(0.75)
    /// 「リストア」ボタンの背景（白 70%）。
    static let proSecondaryButtonBackground = Color.white.opacity(0.70)

    // MARK: - Paywall

    /// Paywall シートの背景グラデーション（`#FDF6EA` → `#FAF1E3`）。
    static let paywallSheetTop = Color(hex: 0xFDF6EA)
    static let paywallSheetBottom = Color(hex: 0xFAF1E3)
    /// Paywall のドラッグハンドル。
    static let paywallDragHandle = Color(hex: 0xE9DCC6)
    /// 星アイコンを載せる金色の円（`#FBE3BC` → `#EFC98F`）。
    static let proStarTop = Color(hex: 0xFBE3BC)
    static let proStarBottom = Color(hex: 0xEFC98F)
    /// 特典 3 行の背景（白 70%）と文字。
    static let proPerkBackground = Color.white.opacity(0.70)
    static let proPerkText = Color(hex: 0x7A5F35)
    /// 「購入をリストア」のリンク文字。
    static let proRestoreText = Color(hex: 0xA98C5F)

    // MARK: - 線

    /// 設定リストの区切り線。
    static let divider = Color(hex: 0xF4EDE3)
    static let border = Color(hex: 0xE7DCCC)
    static let borderInput = Color(hex: 0xEBE0D0)
    static let borderSubtle = Color(hex: 0xEEE3D4)
    /// 破線ボーダー（追加ボタン）。
    static let borderDashed = Color(hex: 0xE0D3C0)
    /// タブバー上端の罫線 / 空状態パネルの枠。
    static let borderPanel = Color(hex: 0xF0E7DA)
    /// シート上端のドラッグハンドル。
    static let dragHandle = Color(hex: 0xE4D9C9)
    /// 設定行の右端シェブロン。
    static let chevron = Color(hex: 0xCFC3B4)
    /// カテゴリ管理シートの並べ替えハンドル。
    static let listHandle = Color(hex: 0xD6C9B6)
    /// Buy List 行の淡いアプリコット枠（`rgba(196,113,60,.10)`）。
    static let borderBuyRow = Color(hex: 0xC4713C, opacity: 0.10)

    // MARK: - 空状態の「空のかご」イラスト

    /// かご本体の面 / 枠。
    static let basketBody = Color(hex: 0xEDF3EC)
    static let basketBodyBorder = Color(hex: 0xD8E6D8)
    /// かごの縁の面 / 枠（持ち手の線も同色）。
    static let basketRim = Color(hex: 0xE2EEE2)
    static let basketRimBorder = Color(hex: 0xD2E2D2)
    /// かごの上に舞う粒（アプリコット / ゴールド / ベージュ）。
    static let basketDotApricot = Color(hex: 0xFCEADC)
    static let basketDotGold = Color(hex: 0xF6E8CE)
    static let basketDotBeige = Color(hex: 0xE7DCCC)

    // MARK: - オーバーレイ / シャドウ

    static let overlay = Color(hex: 0x413830, opacity: 0.28)
    static let overlayPaywall = Color(hex: 0x413830, opacity: 0.32)

    static let shadowCard = Color(hex: 0x967C60, opacity: 0.09)
    static let shadowPrimaryButton = Color(hex: 0x8FB89E, opacity: 0.40)
    static let shadowProButton = Color(hex: 0xC99A56, opacity: 0.35)
    static let shadowSheet = Color(hex: 0x413830, opacity: 0.18)

    // MARK: - グラデーション

    /// ヘッダー背景（`#FDFAF5` → `#FAF5EE`）。
    static let headerGradient = LinearGradient(
        colors: [backgroundTop, background],
        startPoint: .top,
        endPoint: .bottom
    )

    /// セクション見出しの右に伸びる罫線。
    static let sectionRuleGradient = LinearGradient(
        colors: [border, border.opacity(0)],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// 空状態パネルの背景（`#FDFAF5` → `#F8F2E9`）。
    static let emptyPanelGradient = LinearGradient(
        colors: [backgroundTop, Color(hex: 0xF8F2E9)],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Pro カードの背景（`#FDF3E2` → `#F8E7CF`）。
    static let proCardGradient = LinearGradient(
        colors: [proCardTop, proCardBottom],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Paywall シートの背景（CSS の `linear-gradient(170deg, …)` 相当のわずかな傾き）。
    static let paywallSheetGradient = LinearGradient(
        colors: [paywallSheetTop, paywallSheetBottom],
        startPoint: UnitPoint(x: 0.42, y: 0),
        endPoint: UnitPoint(x: 0.58, y: 1)
    )

    /// Paywall の星アイコンを載せる円（`radial-gradient(circle at 32% 28%, …)` 相当）。
    static let proStarGradient = RadialGradient(
        colors: [proStarTop, proStarBottom],
        center: UnitPoint(x: 0.32, y: 0.28),
        startRadius: 2,
        endRadius: 62
    )
}
