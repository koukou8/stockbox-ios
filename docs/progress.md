# LastOne 実装進捗

> Generator がスプリント単位で更新する。仕様の正典は `docs/spec/lastone-app.md`、
> デザインの正典は `docs/design.md`、実装計画は `docs/spec.md`。

---

## 検証状況（2026-09-03 時点）

**Sprint 1〜4 すべて実装完了。** `./scripts/build.sh clean build` は `** BUILD SUCCEEDED **`
（エラー 0 / ソース由来 warning 0 / `project.pbxproj` 無変更 / Swift Package 依存 0 件）。

### 誰がどう検証したか

`.claude/agents/evaluator.md` の evaluator エージェントは **一度も実行していない**。
このエージェントは Playwright でブラウザを操作する前提で書かれており、iOS アプリには適用できないため。
`docs/feedback/` が存在しないのはこのためで、フィードバック未対応が残っているわけではない。

代わりに各スプリント完了時に以下で検証した。

1. `./scripts/build.sh` によるビルド（エラーゼロを完了条件とした）
2. `xcrun simctl` でのクリーンインストール → 起動 → スクリーンショット撮影（`build/shots/`）
3. スクリーンショットと `docs/design.md` の突き合わせ（日本語 / 英語の両ロケール）
4. SQLite（SwiftData ストア）を直接読んでの永続化・件数・リレーションの確認

### 実操作が未検証の項目

検証環境からシミュレータへタップ入力を送れなかったため、以下は実装済みだが実操作での確認ができていない。
手順は各スプリントの「Evaluator への引き渡し事項」のシナリオ #10〜#19 に記載。

| 対象 | スプリント |
|------|-----------|
| カテゴリのドラッグ並べ替え | Sprint 3 |
| カテゴリのスワイプ削除と確認ダイアログ | Sprint 3 |
| エクスポートの共有シート | Sprint 3 |
| インポートのファイル選択 | Sprint 3 |

タップ入力を有効にするには、ホスト側で次を実行する必要がある（要パスワード）。

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

### 受け入れ基準に対する既知の未達

- **Dynamic Type 追従（Sprint 4）**: `LOFont` は `docs/design.md` の実寸に合わせた
  `Font.system(size:)` の固定サイズのため、端末の文字サイズ設定に追従しない。
  文字サイズを上げてもレイアウトが破綻しないことは `simctl ui content_size` で確認済み。
  詳細と移行先は Sprint 4 の「既知の課題」を参照。

---

## Sprint 1: 基盤 — データモデル / デザインシステム / タブシェル / プリセット / i18n
**ステータス:** 実装完了 - ビルド成功・シミュレータ目視検証済み（evaluator エージェントによる評価は未実施）
**実装日:** 2026-09-02
**ビルド結果:** `./scripts/build.sh` → `** BUILD SUCCEEDED **`（ソース由来の warning 0 件）

### 実装内容

#### 1. SwiftData モデル定義
- `LastOne/Models/StockEnums.swift`: `TrackingMode`（`binary` / `count`）と `StockStatus`（`in_stock` / `low`）を `String, Codable, CaseIterable, Identifiable, Sendable` な enum で定義。将来 `out` を足せるよう raw value は String。
- `LastOne/Models/Category.swift`: `id`(unique) / `name` / `sortOrder` / `createdAt` / `items`。`@Relationship(deleteRule: .cascade, inverse: \Item.category)`。
- `LastOne/Models/Item.swift`: 仕様書のフィールドを過不足なく実装。`trackingModeRaw` / `statusRaw` を String で永続化し、`trackingMode` / `status` を computed property で公開。`logs` は cascade + `inverse: \PurchaseLog.item`。既定値は `LOStockDefaults`（threshold=1 / カウント初期値=2 / 既定補充数=2）に集約。
- `LastOne/Models/PurchaseLog.swift`: `id`(unique) / `purchasedAt` / `quantity` / `item`。

#### 2. ModelContainer 設定
- `LastOne/App/LastOneApp.swift`: 仮実装（`Text("LastOne")`）を差し替え。`Schema([Category, Item, PurchaseLog])` + `ModelConfiguration(isStoredInMemoryOnly: false)` でローカル永続化のみ。CloudKit 設定は付けていない。
- ルートに `.fontDesign(.rounded)` / `.tint(LOColor.accent)` / `.preferredColorScheme(.light)`（v1 は Light 固定）を適用。
- `AnalyticsClient` を `.environment(\.analytics, ...)` で注入。

#### 3. プリセット投入（Seeder）
- `LastOne/Services/CategorySeeder.swift`: `FetchDescriptor<Category>(fetchLimit: 1)` で存在確認し、0 件のときだけ「日用品 / 食品 / ペット用品」を `sortOrder` 0,1,2 で投入。
- 投入名は `NSLocalizedString` 経由で実行時ロケールに解決した文字列を確定保存する。
- 起動のたびに増えないことをシミュレータ実機で検証済み（3 回連続起動して `ZCATEGORY` は 3 件のまま）。

#### 4. デザイントークン
- `LastOne/DesignSystem/Color+Hex.swift`: `Color(hex: 0xFAF5EE)` 形式のイニシャライザ。
- `LastOne/DesignSystem/LOColor.swift`: `docs/design.md` §1 のカラーを全色定数化（背景 / テキスト 5 段階 / アクセント / 状態チップ 2 色 / Pro ゴールド / 罫線・枠線 / オーバーレイ / シャドウ / 4 種のグラデーション）。
- `LastOne/DesignSystem/LOFont.swift`: 役割別のサイズ・ウェイトを `.rounded` デザインで定数化。kicker の字間（0.14em × 12pt）も定数化。
- `LastOne/DesignSystem/LOMetrics.swift`: `LORadius`（角丸）/ `LOLayout`（ヘッダー 64/22/14・コンテンツ 8/18/22・要素間 14）/ シャドウ 3 種の View 拡張。

#### 5. 共通シェル部品
- `LOScreenHeader` / `LOScreenScaffold`（ヘッダー + 背景グラデーション + スクロール領域）
- `LOStatusChip`（在庫あり / のこり1つ）、`LOCategoryChip`
- `LOCard`（白・角丸 22・カードシャドウ）、`LOSubBlock`（`#FBF6EF` + 枠 `#EEE3D4`）
- `LOPrimaryCapsuleButton` / `LOPrimaryWideButton` / `LOQuietCapsuleButton` / `LOSubtleWideButton` / `LODashedAddButton` / `LOPressableButtonStyle`
- `LOSectionHeader`（カテゴリ名 + 件数 + 右に伸びるグラデ罫線）

#### 6. カスタムタブバー
- `LastOne/App/AppTab.swift` + `LastOne/DesignSystem/Components/LOTabBar.swift`。
- SF Symbols（`cart` / `shippingbox` / `gearshape`）を 21pt・regular（線幅 1.7 相当）で描画し、フレーム高 23pt。
- 選択タブのみ背景 `rgba(143,184,158,.16)`・角丸 18・文字色 `#5E7F62`、非選択 `#BDB1A2`。切り替えは `withAnimation(.snappy)`。
- 背景は `.ignoresSafeArea(edges: .bottom)` でホームインジケータ下まで伸ばし、タップ領域はセーフエリア内に収めている。
- 各タブに `accessibilityIdentifier`（`tab.buyList` / `tab.stocks` / `tab.settings`）を付与。

#### 7. 3 画面のプレースホルダ
- `BuyListView`: kicker `BUY LIST` / タイトル「買うもの」/ 右上メタは `status == low` の件数（`countLabel`）。中身は Sprint 3。
- `StocksView`: kicker `STOCKS` / タイトル「ストック」/ 右上メタ `<アイテム数> / 30`。カテゴリのセクション見出しのみ表示（プリセット投入の可視確認用）。アイテムカード・追加シートは Sprint 2。
- `SettingsView`: kicker `SETTINGS` / タイトル「設定」/ 右上メタ `Free`。脚注（`privacyNote`）のみ。Pro カード・設定リストは Sprint 3 / 4。

#### 8. String Catalog
- `LastOne/Resources/Localizable.xcstrings`（`sourceLanguage: en`、全 62 キーに en / ja の `stringUnit`、`extractionState: manual`）。
- `docs/design.md` §3 の全キーを網羅（`perks` は `perk1`〜`perk3`、`settings 行` は `settingsExport` 等に展開、`binaryAction` は `binaryActionAdd` / `binaryActionRemove` に展開）。
- `countLabel` / `catCount` は複数形バリエーション（en: one/other、ja: other）で登録。ビルド成果物に `Localizable.stringsdict` が生成されることを確認済み。
- `LastOne/Localization/LOStrings.swift`（`enum L`）に全キーを集約。View からはこれ経由でのみ文言を取得する。
- `LastOne/Localization/LODateFormat.swift`: `Date.FormatStyle` によるロケール準拠の月日フォーマッタ（Sprint 2 の最終購入日表示で使用）。

#### 9. AnalyticsClient の seam
- `LastOne/Services/AnalyticsClient.swift`: `AnalyticsEvent`（name + properties）、7 イベントを型で定義（`item_marked_low` / `item_purchased` / `item_opened` / `item_created` / `category_created` / `paywall_shown` / `pro_purchased`）、`PaywallReason` enum、`AnalyticsClient` プロトコル、`LoggingAnalyticsClient` スタブ、`EnvironmentValues.analytics`。
- PostHog SDK は追加していない。差し替え手順をプロトコル定義にコメントで記載。

#### 10. その他
- `LastOne/Support/LOLimits.swift`: 無料枠（カテゴリ 5 / アイテム 30）と Stocks メタの整形を 1 箇所に集約。
- `LastOne/Support/URLConstants.swift`: プライバシーポリシー / 利用規約のプレースホルダ URL。

### 自己評価

| 基準 | スコア (1-5) | コメント |
|------|-------------|---------|
| 機能完全性 | 5 | Sprint 1 のチェックリスト 8 項目すべてを実装。受け入れ基準（ビルド成功 / 外部依存 0 / 3 タブ / kicker・タイトル / プリセット 3 件・重複なし / 日英切替 / 文言ハードコードなし）をシミュレータ実機で確認済み。 |
| コード品質 | 4 | トークン・文言・上限値・URL をそれぞれ 1 箇所に集約し、後続スプリントが「画面の中身を埋めるだけ」になる構造にした。ただし共通部品の一部（`LOCard` / `LOSubBlock` / ボタン群 / `LODashedAddButton`）は Sprint 2・3 で使うまで未使用のまま置いている。 |
| UI/UX | 4 | ヘッダー・タブバー・背景グラデーションはプロトタイプと同等。ただし Sprint 1 の範囲上、Buy List のコンテンツ領域が空のままで「起動直後の第一印象」は薄い（Sprint 3 の空状態パネルで解消予定）。 |
| エラーハンドリング | 4 | Seeder は fetch / save の失敗時に投入をスキップしてログ出力し、起動は継続する。`ModelContainer` の生成失敗のみ `fatalError`（永続化がなければアプリとして成立しないため意図的）。 |
| 既存機能との統合 | 5 | 初回スプリントのため回帰対象なし。`project.pbxproj` は無変更、Swift Package 依存 0 件、`Package.resolved` は未生成。 |

### 技術的な判断

1. **エントリポイントを `LastOne/App/` に移動**: `LastOne/LastOneApp.swift` → `LastOne/App/LastOneApp.swift`。`LastOne` は file-system-synchronized group なので pbxproj の編集は不要（無変更を確認済み）。`docs/spec.md`「推奨ディレクトリ構成」に合わせた。
2. **プリセット投入のタイミングを `RootView.onAppear` にした**: `ModelContainer.mainContext` は `@MainActor` 隔離のため `App.init()`（nonisolated）からの同期呼び出しはコンパイルエラーになりうる。`onAppear` + `@State` ガード + Seeder 内の DB 件数チェックの三重で冪等性を担保した。
3. **`status` / `trackingMode` の永続化名**: `statusRaw` / `trackingModeRaw` という別名の String プロパティにして、enum は同名の computed property で公開した。SwiftData のマクロが computed property を永続化対象から外すため、スキーマは String のまま将来の case 追加に耐える。
4. **複数形の扱い**: `countLabel` / `catCount` は String Catalog の plural variations で登録し、`String(format: NSLocalizedString(key), n)` で解決している（キー名を design.md の表どおりに保つため、キーに書式指定子を含めない設計にした）。en で「1 item / 2 items」、ja で「N件」が正しく出る。
5. **日付フォーマット**: `Date.FormatStyle(...).month(.abbreviated).day()` を使い、書式そのものをロケールに委ねた。design.md の「8/15 に購入」は見え方の目安であり、実際は ja「9月2日 に購入」/ en「Bought Sep 2」となる（正典の「ロケール準拠フォーマッタを使う」を優先）。
6. **Stocks にカテゴリのセクション見出しだけ置いた**: Sprint 1 の受け入れ基準「初回起動でカテゴリが 3 件生成され、再起動しても増えない」を UI 上で確認可能にするため。アイテムカード・追加シート・破線ボタンは Sprint 2 に据え置いている。
7. **`LOLimits` / `LOURL` を Sprint 1 で先出し**: Stocks の右上メタ「`<アイテム数> / <上限>`」が design.md §2 の共通シェル要件に含まれるため、上限値の定数だけ先に 1 箇所へ置いた。上限判定ロジック・Paywall は Sprint 4。
8. **`metaPro` / `metaFree` もカタログ化**: 両言語とも "Pro" / "Free" と同じ表示だが、View にリテラルを書かない原則を守るためキー化した。
9. **タブアイコン**: プロトタイプの SVG（カート / 箱 / 歯車）に最も近い SF Symbols として `cart` / `shippingbox` / `gearshape` を選定。カスタムフォント・カスタムアイコンは同梱していない。

