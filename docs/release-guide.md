# StockBox App Store リリース手順書（完全版）

> 対象: `StockBox: Home Inventory`（実装プロジェクト名は `LastOne`。iOS 17.0+ / SwiftUI / SwiftData / iPhone 専用）
> 起点: 2026-09-07 時点のリポジトリ状態（Sprint 1〜4 実装完了、`docs/progress.md` 参照）
> 到達点: App Store で一般公開されている状態
> 追加条件: RevenueCat Shipaton 2026 に応募するため、RevenueCat SDK と実際に動作する課金をv1に含める
>
> Apple 側の画面名・要件は年に数回変わります。本書と App Store Connect の表示が食い違う場合は **App Store Connect のヘルプを正** としてください。

### 現在の進捗と保留項目（2026-09-15）

#### Codexで完了した項目

- StockBox用の1024×1024アプリアイコンを登録（シンプル版）
- `PrivacyInfo.xcprivacy` を追加
- `ITSAppUsesNonExemptEncryption = NO` を確認
- GitHub Pages用の `docs/privacy/index.html` を作成し、`main` へ公開
- プライバシーポリシーURLを `URLConstants.swift` に反映
- Bundle IDを `com.kokiyoshida.stockbox` に設定
- 課金Product IDを `com.kokiyoshida.stockbox.pro` に統一

#### ユーザー作業として保留した項目

次の項目はApple / GitHub / RevenueCatのアカウント画面での操作、本人確認、または実機が必要なため、Codexではスキップしています。完了後にこの手順書のチェックを更新してください。

- **Phase 2-1**: XcodeでTeamを選択し、自動署名を有効化する
- **Phase 2-5**: App Store ConnectのApp PrivacyへプライバシーポリシーURLを登録する
- **Phase 3**: 実機接続・実機テストを行う
- **Phase 4-1**: App Store ConnectでProduct ID `com.kokiyoshida.stockbox.pro` を作成する
- **Phase 4-2**: RevenueCatプロジェクト、Entitlement、Offering、APIキーを作成する
- **Phase 4-3**: RevenueCat SDKをXcodeへ追加し、APIキーを設定する
- **Phase 4-5**: Sandboxテスターを作成し、実機で購入・復元を確認する
- **Phase 5**: Archive、TestFlightアップロード、テスター配信を行う
- **Phase 6**: スクリーンショット、掲載文、App Privacy、年齢制限、カテゴリ、審査情報をApp Store Connectへ登録する
- **Phase 7**: App Reviewへ提出し、審査後に公開する
- **Phase 7-6**: Shipatonへ提出する

#### 現時点での注意

- `termsOfUse` は実URL未確定のため、ダミーURLのままです。現在のUIから利用規約へ遷移する導線はありません。v1の開発・テスト中は対応不要ですが、**App Review提出前または最終アーカイブ作成前に定数を削除**してください。v1ではApple標準EULAを使用し、独自の利用規約ページは作成しない方針です。
- RevenueCat SDKは、APIキー未提供のまま組み込むと購入処理を壊すため、アカウント設定後に実装します。
- App Store公開前に、プライバシーポリシー本文の問い合わせ先とRevenueCat利用内容を最終確認してください。

#### Shipaton提出に向けた日程目安（2026-09-15時点）

Shipatonの締切は **2026年9月30日 23:45 PDT（日本時間では10月1日 15:45頃）** です。ストア審査には数営業日以上かかる可能性があるため、**9月22日頃までにApp Reviewへ提出**することを目標にします。

| 期限 | 到達している状態 |
|------|------------------|
| 9/16 | Xcode署名、App Store課金商品、RevenueCatプロジェクトの準備が完了 |
| 9/18 | RevenueCat SDK組み込み、購入・復元導線、Releaseビルドが完了 |
| 9/19 | 実機またはTestFlightで主要機能と課金を確認 |
| 9/20 | スクリーンショット、説明文、App Privacy、審査情報を登録 |
| 9/22 | App Reviewへ提出。ここを過ぎるとShipaton参加が不確実になる |
| 9/23〜9/29 | 審査対応、修正、再提出、デモ動画・Devpost下書きの完成 |
| 9/30 | App Store公開を確認し、Devpostへ最終提出 |

Appleの審査が9月22日までに完了する保証はないため、この日程は余裕を持った目標です。ShipatonではTestFlightではなく、対象ストアで一般公開されたアプリURLが必要です。審査を締切直前まで待たないでください。

---

## 0. 全体像

### 0-1. 現状サマリ

| 項目 | 状態 |
|------|------|
| 実装 | Sprint 1〜4 完了。ReleaseビルドはSimulator環境未起動のため未確認 |
| 検証 | シミュレータでの目視検証のみ。**実機テストは未実施** |
| 未検証の操作 | カテゴリのドラッグ並べ替え / スワイプ削除 / エクスポートの共有シート / インポートのファイル選択（`docs/progress.md`「検証状況」） |
| 既知の未達 | Dynamic Type 追従（固定サイズ。`accessibility1` で拡大を打ち切っている） |
| 課金 | **未完了**。現在はスタブ。v1でRevenueCat SDKと非消耗型の買い切り課金を実装する |
| 計測 | **スタブ**。`LoggingAnalyticsClient` がログを出すだけ |
| 署名 | XcodeでTeam選択・自動署名の有効化待ち。Bundle IDは確定済み |
| アイコン | 1024×1024 PNGを登録済み（シンプル版） |
| プライバシーマニフェスト | `PrivacyInfo.xcprivacy` を追加済み |
| 外部 URL | プライバシーポリシーは `https://koukou8.github.io/stockbox-ios/privacy/` に設定済み。利用規約URLは未確定 |
| Apple Developer Program | 加入済み。Xcodeの署名設定はユーザー作業待ち |

### 0-2. フェーズと流れ

```
Phase 0  決めること（商品・名前・価格・URL・Shipaton提出物）
   │
Phase 1  Apple Developer Program 加入 / App Store Connect 準備   ← 日数がかかるので最初に着手
   │
Phase 2  プロジェクトを配布可能にする（署名・アイコン・マニフェスト・URL）
   │
Phase 3  実機テスト（Xcode → 自分の iPhone）
   │
Phase 4  RevenueCat課金の実装と Sandbox テスト（v1必須）
   │
Phase 5  TestFlight（内部 → 外部テスター）
   │
Phase 6  App Store Connect のメタデータ（スクショ・説明文・プライバシー）
   │
Phase 7  審査提出 → リリース
   │
Phase 8  リリース後の運用
```

Phase 1 は待ち時間が長いので **Phase 2 以降と並行** して進めてください。

### 0-3. 所要期間の目安

| フェーズ | 目安 | 備考 |
|---------|------|------|
| Phase 1 加入 | 個人: 1〜2 日 / 法人: 1〜3 週間 | 法人は D-U-N-S 番号の取得・照合待ちが発生 |
| Phase 2 | 半日〜1 日 | アイコン制作を除く |
| Phase 3 実機テスト | 1〜2 日 | 不具合修正込み |
| Phase 4 課金 | 1〜2 日 | RevenueCat 設定 + Sandbox テスト |
| Phase 5 TestFlight | 内部: 即日 / 外部: +1〜2 日 | 外部配信は Beta App Review 待ち |
| Phase 6 メタデータ | 1 日 | en / ja 両方 |
| Phase 7 審査 | 通常 24〜48 時間 | リジェクト時は往復ごとに +1〜2 日 |

