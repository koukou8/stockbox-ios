import SwiftUI

/// Buy List の空状態に置く「空のかご」の幾何イラスト。
///
/// `docs/design.md` §2「Buy List（タブ1）」の空状態パネルに入る挿絵。
/// プロトタイプ（`screen/LastOne App.dc.html`）の 150×112 の座標をそのまま写し、
/// SwiftUI の `Capsule` / `UnevenRoundedRectangle` / `Circle` だけで組んでいる。
///
/// - Note: 本番アセット（PDF / SVG からの Image）に差し替えるときは、
///   このファイルの `body` を `Image("empty-basket").resizable().scaledToFit()` に
///   置き換えるだけでよい。呼び出し側（`BuyListEmptyState`）は
///   このビューのサイズと「ふわふわ上下する」振る舞いに依存していない。
struct EmptyBasketIllustration: View {

    /// プロトタイプの座標系（この寸法を基準に各パーツを配置する）。
    private static let canvas = CGSize(width: 150, height: 112)
    /// ふわふわアニメの振れ幅と周期（CSS の `floatSoft 5.5s` は往復で 5.5 秒）。
    private static let floatOffset: CGFloat = -6
    private static let floatDuration: Double = 2.75

    @State private var isFloating = false
    /// 「動きを減らす」設定では上下アニメを止める。
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .topLeading) {
            // 座標系を固定するための透明な下敷き。
            Color.clear
                .frame(width: Self.canvas.width, height: Self.canvas.height)

            handle
            basketBody
            rim
            dots
        }
        .frame(width: Self.canvas.width, height: Self.canvas.height)
        .offset(y: isFloating ? Self.floatOffset : 0)
        .animation(
            .easeInOut(duration: Self.floatDuration).repeatForever(autoreverses: true),
            value: isFloating
        )
        .onAppear { isFloating = !reduceMotion }
        // 装飾なので読み上げ対象から外す（意味はタイトル・本文が担う）。
        .accessibilityHidden(true)
    }

    // MARK: - パーツ

    /// 持ち手（上側だけ丸い枠線のアーチ）。下端は縁が覆うので線を描かない。
    private var handle: some View {
        UnevenRoundedRectangle(
            topLeadingRadius: 28,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: 28,
            style: .continuous
        )
        .stroke(LOColor.basketRimBorder, lineWidth: 2)
        .frame(width: 54, height: 44)
        .offset(x: 48, y: 14)
    }

    /// かご本体（下側だけ丸い面）。上端は縁が覆う。
    private var basketBody: some View {
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: 0,
            bottomLeadingRadius: 26,
            bottomTrailingRadius: 26,
            topTrailingRadius: 0,
            style: .continuous
        )
        return shape
            .fill(LOColor.basketBody)
            .overlay(shape.stroke(LOColor.basketBodyBorder, lineWidth: 2))
            .frame(width: 122, height: 52)
            .offset(x: 14, y: 52)
    }

    /// かごの縁（横長のカプセル）。
    private var rim: some View {
        Capsule()
            .fill(LOColor.basketRim)
            .overlay(Capsule().stroke(LOColor.basketRimBorder, lineWidth: 2))
            .frame(width: 138, height: 16)
            .offset(x: 6, y: 44)
    }

    /// かごの上に舞う 3 つの粒。
    private var dots: some View {
        ZStack(alignment: .topLeading) {
            dot(color: LOColor.basketDotApricot, size: 16, x: 26, y: 12)
            dot(color: LOColor.basketDotGold, size: 11, x: 110, y: 24)
            dot(color: LOColor.basketDotBeige, size: 7, x: 96, y: 4)
        }
    }

    private func dot(color: Color, size: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .offset(x: x, y: y)
    }
}

#Preview {
    EmptyBasketIllustration()
        .padding(40)
        .background(LOColor.background)
}
