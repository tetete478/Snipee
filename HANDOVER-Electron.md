# Snipee HANDOVER — Electron (Windows)

**最終更新**: 2026-02-09

---

## 🚩 現在地

### やっていること
Electron版 main.js のリファクタリング。Phase 0〜4 のロードマップに沿って進行中。

### 完了済み
- Phase 0: ファイルリネーム（Mac命名規則に統一） ✅
- Phase 1: モデル6ファイル作成 ✅
- Phase 2: constants.js作成 ✅
- Phase 3: サービス6本抽出（storage, paste, sync, user-report, import-export, promotion） ✅
- Phase 4 Step 1: appState集約 + main.js変換（1,922行→1,464行） ✅
  - `/home/claude/main.js` として生成済み → `app/main.js` に差し替えが必要

### 今ここ → Phase 4 Step 2: IPCハンドラ分離
main.jsに残っている約67個のIPCハンドラを8ファイルに分割する作業。**まだ未着手**。ユーザーに進め方を提案した段階で中断。

分割計画：
| ファイル | IPC数 | 内容 |
|---------|-------|------|
| `ipc/clipboard-handlers.js` | ~8 | 履歴, ピン, コピー, ペースト |
| `ipc/snippet-handlers.js` | ~15 | マスタ/個別スニペットCRUD |
| `ipc/settings-handlers.js` | ~10 | ホットキー, テーマ, 表示設定 |
| `ipc/window-handlers.js` | ~10 | hide, show, resize, editor |
| `ipc/auth-handlers.js` | ~8 | login, logout, member |
| `ipc/admin-handlers.js` | ~8 | 部署, 権限, XML |
| `ipc/update-handlers.js` | ~5 | バージョン, アップデート |
| `ipc/sync-handlers.js` | ~3 | 同期, マスタURL |

### 必要なファイル
作業を再開するには `app/main.js`（最新版）が必要。Phase 4 Step 1で生成した新main.js（1,464行、appState使用版）が適用されているか要確認。

### 作成済みファイル一覧（Phase 0〜4で新規作成）
```
app/app-state.js
app/models/snippet.js
app/models/history-item.js
app/models/app-settings.js
app/models/department.js
app/models/member.js
app/models/user-status.js
app/utilities/constants.js
app/services/storage-service.js
app/services/paste-service.js
app/services/sync-service.js
app/services/user-report-service.js
app/services/snippet-import-export-service.js
app/services/snippet-promotion-service.js
```

---

## 進め方の方針

- コードはすぐに書き換えない → まず改善案を出して許可をもらう
- 修正箇所が少なければ修正前/修正後のマークダウンで指示
- 完全なコード生成後は自身で検証ステップを入れる
- str_replace方式で差分修正（ファイル全体書き換えは避ける）

---

## 📋 プロジェクト概要

Snipeeはクリップボード履歴とスニペット管理ツール。チームで共有できるマスタスニペットと個人用スニペットを使い分けられる。

- **Windows版**: Electron（本ドキュメントの対象）
- **Mac版**: Swift/SwiftUI（SnipeeMac）
- **iOS版**: Swift/SwiftUI（SnipeeIOS）+ カスタムキーボード

---

## ⚠️ 絶対やってはいけないこと

### 1. ❌ 複数ウィンドウIPC通信（Electron）

**失敗**: サブメニュー用に別ウィンドウ作成 → フリーズ
**解決**: 単一HTML内でインライン表示

### 2. ❌ 同期処理で重い操作

**失敗**: 起動時にGoogle Drive同期を同期実行 → 起動に1分
**解決**: ホットキー登録を最優先、同期は非同期

### 3. ❌ デフォルトホットキーで競合

**解決**: 修飾キー2つ以上使う（Cmd+Ctrl+C等）

### 4. ❌ CLIENT_SECRETをPublicリポジトリに公開

**対策**: .envに分離 + .gitignore + GCP「内部」設定

### 6. ❌ Google Drive APIで共有ドライブを忘れる

**失敗**: 404エラーでアップロード失敗
**解決**: `supportsAllDrives=true` パラメータを追加

### 12. ❌ Electronリファクタリングで一度に全ファイル書き換え

**失敗**: 大規模変更で不具合の原因特定が困難
**解決**: フェーズ分割＋各フェーズ後に検証。str_replaceで差分修正。

### 13. ❌ Electron clipboardHistoryを単純export

