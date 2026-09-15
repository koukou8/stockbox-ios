# LastOne — 実装用仕様書（MVP / スプリント計画）

> 本書は実装計画である。製品仕様の正典は `docs/spec/lastone-app.md`、デザインの正典は `docs/design.md`。
> 両者に書かれていない機能を本書で追加してはならない。矛盾がある場合は正典を優先する。

## 概要

家庭の日用品・食品・ペット用品のストックを「残り1つになった瞬間のワンタップ」だけで管理する iOS アプリ。買い忘れと重複購入の防止をゴールとし、在庫数の正確な記帳をユーザーに要求しない。MVP は 1人1端末のローカル完結（SwiftData）、英語基準・日本語対応で App Store 配信する。

## 技術前提（確定済み・変更禁止）

| 項目 | 内容 |
|------|------|
| 言語 / UI | Swift / SwiftUI |
| 最低 OS | iOS 17.0+ |
| 永続化 | SwiftData（端末内ローカルのみ。バックエンドなし） |
| 外観 | Light 固定（ダークモードは v1 対象外） |
| i18n | String Catalog `Localizable.xcstrings`。開発言語 en、翻訳 ja |
| 外部 SDK | **MVP では実 SDK を導入しない。** PostHog / RevenueCat は「プロトコル抽象 + ローカルスタブ実装」で作り、後日差し替え可能な seam とする |

### プロジェクト構成の前提

- `LastOne.xcodeproj` とアプリのエントリポイント（`@main` / `ModelContainer` の設置）は**本計画の外側で既に用意されている**。Sprint 1 はそれがある前提で開始する。
- `LastOne/` は Xcode の **file-system-synchronized group** である。`LastOne/` 配下に `.swift` / `.xcstrings` / アセットを追加するだけでビルド対象に入る。
- **`project.pbxproj` は編集不要かつ編集禁止**。ファイル参照追加のための pbxproj 書き換えを行ってはならない。
- Swift Package 依存を追加しない（ネットワーク取得でビルドが壊れるため）。`Package.resolved` を新規に生やす変更を行わない。

### 推奨ディレクトリ構成（`LastOne/` 配下）

```
LastOne/
  App/            エントリポイント（既存。Sprint 1 で ModelContainer 設定を追記）
  Models/         SwiftData @Model と enum
  DesignSystem/   カラー・タイポ・角丸・シャドウのトークン、共通 View 部品
  Features/
    BuyList/  Stocks/  Settings/  ItemEditor/  CategoryManager/  Paywall/
  Services/       Seeder / ItemStateService / AnalyticsClient / EntitlementStore / DataTransfer
  Resources/      Localizable.xcstrings
```

---

## コア機能一覧

| # | 機能名 | 説明 | 優先度 |
|---|--------|------|--------|
| 1 | デザインシステム | `docs/design.md` のカラー・タイポ・角丸・シャドウをトークン化し、共通部品（画面ヘッダー、チップ、カード、カプセルボタン）を提供 | Must |
| 2 | データモデル | Category / Item / PurchaseLog を SwiftData `@Model` で定義。status・trackingMode は文字列 enum で拡張可能に | Must |
| 3 | プリセットカテゴリ投入 | 初回起動時のみ「日用品 / 食品 / ペット用品」をローカライズ名で投入 | Must |
| 4 | 3タブシェル | 買うもの / ストック / 設定。カスタムタブバー（選択時のみ淡いセージ背景） | Must |
| 5 | i18n | 全文言を String Catalog 経由。日付はロケール準拠フォーマッタ | Must |
| 6 | Stocks 一覧 | カテゴリ別セクション + アイテムカード（状態チップ・最終購入日） | Must |
| 7 | 二値トグル | `in_stock ⇄ low` を全幅の淡いボタンで切替。ラベルは状態で反転 | Must |
| 8 | 開封 −1 | カウント方式のみ。`stockCount` を 1 減らし、閾値以下で自動 `low` | Must |
| 9 | アイテム登録 | 名前 / カテゴリ / 管理方式（二値・カウント）を選ぶモーダルシート | Must |
| 10 | アイテム編集・削除 | 既存アイテムの内容変更と削除 | Must |
| 11 | Buy List 自動集約 | `status == low` のアイテムを1行カードで一覧表示 | Must |
| 12 | 「買った」操作 | 在庫状態へ復帰 + `lastPurchasedAt` 更新 + PurchaseLog 追記（カウント方式は補充） | Must |
| 13 | 最終購入日表示 | アイテムカード / Buy List 行に「8/15 に購入」「Bought Aug 15」を表示 | Must |
| 14 | 購入履歴の蓄積 | PurchaseLog を初日から記録（MVP では閲覧 UI を持たない） | Must |
| 15 | Buy List 空状態 | 幾何イラスト付きパネル + 「ストックを見る」導線 | Should |
| 16 | カテゴリ管理 | 追加・名称変更・並べ替え・削除（所属アイテムの扱いを含む） | Must |
| 17 | Settings 画面 | Pro カード、カテゴリ管理導線、エクスポート / インポート、言語について、プライバシーポリシー、脚注 | Must |
| 18 | データのエクスポート / インポート | JSON でのローカル退避と復元（共有シート / ファイル選択） | Should |
| 19 | 無料枠と上限判定 | カテゴリ 5 / アイテム 30。超過操作で Paywall を表示し理由テキストを出し分け | Must |
| 20 | Pro 購入・リストア | `EntitlementStore` プロトコル + ローカルスタブ。UI は本番同等（購入・リストア必須） | Must |
| 21 | Paywall | 星アイコン・特典3行・価格 CTA・購入をリストア | Must |
| 22 | アナリティクス | `AnalyticsClient` プロトコル + ログ出力スタブ。コアループ / 定着 / 課金ファネルのイベントを発火 | Should |

