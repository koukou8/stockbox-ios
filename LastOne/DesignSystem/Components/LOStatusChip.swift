import SwiftUI

/// 状態チップ（在庫あり / のこり1つ）。色は 2 色のみで、赤系の警告色は使わない。
struct LOStatusChip: View {
    let status: StockStatus

    var body: some View {
        Text(L.statusChip(status))
            .font(LOFont.chip)
            .foregroundStyle(foreground)
            .contentTransition(.opacity)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(background, in: Capsule())
            .accessibilityIdentifier("chip.\(status.rawValue)")
    }

    private var background: Color {
        switch status {
        case .inStock: return LOColor.chipInStockBackground
        case .low: return LOColor.chipLowBackground
        }
    }

    private var foreground: Color {
        switch status {
        case .inStock: return LOColor.chipInStockText
        case .low: return LOColor.chipLowText
        }
    }
}

/// カテゴリ名を表す淡いチップ（Buy List 行で使用）。
struct LOCategoryChip: View {
    let name: String

    var body: some View {
        Text(name)
            .font(LOFont.caption)
            .foregroundStyle(LOColor.chipCategoryText)
            .lineLimit(1)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(LOColor.chipCategoryBackground, in: Capsule())
    }
}