---

## Phase 0. 先に決めること

着手前に以下を決めないと後工程で手戻りします。

### 0-A. 課金仕様を確定する（最重要）

Shipaton 2026の参加条件により、無料版として先に公開する分岐は採用しません。v1にRevenueCat SDKと、少なくとも1つの実際に購入できる商品を含めます。

| 項目 | 採用する仕様 |
|------|--------------|
| SDK | RevenueCat SDK（StoreKit 2の購入処理をRevenueCatで管理） |
| 商品種別 | Non-Consumable（買い切り） |
| 商品名 | StockBox Pro |
| Product ID | `com.kokiyoshida.stockbox.pro` |
| Entitlement | `pro` |
| 価格 | **¥500 / $3.99を採用**。App Store Connectの価格ティアで最終確認 |
| 無料枠 | カテゴリ5個 / アイテム30個 |
| 審査用アクセス | Shipaton用のプロモコード、または無料トライアルを用意 |

現在の `LocalEntitlementStore` のままでは課金は発生しないため、App Store提出前にRevenueCat実装へ差し替えます。

#### Product IDとBundle IDの違い

- **Bundle ID**: アプリ本体の識別子。個人開発者用の名前空間として `com.kokiyoshida.stockbox` を使用する
- **Product ID**: 課金商品の識別子。`com.kokiyoshida.stockbox.pro` を使用する
- **Bundle IDとProduct ID**は別々の識別子だが、同じ名前空間で管理する
- Product IDはApp Store Connectで一度作成すると変更できないため、作成前に最終確定する
- Bundle IDは初回ビルドをApp Store Connectへアップロードする前に確定する。アップロード後に変更すると別アプリ扱いになるため、初回提出前に必ず揃える
- Product IDは、App Store Connect、RevenueCat、アプリ内の `LOEntitlement.productIdentifier` の3箇所で `com.kokiyoshida.stockbox.pro` に揃える

個人開発者で実在ドメインを使わない場合は、個人の管理する名前空間を使います。今回は `com.kokiyoshida.stockbox` をBundle ID、`com.kokiyoshida.stockbox.pro` をProduct IDとして採用します。App Store上の表示名やGitHub PagesのURLと、Bundle ID・Product IDは一致していなくても問題ありません。

### 0-B. その他の決定事項

| 項目 | 決めること | 現状 |
|------|-----------|------|
| App Store 上のアプリ名 | 一意である必要がある | **StockBox: Home Inventory** |
| サブタイトル（30 文字） | 例: "Tap once when it's the last one" / 「残り1つで、ワンタップ」 | 未定 |
| 価格 | 仕様書の目安 ¥600〜1,000 / $4.99〜6.99 | **UI 上は ¥500 / $3.99** |
| 無料枠 | カテゴリ 5 / アイテム 30 | `LastOne/Support/LOLimits.swift` |
| プライバシーポリシーの掲載先 | 公開 URL が必須。GitHub Pagesを使用 | `https://<GitHubユーザー名>.github.io/<リポジトリ名>/privacy/` を予定 |
| サポート URL | 必須。問い合わせフォームまたはメールアドレスを載せたページ | 未定 |
| 開発者アカウントの種別 | 個人 / 法人（法人は D-U-N-S 番号が必要） | 未加入 |
| 配信地域 | 全世界 or 日本 + 米国など | 仕様書は「グローバル」 |

### 0-C. Shipaton 2026の提出条件

Shipaton 2026に応募する場合、以下を満たす必要があります。

- 2026年8月1日〜9月30日の間に、アプリの初回公開を完了する
- App StoreまたはGoogle Play等で一般公開されたアプリURLを提出する
- RevenueCat SDKで少なくとも1つのアプリ内購入またはWeb購入を動かす
- 1024×1024 pxのアプリアイコンを用意する
- 1179×2556 px、端末フレームなしのスクリーンショットを少なくとも1枚用意する
- 2分以内のデモ動画をYouTubeまたはVimeoに公開する
- 審査員がプレミアム機能を試せる無料トライアルまたはプロモコードを用意する

提出先はDevpostです。ストア公開が完了してから、アプリURL・動画・スクリーンショット・アイコン・課金テスト手段を登録します。

---

## Phase 1. Apple Developer Program と App Store Connect

### 1-1. Apple Developer Program に加入

1. 2 ファクタ認証を有効にした Apple Account を用意する
2. https://developer.apple.com/programs/ から加入（または iOS の「Apple Developer」アプリ）
   - **個人**: 本人確認のみ。通常 48 時間以内に有効化
   - **法人**: D-U-N-S 番号（無料。取得に 1〜2 週間）、法人の署名権限者であることの確認が必要
3. 年会費 $99（日本では ¥15,800 前後）を支払う
4. 有効化メールが届いたら https://developer.apple.com/account/ にサインインできることを確認

### 1-2. Xcode に Apple Account を登録

1. Xcode → Settings → Accounts → 「+」→ Apple Account でサインイン
2. チームが表示されることを確認（個人なら自分の名前、法人なら法人名）
3. 「Manage Certificates...」→ 「+」→ **Apple Development** を作成（実機テスト用）
   - Apple Distribution 証明書は Xcode の自動署名がアーカイブ時に作るので手動作成は不要

### 1-3. Bundle ID の登録

自動署名を有効にすると、Xcodeで設定した `com.kokiyoshida.stockbox` をApp IDとして登録できます（Phase 2-1）。
手動で登録する場合は https://developer.apple.com/account/resources/identifiers/ → 「+」→ App IDs → App → Explicit Bundle ID に `com.kokiyoshida.stockbox` を登録します。Capabilitiesは不要（CloudKit / PushはMVP対象外）。AppleのExplicit App IDは、Xcodeターゲットに設定したBundle IDと一致させます。

### 1-4. App Store Connect でアプリを作成

1. https://appstoreconnect.apple.com/ → My Apps → 「+」→ New App
2. 入力項目

   | 項目 | 値 |
   |------|-----|
   | Platforms | iOS |
   | Name | **StockBox: Home Inventory** |
   | Primary Language | **English (U.S.)**（仕様書の基準言語） |
   | Bundle ID | `com.kokiyoshida.stockbox` |
   | SKU | 任意の内部 ID。例: `stockbox-ios` |
   | User Access | Full Access |

3. 作成後、App Information → Localizable Information で **Japanese** を追加

### 1-5. 有料 App 契約（課金を使うため必須）

課金アイテムを「Ready to Submit」にするには以下が必須です。

1. App Store Connect → **Business**（旧 Agreements, Tax, and Banking）
2. **Paid Apps Agreement** に Account Holder が同意
3. 銀行口座情報・税務情報（日本の場合は W-8BEN / 日本の税務フォーム）を入力
4. ステータスが「Active」になるまで待つ（数時間〜数日）

> Account Holder（アカウント所有者）以外は同意できません。法人の場合は署名権限者に依頼が必要です。

---

## Phase 2. プロジェクトを配布可能にする

すべて `LastOne.xcodeproj` / `LastOne/` 内の作業です。Phase 1 の完了を待たずに進められます（署名設定だけはチーム ID が必要）。

