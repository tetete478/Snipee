# ユーザーステータス報告（スプシへのバージョン送信）実装確認

## 調査1: Electron版（Windows）

### 実行タイミング

`startApp()` 内で1回呼ばれる（アプリ起動時のみ）。

| 呼び出し箇所 | ファイル | 行番号 |
|-------------|---------|--------|
| `userReportService.report()` | `app/main.js` | 340 |
| `require('./services/user-report-service')` | `app/main.js` | 31 |

Mac版のような定期実行（1時間ごと）は **実装されていない**。

### report() 関数の処理フロー

**ファイル:** `app/services/user-report-service.js` (行6-21)

1. `googleAuth.getUserEmail()` でメールアドレスを取得（行8）
2. `app.getVersion()` でアプリバージョンを取得（行11）
3. `personalStore.get('snippets', [])` で個別スニペット一覧を取得（行12）
4. `store.get('masterSnippets', { snippets: [] })` でマスタスニペット一覧を取得（行13-14）
5. 個別 + マスタ の合計スニペット数を算出（行15）
6. `sheetsApi.updateUserStatus(email, version, snippetCount)` を呼び出し（行17）

### updateUserStatus() 関数の処理フロー

**ファイル:** `app/services/google-sheets-service.js` (行61-101)

1. `getSheets()` で認証済みGoogle Sheets APIクライアントを取得（行62）
2. `メンバーリスト!B:B` を取得し、メールアドレスで行番号を検索（行66-80）
3. 現在日時を `yyyy-MM-dd HH:mm` 形式にフォーマット（行84-85）
4. `メンバーリスト!E{行番号}:G{行番号}` に `[version, lastActive, snippetCount]` を書き込み（行87-94）

### 送信項目

| 項目 | 書き込み列 | 取得方法 | ファイル | 行番号 |
|------|-----------|---------|---------|--------|
| バージョン | E列 | `app.getVersion()` | user-report-service.js | 11 |
| 最終起動日時 | F列 | `new Date()` → `yyyy-MM-dd HH:mm` | google-sheets-service.js | 84-85 |
| スニペット数 | G列 | 個別 + マスタの合計 | user-report-service.js | 15 |

### OS種別の送信

**送信していない。** バージョン・日時・スニペット数の3項目のみ。Mac/Windowsの区別なし。

### SpreadsheetIDの取得元

**環境変数:** `process.env.SPREADSHEET_ID`

| 使用箇所 | ファイル | 行番号 |
|---------|---------|--------|
| `getMemberList()` | google-sheets-service.js | 15 |
| `getDepartmentSettings()` | google-sheets-service.js | 40 |
| `updateUserStatus()` — B列検索 | google-sheets-service.js | 67 |
| `updateUserStatus()` — E-G列更新 | google-sheets-service.js | 88 |

`.env` ファイルの読み込み: `app/main.js` 行34
```javascript
require('dotenv').config({ path: path.join(__dirname, '..', '.env'), quiet: true });
```

### 関数一覧

| 関数名 | ファイル | 行番号 | 説明 |
|--------|---------|--------|------|
| `report()` | user-report-service.js | 6 | メイン実行関数 |
| `updateUserStatus(email, version, snippetCount)` | google-sheets-service.js | 61 | スプシ更新処理 |
| `getSheets()` | google-sheets-service.js | 4 | 認証済みAPIクライアント取得 |
| `getUserEmail()` | google-auth-service.js | （呼び出し元） | メールアドレス取得 |

---

## 調査2: Mac版（Swift）

### 実行タイミング

`performSync()` 内で呼ばれる。起動時 + 1時間ごとに自動実行。

| 呼び出し箇所 | ファイル | 行番号 |
|-------------|---------|--------|
| `UserReportService.shared.reportUserStatus()` | AppDelegate.swift | 261 |
| `performSync()` | AppDelegate.swift | 254-266 |
| `setupAutoSync()` | AppDelegate.swift | 240-252 |

**定期実行:** `syncTimer` で3600秒（1時間）ごと（AppDelegate.swift 行249-251）

### reportUserStatus() 関数の処理フロー

**ファイル:** `UserReportService.swift` (行18-)

1. `GoogleAuthService.shared.getAccessToken()` でアクセストークン取得（行21）
2. `findUserRowAndUpdate()` でB列を検索し行番号を特定（行33-59）
3. `updateUserRow()` でE-G列にデータ書き込み（行61-88）

### 送信項目

| 項目 | 書き込み列 | 取得方法 | ファイル | 行番号 |
|------|-----------|---------|---------|--------|
| バージョン | E列 | `Constants.App.version`（`CFBundleShortVersionString`） | UserReportService.swift | 69 |
| 最終起動日時 | F列 | `formatCurrentDateTime()` → `yyyy-MM-dd HH:mm` | UserReportService.swift | 92-97 |
| 個別スニペット数 | G列 | `countPersonalSnippets()` | UserReportService.swift | 99-102 |

### OS種別の送信

**送信していない。** Electron版と同じ3項目のみ。

### SpreadsheetIDの取得元

**ハードコード:** `UserReportService.swift` 行11

```swift
private let spreadsheetId = "1IIl0mE96JZwTj-M742DVmVgBLIH27iAzT0lzrpu7qbM"
```

なお、`GoogleSheetsService.swift` 行11 にも同一IDがハードコードされている。

### API呼び出し方法

