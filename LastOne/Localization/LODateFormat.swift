import Foundation

/// 日付表示のフォーマッタ。
///
/// 書式をハードコードせず、必ず `Date.FormatStyle` にロケール判断を委ねる。
/// ja では「9月2日」、en では "Sep 2" のように解決される。
enum LODateFormat {

    /// 最終購入日ラベル用の「月日」表記。
    static func shortMonthDay(_ date: Date, locale: Locale = .autoupdatingCurrent) -> String {
        date.formatted(
            Date.FormatStyle(locale: locale)
                .month(.abbreviated)
                .day(.defaultDigits)
        )
    }
}
