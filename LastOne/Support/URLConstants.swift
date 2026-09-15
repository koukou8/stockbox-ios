import Foundation

/// 外部 URL の定数。差し替えはここ 1 箇所で行う。
enum LOURL {
    /// GitHub Pagesで公開しているプライバシーポリシー。
    static let privacyPolicy = URL(string: "https://koukou8.github.io/stockbox-ios/privacy/")!
    /// 利用規約（TBD）。
    static let termsOfUse = URL(string: "https://example.com/lastone/terms")!
}