### 2-1. 署名設定を配布用に戻す

現在の設定はシミュレータ検証用に署名を止めています。

1. Xcode で `LastOne.xcodeproj` を開く → TARGETS → LastOne → **Signing & Capabilities**
2. **Automatically manage signing** にチェック
3. **Team** に自分のチームを選択
4. `TARGETS → LastOne → General → Identity` の Bundle Identifierを `com.kokiyoshida.stockbox` に変更する
   - App Store Connectでアプリレコードを作成する前、または作成時に同じ値を選択する
5. 以下の 3 設定が pbxproj から消えていることを Build Settings で確認（Debug / Release 両方）

   | 設定 | 現状 | あるべき値 |
   |------|------|-----------|
   | `CODE_SIGNING_ALLOWED` | `NO` | 削除（デフォルト YES） |
   | `CODE_SIGNING_REQUIRED` | `NO` | 削除（デフォルト YES） |
   | `CODE_SIGN_IDENTITY` | `""` | 削除（自動署名に任せる） |
   | `DEVELOPMENT_TEAM` | 未設定 | 自分のチーム ID（10 桁英数字） |
   | `CODE_SIGN_STYLE` | 未設定 | `Automatic` |

   Xcode の GUI で Team を選ぶと自動で書き換わります。CLI で確認する場合:

   ```bash
   grep -nE "CODE_SIGN|DEVELOPMENT_TEAM" LastOne.xcodeproj/project.pbxproj
   ```

6. `./scripts/build.sh` がこれまでどおり通ることを確認（シミュレータ向けは署名不要のため影響なし）

### 2-2. アプリアイコン

`LastOne/Assets.xcassets/AppIcon.appiconset/` に画像がないため、アーカイブ検証で失敗します。

**要件**

- 1024 × 1024 px、PNG、**アルファチャンネルなし**、角丸なし（OS が丸める）
- 透過・角丸付きだと App Store Connect のアップロードで弾かれる
- Xcode 26 では Icon Composer で作る `.icon` 形式（iOS 26 の Liquid Glass 対応）も使えるが、1024 PNG 1 枚で審査は通る

**手順**

1. `AppIcon.png`（1024 × 1024）を用意する
2. Xcode → Assets → AppIcon → 「All Sizes」の 1024 スロットにドラッグ
   （または `Contents.json` の `images[0]` に `"filename": "AppIcon.png"` を追加してファイルを同じフォルダに置く）
3. アルファチャンネルの有無を確認:

   ```bash
   sips -g hasAlpha LastOne/Assets.xcassets/AppIcon.appiconset/AppIcon.png
   ```

   `hasAlpha: no` であること。`yes` なら **Preview.app で開く → ファイル → 書き出す → 「アルファ」のチェックを外して PNG で保存** が確実です。
   CLI で済ませるなら JPEG を経由してアルファを落とします（わずかに非可逆）:

   ```bash
   sips -s format jpeg -s formatOptions best AppIcon.png --out "$TMPDIR/icon.jpg"
   sips -s format png "$TMPDIR/icon.jpg" --out AppIcon.png
   ```

**デザインの方向性**（`docs/design.md` 準拠）: 生成り `#FAF5EE` の地に、セージ `#8FB89E` とアプリコット `#C4713C` の 2 色。空のかご or 「1」のモチーフ。赤は使わない。

### 2-3. プライバシーマニフェスト（必須）

`UserDefaults` を使っているため、Required Reason API の申告が必要です。ないとアップロード時に警告メール（ITMS-91053）が届き、審査で弾かれることがあります。

`LastOne/PrivacyInfo.xcprivacy` を以下の内容で作成（file-system-synchronized group なので置くだけでバンドルに入ります）:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

- `CA92.1` = 「自アプリからのみアクセスできる情報の読み書き」。`LocalEntitlementStore` の用途に一致
- RevenueCat / PostHog を導入した場合、SDK 側が自前のマニフェストを同梱するのでアプリ側の追記は不要。ただし `NSPrivacyCollectedDataTypes` はアプリ全体の申告なので、App Store Connect のプライバシーラベル（Phase 6-3）と整合させる

ビルド後、マニフェストがバンドルに含まれていることを確認:

```bash
ls build/dd/Build/Products/Debug-iphonesimulator/LastOne.app/PrivacyInfo.xcprivacy
```

### 2-4. Info.plist の追加キー

現在は `GENERATE_INFOPLIST_FILE = YES` で Info.plist を自動生成しています。以下を追加します。

1. Xcode → TARGETS → LastOne → **Info** タブ → Custom iOS Target Properties で「+」
2. `App Uses Non-Exempt Encryption`（`ITSAppUsesNonExemptEncryption`）= **NO**
   - HTTPS 等の OS 標準暗号しか使わないため NO。これを入れると **アップロードのたびに出る輸出コンプライアンス質問が省略** される
3. Xcode が `LastOne/Info.plist` を生成し `INFOPLIST_FILE` を設定する。自動生成キーとマージされるので既存の `INFOPLIST_KEY_*` 設定はそのままでよい

### 2-5. 外部 URL の差し替え

`LastOne/Support/URLConstants.swift`:

```swift
static let privacyPolicy = URL(string: "https://<GitHubユーザー名>.github.io/<リポジトリ名>/privacy/")!   // ← 公開後の実 URL に
static let termsOfUse    = URL(string: "https://example.com/stockbox/terms")!     // ← 実 URL に
```

#### GitHub Pagesで公開する

1. リポジトリに `docs/privacy/index.html` を作成する
2. プライバシーポリシー本文を日本語で記載する。英語版を配信する場合は同じページに英語版も用意する
3. GitHubのリポジトリ設定で **Settings → Pages** を開く
4. Sourceを **Deploy from a branch**、Branchを公開対象ブランチの `/(root)` または `docs` 構成に合わせて設定する
5. 公開されたURLをブラウザのシークレットウィンドウでも開けることを確認する
6. 公開URLを `URLConstants.swift` と App Store ConnectのApp Privacyへ設定する

リポジトリのPages設定が `main` ブランチの `/docs` を公開する構成なら、URLは通常 `https://<GitHubユーザー名>.github.io/<リポジトリ名>/privacy/` になります。GitHub Pagesの実際の公開URLを確認してからアプリへ設定してください。

- プライバシーポリシーは **審査必須**。Settings 画面の「プライバシーポリシー」行（`SettingsView.swift:179`）から開くため、ダミーのままだと審査ガイドライン 2.1（不完全なアプリ）で弾かれる
- 利用規約は現在 UI から参照していない。買い切り課金のみなら App Store 標準の EULA で足りるが、独自 EULA を使う場合は Settings に行を足すか App Store Connect の License Agreement 欄に登録する

**プライバシーポリシーに書くこと**（このアプリの実態）

- 収集するデータ: 端末内 SwiftData のデータに加え、RevenueCatへ送信される購入・Entitlement関連情報。PostHogを導入する場合は匿名の利用状況も追記する
- データの保存場所: 端末内。iOS の標準バックアップに含まれる
- 第三者提供: なし
- 問い合わせ先

### 2-6. バージョン番号の運用ルール

