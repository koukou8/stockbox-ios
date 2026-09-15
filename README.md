# LastOne（仮称）

家庭の日用品・食品・ペット用品のストックを最小の入力で管理する iOS アプリ。
「残り1つになったらワンタップ」だけで買い忘れ・重複購入を防ぐ。

- 製品仕様（正典）: [docs/spec/lastone-app.md](docs/spec/lastone-app.md)
- デザイン仕様（正典）: [docs/design.md](docs/design.md)
- 実装計画（スプリント）: [docs/spec.md](docs/spec.md)
- 実装進捗・自己評価: [docs/progress.md](docs/progress.md)

## ステータス

- [x] 要件定義・仕様書
- [x] 画面デザイン（Stitch プロトタイプ → `docs/design.md` に抽出）
- [x] 実装（MVP / Sprint 1〜4 完了）

| スプリント | 内容 | 状態 |
|---|---|---|
| Sprint 1 | データモデル / デザインシステム / 3 タブシェル / プリセット投入 / i18n | 完了 |
| Sprint 2 | Stocks 一覧・二値トグル・開封 −1 / アイテム登録・編集シート | 完了 |
| Sprint 3 | Buy List・購入記録 / カテゴリ管理 / Settings / エクスポート・インポート | 完了 |
| Sprint 4 | 無料枠と Paywall / 課金の seam / i18n・表示の仕上げ | 完了 |

## 技術スタック

| 項目 | 内容 |
|---|---|
| 言語 / UI | Swift / SwiftUI |
| 最低対応 OS | iOS 17.0+ |
| データ保存 | SwiftData（端末内ローカルのみ・バックエンドなし） |
| 外観 | Light 固定（ダークモードは v1 対象外） |
| i18n | String Catalog（`Localizable.xcstrings`）。開発言語 en / 翻訳 ja |
| 外部依存 | **なし**（Swift Package 依存 0 件） |
| アナリティクス | `AnalyticsClient` プロトコル + ログ出力スタブ（PostHog は未導入） |
| 課金 | `EntitlementStore` プロトコル + `UserDefaults` スタブ（RevenueCat は未導入） |

## ビルドと実行

### ビルド

```bash
cd /Users/koukiyoshida/development/lastone-app
./scripts/build.sh
```

- `** BUILD SUCCEEDED **` が出れば成功。全文ログは `build/last-build.log`。
- 中身は `xcodebuild -project LastOne.xcodeproj -scheme LastOne -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath build/dd build`。
  別機種で検証する場合は `scripts/build.sh` の `-destination` を変更する。
- 引数はそのまま `xcodebuild` に渡る（例: `./scripts/build.sh clean build`）。
- Xcode で開く場合は `open LastOne.xcodeproj` → スキーム `LastOne` を実行するだけでよい。

### シミュレータへインストールして起動

```bash
BID=jp.co.gimic.lastone
APP=build/dd/Build/Products/Debug-iphonesimulator/LastOne.app

xcrun simctl boot "iPhone 17" || true
open -a Simulator

xcrun simctl uninstall booted $BID        # クリーンな初回起動を再現（Pro 購入状態も消える）
xcrun simctl install booted "$APP"

# 日本語で起動
xcrun simctl launch booted $BID -AppleLanguages "(ja)" -AppleLocale "ja_JP"
# 英語で起動
xcrun simctl launch booted $BID -AppleLanguages "(en)" -AppleLocale "en_US"

# スクリーンショット / 終了
xcrun simctl io booted screenshot build/shots/check.png
xcrun simctl terminate booted $BID
```

`print` によるアナリティクスのログを見る場合は `--console-pty` を付けて起動する。

```bash
xcrun simctl launch --console-pty booted $BID
# [analytics] item_created / item_marked_low / item_opened / item_purchased
# [analytics] category_created / paywall_shown reason=… / pro_purchased
```

### 保存データの確認

```bash
CONT=$(xcrun simctl get_app_container booted jp.co.gimic.lastone data)
sqlite3 "$CONT/Library/Application Support/default.store" \
  "SELECT 'categories',COUNT(*) FROM ZCATEGORY UNION ALL SELECT 'items',COUNT(*) FROM ZITEM UNION ALL SELECT 'logs',COUNT(*) FROM ZPURCHASELOG;"

# Pro 購入状態（1 = Pro / キーが無ければ Free）
plutil -p "$CONT/Library/Preferences/jp.co.gimic.lastone.plist" | grep entitlement
# Pro を解除する
plutil -remove "jp.co.gimic.lastone.entitlement.pro" "$CONT/Library/Preferences/jp.co.gimic.lastone.plist"
```

## ディレクトリ構成

