# Snipee 機能差分レポート（Mac版 vs Windows版）

調査日: 2026-02-28
Mac版: `SnipeeMac/SnipeeMac/SnipeeMac/` (Swift/SwiftUI)
Windows版: `app/` (Electron/Node.js)

---

## 1. Mac版にあってWindows版にない機能（未実装）

### ~~1-1. 個別スニペットのクラウド同期（PersonalSyncService）~~ ✅ 実装済み（2026-02-28）

- **実装ファイル**: `app/services/personal-sync-service.js`、`app/services/google-drive-service.js`（拡張）、`app/ipc/snippet-handlers.js`（トリガー追加）、`app/main.js`（起動時ダウンロード）
- **実装内容**: 起動時にDriveからダウンロード→ローカルにLast-Writer-Winsマージ、編集時5秒デバウンスでアップロード。Mac版と同じ `Snipee_データ/personal_snippets.json` を共有するためクロスプラットフォーム同期が実現。
- **Mac版との差分**: Mac版は削除追跡（30日墓標）と30分定期同期あり。Windows版は未実装（将来対応）。

### 1-2. スニペット昇格・降格（SnippetPromotionService）

- **Mac版実装ファイル**: `Services/SnippetPromotionService.swift`
  - `promoteSnippetToMaster(snippet:fromFolderName:masterFolders:)` (L14)
  - `demoteSnippetToPersonal(snippet:fromFolderName:personalFolders:)` (L40)
  - `promoteFolderToMaster(folder:masterFolders:personalFolders:)` (L68)
  - `demoteFolderToPersonal(folder:masterFolders:personalFolders:)` (L104)
- **機能の詳細**: 管理者が個別スニペット/フォルダをマスタに昇格、またはマスタスニペット/フォルダを個別に降格できる。スニペット単体の昇格/降格と、フォルダ全体の一括昇格/降格の両方をサポート。昇格時は `type` を `.master` に変更し、フォルダが存在しなければ自動作成。降格は逆方向。
- **Windows版で必要なファイル**: 新規 `app/services/snippet-promotion-service.js`（既にファイルは存在するが空）、`app/ipc/snippet-handlers.js` にIPC追加、`app/views/snippet-editor.html` にUI追加
- **実装難易度**: **中** — ロジック自体はシンプル（typeフィールドの変更と配列操作）だが、UIの追加とマスタスニペットのアップロード連携が必要

### 1-3. Clipy互換XMLエクスポート形式

- **Mac版実装ファイル**: `Utilities/XMLParserHelper.swift`
  - `exportClipyXML(folders:)` (L81) — `<folders>` ルート、`<snippets>`ラッパー、description除外
  - `exportSnipeeXML(folders:)` (L76) — `<snippets>` ルート、description含む
- **機能の詳細**: エクスポート時に2つのフォーマットを選択可能。Snipee形式（descriptionフィールド含む）とClipy互換形式（descriptionなし、`<snippets>`タグでスニペットをラップ）。Clipy（Mac用クリップボードマネージャ）からの移行ユーザーを想定。
- **Windows版で必要なファイル**: `app/services/snippet-import-export-service.js` に `exportClipyXml()` を追加、`app/views/snippet-editor.html` にフォーマット選択UIを追加
- **実装難易度**: **低** — XML文字列組み立てのバリエーション追加のみ。ただしWindows環境でClipy互換の需要は低い可能性あり

### 1-4. エクスポートフォーマット選択ダイアログ

- **Mac版実装ファイル**: `Views/Editor/SnippetEditorView.swift`
  - ExportSheet内でフォーマット選択（Snipee形式 / Clipy互換形式）
  - エクスポート対象（個別/マスタ）とフォルダ選択UIも含む
- **機能の詳細**: エクスポート時にモーダルダイアログで「対象タイプ（個別/マスタ）」「フォルダ選択」「フォーマット（Snipee/Clipy）」を選択してからファイルを保存する。
- **Windows版で必要なファイル**: `app/views/snippet-editor.html` にモーダルUIを追加
- **実装難易度**: **低** — UI追加のみ

### 1-5. ペースト遅延時間の設定（pasteDelay）

