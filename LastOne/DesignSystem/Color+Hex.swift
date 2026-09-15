import SwiftUI

extension Color {
    /// `0xRRGGBB` 形式のリテラルから sRGB カラーを作る。
    /// デザイン仕様（`docs/design.md` §1）の Hex をそのまま書けるようにするためのヘルパー。
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
