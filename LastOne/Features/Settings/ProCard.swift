import SwiftUI

/// Settings 先頭の Pro カード（`docs/design.md` §2「Settings（タブ3）」）。
///
/// ゴールドグラデ `#FDF3E2` → `#F8E7CF`、PRO バッジ + 購入状態 + 見出し + 説明 +
/// 「Pro を見る」/「リストア」。
///
/// Pro のときは「Pro を見る」CTA を購入済み表示に差し替える。
/// 「リストア」は **App Store の審査要件**のため、購入状態に関わらず常に押せる。
struct ProCard: View {
    /// 購入状態（`EntitlementStore.isPro`）。
    var isPro: Bool = false
    /// リストアの実行中。ボタンをローディング表示にして二度押しを防ぐ。
    var isRestoring: Bool = false
    /// 「Pro を見る」。Paywall シートを `proReason` で開く。
    var onSeePro: () -> Void
    /// 「リストア」。審査要件のため常に押せる位置に置く。
    var onRestore: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text(L.proBadge)
                    .font(LOFont.proBadge)
                    .tracking(LOFont.proBadgeTracking)
                    .foregroundStyle(LOColor.proLabel)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(LOColor.proBadgeBackground, in: Capsule())

                Text(L.proStatus(isPro: isPro))
                    .font(LOFont.proStatus)
                    .foregroundStyle(LOColor.proStatusText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Text(L.proHead)
                .font(LOFont.proHead)
                .foregroundStyle(LOColor.proHeading)
                .fixedSize(horizontal: false, vertical: true)

            Text(L.proSub)
                .font(LOFont.body)
                .lineSpacing(5)
                .foregroundStyle(LOColor.proBody)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                primaryAction
                restoreButton
            }
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: LORadius.proCard, style: .continuous)
                .fill(LOColor.proCardGradient)
        )
        .shadow(color: LOColor.shadowProButton.opacity(0.45), radius: 13, x: 0, y: 5)
        .accessibilityIdentifier("settings.proCard")
    }

    // MARK: - CTA

    /// 未購入なら「Pro を見る」、購入済みならタップできない購入済み表示に切り替える。
    @ViewBuilder
    private var primaryAction: some View {
        if isPro {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .accessibilityHidden(true)

                Text(L.proActive)
                    .font(LOFont.primaryButton)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: LORadius.block, style: .continuous)
                    .fill(LOColor.pro)
            )
            .loProButtonShadow()
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("settings.proActive")
        } else {
            Button(action: onSeePro) {
                Text(L.seePro)
                    .font(LOFont.primaryButton)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
            }
            .background(
                RoundedRectangle(cornerRadius: LORadius.block, style: .continuous)
                    .fill(LOColor.pro)
            )
            .loProButtonShadow()
            .buttonStyle(LOPressableButtonStyle())
            .accessibilityLabel(Text(L.seePro))
            .accessibilityIdentifier("settings.seePro")
        }
    }

    /// 「リストア」。購入済みでも押せる（審査要件）。
    private var restoreButton: some View {
        Button(action: onRestore) {
            ZStack {
                Text(L.restoreShort)
                    .font(LOFont.subtleButton)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .opacity(isRestoring ? 0 : 1)

                if isRestoring {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(LOColor.proBody)
                }
            }
            .foregroundStyle(LOColor.proBody)
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
        }
        .background(
            RoundedRectangle(cornerRadius: LORadius.block, style: .continuous)
                .fill(LOColor.proSecondaryButtonBackground)
        )
        .buttonStyle(LOPressableButtonStyle())
        .disabled(isRestoring)
        .accessibilityLabel(Text(L.restore))
        .accessibilityIdentifier("settings.restore")
    }
}

#Preview {
    VStack(spacing: 14) {
        ProCard(isPro: false, onSeePro: {}, onRestore: {})
        ProCard(isPro: true, onSeePro: {}, onRestore: {})
    }
    .padding(18)
    .background(LOColor.background)
}
