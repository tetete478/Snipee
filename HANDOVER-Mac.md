# Snipee HANDOVER — Mac (Swift)

**最終更新**: 2026-02-09

---

## 🚩 現在地

- クラウド同期 Phase 3 途中（PersonalSyncService.swift に着手開始段階）
- 2/5のチャットでMac版の同期エンジン着手

---

## 進め方の方針

- コードはすぐに書き換えない → まず改善案を出して許可をもらう
- 修正箇所が少なければ修正前/修正後のマークダウンで指示
- 完全なコード生成後は自身で検証ステップを入れる
- str_replace方式で差分修正（ファイル全体書き換えは避ける）

---

## 📋 プロジェクト概要

Snipeeはクリップボード履歴とスニペット管理ツール。チームで共有できるマスタスニペットと個人用スニペットを使い分けられる。

- **Mac版**: Swift/SwiftUI（SnipeeMac）— メイン開発プラットフォーム（本ドキュメントの対象）
- **Windows版**: Electron
- **iOS版**: Swift/SwiftUI（SnipeeIOS）+ カスタムキーボード

---

## ⚠️ 絶対やってはいけないこと

### 2. ❌ 同期処理で重い操作

**失敗**: 起動時にGoogle Drive同期を同期実行 → 起動に1分
**解決**: ホットキー登録を最優先、同期は非同期

### 3. ❌ デフォルトホットキーで競合

**解決**: 修飾キー2つ以上使う（Cmd+Ctrl+C等）

### 5. ❌ Swift 6 Strict Concurrency を有効にする

**失敗**: Codable構造体でnonisolatedエラー多発
**解決**: Swift 5 + Minimal設定を維持

### 6. ❌ Google Drive APIで共有ドライブを忘れる

**失敗**: 404エラーでアップロード失敗
**解決**: `supportsAllDrives=true` パラメータを追加

### 7. ❌ appcast XMLをビルド前に更新

**失敗**: DMGが存在しない状態でユーザーがダウンロード試行
**解決**: ビルド完了後にXMLを更新

### 8. ❌ App Sandboxを有効にしたままSparkle使用

**失敗**: 自動インストール時に権限エラー（-60005）
**解決**: App Sandboxを削除（Signing & Capabilities）

### 9. ❌ SwiftUIで@State変数にウィンドウ参照を保持しない

**失敗**: NSWindowがすぐに解放されてウィンドウが表示されない
**解決**: @State private var welcomeWindow: NSWindow? で保持

### 10. ❌ SwiftUIのbodyに.onChange()を大量につけない

**失敗**: コンパイラが型チェックできない（reasonable time エラー）
**解決**: ViewModifierに分離するか、関数に切り出す

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

## 🖥️ Mac版 詳細機能

### オンボーディング（WelcomeView）

- **5ステップ構成**:
  1. ようこそ（機能紹介）
  2. Googleログイン（必須・スキップ不可）
  3. お名前入力
  4. ホットキー説明
  5. 準備完了
- **ログイン必須**: ログインしないと次へ進めない
- **メンバー認証**: スプシのメンバーリストで確認
- **オレンジテーマ**: 全体的にオレンジ色で統一
- **キーボード操作**: Enter=次へ、←→=ステップ移動
- **設定から再表示可能**: 一般タブ「セットアップを再表示」

### 自動アップデート（Sparkle）

- **Sparkle 2.x使用**
- **日次自動チェック**: 1日1回、初回起動時に自動確認
- **ログイン後に開始**: 未ログイン状態ではSparkle未起動
- **手動チェック**: 設定 > 一般 > 「アップデートを確認」
- **appcast URL**: `https://tetete478.github.io/Snipee/appcast-mac.xml`
- **DMG形式**: 署名済み、ノータリゼーション済み

### クリップボード履歴

- **自動監視**: バックグラウンドで常時監視
- **最大件数**: 設定で変更可能（デフォルト100件）
- **ピン留め**: 重要な履歴を固定
- **削除**: 個別削除、全削除（ピン留め以外）