- **Mac版実装ファイル**: `Models/AppSettings.swift` — `pasteDelay: Int` (L27, デフォルト50ms)
  - `Services/PasteService.swift` で使用（ペースト前のウェイト）
- **機能の詳細**: クリップボードに書き込んだ後、ペースト操作（Cmd+V / Ctrl+V）を送る前の待機時間をミリ秒単位で設定可能。環境によってはペーストが早すぎると前のクリップボード内容が貼り付けられることがあるため。
- **Windows版で必要なファイル**: `app/services/paste-service.js` に遅延設定の参照を追加、`app/views/settings.html` に設定UIを追加
- **実装難易度**: **低** — setTimeout の遅延値を設定から読み込むだけ

### 1-6. Pキーによるピン切り替え（ポップアップ内）

- **Mac版実装ファイル**: `Views/Popup/HistoryPopupView.swift`
  - `togglePinForSelectedItem()` — メインリストのピン切り替え
  - `togglePinForSubmenuItem()` — サブメニュー内のピン切り替え
  - キーコード35（P）をハンドリング
- **機能の詳細**: 履歴ポップアップでアイテムを選択した状態でPキーを押すと、ピン留め/ピン解除を切り替えられる。ピン状態は「●」（ピン済み）/「○」（未ピン）で表示される。
- **Windows版で必要なファイル**: `app/views/history.html` および `app/views/index.html` のキーボードハンドラーに追加
- **実装難易度**: **低** — キーボードイベントハンドラーへの追加とIPC呼び出し

### 1-7. スニペットエディタからの個別XMLインポート

- **Mac版実装ファイル**: `Views/Editor/SnippetEditorView.swift`
  - Import Menu: "個別スニペット" / "マスタスニペット"（管理者のみ）
  - `SnippetImportExportService.handleImport()` でターゲット指定
- **機能の詳細**: スニペットエディタのツールバーからXMLインポートが可能。個別スニペットとマスタスニペットのインポート先を選択できる。Windows版はSettings画面の管理者タブからのみマスタXMLインポートが可能で、エディタからのインポートUIがない。
- **Windows版で必要なファイル**: `app/views/snippet-editor.html` にインポートボタンとロジックを追加
- **実装難易度**: **低** — 既存のインポートロジックをエディタUIから呼び出すだけ

---

## 2. 実装済みだが仕様・動作が異なる機能（差分）

### 2-1. デフォルトホットキー

| 項目 | Mac版 | Windows版 |
|------|-------|-----------|
| 簡易ホーム | `Cmd+Ctrl+C` | `Ctrl+Alt+C` |
| スニペット専用 | `Cmd+Ctrl+V` | `Ctrl+Alt+V` |
| 履歴専用 | `Cmd+Ctrl+X` | `Ctrl+Alt+X` |

- **Mac版**: `AppSettings.swift` L37-39 — HotkeyConfig構造体（keyCode + modifiers）
- **Windows版**: `main.js` L57-59 — Accelerator文字列
- **差分**: ModifierキーがOS慣例に合わせて異なる（Mac: Cmd、Windows: Alt）。これはOS差異として適切。
- **修正難易度**: 対応不要

### 2-2. OAuth認証フロー

| 項目 | Mac版 | Windows版 |
|------|-------|-----------|
| リダイレクトURI | `com.addness.snipeemac:/oauth2callback` | `http://localhost:8085/callback` |
| トークン保存先 | UserDefaults | keytar (Windows Credential Manager) |
| スコープ: Drive | `drive` (フルアクセス) | `drive.readonly` + `drive.file` |

- **Mac版**: `Services/GoogleAuthService.swift` — カスタムURLスキーム + UserDefaults
- **Windows版**: `app/services/google-auth-service.js` — ローカルHTTPサーバー + keytar
- **差分**: Mac版はDriveフルアクセススコープを使用。Windows版も個別同期実装（2026-02-28）に合わせて `drive` フルアクセスに変更済み。
- **修正難易度**: 対応済み

### 2-3. マスタスニペット自動同期間隔

| 項目 | Mac版 | Windows版 |
|------|-------|-----------|
| 間隔 | 1時間（3600秒） | 2時間（7200秒） |
| 実装箇所 | `AppDelegate.swift` L254 | `app/services/sync-service.js` |

