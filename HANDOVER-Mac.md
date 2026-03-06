# Snipee HANDOVER — Mac (Swift)

**最終更新**: 2026-03-06

---

## 🚩 現在地

- クラウド同期 Phase 3 完了（Mac版・iOS版 PersonalSyncService.swift 実装済み）
- 2/10 サイドバーUI大幅改善（「...」メニュー、NSViewRepresentable化、自動スクロール）
- 2/15 MVP化：他部署マスタ参照を削除（将来復活用コードセットは本ドキュメント末尾に保存）
- 2/16 サイドバーリネーム修正（SwiftUI TextField → InlineTextField: NSViewRepresentable）
- 2/16 右クリックメニュー復活（.contextMenu）
- 2/19 エクスポート機能完成（Downloads直接保存、Snipee形式/Clipy形式対応）
- 2/19 VSCode SourceKit-LSP セットアップ完了（xcode-build-server config済み）
- 2/27 FolderSidebar バグ修正・UX改善（詳細は変更履歴参照）
- 2/27 v2.0.5 リリース完了
- 3/06 XMLパース失敗時のマスタ全消失バグ修正（Fix 1・2）
- 3/06 FolderSidebar リネーム・ダブルクリックUX修正
- 3/06 build-mac.yml appcast競合修正
- 3/06 v2.0.7 リリース完了

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

### 11. ❌ SwiftUI ScrollView + LazyVStack + ScrollViewReader の組み合わせ

**失敗**: `scrollTo` が遅延読み込みをトリガー → 再レンダリング → 無限ループ
**解決**: `LazyVStack` → `VStack` に変更（スニペット数が数百レベルなら問題なし）

### 12. ❌ SwiftUI の .popover / Menu ビューをリスト全行に配置しない

**失敗**: SwiftUI `Menu` を全行に常時配置 → スクロール不能になるレベルのパフォーマンス劣化
**解決**: `NSViewRepresentable` + `NSButton` + `NSMenu` に置換。SwiftUIのイベントチェーンを経由しないので高速かつ位置正確

### 13. ❌ SwiftUI の .onKeyPress を ScrollView に直接使わない

**失敗**: `ScrollView` + `.focusable()` + `.onKeyPress` ではキーイベントが発火しない
**解決**: `NSEvent.addLocalMonitorForEvents` でキーイベントをキャッチする方式に切り替える（SidebarKeyboardMonitor実装予定）

### 14. ❌ SwiftUI TextField(.plain) + .onSubmit をmacOSで使わない

**失敗**: `.textFieldStyle(.plain)` + `.onSubmit` はmacOS SwiftUIの既知バグでEnterキーが発火しない
**試行錯誤**: `.onChange(of:)` で改行文字検出 → 動作不安定
**解決**: `NSViewRepresentable` + `NSTextField` でラップ（InlineTextField）。`NSTextFieldDelegate` の `control(_:textView:doCommandBy:)` で `insertNewline:` / `cancelOperation:` を捕捉

### 15. ❌ NSViewRepresentable のoverlayでクリックイベントを処理しない

**失敗**: `RowClickHandler: NSViewRepresentable` をSwiftUI行の `.overlay()` で全行に配置 → `makeNSView` 中にクラッシュ（Thread 1で停止）。SnippetEditorが開かなくなる
**原因**: NSViewのライフサイクルとSwiftUIのレイアウトサイクルの競合。大量のNSViewインスタンスが同時生成される
**解決**: 左クリックは `.onTapGesture`、右クリックは `.contextMenu`、メニューボタンは `EllipsisMenuButton: NSViewRepresentable` に分離。NSViewRepresentableは最小限の用途に限定する

### 16. ❌ XMLパース結果が空でもローカルを上書きしない

**失敗**: XMLパース失敗 or 空データ取得時に `[]` をそのまま `saveMasterSnippets()` に渡す → マスタ全消失
**解決**: `parseWithValidation()` を使い、空・エラーどちらも `.failure` で返してローカルデータを保護する（SyncService.swift + XMLParserHelper.swift）