### スニペット管理

- **マスタスニペット**: Google Driveから同期（読み取り専用）
- **個人スニペット**: ローカル保存、自由に編集可能
- **フォルダ管理**: 作成、名前変更、削除、並び替え
- **自動保存**: 編集後0.3秒で自動保存
- **保存インジケーター**: 「保存中...」→「保存完了」表示

### 変数置換

- `{名前}`: ユーザー名
- `{今日}`: 今日の日付
- `{明日}`: 明日の日付
- `{時刻}`: 現在時刻
- `{カーソル}`: ペースト後のカーソル位置

### ホットキー

- **メイン（Cmd+Ctrl+C）**: 履歴+スニペット一覧
- **スニペット（Cmd+Ctrl+V）**: スニペットのみ
- **履歴（Cmd+Ctrl+X）**: 履歴のみ
- **カスタマイズ可能**: 設定で変更可能

### 自動ペースト

- **アクセシビリティ権限必要**
- スニペット選択後、自動でペースト実行
- Bundle IDベースでアプリフォーカス管理

### 設定画面

- **一般タブ**: ユーザー名、履歴件数、ホットキー、リンク、セットアップ再表示、アップデート
- **表示・操作タブ**: テーマ、表示設定
- **アカウントタブ**: ログイン状態、ログアウト
- **ヘルプタブ**: 使い方、FAQ
- **管理者タブ**: マスタアップロード（管理者のみ）

### 管理者機能

- **権限**: スプシで「管理者」「最高管理者」に設定
- **マスタアップロード**: 個人スニペットをGoogle Driveにアップロード
- **共有ドライブ対応**: `supportsAllDrives=true`

### 他部署マスタ参照

- **ツールバーから選択**: 他部署のマスタを閲覧
- **読み取り専用**: 編集不可
- **テキスト選択可能**: コピーは可能

### キーボードナビゲーション

- **↑↓**: アイテム選択
- **←→**: フォルダ移動（設定画面ではタブ移動）
- **Enter**: 選択実行
- **Esc**: ウィンドウを閉じる
- **Cmd+W**: ウィンドウを閉じる
- **Cmd+↑↓**: スニペットエディタでスニペット切り替え
- **Tab**: フォーカス移動

### ウィンドウ管理

- **メニューバーアプリ**: LSUIElement=true
- **左クリック**: メインポップアップ表示
- **右クリック**: コンテキストメニュー
- **ウィンドウドラッグ**: ヘッダー部分でドラッグ可能

---

## 📁 ファイル構成