- **差分**: Mac版は1時間、Windows版は2時間で自動同期。
- **修正難易度**: **低** — 定数変更のみ

### 2-4. カラーテーマ

| テーマ名 | Mac版 | Windows版 |
|---------|-------|-----------|
| space-gray（ダーク） | - | ✓ |
| silver | ✓ | ✓ |
| pearl | ✓ | ✓ |
| blush | ✓ | ✓ |
| peach | ✓ | ✓ |
| cream | ✓ | ✓ |
| pistachio | ✓ | ✓ |
| aqua | ✓ | ✓ |
| periwinkle | ✓ | ✓ |
| wisteria | ✓ | ✓ |

- **Mac版**: `Theme/ColorTheme.swift` — 9テーマ
- **Windows版**: `app/utilities/theme.js` — 10テーマ（space-gray追加）
- **差分**: Windows版のみダークテーマ（space-gray）がある。
- **修正難易度**: 対応不要（Windows独自機能として維持）

### 2-5. XMLエクスポートのルート要素

| 項目 | Mac版（Snipee形式） | Mac版（Clipy形式） | Windows版 |
|------|---------------------|-------------------|-----------|
| ルート要素 | `<snippets>` | `<folders>` | `<folders>` |
| snippet wrapper | なし | `<snippets>` | `<snippets>` |
| description | あり | なし | あり |

- **Mac版**: `Utilities/XMLParserHelper.swift` `export()` (L105) / `exportClipyXML()` (L81)
- **Windows版**: `app/views/settings.html` `generateExportXml()` — `<folders>` ルート
- **差分**: Mac版のデフォルト（Snipee形式）は `<snippets>` をルート要素にする。Windows版は `<folders>` をルート要素にする。インポート時は両方とも対応しているため実害はないが、形式が統一されていない。
- **修正難易度**: **低** — ルート要素の文字列を変更するだけ

### 2-6. 設定画面のタブ構成

| タブ | Mac版 | Windows版 |
|------|-------|-----------|
| 一般 | ✓ | ✓ |
| 表示・操作 | 表示のみ（フォルダ表示設定） | 表示・操作（フォルダ + ウィンドウ位置 + ホットキー） |
| アカウント | ✓（マスタ同期 + 個別同期ボタン） | ✓（マスタ同期のみ + アップデート） |
| ヘルプ | ✓（変数一覧 + ホットキー一覧） | ✓（変数一覧 + ホットキー一覧） |
| 管理者 | なし（エディタ内で管理） | ✓（条件表示） |

- **Mac版**: `Views/Settings/` — GeneralTab, DisplayTab, AccountTab, HelpTab
- **Windows版**: `app/views/settings.html` — general, display, account, help, admin
- **差分**: Windows版はアカウントタブ内にアップデート確認UI + 管理者専用タブがある。Mac版はアカウントタブに個別同期ボタンがある。Mac版の管理者機能はスニペットエディタ内に統合されている。
- **修正難易度**: 対応不要（UIレイアウトの違い）

### 2-7. 履歴クリア時のピン済みアイテム

| 項目 | Mac版 | Windows版 |
|------|-------|-----------|
| クリア対象 | 未ピンのみ（ピン済み保持） | 全履歴削除 |

- **Mac版**: `Services/ClipboardService.swift` `clearHistory()` — ピン済みアイテムをフィルタリングして保持
- **Windows版**: `app/ipc/clipboard-handlers.js` `clear-all-history` — 配列を空にリセット
- **差分**: Mac版はクリア時にピン済みアイテムを保持するが、Windows版は全削除する。
- **修正難易度**: **低** — クリア処理でピン済みアイテムをフィルタリングするだけ

### 2-8. ホットキー登録方式

| 項目 | Mac版 | Windows版 |
|------|-------|-----------|
| API | Carbon Event API (EventHotKey) | Electron globalShortcut |
| 設定形式 | keyCode + modifiers (ビットフラグ) | Accelerator文字列 (例: "Ctrl+Alt+C") |
| リトライ | なし | 3回リトライ (500ms間隔) |

- **Mac版**: `Services/HotkeyService.swift`
- **Windows版**: `app/main.js` `registerGlobalShortcuts()` (L307)
- **差分**: 実装メカニズムはOS固有で異なるが、機能的には同等。Windows版はリトライ機構あり。
- **修正難易度**: 対応不要