| 設定 | Info.plist キー | 意味 | ルール |
|------|----------------|------|--------|
| `MARKETING_VERSION` | `CFBundleShortVersionString` | ユーザーに見えるバージョン | `1.0` → `1.0.1` → `1.1`。App Store Connect のバージョンと一致させる |
| `CURRENT_PROJECT_VERSION` | `CFBundleVersion` | ビルド番号 | **同じバージョンで再アップロードするたびに +1**。重複するとアップロード拒否 |

初回は `1.0 (1)` のままでよい。修正版を上げるたびに `CURRENT_PROJECT_VERSION` を上げる:

```bash
# 例: ビルド番号を 2 に
sed -i '' 's/CURRENT_PROJECT_VERSION = 1;/CURRENT_PROJECT_VERSION = 2;/g' LastOne.xcodeproj/project.pbxproj
```

（Xcode の General → Identity → Build でも変更可）

### 2-7. 課金導線の本番前提を確認

v1ではPaywall、無料枠、Proカード、購入復元導線を残します。課金を無効化するfeature flagは追加しません。

- Paywallから購入処理へ到達できる
- Settingsから購入の復元へ到達できる
- 無料枠超過時にPaywallが表示される
- Pro購入後はカテゴリ・アイテムの上限が外れる
- 商品取得やネットワーク失敗時に、購入済みと誤認させずエラーを表示する

### 2-8. Release 構成でのビルド確認

`scripts/build.sh` は Debug / シミュレータ用です。Release でも警告なしで通ることを確認します。

```bash
xcodebuild -project LastOne.xcodeproj -scheme LastOne -configuration Release \
  -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath build/dd build 2>&1 \
  | grep -E "warning:|error:|BUILD" | sort -u
```

### 2-9. iOS 17 での動作確認

最低対応 OS は iOS 17.0 ですが、これまでの検証は iOS 26.2 シミュレータのみです。iOS 17 の UI 差分（`.presentationDetents` の挙動、`ContentUnavailableView` のレイアウトなど）を確認します。

1. Xcode → Settings → Components → iOS 17.x Simulator Runtime をダウンロード
2. `xcrun simctl list runtimes` で表示されることを確認
3. iOS 17 の iPhone 15 などで起動し、3 タブ + 各シートを一通り開く

実機が iOS 17 ならそちらで確認しても構いません。

### Phase 2 完了チェック

- [ ] 自動署名が有効で Team が設定されている
- [ ] 1024 px のアイコンが入り、`hasAlpha: no`
- [ ] `LastOne/PrivacyInfo.xcprivacy` がバンドルに含まれる
- [ ] `ITSAppUsesNonExemptEncryption = NO`
- [ ] プライバシーポリシーの実 URL が入り、Settings から開ける
- [ ] Release 構成でビルドが通る
- [ ] iOS 17 で起動確認
- [ ] Paywall / 上限 / Restore が本番課金導線として動作する

---

## Phase 3. 実機テスト

### 3-1. 用意するもの

| もの | 条件 |
|------|------|
| iPhone | **iOS 17.0 以上**。可能なら iOS 17 系と最新の 2 台 |
| ケーブル | 初回接続は USB 必須。以降は Wi-Fi でも可 |
| Apple Account | Xcode に登録済み（Phase 1-2）。有料 Program 未加入でも 7 日間有効の開発署名で実機実行だけは可能 |

### 3-2. iPhone 側の準備

1. iPhone を Mac に接続 → 「このコンピュータを信頼しますか？」→ 信頼
2. **Developer Mode を有効化**（iOS 16 以降で必須）
   - 設定 → プライバシーとセキュリティ → デベロッパモード → ON → 再起動
   - この項目は Xcode に一度接続した後に現れる
3. Xcode → Window → Devices and Simulators で端末が表示され、「Preparing device」が終わるまで待つ

### 3-3. Xcode から実機で起動

1. Xcode のツールバーで Run Destination を自分の iPhone に切り替え
2. ⌘R
3. 初回は iPhone 側で「信頼されていないデベロッパ」と出る
   → 設定 → 一般 → VPN とデバイス管理 → 自分の Apple Account → 信頼
4. 再度 ⌘R でアプリが起動する

**CLI で行う場合**（Xcode 15 以降の `devicectl`）:

```bash
# 接続中の端末と UDID を確認
xcrun devicectl list devices

# 実機向けにビルド（署名は自動）
xcodebuild -project LastOne.xcodeproj -scheme LastOne -configuration Debug \
  -destination 'generic/platform=iOS' -derivedDataPath build/dd-device \
  -allowProvisioningUpdates build

# インストールして起動
xcrun devicectl device install app --device <UDID> build/dd-device/Build/Products/Debug-iphoneos/LastOne.app
xcrun devicectl device process launch --device <UDID> <確定したBundle ID>
```

### 3-4. Wi-Fi 経由での接続（任意）

Devices and Simulators → 端末を選択 → **Connect via network** にチェック。同一 Wi-Fi ならケーブル不要になります。

### 3-5. テスト観点チェックリスト

シミュレータで確認できなかったこと、実機でしか分からないことを優先します。

#### A. 未検証の 4 操作（最優先）

- [ ] Settings → カテゴリの管理 → 行を長押しドラッグで並べ替え → 閉じて Stocks の順序が変わる → アプリ再起動後も維持
- [ ] カテゴリ管理 → 行を左スワイプ → 削除 → 確認ダイアログ → 削除するとそのカテゴリのアイテムも消える（仕様どおりの挙動か確認）
- [ ] Settings → データのエクスポート → 共有シート → 「ファイルに保存」→ Files アプリに JSON ができる
- [ ] Settings → データのインポート → ファイル選択 → 上で保存した JSON を選ぶ → データが復元される（**エクスポート → 全削除 → インポートの往復**）

#### B. コアループ（仕様書の受け入れ基準）

- [ ] 二値アイテム: 「買うものリストに追加」→ Buy List に出る → 「買った」→ 消えて最終購入日が今日になる
- [ ] カウントアイテム（3 / 閾値 1）: 「開封 −1」×2 → 自動で「のこり1つ」→ Buy List → 「買った」→ 在庫数が閾値を超えて戻る
- [ ] 0 の状態で「開封 −1」を押してもクラッシュしない
- [ ] アプリを強制終了 → 再起動 → 全データが残っている
- [ ] 機内モードで全操作ができる（ローカル完結の確認）

#### C. 実機でしか分からないこと

- [ ] **日本語入力**: アイテム名に日本語 IME で入力 → 変換確定 → 追加。変換中に「追加する」を押した場合の挙動
- [ ] キーボード表示中にシートの「追加する」ボタンが隠れない
- [ ] Dynamic Island / ノッチとヘッダーの重なり、ホームインジケータとタブバーの重なり
- [ ] 縦向き固定になっている（横にしても回転しない）
- [ ] 文字サイズ変更（設定 → アクセシビリティ → 画面表示とテキストサイズ → さらに大きな文字）で最大まで上げてもレイアウトが破綻しない（`accessibility1` で打ち止めになる仕様）
- [ ] 太字テキスト ON、視差効果を減らす ON でも表示が崩れない
- [ ] ダークモード設定でもアプリは Light 固定で表示され、ステータスバーが読める
- [ ] VoiceOver で 3 タブと主要ボタンが読み上げられる
- [ ] スクロール・シート表示がカクつかない（30 アイテム / 5 カテゴリ投入して確認）