### 既知の課題

- Buy List のコンテンツ領域が空（Sprint 3 で空状態パネルを実装するまで、起動直後の画面がヘッダーとタブバーだけになる）。
- 共通部品のうち `LOCard` / `LOSubBlock` / 各種ボタン / `LODashedAddButton` は Sprint 2・3 で配線するまで未使用。Xcode の警告は出ないが、実画面での見え方の検証はまだ済んでいない。
- Dynamic Type を上げたときのヘッダー・タブバーの検証は未実施（Sprint 4 の「表示仕上げ」で対応予定）。
- `LOURL` はプレースホルダ URL（`https://example.com/...`）。公開前に差し替えが必要（仕様書の TBD）。
- `docs/spec.md` の受け入れ基準にある `-destination 'platform=iOS Simulator,name=iPhone 17'` は `scripts/build.sh` に埋め込まれている。他機種で検証する場合はスクリプト側の変更が必要。

### 仕様に関する気づき（`spec.md` は変更していない）

- `docs/design.md` §3 の `limitCats` は ja / en とも「5個」を文字列に直書きしているが、実装では `%lld` にして `LOLimits.freeCategoryLimit` から渡すようにした（「上限値は 1 箇所の定数にまとめる」という Sprint 4 の要求と整合させるため）。表示結果は同じ。
- design.md の `binaryHint`（ja「在庫あり / のこり1つ」）はプロトタイプ本文とスラッシュ記号が異なる（表では「在庫あり・のこり1つ」）。表側の中黒を採用した。

### Evaluator への引き渡し事項

**このプロジェクトは iOS アプリです。Web ブラウザ / Playwright / URL での検証は行いません。**

#### 1. ビルド検証（必須）

```bash
cd /Users/koukiyoshida/development/lastone-app
./scripts/build.sh
```

- 判定: 出力に `** BUILD SUCCEEDED **` が含まれること。エラー全文は `build/last-build.log`。
- 補足: `xcodebuild` は CoreSimulator への XPC 接続を行うため、サンドボックス内では必ず失敗します。**`dangerouslyDisableSandbox: true` を付けて実行してください。**
- 外部依存が増えていないことの確認:
  ```bash
  git status --porcelain LastOne.xcodeproj/project.pbxproj   # 出力が空 = 無変更
  find . -name Package.resolved -not -path "./build/*"       # 出力が空 = 依存 0 件
  ```

#### 2. シミュレータへのインストールと起動

```bash
BID=jp.co.gimic.lastone
APP=build/dd/Build/Products/Debug-iphonesimulator/LastOne.app
xcrun simctl boot "iPhone 17" || true
open -a Simulator
xcrun simctl uninstall booted $BID          # クリーンな初回起動を再現
xcrun simctl install booted "$APP"
xcrun simctl launch booted $BID -AppleLanguages "(ja)" -AppleLocale "ja_JP"   # 日本語
# xcrun simctl launch booted $BID -AppleLanguages "(en)" -AppleLocale "en_US" # 英語
xcrun simctl io booted screenshot /tmp/lastone.png
```

#### 3. テストシナリオ

| # | 操作 | 期待結果 |
|---|------|---------|
| 1 | アンインストール → インストール → **日本語**で起動 | 背景が生成り色（`#FAF5EE` 系）。ヘッダーに kicker `BUY LIST`（大文字・字間広め）とタイトル「買うもの」、右上に「0件」。下部に 3 タブ（買うもの / ストック / 設定）。 |
| 2 | 「ストック」タブをタップ | 選択ハイライト（淡いセージの角丸 18 背景）がストックへ移動し、文字色が濃いセージになる。ヘッダーが kicker `STOCKS` / タイトル「ストック」/ 右上「0 / 30」。**プリセットカテゴリ「日用品」「食品」「ペット用品」の 3 セクションが 0件 で並ぶ。** |
| 3 | 「設定」タブをタップ | kicker `SETTINGS` / タイトル「設定」/ 右上「Free」。脚注「データは端末内にのみ保存されます。…」が表示される。 |
| 4 | アプリを終了して再起動（`simctl terminate` → `launch`）を 2 回繰り返し、ストックタブを開く | **カテゴリが 3 件のまま増えない**（重複投入なし）。 |
| 5 | アンインストール → インストール → **英語**で起動し、各タブを巡回 | タブが `Buy List / Stocks / Settings`、カテゴリが `Daily Goods / Food / Pet Supplies`、Buy List のメタが `0 items`。テキストの見切れ・折返し崩れがない。 |
| 6 | 3 タブを何度か往復 | クラッシュせず、ハイライトが追従する。ホームインジケータとタブバーが重なっていない。 |

#### 4. データ層の直接確認（プリセット投入の検証用）

```bash
BID=jp.co.gimic.lastone
CONT=$(xcrun simctl get_app_container booted $BID data)
sqlite3 "$CONT/Library/Application Support/default.store" \
  "SELECT ZSORTORDER, ZNAME FROM ZCATEGORY ORDER BY ZSORTORDER;"
# 期待: 0|日用品 / 1|食品 / 2|ペット用品（英語起動時は Daily Goods / Food / Pet Supplies）
sqlite3 "$CONT/Library/Application Support/default.store" ".tables"
# 期待: ZCATEGORY / ZITEM / ZPURCHASELOG が存在する
```

#### 5. 本スプリントの範囲外（不合格にしないでください）

以下は仕様上 Sprint 2 以降の実装対象です。

- アイテムの追加 / 編集 / 削除、アイテムカード、二値トグル、開封 −1（Sprint 2）
- Buy List の 1 行カード・「買った」操作・空状態パネル、カテゴリ管理シート、Settings の Pro カードと設定リスト、エクスポート / インポート（Sprint 3）
- 無料枠の上限判定・Paywall・課金（Sprint 4）
- ユニットテスト / UI テストターゲット（`project.pbxproj` の編集が必要なため、仕様で新規作成を禁止されている）

---

## Sprint 2: Stocks 画面とコア状態遷移 + アイテム登録／編集シート
**ステータス:** 実装完了 - ビルド成功・シミュレータ目視検証済み（evaluator エージェントによる評価は未実施）
**実装日:** 2026-09-02
**ビルド結果:** `./scripts/build.sh` → `** BUILD SUCCEEDED **`（ソース由来の warning 0 件 / `project.pbxproj` 無変更 / `Package.resolved` 未生成）

### 実装内容

#### 1. ItemStateService（状態遷移の集約）
- `LastOne/Services/ItemStateService.swift`（新規）。View から SwiftData へ直接書き込まず、必ずこの型を経由する。`updatedAt` の更新と `ModelContext.save()` もここで行う。
- 二値方式: `markLow` / `unmarkLow` / `toggleBinary`。
- カウント方式: `openOne` … `stockCount = max(0, stockCount - 1)`、`status = (stockCount <= threshold) ? .low : .inStock`。`stockCount == 0` でさらに押しても 0 のまま維持（クラッシュしない）。
- `purchase`（Sprint 3 の Buy List 用に先行実装）… `status = .inStock` / `lastPurchasedAt = now` / `PurchaseLog` 追記。カウント方式は `stockCount = max(threshold + 1, stockCount + 2)` とし `quantity` に実際の増分を記録、二値方式は `quantity = 1`。
- 生成 / 更新 / 削除（`create` / `update` / `delete`）も同居させ、アイテムに対する全ミューテーションを 1 箇所に集約した。
- 計測は `AnalyticsClient` プロトコル越し。`item_created` / `item_marked_low` / `item_opened` を発火（`item_purchased` は Sprint 3 の Buy List から）。

#### 2. Stocks 一覧（`LastOne/Features/Stocks/StocksView.swift`）
- カテゴリ `sortOrder` 昇順のセクション（`LOSectionHeader` = カテゴリ名 + 件数 + 右に伸びるグラデ罫線）→ アイテムカード（カテゴリ内 `sortOrder` 昇順）→ 末尾に破線の「＋ アイテムを追加」（`LODashedAddButton`）。
- アイテムはリレーション（`category.items`）ではなく `@Query` の結果から絞り込み、追加・削除・カテゴリ変更が確実に一覧へ反映されるようにした。
- 右上メタは Sprint 1 のまま `<アイテム数> / 30`（`LOLimits.stocksMeta`）。

#### 3. アイテムカード（`LastOne/Features/Stocks/StockItemCard.swift`）
- 白・角丸 22・padding 15/16・カードシャドウ。上段左にアイテム名（16/medium）＋最終購入日（11.5 `#B0A496`）、上段右に状態チップ。
- 最終購入日は `L.lastPurchasedLabel(_:)`（`Date.FormatStyle` 経由）。ja「8月15日 に購入」/ en「Bought Aug 15」、未購入は「まだ購入記録なし / Never bought yet」。
- 二値方式の操作行: 全幅の淡いボタン（`#FBF6EF` / 枠 `#EEE3D4` / 角丸 16）。ラベルは `in_stock`→「買うものリストに追加」、`low`→「買うものリストから除外」で反転。
- カウント方式の操作行: `#FBF6EF` ブロックに大きな数値（20/bold）+「つストック（閾値 N）」、右に「開封 −1」カプセルボタン。
- 状態変更は `withAnimation(.snappy(duration: 0.22))`。チップ / ラベル / 数値は `contentTransition` で控えめにクロスフェードする。
- カードの**ボタン以外の領域をタップすると編集シートが開く**（ボタン領域はボタンが優先して消費する）。

#### 4. アイテム追加 / 編集シート（`LastOne/Features/ItemEditor/ItemEditorSheet.swift`）
- 構成は `docs/design.md` §2「アイテム追加シート」どおり: ドラッグハンドル（44×5 / `#E4D9C9`）→ タイトル（20/bold）→ 名前入力（白・角丸 16・枠 `#EBE0D0`・プレースホルダ `namePlaceholder`）→ カテゴリチップ選択 → 管理方式の 2 択カード（サブテキスト付き・角丸 18）→「追加する」（角丸 20 / `#8FB89E`）→ 残り枠ラベル。
- 追加のデフォルトは二値方式 / `threshold = 1` / `status = in_stock`、カウント方式を選んだときのみ `stockCount = 2`。名前が空（空白のみ）なら「新しいアイテム / New item」。
- 編集時はタイトルと CTA を `editSheetTitle` / `editConfirm` に切り替え、名前 / カテゴリ / 管理方式 / 閾値（＋いまのストック数）を変更でき、末尾に削除導線を持つ。削除は確認ダイアログを挟む。
- 残り枠ラベルは `L.quota(isPro: false, remaining:)` で**表示のみ**。上限によるブロックは Sprint 4。

#### 5. 共通部品の追加（DesignSystem）
- `LOFlowLayout`（`Layout` プロトコルによる折り返しレイアウト。カテゴリチップの `flex-wrap` 相当）
- `LOSelectableChip`（選択カプセルチップ）/ `LOChoiceCard`（管理方式の 2 択カード）/ `LOFieldLabel`（シート内の項目見出し）
- トークン追記: `LOFont.fieldLabel` / `.textInput` / `.sheetButton` / `.chipSelectable` / `.choiceCardTitle` / `.choiceCardSubtitle`、`LORadius.choiceCard = 18`、`LOColor.dragHandle = #E4D9C9`
- `LOPrimaryWideButton` に `font` パラメータ（既定は従来値）を追加。`LOStatusChip` / `LOSubtleWideButton` に `contentTransition(.opacity)` を追加。

#### 6. String Catalog
- `Localizable.xcstrings` に 12 キーを en / ja 両方で追加（62 → 74 キー）。JSON の妥当性と、ビルド成果物 `en.lproj` / `ja.lproj` への反映を確認済み。
- 追加キー: `editSheetTitle` / `editConfirm` / `countSettings` / `stockCountLabel` / `threshold` / `thresholdHint` / `editHint` / `deleteItem` / `deleteItemTitle` / `deleteItemMessage` / `deleteItemConfirm` / `cancel`
- すべて `LastOne/Localization/LOStrings.swift`（`enum L`）経由で参照する。View に UI 文言のリテラルは無い。