```
LastOne/                        アプリ本体（Xcode の file-system-synchronized group）
  App/                          エントリポイント・ルートビュー・タブ定義
    LastOneApp.swift            @main / ModelContainer / AnalyticsClient・EntitlementStore の注入
    RootView.swift              3 タブのシェルとプリセット投入のトリガー
    AppTab.swift
  Models/                       SwiftData の @Model と enum
    Category.swift  Item.swift  PurchaseLog.swift  StockEnums.swift
  DesignSystem/                 docs/design.md のトークンと共通部品
    LOColor.swift  LOFont.swift  LOMetrics.swift  Color+Hex.swift
    Components/                 ヘッダー / カード / チップ / ボタン / タブバー / 設定リスト ほか
  Features/
    BuyList/                    買うものリスト・空状態・空のかごイラスト
    Stocks/                     ストック一覧・アイテムカード
    ItemEditor/                 アイテム追加 / 編集シート
    CategoryManager/            カテゴリ管理シート
    Settings/                   設定画面・Pro カード・言語について
    Paywall/                    Paywall シート・購入結果アラート
  Services/                     ロジックと外部連携の seam（View から SwiftData / SDK に直接触れない）
    CategorySeeder.swift        初回起動時のプリセットカテゴリ投入
    ItemStateService.swift      アイテムの状態遷移・生成・更新・削除
    CategoryService.swift       カテゴリの生成・改名・並べ替え・削除
    DataTransfer.swift          JSON のエクスポート / インポート（全置換）
    AnalyticsClient.swift       計測の抽象 + ログ出力スタブ
    EntitlementStore.swift      課金の抽象 + UserDefaults スタブ
  Localization/
    LOStrings.swift             文言キーのファサード（enum L）。View に文言リテラルを書かない
    LODateFormat.swift          ロケール準拠の日付フォーマッタ
  Support/
    LOLimits.swift              無料枠の上限値と上限判定
    URLConstants.swift          プライバシーポリシー / 利用規約の URL
  Resources/
    Localizable.xcstrings       String Catalog（en / ja）
docs/                           仕様・デザイン・実装計画・進捗
screen/                         Stitch プロトタイプ（デザインの出典）
scripts/build.sh                ビルド検証スクリプト
build/                          ビルド成果物・ログ・検証スクリーンショット（Git 管理外）
```

## 外部 SDK を後から差し込む手順

MVP では**実 SDK を一切導入していない**（ネットワーク取得でビルドが壊れるのを避けるため）。
どちらもプロトコル抽象の背後にあり、**差し替えは `LastOneApp.swift` の 1 行のみ**で済む。
View 側の変更は不要。

### PostHog（アナリティクス）

1. Xcode で `File > Add Package Dependencies…` → `https://github.com/PostHog/posthog-ios`
2. `LastOne/Services/` に新しいファイルを作る（既存ファイルは編集しない）:

   ```swift
   import PostHog

   final class PostHogAnalyticsClient: AnalyticsClient {
       func track(_ event: AnalyticsEvent) {
           PostHogSDK.shared.capture(event.name, properties: event.properties)
       }
   }
   ```
3. `LastOneApp.init()` で `PostHogSDK.shared.setup(PostHogConfig(apiKey: "<プロジェクト API キー>", host: "…"))` を呼ぶ。
4. `LastOneApp` の `private let analytics: any AnalyticsClient = LoggingAnalyticsClient()` を
   `PostHogAnalyticsClient()` に差し替える。

送信されるイベントは 7 種（`AnalyticsClient.swift` に定義済み）:
`item_marked_low` / `item_purchased` / `item_opened` / `item_created` / `category_created` /
`paywall_shown`（`reason` property つき）/ `pro_purchased`。

### RevenueCat（課金・StoreKit 2）

1. Xcode で `File > Add Package Dependencies…` → `https://github.com/RevenueCat/purchases-ios`
2. App Store Connect で非消耗型プロダクトを作成し、RevenueCat 側で entitlement `pro` に紐づける
   （識別子は `LOEntitlement`（`LastOne/Services/EntitlementStore.swift`）にまとめてある）。
3. `LastOneApp.init()` の先頭で `Purchases.configure(withAPIKey: "<公開 SDK キー>")` を呼ぶ。
4. `LastOne/Services/` に `RevenueCatEntitlementStore: EntitlementStore` を新規作成する。
   **実装例は `EntitlementStore.swift` の doc comment にそのまま載せてある**
   （`purchase()` / `restore()` / `customerInfo` からの `isPro` 判定 / `delegate` での追従）。
5. `LastOneApp` の `private let entitlements: any EntitlementStore = LocalEntitlementStore()` を
   `RevenueCatEntitlementStore()` に差し替える。
6. `priceCta` / `proSub`（`Localizable.xcstrings`）の価格表記を、StoreKit から取得した
   ローカライズ済み価格に差し替える。**審査では実価格の表示が必要。**
7. `LOURL.privacyPolicy` / `LOURL.termsOfUse` を実 URL に差し替える（審査要件）。

> どちらの SDK も App Store のプライバシーラベル申告対象。導入時に申告内容を更新すること。

## 未確定事項（TBD）

| 項目 | 現在の仮値 | 変更箇所 |
|---|---|---|
| 無料枠の上限 | **カテゴリ 5 個 / アイテム 30 個** | `LastOne/Support/LOLimits.swift`（1 箇所） |
| Pro の価格 | **¥800 / $5.99（買い切り）** ※表示文言のみ。実際の課金は未実装 | `Localizable.xcstrings` の `priceCta` / `proSub`（実 SDK 導入後は StoreKit の価格に差し替え） |
| プライバシーポリシー / 利用規約の URL | `https://example.com/lastone/...`（プレースホルダ） | `LastOne/Support/URLConstants.swift` |
| アプリ正式名称 | 「LastOne」 | — |

## MVP の意図的な制限

- 購入履歴（PurchaseLog）は初日から記録するが、**閲覧 UI は作らない**（エクスポート JSON で確認できる）。
- **ダークモード非対応**（Light 固定）。
- **CloudKit 同期 / ウィジェット / 消費周期予測 / 家族共有 / プッシュ通知 / バーコード登録は対象外**。
- **アプリ内の言語切替 UI は置かない**（iOS 標準の「設定 > アプリごとの言語」に委ねる）。
- **ユニットテスト / UI テストターゲットは作らない**（`project.pbxproj` の編集が必要なため）。
  検証はビルド成功 + シミュレータでの手動シナリオ（`docs/progress.md` の各スプリント末尾）で行う。
