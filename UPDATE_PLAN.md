# Snipee Mac 版 Swift 化計画書

**作成日**: 2026-01-12  
**目標**: Electron 版の全機能をネイティブ Swift アプリとして再実装  
**想定期間**: Claude/AI 活用で 1 日（手動なら 2-3 週間）

---

## 📌 なぜ Swift 化するのか

### Electron 版の課題

| 問題                 | 詳細                                |
| -------------------- | ----------------------------------- |
| 仮想デスクトップ相性 | `setVisibleOnAllWorkspaces`が不安定 |
| アプリサイズ         | 100MB 超                            |
| メモリ使用量         | 常時 150-300MB                      |
| 起動速度             | 2-3 秒                              |
| Bundle ID 問題       | VSCode と同じ「Electron」として認識 |

### Swift 版で得られるもの

| メリット       | 詳細                     |
| -------------- | ------------------------ |
| ネイティブ体験 | 仮想デスクトップ問題解消 |
| 軽量           | 5-10MB                   |
| 低メモリ       | 常時 20-50MB             |
| 高速起動       | 0.5 秒以下               |

---

## 🗂️ フォルダ構成

### 現状（変更なし）

```
snipee/                    ← Electron版（Windows + Mac）
├── app/
│   ├── main.js
│   ├── index.html
│   ├── snippets.html
│   ├── settings.html
│   ├── snippet-editor.html
│   └── common/
├── package.json
└── ...
```

### 追加するフォルダ

```
snipee/
├── app/                   ← Electron版（そのまま維持）
├── snipee-mac/            ← 【新規】Swift版Mac専用
│   ├── SnipeeMac.xcodeproj
│   ├── SnipeeMac/
│   │   ├── App/
│   │   ├── Core/
│   │   ├── Services/
│   │   ├── Models/
│   │   ├── Views/
│   │   └── Resources/
│   └── README.md
├── package.json
└── HANDOVER.md
```

**ポイント**:

- Electron 版は**そのまま維持**（Windows 用として継続）
- Swift 版は**別フォルダ**で完全に独立
- 同一リポジトリ内で管理（将来的に分離も可能）

---

## 🔄 Electron 版コードの扱い

### 残すもの（Windows 用）

| ファイル       | 理由                       |
| -------------- | -------------------------- |
| `app/main.js`  | Windows 版のメインプロセス |
| `app/*.html`   | Windows 版の UI            |
| `app/common/`  | 共通ロジック               |
| GitHub Actions | Windows 版ビルド継続       |

### Mac 固有コードの削除検討

現状の`main.js`にある Mac 固有コード：

```
if (process.platform === 'darwin') {
  // Bundle ID取得（osascript）
  // AppleScript自動ペースト
  // アクセシビリティ権限チェック
}
```

**移行完了後の対応**:

1. `main.js`の Mac 固有コードを削除
2. `package.json`の Mac ビルド設定を削除
3. GitHub Actions から Mac ジョブを削除

---

## 📋 Electron 版の整理（Swift 化前の準備）

### 1. ファイル構成の見直し

**現状**:

```
app/
├── main.js              ← 1500行以上、巨大
├── common/
│   ├── google-auth.js
│   ├── sheets-api.js
│   ├── drive-api.js
│   └── member-manager.js
└── *.html
```

**整理案**:

```
app/
├── main.js              ← コア機能のみ（500行程度）
├── ipc/
│   ├── clipboard-handlers.js    ← クリップボード関連IPC
│   ├── snippet-handlers.js      ← スニペット関連IPC
│   ├── settings-handlers.js     ← 設定関連IPC
│   └── auth-handlers.js         ← 認証関連IPC
├── common/
│   ├── google-auth.js
│   ├── sheets-api.js
│   ├── drive-api.js
│   └── member-manager.js
└── *.html
```

### 2. main.js の分割ポイント

| 機能グループ             | 行数目安 | 分割先                  |
| ------------------------ | -------- | ----------------------- |
| クリップボード監視・履歴 | 200 行   | `clipboard-handlers.js` |
| スニペット管理           | 300 行   | `snippet-handlers.js`   |
| ホットキー管理           | 150 行   | `settings-handlers.js`  |
| Google 認証・API         | 250 行   | `auth-handlers.js`      |
| ウィンドウ管理           | 300 行   | `main.js`に残す         |
| Tray・メニュー           | 100 行   | `main.js`に残す         |

