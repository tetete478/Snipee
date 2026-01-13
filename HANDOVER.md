# Snipee 開発引き継ぎドキュメント

**バージョン**: v2.1.0  
**最終更新**: 2026-01-12  
**GitHub**: https://github.com/tetete478/snipee

---

## 📌 プロジェクト概要

### 目的

Clipy の代替として、チーム（主に Windows ユーザー）で使えるクロスプラットフォーム対応のクリップボード管理ツール。

**重要**: Snipee の主目的は**Windows ユーザーのスニペット簡易化**。Mac には Clipy があるため、Mac 版は副次的。

### 主要機能

- クリップボード履歴管理（最大 100 件）
- **【v2.0】Google Workspace 認証（OAuth 2.0）**
- **【v2.0】部署別マスタスニペット管理**
- **【v2.0】XML インポート/エクスポート機能**
- ローカルスニペット（個別スニペット）
- カスタマイズ可能なホットキー
- Mac/Windows 対応
- 自動アップデート機能（GitHub Releases 経由）
- 変数機能（日付、名前などの動的挿入）
- 履歴専用ウィンドウ
- 初回ウェルカム画面（セットアップウィザード）
- DMG ドラッグインストール対応
- カラーテーマ機能（9 種類）

### 配布方針（最重要）

- **ダブルクリックで起動**（Node.js 不要）
- 非エンジニアでも簡単に使える
- **自動アップデートでユーザーは何もしなくて OK（Mac/Windows 両対応）**

---

## 🔧 技術スタック

### v2.0（現行）

| 用途                    | 技術                                             |
| ----------------------- | ------------------------------------------------ |
| フレームワーク          | Electron                                         |
| データ保存              | electron-store                                   |
| XML 解析                | xml2js（Clipy 互換）                             |
| 自動ペースト（Mac）     | AppleScript + Bundle ID                          |
| 自動ペースト（Windows） | koffi（Windows API 直接呼び出し）                |
| 自動アップデート        | electron-updater + GitHub Releases               |
| ビルド                  | electron-builder                                 |
| CI/CD                   | GitHub Actions（タグプッシュで自動ビルド）       |
| 認証                    | Google OAuth 2.0                                 |
| トークン保存            | keytar（OS 標準: Keychain/Credential Manager）   |
| メンバー管理            | Google Sheets API                                |
| マスタ XML 管理         | Google Drive API                                 |
| Mac 署名                | Apple Developer Program（チーム ID: F8KR53ZN3Y） |

---

## 🚀 リリース手順

### 新バージョンのリリース
```bash
# 1. package.json のバージョンを更新

# 2. 1行コマンドでリリース
git add . && git commit -m "v2.1.0: 変更内容" && git push && git tag v2.1.0 && git push origin v2.1.0
```

### 自動で実行されること
```
タグをプッシュ → GitHub Actions 起動 → Mac/Windows 並行ビルド → 署名・公証 → GitHub Releases にアップロード
```

### リリース後の確認

1. GitHub → Actions タブで両方のジョブが成功しているか確認
2. https://github.com/tetete478/snipee/releases にアクセス
3. Draft 状態なら「Edit」→「Publish release」をクリック

### リリース前のセキュリティチェック
```bash
npm audit          # 脆弱性チェック
npm audit fix      # 安全な範囲で自動修正
```

### ローカル開発
```bash
cd /path/to/snipee
npm install
npx electron-rebuild  # robotjs のリビルド
npm start
```

---

## 📂 プロジェクト構造
```
snipee/
├── app/
│   ├── main.js               # メインプロセス
│   ├── index.html            # 簡易ホーム（クリップボード履歴）
│   ├── snippets.html         # スニペット専用ホーム
│   ├── history.html          # 履歴専用ウィンドウ
│   ├── snippet-editor.html   # スニペット編集画面
│   ├── settings.html         # 設定画面（管理タブ追加）
│   ├── welcome.html          # 初回ウェルカム画面
│   ├── login.html            # 【v2.0】Googleログイン画面
│   ├── permission-guide.html # アクセシビリティ権限ガイド
│   └── common/
│       ├── variables.css     # CSS変数・テーマ定義
│       ├── common.css        # 共通スタイル
│       ├── utils.js          # 共通JavaScript
│       ├── theme.js          # テーマ管理
│       ├── drag-drop.js      # ドラッグ&ドロップ
│       ├── google-auth.js    # 【v2.0】Google認証
│       ├── sheets-api.js     # 【v2.0】Sheets API連携
│       ├── drive-api.js      # 【v2.0】Drive API連携
│       └── member-manager.js # 【v2.0】メンバー・部署管理
├── build/
│   └── ...                   # ビルド用アセット
├── .env                      # 【v2.0】OAuth認証情報（gitignore）
├── HANDOVER.md               # このファイル
└── UPDATE_LOG.md             # 更新履歴（ユーザー向け）
```

