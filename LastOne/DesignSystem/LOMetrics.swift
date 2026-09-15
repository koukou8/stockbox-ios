import SwiftUI

/// `docs/design.md` §1「角丸」と共通レイアウト値のトークン。
enum LORadius {
    /// アイテムカード / Buy List 行。
    static let card: CGFloat = 22
    /// 設定カード。
    static let settingsCard: CGFloat = 24
    /// Pro カード。
    static let proCard: CGFloat = 26
    /// パネル（空状態）/ シート上端。
    static let panel: CGFloat = 30
    /// Paywall シート上端。
    static let paywallSheet: CGFloat = 32
    /// カード内の操作ブロック。
    static let block: CGFloat = 16
    /// シート内の主要ボタン。
    static let primaryButton: CGFloat = 20
    /// シート内の 2 択カード。
    static let choiceCard: CGFloat = 18
    /// カテゴリ管理シートの行。
    static let categoryRow: CGFloat = 18
    /// タブバーの選択背景。
    static let tabSelection: CGFloat = 18
    /// カプセル。
    static let capsule: CGFloat = 999
}

/// 共通シェルのレイアウト値（`docs/design.md` §2）。
enum LOLayout {
    /// ヘッダー padding 64 / 22 / 14。
    static let headerTop: CGFloat = 64
    static let headerHorizontal: CGFloat = 22
    static let headerBottom: CGFloat = 14

    /// コンテンツ padding 8 / 18 / 22。
    static let contentTop: CGFloat = 8
    static let contentHorizontal: CGFloat = 18
    static let contentBottom: CGFloat = 22
    /// コンテンツの要素間。
    static let contentSpacing: CGFloat = 14
}

extension View {
    /// カードシャドウ（`y8 blur22 rgba(150,124,96,0.09)` 相当）。
    func loCardShadow() -> some View {
        shadow(color: LOColor.shadowCard, radius: 11, x: 0, y: 5)
    }

    /// 主要ボタンのシャドウ（`y6 blur14 rgba(143,184,158,0.40)` 相当）。
    func loPrimaryButtonShadow() -> some View {
        shadow(color: LOColor.shadowPrimaryButton, radius: 7, x: 0, y: 3)
    }

    /// Pro ボタンのシャドウ（`y8-10 blur18-24 rgba(201,154,86,0.35)` 相当）。
    func loProButtonShadow() -> some View {
        shadow(color: LOColor.shadowProButton, radius: 11, x: 0, y: 5)
    }
}