### 自己評価

| 基準 | スコア (1-5) | コメント |
|------|-------------|---------|
| 機能完全性 | 5 | Sprint 2 のチェックリスト 9 項目をすべて実装。シミュレータ実機で「二値トグルのラベル反転」「開封 −1 で 3→2→1（自動 low）→0」「0 での連打でもクラッシュしない」「未購入の `noLast` 表示」「追加シート / 編集シートの全構成」を日英両方で確認済み。 |
| コード品質 | 4 | 状態遷移も生成・更新・削除も `ItemStateService` の 1 箇所に集約し、Buy List（Sprint 3）がそのまま `purchase` を呼べる形にした。カード / シートは既存デザイントークンと共通部品だけで組んでいる。折り返しレイアウトを自前実装した分だけコード量が増えている。 |
| UI/UX | 4 | プロトタイプの Stocks 画面・追加シートをほぼ再現。英語でもボタン・チップの見切れなし。ただしカードのタップで編集に入る導線は視覚的なヒント（chevron 等）が無く、`design.md` に指定が無いため控えめなままにしている。 |
| エラーハンドリング | 4 | `stockCount` 0 での連打、`stockCount` が nil のカウント方式アイテム、カテゴリ未選択（CTA を無効化）、保存失敗（ログ出力して継続）をカバー。削除は「シートを閉じてから実行」にして削除済みモデルの参照クラッシュを防いでいる。 |
| 既存機能との統合 | 5 | Sprint 1 の 3 タブシェル・プリセット投入・デザイントークン・String Catalog をそのまま利用し、破壊的変更なし。クリーンインストール後の store は `categories=3 / items=0 / logs=0` で、Sprint 1 の受け入れ基準を維持している。 |

### 技術的な判断

1. **`ItemStateService` に create / update / delete も同居させた**: `docs/spec.md` が要求するのは markLow / unmarkLow / openOne / purchase だが、「View から SwiftData の書き込みを直接行わない」という原則を通すため、アイテムに対する全ミューテーションを同じ型に集約した。Sprint 3 のカテゴリ管理は別サービスに分ける想定。
2. **アイテムが 0 件のカテゴリもセクション見出しを表示する**: プロトタイプ（`screen/LastOne App.dc.html`）は空カテゴリを `filter` で落としているが、(a) Sprint 1 の受け入れ基準「プリセット 3 セクションが並ぶ」を維持するため、(b) 空カテゴリが一覧から消えるとそこにアイテムを足せることが伝わらないため、全カテゴリを表示する方を選んだ。`docs/spec.md` / `docs/design.md` に「空カテゴリを隠す」記述は無い。
3. **編集シートに「いまのストック数」ステッパーを追加した**: `docs/spec.md` の編集項目は「名前 / カテゴリ / 管理方式 / 閾値」だが、Sprint 2 単体では `stockCount` を既定値 2 以外にする手段が無く、受け入れ基準「カウント方式（`stockCount = 3`, `threshold = 1`）で開封 −1」を検証できない。閾値の隣に並べるのが自然でもあるため追加した（フィールドの新設ではなく既存フィールドの編集 UI）。
4. **削除はシートを閉じきってから親が実行する**: シート内で `context.delete` すると、`.sheet(item:)` が保持する削除済み `Item` を body が読んでクラッシュしうる。シートは `onRequestDelete` で親に依頼するだけにし、`StocksView` が `.sheet(onDismiss:)` で実際の削除を行う。削除確認ダイアログに出す名前も init で控えて live なモデルを読まない。
5. **編集はドラフト方式**: 入力値は `@State` に保持し、「保存する」を押したときだけ `ItemStateService.update` で書き戻す。シートを閉じただけでは何も変わらない。
6. **カウント方式の `status` は保存時に必ず再計算する**: カウント方式の状態は「数と閾値」から一意に導出できるため、閾値や在庫数を編集した結果と状態が矛盾しないようにした。二値方式に切り替えた場合は `stockCount = nil` にし、`status` は現状を維持する（在庫の有無はユーザーの申告だけが情報源のため）。
7. **`openOne` の計測は実際に減ったときだけ発火**: `stockCount == 0` での空打ちで `item_opened` が水増しされるのを防ぐ。状態の再計算は毎回行う。
8. **シートの detent**: 追加は `.medium` 起点（プロトタイプのボトムシートに近い）、編集は項目が多いので `.large` 起点。どちらもドラッグで切り替え可能。
9. **カード全体（ボタン以外）を編集の導線にした**: `docs/design.md` にアイテムカードから編集へ入る導線の指定が無いため、追加の UI 要素を足さずタップ領域だけを広げる方式にした。アクセシビリティヒントに `editHint`（「タップして編集」）を付与している。
10. **折り返しレイアウトを自前実装（`LOFlowLayout`）**: Swift Package 依存の追加が禁止されているため、`Layout` プロトコルで最小限の flow layout を書いた。
11. **`sortOrder` はカテゴリ内の最大値 + 1**: 追加時とカテゴリ変更時に末尾へ置く。並べ替え UI は仕様に無いため実装していない。
12. **`design.md` §3 に無い文言のキー命名**: 既存の命名（`addSheetTitle` / `addConfirm`）に合わせて `editSheetTitle` / `editConfirm` などとし、削除まわりは `deleteItem*` に揃えた。

### 既知の課題

- **残り枠ラベルは表示のみ**（「あと N 個まで無料で登録できます」）。上限に達しても追加はブロックされない。上限判定と Paywall は Sprint 4 の担当（`docs/spec.md` の指示どおり）。
- **カテゴリの追加・改名・並べ替え・削除は未実装**（Sprint 3）。編集シートでは既存カテゴリからの選択のみ。カテゴリが 0 件だと「追加する」が押せない実装だが、プリセット 3 件があるため現状は到達しない。
- **Buy List は空のまま**（Sprint 3）。二値トグルで `low` にしても、右上メタの件数が増えるだけで一覧には何も出ない。
- **削除確認ダイアログの見た目は未検証**。このマシンでは `osascript`/System Events に補助アクセスが許可されておらず、シミュレータへタップ入力を送れないため（詳細は下記「検証方法の制約」）。
- **アイテムの手動並べ替え UI は無い**。`sortOrder` は追加順のまま。仕様に要求が無いため実装していない。
- Dynamic Type / セーフエリアの詰めは Sprint 4 の「表示仕上げ」で対応予定。

### 検証方法の制約（Evaluator への注記）

Claude Code のサンドボックス環境では `xcrun simctl` にタップ入力の API が無く、`osascript`（System Events）も補助アクセス未許可のため、**エージェント側からシミュレータの UI を操作できない**。

そのため本スプリントの動作確認は、`RootView` の初期タブと `StocksView` に**一時的な検証用ハーネス**（サンプルアイテムの投入 → `toggleBinary` / `openOne` の自動実行 → シートの自動表示）を仕込んだビルドで日英のスクリーンショットを取得して行った。ハーネスは検証後に**完全に撤去済み**（バックアップとの差分ゼロを確認）で、最終ビルドとクリーンインストールでの store 状態（`categories=3 / items=0 / logs=0`）も確認している。取得済みスクリーンショット:

- `build/shots/s2-ja-01-list.png` — 日本語の Stocks 一覧（二値カード / カウントカード / 破線の追加ボタン）
- `build/shots/s2-ja-03-zero-count.png` — トグル後（「のこり1つ」＋「買うものリストから除外」）、`stockCount = 0`、追加シート
- `build/shots/s2-ja-05-edit-sheet.png` — 編集シート（日本語）
- `build/shots/s2-en-01-list.png` / `s2-en-02-add-sheet.png` / `s2-en-03-edit-sheet.png` — 英語版

### Evaluator への引き渡し事項

**このプロジェクトは iOS アプリです。Web ブラウザ / Playwright / URL での検証は行いません。**

#### 1. ビルド検証（必須）

```bash
cd /Users/koukiyoshida/development/lastone-app
./scripts/build.sh
```

- 判定: 出力に `** BUILD SUCCEEDED **` が含まれること。エラー全文は `build/last-build.log`。
- **`xcodebuild` は CoreSimulator への XPC 接続を行うため、サンドボックス内では必ず失敗します。`dangerouslyDisableSandbox: true` を付けて実行してください。**
- 外部依存が増えていないことの確認:
  ```bash
  find . -name Package.resolved -not -path "./build/*"   # 出力が空 = 依存 0 件
  ```

#### 2. シミュレータへのインストールと起動

```bash
BID=jp.co.gimic.lastone
APP=build/dd/Build/Products/Debug-iphonesimulator/LastOne.app
xcrun simctl boot "iPhone 17" || true
open -a Simulator
xcrun simctl uninstall "iPhone 17" $BID          # クリーンな初回起動を再現
xcrun simctl install "iPhone 17" "$APP"
xcrun simctl launch "iPhone 17" $BID -AppleLanguages "(ja)" -AppleLocale "ja_JP"   # 日本語
# xcrun simctl launch "iPhone 17" $BID -AppleLanguages "(en)" -AppleLocale "en_US" # 英語
xcrun simctl io "iPhone 17" screenshot build/shots/check.png
```

#### 3. テストシナリオ（Sprint 2 の受け入れ基準に対応）

| # | 操作 | 期待結果 |
|---|------|---------|
| 1 | 起動 →「ストック」タブ | プリセット 3 セクション（日用品 / 食品 / ペット用品）が「0件」で並び、末尾に破線の「＋ アイテムを追加」。右上メタは「0 / 30」。 |
| 2 | 「＋ アイテムを追加」→ 名前「醤油」/ カテゴリ「食品」/ 二値 →「追加する」 | 食品セクションに「醤油」カードが**在庫あり**チップ付きで現れる。最終購入日は「まだ購入記録なし」。右上メタが「1 / 30」。 |
| 3 | 「＋ アイテムを追加」→ 名前を空のまま「追加する」 | 「新しいアイテム」（英語では「New item」）という名前のアイテムが作られる。 |
| 4 | 醤油の「買うものリストに追加」をタップ | チップが「のこり1つ」に、ボタンラベルが「買うものリストから除外」に変わる（`.snappy` の控えめなアニメーション）。 |
| 5 | もう一度タップ | 「在庫あり」/「買うものリストに追加」に戻る。 |
| 6 | 「＋ アイテムを追加」→ 名前「トイレットペーパー」/ カテゴリ「日用品」/ **カウント** →「追加する」 | カード下段が「2 つストック（閾値 1）」+「開封 −1」ブロックになる。チップは「在庫あり」。 |
| 7 | カードをタップ（ボタン以外の余白）→ 編集シート →「いまのストック数」を **3** に →「保存する」 | カードが「3 つストック（閾値 1）」になる。 |
| 8 | 「開封 −1」を 1 回 | 「2 つストック」になり、チップは**在庫ありのまま**。 |
| 9 | 「開封 −1」をもう 1 回 | 「1 つストック」になり、**自動で「のこり1つ」チップ**に変わる。 |
| 10 | 「開封 −1」をさらに 3 回以上連打 | 「0 つストック」で止まり、**クラッシュしない**。マイナスにならない。 |
| 11 | アプリを終了（`simctl terminate`）→ 再起動 | 状態・カウント値・アイテムがすべて保持されている。 |
| 12 | カードをタップ → 編集シートでカテゴリを「食品」に変更 →「保存する」 | 一覧上でアイテムが日用品セクションから食品セクションへ移動する。セクションの件数も追従する。 |
| 13 | カードをタップ → 「このアイテムを削除」→ 確認ダイアログで「削除する」 | シートが閉じ、カードが消える。再起動しても復活しない。 |
| 14 | 確認ダイアログで「キャンセル」 | 何も削除されない。 |
| 15 | **英語**で起動して 1〜13 を巡回 | `In stock` / `Last one` / `Add to Buy List` / `Remove from Buy List` / `3 in stock (threshold 1)` / `Opened −1` / `Bought Aug 15` / `Never bought yet` / `+ Add item` / `Add an item` / `Edit item` が表示され、見切れ・折返し崩れが無い。 |

#### 4. データ層の直接確認

```bash
BID=jp.co.gimic.lastone
CONT=$(xcrun simctl get_app_container "iPhone 17" $BID data)
sqlite3 "$CONT/Library/Application Support/default.store" \
  "SELECT ZNAME, ZTRACKINGMODERAW, ZSTATUSRAW, ZSTOCKCOUNT, ZTHRESHOLD FROM ZITEM ORDER BY ZSORTORDER;"
# 期待: 二値方式は ZSTOCKCOUNT が NULL、カウント方式は数値。ZSTATUSRAW は in_stock / low。
```