**失敗**: filter/splice/unshiftなど直接再代入が多く、外部モジュール化するとmain.js側で参照が切れる
**解決**: appState.clipboard.historyとして共有オブジェクト内に保持

---

## 📊 機能対応表

| 機能                         | Windows (Electron) | Mac (Swift) | iOS (Swift) |
| ---------------------------- | :----------------: | :---------: | :---------: |
| クリップボード履歴           |         ✅         |     ✅      |     ❌      |
| 履歴ピン留め                 |         ✅         |     ✅      |     ❌      |
| 履歴フォルダ分け表示         |         ✅         |     ✅      |     ❌      |
| スニペット表示               |         ✅         |     ✅      |     ✅      |
| スニペット編集               |         ✅         |     ✅      |     ❌      |
| フォルダ管理                 |         ✅         |     ✅      |     ✅      |
| ホットキー起動               |         ✅         |     ✅      |     ❌      |
| ホットキーカスタマイズ       |         ✅         |     ✅      |     ❌      |
| 自動ペースト                 |         ✅         |     ✅      |     ❌      |
| カスタムキーボード           |         ❌         |     ❌      |     ✅      |
| Google OAuth（PKCE）         |         ✅         |     ✅      |     ✅      |
| メンバー認証（スプシ）       |         ✅         |     ✅      |     ✅      |
| マスタ同期                   |         ✅         |     ✅      |     ✅      |
| マスタアップロード           |         ✅         |     ✅      |     ❌      |
| 他部署マスタ参照             |         ✅         |     ✅      |     ❌      |
| 自動アップデート             |         ✅         |     ✅      |     ✅      |
| 日次自動アップデートチェック |         ✅         |     ✅      |     ❌      |
| XMLインポート/エクスポート   |         ✅         |     ✅      |     ❌      |
| 管理者機能                   |         ✅         |     ✅      |     ❌      |
| オンボーディング             |         ✅         |     ✅      |     ✅      |
| オンボーディング内ログイン   |         ✅         |     ✅      |     ✅      |
| テーマ切り替え               |         ✅         |     ✅      |     ❌      |
| ウィンドウドラッグ           |         ✅         |     ✅      |     ❌      |
| カーソルループ               |         ✅         |     ✅      |     ❌      |
| 確認ダイアログ               |         ✅         |     ✅      |     ✅      |
| 自動保存                     |         ✅         |     ✅      |     ❌      |
| 変数置換（16種）             |         ✅         |     ✅      |     ✅      |
| ユーザーステータス報告       |         ✅         |     ✅      |     ❌      |
| 履歴最大件数設定             |         ✅         |     ✅      |     ❌      |
| ドメイン制限（hd）           |         ✅         |     ✅      |     ❌      |

---

## 🪟 Electron版 詳細機能

### オンボーディング（welcome.html）

- **5ステップ構成**（Mac版と統一）:
  1. ようこそ（機能紹介）
  2. Googleログイン（必須・スキップ不可）
  3. メンバー認証（スプシ照合）
  4. 名前入力
  5. 完了
- **ログイン必須**: ログインしないと次へ進めない
- **メンバー認証**: スプシのメンバーリストで確認
- **ドメイン制限**: `@team.addness.co.jp` のみ許可

### 自動アップデート（electron-updater）

- **GitHub Releases使用**
- **日次自動チェック**: 1日1回、起動時に確認（24時間間隔）
- **手動チェック**: 設定から「アップデートを確認」
- **NSISインストーラー形式**

### OAuth認証

- **PKCE (S256) 方式**（Mac版と統一）
- **ドメイン制限**: `hd: 'team.addness.co.jp'`
- **ログインヒント**: `login_hint: '@team.addness.co.jp'`
- **localhostコールバック**: `http://localhost:8085/callback`

### クリップボード履歴

- **自動監視**: 500msインターバル
- **最大件数**: 設定で変更可能（デフォルト100件）
- **ピン留め**: 重要な履歴を固定
- **自動同期**: 2時間ごとにマスタスニペット同期

### スニペット管理

- **マスタスニペット**: Google Driveから同期（読み取り専用）
- **個人スニペット**: electron-storeで永続化
- **フォルダ管理**: 作成、名前変更、削除、並び替え
- **自動保存**: 0.3秒デバウンスで自動保存
- **他部署マスタ参照**: 読み取り専用で閲覧可能