```
SnipeeMac/SnipeeMac/SnipeeMac/
├── App/
│   └── AppDelegate.swift           # アプリ起動、メニューバー、Sparkle初期化、ホットキー登録
├── Models/
│   ├── AppSettings.swift           # 設定データモデル（履歴件数、ホットキー等）
│   ├── Department.swift            # 部署情報モデル（名前、XMLファイルID）
│   ├── HistoryItem.swift           # クリップボード履歴アイテム（テキスト、ピン留め）
│   ├── Member.swift                # メンバー情報モデル（名前、メール、部署、権限）
│   ├── Snippet.swift               # スニペットモデル（タイトル、内容、フォルダ、タイプ）
│   └── UserStatus.swift            # ユーザーステータス報告用モデル
├── Services/
│   ├── ClipboardService.swift      # クリップボード監視、履歴管理、ピン留め
│   ├── GoogleAuthService.swift     # OAuth認証、トークン管理、Keychain保存
│   ├── GoogleDriveService.swift    # Drive API（XMLダウンロード/アップロード）
│   ├── GoogleSheetsService.swift   # Sheets API（メンバー認証、部署取得）
│   ├── HotkeyService.swift         # グローバルホットキー登録・解除
│   ├── PasteService.swift          # 自動ペースト実行、アクセシビリティ
│   ├── SnippetImportExportService.swift  # XMLインポート/エクスポート処理（未使用）
│   ├── SnippetPromotionService.swift     # スニペット昇格/降格処理（未使用）
│   ├── StorageService.swift        # UserDefaults保存（設定、スニペット、履歴）
│   ├── SyncService.swift           # マスタスニペット同期、メンバー情報キャッシュ
│   ├── UserReportService.swift     # ユーザーステータス報告（スプシへ送信）
│   └── VariableService.swift       # 変数置換（{名前}、{今日}等）
├── Theme/
│   └── ColorTheme.swift            # テーマ定義（Silver、Blue、Orange等）
├── Utilities/
│   ├── Constants.swift             # 定数（API URL、appcast URL等）
│   ├── KeyboardNavigator.swift     # キーボードナビゲーション補助
│   ├── NavigationHelper.swift      # ナビゲーション補助関数
│   └── XMLParserHelper.swift       # XMLパース（Clipy形式対応）、エクスポート
├── Views/
│   ├── Components/
│   │   ├── HotkeyField.swift       # ホットキー入力フィールド
│   │   ├── PopupKeyboardHandler.swift  # ポップアップ共通キーボード処理
│   │   ├── SearchField.swift       # 検索フィールド
│   │   └── ThemePicker.swift       # テーマ選択UI
│   ├── Editor/
│   │   ├── ContentPanel.swift      # スニペット編集パネル（タイトル、内容、説明）
│   │   ├── FolderSidebar.swift     # フォルダ/スニペット一覧サイドバー
│   │   ├── SnippetEditorView.swift # スニペットエディタメイン画面
│   │   └── SnippetEditorWindow.swift   # エディタウィンドウ管理
│   ├── Onboarding/
│   │   └── LoginRequiredView.swift # ログイン必須ダイアログ
│   ├── Popup/
│   │   ├── HistoryPopupView.swift  # 履歴専用ポップアップ
│   │   ├── MainPopupView.swift     # メインポップアップ（履歴+スニペット）
│   │   ├── PopupWindowController.swift # ポップアップウィンドウ制御
│   │   ├── SnippetPopupView.swift  # スニペット専用ポップアップ
│   │   └── SubmenuView.swift       # サブメニュー（フォルダ内スニペット一覧）
│   └── Settings/
│       ├── AccountTab.swift        # アカウントタブ（ログイン状態、ログアウト）
│       ├── AdminTab.swift          # 管理者タブ（マスタアップロード）
│       ├── DisplayTab.swift        # 表示・操作タブ（テーマ設定）
│       ├── GeneralTab.swift        # 一般タブ（ユーザー名、ホットキー等）
│       ├── HelpTab.swift           # ヘルプタブ（使い方、FAQ）
│       ├── SettingsView.swift      # 設定画面メイン（タブ切り替え）
│       └── WelcomeView.swift       # オンボーディング（5ステップ）
├── ContentView.swift               # メインContentView（未使用）
└── SnipeeMacApp.swift              # アプリエントリーポイント
```

---

## 🔧 ビルド・リリース

### Mac版ビルド

```bash
# 開発ビルド
cd ~/Desktop/Snipee/SnipeeMac/SnipeeMac
xcodebuild -scheme SnipeeMac -configuration Debug build

# リリース（GitHub Actions）
git tag mac-v2.0.1
git push origin mac-v2.0.1
```

### appcast更新

ビルド完了後、`docs/appcast-mac.xml` を更新:

```xml
<item>
  <title>Snipee 2.0.1</title>
  <sparkle:version>2.0.1</sparkle:version>
  <sparkle:shortVersionString>2.0.1</sparkle:shortVersionString>
  <pubDate>Sat, 01 Feb 2026 12:00:00 +0900</pubDate>
  <enclosure url="https://github.com/tetete478/Snipee/releases/download/mac-v2.0.1/Snipee-Swift-2.0.1.dmg"
             type="application/octet-stream"/>
</item>
```

---

## 🔄 Mac改善（残課題）

