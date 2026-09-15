import SwiftUI
import UIKit

/// 共有シート（`UIActivityViewController`）の薄いラッパー。
///
/// `ShareLink` は「共有する値」をビューの生成時に確定させる必要があり、
/// エクスポート用の JSON を毎回のレンダリングで組み立てることになってしまう。
/// そのため「タップされたときにファイルを書き出し → その URL を共有する」形にできる
/// この方式を採っている。
struct LOShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        // iPad（Regular 幅）ではポップオーバーの起点が必要になるため、後段で設定できるようにしておく。
        controller.popoverPresentationController?.permittedArrowDirections = []
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

/// `.sheet(item:)` に渡すためのエクスポート済みファイル。
struct LOExportedFile: Identifiable {
    let id = UUID()
    let url: URL
}