### 変数置換（16種）

- `{名前}`, `{今日}`, `{明日}`, `{明後日}`, `{昨日}`, `{一昨日}`
- `{時刻}`, `{曜日}`, `{年}`, `{月}`, `{日}`
- `{来週の月曜}`, `{今週の月曜}`, `{今週の金曜}`
- `{来月1日}`, `{カーソル}`

### ホットキー

- **メイン（Ctrl+Alt+C）**: 履歴+スニペット一覧
- **スニペット（Ctrl+Alt+V）**: スニペットのみ
- **履歴（Ctrl+Alt+X）**: 履歴のみ
- **カスタマイズ可能**: 設定で変更可能

### ユーザーステータス報告

- 起動時にスプシへバージョン・最終起動・スニペット数を送信
- サイレント実行（エラー時も通知なし、Mac版と同じ）

### 管理者機能

- **権限**: スプシで「管理者」「最高管理者」に設定
- **マスタアップロード**: 個人スニペットをGoogle Driveにアップロード
- **共有ドライブ対応**: `supportsAllDrives=true`

---

## 🔧 リファクタリング状況

### 概要

main.js を1,922行のモノリシック構造から分割。Mac版の45ファイル構成を参考に、Electronの制約を考慮した構造へ。

### 完了フェーズ

| フェーズ | 内容 | 状態 |
|---------|------|------|
| Phase 0 | ファイルリネーム（Mac命名規則に統一） | ✅ |
| Phase 1 | モデル作成（6ファイル） | ✅ |
| Phase 2 | constants.js 作成 | ✅ |
| Phase 3 | サービス抽出（6サービス） | ✅ |
| Phase 4 Step 1 | appState集約 + main.js変換 | ✅ |
| Phase 4 Step 2 | IPCハンドラ分離 | 🔄 次 |

### 削減効果

- main.js: **1,922行 → 1,464行**（-458行、24%削減）
- 新規ファイル: **14ファイル**追加

### Phase 4 Step 2 計画（IPCハンドラ分離）

| ファイル | IPC数 | 内容 |
|---------|-------|------|
| `ipc/clipboard-handlers.js` | ~8 | 履歴, ピン, コピー, ペースト |
| `ipc/snippet-handlers.js` | ~15 | マスタ/個別スニペットCRUD |
| `ipc/settings-handlers.js` | ~10 | ホットキー, テーマ, 表示設定 |
| `ipc/window-handlers.js` | ~10 | hide, show, resize, editor |
| `ipc/auth-handlers.js` | ~8 | login, logout, member |
| `ipc/admin-handlers.js` | ~8 | 部署, 権限, XML |
| `ipc/update-handlers.js` | ~5 | バージョン, アップデート |
| `ipc/sync-handlers.js` | ~3 | 同期, マスタURL |

---

## 📁 ファイル構成

```
electron/app/
├── main.js                          # メインプロセス（1,464行）IPCハンドラ、ウィンドウ管理
├── app-state.js                     # 共有状態（windows参照、clipboard履歴）
├── models/
│   ├── snippet.js                   # Snippet/SnippetFolder/SnippetType
│   ├── history-item.js              # HistoryItem（id, content, timestamp, type, isPinned）
│   ├── app-settings.js              # SettingsKeys定数 + DefaultSettings
│   ├── department.js                # Department（id, name, xmlFileId）
│   ├── member.js                    # Member + MemberRole enum
│   └── user-status.js               # UserStatus報告用
├── services/
│   ├── google-auth-service.js       # OAuth認証（PKCE）、トークン管理
│   ├── google-drive-service.js      # Drive API（XMLダウンロード/アップロード）
│   ├── google-sheets-service.js     # Sheets API（メンバー認証、ステータス更新）
│   ├── member-manager.js            # メンバー管理（認証→キャッシュ）
│   ├── variable-service.js          # 変数置換（16種）
│   ├── storage-service.js           # electron-store（store + personalStore）
│   ├── paste-service.js             # Windows API経由の自動ペースト（koffi）
│   ├── sync-service.js              # マスタスニペット同期、自動同期タイマー
│   ├── user-report-service.js       # ユーザーステータス報告
│   ├── snippet-import-export-service.js  # XMLインポート/エクスポート
│   └── snippet-promotion-service.js # マスタ昇格（管理者→Drive）
├── theme/
│   ├── common.css                   # 共通スタイル
│   └── variables.css                # CSSカスタムプロパティ（テーマ）
├── utilities/
│   ├── constants.js                 # 定数（UI, クリップボード, 同期, 更新, Windows API）
│   ├── drag-drop.js                 # ドラッグ&ドロップ
│   ├── theme.js                     # テーマ切り替え
│   └── utils.js                     # 汎用ユーティリティ
└── views/
    ├── index.html                   # メインポップアップ（履歴+スニペット）
    ├── snippets.html                # スニペット専用ポップアップ
    ├── history.html                 # 履歴専用ポップアップ
    ├── snippet-editor.html          # スニペットエディタ
    ├── settings.html                # 設定画面
    ├── welcome.html                 # オンボーディング（5ステップ）
    └── login.html                   # ログイン画面
```

