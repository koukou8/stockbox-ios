import SwiftUI

/// 設定リストの 1 行（`docs/design.md` §2「Settings（タブ3）」）。
///
/// ラベル（14.5 / medium `#4A4038`）+ 右側の値（12.5 / regular `#B0A496`）+ 任意のシェブロン。
/// padding 17/18。行間の区切り線は `LOSettingsCard` 側が引く。
struct LOSettingsRow: View {
    let label: LocalizedStringKey
    /// 右側の値。整形済みの文字列（「5 カテゴリ」など）を渡す。
    var value: String?
    /// 遷移を示すシェブロンを出すか。
    var showsChevron: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(label)
                    .font(LOFont.settingsRow)
                    .foregroundStyle(LOColor.textBody)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let value {
                    Text(value)
                        .font(LOFont.settingsValue)
                        .foregroundStyle(LOColor.textTertiaryAlt)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(LOColor.chevron)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 17)
            .contentShape(Rectangle())
        }
        .buttonStyle(LOSettingsRowButtonStyle())
    }
}

/// 設定リストの白カード（角丸 24・カードシャドウ）。行の間に `#F4EDE3` の区切り線を引く。
struct LOSettingsCard<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            content()
        }
        .background(LOColor.card)
        .clipShape(RoundedRectangle(cornerRadius: LORadius.settingsCard, style: .continuous))
        .loCardShadow()
    }
}

/// 設定リストの区切り線。
struct LOSettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(LOColor.divider)
            .frame(height: 1)
    }
}

/// 押下中だけ淡く敷く（プロトタイプの hover `#FDFAF5` 相当）。
private struct LOSettingsRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? LOColor.backgroundTop : Color.clear)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}