### 3. 整理のメリット

- **Swift 版開発時**: 機能ごとにファイルを参照できる
- **AI への指示**: 「このファイルを Swift に移植して」が明確
- **保守性**: Windows 版の今後のメンテナンスも楽

---

## 🔧 Swift ならではの必要事項

### 1. Apple Developer Program

| 項目   | 状態    | 備考                     |
| ------ | ------- | ------------------------ |
| 登録   | ✅ 済み | チーム ID: F8KR53ZN3Y    |
| 証明書 | ✅ 済み | Electron 版で使用中      |
| App ID | 🔲 必要 | `com.addness.snipee-mac` |

### 2. Info.plist 設定（Electron には無かったもの）

| 設定                            | 用途                                    |
| ------------------------------- | --------------------------------------- |
| `LSUIElement = true`            | Dock に表示しない（メニューバーアプリ） |
| `NSAppleEventsUsageDescription` | AppleScript 使用の説明文                |
| `SUFeedURL`                     | Sparkle 自動更新 URL                    |
| `SUPublicEDKey`                 | Sparkle 署名用公開鍵                    |

### 3. Entitlements（権限ファイル）

| 権限                                         | 用途                 |
| -------------------------------------------- | -------------------- |
| `com.apple.security.automation.apple-events` | 他アプリへのペースト |
| `com.apple.security.network.client`          | Google API 通信      |
| Keychain Access Groups                       | トークン保存         |

### 4. 必要な Swift ライブラリ

| 用途             | ライブラリ                 | 備考                          |
| ---------------- | -------------------------- | ----------------------------- |
| 自動アップデート | Sparkle 2.x                | electron-updater の代替       |
| HTTP 通信        | URLSession                 | 標準ライブラリ（axios 不要）  |
| JSON パース      | Codable                    | 標準ライブラリ                |
| XML パース       | XMLParser                  | 標準ライブラリ（xml2js 不要） |
| OAuth 認証       | ASWebAuthenticationSession | 標準ライブラリ                |

### 5. Electron で必要だったけど Swift では不要なもの

| Electron         | Swift 代替        |
| ---------------- | ----------------- |
| electron-store   | UserDefaults      |
| keytar           | Keychain Services |
| electron-updater | Sparkle           |
| axios            | URLSession        |
| xml2js           | XMLParser         |
| robotjs/koffi    | CGEvent（標準）   |

---

## 📊 機能マッピング表（AI に渡す用）

### コア機能

| Electron (main.js)          | Swift                      | 説明                   |
| --------------------------- | -------------------------- | ---------------------- |
| `electron-store`            | `UserDefaults` + `Codable` | データ永続化           |
| `clipboard.readText()`      | `NSPasteboard.general`     | クリップボード読み取り |
| `globalShortcut.register()` | `CGEvent` tap              | グローバルホットキー   |
| `Tray`                      | `NSStatusBar`              | メニューバーアイコン   |
| `BrowserWindow`             | `NSPanel` + `SwiftUI`      | ポップアップウィンドウ |
| `keytar`                    | `Keychain Services`        | トークン保存           |
| `electron-updater`          | `Sparkle`                  | 自動アップデート       |
| `ipcMain.handle()`          | 不要（直接呼び出し）       | プロセス間通信         |
| `osascript`                 | `CGEvent` + `NSWorkspace`  | 自動ペースト           |

### 画面マッピング

| Electron HTML         | Swift View           | 用途               |
| --------------------- | -------------------- | ------------------ |
| `index.html`          | `ClipboardPopupView` | クリップボード履歴 |
| `snippets.html`       | `SnippetPopupView`   | スニペット選択     |
| `history.html`        | `HistoryPopupView`   | 履歴専用           |
| `settings.html`       | `SettingsView`       | 設定画面           |
| `snippet-editor.html` | `SnippetEditorView`  | スニペット編集     |
| `login.html`          | `LoginView`          | Google ログイン    |
| `welcome.html`        | `WelcomeView`        | 初回セットアップ   |