---

## 🔧 ビルド・リリース

```bash
# 開発
cd ~/Desktop/Snipee/electron
npm run dev

# リリース（GitHub Actions）
git tag win-v2.0.1
git push origin win-v2.0.1
```

---

## 🔄 プラットフォーム差分（残課題）

### Mac独自 → Electron移植TODO（6件）

| # | 機能 | 重要度 |
|---|------|--------|
| 1 | スニペット昇格/降格 | 中 |
| 2 | フォルダ昇格/降格 | 中 |
| 3 | 履歴グループ分け表示（15件×時系列） | 低 |
| 4 | Pキーでピン留めトグル | 低 |
| 5 | エディタ前後スニペット移動（Cmd+↑↓相当） | 低 |
| 6 | バックアップ復元UI | 中 |

### プラットフォーム固有（変更不要）

- **ペースト遅延**: 固定20ms（Mac版と方式が違うがOK）
- **autoLogin**: 常に自動ログイン試行（変更不要）
- **マウスオーバー自動クローズ**: 150ms遅延
- **ホットキー**: Ctrl+Alt+C/V/X
- **認証フロー**: localhost HTTPコールバック
- **管理者機能**: 設定画面の独立タブ

### Windows改善（完了済み、記録）

| # | 機能 | 差分の詳細 |
|---|------|------------|
| 11 | 自動同期間隔 | ~~2時間~~ → 1時間に修正 |
| 12 | 個人スニペットバックアップ | 保存前にbackup追加済み |
| 13 | スコープバージョン管理 | scopeVersion=3チェック＆自動ログアウト追加済み |
| 14 | 他部署マスタ閲覧 | snippet-editor.htmlに他部署閲覧UI追加済み |
| 15 | ログイン時起動設定 | settings.htmlにトグルUI、main.jsにIPCハンドラー追加済み |
| 16 | 変数一覧ヘルプ | settings.htmlにヘルプタブ追加済み（変数一覧＋ホットキー一覧） |
| 17 | 設定タブ構成 | ヘルプタブ追加でMacと近い構成に |
| 18 | ユーザーステータス報告 | マスタ＋個別合計に修正済み |
| 19 | 日次アップデートチェック | ~~60秒~~ → 2秒に修正済み |

---

## 🔄 クラウド同期計画

### 現状（Electronの個別スニペット保存）

| 項目 | 内容 |
|------|------|
| **保存先** | electron-store (`personal-snippets.json`) |
| **キー** | `folders` + `snippets`（分離） |
| **形式** | JSON（フォルダとスニペットが別キー） |
| **バックアップ** | `folders_backup` + `snippets_backup`（1世代） |
| **保存トリガー** | IPC経由で即時保存 |

### 共通仕様

#### 保存先
```
各ユーザーのマイドライブ/
├── Snipee_データ/                    ← 同期用フォルダ
│   └── personal_snippets.json       ← 個別スニペットデータ
└── Snipee_バックアップ/              ← 将来実装：バックアップ用フォルダ
```

**フォルダ管理方式**: Google Drive の `appDataFolder`（隠しフォルダ）は使わず、ユーザーのマイドライブに `Snipee_データ` フォルダを作成。理由:
- ユーザーが手動でバックアップ確認可能
- デバッグが容易
- `drive.file` スコープで操作可能

#### JSON スキーマ