---

## データモデル定義（SwiftData 用に整理）

`docs/spec/lastone-app.md` の「データモデル」章をそのまま SwiftData に落としたもの。フィールドの追加・削除は行わない。

```
Category 1 ─── N Item 1 ─── N PurchaseLog
```

### 共通方針

- 3 モデルとも SwiftData の `@Model` クラス。`id: UUID` を保持する（`@Attribute(.unique)` を付与）。
- **enum は String raw value でストアする。** `trackingMode` / `status` は `String` プロパティとして保存し、Swift 側は computed property で enum を公開する。正典の「将来 `out` 状態を足せるよう拡張可能に」という要求と、SwiftData のスキーマ変更コストを両立させるため。
- リレーションは `Category → [Item]`、`Item → [PurchaseLog]` を `@Relationship(deleteRule: .cascade)` で持ち、逆参照（`item.category` / `log.item`）を `inverse` で結ぶ。
- 日付はすべて `Date`。表示時のみロケール準拠フォーマッタを通す。

### Category

| フィールド | 型 | 説明 |
|-----------|----|----|
| id | UUID | 一意 |
| name | String | カテゴリ名（ユーザー入力。プリセットは投入時にローカライズ済み文字列を確定保存） |
| sortOrder | Int | 表示順（0 起点の連番） |
| createdAt | Date | |
| items | [Item] | cascade 削除 |

### Item

| フィールド | 型 | 説明 |
|-----------|----|----|
| id | UUID | 一意 |
| category | Category? | リレーション（逆参照） |
| name | String | アイテム名。空文字で登録された場合は「新しいアイテム / New item」を採用 |
| trackingMode | `binary` \| `count` | 保存は String。デフォルト `binary` |
| stockCount | Int? | カウント方式のみ使用。二値方式では nil |
| threshold | Int | `low` になる閾値。デフォルト 1（カウント方式のみ意味を持つ） |
| status | `in_stock` \| `low` | 保存は String。デフォルト `in_stock` |
| lastPurchasedAt | Date? | 最終購入日時。未購入は nil |
| sortOrder | Int | カテゴリ内の表示順 |
| createdAt / updatedAt | Date | 状態変更時に `updatedAt` を更新 |
| logs | [PurchaseLog] | cascade 削除 |

### PurchaseLog

| フィールド | 型 | 説明 |
|-----------|----|----|
| id | UUID | 一意 |
| item | Item? | リレーション（逆参照） |
| purchasedAt | Date | 購入日時 |
| quantity | Int | 購入数。二値方式は 1、カウント方式は実際に加算した個数 |

### 状態遷移（`docs/design.md` §4 と一致させること）

```
二値方式:
  in_stock ──「買うものリストに追加」──▶ low ──「買った」──▶ in_stock
  low ──「買うものリストから除外」──▶ in_stock

カウント方式:
  開封 −1 : stockCount = max(0, stockCount - 1)
            status = (stockCount <= threshold) ? low : in_stock
  買った  : status = in_stock
            stockCount = max(threshold + 1, stockCount + 2)   // 既定購入数は 2、ただし必ず閾値超
            quantity = 実際に増えた差分

共通（買った）:
  lastPurchasedAt = now / PurchaseLog を 1 件追記 / updatedAt = now
```

### 登録時のデフォルト

- `trackingMode = binary`、`threshold = 1`、`status = in_stock`、`lastPurchasedAt = nil`
- カウント方式を選んだ場合のみ `stockCount = 2`

---

## スプリント計画

