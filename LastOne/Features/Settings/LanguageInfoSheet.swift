import SwiftUI
import UIKit

/// 「言語について」のシート。
///
/// アプリ内に独自の言語切替 UI は置かない（`docs/spec.md`「MVP 内の意図的な制限」）。
/// 端末の設定に追従することの説明と、iOS 設定アプリへの導線だけを持つ。
struct LanguageInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Capsule()
                .fill(LOColor.dragHandle)
                .frame(width: 44, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 14)

            Text(L.settingsLanguage)
                .font(LOFont.sheetTitle)
                .foregroundStyle(LOColor.textPrimary)

            Text(L.languageSheetBody)
                .font(LOFont.body)
                .lineSpacing(6)
                .foregroundStyle(LOColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            VStack(spacing: 12) {
                LOPrimaryWideButton(title: L.openSettings, font: LOFont.sheetButton) {
                    openSystemSettings()
                }
                .accessibilityIdentifier("language.openSettings")

                Button {
                    dismiss()
                } label: {
                    Text(L.close)
                        .font(LOFont.subtleButton)
                        .foregroundStyle(LOColor.textSecondaryAlt)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(LOPressableButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.bottom, 28)
        .background(LOColor.background)
        .presentationDetents([.height(320), .medium])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(LORadius.panel)
        .presentationBackground(LOColor.background)
        .accessibilityIdentifier("sheet.languageInfo")
    }

    /// iOS の「設定 > LastOne」を開く。開けなければ何もしない（クラッシュさせない）。
    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
        dismiss()
    }
}