```json
{
  "version": 1,
  "lastModified": "2026-02-05T10:30:00.000Z",
  "deviceId": "mac-xxxxx",
  "folders": [
    {
      "id": "uuid-string",
      "name": "フォルダ名",
      "order": 0,
      "snippets": [
        {
          "id": "uuid-string",
          "title": "スニペットタイトル",
          "content": "スニペット内容",
          "description": "",
          "order": 0,
          "createdAt": "2026-01-01T00:00:00.000Z",
          "updatedAt": "2026-02-05T10:30:00.000Z"
        }
      ]
    }
  ],
  "deleted": [
    {
      "id": "uuid-string",
      "deletedAt": "2026-02-05T10:00:00.000Z"
    }
  ]
}
```

**フィールド説明**:

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| version | Int | ✅ | スキーマバージョン（将来の互換用） |
| lastModified | ISO8601 | ✅ | 最終更新日時（マージ判定用） |
| deviceId | String | ✅ | 更新元デバイスの識別子（デバッグ用） |
| folders | Array | ✅ | フォルダ＋スニペット階層 |
| deleted | Array | ✅ | 削除済みID一覧（墓標、30日保持後自動削除） |

**ID方式**: UUID文字列に統一（Windows版のhash方式は移行時にUUIDへ変換）

#### マージロジック

```
同期実行時:
1. クラウドからJSON取得 (remote)
2. ローカルのJSON取得 (local)
3. マージ処理:
   a. remote.deleted に含まれるIDをlocalから削除
   b. local.deleted に含まれるIDをremoteから削除
   c. 両方に存在するスニペット → updatedAt が新しい方を採用
   d. localのみに存在 → クラウドに追加
   e. remoteのみに存在 → ローカルに追加
   f. フォルダ名の変更 → updatedAt が新しい方を採用
4. マージ結果をローカル保存 + クラウドにアップロード
```

**競合解決ルール**:
- **Last-Writer-Wins**: `updatedAt` が新しい方が勝つ
- **削除優先**: deleted リストに入っていれば、相手側のupdatedAtに関係なく削除
- **フォルダ競合**: 同名フォルダは同一とみなしマージ

#### 同期タイミング

| タイミング | 方式 | 説明 |
|-----------|------|------|
| アプリ起動時 | ダウンロード → マージ | 最新状態を取得 |
| 保存時 | デバウンス付きアップロード（5秒） | 頻繁な保存を抑制 |
| 定期 | 30分ごと（バックグラウンド） | 他デバイスの変更を取得 |
| 手動 | 同期ボタン | ユーザー操作 |

#### 削除の扱い

- ローカルで削除 → `deleted` 配列にIDと日時を追加
- 次回同期時にクラウドの `deleted` 配列にもマージ
- 30日経過した `deleted` エントリは自動クリーンアップ
- 全デバイスで削除が反映されたことを保証するため、30日間墓標を保持

#### エラー時の挙動

| エラー | 対応 |
|--------|------|
| オフライン | ローカル保存のみ。次回オンライン時に同期 |
| API失敗（一時的） | 3回リトライ（1秒、3秒、10秒間隔）、失敗後はローカル保存 |
| トークン期限切れ | リフレッシュトークンで自動更新。失敗時は再ログイン要求 |
| ファイル未存在（404） | 新規作成フローにフォールバック |
| 容量不足 | エラー通知を表示 |

### Windows版の実装計画

#### 変更が必要なファイル

| ファイル | 変更内容 | 規模 |
|---------|----------|------|
| `app/services/google-drive-service.js` | ファイル検索(`files.list`)、メタデータ取得追加 | 小 |
| `app/services/personal-sync-service.js` | **新規作成**: 個別スニペット同期サービス | 大 |
| `app/main.js` | 同期IPCハンドラー追加、保存時の同期トリガー | 中 |
| `app/models/snippet.js` | `createdAt`, `updatedAt` フィールド追加 | 小 |
| `app/services/storage-service.js` | 同期用データ形式の変換関数追加 | 小 |
| `app/views/settings.html` | 同期状態表示UI追加 | 小 |

#### 追加する関数

**google-drive-service.js**:
```javascript
async function findFile(name, parentFolderId)     // files.list でファイル検索
async function getFileMetadata(fileId)             // files.get でメタデータ取得
async function findOrCreateFolder(name)            // Snipeeフォルダ検索/作成
```