> **進捗（2026-09-03 時点）: Sprint 1〜4 すべて実装完了。**
> 各スプリントのチェックは「実装が入っていること」を表す。受け入れ基準の検証状況は
> `docs/progress.md` の「検証状況」を参照。以下の 5 点だけ実装済みだが実操作での検証が済んでいない。
>
> | 対象 | スプリント | 状態 |
> |------|-----------|------|
> | カテゴリのドラッグ並べ替え | Sprint 3 | 実装済み・実操作未検証 |
> | カテゴリのスワイプ削除と確認ダイアログ | Sprint 3 | 実装済み・実操作未検証 |
> | エクスポートの共有シート | Sprint 3 | 実装済み・実操作未検証 |
> | インポートのファイル選択 | Sprint 3 | 実装済み・実操作未検証 |
> | Dynamic Type 追従 | Sprint 4 | **未達**。`LOFont` は `docs/design.md` の実寸に合わせた固定サイズのため文字サイズ設定に追従しない（レイアウトが破綻しないことのみ確認済み） |
>
> 実操作未検証の 4 件は、検証環境からシミュレータへタップ入力を送れなかったことによる。

各スプリントは Generator の1回の呼び出しで実装しきれる粒度に切ってある。前のスプリントの成果物を壊さないこと（回帰したら不合格）。

---

### Sprint 1: 基盤 — データモデル / デザインシステム / タブシェル / プリセット / i18n

**ゴール:** アプリを起動すると 3 タブのシェルが `docs/design.md` のトークン通りに表示され、初回起動でプリセットカテゴリが SwiftData に投入されている状態。以降のスプリントが「画面の中身を埋めるだけ」で進められる土台を作る。

**機能:**

- [x] **SwiftData モデル定義**: `Category` / `Item` / `PurchaseLog` を上記「データモデル定義」の通りに実装。`TrackingMode` / `StockStatus` は `String, Codable, CaseIterable` な enum とし、モデルには raw String を保存して computed property で公開する。リレーションは cascade + inverse。
- [x] **ModelContainer 設定**: 既存のエントリポイントに 3 モデルのスキーマを登録する。ローカル永続化のみ（CloudKit 設定は付けない）。
- [x] **プリセット投入（Seeder）**: 起動時に `Category` が 0 件のときだけ「日用品 / 食品 / ペット用品」（en: Daily Goods / Food / Pet Supplies）を `sortOrder` 0,1,2 で投入。2回目以降の起動で重複投入しないこと。投入名は実行時のロケールに応じたローカライズ文字列を確定保存する。
- [x] **デザイントークン**: `docs/design.md` §1 のカラー全色を `Color` の名前付き定数に、角丸・シャドウ・タイポ（役割別のサイズ/ウェイト/色）をヘルパーとして定義。フォントは `.fontDesign(.rounded)` で統一し、カスタムフォントは同梱しない。
- [x] **共通シェル部品**: 画面ヘッダー（kicker + タイトル + 右上メタ、padding 64/22/14）、背景グラデーション（`#FDFAF5` → `#FAF5EE`）、状態チップ、カードコンテナ、カプセルボタン、破線ボーダーの追加ボタンを再利用可能な View として実装。
- [x] **カスタムタブバー**: 下部固定 3 タブ（買うもの / ストック / 設定）。アイコンは 23pt・線幅 1.7 相当の SF Symbols（カート / 箱 / 歯車）。選択タブのみ背景 `rgba(143,184,158,.16)`・角丸 18・文字色 `#5E7F62`、非選択は `#BDB1A2`。
- [x] **3画面のプレースホルダ**: 各タブに正しい kicker / タイトル / 右上メタ枠を持つ空画面を置く（中身は次スプリント以降）。
- [x] **String Catalog**: `Localizable.xcstrings` を作成し、`docs/design.md` §3 の全キーを en / ja で登録。UI 文言のハードコードを禁止する。キー命名は design.md の表のキー名に準拠。
- [x] **AnalyticsClient の seam**: `AnalyticsClient` プロトコル（`track(_ event: AnalyticsEvent)`）と、`print` に流すだけの `LoggingAnalyticsClient` スタブを実装し、SwiftUI の Environment 経由で注入。イベント名は `item_marked_low` / `item_purchased` / `item_opened` / `item_created` / `category_created` / `paywall_shown` / `pro_purchased` を型で定義しておく（発火は後続スプリント）。**PostHog SDK は追加しない。**

**受け入れ基準:**

- `xcodebuild -scheme LastOne -destination 'platform=iOS Simulator,name=iPhone 17' build` がエラーなく成功する。
- 外部パッケージ依存が 0 件のままである（`project.pbxproj` に変更が入っていない／`Package.resolved` が生成されていない）。
- シミュレータで起動すると背景が `#FAF5EE` 系の生成り色で、下部に 3 タブが表示され、タップで選択タブのハイライトが移動する。
- 各タブのヘッダーに kicker（大文字・字間広め）とタイトルが design.md の表通りに出る（Buy List / Stocks / Settings）。
- アプリを一度削除して再インストールした初回起動でカテゴリが 3 件生成され、アプリを再起動しても 3 件のまま増えない。
- 端末言語を日本語にすると タブが「買うもの / ストック / 設定」、英語にすると「Buy List / Stocks / Settings」になる。
- ソース内に UI 表示用の日本語・英語リテラルが直書きされていない（文言はすべて String Catalog キー経由）。

**参照:** `docs/design.md` §1（全体）、§2「共通シェル」、§3（全キー）、§5