| # | 機能 | 現状 | 重要度 |
|---|------|------|--------|
| 7 | トークン保存 | UserDefaults（平文）→ Keychain化すべき | 高 |
| 8 | Google Driveスコープ | drive（フルアクセス）→ 制限推奨 | 高 |
| 9 | supportsAllDrives | upload時のみ → download時にも追加 | 中 |
| 10 | 部署データ形式 | 単一文字列 → カンマ区切り配列に修正 | 中 |

---

## 🔄 クラウド同期計画

### 現状（Macの個別スニペット保存）

| 項目 | 内容 |
|------|------|
| **保存先** | UserDefaults |
| **キー** | `personal_snippets` |
| **形式** | JSON (`[SnippetFolder]`) |
| **バックアップ** | `personal_snippets_backup`（1世代） |
| **保存トリガー** | 500msデバウンス自動保存、切替時即時保存 |

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

### Mac版の実装計画

#### 変更が必要なファイル

| ファイル | 変更内容 | 規模 |
|---------|----------|------|
| `Services/GoogleDriveService.swift` | `createFile`, `findFile`, `getMetadata` 追加 | 中 |
| `Services/PersonalSyncService.swift` | **新規作成**: 個別スニペット同期サービス | 大 |
| `Services/StorageService.swift` | 同期用save/loadインターフェース追加 | 小 |
| `Models/Snippet.swift` | `createdAt`, `updatedAt` フィールド追加 | 小 |
| `Views/Settings/AccountTab.swift` | 個別スニペット同期状態表示追加 | 小 |
| `Views/Editor/ContentPanel.swift` | 保存時の同期トリガー追加 | 小 |

#### 追加する関数

**GoogleDriveService.swift**:
```swift
func createFile(name: String, content: Data, parentId: String?,
                mimeType: String, completion: ...)
func findFile(name: String, parentFolderId: String?,
              completion: ...)                          // files.list
func findOrCreateFolder(name: String, completion: ...) // Snipeeフォルダ
func getFileMetadata(fileId: String, completion: ...)   // modifiedTime取得
```

**PersonalSyncService.swift** (新規):
```swift
func syncPersonalSnippets(completion: ...)
func downloadPersonalData(completion: ...)
func uploadPersonalData(_ data: SyncData, completion: ...)
func mergeData(local: SyncData, remote: SyncData) -> SyncData
func ensureSyncFile(completion: ...)
func startAutoSync()
func stopAutoSync()
```

### 実装フェーズ

#### Phase 1: 基盤（Drive API拡張）
**目的**: ファイル作成・検索・メタデータ取得を可能にする

**対象**: `GoogleDriveService.swift` に `createFile`, `findFile`, `getFileMetadata` 追加

**完了条件**: `Snipee/personal_snippets.json` の作成・読み書きが可能

#### Phase 2: モデル統一
**目的**: Snippetモデルに `createdAt`, `updatedAt` を追加

**対象**: `Snippet.swift` に `createdAt`, `updatedAt` 追加（Optional、後方互換）

**マイグレーション**: 既存データ読み込み時に `createdAt`/`updatedAt` が無ければ現在日時で補完

#### Phase 3: 同期エンジン（Mac版先行）← 現在ここ
**目的**: 1プラットフォームで完全な同期機能を実装・検証

**対象**: `PersonalSyncService.swift`

**理由**: Mac版が最も安定しており、iOS版とコード共有可能。Windows版はリファクタリング中のため後回し。

**実装内容**:
1. `ensureSyncFile()` - Snipeeフォルダ＋JSONファイルの存在確認/作成
2. `downloadPersonalData()` - クラウドからJSONダウンロード
3. `mergeData()` - Last-Writer-Wins マージロジック
4. `uploadPersonalData()` - マージ結果をアップロード
5. `syncPersonalSnippets()` - 上記を統合した同期フロー
6. 保存時のデバウンス付きアップロード
7. 起動時ダウンロード
8. 定期同期（30分）

#### Phase 5: UI・UX
**目的**: 同期状態の表示とエラー通知

**実装内容**:
- 最終同期日時の表示
- 同期中インジケーター
- エラー発生時の通知
- 手動同期ボタン