#### D. 言語切替

- [ ] 設定 → 一般 → 言語と地域 → 英語に変更 → 全画面が英語になり、日付が "Bought Sep 3" 形式になる
- [ ] 設定 → アプリ → StockBox: Home Inventory → 言語 → 日本語（iOS 17 は設定直下に表示される。複数ローカリゼーションを持つアプリではこの項目が自動で現れる）
- [ ] 英語 UI で長い文言（"Remove from Buy List" 等）のボタンが折り返しで崩れない

#### E. 課金（Phase 4 完了後に必ず実施）

- [ ] 31 個目のアイテム追加で Paywall が開き、アイテムは追加されない
- [ ] 6 個目のカテゴリ追加で Paywall が開く
- [ ] Sandbox アカウントで購入 → Pro になり上限が外れる
- [ ] アプリを削除 → 再インストール → 「購入をリストア」で Pro に戻る

### 3-6. 不具合の記録

見つけた不具合は `docs/feedback/device-test.md` に以下の形式で残し、修正後に `docs/progress.md` の「検証状況」を更新します。

```markdown
| # | 重要度 | 内容 | 再現手順 | 端末 / iOS | 状態 |
|---|--------|------|----------|-----------|------|
| 1 | Major | ... | ... | iPhone 15 / 17.5 | 修正済み |
```

---

## Phase 4. RevenueCat課金の実装と Sandbox テスト

Shipaton応募とv1公開の必須フェーズです。このフェーズを完了するまで、App Store提出用のビルドは作成しません。

### 4-1. App Store Connect で課金アイテムを作成

1. My Apps → StockBox: Home Inventory → **In-App Purchases** → 「+」
2. 設定値

   | 項目 | 値 |
   |------|-----|
   | Type | **Non-Consumable**（買い切り） |
   | Reference Name | `StockBox Pro`（内部用） |
   | Product ID | `com.kokiyoshida.stockbox.pro`（**後から変更不可**） |
   | Price | Phase 0 で決めた価格帯（Apple の価格ティアから選択。全地域の価格は自動換算） |
   | Localization | en-US: "StockBox Pro" / "Unlimited categories and items"、ja: "StockBox Pro" / "カテゴリ・アイテム無制限" |
   | Review Screenshot | Paywall 画面のスクショ（審査用。必須） |
   | Review Notes | 「31 個目のアイテム追加時に Paywall が表示されます」 |

3. ステータスが「Ready to Submit」になることを確認（有料 App 契約が Active でないとここで止まる）
4. **最初の課金アイテムはアプリのバージョンと一緒に審査提出する**必要がある。Phase 6 でバージョンページの「In-App Purchases and Subscriptions」欄に追加する

### 4-2. RevenueCat の設定

1. https://app.revenuecat.com/ でプロジェクト作成 → Apps → iOS を追加（Bundle IDはPhase 0で確定した値）
2. **In-App Purchase Key** を登録
   - App Store Connect → Users and Access → Integrations → **In-App Purchase** → キーを生成 → `.p8` をダウンロード
   - RevenueCat の App 設定にアップロード（StoreKit 2 での検証に必要）
3. Products → App Store Connectで作成したProduct IDをインポート
   - App Store Connect API key未設定の場合は、Products → Newから手動登録してもよい
   - Identifier: `com.kokiyoshida.stockbox.pro` / Product type: **Non-consumable**
4. Entitlements → 識別子 **`pro`** を作成（`EntitlementStore.swift` の `LOEntitlement.identifier` と一致させる）→ 上の Product を紐付け
5. Offerings → `default` を作成（既存の`default`があれば再利用）→ Package（Lifetime）にProductを紐付け
6. API Keys → iOS の Public API key（`appl_...`）を控える。Secret API keyはアプリに組み込まない

**StockBoxの設定状況（2026-09-19）**

- App Store用アプリ設定: 完了（Bundle ID `com.kokiyoshida.stockbox`）
- In-App Purchase Key: `Valid credentials` を確認済み
- Product: `com.kokiyoshida.stockbox.pro` を登録済み
- Entitlement: `pro` を作成し、上記Productを紐付け済み
- Offering: `default` のLifetime packageに上記Productを紐付け済み
- iOS Public API key: 確認済み（リポジトリへは未コミット）
- App Store Connect API key: 未設定のため、Productは手動登録。価格の自動同期は未設定

### 4-3. SDK を導入して `EntitlementStore` を差し替え

1. Xcode → File → Add Package Dependencies → `https://github.com/RevenueCat/purchases-ios-spm.git`
   → Products は **RevenueCat** と **RevenueCatUI**（Paywall 用）を LastOne ターゲットに追加
2. `EntitlementStore.swift` のコメントに書いてある手順どおり `RevenueCatEntitlementStore` を実装
   - `purchase()` → `Purchases.shared.offerings()` → `purchase(package:)` → `customerInfo.entitlements["pro"]?.isActive`
   - `restore()` → `Purchases.shared.restorePurchases()`
   - `Purchases.shared.delegate` で `customerInfo` 更新を受けて `isPro` に反映
3. `LastOne/App/LastOneApp.swift:17` の注入を差し替え

   ```swift
   private let entitlements: any EntitlementStore = RevenueCatEntitlementStore()
   ```

4. `init()` の先頭で SDK を初期化

   ```swift
   Purchases.logLevel = .warn
   Purchases.configure(withAPIKey: "appl_xxxxxxxx")
   ```

   API キーはソースに直書きせず、`Secrets.xcconfig`（`.gitignore` 済み）→ Info.plist 経由で読む構成を推奨
5. Paywall は既存の `PaywallView` をそのまま使う（価格表示だけ `package.storeProduct.localizedPriceString` に置き換える）か、RevenueCat Paywalls（`RevenueCatUI.PaywallView`）に置き換える。**「購入をリストア」ボタンは必ず残す**（審査要件）

**StockBoxの実装状況（2026-09-19）**

- RevenueCat Swift Package（`RevenueCat` / `RevenueCatUI`）: 導入済み
- `RevenueCatEntitlementStore`: 実装済み
- `LastOneApp`のSDK初期化とEntitlement注入: 実装済み
- Release向けビルド: 成功確認済み
- Sandbox購入・復元: 未確認（Phase 4-4で実施）

> `Package.resolved` が生成され、`docs/spec.md` の「Swift Package 依存 0 件」の前提がここで解除されます。`docs/progress.md` に記録してください。

### 4-4. StoreKit Configuration でローカルテスト（Sandbox 不要）

1. Xcode → File → New → File → **StoreKit Configuration File** → 「Sync this file with an app in App Store Connect」にチェック → 4-1 のアイテムが取り込まれる
2. Product → Scheme → Edit Scheme → Run → Options → **StoreKit Configuration** に作成したファイルを選択
3. シミュレータで購入フローを通す（課金は発生しない）
4. Debug → StoreKit → Manage Transactions で購入を取り消して再テスト

### 4-5. Sandbox テスターで実機テスト

