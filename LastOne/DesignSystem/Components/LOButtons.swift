import SwiftUI

/// 主要アクションのカプセルボタン（`#8FB89E` / 白文字 / ボタンシャドウ）。
/// 「買った」など。
struct LOPrimaryCapsuleButton: View {
    let title: LocalizedStringKey
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(LOFont.primaryButton)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 17)
                .padding(.vertical, 11)
        }
        .background(LOColor.accent, in: Capsule())
        .loPrimaryButtonShadow()
        .buttonStyle(LOPressableButtonStyle())
    }
}

/// シート内の全幅ボタン（角丸 20・`#8FB89E`）。
struct LOPrimaryWideButton: View {
    let title: LocalizedStringKey
    var font: Font = LOFont.primaryButton
    var isEnabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(font)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
        }
        .background(
            RoundedRectangle(cornerRadius: LORadius.primaryButton, style: .continuous)
                .fill(isEnabled ? LOColor.accent : LOColor.accent.opacity(0.5))
        )
        .loPrimaryButtonShadow()
        .buttonStyle(LOPressableButtonStyle())
        .disabled(!isEnabled)
    }
}

/// 白地・枠線のカプセルボタン（「開封 −1」「ストックを見る」など）。
struct LOQuietCapsuleButton: View {
    let title: LocalizedStringKey
    var horizontalPadding: CGFloat = 16
    var verticalPadding: CGFloat = 9
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(LOFont.smallButton)
                .foregroundStyle(LOColor.textSecondaryAlt)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)
        }
        .background(LOColor.card, in: Capsule())
        .overlay(Capsule().stroke(LOColor.border, lineWidth: 1))
        .buttonStyle(LOPressableButtonStyle())
    }
}

/// カード下段の全幅な淡いボタン（二値方式の操作行）。
struct LOSubtleWideButton: View {
    let title: LocalizedStringKey
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(LOFont.subtleButton)
                .foregroundStyle(LOColor.textSecondaryAlt)
                // 状態が反転してラベルが差し替わるときに控えめにクロスフェードさせる。
                .contentTransition(.opacity)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .padding(.horizontal, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: LORadius.block, style: .continuous)
                .fill(LOColor.subBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: LORadius.block, style: .continuous)
                        .stroke(LOColor.borderSubtle, lineWidth: 1)
                )
        )
        .buttonStyle(LOPressableButtonStyle())
    }
}

/// 破線ボーダーの追加ボタン（「＋ アイテムを追加」「＋ カテゴリを追加」）。
struct LODashedAddButton: View {
    let title: LocalizedStringKey
    var cornerRadius: CGFloat = LORadius.card
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(LOFont.primaryButton)
                .foregroundStyle(Color(hex: 0xA2957F))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(LOColor.card.opacity(0.55))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LOColor.borderDashed,
                            style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                        )
                )
        )
        .buttonStyle(LOPressableButtonStyle())
    }
}

/// 押下時に軽く沈むボタンスタイル（`docs/design.md` §1「モーション」の控えめな指針に合わせる）。
struct LOPressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.75 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}
