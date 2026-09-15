import SwiftUI

/// 選択できるカプセルチップ（アイテム追加シートのカテゴリ選択）。
///
/// 選択時は `#8FB89E` / 白文字、非選択は白地・枠 `#EBE0D0` ・文字 `#8A7D6E`。
struct LOSelectableChip: View {
    let title: String
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(LOFont.chipSelectable)
                .foregroundStyle(isSelected ? Color.white : LOColor.textSecondaryAlt)
                .lineLimit(1)
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
        }
        .background(isSelected ? LOColor.accent : LOColor.card, in: Capsule())
        .overlay(
            Capsule().stroke(isSelected ? LOColor.accent : LOColor.borderInput, lineWidth: 1)
        )
        .buttonStyle(LOPressableButtonStyle())
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}

/// 2 択カード（アイテム追加シートの管理方式選択）。
///
/// タイトル + サブテキストを縦に積んだ角丸 18 のカード。選択時の配色はチップと同じ。
struct LOChoiceCard: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text(title)
                    .font(LOFont.choiceCardTitle)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(subtitle)
                    .font(LOFont.choiceCardSubtitle)
                    .opacity(0.7)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(isSelected ? Color.white : LOColor.textSecondaryAlt)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .padding(.horizontal, 10)
        }
        .background(
            RoundedRectangle(cornerRadius: LORadius.choiceCard, style: .continuous)
                .fill(isSelected ? LOColor.accent : LOColor.card)
                .overlay(
                    RoundedRectangle(cornerRadius: LORadius.choiceCard, style: .continuous)
                        .stroke(isSelected ? LOColor.accent : LOColor.borderInput, lineWidth: 1)
                )
        )
        .buttonStyle(LOPressableButtonStyle())
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}

/// シート内のセクション見出し（「カテゴリ」「管理方式」）。11.5 / medium・`#A79C91`。
struct LOFieldLabel: View {
    let title: LocalizedStringKey

    var body: some View {
        Text(title)
            .font(LOFont.fieldLabel)
            .foregroundStyle(LOColor.textTertiary)
    }
}