---

### Sprint 2: Stocks 画面とコア状態遷移 + アイテム登録／編集シート

**ゴール:** ユーザーがアイテムを登録し、Stocks 画面で「買うものリストに追加」「開封 −1」を操作して `in_stock` / `low` を行き来できる。アプリのコアループの前半（在庫→low）が完成する。

**機能:**

- [x] **Stocks 一覧**: カテゴリごとのセクション。見出し行はカテゴリ名（13/medium `#9A8D7E`）+ 件数（11/semibold `#C4B8A8`）+ 右に伸びるグラデ罫線。カテゴリは `sortOrder` 昇順、アイテムはカテゴリ内 `sortOrder` 昇順。
- [x] **アイテムカード（共通）**: 白・角丸 22・padding 15/16・カードシャドウ。上段左にアイテム名（16/medium）と最終購入日（11.5 `#B0A496`）、上段右に状態チップ（在庫あり: 背景 `#EAF2E9` / 文字 `#688B6D`、のこり1つ: 背景 `#FCEADC` / 文字 `#C4713C`）。赤系の色は使わない。
- [x] **最終購入日の表示**: `lastPurchasedAt` があれば「8/15 に購入」「Bought Aug 15」相当をロケール準拠フォーマッタ（`Date.FormatStyle`）で生成。nil なら「まだ購入記録なし / Never bought yet」。
- [x] **二値方式の操作行**: カード下段に全幅の淡いボタン（背景 `#FBF6EF` / 枠 `#EEE3D4` / 角丸 16）。ラベルは `in_stock` のとき「買うものリストに追加」、`low` のとき「買うものリストから除外」。タップで状態をトグルし、`withAnimation(.snappy)` 程度の控えめなアニメーションでチップとラベルが切り替わる。
- [x] **カウント方式の操作行**: `#FBF6EF` のブロックに大きな数値（20/bold）+「つストック（閾値 N）」、右に「開封 −1」カプセルボタン。タップで `stockCount = max(0, stockCount - 1)`、`stockCount <= threshold` なら `low`、そうでなければ `in_stock`。`stockCount == 0` でもクラッシュせず 0 のまま維持する。
- [x] **ItemStateService**: 状態遷移ロジック（markLow / unmarkLow / openOne / purchase）を View から切り離した1箇所に集約し、`updatedAt` の更新もここで行う。purchase は Sprint 3 で使う。
- [x] **アイテム追加シート**: `docs/design.md` §2「アイテム追加シート」の構成（ドラッグハンドル → タイトル → 名前入力 → カテゴリチップ選択 → 管理方式 2択カード → 「追加する」→ 残り枠ラベル）。デフォルトは二値方式・`threshold = 1`、カウント選択時のみ `stockCount = 2`。名前が空のまま追加したら「新しいアイテム / New item」を採用。残り枠ラベルは「あと N 個まで無料で登録できます」を表示（この時点では表示のみでブロックはしない。上限判定は Sprint 4）。
- [x] **アイテム編集・削除**: 一覧のカードから編集シートを開き、名前 / カテゴリ / 管理方式 / 閾値を変更できる。削除も編集シートから行い、確認のうえ実行する（紐づく PurchaseLog は cascade で消える）。
- [x] **「＋ アイテムを追加」ボタン**: 一覧末尾に破線ボーダー（`#E0D3C0` 1.5px dashed）で配置し、追加シートを開く。
- [x] **アナリティクス発火**: `item_created` / `item_marked_low` / `item_opened` を `AnalyticsClient` 経由で発火（スタブ実装のため実際はログ出力）。

**受け入れ基準:**

- `xcodebuild -scheme LastOne -destination 'platform=iOS Simulator,name=iPhone 17' build` が成功する。
- Stocks で「＋ アイテムを追加」→ 名前「醤油」、カテゴリ「食品」、二値方式 →「追加する」で、食品セクションに「醤油」カードが在庫ありチップ付きで現れる。
- 名前を空のまま追加すると「新しいアイテム」（英語では New item）という名前のアイテムが作られる。
- 二値方式のカードで「買うものリストに追加」を押すとチップが「のこり1つ」に変わり、ボタンラベルが「買うものリストから除外」に変わる。もう一度押すと元に戻る。
- カウント方式（`stockCount = 3`, `threshold = 1`）のアイテムで「開封 −1」を押すと 2 になり在庫ありのまま。もう一度押して 1 になると自動で「のこり1つ」チップに変わる。
- `stockCount` が 0 の状態で「開封 −1」を押しても 0 のまま、クラッシュしない。
- アプリを再起動しても、変更した状態・カウント値が保持されている。
- 未購入アイテムには「まだ購入記録なし / Never bought yet」が表示される。
- 編集シートでカテゴリを変更すると、一覧上でアイテムが別セクションへ移動する。削除するとカードが消え、再起動後も復活しない。