#### 5. コンソールログでのアナリティクス確認

```bash
xcrun simctl spawn "iPhone 17" log stream --predicate 'processImagePath CONTAINS "LastOne"' --style compact
# 「追加する」で [analytics] item_created、「買うものリストに追加」で item_marked_low、
# 「開封 −1」で item_opened が出力される（PostHog SDK は未導入・print スタブ）。
```

#### 6. 本スプリントの範囲外（不合格にしないでください）

以下は仕様上 Sprint 3 以降の実装対象です。

- Buy List の 1 行カード・「買った」操作・空状態パネル・右上メタの追従（Sprint 3）
- カテゴリ管理シート（追加 / 改名 / 並べ替え / 削除）、Settings の Pro カードと設定リスト、エクスポート / インポート（Sprint 3）
- 無料枠の上限判定・Paywall・課金（Sprint 4）。**残り枠ラベルは表示されますが、31 個目のアイテムも登録できます（仕様どおり）。**
- Stocks 右上メタの「N / ∞」表示、アイテム追加シートの「Pro：登録数は無制限です」（Sprint 4）
- ユニットテスト / UI テストターゲット（`project.pbxproj` の編集が必要なため、仕様で新規作成を禁止されている）

---

## Sprint 3: Buy List / 購入記録 / カテゴリ管理 / Settings 骨格
**ステータス:** 実装完了 - ビルド成功・シミュレータ目視検証済み（evaluator エージェントによる評価は未実施）
**実装日:** 2026-09-02
**ビルド結果:** `./scripts/build.sh` → `** BUILD SUCCEEDED **`（ソース由来の warning 0 件 / `project.pbxproj` 無変更 / `Package.resolved` 未生成 / Swift Package 依存 0 件）

### 前スプリントからの積み残しへの対応

- **Stocks でアイテム 0 件のカテゴリのセクションが出ていた問題を修正。**
  `StocksView` を、デザイン試作（`screen/LastOne App.dc.html` の `groups ... .filter(g => g.items.length > 0)`）と同じく
  **アイテムが 1 件以上あるカテゴリだけ**を描画するよう変更した（Sprint 2 の技術的判断 #2 を撤回）。
  画面が真っ白にならないよう、表示できるセクションが 0 件のときは案内文（`stocksEmptyHint`）を
  破線の「＋ アイテムを追加」の上に出す。シミュレータで
  「プリセット 3 カテゴリ / アイテム 0 件」→ ヒント + 追加ボタンのみ、
  「日用品 2 / 食品 2 / ペット用品 0」→ ペット用品のセクションが出ないことを確認済み。
- `docs/feedback/` は存在しないため、Evaluator フィードバックへの対応はなし。

### 実装内容

#### 1. Buy List 一覧（`LastOne/Features/BuyList/`）
- `BuyListView.swift`: `status == low` を自動集約。並び順はカテゴリ `sortOrder` → アイテム `sortOrder`。
  右上メタは `L.countLabel(lowItems.count)` で `@Query` に追従する。行間はプロトタイプに合わせて 12。
- `BuyListRow.swift`（新規）: 白・角丸 22・padding 16/16/16/18・カードシャドウ ＋ 淡いアプリコット枠
  （`rgba(196,113,60,.10)`）。左にアイテム名（16/medium）、2 行目にカテゴリチップ
  （背景 `#F4EEE5` / 文字 `#9A8D7E`）と最終購入日ラベル、右に「買った」カプセルボタン
  （`#8FB89E` / 白文字 / ボタンシャドウ）。
- 「買った」は `ItemStateService.purchase` を `withAnimation(.snappy(duration: 0.24))` で呼び、
  行が消えるところまで控えめにアニメーションする（`transition(.opacity + .scale)`）。

#### 2. 「買った」操作（Sprint 2 実装分の配線）
- `status = in_stock` / `lastPurchasedAt = now` / `updatedAt = now` / `PurchaseLog` を 1 件追記。
- カウント方式は `stockCount = max(threshold + 1, stockCount + 2)`、`quantity` は実際の増分。
  二値方式は `quantity = 1`。ロジックは Sprint 2 で用意した `ItemStateService.purchase` をそのまま再利用し、
  Buy List 側にはロジックを持たせていない。
- 計測 `item_purchased` は `ItemStateService.purchase` の中で `AnalyticsClient` 越しに発火する。

#### 3. Buy List 空状態
- `EmptyBasketIllustration.swift`（新規）: 「空のかご」の幾何イラスト。プロトタイプの 150×112 の座標を
  そのまま写し、`UnevenRoundedRectangle`（持ち手 / かご本体）・`Capsule`（縁）・`Circle`（粒 3 つ）だけで構成。
  `.easeInOut(2.75s).repeatForever(autoreverses:)` で −6pt のふわふわ上下（CSS の `floatSoft 5.5s` 相当）。
  「動きを減らす」設定ではアニメを止める。装飾なので `accessibilityHidden`。
  **本番アセットへ差し替えるときは、このファイルの `body` を `Image(...)` に置き換えるだけでよい**独立 View にしてある。
- `BuyListEmptyState.swift`（新規）: 角丸 30・`#FDFAF5`→`#F8F2E9` グラデ・枠 `#F0E7DA` 1.5px のパネルに
  イラスト → `emptyTitle` → `emptyBody`（最大幅 230）→「ストックを見る」。
  ボタンを押すと `selection = .stocks` で Stocks タブへ切り替わる。

#### 4. カテゴリ管理（`LastOne/Features/CategoryManager/CategoryManagerSheet.swift` / `LastOne/Services/CategoryService.swift`）
- `CategoryService`（新規）: `create` / `rename` / `move` / `applySortOrder` / `delete` / `canDelete`。
  `ItemStateService` と同じ方針で、View から SwiftData へ直接書き込まない。`sortOrder` の 0 起点連番維持もここが担当。
  `category_created` を `AnalyticsClient` 越しに発火する。
- シートは design.md どおりの見た目（ドラッグハンドル → タイトル → 行 → 破線の「＋ カテゴリを追加」）。
  行は白・角丸 18・padding 14/16 に、ハンドルアイコン（`line.3.horizontal` / `#D6C9B6`）+ 名前 + 件数。
- **追加**: 「新しいカテゴリ N」を末尾に作り、そのままインライン改名にフォーカスが入る。
- **名称変更**: 行タップでその行が `TextField` に変わる（インライン編集）。確定は Return / 他の行のタップ /
  追加・削除の直前 / シートを閉じたとき。空文字なら元の名前を維持する。
- **並べ替え**: `List` + `ForEach.onMove`（行の長押しドラッグ）。並べ替え後の配列順で `sortOrder` を振り直して永続化する。
- **削除**: 左スワイプ。

#### 5. カテゴリ削除の扱い（決定事項）
- **所属アイテムがある場合**: 確認ダイアログを出し、`deleteCategoryMessage` で
  「「%@」と、所属する %lld 件のアイテム・購入履歴をすべて削除します。この操作は取り消せません。」と明示する（cascade）。
- **所属アイテムが 0 件の場合**: 確認なしで即削除する（消えて困るものが無く、`docs/spec.md` の要求も
  「所属アイテムがある場合は削除前に確認を出し」であるため）。
- **カテゴリが 1 件しかない場合**: 削除させない。スワイプアクション自体は出したうえで
  `lastCategoryTitle` / `lastCategoryMessage` のアラートで理由を説明する（黙って無反応にしない）。
- 削除後は残りのカテゴリの `sortOrder` を 0 起点に詰め直す。

#### 6. Settings 画面（`LastOne/Features/Settings/`）
- `ProCard.swift`（新規）: ゴールドグラデ `#FDF3E2`→`#F8E7CF`・角丸 26・padding 22。
  PRO バッジ（白 75% カプセル・字間 0.12em・`#B08344`）+ 購入状態（`proStatus`）+ 見出し（19/bold `#6E4F26`）
  + 説明 + 「Pro を見る」（`#C99A56` / Pro ボタンシャドウ）/「リストア」（白 70%）。
  **Sprint 3 ではレイアウトのみ**で、ボタンのアクションは空クロージャ（Sprint 4 で `EntitlementStore` に配線）。
- `LOSettingsList.swift`（新規・DesignSystem）: `LOSettingsRow`（ラベル + 値 + 任意のシェブロン・padding 17/18・
  押下時に `#FDFAF5` が敷かれる）/ `LOSettingsCard`（白・角丸 24・カードシャドウ）/ `LOSettingsDivider`（`#F4EDE3`）。
- リストの 5 行: 「カテゴリの管理 >」（右に `N カテゴリ`・シェブロン付き）/ データのエクスポート（右に `JSON`）/
  データのインポート / 言語について（右に `端末の設定に追従`）/ プライバシーポリシー（`LOURL.privacyPolicy` を開く）。
- 末尾に脚注（`privacyNote`）。右上メタは `Free`（Sprint 4 で Pro を反映）。
- `LanguageInfoSheet.swift`（新規）: 端末の設定に追従する旨の説明 + `UIApplication.openSettingsURLString` で
  iOS 設定アプリへ。アプリ内の言語切替 UI は置かない（MVP の意図的な制限）。

#### 7. エクスポート / インポート（`LastOne/Services/DataTransfer.swift`）
- JSON スキーマ: `format`（`jp.co.gimic.lastone.backup`）/ `version`（1）/ `exportedAt` /
  `categories` / `items` / `purchaseLogs` の**フラットな 3 配列 + 外部キー**。日付は ISO8601。
  `trackingMode` / `status` は raw String のまま往復させ、将来 case が増えても欠落しない。
- エクスポート: 一時ディレクトリに `LastOne-Backup-yyyy-MM-dd-HHmm.json` を書き出し、
  `LOShareSheet`（`UIActivityViewController` ラッパー）で共有する。
- インポート: `.fileImporter`（`.json`）→ 読み込み・検証 →**実行前に確認ダイアログ**
  （ファイルの中身の件数を出す）→「全置換」。3 モデルを全削除してから作り直す
  （カテゴリの cascade だけに頼らず、孤児のアイテム / 履歴も確実に消す）。完了時は復元件数をアラートで出す。
- 不正な JSON / 別アプリの JSON / 空ファイルはクラッシュせず `DataTransferError.unsupportedFormat` を投げ、
  `importFailedTitle` / `importFailedMessage` のアラートを出す。ファイル選択のキャンセルはエラー扱いにしない。

#### 8. String Catalog
- `Localizable.xcstrings` に **23 キー**を en / ja 両方で追加（74 → 97 キー）。JSON の妥当性と、
  ビルド成果物 `en.lproj` / `ja.lproj` の `Localizable.strings` に 95 件（＋ 複数形 2 件は `.stringsdict`）が
  空値なしで入ることを確認済み。
- 追加キー: `stocksEmptyHint` / `ok` / `close` / `deleteAction` / `categoryNamePlaceholder` /
  `renameCategoryHint` / `reorderCategoryHint` / `deleteCategoryTitle` / `deleteCategoryMessage` /
  `lastCategoryTitle` / `lastCategoryMessage` / `proBadge` / `exportFailedTitle` / `exportFailedMessage` /
  `importConfirmTitle` / `importConfirmMessage` / `importConfirmAction` / `importFailedTitle` /
  `importFailedMessage` / `importDoneTitle` / `importDoneMessage` / `languageSheetBody` / `openSettings`
- すべて `LOStrings.swift`（`enum L`）経由で参照する。View に UI 文言のリテラルは無い。

#### 9. デザイントークンの追記
- `LOColor`: 空状態イラスト 7 色（`basketBody` / `basketBodyBorder` / `basketRim` / `basketRimBorder` /
  `basketDot*` 3 色）、`proStatusText` / `proBadgeBackground` / `proSecondaryButtonBackground`、
  `chevron` / `listHandle` / `borderBuyRow`。
- `LOFont`: `emptyTitle` / `proBadge`（+ `proBadgeTracking`）/ `proStatus` / `proHead`。
- `LORadius.categoryRow = 18`。`LOQuietCapsuleButton` に padding パラメータ（既定値は従来どおり）を追加。

### 自己評価