### 17. ❌ FolderRow の Spacer に独立タップを付けない

**失敗**: `Spacer().onTapGesture { onToggle() }` が行末クリック時に発火 → ダブルクリックリネームが起動しない
**解決**: Spacer のタップを削除し、行全体の `.onTapGesture(count:1/2)` に一本化

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
| 他部署マスタ参照             |         ✅         |     🔒      |     ❌      |
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
- **表示・操作タブ**: フォルダ表示設定
- **アカウントタブ**: ログイン状態、ログアウト
- **ヘルプタブ**: 使い方、FAQ

### 管理者機能

- **権限**: スプシで「管理者」「最高管理者」に設定
- **マスタアップロード**: 個人スニペットをGoogle Driveにアップロード
- **共有ドライブ対応**: `supportsAllDrives=true`

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

### Mac版リリース

```bash
git add . && git commit -m "変更内容" && git tag mac-vX.X.X && git push origin main && git push origin mac-vX.X.X
```

GitHub Actions が自動でビルド・公証・appcast更新まで実行する。手動でのappcast編集は不要。

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
├── Snipee_データ/
│   └── personal_snippets.json
└── Snipee_バックアップ/（将来実装）
```

#### 同期タイミング

| タイミング | 方式 | 説明 |
|-----------|------|------|
| アプリ起動時 | ダウンロード → マージ | 最新状態を取得 |
| 保存時 | デバウンス付きアップロード（5秒） | 頻繁な保存を抑制 |
| 定期 | 30分ごと（バックグラウンド） | 他デバイスの変更を取得 |
| 手動 | 同期ボタン | ユーザー操作 |

### 実装フェーズ

| Phase | 内容 | 状態 |
|-------|------|------|
| Phase 1 | Drive API拡張 | ✅ |
| Phase 2 | モデル統一（createdAt/updatedAt追加） | ✅ |
| Phase 3 | 同期エンジン（PersonalSyncService.swift） | ✅ |
| Phase 5 | UI・UX（同期状態表示） | 🔄 未着手 |
| Phase 6 | 移行・テスト | 🔄 未着手 |

---

## 🚨 未解決の問題

### スニペットエディタのパフォーマンス問題

**症状**: スニペットをクリックしてからフォーカス移動までワンテンポ遅れる。

**ボトルネック（改善優先度順）**:

| # | 問題 | 影響度 | 改善案 |
|---|------|--------|--------|
| 1 | 11個の@State変数が個別更新 | 高 | 構造体にまとめて1回で更新 |
| 2 | saveImmediately()のメインスレッド同期書き込み | 高 | 非同期化 |
| 3 | DispatchQueue.main.asyncによる2パスレンダー | 中 | 同期化 |
| 4 | ContentPanel .id()によるView破棄・再作成 | 中 | 見直し |
| 5 | selectedSnippet計算プロパティのO(n)検索 | 低 | Dictionaryキャッシュ化 |

---

## 🗓️ TODO

### 🟡 改善
- スニペットエディタ パフォーマンス改善（@Stateバッチ化、saveImmediately非同期化）
- Mac改善4件（Keychain化、スコープ制限等）
- Windows版 Fix 1（XMLパース空配列ガード）対応

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

### 2026-03-06

- **XMLパース失敗時のマスタ全消失バグ修正**（SyncService.swift / XMLParserHelper.swift）
  - `XMLParserHelper` に `parseWithValidation()` を追加（エラー検知 + 空配列ガード）
  - `parseError` プロパティ + `parser(_:parseErrorOccurred:)` デリゲートでパースエラーを捕捉
  - `SyncService.downloadAndParseXML` で `parseWithValidation()` を使用。空・エラー両方で `.failure` を返しローカルデータを保護
  - `SyncError` に `.emptyResult` ケースを追加
- **FolderSidebar リネームUX修正**（FolderSidebar.swift）
  - `InlineTextField.makeNSView` の `selectAll` を削除 → デフォルト動作（クリック位置にカーソル）に変更
  - `FolderRow` の `Spacer().onTapGesture` を削除 → 行全体の `.onTapGesture(count:1/2)` に一本化。行末クリックでダブルクリック判定が妨害されていたバグを修正
- **build-mac.yml appcast競合修正**（.github/workflows/build-mac.yml）
  - 「Update Appcast」ステップを削除
  - 「Commit and Push Appcast」ステップ内でappcast生成 + checkout + push を一括処理。`git stash` 方式による競合を解消
- **v2.0.7 リリース完了**

### 2026-02-27

- **FolderSidebar バグ修正・UX改善**（FolderSidebar.swift）
  - キーボードナビゲーション完成（SidebarKeyboardMonitor + NSEvent.addLocalMonitorForEvents）
  - フォルダ作成をインライン化（モーダル廃止）
  - マスタ/個別フォルダ作成分岐を修正
  - フォルダクリック時のフォーカス状態を修正
  - フォルダのフォーカス背景色を追加
  - 削除したデータが再起動で復活するバグを修正（markAsDeleted呼び出し追加）
  - MainPopupView.swift を移動（Views/Popup/ → Views/Onboarding/）
- **v2.0.5 リリース完了**

### 2026-02-16

- サイドバーリネーム完全修正（InlineTextField: NSViewRepresentable）
- 右クリックメニュー復活（.contextMenu）
- EllipsisMenuButton（...ボタン）復活
- RowClickHandler削除

### 2026-02-15

- MVP化：他部署マスタ参照を削除（SnippetEditorView.swift）
- 将来復活用コードセットを本ドキュメント末尾に保存

### 2026-02-10

- サイドバーUI大幅改善（EllipsisMenuButton、自動スクロール）

### 2026-02-03

- Google APIスコープ変更（spreadsheets.readonly → spreadsheets）

### 2026-02-02

- v2.0.3リリース
- バックアップ機能追加
- ツールバー整理
- GitHub Actions修正

---

## 🔒 将来復活用コードセット

### 他部署マスタ参照（2026-02-15 削除）

**概要**: 管理者がツールバーから他部署のマスタスニペットを読み取り専用で閲覧する機能

**前提条件**:
- `GoogleSheetsService.swift` の `fetchAllDepartments()` / `DepartmentInfo` は温存済み
- `FolderSidebar.swift` / `ContentPanel.swift` の `isReadOnly` パラメータは温存済み
- 復活時は `SnippetEditorView.swift` のみ修正すればよい

**復活手順**: 以下のコードを `SnippetEditorView.swift` に追加する

#### 1. @State変数（既存の isAdmin / userDepartment の下に追加）
```swift
@State private var allDepartments: [DepartmentInfo] = []
@State private var selectedOtherDepartment: DepartmentInfo?
@State private var otherDepartmentFolders: [SnippetFolder] = []
@State private var isLoadingOtherDepartment = false
@State private var isViewingOtherDepartment = false
```

#### 2. buildFlatSnippetList — isViewingOtherDepartment ガード追加
```swift
if !isViewingOtherDepartment {
    // ... personalFolders ループ
}
let masters = isViewingOtherDepartment ? otherDepartmentFolders : masterFolders
```

#### 3. sidebarView / contentPanelView の isReadOnly を差し替え
```swift
isReadOnly: isViewingOtherDepartment,
onSave: { if !isViewingOtherDepartment { saveData() } },
onAddSnippet: { if !isViewingOtherDepartment { isAddingSnippet = true } },
```

#### 4. currentMasterFolders / currentContentFolders の分岐復活
```swift
private var currentMasterFolders: Binding<[SnippetFolder]> {
    isViewingOtherDepartment ? $otherDepartmentFolders : $masterFolders
}
private var currentContentFolders: Binding<[SnippetFolder]> {
    if isShowingMaster {
        return isViewingOtherDepartment ? $otherDepartmentFolders : $masterFolders
    } else {
        return $personalFolders
    }
}
```

#### 5〜8. editorToolbar / otherDepartmentMenu / loadAllDepartments / loadOtherDepartmentSnippets / closeOtherDepartmentView

（詳細は2026-02-15時点のHANDOVERを参照）