---

## ⚠️ 絶対やってはいけないこと

### 1. ❌ 複数ウィンドウ IPC 通信

**失敗**: サブメニュー用に別ウィンドウ作成 → アプリがフリーズ  
**解決**: 単一 HTML 内でインライン表示  
**教訓**: 新しいウィンドウを作る前に、必ずインライン表示で実装できないか検討

### 2. ❌ 同期処理で重い操作

**失敗**: 起動時に Google Drive 同期を同期実行 → 起動に 1 分  
**解決**: ホットキー登録を最優先、同期は非同期  
**教訓**: 起動順序は「ホットキー登録 → UI 表示 → データ同期」

### 3. ❌ デフォルトホットキーで競合

**失敗**: `Cmd+C/V` → 標準コピペと競合  
**解決**: `Command+Control+C/V` (Mac), `Ctrl+Alt+C/V` (Windows)  
**教訓**: 修飾キー 2 つ以上使う

### 4. ❌ 同期処理で UI 更新

**失敗**: blur イベントで同期保存 → UI freeze  
**解決**: UI 更新を先に実行、保存は非同期  
**教訓**: `await` は必ず UI 更新の後に

### 5. ❌ app.isQuitting を設定せずに終了

**失敗**: `app.quit()` だけだと mainWindow の close イベントで preventDefault される  
**解決**: 終了前に必ず `app.isQuitting = true` を設定  
**教訓**: `before-quit` イベントでフラグを設定する

---

## ✅ 完了した作業

### v2.1.0（2026-01-12）

**UI改善:**
- 設定画面タブ統合（6タブ→4タブ: 一般/表示・操作/アカウント/管理者）
- ログイン画面にドメイン注意書き追加
- ログイン失敗時「別のアカウントでログイン」ボタン追加
- 管理者タブにスプシリンク追加

**権限名変更:**
- 「編集者」→「管理者」に名称変更

**スプシ構造変更:**
- メンバーリスト列構成: A=スタッフ名, B=メールアドレス, C=部署, D=権限
- 部署ごとの空行対応（空行スキップ処理追加）

### v2.0.0（2026-01-12）

**Google Workspace 連携:**

- Google OAuth 2.0 認証
- keytar によるトークン安全保存
- Google Sheets API でメンバー管理
- Google Drive API で部署別 XML 管理

**部署別マスタスニペット:**

- 部署ごとに異なる XML を読み込み
- 権限に応じた表示制御（最高管理者/管理者/一般）
- 2 時間ごとの自動同期

**インポート/エクスポート機能:**

- settings.html「管理」タブ追加（最高管理者/管理者のみ）
- snippet-editor.html「Import」ボタン追加
- マスタスニペット: すり替え方式
- 個別スニペット: 追加・更新方式（同名は更新、新規は追加）

**認証フロー:**

- ログイン画面 UI
- 未登録ユーザー案内
- 自動ログイン（トークン再利用）

**権限構造:**

| 権限       | XML を見る    | XML 編集      | メンバー追加         |
| ---------- | ------------- | ------------- | -------------------- |
| 一般       | ✅ 自部署のみ | ❌            | ❌                   |
| 管理者     | ✅ 自部署のみ | ✅ 自部署のみ | ❌                   |
| 最高管理者 | ✅ 全部署     | ✅ 全部署     | ✅（スプシ直接編集） |

### v1.6.0（Mac 署名対応）

**Mac コード署名・公証（notarization）:**

- Apple Developer Program 登録完了（チーム ID: F8KR53ZN3Y）
- GitHub Actions で自動署名・公証
- Mac 自動アップデート有効化

### v1.5.31（2025-01-11）

**Mac 終了問題の修正:**

- `app.on('before-quit')` を追加してシステム再起動/シャットダウン時に正常終了
- `quit-app` ハンドラに `app.isQuitting = true` を追加

**Mac 仮想デスクトップ固定化防止:**

- `setVisibleOnAllWorkspaces` に `skipTransformProcessType: true` オプション追加
- `show()` 後に `setTimeout` で再設定を追加

### v1.5.30 以前

- 個別スニペット表示改善
- Windows 速度大幅改善（koffi 導入）
- カラーテーマ機能（9 種類）
- 履歴専用ウィンドウ
- 初回ウェルカム画面
- Mac/Windows 自動ペースト
- 変数機能
- マスタ編集モード
- XML エクスポート機能

---

## 🔐 セキュリティ対策（v2.0）

**実装済み対策**