**参照:** `docs/design.md` §2「Stocks（タブ2）」「アイテム追加シート」、§3（`inStock` / `low` / `openOne` / `binaryAction` / `countHint` / `addItem` / `addSheetTitle` / `namePlaceholder` / `category` / `trackingMode` / `binary` / `count` / `addConfirm` / `last` / `noLast` / `quota`）、§4

---

### Sprint 3: Buy List / 購入記録 / カテゴリ管理 / Settings 骨格

**ゴール:** コアループ（low → 買った → in_stock）が閉じ、購入履歴が蓄積される。カテゴリを自分で管理でき、Settings のリストが機能する。

**機能:**

- [x] **Buy List 一覧**: `status == low` のアイテムを自動集約した横並びの1行カード（角丸 22）。左にアイテム名（16/medium）、2 行目にカテゴリチップ（背景 `#F4EEE5` / 文字 `#9A8D7E`）と最終購入日ラベル。右に「買った」カプセルボタン（`#8FB89E` / 白文字 / ボタンシャドウ）。
- [x] **「買った」操作**: `status = in_stock`、`lastPurchasedAt = now`、`updatedAt = now`、`PurchaseLog` を 1 件追記。カウント方式は `stockCount = max(threshold + 1, stockCount + 2)` とし、`quantity` に実際の増分を記録。二値方式は `quantity = 1`。実行後、その行が Buy List から消える（`.snappy` 程度のアニメーション）。
- [x] **右上メタの件数**: Buy List ヘッダー右上に「N件 / N items」を表示し、リストの増減に追従する。
- [x] **空状態**: low が 0 件のとき、角丸 30 のパネル（`#FDFAF5`→`#F8F2E9`、枠 `#F0E7DA` 1.5px）に「空のかご」の幾何イラスト（`SF Symbols` ではなく Shape で構成した簡素な図形で可。ゆっくり上下する控えめなアニメーション）+ 「買うものはありません」+ 本文 + 「ストックを見る」ボタン。ボタンを押すと Stocks タブへ切り替わる。
- [x] **カテゴリ管理シート**: 行（ハンドルアイコン + 名前 + 件数）のリスト + 破線の「＋ カテゴリを追加」。名称変更（インライン編集）、ドラッグ並べ替え（`sortOrder` を永続化）、スワイプ削除に対応。
- [x] **カテゴリ削除の扱い**: 所属アイテムがある場合は削除前に確認を出し、「所属アイテムも一緒に削除される」ことを明示する（cascade）。最後の 1 カテゴリは削除させない（アイテムの行き先が無くなるため）。
- [x] **Settings 画面（骨格）**: 先頭に Pro カード（ゴールドグラデ `#FDF3E2`→`#F8E7CF`、PRO バッジ、購入状態、見出し、説明、「Pro を見る」/「リストア」）を**レイアウトのみ**配置。続いて白カードのリスト: 「カテゴリの管理 >」（右にカテゴリ数「N カテゴリ」）、データのエクスポート（JSON）、データのインポート、言語について（端末の設定に追従）、プライバシーポリシー。行間は区切り線 `#F4EDE3`。末尾に脚注（`privacyNote`）。
- [x] **エクスポート / インポート**: 全 Category / Item / PurchaseLog を JSON にシリアライズして共有シートで書き出し、ファイル選択で読み込んで復元する。インポートは「全置換」とし、実行前に確認ダイアログを出す。バージョン識別子を JSON に含めておく。
- [x] **言語について / プライバシーポリシー**: 前者はタップで「端末の設定に追従します」旨の説明と iOS 設定アプリへの導線、後者は URL を開く（URL は定数として1箇所にまとめ、差し替え可能にする）。
- [x] **アナリティクス発火**: `item_purchased` / `category_created`。

**受け入れ基準:**

- `xcodebuild -scheme LastOne -destination 'platform=iOS Simulator,name=iPhone 17' build` が成功する。
- Stocks で二値方式アイテムの「買うものリストに追加」を押すと、Buy List タブにそのアイテムが現れ、右上メタの件数が +1 される。
- Stocks でカウント方式アイテム（`stockCount = 2`, `threshold = 1`）の「開封 −1」を閾値まで押すと、そのアイテムが Buy List に現れる。
- Buy List で「買った」を押すと行が消え、Stocks 側で同アイテムのチップが「在庫あり」に戻り、最終購入日が今日の日付で表示される。
- カウント方式アイテムを「買った」した後、`stockCount` が閾値を必ず上回っている（例: 1 → 3）。
- 「買った」を 2 回行った後にエクスポートした JSON に、PurchaseLog が 2 件（`purchasedAt` / `quantity` つき）含まれている。
- low が 0 件のとき空状態パネルが表示され、「ストックを見る」でタブが Stocks に切り替わる。
- カテゴリ管理でカテゴリを追加すると、アイテム追加シートのカテゴリチップにも即座に現れる。並べ替えた順序が Stocks のセクション順に反映され、再起動後も保持される。
- アイテムを持つカテゴリを削除しようとすると確認が出る。カテゴリが 1 件しかないときは削除できない。
- エクスポートした JSON をインポートすると、削除したアイテムを含めてエクスポート時点の状態に復元される。