| 基準 | スコア (1-5) | コメント |
|------|-------------|---------|
| 機能完全性 | 5 | Sprint 3 のチェックリスト 9 項目をすべて実装。Buy List / 空状態 / カテゴリ管理 / Settings / エクスポート・インポートを日英ともシミュレータ実機で確認し、エクスポート JSON と全置換インポート後の SQLite の中身まで突き合わせ済み。無料枠判定・Paywall は仕様どおり Sprint 4 に残している。 |
| コード品質 | 4 | カテゴリの全ミューテーションを `CategoryService` に、データ入出力を `DataTransferService` に切り出し、View にロジックを置かない構造を Sprint 2 から継続。Buy List は `ItemStateService.purchase` をそのまま呼ぶだけで、遷移ロジックの重複が無い。イラストは差し替え前提の独立 View。`LOShareSheet` だけ UIKit ラッパーが混じる。 |
| UI/UX | 4 | プロトタイプの Buy List / 空状態 / カテゴリ管理シート / Settings をほぼ再現（スクリーンショットで確認）。英語でもボタン・チップ・設定行の見切れなし。ただしカテゴリの並べ替えが「長押しドラッグ」で、明示的な編集モードのボタンが無いため、ヒント文に頼っている。 |
| エラーハンドリング | 4 | 壊れた JSON / 空ファイル / 別形式の JSON をアラートで弾いてクラッシュしない。ファイル選択キャンセルはエラー表示しない。エクスポート失敗もアラート。最後の 1 カテゴリの削除、削除済みモデルの参照、改名時の空文字をすべてガード。SwiftData の save 失敗はログ出力して継続。 |
| 既存機能との統合 | 5 | Sprint 1・2 の資産（デザイントークン / 共通部品 / `ItemStateService` / String Catalog / タブシェル）をそのまま利用。Sprint 2 のアイテムカード・追加/編集シートは無変更。クリーンインストール後の store は `categories=3 / items=0 / logs=0` で Sprint 1 の受け入れ基準を維持。唯一の意図的な挙動変更が Stocks の空カテゴリ非表示（積み残しの修正）。 |

### 技術的な判断

1. **Stocks の空カテゴリを非表示にした（Sprint 2 の判断 #2 を撤回）**: 指示とデザイン試作に合わせた。
   ただし「セクションが 1 つも無い」状態で画面が空白になるのを避けるため、`stocksEmptyHint` の案内文を
   破線の追加ボタンの上に出す。カテゴリの存在は Settings の「カテゴリの管理」と追加シートのチップで確認できる。
2. **バックアップ JSON をフラットな 3 配列 + 外部キーにした**: ネスト構造より正典のデータモデル（3 テーブル）に
   素直に対応し、万一カテゴリの無いアイテムがあっても取りこぼさないため。`format` / `version` を必ず持たせ、
   将来スキーマを変えたときに読み込み側が判定できるようにした。
3. **`ShareLink` ではなく `UIActivityViewController` ラッパー（`LOShareSheet`）を使った**: `ShareLink` は
   共有する値をビュー生成時に確定させる必要があり、エクスポート JSON を毎回のレンダリングで
   組み立てることになる。「タップされたときに書き出す」ためにこの方式にした（Swift Package の追加は不要）。
4. **インポートは「ファイル選択 → 検証 → 件数つき確認 → 全置換」の順にした**: 先に確認を出すより、
   実際に読めたファイルの中身（カテゴリ N 件 / アイテム N 件）を見せてから確定させるほうが誤操作を防げる。
   `docs/spec.md` の「実行前に確認ダイアログを出す」は満たしている。
5. **削除の全消しでカテゴリの cascade に頼らなかった**: `PurchaseLog` → `Item` → `Category` の順に明示的に
   削除する。カテゴリを持たないアイテムやアイテムを持たない履歴が残っていた場合にも確実に全置換になる。
6. **カテゴリの改名を「タップで TextField に切り替える」方式にした**: 常時 `TextField` を置くと
   長押しドラッグ（並べ替え）と競合する。行タップで対象行だけを入力欄に変え、Return / 他行タップ /
   追加・削除の直前 / シートを閉じたときに確定する。
7. **並べ替えを `List` + `onMove`（長押しドラッグ）にした**: 常時アクティブな `EditMode` にすると
   赤い削除サークルが並び、design.md §5 の「赤系の警告色を追加しない」方針と、インライン編集の
   `TextField` 操作性の両方に無理が出る。代わりにデザイン指定のハンドルアイコンを残し、
   `reorderCategoryHint`（「長押しして上下にドラッグすると並べ替えられます」）を見出し直下に添えた。
8. **空カテゴリの削除は確認なし**: 上記「カテゴリ削除の扱い」に記載。仕様の要求（所属アイテムがある場合に確認）は満たしつつ、
   操作を軽くしている。
9. **最後の 1 カテゴリはアラートで理由を説明する**: スワイプアクションを隠す実装だと「なぜ消せないか」が
   伝わらないため、押せるがアラートで止める形にした。
10. **`ProCard` は `isPro` を引数で受ける形にした**: Sprint 4 で `EntitlementStore.isPro` を差し込むだけで
    購入状態表示・CTA の切替に対応できる。現状は `isPro: false` 固定、ボタンのアクションは空クロージャ。
11. **イラストを独立 View にした**: `EmptyBasketIllustration` は `BuyListEmptyState` からサイズにも
    アニメーションにも依存されない形で切り離してあり、本番アセット導入時は `body` の差し替えだけで済む。
12. **`deleteCategoryMessage` などの複数引数の書式は位置指定子（`%1$@` / `%2$lld`）を使った**: 日英で
    語順が変わっても安全に差し替えられるようにするため。
13. **`settingsExportValue` / `settingsLanguageValue` を `L` の String プロパティとして公開した**:
    `LOSettingsRow` の `value` が整形済み `String` を取るため。View に `String(localized:)` の生キーを書かない原則を維持した。

### 既知の課題

- **Pro カードのボタンは押しても何も起きない**（Sprint 4 で Paywall シートと `EntitlementStore` に配線する）。
  右上メタも `Free` 固定、Stocks の右上メタも `N / 30` 固定。
- **無料枠の上限判定は未実装**。カテゴリを 6 個以上、アイテムを 31 個以上作れる（仕様どおり Sprint 4 の担当）。
- **カテゴリの並べ替えは長押しドラッグのみ**。明示的な編集モードのボタンは置いていない（技術的判断 #7）。
  エージェントからシミュレータへタップ入力を送れないため、**ドラッグ並べ替えの実機での動作は未検証**。
  Evaluator に手動確認をお願いしたい（下記テストシナリオ #12）。
- **同じ理由で、以下も画面表示までの確認に留まる**: 「買った」タップ後の行の消滅アニメーション、
  スワイプ削除と確認ダイアログの見た目、共有シートの表示、`fileImporter` のファイル選択 UI、
  インライン改名のフォーカス挙動。ロジック側（`purchase` / 全置換インポート / 不正 JSON の拒否）は
  一時ハーネス経由で実行し、SQLite と出力 JSON で結果を検証済み（ハーネスは撤去済み）。
- **カテゴリ管理シートへの導線は Settings のみ**。正典（`docs/spec/lastone-app.md`）は
  「Stocks / Settings から遷移」としているが、`docs/spec.md` Sprint 3 と `docs/design.md` が
  Settings 行のみを指定しているため、そちらに合わせた。
- **エクスポートの一時ファイルを削除していない**。`FileManager.temporaryDirectory` 配下なので OS が回収するが、
  厳密にはクリーンアップを入れる余地がある。
- `LOURL.privacyPolicy` はプレースホルダ URL（`https://example.com/...`）のまま。公開前に差し替えが必要（仕様の TBD）。
- Dynamic Type / セーフエリアの詰めは Sprint 4 の「表示仕上げ」で対応予定。

### 仕様に関する気づき（`spec.md` は変更していない）

- `docs/design.md` のカテゴリ管理シートのタイトルは試作では `L.category`（「カテゴリ」）だが、
  画面の役割が伝わる `manageCats`（「カテゴリの管理」）を採用した。新規キーは足していない。
- `docs/design.md` の Buy List 行には試作にだけ薄い枠線（`rgba(196,113,60,.10)`）があり、
  トークン表には載っていない。試作の見た目を優先して再現し、`LOColor.borderBuyRow` として定数化した。

### 検証方法の制約（Evaluator への注記）

Sprint 2 と同じく、この環境では `xcrun simctl` にタップ入力の API が無く `osascript`（System Events）も
補助アクセス未許可のため、**エージェント側からシミュレータの UI を操作できない**。
そのため本スプリントの確認は、`RootView` / `SettingsView` に**一時的な検証用ハーネス**
（サンプル投入・初期タブ指定・シート自動表示・エクスポート/インポートの往復実行）を仕込んだビルドで行った。
ハーネスは検証後に**完全に撤去済み**（バックアップとの差分ゼロ、`grep` で参照 0 件、クリーンインストール後の
store が `categories=3 / items=0 / logs=0` であることを確認）。

ハーネス経由で確認できた事実:

- エクスポート JSON: `format=jp.co.gimic.lastone.backup` / `version=1` / categories 3・items 4・**purchaseLogs 3**。
  カウント方式アイテムの「買った」で `stockCount 1 → 3`（閾値 1 超）、`quantity=2`（実際の増分）。二値方式は `quantity=1`。
- 全置換インポート: 全削除（categories 0 / items 0）後にインポートし、
  categories 3 / items 4 / logs 3 が関連づけ込みで復元。孤児レコード 0 件。
- 不正 JSON（`{ not json` / `{"a":1}` / 空データ）はすべて拒否され、クラッシュしない。

取得済みスクリーンショット:

- `build/shots/s3-ja-01-empty.png` — Buy List 空状態（空のかごイラスト + タイトル + 本文 +「ストックを見る」）
- `build/shots/s3-ja-02-stocks-empty.png` — Stocks（アイテム 0 件 → 空カテゴリのセクションが出ず、案内文 + 追加ボタン）
- `build/shots/s3-ja-03-settings.png` — Settings（Pro カード + 設定リスト + 脚注）
- `build/shots/s3-ja-04-buylist.png` — Buy List 3 件（カテゴリチップ / 最終購入日 /「買った」）
- `build/shots/s3-ja-05-stocks.png` — Stocks（日用品 2 / 食品 2。**ペット用品 0 件のセクションが出ない**）
- `build/shots/s3-ja-06-categories.png` — カテゴリ管理シート（ハンドル + 名前 + 件数 + 破線の追加）
- `build/shots/s3-en-01-buylist.png` / `s3-en-02-categories.png` / `s3-en-03-settings.png` — 英語版
- `build/shots/s3-final-clean.png` — ハーネス撤去後のクリーンインストール起動

### Evaluator への引き渡し事項

**このプロジェクトは iOS アプリです。Web ブラウザ / Playwright / URL での検証は行いません。**

#### 1. ビルド検証（必須）

```bash
cd /Users/koukiyoshida/development/lastone-app
./scripts/build.sh
```

- 判定: 出力に `** BUILD SUCCEEDED **` が含まれること。エラー全文は `build/last-build.log`。
- **`xcodebuild` は CoreSimulator への XPC 接続を行うため、サンドボックス内では必ず失敗します。`dangerouslyDisableSandbox: true` を付けて実行してください。**
- 外部依存が増えていないことの確認:
  ```bash
  find . -name Package.resolved -not -path "./build/*"   # 出力が空 = 依存 0 件
  ```

#### 2. シミュレータへのインストールと起動

```bash
BID=jp.co.gimic.lastone
APP=build/dd/Build/Products/Debug-iphonesimulator/LastOne.app
xcrun simctl boot "iPhone 17" || true
open -a Simulator
xcrun simctl uninstall "iPhone 17" $BID          # クリーンな初回起動を再現
xcrun simctl install "iPhone 17" "$APP"
xcrun simctl launch "iPhone 17" $BID -AppleLanguages "(ja)" -AppleLocale "ja_JP"   # 日本語
# xcrun simctl launch "iPhone 17" $BID -AppleLanguages "(en)" -AppleLocale "en_US" # 英語
xcrun simctl io "iPhone 17" screenshot build/shots/check.png
```

#### 3. テストシナリオ（Sprint 3 の受け入れ基準に対応）