---

## 3. Windows版独自機能（Macにない）

### 3-1. ダークテーマ（space-gray）

- **実装ファイル**: `app/utilities/theme.js` — `space-gray` テーマ定義、`app/theme/variables.css`
- **概要**: 背景色 `#1d1d1f` のダークテーマ。Mac版にはないWindows限定のテーマオプション。

### 3-2. 二重起動通知

- **実装ファイル**: `app/main.js` L10-21
- **概要**: `app.requestSingleInstanceLock()` で単一インスタンスを保証。二重起動時にElectron Notificationで「Snipeeは既に起動しています」と通知。Mac版は二重起動防止のみでユーザー通知なし。

### 3-3. ウィンドウ位置モード（カーソル / 前回位置）

- **実装ファイル**: `app/main.js` `positionAndShowWindow()` (L475)、`app/ipc/settings-handlers.js`、`app/views/settings.html`
- **概要**: ポップアップの表示位置を「カーソル位置」「前回の位置」から選択可能。Mac版はカーソル/ステータスバー付近に固定。

### 3-4. ドラッグ&ドロップによるフォルダ・スニペット並び替え

- **実装ファイル**: `app/utilities/drag-drop.js` — `DragDropManager` クラス
- **概要**: スニペットエディタでフォルダ間・フォルダ内のスニペットをドラッグ&ドロップで並び替え可能。`onFolderReorder`、`onItemReorder`、`onItemDropToEnd` コールバックで順序を保存。

### 3-5. マスタスニペットの説明文（description）編集

- **実装ファイル**: `app/ipc/snippet-handlers.js` — `update-master-description` IPC
- **概要**: マスタスニペット個別のdescriptionフィールドを更新するIPCハンドラー。Mac版はdescriptionフィールド自体はあるが、マスタスニペットのdescription個別更新IPCはない（エディタ内で統合編集）。

### 3-6. 他部署スニペットの閲覧（管理者機能）

- **実装ファイル**: `app/ipc/auth-handlers.js` — `get-viewable-departments`、`get-other-department-snippets` IPC
- **概要**: 管理者が自分の所属部署以外のスニペットも閲覧可能。Mac版にはこの明示的なIPCはない。

---

## 4. 変数置換の対応表

Mac版: `Services/VariableService.swift` `processVariables()` (L89)
Windows版: `app/services/variable-service.js` `replaceVariables()` (L65)

| 変数 | Mac版 | Windows版 | 備考 |
|------|-------|-----------|------|
| `{名前}` | ✓ (L96) | ✓ (L70) | |
| `{name}` | ✓ (L97) | ✓ (L71) | |
| `{日付}` | ✓ (L102) | ✓ (L78) | YYYY/MM/DD |
| `{date}` | ✓ (L103) | ✓ (L79) | YYYY/MM/DD |
| `{年}` | ✓ (L106) | ✓ (L82) | |
| `{月}` | ✓ (L107) | ✓ (L83) | |
| `{日}` | ✓ (L108) | ✓ (L84) | |
| `{時刻}` | ✓ (L113) | ✓ (L90) | HH:mm |
| `{time}` | ✓ (L114) | ✓ (L91) | HH:mm |
| `{曜日}` | ✓ (L119) | ✓ (L95) | 日/月/火/水/木/金/土 |
| `{明日}` | ✓ (L123) | ✓ (L103) | YYYY/MM/DD |
| `{明後日}` | ✓ (L126) | ✓ (L111) | YYYY/MM/DD |
| `{今日:MM/DD}` | ✓ (L134) | ✓ (L114) | MM/DD |
| `{明日:MM/DD}` | ✓ (L138) | ✓ (L117) | MM/DD |
| `{タイムスタンプ}` | ✓ (L142) | ✓ (L120) | YYYY/MM/DD HH:mm:ss |
| `{当日:M月D日:曜日短（毎月1日は除外して翌日）}` | ✓ (L149) | ✓ (L125) | 連動ペアA-1 |
| `{1日後:M月D日:曜日短（毎月1日は除外して2日後）}` | ✓ (L153) | ✓ (L129) | 連動ペアA-2 / B-1 |
| `{2日後:M月D日:曜日短（毎月1日は除外して3日後）}` | ✓ (L175) | ✓ (L147) | 連動ペアB-2 / C-1 |
| `{3日後:M月D日:曜日短（毎月1日は除外して4日後）}` | ✓ (L179) | ✓ (L151) | 連動ペアC-2 |