#### Phase 6: 移行・テスト
**目的**: 既存ユーザーのデータ移行と品質保証

**実装内容**:
- 既存ローカルデータの初回アップロード
- 複数デバイス同時編集テスト
- オフライン→オンライン復帰テスト
- 大量データ（1000スニペット）でのパフォーマンステスト

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

### スニペットエディタのパフォーマンス問題

**症状**: スニペットをクリックしてからフォーカス移動までワンテンポ遅れる。Clipy（AppKit）は軽いがSnipee（SwiftUI）は重い。

**関連ファイル**:
- `SnippetEditorView.swift`
- `SnippetEditorWindow.swift`
- `ContentPanel.swift`
- `FolderSidebar.swift`

**調査結果（2026-02-09）**:

1クリックで最大11個の@State変数が変更され、少なくとも2回のレンダーパスが発生している。

**クリック時の処理フロー**:
```
SnippetRow.onTapGesture (FolderSidebar.swift:914)
  → onSelectSnippet callback (FolderSidebar.swift:99-104)
    → 5つの@State/@Binding同期更新
  → ContentPanel onChange(selectedSnippetId) (ContentPanel.swift:72)
    → hasUnsavedChanges ? saveImmediately() → UserDefaults同期書き込み
    → loadSnippet() → 6つの@State変数更新
    → DispatchQueue.main.async { isLoadingSnippet = false } → 追加レンダーパス
```

**ボトルネック（改善優先度順）**:

| # | 問題 | 影響度 | 場所 | 改善案 |
|---|------|--------|------|--------|
| 1 | 11個の@State変数が個別更新→多数のレンダーパス | 高 | FolderSidebar:99-104, ContentPanel:321-337 | 構造体にまとめて1回で更新 |
| 2 | saveImmediately()のメインスレッド同期UserDefaults書き込み | 高 | ContentPanel:74-76 → SnippetEditorView:358-360 | 非同期化 or バックグラウンドキュー |
| 3 | DispatchQueue.main.asyncによる2パスレンダー | 中 | ContentPanel:334-336 | isLoadingSnippetのリセットを同期化 |
| 4 | ContentPanel .id()修飾子によるView破棄・再作成 | 中 | SnippetEditorView:165 | 個別/マスタ切替時にonAppear+onChangeの二重loadSnippet()が発生 |
| 5 | selectedSnippet計算プロパティのO(n)検索 | 低 | ContentPanel:37,41 | Dictionaryキャッシュ化 |

**過去の調査（2026-02-02）**:

| テスト | 結果 |
|-------|------|
| `.id()` コメントアウト | 原因ではなかった |
| `isLoadingSnippet` フラグ追加（onChange抑制） | 少し改善 |
| `DispatchQueue.main.async` で遅延解除 | 少し改善 |

**否定された仮説**:
- デバッグprint文のI/Oブロッキング → 前回40件削除済み、スニペット選択のホットパスに残存printはゼロ

**将来検討**: 上記で不十分な場合、SwiftUI TextEditor → NSViewRepresentable(NSTextView)への置換

### XMLインポート後にcontentが表示されない

**症状**: XMLインポート成功、保存も成功、しかしContentPanelでスニペット選択時にcontentが空

**状況**: 調査済みだが未解決。スキップして後回し。

**関連ファイル**:

- `SnippetEditorView.swift`: handlePersonalImport()
- `ContentPanel.swift`: loadSnippet(), selectedSnippet計算プロパティ

---

## 🗓️ TODO / ロードマップ

### 🔴 最優先
- クラウド同期 Phase 3 完成（PersonalSyncService.swift）

### 🟡 改善
- スニペットエディタ パフォーマンス改善（@Stateバッチ化、saveImmediately非同期化）
- Mac改善4件（Keychain化、スコープ制限等）
- XMLインポート問題

### 🟢 将来
- ユーザーへのMac版移行案内
- Swift 6 移行（async/await対応）
- タグ機能、検索機能強化

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

### テスト用コマンド