| # | 操作 | 期待結果 |
|---|------|---------|
| 1 | クリーンインストール → 起動（日本語） | Buy List に**空状態パネル**（角丸の生成りパネル + 空のかごイラスト +「買うものはありません」+ 本文 +「ストックを見る」）。イラストがゆっくり上下する。右上メタ「0件」。 |
| 2 | 「ストックを見る」をタップ | **Stocks タブに切り替わる**。アイテム 0 件なので、カテゴリのセクションは出ず、案内文と破線の「＋ アイテムを追加」だけが出る。 |
| 3 | 「＋ アイテムを追加」→ 名前「シャンプー」/ 日用品 / 二値 →「追加する」 | 日用品セクションが**現れて**「シャンプー」カードが在庫ありで並ぶ。食品・ペット用品のセクションは出ない。 |
| 4 | シャンプーの「買うものリストに追加」 | チップが「のこり1つ」に。Buy List タブに移ると 1 行カードが現れ、右上メタが「1件」。 |
| 5 | 「＋ アイテムを追加」→「トイレットペーパー」/ 日用品 / **カウント** →「追加する」→「開封 −1」を 1 回 | `stockCount` が 2 → 1（閾値 1 以下）で自動的に「のこり1つ」。Buy List に現れ、右上メタが「2件」。 |
| 6 | Buy List で「買った」を 2 件とも押す | 行が消えて**空状態パネル**に戻る。右上メタが「0件」。 |
| 7 | Stocks に戻る | 両方「在庫あり」。最終購入日が**今日**（ja「9月2日 に購入」/ en「Bought Sep 2」）。トイレットペーパーの `stockCount` が **3**（閾値 1 を必ず上回る）。 |
| 8 | Settings →「カテゴリの管理」 | シートが開き、3 行（日用品 2件 / 食品 0件 / ペット用品 0件）+ 破線の「＋ カテゴリを追加」。 |
| 9 | 「＋ カテゴリを追加」→ 名前を「掃除用品」に変えて Return | 末尾に追加され、Settings の行が「4 カテゴリ」になる。**アイテム追加シートのカテゴリチップにも即座に現れる**。 |
| 10 | ペット用品を左スワイプ →「削除」 | 所属アイテム 0 件なので**確認なしで**削除される。 |
| 11 | 日用品（アイテムあり）を左スワイプ →「削除」 | **確認ダイアログ**が出て「所属する N 件のアイテム・購入履歴をすべて削除します」と表示される。「削除する」で所属アイテムごと消え、Stocks から日用品セクションが消える。「キャンセル」なら何も消えない。 |
| 12 | 行を**長押ししてドラッグ**し、順序を入れ替える | 並び替わり、Stocks のセクション順にも反映される。アプリを再起動しても順序が保持される。 |
| 13 | カテゴリを 1 件だけにして、その 1 件を左スワイプ →「削除」 | 「カテゴリは 1 つ以上必要です」のアラートが出て、**削除されない**。 |
| 14 | 行をタップ → 名前を編集 → Return | インラインで改名され、Stocks のセクション見出しにも反映される。空文字のまま確定すると元の名前のまま。 |
| 15 | Settings →「データのエクスポート」 | 共有シートが開き、`LastOne-Backup-YYYY-MM-DD-HHmm.json` を保存 / 共有できる。 |
| 16 | 保存した JSON を確認 | `format` / `version` / `exportedAt` と、`categories` / `items` / `purchaseLogs` の 3 配列。**「買った」2 回分の PurchaseLog が `purchasedAt` / `quantity` つきで含まれる**。 |
| 17 | アイテムを 1 つ削除 → Settings →「データのインポート」→ さっきの JSON を選択 | **確認ダイアログ**（「カテゴリ N 件 / アイテム N 件に置き換えます」）→「置き換える」で、削除したアイテムを含めエクスポート時点に復元される。完了アラートに復元件数が出る。 |
| 18 | インポートで**別の JSON**（例: 適当なテキストを .json にしたもの）を選択 | 「読み込めませんでした」のアラートが出て、**クラッシュせず既存データも壊れない**。 |
| 19 | インポートのファイル選択を**キャンセル** | 何も起きない（エラーも出ない）。 |
| 20 | Settings →「言語について」 | シートが開き、端末の設定に追従する旨の説明 +「iOS の設定を開く」。ボタンで設定アプリが開く。 |
| 21 | Settings →「プライバシーポリシー」 | ブラウザで `https://example.com/lastone/privacy`（プレースホルダ）が開く。 |
| 22 | Settings の Pro カード | ゴールドのカードに PRO バッジ・「未購入」・見出し・説明・「Pro を見る」/「リストア」が並ぶ。**押しても何も起きない（Sprint 4 の担当）**。 |
| 23 | **英語**で起動して 1〜22 を巡回 | `Nothing to buy` / `Go to Stocks` / `Bought` / `Manage categories` / `Export data` / `Import data` / `About language` / `Privacy Policy` / `Free plan` / `See Pro` / `Restore` / `+ Add category` / `Delete this category?` などが表示され、見切れ・折返し崩れが無い。件数は `1 item` / `3 items` / `3 categories`。 |

#### 4. データ層の直接確認

```bash
BID=jp.co.gimic.lastone
CONT=$(xcrun simctl get_app_container "iPhone 17" $BID data)
DB="$CONT/Library/Application Support/default.store"
sqlite3 "$DB" "SELECT 'categories',COUNT(*) FROM ZCATEGORY UNION ALL SELECT 'items',COUNT(*) FROM ZITEM UNION ALL SELECT 'logs',COUNT(*) FROM ZPURCHASELOG;"
# 「買った」の副作用
sqlite3 "$DB" "SELECT i.ZNAME, i.ZSTATUSRAW, IFNULL(i.ZSTOCKCOUNT,'-'), i.ZTHRESHOLD, i.ZLASTPURCHASEDAT FROM ZITEM i;"
# 購入履歴（quantity は二値=1 / カウント=実際の増分）
sqlite3 "$DB" "SELECT i.ZNAME, l.ZQUANTITY, l.ZPURCHASEDAT FROM ZPURCHASELOG l LEFT JOIN ZITEM i ON l.ZITEM=i.Z_PK ORDER BY l.ZPURCHASEDAT;"
# カテゴリの並び順
sqlite3 "$DB" "SELECT ZSORTORDER, ZNAME FROM ZCATEGORY ORDER BY ZSORTORDER;"
```

#### 5. コンソールログでのアナリティクス確認

```bash
xcrun simctl spawn "iPhone 17" log stream --predicate 'processImagePath CONTAINS "LastOne"' --style compact
# 「買った」で [analytics] item_purchased、「＋ カテゴリを追加」で category_created が出力される
#（PostHog SDK は未導入・print スタブなので Xcode のコンソールでも確認できる）。
```

#### 6. 本スプリントの範囲外（不合格にしないでください）

以下は仕様上 Sprint 4 の実装対象です。

- 無料枠の上限判定（カテゴリ 5 / アイテム 30）。**6 個目のカテゴリも 31 個目のアイテムも登録できます（仕様どおり）。**
- Paywall シートの表示と、Pro カードの「Pro を見る」/「リストア」の実処理（`EntitlementStore` の seam）
- Stocks 右上メタの「N / ∞」、Settings 右上メタの「Pro」、追加シートの「Pro：登録数は無制限です」
- Dynamic Type / セーフエリアの詰めなどの表示仕上げ
- 購入履歴の閲覧 UI（MVP では作らない。エクスポート JSON でのみ確認可能）
- ユニットテスト / UI テストターゲット（`project.pbxproj` の編集が必要なため、仕様で新規作成を禁止されている）

---

## Sprint 4: 無料枠と Paywall / 課金の seam / 仕上げ
**ステータス:** 実装完了 - ビルド成功・シミュレータ目視検証済み（evaluator エージェントによる評価は未実施）
**実装日:** 2026-09-02
**ビルド結果:** `./scripts/build.sh` → `** BUILD SUCCEEDED **`（ソース由来の warning 0 件 / `project.pbxproj` 無変更 / `Package.resolved` 未生成 / Swift Package 依存 0 件）

### 前スプリントからの積み残しへの対応

- `docs/feedback/` は存在しないため、Evaluator フィードバックへの対応はなし。
- Sprint 3 の既知の課題「Pro カードのボタンは押しても何も起きない」「右上メタが `Free` / `N / 30` 固定」
  「無料枠の上限判定が未実装」を本スプリントで解消した。

### 実装内容

#### 1. EntitlementStore の seam（`LastOne/Services/EntitlementStore.swift`・新規）
- `protocol EntitlementStore: AnyObject, Observable`（`isPro` / `purchase()` / `restore()`）。
  **View は必ずこのプロトコル越しに参照し、SDK に直接触れない。**
- `LocalEntitlementStore`: `@Observable` + `UserDefaults`（キー `jp.co.gimic.lastone.entitlement.pro`）のスタブ。
  `purchase()` は必ず成功、`restore()` は「この Apple アカウントが購入済み」とみなして Pro を有効にする。
  ストア往復を模した 260ms の待ち時間を入れ、CTA のローディング表示を実機と同じ経路で確認できるようにした。
- `EntitlementOutcome`（`purchased` / `restored` / `cancelled` / `noPurchaseFound` / `failed`）を定義し、
  実 SDK でも同じ粒度で扱えるようにした。UI は 5 分岐すべてを実装済み（スタブでは `cancelled` /
  `noPurchaseFound` / `failed` に到達しない）。
- `LOEntitlement` に entitlement 識別子（`pro`）/ プロダクト ID / UserDefaults キーを集約。
- **RevenueCat（StoreKit 2）への差し替え手順**をプロトコル定義の doc comment に記載
  （`RevenueCatEntitlementStore` の実装例つき。差し替えは `LastOneApp` のインスタンス 1 行のみで、View 側は無変更）。
- `EnvironmentValues.entitlements` で注入（`AnalyticsClient` と同じ方式）。

#### 2. 無料枠の上限判定（`LastOne/Support/LOLimits.swift`）
- `canAddItem(currentCount:isPro:)` / `canAddCategory(currentCount:isPro:)` を追加。上限値は
  Sprint 1 から `LOLimits` の 1 箇所（カテゴリ 5 / アイテム 30）にあり、そこを変えるだけで全画面に効く。
- 判定箇所:
  - `StocksView.requestAddItem()` … 「＋ アイテムを追加」タップ時。上限なら**追加シートを開かず** Paywall。
  - `ItemEditorSheet.submit()` … 「追加する」タップ時の**実行時点**でも再判定（親に通知してシートを閉じ、Paywall へ）。
  - `CategoryManagerSheet.addCategory()` … 「＋ カテゴリを追加」タップ時。上限なら**作らずに** Paywall。
- Pro（`isPro == true`）ではすべて無制限。

#### 3. Paywall シート（`LastOne/Features/Paywall/PaywallSheet.swift`・新規）
- 構成は `docs/design.md` §2「Paywall シート」とプロトタイプの実測値どおり:
  ドラッグハンドル（44×5 `#E9DCC6`）→ 金色の円（74pt・`radial-gradient(32% 28%, #FBE3BC→#EFC98F)`・
  Pro ボタンシャドウ）に星アイコン →「LastOne Pro」（22/bold `#6E4F26`）→ 理由テキスト
  （13/regular `#9A7A4C`・最大幅 280・中央揃え）→ 特典 3 行（白 70% / 角丸 16 / padding 12・14 +
  `#C99A56` のチェック）→ 価格 CTA（`#C99A56` / 角丸 20 / padding 17）→「購入をリストア」。
- 背景は `#FDF6EA` → `#FAF1E3` のグラデ、シート上端の角丸 32（`LORadius.paywallSheet`）。
- **高さは内容の実寸に追従**（`PreferenceKey` で測って `.presentationDetents([.height(_)])` に渡す）。
  言語・文言の長さで理由テキストが 1 行 / 2 行と変わってもシートに余白や見切れが出ない。
  収まらない場合は SwiftUI 側でクランプされ、内容がスクロールする。
- **「購入をリストア」は App Store の審査要件のため常設**（実行中以外は必ず押せる）。
- 購入 / リストア中は CTA を `ProgressView` に差し替え、二度押しを防ぐ。

#### 4. 表示理由の出し分け（`L.paywallReason(_:)`）
| 開いた場所 | `PaywallReason` | 文言 |
|---|---|---|
| Stocks の「＋ アイテムを追加」/ 追加シートの「追加する」 | `.itemLimit` | `limitItems`（「無料枠のアイテム上限（30個）に達しました。…」） |
| カテゴリ管理シートの「＋ カテゴリを追加」 | `.categoryLimit` | `limitCats`（「無料枠のカテゴリ上限（5個）に達しました。」） |
| Settings の「Pro を見る」 | `.settings` | `proReason`（「無料枠はカテゴリ5個・アイテム30個まで。…」） |

- 3 種とも上限値は `LOLimits` から `String(format:)` で差し込む（文言に数値を直書きしない）。
  `proReason` は en / ja とも位置指定子（`%1$lld` / `%2$lld`）の 2 引数に変更した。

#### 5. Pro 状態の反映
- **Stocks 右上メタ**: `LOLimits.stocksMeta(itemCount:isPro:)` →無料 `30 / 30` / Pro `30 / ∞`。
- **Settings 右上メタ**: `L.settingsMeta(isPro:)` → `Free` / `Pro`。
- **Pro カード**（`ProCard`）: 購入状態ラベル（`proStatus`）に加え、Pro のときは「Pro を見る」CTA を
  タップできない購入済み表示（`checkmark.seal.fill` +「Pro 利用中 / Pro active」）に差し替える。
  「リストア」は購入済みでも押せる（審査要件）。リストア中は `ProgressView`。
- **アイテム追加シートの残り枠ラベル**: `L.quota(isPro:remaining:)` →
  無料「あと N 個まで無料で登録できます」/ Pro「Pro：登録数は無制限です」。

