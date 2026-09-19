import SwiftUI

/// Paywall の表示要求。`.sheet(item:)` に渡す。
///
/// 表示理由（`PaywallReason`）は理由テキストの出し分けと `paywall_shown` の property を兼ねる。
struct PaywallPresentation: Identifiable {
    let reason: PaywallReason

    var id: String { reason.rawValue }

    /// 無料枠のアイテム上限に達した。
    static let itemLimit = PaywallPresentation(reason: .itemLimit)
    /// 無料枠のカテゴリ上限に達した。
    static let categoryLimit = PaywallPresentation(reason: .categoryLimit)
    /// Settings の「Pro を見る」から開いた。
    static let settings = PaywallPresentation(reason: .settings)
}

/// Paywall シート（`docs/design.md` §2「Paywall シート」）。
///
/// グラデ背景 → 金色の円に星アイコン（74pt）→「StockBox Pro」→ 表示理由テキスト
/// → 特典 3 行（チェックアイコン）→ 価格 CTA → 「購入をリストア」。
///
/// - 購入 / リストアは `EntitlementStore` プロトコル越しにのみ行う（View は SDK に触れない）。
/// - 「購入をリストア」は **App Store の審査要件**のため、購入済みかどうかに関わらず常に押せる。
struct PaywallSheet: View {
    /// 表示理由。テキストの出し分けと計測に使う。
    let reason: PaywallReason

    @Environment(\.dismiss) private var dismiss
    @Environment(\.entitlements) private var entitlements
    @Environment(\.analytics) private var analytics

    /// 購入 / リストアの実行中（二度押しを防ぎ、CTA をローディング表示に切り替える）。
    @State private var isBusy = false
    @State private var alert: EntitlementAlert?
    /// 内容の実寸に合わせてシートの高さを決める（言語・Dynamic Type で高さが変わるため）。
    @State private var contentHeight: CGFloat = PaywallSheet.fallbackHeight

    /// 実寸が取れるまでの暫定値。
    private static let fallbackHeight: CGFloat = 560

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                dragHandle
                starBadge

                Text(L.paywallTitle)
                    .font(LOFont.paywallTitle)
                    .foregroundStyle(LOColor.proHeading)
                    .multilineTextAlignment(.center)

                Text(L.paywallReason(reason))
                    .font(LOFont.paywallReason)
                    .lineSpacing(9)
                    .foregroundStyle(LOColor.proBody)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 280)
                    .accessibilityIdentifier("paywall.reason")

                perks
                priceButton
                restoreButton
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 22)
            .padding(.top, 16)
            .padding(.bottom, 36)
            .background(heightReader)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .background(LOColor.paywallSheetGradient)
        .presentationDetents([.height(contentHeight)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(LORadius.paywallSheet)
        .presentationBackground(LOColor.paywallSheetGradient)
        .loEntitlementAlert($alert)
        .onAppear {
            // 実際に表示されたタイミングで 1 回だけ発火する（理由を property に付与）。
            analytics.track(.paywallShown(reason: reason))
        }
        .accessibilityIdentifier("sheet.paywall")
    }

    // MARK: - パーツ

    private var dragHandle: some View {
        Capsule()
            .fill(LOColor.paywallDragHandle)
            .frame(width: 44, height: 5)
            .accessibilityHidden(true)
    }

    /// 金色の円に星アイコン（74pt）。装飾なので VoiceOver からは隠す。
    private var starBadge: some View {
        Circle()
            .fill(LOColor.proStarGradient)
            .frame(width: 74, height: 74)
            .overlay(
                Image(systemName: "star")
                    .font(.system(size: 31, weight: .regular))
                    .foregroundStyle(.white)
            )
            .shadow(color: LOColor.shadowProButton.opacity(0.85), radius: 12, x: 0, y: 5)
            .padding(.top, 6)
            .accessibilityHidden(true)
    }

    /// 特典 3 行（チェックアイコン + 文言）。
    private var perks: some View {
        VStack(spacing: 9) {
            ForEach(Array(L.perks.enumerated()), id: \.offset) { _, perk in
                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(LOColor.pro)
                        .accessibilityHidden(true)

                    Text(perk)
                        .font(LOFont.perk)
                        .foregroundStyle(LOColor.proPerkText)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: LORadius.block, style: .continuous)
                        .fill(LOColor.proPerkBackground)
                )
                .accessibilityElement(children: .combine)
            }
        }
        .padding(.top, 4)
        .padding(.bottom, 2)
        .accessibilityIdentifier("paywall.perks")
    }

    /// 価格 CTA（`#C99A56`）。押すと購入し、成功したらシートを閉じる。
    private var priceButton: some View {
        Button {
            Task { await purchase() }
        } label: {
            ZStack {
                Text(L.priceCta)
                    .font(LOFont.sheetButton)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .opacity(isBusy ? 0 : 1)

                if isBusy {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
        }
        .background(
            RoundedRectangle(cornerRadius: LORadius.primaryButton, style: .continuous)
                .fill(LOColor.pro)
        )
        .loProButtonShadow()
        .buttonStyle(LOPressableButtonStyle())
        .disabled(isBusy)
        .accessibilityLabel(Text(L.priceCta))
        .accessibilityIdentifier("paywall.purchase")
    }

    /// 「購入をリストア」。審査要件のため常設し、実行中以外は必ず押せる。
    private var restoreButton: some View {
        Button {
            Task { await restore() }
        } label: {
            Text(L.restore)
                .font(LOFont.restoreLink)
                .foregroundStyle(LOColor.proRestoreText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(6)
        }
        .buttonStyle(LOPressableButtonStyle())
        .disabled(isBusy)
        .accessibilityLabel(Text(L.restore))
        .accessibilityIdentifier("paywall.restore")
    }

    /// 内容の実寸を測ってシートの高さに反映する。上限は SwiftUI 側でクランプされ、
    /// 収まらない場合はスクロールできる。
    private var heightReader: some View {
        GeometryReader { proxy in
            Color.clear.preference(key: PaywallHeightKey.self, value: proxy.size.height)
        }
        .onPreferenceChange(PaywallHeightKey.self) { height in
            guard height > 0, abs(height - contentHeight) > 1 else { return }
            contentHeight = height
        }
    }

    // MARK: - 課金

    private func purchase() async {
        guard !isBusy else { return }
        isBusy = true
        let outcome = await entitlements.purchase()
        isBusy = false

        switch outcome {
        case .purchased, .restored:
            analytics.track(.proPurchased)
            dismiss()
        case .cancelled:
            break
        case .noPurchaseFound, .failed:
            alert = .purchaseFailed
        }
    }

    private func restore() async {
        guard !isBusy else { return }
        isBusy = true
        let outcome = await entitlements.restore()
        isBusy = false

        switch outcome {
        case .purchased, .restored:
            dismiss()
        case .cancelled:
            break
        case .noPurchaseFound:
            alert = .noPurchaseFound
        case .failed:
            alert = .purchaseFailed
        }
    }
}

/// 内容の実寸をシートの detent に渡すための PreferenceKey。
private struct PaywallHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            PaywallSheet(reason: .itemLimit)
        }
}