**参照:** `docs/design.md` §2「Buy List（タブ1）」「Settings（タブ3）」「カテゴリ管理シート」、§3（`bought` / `emptyTitle` / `emptyBody` / `emptyCta` / `addCat` / `manageCats` / `catCount` / `countLabel` / `privacyNote` / settings 行）、§4

---

### Sprint 4: 無料枠と Paywall / 課金の seam / 仕上げ

**ゴール:** 無料枠の上限判定が働き、超過時に Paywall が出て「購入」「リストア」で Pro 状態が切り替わる（ローカルスタブ経由）。全画面のコピー・レイアウトが en / ja の両方で崩れない状態に仕上げる。

**機能:**

- [x] **EntitlementStore の seam**: `EntitlementStore` プロトコル（`isPro: Bool` の監視、`purchase()`, `restore()`）を定義し、`UserDefaults` に保存する `LocalEntitlementStore` スタブを実装。Environment 経由で注入し、View は必ずプロトコル越しに参照する。**RevenueCat SDK は追加しない。** 実 SDK 導入時にこのプロトコルの実装クラスを差し替えるだけで済む構造にすること（プロトコル定義ファイルに、その差し替え手順をコメントで残す）。
- [x] **無料枠の上限判定**: カテゴリ 5 個 / アイテム 30 個。上限値は 1 箇所の定数にまとめ、`isPro == true` では無制限。追加操作の実行時点で判定する。
- [x] **Paywall シート**: グラデ背景 → 金色の円に星アイコン（74pt）→「LastOne Pro」→ 表示理由テキスト → 特典 3 行（チェックアイコン + 文言）→ 価格 CTA（`#C99A56`）→「購入をリストア」。角丸 32、オーバーレイ `rgba(65,56,48,0.32)`。
- [x] **表示理由の出し分け**: アイテム上限で開いたときは `limitItems`、カテゴリ上限では `limitCats`、Settings の「Pro を見る」から開いたときは `proReason` を表示する。
- [x] **Pro カードの状態反映**: Settings の Pro カードに購入状態（「購入済み・ありがとうございます」/「未購入」）を表示。Pro のときは「Pro を見る」CTA を購入済み表示に切り替える。「リストア」は常に押せる（審査要件）。
- [x] **右上メタへの反映**: Stocks の右上メタを「`<アイテム数> / <上限 or ∞>`」に、Settings の右上メタを「Pro / Free」にする。アイテム追加シートの残り枠ラベルも Pro 時は「Pro：登録数は無制限です」に切り替える。
- [x] **アナリティクス発火**: `paywall_shown`（理由を property として付与）/ `pro_purchased`。
- [x] **i18n 仕上げ**: 全画面を英語で通し、ボタン・チップ・カード内テキストが折返しや `minimumScaleFactor` で崩れないことを確認して調整する。日付・件数表示のロケール確認。String Catalog に未翻訳（`stale` / 未入力）のキーが残っていないこと。
- [x] **表示仕上げ**: Dynamic Type を 1 段上げても主要画面が破綻しないこと、セーフエリア（ホームインジケータ）とタブバーの重なりが無いこと、スクロール時のヘッダーグラデーションが不自然でないことを確認して調整する。

**受け入れ基準:**

- `xcodebuild -scheme LastOne -destination 'platform=iOS Simulator,name=iPhone 17' build` が成功する。
- 外部パッケージ依存が 0 件のままで、`project.pbxproj` に差分が無い。
- 無料状態でカテゴリを 6 個目に追加しようとすると Paywall が開き、「無料枠のカテゴリ上限（5個）に達しました。」が表示され、カテゴリは追加されていない。
- 無料状態でアイテムを 31 個目に追加しようとすると Paywall が開き、`limitItems` の文言が表示され、アイテムは追加されていない。
- Paywall の価格 CTA を押すと Pro になり、シートが閉じ、その直後に同じ追加操作が成功する。Settings の右上メタが「Pro」に変わる。
- アプリを再起動しても Pro 状態が保持される。
- Pro を解除した状態（`UserDefaults` をリセット、またはアプリ再インストール）で「購入をリストア」を押すと Pro 状態に戻る（スタブ実装の範囲で購入履歴を復元する挙動）。
- Pro 状態では Stocks の右上メタが「N / ∞」になり、アイテム追加シートの残り枠ラベルが「Pro：登録数は無制限です」になる。
- 端末言語を英語にして全画面を巡回し、テキストの見切れ・ボタンの潰れ・レイアウト崩れが無い。日本語でも同様。
- `EntitlementStore` / `AnalyticsClient` の呼び出しが View から直接 SDK に触れる形になっておらず、プロトコル越しになっている。