#### 6. 購入 / リストアの結果表示（`LastOne/Features/Paywall/EntitlementAlert.swift`・新規）
- `EntitlementAlert`（`restored` / `noPurchaseFound` / `purchaseFailed`）と、Paywall・Settings で
  共有する `.loEntitlementAlert(_:)` モディファイア。
- Paywall での購入 / リストア成功時はシートを閉じる（Pro 反映が画面で見えるため）。
  Settings のリストア成功時は「Pro を復元しました」のアラートで明示する。

#### 7. アナリティクス発火
- `paywall_shown`（`reason` を property に付与）… `PaywallSheet.onAppear`。
  **実際に表示された瞬間**に 1 回だけ発火するため、トリガー箇所が増えても計測が漏れない。
- `pro_purchased` … 購入成功時（`PaywallSheet.purchase()`）。
- 既存の `item_marked_low` / `item_purchased` / `item_opened` / `item_created` / `category_created` は
  Sprint 2・3 で `ItemStateService` / `CategoryService` に仕込み済み。**7 イベントすべてが `AnalyticsClient`
  プロトコル越し**で、View から SDK に触れる箇所は無い。

#### 8. i18n
- `Localizable.xcstrings` に **12 キー**を en / ja 両方で追加（97 → 109 キー）。JSON の妥当性、
  および `en.lproj` / `ja.lproj` の `Localizable.strings` に 107 件（＋複数形 2 件は `.stringsdict`）が
  空値なしで入ることを確認済み。未翻訳（`stale` / 空）のキーは 0。
- 追加キー: `paywallTitle` / `proActive` / `purchaseFailedTitle` / `purchaseFailedMessage` /
  `restoreDoneTitle` / `restoreDoneMessage` / `restoreNoneTitle` / `restoreNoneMessage` /
  `a11yBought` / `a11yMarkLow` / `a11yUnmarkLow` / `a11yOpenOne`
- 変更キー: `proReason`（数値の直書き → 位置指定子の 2 引数）。
- すべて `LOStrings.swift`（`enum L`）経由。View に UI 文言のリテラルは無い。

#### 9. アクセシビリティ（VoiceOver）
- 対象を含む読み上げラベルを主要操作ボタンに付与:
  - Buy List「買った」→「醤油 を買った / Mark 醤油 as bought」
  - Stocks の二値トグル →「醤油 を買うものリストに追加 / から除外」
  - Stocks「開封 −1」→「トイレットペーパー を 1 つ開封する / Open one of …」（記号だけでは伝わらないため）
  - 空状態の「ストックを見る」/ Paywall の価格 CTA・リストア / Pro カードの CTA
- Paywall の星アイコン・特典行のチェックアイコンは装飾なので `accessibilityHidden`。
  特典 1 行は `accessibilityElement(children: .combine)` で 1 要素にまとめた。
- Paywall / Pro カードの各操作に `accessibilityIdentifier` を付与
  （`paywall.purchase` / `paywall.restore` / `paywall.reason` / `settings.seePro` / `settings.proActive` /
  `settings.restore` / `sheet.quota`）。

#### 10. 表示仕上げ
- 英語 UI を全画面巡回し、「Remove from Buy List」「Add to Buy List」「Buy once · $3.99」
  「Free covers 5 categories and 30 items. Pro lifts both.」「Purchased — thank you」
  「One-time purchase, no upsells」などで折返し・`minimumScaleFactor` の崩れが無いことを
  スクリーンショットで確認した。
- ルートに `.dynamicTypeSize(...DynamicTypeSize.accessibility1)` を追加し、
  SwiftUI 標準コンポーネント（`Stepper` / スワイプアクションのラベル / `ProgressView` / システムのアラート）
  が極端に拡大されてもレイアウトが破綻しないようにした。
- セーフエリア（ホームインジケータ）とタブバーの重なり、ヘッダーグラデーションの継ぎ目は
  Sprint 1 の実装のままで問題が無いことを再確認した。

### 自己評価

| 基準 | スコア (1-5) | コメント |
|------|-------------|---------|
| 機能完全性 | 5 | Sprint 4 のチェックリスト 8 項目をすべて実装。上限判定（アイテム / カテゴリ）・Paywall の 3 種の理由・購入 / リストア・Pro 反映（3 箇所）・`paywall_shown` / `pro_purchased` を、シミュレータ実機で SQLite とコンソールログまで突き合わせて確認済み（下記「検証で確認できた事実」）。 |
| コード品質 | 5 | 課金は `EntitlementStore` プロトコルの背後に完全に隠れ、View は `\.entitlements` を読むだけ。上限値は `LOLimits`、文言は `L`、理由の出し分けは `PaywallReason` の 1 箇所に集約。実 SDK 差し替えは `LastOneApp` の 1 行で済み、その手順もコード内に残した。 |
| UI/UX | 4 | Paywall はプロトタイプの実測値を再現し、シート高さを内容の実寸に追従させて日英どちらでも余白 / 見切れが出ないようにした。購入 / リストア中のローディングもある。ただしオーバーレイの濃度（`rgba(65,56,48,.32)`）は SwiftUI 標準シートの dimming に委ねており、design.md の指定値そのままではない。 |
| エラーハンドリング | 4 | 購入 / リストアの 5 つの結果をすべて UI 分岐済み（キャンセルは無表示、失敗と「購入なし」はアラート）。二度押しは `isBusy` でガード。上限判定は「シートを開く前」と「追加の実行時点」の二重。ただしスタブのため失敗系の実挙動は未確認（実 SDK 導入時に要確認）。 |
| 既存機能との統合 | 5 | Sprint 1〜3 の資産（デザイントークン / 共通部品 / `ItemStateService` / `CategoryService` / `DataTransferService` / String Catalog / タブシェル）をそのまま利用。既存の状態遷移・エクスポート / インポートには一切手を入れていない。クリーンインストール後の store は `categories=3 / items=0 / logs=0`、entitlement 未設定（＝ Free）で Sprint 1 の受け入れ基準を維持。 |

### 技術的な判断

1. **`EntitlementStore` を `Observable` 継承のプロトコルにした**: `any EntitlementStore` 越しでも
   `@Observable` の変更通知が SwiftUI に届く（プロパティの getter が `ObservationRegistrar` に登録するため、
   静的な型に依存しない）。実機で「購入 → 再起動なしで Settings のメタが `Free` → `Pro` に変わる」ことを
   確認済み。`ObservableObject` / `@EnvironmentObject` を使うと存在型との相性が悪くなるため採用しなかった。
2. **`isPro` は同期プロパティ、`purchase()` / `restore()` は `async`**: 実 SDK（StoreKit 2 / RevenueCat）が
   async なので seam も async に揃えた。プロトコル自体は非分離のまま、実装側のメソッドだけ `@MainActor` に
   することで、`EnvironmentKey.defaultValue` からの生成（非分離コンテキスト）と、`isPro` のメインスレッド更新を
   両立させている。
3. **スタブの `restore()` は必ず Pro を復元する**: `UserDefaults` はアプリ削除で消えるため、
   「アンインストール → 再インストール → リストアで Pro に戻る」という受け入れ基準を満たすには
   「App Store 側が購入を持っている」と仮定するしかない。実 SDK では
   `Purchases.restorePurchases()` の結果を見て entitlement が無ければ `.noPurchaseFound` を返す想定で、
   UI 側（「購入が見つかりませんでした」アラート）は先に実装してある。
4. **上限判定を「シートを開く前」と「追加の実行時点」の二重にした**: プロトタイプ
   （`screen/LastOne App.dc.html` の `openAdd` と `submitAdd`）と同じ。入力を終えてから弾かれる体験を避けつつ、
   `docs/spec.md` の「追加操作の実行時点で判定する」も満たす。実行時点で弾かれた場合は
   シートを閉じてから親が Paywall を出す（シートの多重表示と、削除処理との競合を避けるため）。
5. **カテゴリ上限の Paywall はカテゴリ管理シートの上に重ねた**: どのカテゴリを何個持っているかが
   背面に見えている方が納得感があるため。iOS 16.4+ のシート多段表示で動作を確認済み。
6. **Paywall の高さを内容の実寸に合わせた**: `.medium` だと理由テキストと特典 3 行が切れ、`.large` だと
   デザイン（内容にフィットするボトムシート）から外れる。`PreferenceKey` で内容の高さを測って
   `.presentationDetents([.height(_)])` に渡す方式にし、日英 / 理由 3 種で余白・見切れが出ないことを確認した。
7. **`paywall_shown` を `PaywallSheet.onAppear` で発火した**: トリガー側（Stocks / カテゴリ管理 / Settings）に
   分散させると、シートが実際には出なかったケースまで計測してしまう。表示のタイミングで 1 回だけ発火する。
8. **Pro のときの CTA をボタンではなく静的な表示にした**: 押しても何も起きないボタンを残すより、
   購入済みであることを示す非対話の表示に差し替えるほうが誤解が無い。`docs/spec.md` の
   「Pro のときは『Pro を見る』CTA を購入済み表示に切り替える」に対応。
9. **`proReason` の数値を位置指定子にした**: design.md §3 の原文は en / ja とも「5 categories」「カテゴリ5個」と
   数値を直書きしているが、「上限値は 1 箇所の定数にまとめる」という Sprint 4 の要求と両立させるため
   `%1$lld` / `%2$lld` にした（Sprint 1 で `limitCats` に対して行った判断と同じ）。表示結果は同じ。
10. **Dynamic Type の扱い**: `LOFont` は design.md の実寸（27 / 22 / 16 / 13.5 …）に合わせて
    `Font.system(size:)` で組んでおり、これは SwiftUI では**固定サイズ**で Dynamic Type に追従しない。
    最終スプリントで全画面のタイポグラフィを可変にするのは回帰リスクが高いため、今回は
    (a) レイアウトが崩れないこと（＝受け入れ基準）を実機の `content_size` 変更で確認し、
    (b) 標準コンポーネント側の暴走を防ぐクランプ（`...accessibility1`）を入れる、に留めた。
    追従させる場合の移行先は `LOFont` に `@ScaledMetric` / `UIFontMetrics` を通す一点（下記「既知の課題」）。
11. **`EntitlementAlert` を Paywall / Settings で共有した**: 同じ結果に同じ文言を出すため、
    アラートの組み立てを `.loEntitlementAlert(_:)` の 1 箇所にまとめた。

### 既知の課題

- **`Font.system(size:)` は Dynamic Type に追従しない**（本文サイズを上げても文字が大きくならない）。
  レイアウトは崩れないが、視力に配慮した拡大には対応できていない。対応するなら `LOFont` の各トークンを
  `@ScaledMetric` / `UIFontMetrics.default.scaledValue(for:)` 経由にする（トークンが 1 ファイルに
  集約されているので変更範囲は `LOFont.swift` + 各 View の `font` 指定に限定できる）。
- **Paywall のオーバーレイ濃度が design.md の `rgba(65,56,48,0.32)` ちょうどではない**。
  SwiftUI 標準シートの dimming をそのまま使っている（`LOColor.overlayPaywall` は定義済みだが未使用）。
  厳密に合わせるにはフルスクリーンカバー + 自前のオーバーレイに置き換える必要があり、
  シートのドラッグ / detent / アクセシビリティを自前実装することになるため見送った。
- **スタブの `restore()` は「購入が見つからない」分岐に到達しない**（必ず Pro になる）。
  実 SDK 導入時に `.noPurchaseFound` の実挙動を確認すること。UI とアラートは実装済み。
- **価格は文言（`priceCta` / `proSub`）に直書きの仮値**（¥500 / $3.99）。実 SDK 導入後は
  StoreKit / RevenueCat から取得したローカライズ済み価格を差し込む必要がある（App Store 審査でも
  実価格の表示が求められる）。無料枠の数値（5 / 30）も仕様上 TBD。
- **`LOURL.privacyPolicy` / `termsOfUse` はプレースホルダ URL**（`https://example.com/...`）。
  課金アプリの審査要件なので、公開前に実 URL への差し替えが必須。
- **Pro を解除する UI が無い**（検証時は `UserDefaults` のキーを消すかアプリを削除する）。
  製品としては正しい挙動だが、Evaluator の検証手順に手間が増えるため下記に手順を記載した。
- カテゴリの並べ替え（長押しドラッグ）は Sprint 3 から引き続き**エージェント側では未検証**。
- エクスポートの一時ファイルを削除していない（Sprint 3 からの継続。OS が回収する）。

### 仕様に関する気づき（`spec.md` は変更していない）

- `docs/design.md` §3 の `proReason` は en / ja とも「5 categories」「カテゴリ5個」と数値を直書きしているが、
  Sprint 4 の「上限値は 1 箇所の定数にまとめる」と矛盾するため書式指定子に置き換えた（表示結果は同じ）。
