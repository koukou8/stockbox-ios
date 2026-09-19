# LastOne デザイン仕様（screen/ プロトタイプ抽出）

出典: `screen/LastOne App.dc.html`（Stitch/DC 形式のインタラクティブ試作）。
実装（SwiftUI）はこのトークン・レイアウト・コピーに準拠すること。

## 1. デザイントークン

### カラー（Light。ダークモードは v1 では対象外、Light 固定でよい）

| 用途 | Hex | 備考 |
|------|-----|------|
| 背景（アプリ全体 / シート） | `#FAF5EE` | 生成りの紙色。純白を使わない |
| 背景グラデ上端（ヘッダー） | `#FDFAF5` | `#FDFAF5` → `#FAF5EE` の縦グラデ |
| カード背景 | `#FFFFFF` | |
| サブ背景（カード内の操作ブロック） | `#FBF6EF` | 枠線 `#EEE3D4` |
| テキスト primary | `#413830` | 見出し・アイテム名 |
| テキスト body | `#4A4038` | 設定行ラベル |
| テキスト secondary | `#8C8073` / `#8A7D6E` | 説明文・ボタン文字 |
| テキスト tertiary | `#A79C91` / `#B0A496` | 補足・最終購入日 |
| テキスト faint | `#C0B4A5` / `#B5A996` / `#BDB1A2` | kicker・脚注・非選択タブ |
| アクセント（主要アクション） | `#8FB89E` | 「買った」「追加する」。押下/hover `#7FA588` |
| アクセント濃（タブ選択文字） | `#5E7F62` | 選択タブ背景 `rgba(143,184,158,.16)` |
| 在庫ありチップ | 背景 `#EAF2E9` / 文字 `#688B6D` | |
| のこり1つチップ | 背景 `#FCEADC` / 文字 `#C4713C` | 赤い警告色は使わない |
| Pro ゴールド | `#C99A56`（押下 `#B98A47`） | Pro カード背景は `#FDF3E2`→`#F8E7CF` グラデ |
| Pro テキスト | 見出し `#6E4F26` / 本文 `#9A7A4C` / ラベル `#B08344` | |
| 区切り線 | `#F4EDE3` | 設定リストの行間 |
| 枠線 | `#E7DCCC` / `#EBE0D0` / `#EEE3D4` | |
| 破線ボーダー（追加ボタン） | `#E0D3C0` 1.5px dashed | |

### シャドウ
- カード: `y8 blur22 rgba(150,124,96,0.09)`（SwiftUI: `.shadow(color: Color(red:0.588,green:0.486,blue:0.376).opacity(0.09), radius: 11, y: 5)` 目安）
- 主要ボタン: `y6 blur14 rgba(143,184,158,0.40)`
- Pro ボタン: `y8-10 blur18-24 rgba(201,154,86,0.35)`
- シート: `y-14 blur40 rgba(65,56,48,0.18)`
- モーダル背景オーバーレイ: `rgba(65,56,48,0.28)`（Paywall は 0.32）

### 角丸
| 対象 | 半径 |
|------|------|
| アイテムカード / Buy List 行 | 22 |
| 設定カード / パネル | 24–26 |
| シート上端 | 30（Paywall 32） |
| カード内操作ブロック | 16 |
| 主要ボタン（シート内） | 20 |
| チップ・ピル・タブ内ボタン | 999（カプセル） |
| タブバー選択背景 | 18 |

### タイポグラフィ
プロトは Zen Maru Gothic（丸ゴシック）+ 数字 Quicksand。
**SwiftUI では `.fontDesign(.rounded)`（SF Rounded）で代替**し、追加フォントは同梱しない。

| 役割 | サイズ / ウェイト | 色 |
|------|------------------|-----|
| 画面 kicker（"Buy List" 等・大文字） | 12 / medium・letterSpacing 0.14em・uppercase | `#C0B4A5` |
| 画面タイトル | 27 / bold | `#413830` |
| 画面メタ（右上） | 12 / regular | `#A79C91` |
| セクション見出し（カテゴリ名） | 13 / medium | `#9A8D7E` |
| セクション件数 | 11 / semibold | `#C4B8A8` |
| アイテム名 | 16 / medium | `#413830` |
| 最終購入日・補足 | 11.5 / regular | `#B0A496` |
| チップ | 11.5 / medium | 状態色 |
| 主要ボタン | 13.5–15 / medium | 白 |
| 設定行ラベル | 14.5 / medium | `#4A4038` |
| シートタイトル | 20 / bold | `#413830` |
| カウント数値 | 20 / bold（数字は rounded） | `#413830` |