**personal-sync-service.js** (新規):
```javascript
async function syncPersonalSnippets()              // メイン同期関数
async function downloadPersonalData()              // クラウドからダウンロード
async function uploadPersonalData(data)            // クラウドにアップロード
function mergeData(local, remote)                  // マージロジック
async function ensureSyncFile()                    // 同期ファイル存在確認/作成
function startAutoSync(intervalMs)                 // 定期同期開始
function stopAutoSync()                            // 定期同期停止
```

#### 既存コードの修正箇所

**main.js**:
- `save-personal-snippets` ハンドラー (行883): 保存後に同期トリガー追加
- `save-personal-folders` ハンドラー (行876): 同上
- `startApp()` (行286): 起動時同期追加
- 新規IPC: `sync-personal-snippets`, `get-personal-sync-status`

**snippet.js**:
- `constructor`: `createdAt`, `updatedAt` デフォルト値追加（`new Date().toISOString()`）
- `generateId`: 新規スニペットはUUID生成に変更

### Windows版ID移行

Windows版は現在 `hash(folder+title+content)` でIDを生成しているため、内容変更でIDが変わる。

**移行方針**:
1. 移行時に全スニペットにUUID IDを付与
2. `legacyId` フィールドに旧IDを保持（1回限りの互換）
3. 以降はUUIDで管理

### Phase 7: Windows版対応

**目的**: Windows版に同期機能を追加

**対象**: Windows版 `personal-sync-service.js`

**前提条件**: main.js リファクタリング完了後に実施

**実装内容**: Mac版のロジックをJavaScriptに移植

### Drive API呼び出し詳細

#### Snipee_データフォルダ検索
```
GET https://www.googleapis.com/drive/v3/files
  ?q=name='Snipee_データ' and mimeType='application/vnd.google-apps.folder' and trashed=false
  &spaces=drive
  &fields=files(id,name)
  &supportsAllDrives=true
```

#### Snipee_データフォルダ作成
```
POST https://www.googleapis.com/drive/v3/files
  ?supportsAllDrives=true
Content-Type: application/json

{
  "name": "Snipee_データ",
  "mimeType": "application/vnd.google-apps.folder"
}
```

#### personal_snippets.json 検索

```
GET https://www.googleapis.com/drive/v3/files
  ?q=name='personal_snippets.json' and '{folderId}' in parents and trashed=false
  &spaces=drive
  &fields=files(id,name,modifiedTime)
  &supportsAllDrives=true
```

#### personal_snippets.json 作成

```
POST https://www.googleapis.com/upload/drive/v3/files
  ?uploadType=multipart
  &supportsAllDrives=true
Content-Type: multipart/related; boundary=boundary

--boundary
Content-Type: application/json

{"name": "personal_snippets.json", "parents": ["{folderId}"], "mimeType": "application/json"}
--boundary
Content-Type: application/json

{JSONデータ}
--boundary--
```

#### personal_snippets.json 更新

```
PATCH https://www.googleapis.com/upload/drive/v3/files/{fileId}
  ?uploadType=media
  &supportsAllDrives=true
Content-Type: application/json
Authorization: Bearer {token}

{JSONデータ}
```

#### personal_snippets.json ダウンロード

```
GET https://www.googleapis.com/drive/v3/files/{fileId}
  ?alt=media
  &supportsAllDrives=true
Authorization: Bearer {token}
```

### リスクと注意点

#### 競合発生時の対応

| 競合パターン | 対応 |
|-------------|------|
| 同じスニペットを2デバイスで編集 | Last-Writer-Wins（updatedAtが新しい方） |
| 片方で削除、片方で編集 | 削除が優先（deleted リストにIDがあれば削除） |
| 同名フォルダを2デバイスで作成 | IDが異なれば別フォルダとして保持 |
| 同時アップロード | 後からアップロードした方が勝つ（Drive APIの仕様） |

**データロス防止策**:
- ローカルバックアップは従来通り保持
- 同期前に必ずローカルのスナップショットを保存
- `deleted` から復元可能な期間は30日間

#### API制限への対策

| 制限 | 値 | 対策 |
|------|-----|------|
| Drive API 日次クォータ | 10億回/日（プロジェクト全体） | 問題なし |
| Drive API ユーザー毎 | 12,000回/分 | 問題なし |
| ファイルサイズ | 5TB | 問題なし（JSONは数MB以下） |
| rate limit (429) | 可変 | エクスポネンシャルバックオフで3回リトライ |
| 無料アカウント容量 | 15GB | JSONファイル1つなので影響なし |

#### セキュリティ

