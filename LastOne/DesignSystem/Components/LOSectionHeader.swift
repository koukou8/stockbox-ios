import SwiftUI

/// カテゴリセクションの見出し行。
/// カテゴリ名（13/medium）＋ 件数（11/semibold）＋ 右に伸びるグラデ罫線。
struct LOSectionHeader: View {
    let title: String
    /// 整形済みの件数ラベル（「3件」/ "3 items"）。
    let countLabel: String

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(LOFont.sectionTitle)
                .foregroundStyle(LOColor.sectionTitle)
                .lineLimit(1)

            Text(countLabel)
                .font(LOFont.sectionCount)
                .foregroundStyle(LOColor.sectionCount)
                .lineLimit(1)

            LOColor.sectionRuleGradient
                .frame(height: 1)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 4)
    }
}