```bash
# Mac版 完全リセット
osascript -e 'quit app "SnipeeMac"' && defaults delete com.addness.SnipeeMac 2>/dev/null; rm -rf ~/Library/Preferences/com.addness.SnipeeMac.plist && rm -rf ~/Library/Containers/com.addness.SnipeeMac && rm -rf ~/Library/Application\ Support/SnipeeMac && security delete-generic-password -s "com.addness.SnipeeMac" 2>/dev/null; killall cfprefsd

# アップデートチェック日付リセット
defaults delete com.addness.SnipeeMac lastUpdateCheckDate

# オンボーディングリセット
defaults delete com.addness.SnipeeMac welcomeCompleted
```

---

## 🔄 変更履歴

### 2026-02-03

- **Google APIスコープ変更**
  - `spreadsheets.readonly` → `spreadsheets`（ステータス報告用の書き込み権限）

### 2026-02-02

- **v2.0.3リリース**
- **バックアップ機能追加**（StorageService.swift）
  - 個別スニペット保存時に1世代バックアップを自動作成
  - `personal_snippets_backup` キーで保存
- **ツールバー整理**（SnippetEditorView.swift）
  - ボタンを右寄せに統一
  - 管理者: 同期 | インポート | エクスポート | 他部署マスタ▼ | マスタ更新
  - 一般: 同期 | インポート | エクスポート
  - ツールバーをコンテンツパネル側のみに表示
- **レイアウト安定化**（ContentPanel.swift）
  - 空状態でもツールバーを表示してガタつき解消
- **GitHub Actions修正**（build-mac.yml）
  - appcast push前にfetch/checkout/pullを追加
  - 競合によるpush失敗を防止

### 2026-02-01（午後）

- **ポップアップキーボード処理を共通化**
  - `PopupKeyboardHandler.swift` を新規作成
  - MainPopupView、SnippetPopupView、HistoryPopupViewで共通利用
- **デバッグprint文を削除**（40件、10ファイル）
- **スニペットエディタにキーボード操作追加**
  - Cmd+↑↓でスニペット切り替え
- **ContentPanelの保存最適化**
  - hasUnsavedChangesフラグで変更時のみ保存
- **不要ファイル削除**
  - OPTIMIZATION_PROPOSAL.md
  - SNIPPET_EDITOR_ANALYSIS.md

### 2026-02-01（午前）

- **Clipy XMLインポート問題の調査**（未解決→スキップ）
- **オンボーディング改善**
  - WelcomeViewにログインステップ追加（5ステップに）
  - ログイン必須化（スキップ不可）
  - オレンジテーマで統一
  - OnboardingView.swift、OnboardingWindow.swiftを削除（未使用）
- **自動アップデート改善**
  - ログイン後にのみSparkle開始
  - App Sandbox削除（インストール権限エラー対策）
- **LoginRequiredView改善**
  - ウィンドウクローズをタイトルで特定
- **設定画面**
  - セットアップ再表示をWelcomeViewに変更
  - ウィンドウ参照を@Stateで保持

### 2026-01-31

- **自動保存機能を追加**
  - 0.3秒デバウンスで自動保存
  - 保存状態のアニメーション表示
  - 切り替え時・画面クローズ時の即時保存
- **自動アップデート機能を修正**
  - appcast-mac.xml を正しいURLで作成
  - Constants.swift のappcast URLを修正（大文字Snipee）
  - Sparkleエラーハンドリングを追加
- **バージョン自動更新を追加**
  - GitHub Actionsでタグからバージョンを自動抽出
  - Xcodeでの手動更新が不要に
- **マスタアップロード機能を修正**
  - Google Driveスコープを`drive`に変更（フルアクセス）
  - 共有ドライブ対応（`supportsAllDrives=true`）

### 2026-01-27

- **他部署マスタ参照機能を追加**
  - ツールバーに他部署マスタ選択メニュー
  - 読み取り専用モード実装
  - テキスト選択機能
- **管理者マスタアップロード機能を追加**
