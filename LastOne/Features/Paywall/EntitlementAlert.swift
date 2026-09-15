import SwiftUI

/// 購入 / リストアの結果を伝えるアラート。Paywall と Settings の Pro カードで共有する。
enum EntitlementAlert: String, Identifiable {
    /// リストアで Pro が復元された。
    case restored
    /// 復元対象の購入が見つからなかった。
    case noPurchaseFound
    /// 購入 / リストアに失敗した。
    case purchaseFailed

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .restored: return L.restoreDoneTitle
        case .noPurchaseFound: return L.restoreNoneTitle
        case .purchaseFailed: return L.purchaseFailedTitle
        }
    }

    var message: LocalizedStringKey {
        switch self {
        case .restored: return L.restoreDoneMessage
        case .noPurchaseFound: return L.restoreNoneMessage
        case .purchaseFailed: return L.purchaseFailedMessage
        }
    }
}

extension View {
    /// `EntitlementAlert` を表示する。`nil` になると閉じる。
    func loEntitlementAlert(_ alert: Binding<EntitlementAlert?>) -> some View {
        modifier(LOEntitlementAlertModifier(alert: alert))
    }
}

private struct LOEntitlementAlertModifier: ViewModifier {
    @Binding var alert: EntitlementAlert?

    func body(content: Content) -> some View {
        content.alert(
            alert?.title ?? L.ok,
            isPresented: Binding(
                get: { alert != nil },
                set: { isPresented in
                    if !isPresented { alert = nil }
                }
            ),
            presenting: alert
        ) { _ in
            Button(L.ok, role: .cancel) {}
        } message: { alert in
            Text(alert.message)
        }
    }
}
