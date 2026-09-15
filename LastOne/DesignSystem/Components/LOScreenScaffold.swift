import SwiftUI

/// 共通シェルの画面ヘッダー（`docs/design.md` §2「共通シェル」）。
///
/// padding 64/22/14、kicker → タイトル（左）＋ メタ（右下揃え）。
/// 背景は `#FDFAF5` → `#FAF5EE` の縦グラデーション。
struct LOScreenHeader: View {
    let kicker: LocalizedStringKey
    let title: LocalizedStringKey
    /// 右上のメタ表示。整形済みの文字列を渡す（nil なら非表示）。
    var meta: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(kicker)
                .font(LOFont.kicker)
                .tracking(LOFont.kickerTracking)
                .textCase(.uppercase)
                .foregroundStyle(LOColor.textFaint)

            HStack(alignment: .lastTextBaseline, spacing: 10) {
                Text(title)
                    .font(LOFont.screenTitle)
                    .foregroundStyle(LOColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer(minLength: 0)

                if let meta {
                    Text(meta)
                        .font(LOFont.screenMeta)
                        .foregroundStyle(LOColor.textTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .accessibilityIdentifier("screen.meta")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, LOLayout.headerTop)
        .padding(.horizontal, LOLayout.headerHorizontal)
        .padding(.bottom, LOLayout.headerBottom)
        .background(LOColor.headerGradient)
    }
}

/// 3 タブに共通する画面の骨格。ヘッダー + スクロールするコンテンツ領域。
///
/// コンテンツ領域は padding 8/18/22、要素間 14（`docs/design.md` §2）。
struct LOScreenScaffold<Content: View>: View {
    let kicker: LocalizedStringKey
    let title: LocalizedStringKey
    var meta: String?
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            LOScreenHeader(kicker: kicker, title: title, meta: meta)

            ScrollView {
                VStack(alignment: .leading, spacing: LOLayout.contentSpacing) {
                    content()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, LOLayout.contentTop)
                .padding(.horizontal, LOLayout.contentHorizontal)
                .padding(.bottom, LOLayout.contentBottom)
            }
            .scrollIndicators(.hidden)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(LOColor.background)
    }
}