**参照:** `docs/design.md` §1（Pro ゴールド系）、§2「Paywall シート」「Settings（タブ3）」、§3（`proHead` / `proSub` / `seePro` / `restoreShort` / `restore` / `priceCta` / `perks` / `proStatus` / `quota` / `limitItems` / `limitCats` / `proReason`）、§4「無料枠」、§5

---

## 画面ごとの要件

すべての画面で、レイアウト値（padding / 角丸 / 色 / フォントサイズ）は `docs/design.md` §1・§2 を正とする。

### 共通シェル

- ヘッダー: `padding 64/22/14`。kicker（12/medium・字間 0.14em・大文字・`#C0B4A5`）→ タイトル（27/bold・`#413830`）を左に、メタ（12/regular・`#A79C91`）を右下揃えに配置。
- コンテンツ: スクロール領域 `padding 8/18/22`、要素間 14。
- タブバー: 下部固定 3 タブ。選択時のみ角丸 18 の淡いセージ背景。
- 参照: `docs/design.md` §2「共通シェル」

### Buy List（タブ1）

- 表示対象: `status == low` のアイテム全件（カテゴリ横断）。並び順はカテゴリ `sortOrder` → アイテム `sortOrder`。
- 各行: 名前 + カテゴリチップ + 最終購入日 + 「買った」ボタン。
- 空状態: `emptyTitle` / `emptyBody` / `emptyCta` のパネル。
- 右上メタ: 件数（`countLabel`）。
- 参照: `docs/design.md` §2「Buy List（タブ1）」、§3

### Stocks（タブ2）

- カテゴリ別セクション（見出し + 件数 + グラデ罫線）→ アイテムカード → 末尾に破線の「＋ アイテムを追加」。
- カードは二値方式とカウント方式で下段の操作ブロックが変わる。
- 右上メタ: `<アイテム数> / <上限 or ∞>`。
- 参照: `docs/design.md` §2「Stocks（タブ2）」、§4

### Settings（タブ3）

- Pro カード → 白カードのリスト（カテゴリの管理 / エクスポート / インポート / 言語について / プライバシーポリシー）→ 脚注。
- 右上メタ: `Pro` / `Free`。
- 参照: `docs/design.md` §2「Settings（タブ3）」、§3「settings 行」

### アイテム追加・編集シート

- ドラッグハンドル → タイトル（20/bold）→ 名前入力（白・角丸 16・枠 `#EBE0D0`・プレースホルダ `namePlaceholder`）→ カテゴリチップ選択 → 管理方式の 2 択カード（サブテキスト付き）→ 「追加する」ボタン（角丸 20・`#8FB89E`）→ 残り枠ラベル。
- 編集時はタイトルと CTA を編集用の文言に切り替え、削除導線を持つ。
- 参照: `docs/design.md` §2「アイテム追加シート」

### カテゴリ管理シート

- 行（ハンドル + 名前 + 件数）+ 破線の「＋ カテゴリを追加」。並べ替え・改名・削除。
- 参照: `docs/design.md` §2「カテゴリ管理シート」

### Paywall シート

- 星アイコン → タイトル → 表示理由 → 特典 3 行 → 価格 CTA → 購入をリストア。
- 参照: `docs/design.md` §2「Paywall シート」

---

## 検証方法

Evaluator は **Web ブラウザではなく iOS シミュレータ**で検証する。Playwright は使用しない。

### 1. ビルド検証（必須・全スプリント共通）

```bash
cd /Users/koukiyoshida/development/lastone-app
xcodebuild -scheme LastOne \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath build \
  build
```

- 判定: `** BUILD SUCCEEDED **` が出力されること。
- 併せて `git diff --stat` で `LastOne.xcodeproj/project.pbxproj` に差分が無いこと、`Package.resolved` が新規生成されていないことを確認する。

### 2. シミュレータ起動

```bash
xcrun simctl boot "iPhone 17" || true
open -a Simulator
xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/LastOne.app
xcrun simctl launch booted <APP_BUNDLE_ID>
```

- クリーンな初回起動を再現する場合: `xcrun simctl uninstall booted <APP_BUNDLE_ID>` の後に再インストール。
- `<APP_BUNDLE_ID>` は Xcode プロジェクトの設定値に従う。

### 3. 言語別の起動

```bash
# 日本語で起動
xcrun simctl launch booted <APP_BUNDLE_ID> -AppleLanguages "(ja)" -AppleLocale "ja_JP"
# 英語で起動
xcrun simctl launch booted <APP_BUNDLE_ID> -AppleLanguages "(en)" -AppleLocale "en_US"
```

### 4. 手動テストシナリオ（コアループ）