| リスク | 対策 |
|--------|------|
| マイドライブ上のJSONが他者に見える | ファイル共有設定は本人のみ（デフォルト） |
| トークン漏洩 | Mac版のUserDefaults保存をKeychain化推奨 |
| スコープ過剰 | `drive.file` への統一を推奨（Phase 1で対応） |

---

## 🚨 未解決の問題

### #9 パスワード→権限管理統一

着手中断。2/4のチャットで作業開始したが中断。

---

## 🗓️ TODO / ロードマップ

### 🔴 最優先
- Phase 4 Step 2: IPCハンドラ分離
- Phase 5: main.js最終整理（目標500行以下）

### 🟡 差分埋め
- Mac独自6件の移植

### 🟢 将来
- クラウド同期（Phase 7、リファクタ完了後）
- タグ機能、検索機能強化、お気に入り機能

---

## 📚 参考情報

### スプシ構造

**シート1: メンバーリスト**

| スタッフ名 | メールアドレス      | 部署        | 権限       |
| ---------- | ------------------- | ----------- | ---------- |
| 小松晃也   | komatsu@company.com | 営業,マーケ | 最高管理者 |

**シート2: 部署設定**

| 部署 | XMLファイルID |
| ---- | ------------- |
| 営業 | 1ABC123...    |

### デフォルトホットキー

| 機能           | Mac        | Windows    |
| -------------- | ---------- | ---------- |
| メイン         | Cmd+Ctrl+C | Ctrl+Alt+C |
| スニペット専用 | Cmd+Ctrl+V | Ctrl+Alt+V |
| 履歴専用       | Cmd+Ctrl+X | Ctrl+Alt+X |

### Google API スコープ

```
https://www.googleapis.com/auth/userinfo.email
https://www.googleapis.com/auth/spreadsheets
https://www.googleapis.com/auth/drive
```

### 認証フローの違い

**Mac版**:
```
1. システムブラウザでGoogle認証ページを開く
2. カスタムURLスキーム（com.addness.snipeemac:/oauth2callback）でコールバック
3. AppDelegateでURLを受け取りトークン交換
```

**Windows版**:
```
1. Electronウィンドウ内でGoogle認証ページを表示
2. ローカルHTTPサーバー（localhost:8085）でコールバック受信
3. トークン交換後にウィンドウを閉じる
```

### ストレージの違い

| 項目 | Mac版 | Windows版 |
|------|-------|-----------|
| 設定 | UserDefaults | electron-store |
| トークン | UserDefaults | keytar |
| スニペット | UserDefaults | electron-store (personal-snippets) |

---

## 🔄 変更履歴

### 2026-02-03

- **Windows版：Mac版との完全機能統一**
  - オンボーディング5ステップ化（ログイン必須）
  - ホットキーカスタマイズ（履歴ウィンドウ）
  - 自動保存（0.3秒デバウンス）
  - 変数置換16種に拡張（Mac版と完全一致）
  - 他部署マスタ参照
  - 日次自動アップデートチェック（24時間間隔）
  - 履歴最大件数設定
  - ユーザーステータス報告
  - OAuth PKCE移行
- **Windows版：クリティカルバグ3件修正**
  - autoUpdater再有効化（コメントアウト解除）
  - Drive API関数名修正（updateFileContent → uploadFile）
  - ドメイン制限追加（hd パラメータ）
- **Windows版：不要機能の削除**（Mac版の削除に合わせて）
  - ペースト遅延設定UI削除（固定値に戻す）
  - テーマカラー選択UI削除
- **Electronリファクタリング（Phase 0〜4）**
  - サービスファイルリネーム（Mac命名規則に統一）
  - モデル6ファイル作成
  - constants.js作成
  - サービス6本抽出（storage, paste, sync, user-report, import-export, promotion）
  - appState集約（ウィンドウ参照・クリップボード状態を一元管理）
  - main.js: 1,922行 → 1,464行（24%削減）
- **Google APIスコープ変更**
  - `spreadsheets.readonly` → `spreadsheets`（ステータス報告用の書き込み権限）

### 2026-01-24

- **Electron Mac版を完全削除**
  - main.js からMac専用コード削除
  - settings.html, welcome.html のMac条件分岐削除
  - package.json からMacビルド設定削除
  - build.yml から publish-mac ジョブ削除
  - 不要ファイル6個削除
  - GitHub Secrets整理