**結論**: 変数置換は完全に一致。両プラットフォームで同一の変数セットと同一のロジック（1日除外・連動ペア含む）を実装済み。

---

## 5. UIの差分

### 5-1. ポップアップウィンドウ

| 項目 | Mac版 | Windows版 |
|------|-------|-----------|
| フレームワーク | SwiftUI (NSPanel) | HTML/CSS/JS (BrowserWindow) |
| サイズ | 180×500pt | 230×600px |
| サブメニュー幅 | 280pt | N/A（同一ウィンドウ内展開） |
| 背景 | ネイティブ透明パネル | transparent BrowserWindow |
| ピン表示 | ● / ○ アイコン | ピンアイコン |
| Pキーでピン切替 | ✓ | - |
| 検索 | SearchField.swift | リアルタイム検索あり |
| 番号キー選択 | 1-9 | 1-9 |
| 履歴グループ | 15件ずつ（最近/少し前/以前） | 15件ずつ |
| フッターキーヒント | ✓（↑↓ ▶ ◀ Esc） | - |

### 5-2. スニペットエディタ

| 項目 | Mac版 | Windows版 |
|------|-------|-----------|
| フレームワーク | SwiftUI | HTML/CSS/JS |
| サイドバー | フォルダツリー（展開/折畳） | フォルダツリー（展開/折畳） |
| ドラッグ&ドロップ | フォルダのみ | フォルダ + スニペット（DragDropManager） |
| インポートボタン | ✓（個別/マスタ選択） | ✓（XMLインポートのみ） |
| エクスポートボタン | ✓（フォーマット選択あり） | ✓（単一フォーマット） |
| 昇格/降格ボタン | ✓（管理者のみ表示） | - |
| マスタ更新ボタン | ✓（管理者のみ、進捗表示） | - |
| 同期ボタン | ✓（ツールバー内） | - |
| descriptionフィールド | ✓ | ✓ |
| 変数リファレンス | ✓（エディタ内パネル） | - |

### 5-3. 設定画面

| 項目 | Mac版 | Windows版 |
|------|-------|-----------|
| タブ数 | 4（一般/表示/アカウント/ヘルプ） | 5（一般/表示・操作/アカウント/ヘルプ/管理者） |
| ホットキー設定の場所 | 一般タブ内 | 表示・操作タブ内 |
| ウィンドウ位置設定 | なし | 表示・操作タブ内（カーソル/前回位置） |
| マニュアルリンク | GitHub | Google Docs |
| アップデート確認 | 一般タブ内 | アカウントタブ内 |
| 個別同期ボタン | アカウントタブ内 | なし |
| 管理者タブ | なし（エディタに統合） | あり（条件表示） |
| テーマ選択UI | 表示タブ内 | なし（CSS変数で切替） |

### 5-4. オンボーディング（ウェルカム画面）

| 項目 | Mac版 | Windows版 |
|------|-------|-----------|
| 実装 | WelcomeView.swift | welcome.html |
| ステップ | マルチステップウィザード | マルチステップウィザード |
| 名前入力 | ✓ | ✓ |
| セットアップ再表示 | 一般タブから | 一般タブから |

### 5-5. ログイン画面

| 項目 | Mac版 | Windows版 |
|------|-------|-----------|
| 実装 | LoginRequiredView.swift | login.html |
| Googleログインボタン | ✓ | ✓ |
| アカウント制限表示 | ✓（@team.addness.co.jp注記） | - |

---

## 6. その他の技術差分

### 6-1. ペースト機構

| 項目 | Mac版 | Windows版 |
|------|-------|-----------|
| API | CGEvent (Core Graphics) | koffi + user32.dll |
| キーシミュレーション | Cmd+V (keyCode 9) | Ctrl+V (VK_CONTROL + VK_V) |
| 前アプリ復帰 | NSRunningApplication.activate | GetForegroundWindow/SetForegroundWindow |
| 遅延設定 | pasteDelay (デフォルト50ms) | 固定（設定なし） |

