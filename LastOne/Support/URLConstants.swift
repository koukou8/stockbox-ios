import Foundation

/// 外部 URL の定数。差し替えはここ 1 箇所で行う。
enum LOURL {
    /// プライバシーポリシー（TBD: 公開前に実 URL に差し替える）。
    static let privacyPolicy = URL(string: "https://example.com/lastone/privacy")!
    /// 利用規約（TBD）。
    static let termsOfUse = URL(string: "https://example.com/lastone/terms")!
}