### モーション
- シート: 下からスライドイン 0.28s `cubic-bezier(.22,.9,.3,1)` → SwiftUI 標準の `.sheet` + `.presentationDetents([.medium/.large])` で可
- オーバーレイ: fadeIn 0.18s
- 状態変化は `withAnimation(.snappy)` 程度の控えめなもの

## 2. 画面レイアウト

### 共通シェル
- ヘッダー: `padding 64/22/14`、kicker → タイトル（左）＋メタ（右下揃え）
- コンテンツ: スクロール、`padding 8/18/22`、要素間 14
- タブバー: 下部固定、3タブ（買うもの / ストック / 設定）。アイコンは 23pt ストローク 1.7 の線画（カート・箱・歯車）。選択時のみ背景 `rgba(143,184,158,.16)` の角丸 18

| タブ | kicker | タイトル | 右上メタ |
|------|--------|---------|---------|
| Buy List | Buy List | 買うもの / Buy List | `<件数>件` / `N items` |
| Stocks | Stocks | ストック / Stocks | `<アイテム数> / <上限 or ∞>` |
| Settings | Settings | 設定 / Settings | `Pro` / `Free` |

### Buy List（タブ1）
- `status == low` のアイテムを自動集約した1行カード（横並び）
  - 左: アイテム名（16/medium）＋ 2行目にカテゴリチップ（背景 `#F4EEE5` / 文字 `#9A8D7E`）と最終購入日ラベル
  - 右: 「買った」カプセルボタン（`#8FB89E` / 白文字）
- 空状態: 角丸 30 のパネル（`#FDFAF5`→`#F8F2E9`、枠 `#F0E7DA` 1.5px）に「空のかご」の幾何イラスト（ふわふわ上下する 5.5s アニメ）＋ タイトル / 本文 / 「ストックを見る」ボタン

### Stocks（タブ2）
- カテゴリごとのセクション: 見出し行（カテゴリ名 + 件数 + 右に伸びるグラデ罫線）
- アイテムカード（白・角丸22・padding 15/16）
  - 上段: 名前 + 最終購入日 / 右に状態チップ（在庫あり or のこり1つ）
  - 下段（二値方式）: 全幅の淡いボタン `#FBF6EF`。ラベルは状態で切替（在庫あり→「買うものリストに追加」/ low→「買うものリストから除外」）
  - 下段（カウント方式）: `#FBF6EF` のブロックに大きな数値 + 「つストック（閾値 N）」、右に「開封 −1」カプセルボタン
- 末尾: 破線ボーダーの「＋ アイテムを追加」

### Settings（タブ3）
- 先頭に Pro カード（ゴールドグラデ）: PRO バッジ + 購入状態 + 見出し + 説明 + 「Pro を見る」/「リストア」
- 白カードのリスト: 「カテゴリの管理 >」（右にカテゴリ数）、データのエクスポート（JSON）、データのインポート、言語について（端末の設定に追従）、プライバシーポリシー
- 脚注: データは端末内にのみ保存 / 購入履歴を将来機能のために記録中

### アイテム追加シート
ドラッグハンドル → タイトル → 名前入力（白・角丸16・枠 `#EBE0D0`）→ カテゴリチップ選択 → 管理方式の2択カード（二値 / カウント、サブテキスト付き）→ 「追加する」ボタン → 残り枠ラベル

### カテゴリ管理シート
行（ハンドルアイコン + 名前 + 件数）のリスト ＋ 破線の「＋ カテゴリを追加」

### Paywall シート
グラデ背景 → 金色の円に星アイコン（74pt）→ 「LastOne Pro」→ 表示理由テキスト → 特典3行（チェックアイコン + 文言）→ 価格 CTA → 「購入をリストア」

## 3. コピー（en / ja。String Catalog のキー設計の基準）