- `docs/spec/lastone-app.md` は「Paywall は RevenueCat Paywalls で構築」としているが、
  `docs/spec.md`（実装計画）は「実 SDK を導入せず自前で作る」としている。後者に従い、
  RevenueCat Paywalls ではなく SwiftUI で design.md どおりに実装した。実 SDK 導入時に
  RevenueCat Paywalls へ寄せるか自前 UI を維持するかは、その時点で判断する余地を残してある。
- design.md の Paywall にはシートを閉じる明示的なボタンが無い。SwiftUI のシート標準（下スワイプ / 背景タップ）と
  ドラッグハンドルの表示で代替している（VoiceOver のエスケープジェスチャでも閉じられる）。

### 検証方法の制約（Evaluator への注記）

Sprint 2・3 と同じく、この環境では `xcrun simctl` にタップ入力の API が無く `osascript`（System Events）も
補助アクセス未許可のため、**エージェント側からシミュレータの UI を操作できない**。
そのため本スプリントの確認は、`RootView` / `StocksView` / `SettingsView` / `CategoryManagerSheet` /
`PaywallSheet` に**一時的な検証用ハーネス**（起動引数 `-LOHarness` でサンプル投入・初期タブ指定・
シート自動表示・「＋ 追加」の自動実行・購入 / リストアの自動実行を切り替える）を仕込んだビルドで行った。
ハーネスは検証後に**完全に撤去済み**（バックアップとの `diff` が 4 ファイルとも差分ゼロ、
`grep` で参照 0 件、撤去後のビルドが warning 0 で成功、クリーンインストール後の store が
`categories=3 / items=0 / logs=0`・entitlement 未設定であることを確認）。

#### 検証で確認できた事実

| 確認項目 | 結果 |
|---|---|
| アイテム 30 件の無料状態で「＋ アイテムを追加」 | Paywall が `limitItems`（「無料枠のアイテム上限（30個）に達しました。…」）で開き、コンソールに `[analytics] paywall_shown reason=item_limit`。**SQLite の `ZITEM` は 30 件のまま**（追加シートも開かない） |
| カテゴリ 5 件の無料状態で「＋ カテゴリを追加」 | Paywall が `limitCats`（「無料枠のカテゴリ上限（5個）に達しました。」）で開き、`paywall_shown reason=category_limit`。**`ZCATEGORY` は 5 件のまま**。Paywall はカテゴリ管理シートの上に重なって表示される |
| Settings の「Pro を見る」 | Paywall が `proReason`（en「Free covers 5 categories and 30 items. Pro lifts both.」）で開く |
| Paywall の価格 CTA | `[analytics] pro_purchased` が発火 → シートが閉じ、**再起動なしで** Stocks の右上メタが `30 / 30` → `30 / ∞` に変わる |
| 購入状態の永続化 | `Library/Preferences/jp.co.gimic.lastone.plist` に `"jp.co.gimic.lastone.entitlement.pro" => 1`。再起動後も Pro のまま |
| Pro での Settings | 右上メタ `Pro`、Pro カードが「購入済み・ありがとうございます」＋ CTA が「Pro 利用中 / Pro active」に差し替わり、「リストア」は押せる |
| Pro でのアイテム追加シート | 残り枠ラベルが「Pro：登録数は無制限です」。アイテム 30 件でも追加シートが開く（上限で弾かれない） |
| **アンインストール → 再インストール → リストア** | 「Pro を復元しました / カテゴリ・アイテムの登録数がふたたび無制限になりました。」のアラートが出て Pro に戻る |
| 英語 UI | Paywall・Pro カード・設定リスト・Stocks カードで見切れ・折返し崩れなし |
| Dynamic Type | `simctl ui content_size` を `extra-large` / `accessibility-extra-extra-extra-large` にしてもレイアウト崩れなし（＝ 固定サイズのため変化しない。上記「既知の課題」参照） |

取得済みスクリーンショット（`build/shots/`）:

- `s4-ja-01-paywall-item.png` — 日本語 / アイテム上限の Paywall（Stocks メタ `30 / 30`）
- `s4-ja-02-paywall-cats.png` — 日本語 / カテゴリ上限の Paywall（カテゴリ管理シートの上に重畳）
- `s4-en-03-paywall-settings.png` — 英語 / Settings からの Paywall（`proReason`）
- `s4-ja-05-settings-pro.png` — 購入直後の Settings（メタ `Pro` / 「Pro 利用中」）
- `s4-ja-06-pro-quota.png` — Pro での Stocks メタ `30 / ∞` と追加シートの「Pro：登録数は無制限です」
- `s4-en-08-settings-pro.png` — 英語 / Pro の Settings（`Pro active` / `Purchased — thank you`）
- `s4-ja-09-after-purchase.png` — 購入後に Paywall が閉じてメタが `30 / ∞` になった Stocks
- `s4-ja-13-guard-item.png` / `s4-ja-14-guard-cat.png` — 上限ガードの発動
- `s4-ja-15-restore-alert.png` — クリーンインストール後のリストア成功アラート
- `s4-final-clean.png` — ハーネス撤去後のクリーンインストール起動（Buy List 空状態）

### Evaluator への引き渡し事項

**このプロジェクトは iOS アプリです。Web ブラウザ / Playwright / URL での検証は行いません。**

#### 1. ビルド検証（必須）

```bash
cd /Users/koukiyoshida/development/lastone-app
./scripts/build.sh
```

- 判定: 出力に `** BUILD SUCCEEDED **` が含まれること。エラー全文は `build/last-build.log`。
- **`xcodebuild` / `xcrun simctl` は CoreSimulator への XPC 接続を行うため、サンドボックス内では必ず失敗します。
  `dangerouslyDisableSandbox: true` を付けて実行してください。**
- 外部依存が増えていないことの確認:
  ```bash
  find . -name Package.resolved -not -path "./build/*"   # 出力が空 = 依存 0 件
  ```

#### 2. シミュレータへのインストールと起動

```bash
BID=jp.co.gimic.lastone
APP=build/dd/Build/Products/Debug-iphonesimulator/LastOne.app
xcrun simctl boot "iPhone 17" || true
open -a Simulator
xcrun simctl uninstall booted $BID          # クリーンな初回起動を再現（Pro も解除される）
xcrun simctl install booted "$APP"
xcrun simctl launch booted $BID -AppleLanguages "(ja)" -AppleLocale "ja_JP"   # 日本語
# xcrun simctl launch booted $BID -AppleLanguages "(en)" -AppleLocale "en_US" # 英語
xcrun simctl io booted screenshot build/shots/check.png
```

**Pro 状態のリセット**（アプリを消さずに Free に戻したいとき）:

```bash
CONT=$(xcrun simctl get_app_container booted $BID data)
plutil -remove "jp.co.gimic.lastone.entitlement.pro" "$CONT/Library/Preferences/$BID.plist"
xcrun simctl terminate booted $BID     # 次回起動から Free
```

#### 3. テストシナリオ（Sprint 4 の受け入れ基準に対応）

| # | 操作 | 期待結果 |
|---|------|---------|
| 1 | クリーンインストール → 起動 → Settings | 右上メタが **`Free`**。Pro カードが「PRO / 未購入 / カテゴリもアイテムも、無制限に。/ 買い切り ¥500。… / Pro を見る / リストア」。 |
| 2 | Settings →「Pro を見る」 | **Paywall** が開く。金色の円に星（74pt）→「LastOne Pro」→ **`proReason`**（「無料枠はカテゴリ5個・アイテム30個まで。…」）→ 特典 3 行 → 「¥500 で買い切り」→「購入をリストア」。 |
| 3 | Paywall を下スワイプで閉じる | Settings に戻る。Pro にはならない。 |
| 4 | Settings →「カテゴリの管理」→ カテゴリを 5 個になるまで追加 | 5 個目までは普通に追加できる（Settings の行が「5 カテゴリ」）。 |
| 5 | 6 個目の「＋ カテゴリを追加」 | **Paywall が `limitCats`**（「無料枠のカテゴリ上限（5個）に達しました。」）で開き、**カテゴリは追加されていない**（閉じると 5 個のまま）。 |
| 6 | Stocks でアイテムを 30 個になるまで追加 | 追加シートの残り枠ラベルが「あと N 個まで無料で登録できます」と減っていき、最後は「あと 0 個…」。右上メタが `30 / 30`。 |
| 7 | 31 個目の「＋ アイテムを追加」 | **Paywall が `limitItems`**（「無料枠のアイテム上限（30個）に達しました。Pro で上限がなくなります。」）で開き、**追加シートは開かず、アイテムも増えない**。 |
| 8 | その Paywall で「¥500 で買い切り」をタップ | 一瞬ローディング → **シートが閉じる**。Stocks の右上メタが **`30 / ∞`** に変わる。 |
| 9 | 直後にもう一度「＋ アイテムを追加」 | **追加シートが開き**、残り枠ラベルが「**Pro：登録数は無制限です**」。31 個目を追加できる。 |
| 10 | Settings を開く | 右上メタが **`Pro`**。Pro カードが「購入済み・ありがとうございます」、CTA が「**Pro 利用中**」（押せない）、「リストア」は押せる。 |
| 11 | アプリを終了（`simctl terminate`）→ 再起動 | **Pro のまま**（メタ `Pro` / `N / ∞`）。 |
| 12 | アンインストール → 再インストール → 起動 → Settings | `Free` に戻っている。 |
| 13 | 「リストア」をタップ | 一瞬ローディング → 「**Pro を復元しました**」のアラート → OK で閉じると **Pro になっている**（スタブ実装の範囲で購入履歴を復元する挙動）。 |
| 14 | Pro の状態でカテゴリを 6 個目・アイテムを 31 個目に追加 | **Paywall は出ず、そのまま追加できる**。 |
| 15 | **英語**で 1〜14 を巡回 | `Free plan` / `See Pro` / `Restore` / `Restore purchase` / `Buy once · $3.99` / `Pro active` / `Purchased — thank you` / `You hit the free limit of 30 items. Pro removes it.` / `You hit the free limit of 5 categories.` / `Free covers 5 categories and 30 items. Pro lifts both.` / `0 more items on the free plan` / `Pro: unlimited items` が表示され、見切れ・折返し崩れが無い。 |
| 16 | VoiceOver を ON にして Buy List / Stocks を操作 | 「買った」が「醤油 を買った」、二値トグルが「醤油 を買うものリストに追加」、「開封 −1」が「トイレットペーパー を 1 つ開封する」と読み上げられる。Paywall の星アイコンは読み上げられない。 |
| 17 | Sprint 1〜3 の機能（コアループ / カテゴリ管理 / エクスポート / インポート）を一通り | 回帰していない。 |

#### 4. データ層 / 設定の直接確認

```bash
BID=jp.co.gimic.lastone
CONT=$(xcrun simctl get_app_container booted $BID data)
DB="$CONT/Library/Application Support/default.store"
# 上限で弾かれたときに増えていないこと
sqlite3 "$DB" "SELECT 'categories',COUNT(*) FROM ZCATEGORY UNION ALL SELECT 'items',COUNT(*) FROM ZITEM;"
# Pro 状態（1 = Pro / キーが無い = Free）
plutil -p "$CONT/Library/Preferences/$BID.plist" | grep entitlement
```

#### 5. コンソールログでのアナリティクス確認

```bash
BID=jp.co.gimic.lastone
xcrun simctl launch --console-pty booted $BID -AppleLanguages "(ja)" -AppleLocale "ja_JP"
# Paywall が開くと [analytics] paywall_shown reason=item_limit / category_limit / settings
# 価格 CTA で   [analytics] pro_purchased
#（PostHog SDK は未導入・print スタブ。`--console-pty` でないと stdout が拾えない点に注意）
```

#### 6. 本スプリントの範囲外（不合格にしないでください）

- **実 SDK（PostHog / RevenueCat）の組み込み**。仕様上 MVP ではプロトコル抽象 + ローカルスタブまで
  （`docs/spec.md`「MVP 内の意図的な制限」）。差し替え手順は `EntitlementStore.swift` /
  `AnalyticsClient.swift` のコメントと README に記載。
- **実際の課金**（StoreKit の購入ダイアログは出ません。CTA を押すと即 Pro になります）。
- **価格・無料枠の数値**（TBD の仮値。`LOLimits` と `priceCta` / `proSub` で変更可能）。
- **プライバシーポリシー / 利用規約の実 URL**（プレースホルダ。`LOURL` の 1 箇所で差し替え）。
- **Dynamic Type への追従**（フォントは design.md の実寸固定。レイアウトが崩れないことは確認済み）。
- **購入履歴の閲覧 UI / CloudKit 同期 / ウィジェット / 消費周期予測**（MVP 対象外）。
- **ユニットテスト / UI テストターゲット**（`project.pbxproj` の編集が必要なため、仕様で新規作成を禁止されている）。