1. アプリを削除 → 再インストール → 起動。Stocks にプリセット 3 カテゴリのセクションが空で並ぶ。
2. 「＋ アイテムを追加」→ 名前「シャンプー」/ カテゴリ「日用品」/ 二値方式 →「追加する」。カードが在庫ありで出る。
3. 同じ手順でカウント方式のアイテム「トイレットペーパー」を追加（`stockCount = 2`, `threshold = 1`）。
4. シャンプーの「買うものリストに追加」を押す → チップが「のこり1つ」になる。
5. トイレットペーパーの「開封 −1」を押す → 1 になり自動で「のこり1つ」になる。
6. Buy List タブへ → 2 件表示され、右上メタが「2件」。
7. 両方の「買った」を押す → 行が消え、空状態パネルが出る。
8. Stocks に戻る → 両方が「在庫あり」、最終購入日が今日、トイレットペーパーの `stockCount` が閾値超（3）。
9. アプリを終了して再起動 → 上記の状態が保持されている。
10. Settings → エクスポート → JSON に PurchaseLog が 2 件含まれる。

### 5. 上限・Paywall シナリオ（Sprint 4）

1. カテゴリを 5 個にする → 6 個目の追加操作 → Paywall が `limitCats` の理由で開き、追加されない。
2. アイテムを 30 個にする → 31 個目 → Paywall が `limitItems` の理由で開き、追加されない。
3. 価格 CTA を押す → Pro になり、同じ追加操作が成功する。
4. 再起動しても Pro のまま。アンインストール → 再インストール → 「購入をリストア」で Pro に戻る。

### 6. 日本語 / 英語の両方で確認すべき点

| 観点 | 確認内容 |
|------|---------|
| タブ・ヘッダー | 買うもの / ストック / 設定 ⇄ Buy List / Stocks / Settings が正しく切り替わる |
| 状態チップ | 在庫あり / のこり1つ ⇄ In stock / Last one。英語で幅が伸びてもチップが潰れない |
| 操作ボタン | 「買うものリストに追加 / 除外」⇄「Add to / Remove from Buy List」。英語の長文で折返し・省略が崩れない |
| カウント表記 | 「3 つストック（閾値 1）」⇄「3 in stock (threshold 1)」 |
| 最終購入日 | ja「8/15 に購入」/ en「Bought Aug 15」。ロケール準拠フォーマッタ経由で、ハードコードした書式でない |
| 件数表記 | 「N件」/「N items」、「N カテゴリ」/「N categories」 |
| Pro 文言 | 価格 CTA・特典 3 行・購入状態が両言語で表示され、CTA ボタンからテキストが溢れない |
| プリセットカテゴリ | 初回起動時のロケールに応じた名前で作られる |
| 未翻訳 | String Catalog に未翻訳キーが残っていない |

---

## スコープ外（MVP に含めない）

`docs/spec/lastone-app.md`「MVP 対象外（ロードマップ）」の再掲。以下をスプリントに含めてはならない。

| 機能 | 想定時期 | 理由 / メモ |
|------|---------|------|
| CloudKit 同期（機種変更・複数端末） | v1.1 | MVP はローカルのみ。`ModelContainer` に CloudKit 設定を入れない |
| ホーム画面ウィジェット（WidgetKit） | v1.1 | 別ターゲットが必要 |
| カレンダー UI（購入日表示・日付タップで購入品一覧） | v1.1 以降 | PurchaseLog は MVP から蓄積するが、閲覧 UI は作らない |
| 消費周期の推定・「切れる日予測」 | v1.2 以降 | 本命差別化機能。サブスク課金候補 |
| 家族共有・リアルタイム同期 | v2 | クラウド DB + 認証が前提 |
| プッシュ通知 | 予測機能とセット | 通知許可のリクエストも実装しない |
| バーコード登録 | 未定 | カメラ権限も要求しない |

### MVP 内の意図的な制限

- **購入履歴の閲覧 UI は作らない**（記録のみ。エクスポート JSON でのみ確認可能）。
- **ダークモードは対応しない**（Light 固定）。
- **実 SDK（PostHog / RevenueCat）は組み込まない**。プロトコル抽象 + ローカルスタブまで。実 SDK 差し替えは MVP 完了後、API キーと Apple Developer Program 加入が揃ってから行う。
- **アプリ内の言語切替 UI は置かない**（iOS 標準の「設定 > アプリごとの言語」に委ねる。Settings の「言語について」は説明と設定アプリへの導線のみ）。
- **`out`（品切れ）状態は実装しない**（`status` を文字列 enum にして将来の追加に備えるのみ）。
- **ユニットテスト / UI テストターゲットは新規作成しない**（`project.pbxproj` 編集が必要になるため）。検証はビルド成功 + シミュレータでの手動シナリオで行う。

### 未確定事項（TBD・実装時は仮値で進める）

- 無料枠の数値（カテゴリ 5 / アイテム 30 で実装。1 箇所の定数で変更可能にする）
- Pro の価格（表示は design.md の `priceCta`「¥800 で買い切り」/「Buy once · $5.99」を仮の文言として使用）
- プライバシーポリシー / 利用規約の URL（定数として 1 箇所にまとめ、プレースホルダ URL で実装）
- アプリ正式名称（「LastOne」で実装）