---

## 🚀 1 日で完成させる実装手順

### 前提

- Claude/AI に現状の Electron コードを渡して移植させる
- Xcode プロジェクトの基本セットアップは手動

### Step 1: 準備（30 分）

1. **Xcode で新規プロジェクト作成**

   - macOS App → SwiftUI → `SnipeeMac`
   - `snipee/snipee-mac/` に配置

2. **基本設定**

   - Bundle ID: `com.addness.snipee-mac`
   - Deployment Target: macOS 12.0+
   - App Sandbox: OFF（アクセシビリティ API に必要）

3. **Sparkle 追加**
   - Swift Package Manager
   - URL: `https://github.com/sparkle-project/Sparkle`

### Step 2: コア機能移植（2 時間）

**AI への指示例**:

> 「以下の Electron main.js のクリップボード監視機能を Swift に移植してください。
>
> - 0.5 秒間隔で NSPasteboard を監視
> - 変更があれば ClipboardItem 配列に追加
> - 最大 100 件保持
> - UserDefaults に保存」

移植する機能:

1. クリップボード監視 (`startClipboardMonitoring`)
2. 履歴管理 (`addToClipboardHistory`)
3. データ保存 (`electron-store` → `UserDefaults`)

### Step 3: UI 移植（2 時間）

**AI への指示例**:

> 「以下の index.html の UI を SwiftUI で再現してください。
>
> - 検索バー
> - 履歴リスト（ピン留めアイコン付き）
> - 右クリックメニュー（削除、ピン留め）
> - フォルダ展開/折りたたみ」

移植する画面:

1. クリップボードポップアップ (`index.html`)
2. スニペットポップアップ (`snippets.html`)
3. 設定画面 (`settings.html`)

### Step 4: グローバルホットキー（1 時間）

**AI への指示例**:

> 「macOS で Cmd+Ctrl+C のグローバルホットキーを登録し、
> 押されたらコールバックを実行する HotkeyManager クラスを作成してください。
> CGEventTap を使用し、アクセシビリティ権限チェックも含めてください。」

### Step 5: Google 認証・API（2 時間）

**AI への指示例**:

> 「以下の google-auth.js を Swift に移植してください。
>
> - ASWebAuthenticationSession で OAuth 認証
> - トークンを Keychain に保存
> - リフレッシュトークンで自動更新」

移植するファイル:

1. `google-auth.js` → `GoogleAuthService.swift`
2. `sheets-api.js` → `SheetsAPIService.swift`
3. `drive-api.js` → `DriveAPIService.swift`

### Step 6: 仕上げ（1 時間）

1. Info.plist 設定
2. Entitlements 設定
3. アイコン設定
4. 動作テスト

---

## ✅ AI に渡すファイル一覧

### 必須（これを渡せば移植できる）

| ファイル                   | 用途              | 行数    |
| -------------------------- | ----------------- | ------- |
| `main.js`                  | 全機能のロジック  | 1500 行 |
| `index.html`               | クリップボード UI | 500 行  |
| `snippets.html`            | スニペット UI     | 400 行  |
| `settings.html`            | 設定 UI           | 800 行  |
| `snippet-editor.html`      | エディタ UI       | 1000 行 |
| `common/google-auth.js`    | OAuth 認証        | 150 行  |
| `common/sheets-api.js`     | Sheets API        | 80 行   |
| `common/drive-api.js`      | Drive API         | 60 行   |
| `common/member-manager.js` | メンバー管理      | 100 行  |

### 参考（デザイン・仕様確認用）

| ファイル               | 用途                 |
| ---------------------- | -------------------- |
| `common/variables.css` | カラー・フォント定義 |
| `common/common.css`    | 共通スタイル         |
| `common/utils.js`      | ヘルパー関数         |
| `HANDOVER.md`          | 全体仕様・設計思想   |

---

## 📅 タイムライン

### 1 日プラン（AI 活用）

| 時間      | 作業                                       |
| --------- | ------------------------------------------ |
| 0:00-0:30 | Xcode プロジェクトセットアップ             |
| 0:30-2:30 | コア機能移植（クリップボード、データ保存） |
| 2:30-4:30 | UI 移植（ポップアップ、設定画面）          |
| 4:30-5:30 | グローバルホットキー                       |
| 5:30-7:30 | Google 認証・API                           |
| 7:30-8:00 | 仕上げ・テスト                             |