1. App Store Connect → Users and Access → **Sandbox** → Test Accounts → 「+」でテスト用 Apple Account を作成（実在しないメールでよいが、以後変更不可）
2. iPhone の **設定 → App Store → Sandbox アカウント** にサインイン（この項目は一度でも開発ビルドで購入を試みると現れる）
3. Xcode から実機で起動 → Paywall → 購入 → Sandbox のサインインダイアログ → 購入完了（請求なし）
4. 4-1 の Product が「Ready to Submit」になっていないと商品が取得できず Paywall が空になる
5. アプリ削除 → 再インストール → リストアで Pro が戻ることを確認
6. RevenueCat ダッシュボードの Customers に Sandbox の購入が記録されることを確認

> TestFlight ビルドも自動的に Sandbox 環境で課金されます（テスターに請求は発生しません）。

### 4-6. PostHog の導入（任意。v1 で計測を入れるなら）

1. https://posthog.com/ でプロジェクト作成 → Project API Key と Host（`https://us.i.posthog.com` 等）を控える
2. Xcode → Add Package → `https://github.com/PostHog/posthog-ios`
3. `AnalyticsClient` プロトコルの実装 `PostHogAnalyticsClient` を作り、`LastOneApp.swift:12` の `LoggingAnalyticsClient()` を差し替え
4. **導入すると Phase 6-3 のプライバシーラベルが「Data Not Collected」ではなくなる**（利用状況データ・識別子の申告が必要）。v1 で急がないなら v1.1 に回すのが安全

---

## Phase 5. TestFlight

### 5-1. アーカイブを作る

**Xcode（推奨）**

1. Run Destination を **Any iOS Device (arm64)** にする（シミュレータのままだと Archive がグレーアウト）
2. Product → **Archive**
3. 完了すると Organizer（Window → Organizer → Archives）が開く

**CLI**

```bash
xcodebuild -project LastOne.xcodeproj -scheme LastOne -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath build/LastOne.xcarchive \
  -allowProvisioningUpdates archive 2>&1 | grep -E "error:|warning:|ARCHIVE" | sort -u
```

### 5-2. App Store Connect にアップロード

**Xcode Organizer（推奨）**

1. Archives → 対象を選択 → **Distribute App**
2. **App Store Connect** → Upload
3. 「Upload your app's symbols」「Manage Version and Build Number」はデフォルト ON のまま
4. 自動署名で Apple Distribution 証明書とプロビジョニングプロファイルが作られる → Upload
5. 数分〜30 分で App Store Connect → TestFlight タブに「Processing」→ 完了メールが届く

**CLI（ExportOptions で直接アップロード）**

`scripts/ExportOptions.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store-connect</string>
    <key>destination</key>
    <string>upload</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>teamID</key>
    <string>XXXXXXXXXX</string>
    <key>uploadSymbols</key>
    <true/>
</dict>
</plist>
```

```bash
xcodebuild -exportArchive -archivePath build/LastOne.xcarchive \
  -exportOptionsPlist scripts/ExportOptions.plist -exportPath build/export \
  -allowProvisioningUpdates
```

（古い Xcode では `method` が `app-store`。Apple Account の認証は Xcode に登録済みのものが使われる）

### 5-3. 輸出コンプライアンス

Phase 2-4 で `ITSAppUsesNonExemptEncryption = NO` を入れていれば質問は出ません。入れていない場合はビルドごとに TestFlight タブで「Missing Compliance」→ 「No」を選びます。

### 5-4. 内部テスト（審査不要・即日）

1. TestFlight → Internal Testing → 「+」でグループ作成（例: `Team`）
2. App Store Connect にユーザー登録されている人（最大 100 人）を追加
3. ビルドを選択 → テスターに TestFlight アプリ経由でメールが届く
4. テスターは iPhone に **TestFlight アプリ** を入れ、招待を受けてインストール

### 5-5. 外部テスト（Beta App Review あり）

社外の人や友人に配る場合。

1. TestFlight → External Testing → グループ作成
2. **Test Information** を入力: 説明文、フィードバック用メール、「PaywallはSandboxで購入できます」等のReview Notes
3. ビルドを追加 → **Submit for Review**（初回のみ Beta App Review。通常 1〜2 日）
4. 承認後、メール招待または **Public Link**（最大 10,000 人）で配布

### 5-6. 運用上の注意

- TestFlight ビルドは **90 日で失効**
- 同じバージョンでビルドを上げ直すときは `CURRENT_PROJECT_VERSION` を +1（Phase 2-6）
- テスターのフィードバック（スクショ付き）は TestFlight → Feedback に集まる。クラッシュは Xcode Organizer → Crashes にシンボリケートされて届く
- 実機テストの Phase 3-5 チェックリストを TestFlight テスターにも配ると観点が揃う

---

## Phase 6. App Store Connect のメタデータ

My Apps → StockBox: Home Inventory → 左のバージョン「1.0 Prepare for Submission」で入力します。**en-US と ja の両方** に入れます（言語切替は右上のドロップダウン）。

### 6-1. スクリーンショット

| 要件 | 内容 |
|------|------|
| 必須サイズ | **iPhone 6.9 インチ**（1320 × 2868 px 縦）。他サイズは任意（未登録なら自動でスケールされる） |
| 枚数 | 1〜10 枚。3〜5 枚が一般的 |
| iPad | 不要（`TARGETED_DEVICE_FAMILY = 1` の iPhone 専用のため） |
| 内容 | 実際のアプリ画面であること。デバイスフレーム・見出しテキストの合成は可 |

`build/shots/` の既存スクショは **iPhone 17（6.3 インチ）で撮ったものなのでサイズが合いません**。iPhone 17 Pro Max シミュレータで撮り直します:

```bash
DEV="iPhone 17 Pro Max"
xcrun simctl boot "$DEV" 2>/dev/null
xcrun simctl install "$DEV" build/dd/Build/Products/Debug-iphonesimulator/LastOne.app
xcrun simctl launch "$DEV" <確定したBundle ID>
# 画面を整えてから
xcrun simctl io "$DEV" screenshot build/shots/store-01-buylist.png
```

推奨構成（en / ja それぞれ）:

1. Buy List に 3 件並んだ状態（コア価値）
2. Stocks でカウント方式カードが見える状態
3. アイテム追加シート（二値 / カウントの選択）
4. Buy List の空状態（「ふわっと」した世界観）
5. Settings の Pro カードと購入復元

シミュレータの言語は `xcrun simctl launch "$DEV" <確定したBundle ID> -AppleLanguages "(ja)" -AppleLocale ja_JP` で切り替えられます。

### 6-2. テキスト

| 項目 | 上限 | en-US（例） | ja（例） |
|------|------|------------|---------|
| Name | 30 | StockBox: Home Inventory | StockBox: 家庭の在庫管理 |
| Subtitle | 30 | Tap once when it's the last one | 残り1つで、ワンタップ |
| Promotional Text | 170 | 審査なしで随時変更できる宣伝文 | 同左 |
| Description | 4000 | 仕様書「概要」「設計思想」を平易に。箇条書き可 | 同左 |
| Keywords | 100 | `stock,inventory,grocery,shopping list,household,pantry,restock` | `在庫,ストック,買い物リスト,日用品,買い忘れ,消耗品` |
| What's New | 4000 | 初回は "Initial release." | 「初回リリース」 |
| Support URL | — | 必須 | 同じでよい |
| Marketing URL | — | 任意 | |
| Copyright | — | `2026 Gimic Inc.` 等 | |