### 6-2. 自動アップデート

| 項目 | Mac版 | Windows版 |
|------|-------|-----------|
| ライブラリ | Sparkle | electron-updater |
| 配信URL | GitHub Pages appcast-mac.xml | electron-updater設定 |
| チェック間隔 | 1日1回 | 1日1回 |
| ダウンロード進捗 | Sparkle内蔵UI | 設定画面内プログレスバー |
| 手動/自動区別 | なし | isManualDownloadフラグ |

### 6-3. データストレージ

| 項目 | Mac版 | Windows版 |
|------|-------|-----------|
| メイン | UserDefaults (JSON) | electron-store (JSON) |
| 個別スニペット | UserDefaults内 | 別ファイル (personal-snippets) |
| トークン | UserDefaults | keytar |
| バックアップ | personal_snippets_backup キー | なし |

---

## 7. エクスポート機能 詳細差分

### 7-1. Mac版のエクスポート実装

**ファイル**: `SnipeeMac/SnipeeMac/SnipeeMac/Utilities/XMLParserHelper.swift`

#### 関数一覧

| 関数名 | 行番号 | 説明 |
|--------|--------|------|
| `exportSnipeeXML(folders:)` | L76-78 | Snipee形式でエクスポート（`export()` のラッパー） |
| `exportClipyXML(folders:)` | L81-103 | Clipy互換形式でエクスポート |
| `export(folders:)` | L105-128 | Snipee形式の本体（`exportSnipeeXML` から呼ばれる） |
| `escapeXML(_:)` | L130-138 | XML特殊文字エスケープ（`& < > " '`） |

#### Snipee形式（`export()` / `exportSnipeeXML()`）
```xml
<?xml version="1.0" encoding="UTF-8"?>
<snippets>              ← ルート要素: <snippets>
  <folder>
    <title>フォルダ名</title>
    <snippet>           ← <snippets>ラッパーなし、直接<snippet>
      <title>タイトル</title>
      <content>内容</content>
      <description>説明</description>  ← description含む（nilでなければ）
    </snippet>
  </folder>
</snippets>
```

#### Clipy互換形式（`exportClipyXML()`）
```xml
<?xml version="1.0" encoding="UTF-8"?>
<folders>               ← ルート要素: <folders>
  <folder>
    <title>フォルダ名</title>
    <snippets>          ← <snippets>ラッパーあり
      <snippet>
        <title>タイトル</title>
        <content>内容</content>
                        ← descriptionなし
      </snippet>
    </snippets>
  </folder>
</folders>
```

#### 2形式の差分まとめ

| 項目 | Snipee形式 | Clipy互換形式 |
|------|-----------|--------------|
| ルート要素 | `<snippets>` | `<folders>` |
| snippet ラッパー | なし（`<folder>` 直下に `<snippet>`） | `<snippets>` タグで囲む |
| `<description>` | あり（値があれば出力） | なし |
| `<id>` | なし | なし |

### 7-2. Windows版の現在のエクスポート実装

Windows版にはエクスポート処理が **2箇所** に存在する。

#### (A) スニペットエディタ内 — `app/views/snippet-editor.html`

**UI**: ツールバーの「📤 Export」ボタン → エクスポートモーダル（L498-519）

| 関数名 | 行番号 | 説明 |
|--------|--------|------|
| `showExportDialog()` | L1573 | モーダルを開き、マスタ/個別フォルダのチェックリストを生成 |
| `hideExportDialog()` | L1626 | モーダルを閉じる |
| `toggleSelectAll()` | L1630 | 全選択/全解除 |
| `updateSelectAllState()` | L1637 | 個別チェック変更時に「すべて選択」チェックの状態を更新 |
| `executeExport()` | L1643 | 選択フォルダのスニペットを収集 → `generateClipyXML()` → IPC `export-snippets-xml` |
| `generateClipyXML(snippets)` | L1708 | XML文字列を生成 |
| `escapeXml(str)` | L1749 | XML特殊文字エスケープ（`& < > " '`） |