| キー | ja | en |
|------|----|----|
| bought | 買った | Bought |
| low | のこり1つ | Last one |
| inStock | 在庫あり | In stock |
| openOne | 開封 −1 | Opened −1 |
| addItem | ＋ アイテムを追加 | + Add item |
| addSheetTitle | アイテムを追加 | Add an item |
| namePlaceholder | なにをストックしますか？ | What are you stocking? |
| category | カテゴリ | Category |
| trackingMode | 管理方式 | Tracking |
| binary / binaryHint | 二値 / 在庫あり・のこり1つ | Binary / In stock · Last one |
| count / countHintShort | カウント / 開封するたび −1 | Count / −1 on each opening |
| addConfirm | 追加する | Add item |
| addCat | ＋ カテゴリを追加 | + Add category |
| tabBuy / tabStocks / tabSettings | 買うもの / ストック / 設定 | Buy List / Stocks / Settings |
| proHead | カテゴリもアイテムも、無制限に。 | Unlimited items and categories. |
| proSub | 買い切り ¥500。家中のストックを気にせず登録できます。 | One-time $3.99. Stock the whole house without counting. |
| seePro / restoreShort / restore | Pro を見る / リストア / 購入をリストア | See Pro / Restore / Restore purchase |
| priceCta | ¥500 で買い切り | Buy once · $3.99 |
| manageCats | カテゴリの管理 | Manage categories |
| privacyNote | データは端末内にのみ保存されます。購入履歴は将来のカレンダー・消費周期予測のために記録中です。 | Data stays on this device. Purchases are logged now to power the calendar and refill predictions later. |
| emptyTitle | 買うものはありません | Nothing to buy |
| emptyBody | ストックの最後の1つを開けたら、ストック一覧でチェックしてください。 | When you open the last one of a stock, check it off in Stocks. |
| emptyCta | ストックを見る | Go to Stocks |
| perks | カテゴリ・アイテムを無制限に登録 / 最終購入日をずっと残す / 買い切り・追加課金なし | Unlimited categories and items / Keep every purchase date / One-time purchase, no upsells |
| settings 行 | データのエクスポート(JSON) / データのインポート / 言語について(端末の設定に追従) / プライバシーポリシー | Export data(JSON) / Import data / About language(Follows device) / Privacy Policy |
| プリセットカテゴリ | 日用品 / 食品 / ペット用品 | Daily Goods / Food / Pet Supplies |
| countHint | 「つストック（閾値 N）」 | "in stock (threshold N)" |
| binaryAction | low: 買うものリストから除外 / in_stock: 買うものリストに追加 | Remove from Buy List / Add to Buy List |
| last / noLast | 8/15 に購入 / まだ購入記録なし | Bought Aug 15 / Never bought yet |
| countLabel / catCount | N件 / N カテゴリ | N items / N categories |
| proStatus | 購入済み・ありがとうございます / 未購入 | Purchased — thank you / Free plan |
| quota | Pro：登録数は無制限です / あと N 個まで無料で登録できます | Pro: unlimited items / N more items on the free plan |
| limitItems | 無料枠のアイテム上限（N個）に達しました。Pro で上限がなくなります。 | You hit the free limit of N items. Pro removes it. |
| limitCats | 無料枠のカテゴリ上限（5個）に達しました。 | You hit the free limit of 5 categories. |
| proReason | 無料枠はカテゴリ5個・アイテムN個まで。Pro なら家中のストックを全部登録できます。 | Free covers 5 categories and N items. Pro lifts both. |

> 日付は必ずロケール準拠のフォーマッタ（`Date.FormatStyle`）を使う。上表の "8/15 に購入" / "Bought Aug 15" は見え方の目安。

## 4. 振る舞い（プロトタイプのロジック）

- 二値トグル: `in_stock ⇄ low`
- 開封 −1: `stockCount = max(0, stockCount - 1)`、`stockCount <= threshold` なら `low`、そうでなければ `in_stock`
- 買った: `status = in_stock`、`lastPurchasedAt = now`、PurchaseLog 追記。カウント方式は `stockCount = max(threshold + 1, stockCount + 2)`（＝購入数のデフォルトは 2、ただし必ず閾値を上回る）
- 追加時のデフォルト: 二値方式、`threshold = 1`、カウント方式なら `stockCount = 2`
- 無料枠: カテゴリ 5 / アイテム 30（仕様書準拠。プロトの 10 はプレビュー用）。超過操作で Paywall を出し、理由テキストを差し替える
- 名前が空のまま追加 → 「新しいアイテム / New item」

## 5. 実装上の注意
- 文言はすべて String Catalog（`.xcstrings`）経由。英語を基準（開発言語）とし ja を翻訳として持つ
- 英語 UI は文字幅が伸びる（"Down to the last one" 等）。ボタンは折返し・`minimumScaleFactor` で崩れないこと
- 状態色は 2 色（セージ / アプリコット）のみ。赤系の警告色を追加しない