| 対策                    | 内容                           | 状態 |
| ----------------------- | ------------------------------ | ---- |
| OAuth 情報を.env に分離 | `.env` + `.gitignore`          | ✅   |
| GCP「内部」設定         | OAuth 同意画面を「内部」に     | ✅   |
| keytar でトークン保存   | OS 標準の暗号化ストレージ      | ✅   |
| Mac コード署名          | Apple Developer Program で署名 | ✅   |

**GitHub について**

- リポジトリは **Public** のまま運用
- 機密情報（OAuth 情報、スプシ ID）は `.env` に分離済み
- GCP「内部」設定により組織外からのログイン不可
- Private 化すると自動更新が複雑になるため、現状維持

**推奨対策（v2.2 以降）**

| 対策                   | 内容                     |
| ---------------------- | ------------------------ |
| contextIsolation: true | XSS 攻撃からの保護       |
| preload.js 移行        | Node.js API の安全な公開 |

**.env ファイル構成**
```env
# .env（.gitignoreに追加必須）
GOOGLE_CLIENT_ID=xxxxx
GOOGLE_CLIENT_SECRET=xxxxx
SPREADSHEET_ID=xxxxx
```

---

## 🗓️ TODO / ロードマップ

### 🔴 最優先

- [ ] Windows 動作確認・テスト
- [ ] ドキュメント整備（ユーザーマニュアル）

### 🟡 機能追加（v2.2）

- タグ機能（マスタ/個別スニペットにタグ付け、フィルタリング）
- 検索機能強化（スニペット内容の全文検索）
- お気に入り機能（よく使うスニペットをピン留め）
- 変数機能拡張（カスタム変数: `{会社名}` など）

### 🟢 UI/UX 改善

- snippet-editor.html タイトル・タグ表示改善
- フォントサイズ設定（ユーザーが調整可能）
- キーボードショートカット拡充

### 🔵 安定性・パフォーマンス

- Windows 自動ペースト改善（フォーカス管理の安定化）
- IME ホットキー問題（日本語入力時の不安定さ解消）
- エラーハンドリング（Google Drive 同期失敗時のリトライ）

### ⚪ セキュリティ強化（v2.2 以降）

**contextIsolation / preload.js 移行**

現状:
```javascript
nodeIntegration: true,
contextIsolation: false
```

推奨設定:
```javascript
nodeIntegration: false,
contextIsolation: true,
preload: path.join(__dirname, 'preload.js')
```

### 🔘 将来検討

**Mac 版を Swift で書き直し**

- Electron は Mac の仮想デスクトップと相性が悪い
- Mac ユーザーには本家 Clipy を推奨する手もある
- v2.0 のアーキテクチャなら Swift 移行も容易（Google API を叩くだけ）

**モバイル版**

- メッセージ対応時にスマホでもスニペット使いたいニーズ
- Flutter or React Native で実装可能
- v2.0 のアーキテクチャなら追加しやすい

---

## 🛠️ 開発ルール

### コード修正時

1. **提案してから実装**: 修正内容を先に提示して許可を得る
2. **場所を明示**: ファイル名、行番号、修正タイプを明記
3. **共通化チェック**: 新しいコードを書く前に common/ に入れられないか確認

### リリース前チェックリスト

1. `npm audit` で脆弱性チェック
2. 全画面の動作確認
3. package.json のバージョン更新
4. HANDOVER.md と UPDATE_LOG.md の更新
5. Git tag でリリース

---

## 📚 参考情報

### スプシ構造（v2.1）

**シート 1: メンバーリスト**

| スタッフ名 | メールアドレス      | 部署                 | 権限       |
| ---------- | ------------------- | -------------------- | ---------- |
| 小松晃也   | komatsu@company.com | 営業,営業管理,マーケ | 最高管理者 |
| 田中太郎   | tanaka@company.com  | マーケ               | 管理者     |
| 鈴木花子   | suzuki@company.com  | 営業                 | 一般       |

※部署ごとに空行を入れてもOK（空行はスキップされる）

**シート 2: 部署設定**

| 部署     | XML ファイル ID |
| -------- | --------------- |
| 営業     | 1ABC123...      |
| 営業管理 | 1DEF456...      |
| マーケ   | 1GHI789...      |

### デフォルトホットキー

| 機能           | Mac          | Windows      |
| -------------- | ------------ | ------------ |
| 簡易ホーム     | `Cmd+Ctrl+C` | `Ctrl+Alt+C` |
| スニペット専用 | `Cmd+Ctrl+V` | `Ctrl+Alt+V` |
| 履歴専用       | `Cmd+Ctrl+X` | `Ctrl+Alt+X` |

### マスタ編集パスワード（レガシー）

`1108`

※v2.0 以降は Google 認証 + 権限で制御。ローカル編集用に残存しているが、将来的に削除予定。

---

**最終更新**: 2026-01-12