**エクスポートモーダルの機能**:
- マスタスニペット / 個別スニペットのフォルダ別チェックボックス
- 「すべて選択」チェックボックス
- フォルダごとのスニペット件数表示
- マスタ/個別の混在選択が可能

**`generateClipyXML()` の出力形式**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<snippets>              ← ルート要素: <snippets>
  <folder>
    <title>フォルダ名</title>
    <snippets>          ← <snippets>ラッパーあり
      <snippet>
        <id>ID</id>     ← id含む（あれば）
        <title>タイトル</title>
        <content>内容</content>
        <description>説明</description>  ← description含む（あれば）
      </snippet>
    </snippets>
  </folder>
</snippets>
```

#### (B) バックエンドサービス — `app/services/snippet-import-export-service.js`

| 関数名 | 行番号 | 説明 |
|--------|--------|------|
| `exportSnippetsXml(xml, filename)` | L98-116 | 保存ダイアログ表示 → ファイル書き込み（XML文字列は呼び出し元から受け取る） |
| `selectXmlFile()` | L118-136 | インポート用: ファイル選択ダイアログ → 内容読み込み |
| `importPersonalXml(xmlContent)` | L11-96 | 個別スニペットへのXMLインポート（マージ方式） |
| `escapeXmlForMerge(str)` | L6-9 | XML特殊文字エスケープ（インポート用） |

**注意**: `exportSnippetsXml()` はXML文字列の**生成は行わない**。保存ダイアログの表示とファイル書き込みのみ担当。XML生成はフロントエンド（snippet-editor.html の `generateClipyXML()` や settings.html の `generateExportXml()`）が行う。

### 7-3. 差分・未実装項目

#### Mac版にあってWindows版にない機能

| # | 項目 | 詳細 | 対応優先度 |
|---|------|------|-----------|
| 1 | **フォーマット選択** | Mac版はエクスポート時にSnipee形式 / Clipy互換形式を選択可能。Windows版は1形式のみ（後述の「ハイブリッド形式」） | 低（Windows環境でClipy互換の需要は低い） |
| 2 | **description除外オプション** | Clipy互換形式ではdescriptionを除外する。Windows版は常にdescriptionを出力 | 低 |
| 3 | **`<id>` フィールドの非出力** | Mac版はいずれの形式でも `<id>` を出力しない。Windows版は `<id>` を出力する | 低（インポート側で無視されるため実害なし） |

#### Windows版の形式がMac版のどちらとも一致しない問題

Windows版の `generateClipyXML()` は **Mac版のSnipee形式ともClipy形式とも一致しない「ハイブリッド形式」** になっている:

| 項目 | Mac Snipee形式 | Mac Clipy形式 | Windows版 `generateClipyXML()` |
|------|---------------|--------------|-------------------------------|
| ルート要素 | `<snippets>` | `<folders>` | **`<snippets>`** |
| snippet ラッパー | なし | `<snippets>` | **`<snippets>`（あり）** |
| `<description>` | あり | なし | **あり** |
| `<id>` | なし | なし | **あり** |
| 関数名 | `exportSnipeeXML` | `exportClipyXML` | **`generateClipyXML`**（名前はClipy） |

**つまり**: Windows版は関数名が `generateClipyXML` だが、実際の出力はClipy形式ではなく、ルート要素が `<snippets>` で `description` を含む点はSnipee形式寄り、`<snippets>` ラッパーがある点はClipy形式寄りの混合形式。

#### インポート互換性への影響

Mac版の `XMLParserHelper.parse()` は `<folder>` → `<snippet>` の階層を解析するが、ルート要素名（`<snippets>` / `<folders>`）は問わない実装（L32-41）のため、Windows版が出力するXMLはMac版でインポート可能。ただし `<snippets>` ラッパー内の `<snippet>` を正しく辿れるかは、パーサーの実装に依存する（現在のMac版パーサーは `<snippet>` 開始タグで新規Snippetを生成するため、ネストに関係なく動作する — L38-39）。

逆方向（Mac版Snipee形式 → Windows版インポート）は、Windows版が `xml2js` ライブラリを使い `folder.snippets.snippet` パスでアクセスするため（snippet-import-export-service.js L50-54）、`<snippets>` ラッパーがないSnipee形式ではスニペットが取得できない可能性がある。