| 操作 | HTTPメソッド | URL | ファイル | 行番号 |
|------|------------|-----|---------|--------|
| B列検索 | GET | `spreadsheets/{id}/values/メンバーリスト!B:B` | UserReportService.swift | 36 |
| E-G列更新 | PUT | `spreadsheets/{id}/values/メンバーリスト!E{row}:G{row}?valueInputOption=USER_ENTERED` | UserReportService.swift | 64 |

### 関数一覧

| 関数名 | ファイル | 行番号 | 説明 |
|--------|---------|--------|------|
| `reportUserStatus()` | UserReportService.swift | 18 | メイン実行関数 |
| `findUserRowAndUpdate()` | UserReportService.swift | 33 | メール検索＆更新 |
| `updateUserRow()` | UserReportService.swift | 61 | E-G列にデータ更新 |
| `formatCurrentDateTime()` | UserReportService.swift | 92 | 日時フォーマット |
| `countPersonalSnippets()` | UserReportService.swift | 99 | スニペット数カウント |
| `performSync()` | AppDelegate.swift | 254 | 同期メイン関数（呼び出し元） |
| `setupAutoSync()` | AppDelegate.swift | 240 | 定期実行セットアップ |

---

## 調査3: スプレッドシートの列構成

### 「メンバーリスト」シートの推定列構成

| 列 | 項目名 | 読み取り | 書き込み（Electron版） | 書き込み（Mac版） |
|----|--------|---------|---------------------|-----------------|
| A | 名前 | ✅ `getMemberList()` | — | — |
| B | メールアドレス | ✅ `getMemberList()` / 行検索 | — | — |
| C | 部署 | ✅ `getMemberList()` | — | — |
| D | ロール | ✅ `getMemberList()` | — | — |
| E | バージョン | — | ✅ `app.getVersion()` | ✅ `Constants.App.version` |
| F | 最終起動日時 | — | ✅ `yyyy-MM-dd HH:mm` | ✅ `yyyy-MM-dd HH:mm` |
| G | スニペット数 | — | ✅ 個別+マスタ合計 | ✅ 個別のみ |

**根拠:**
- A-D列: `google-sheets-service.js` 行14-30 の `getMemberList()` で `A:D` を読み取り
- E-G列: 両版とも `E{row}:G{row}` に `[version, lastActive, snippetCount]` を書き込み

---

## Mac版 vs Electron版 差分まとめ

| 項目 | Electron版 | Mac版 | 差分 |
|------|-----------|-------|------|
| **実行タイミング** | 起動時のみ（1回） | 起動時 + 1時間ごと | ⚠️ Electron版は定期実行なし |
| **E列: バージョン** | `app.getVersion()` | `CFBundleShortVersionString` | 同等 |
| **F列: 最終起動日時** | `new Date()` → `yyyy-MM-dd HH:mm` | `DateFormatter` → `yyyy-MM-dd HH:mm` | 同等 |
| **G列: スニペット数** | 個別 + マスタの合計 | 個別のみ | ⚠️ カウント方法が異なる |
| **OS種別送信** | なし | なし | 両方とも未対応 |
| **SpreadsheetID** | 環境変数 `process.env.SPREADSHEET_ID` | ハードコード | ⚠️ 管理方法が異なる |
| **エラーハンドリング** | `console.error` 出力 | サイレント（エラー無視） | 差異あり |
| **API呼び出し** | `googleapis` npm パッケージ | 直接HTTP（URLSession） | 実装方法の違い |

---

## ⚠️ 要確認事項

### 1. スニペット数のカウント方法の不一致

- **Electron版** (`user-report-service.js` 行15): `personalSnippets.length + masterSnippets.length` — **個別 + マスタの合計**
- **Mac版** (`UserReportService.swift` 行99-102): `countPersonalSnippets()` — **個別のみ**

同一ユーザーが同じスニペット構成でもMac版とElectron版でG列の値が異なる。

### 2. 定期実行の有無

- **Mac版:** 1時間ごとに `performSync()` → `reportUserStatus()` が実行される
- **Electron版:** `startApp()` 内の1回のみ。長時間起動していても最終起動日時は更新されない

### 3. OS種別の識別不可

両版とも OS種別を送信していないため、スプレッドシート上で同一ユーザーがMacとWindowsどちらで起動したか判別できない。

### 4. SpreadsheetID管理方法の不統一

- **Mac版:** ソースコードにハードコード（`UserReportService.swift` 行11, `GoogleSheetsService.swift` 行11）
- **Electron版:** 環境変数（`.env` ファイル経由）

---

## 参照ファイル一覧

### Electron版

| ファイル | 主な関数 | 行番号 |
|---------|---------|--------|
| `app/services/user-report-service.js` | `report()` | 6-21 |
| `app/services/google-sheets-service.js` | `updateUserStatus()` | 61-101 |
| | `getSheets()` | 4-8 |
| | `getMemberList()` | 10-33 |
| `app/main.js` | `userReportService.report()` 呼び出し | 340 |
| | `require('dotenv').config(...)` | 34 |

### Mac版

| ファイル | 主な関数 | 行番号 |
|---------|---------|--------|
| `SnipeeMac/.../Services/UserReportService.swift` | `reportUserStatus()` | 18 |
| | `findUserRowAndUpdate()` | 33-59 |
| | `updateUserRow()` | 61-88 |
| | `formatCurrentDateTime()` | 92-97 |
| | `countPersonalSnippets()` | 99-102 |
| `SnipeeMac/.../App/AppDelegate.swift` | `performSync()` | 254-266 |
| | `setupAutoSync()` | 240-252 |
| `SnipeeMac/.../Services/GoogleSheetsService.swift` | `fetchMemberSheet()` | 30 |