- キーワードはカンマ区切り、スペース不要。アプリ名・カテゴリ名と重複させない
- 説明文の 1〜2 行目が検索結果で見えるので、そこに「残り1つになったらワンタップ」の価値を置く

### 6-3. App Privacy（プライバシーラベル）

App Information → App Privacy → Get Started。

| 構成 | 申告 |
|------|------|
| RevenueCatあり | Purchases → Purchase History（App Functionality / Not linked to identity）、Identifiers → User ID（RevenueCatの匿名ID）。RevenueCat公式のApp Privacyガイドで最新の申告項目を確認 |
| + PostHog | Usage Data → Product Interaction、Identifiers → Device ID、Diagnostics。PostHog 公式ガイドで確認 |

- Privacy Policy URL は App Information の各言語欄にも入れる
- ここで申告した内容と `PrivacyInfo.xcprivacy` の `NSPrivacyCollectedDataTypes`、実装の実態が食い違うとリジェクト理由になる

### 6-4. 年齢制限

App Information → Age Rating → 質問票に回答。このアプリは該当項目がないので最低区分（4+）になります。

### 6-5. カテゴリ・価格・配信地域

| 項目 | 値 |
|------|-----|
| Primary Category | Productivity（または Lifestyle / Utilities） |
| Secondary Category | Shopping（任意） |
| Price（App 本体） | Free |
| Availability | Phase 0 で決めた地域。デフォルトは全 175 地域 |
| Mac availability | 「Make this app available on Mac」（Apple Silicon Mac で iPhone アプリを動かす）は **最初は OFF 推奨**。Mac で未検証のため |

### 6-6. In-App Purchase の紐付け

バージョンページ → In-App Purchases and Subscriptions → 「+」→ `StockBox Pro` を追加。これを忘れると課金アイテムが審査されず、リリース後に商品が取得できません。

### 6-7. App Review Information

| 項目 | 内容 |
|------|------|
| Sign-in required | **No**（認証なし） |
| Contact Information | 審査官が連絡できる電話・メール |
| Notes | 例: 「Data is stored on-device only. Tap 'Add to Buy List' on any item in Stocks to see it appear in Buy List. (Plan A) The paywall appears when adding the 31st item; purchases work in Sandbox.」 |
| Attachment | 操作の流れを示す短い動画があると往復が減る（任意） |

### 6-8. Version Release（公開方法）

| 選択肢 | 動作 |
|--------|------|
| Manually release this version | 審査通過後、自分で「Release」を押すまで公開されない。**初回はこれを推奨**（公開タイミングを制御できる） |
| Automatically release | 審査通過と同時に公開 |
| Scheduled | 日時指定 |

段階的リリース（Phased Release）はアップデート版でのみ使えます。初回リリースでは選べません。

### Phase 6 完了チェック

- [ ] 6.9 インチのスクショが en / ja に 3 枚以上
- [ ] Name / Subtitle / Description / Keywords / Support URL が en / ja 両方
- [ ] Privacy Policy URL（App Information）
- [ ] App Privacy の申告
- [ ] Age Rating
- [ ] Category / Price / Availability
- [ ] In-App Purchase がバージョンに紐付き「Ready to Submit」
- [ ] RevenueCatのProduct / Entitlement / Offeringが本番設定済み
- [ ] Shipaton提出用のプロモコードまたは無料トライアルが利用可能
- [ ] App Review Information の連絡先とメモ
- [ ] Build が選択されている（TestFlight で Processing 完了したもの）

---

## Phase 7. 審査提出からリリース

### 7-1. 提出前の最終チェック

- [ ] 提出するビルドで Phase 3-5 のチェックリスト A〜Eが通っている
- [ ] Settings のプライバシーポリシー行が実 URL を開く
- [ ] Sandbox で購入・リストアが通る
- [ ] `docs/progress.md` の「検証状況」を実機テストの結果で更新した
- [ ] `MARKETING_VERSION` が App Store Connect のバージョン（1.0）と一致
- [ ] git でリリースコミットにタグを打った（例: `v1.0-build1`）

### 7-2. 提出

バージョンページ右上 **Add for Review** → 内容確認 → **Submit to App Review**。ステータスが「Waiting for Review」→「In Review」→「Ready for Distribution」（Manual release の場合は「Pending Developer Release」）と進みます。

### 7-3. 審査期間と、このアプリで起こりやすいリジェクト理由

通常 24〜48 時間。初回提出は長めになることがあります。

| ガイドライン | 起こりうる指摘 | 予防 |
|-------------|--------------|------|
| 2.1 App Completeness | プライバシーポリシーがダミー URL / リンク切れ | Phase 2-5 |
| 2.3.3 Accurate Metadata | スクショが実際の画面と違う、別サイズ端末の画像 | Phase 6-1 |
| 3.1.1 In-App Purchase | 課金を伴わない「購入」ボタン、Restore がない、価格表示が実ストアと違う | Phase 4 |
| 3.1.1 | Paywall に価格・買い切りであることの明記がない | 価格は StoreKit から取得した `localizedPriceString` を表示 |
| 5.1.1 Data Collection | プライバシーラベルと実態の不一致 | Phase 6-3 |
| 4.0 Design | 最低 OS で表示崩れ | Phase 2-9 |
| Guideline 2.5.1 | 不足しているプライバシーマニフェスト（ITMS-91053 メール） | Phase 2-3 |

### 7-4. リジェクトされたら

1. App Store Connect → **Resolution Center** に理由とスクショが届く
2. 指摘が誤解なら Resolution Center で返信（Reply）。修正が必要なら修正 → ビルド番号 +1 → 再アップロード → 再提出
3. 再審査は通常初回より早い

### 7-5. リリース

- Manual release: 「Pending Developer Release」→ **Release This Version** を押す
- 公開後、App Store に反映されるまで数時間かかることがある
- App Store のページ URL（`https://apps.apple.com/app/id<AppleID>`）を控える。Apple ID は App Information にある

### 7-6. Shipaton 2026へ提出

App Store公開後、DevpostのRevenueCat Shipaton 2026へ提出します。提出締切は **2026年9月30日 23:45 PDT** です。ストア審査・反映には時間がかかるため、9月30日当日の提出を前提にしないでください。

提出前に以下を揃えます。

- App Storeの公開URL
- RevenueCat SDKを組み込んだ公開ビルド
- RevenueCatの実購入が動作することを示せる状態
- 審査員用のプロモコード、または無料トライアル
- 1024×1024 pxのアプリアイコン
- 1179×2556 px、端末フレームなしのスクリーンショット1枚以上
- YouTubeまたはVimeoに公開した2分以内のデモ動画
- アプリの機能説明とRevenueCatを使った課金方法の説明

DevpostのProject Submissionから上記を登録し、公開日が2026年8月1日〜9月30日の期間内であることを確認します。提出後は、公開URL、提出内容、プロモコードの有効性を保存しておきます。

---

## Phase 8. リリース後の運用

### 8-1. 監視

| 何を | どこで |
|------|-------|
| クラッシュ | Xcode → Window → Organizer → Crashes（シンボル付き） |
| 評価・レビュー | App Store Connect → Ratings and Reviews。返信できる |
| ダウンロード・購入 | App Store Connect → App Analytics / Sales and Trends。RevenueCat ダッシュボード |
| 利用状況 | PostHog（導入した場合） |