### 手動開発の場合（2-3 週間）

| 週     | 作業                                           |
| ------ | ---------------------------------------------- |
| Week 1 | 基盤（メニューバー、データ保存、ポップアップ） |
| Week 2 | 機能（ホットキー、クリップボード、ペースト）   |
| Week 3 | API 連携（OAuth、Sheets、Drive）、仕上げ       |

---

## 🔒 移行後のリポジトリ運用

### GitHub Actions 変更

**現状**:

```yaml
jobs:
  publish-mac: # Mac版ビルド
  publish-windows: # Windows版ビルド
```

**移行後**:

```yaml
jobs:
  # publish-mac: 削除（Xcodeで手動ビルド or 別CIへ）
  publish-windows: # Windows版のみ継続
```

### リリース管理

| バージョン | 内容                                          |
| ---------- | --------------------------------------------- |
| v2.x.x     | Electron 版（Mac + Windows）                  |
| v3.0.0     | Mac: Swift 版リリース、Windows: Electron 継続 |
| v3.x.x     | Mac: Swift 版、Windows: Electron 版（別管理） |

### README 更新

```markdown
## ダウンロード

### Mac 版（Swift・推奨）

- [Snipee-Mac.dmg](リンク)

### Windows 版

- [Snipee-Setup.exe](リンク)
```

---

## ⚠️ 注意点

### アクセシビリティ権限

- **必須**: グローバルホットキー、自動ペースト
- 初回起動時にシステム環境設定への案内が必要
- Electron 版の`permission-guide.html`と同等の UX を実装

### データ移行

| 項目           | Electron 版                                                   | Swift 版                                    |
| -------------- | ------------------------------------------------------------- | ------------------------------------------- |
| 設定データ     | `~/Library/Application Support/snipee/config.json`            | `UserDefaults`                              |
| 個別スニペット | `~/Library/Application Support/snipee/personal-snippets.json` | `~/Documents/Snipee/personal-snippets.json` |

**必要な機能**: 初回起動時に Electron 版のデータをインポートするオプション

### 並行運用期間

1. Swift 版 v1.0 リリース
2. 2 週間の並行運用（バグ報告収集）
3. 問題なければ Electron Mac 版を非推奨化
4. 1 ヶ月後に Electron Mac 版のビルドを停止

---

## 📝 チェックリスト

### Phase 1: Swift 化前（Electron 整理）

- [ ] main.js を機能別に分割（or コメントで区切りを明確に）
- [ ] 不要なコメント・デバッグコード削除
- [ ] 各ファイルに機能説明コメント追加
- [ ] HANDOVER に機能一覧を詳細化

### Phase 2: Swift 版開発

- [ ] Xcode プロジェクト作成
- [ ] メニューバーアイコン表示
- [ ] クリップボード監視・履歴
- [ ] ポップアップ UI（履歴、スニペット）
- [ ] グローバルホットキー
- [ ] 自動ペースト（CGEvent）
- [ ] スニペット機能（フォルダ、検索）
- [ ] 変数置換機能
- [ ] Google OAuth 認証
- [ ] Sheets/Drive API 連携
- [ ] 設定画面（4 タブ）
- [ ] スニペットエディタ
- [ ] Sparkle 自動アップデート
- [ ] コード署名・公証

### Phase 3: リリース

- [ ] DMG インストーラー作成
- [ ] appcast.xml 作成（Sparkle 用）
- [ ] GitHub Releases 公開
- [ ] README 更新
- [ ] HANDOVER.md 更新
- [ ] Electron 版からのデータ移行機能

---

## 🎯 成功の定義

Swift 版が「成功」と言えるのは：

1. **全機能が Electron 版と同等に動作**
2. **仮想デスクトップ問題が解消**
3. **メモリ使用量が 50MB 以下**
4. **起動が 1 秒以内**
5. **自動アップデートが機能**
6. **Electron 版ユーザーがスムーズに移行できる**

---

**作成日**: 2026-01-12