### 8-2. アップデートの出し方

1. `MARKETING_VERSION` を上げる（`1.0.1` / `1.1`）、`CURRENT_PROJECT_VERSION` を +1
2. App Store Connect → 「+」→ 新バージョンを作成 → What's New を en / ja で入力
3. Phase 5 → 6 → 7 を繰り返す（メタデータは前バージョンから引き継がれる）
4. アップデートでは **Phased Release**（7 日間かけて段階配信）が使える。問題があれば途中で停止できる

### 8-3. 緊急修正（hotfix）

- クリティカルなクラッシュは App Review Information の「Expedited Review」を申請できる（年に数回が目安。乱用不可）
- SwiftData のスキーマを変えるアップデートは **マイグレーションを必ず実機で確認**（既存データを持つ端末で旧版 → 新版へ上書きインストール）

### 8-4. v1.1 に向けた積み残し（`docs/progress.md` より）

- Dynamic Type 追従（`LOFont` を `Font.custom(_:size:relativeTo:)` ベースに移行）
- RevenueCat課金の改善、価格・Paywallの検証
- ロードマップ: CloudKit 同期 / ウィジェット / カレンダー / 消費周期予測

---

## 付録

### A. ワンページ・チェックリスト

```
Phase 0  [ ] RevenueCat商品仕様  [ ] アプリ名  [ ] 価格  [ ] ポリシー URL の置き場  [ ] サポート URL  [ ] Shipaton提出物
Phase 1  [ ] Program 加入  [ ] Xcode に Account  [ ] App Store Connect にアプリ  [ ] 有料 App 契約
Phase 2  [ ] 署名を戻す  [ ] アイコン  [ ] PrivacyInfo  [ ] 暗号キー  [ ] URL 差替  [ ] Release ビルド  [ ] iOS 17
Phase 3  [ ] Developer Mode  [ ] 実機で起動  [ ] 未検証 4 操作  [ ] コアループ  [ ] IME  [ ] 言語切替  [ ] 文字サイズ
Phase 4  [ ] IAP 作成  [ ] RevenueCat  [ ] SDK 差替  [ ] StoreKit Config  [ ] Sandbox 購入/リストア
Phase 5  [ ] Archive  [ ] Upload  [ ] 内部テスト  [ ] (任意) 外部テスト
Phase 6  [ ] 6.9" スクショ en/ja  [ ] テキスト en/ja  [ ] App Privacy  [ ] 年齢  [ ] カテゴリ  [ ] IAP 紐付け  [ ] 審査情報  [ ] プロモコード/無料トライアル
Phase 7  [ ] 最終チェック  [ ] 提出  [ ] リリース  [ ] App Store URL取得  [ ] Devpost提出
Phase 8  [ ] クラッシュ監視  [ ] レビュー返信
```

### B. コマンド集

```bash
# シミュレータ向けビルド（既存）
./scripts/build.sh

# Release 構成のビルド確認
xcodebuild -project LastOne.xcodeproj -scheme LastOne -configuration Release \
  -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath build/dd build

# 実機一覧
xcrun devicectl list devices

# 実機向けビルド + インストール + 起動
xcodebuild -project LastOne.xcodeproj -scheme LastOne -configuration Debug \
  -destination 'generic/platform=iOS' -derivedDataPath build/dd-device -allowProvisioningUpdates build
xcrun devicectl device install app --device <UDID> build/dd-device/Build/Products/Debug-iphoneos/LastOne.app
xcrun devicectl device process launch --device <UDID> <確定したBundle ID>

# アーカイブ
xcodebuild -project LastOne.xcodeproj -scheme LastOne -configuration Release \
  -destination 'generic/platform=iOS' -archivePath build/LastOne.xcarchive -allowProvisioningUpdates archive

# アップロード（scripts/ExportOptions.plist の destination=upload）
xcodebuild -exportArchive -archivePath build/LastOne.xcarchive \
  -exportOptionsPlist scripts/ExportOptions.plist -exportPath build/export -allowProvisioningUpdates

# App Store 用スクショ（6.9 インチ）
xcrun simctl boot "iPhone 17 Pro Max"
xcrun simctl install "iPhone 17 Pro Max" build/dd/Build/Products/Debug-iphonesimulator/LastOne.app
xcrun simctl launch "iPhone 17 Pro Max" <確定したBundle ID> -AppleLanguages "(en)"
xcrun simctl io "iPhone 17 Pro Max" screenshot build/shots/store-en-01.png

# アイコンのアルファ確認
sips -g hasAlpha LastOne/Assets.xcassets/AppIcon.appiconset/AppIcon.png

# ビルド番号を上げる（例: 1 → 2）
sed -i '' 's/CURRENT_PROJECT_VERSION = 1;/CURRENT_PROJECT_VERSION = 2;/g' LastOne.xcodeproj/project.pbxproj
```

### C. このリポジトリで触るファイル一覧

| ファイル | フェーズ | 変更内容 |
|---------|---------|---------|
| `LastOne.xcodeproj/project.pbxproj` | 2-1, 2-6 | 署名設定の削除と Team 設定、バージョン番号 |
| `LastOne/Assets.xcassets/AppIcon.appiconset/` | 2-2 | 1024 px PNG を追加 |
| `LastOne/PrivacyInfo.xcprivacy` | 2-3 | 新規作成 |
| `LastOne/Info.plist` | 2-4 | Xcode が生成。`ITSAppUsesNonExemptEncryption` |
| `LastOne/Support/URLConstants.swift` | 2-5 | 実 URL |
| `LastOne/Support/LOLimits.swift` | 2-7 | 無料枠の上限値。v1では課金導線を無効化するflagを追加しない |
| `LastOne/Services/EntitlementStore.swift` | 4-3（A） | `RevenueCatEntitlementStore` 追加 |
| `LastOne/App/LastOneApp.swift` | 4-3 / 4-6 | SDK 初期化、注入の差し替え |
| `scripts/ExportOptions.plist` | 5-2 | 新規作成（CLI アップロード用） |
| `docs/progress.md` | 3-6, 7-1 | 実機テスト結果で「検証状況」を更新 |
| `docs/feedback/device-test.md` | 3-6 | 実機テストの不具合台帳 |

### D. 用語

| 用語 | 意味 |
|------|------|
| Bundle ID | アプリの一意識別子。個人開発者用の名前空間 `com.kokiyoshida.stockbox`。App Store Connectへの初回アップロード後は変更不可 |
| Entitlement（RevenueCat） | 「Pro 機能が使える権利」の名前。本アプリでは `pro` |
| Product ID | App Store Connect上の課金アイテムID。`com.kokiyoshida.stockbox.pro`。作成後変更不可 |
| Sandbox | 課金のテスト環境。請求は発生しない |
| TestFlight | Apple 公式のベータ配信。90 日で失効 |
| Beta App Review | TestFlight 外部テストの初回に入る簡易審査 |
| Resolution Center | 審査結果とやり取りをする App Store Connect 内の窓口 |
| Phased Release | アップデートを 7 日かけて段階配信する仕組み。初回リリースでは使えない |
