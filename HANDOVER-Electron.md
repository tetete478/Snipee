# Snipee HANDOVER — Windows (Electron)

**最終更新**: 2026-03-06  
**GitHub**: https://github.com/tetete478/snipee

---

## 🚩 現在地

- v2.0.8 リリース完了
- 3/06 XMLパース失敗時のマスタ全消失バグ修正（sync-service.js）
- 3/06 build-windows.yml バージョン更新方式修正（npm version → node直接書き換え）
- Syncthing の node_modules 無視設定済み

---

## 📋 プロジェクト概要

Clipyの代替として、チーム20人で使えるクロスプラットフォーム対応のクリップボード管理ツール。

- **Windows版**: Electron（本ドキュメントの対象）
- **Mac版**: Swift/SwiftUI（SnipeeMac）
- **iOS版**: Swift/SwiftUI + カスタムキーボード

### 配布方針（最重要）

- **ダブルクリックで起動**（Node.js不要）
- 非エンジニアでも簡単に使える
- 自動アップデートでユーザーは何もしなくてOK

---

## 🔧 技術スタック

| 用途 | 技術 |
|------|------|
| フレームワーク | Electron |
| データ保存 | electron-store |
| XML解析 | xml2js（Clipy互換） |
| 自動ペースト | PowerShell + robotjs |
| 自動アップデート | electron-updater + GitHub Releases |
| ビルド | electron-builder |
| CI/CD | GitHub Actions（win-v*タグで自動ビルド） |

---

## 🚀 リリース手順

```bash
git add . && git commit -m "変更内容" && git tag win-vX.X.X && git push origin main && git push origin win-vX.X.X
```

GitHub Actionsが自動でビルド・アップロードまで実行する。  
**package.jsonのバージョンはActionsが自動でタグから設定するので手動変更不要。**

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
│   ├── settings.html         # 設定画面
│   ├── welcome.html          # 初回ウェルカム画面
│   ├── permission-guide.html # アクセシビリティ権限ガイド
│   └── common/
│       ├── variables.css     # CSS変数・テーマ定義
│       ├── common.css        # 共通スタイル
│       ├── utils.js          # 共通JavaScript
│       ├── theme.js          # テーマ管理
│       └── drag-drop.js      # ドラッグ&ドロップ
├── build/
│   ├── installer.nsh         # NSISカスタムスクリプト
│   ├── icon.ico              # Windowsアイコン
│   └── ...
├── .github/workflows/
│   └── build-windows.yml     # GitHub Actions（Windowsビルド）
├── HANDOVER-Windows.md
└── UPDATE_LOG.md
```

---

## ⚠️ 絶対やってはいけないこと

### ❌ 複数ウィンドウ IPC 通信
**失敗**: サブメニュー用に別ウィンドウ作成 → アプリがフリーズ  
**解決**: 単一HTML内でインライン表示

### ❌ 同期処理で重い操作
**失敗**: 起動時にGoogle Drive同期を同期実行 → 起動に1分  
**解決**: ホットキー登録を最優先、同期は非同期

### ❌ googleapis@170+を使う
**失敗**: gaxios@7.xがasarパッケージング時にシンボリックリンク構造でクラッシュ  
**解決**: `googleapis@144.0.0` に固定

### ❌ openDevTools() を resizable:false ウィンドウで呼ぶ
**失敗**: ウィンドウがネイティブレベルで破壊される（closedイベントのみ発火）  
**解決**: 開発時のみ、resizable:trueにしてから呼ぶ

### ❌ XMLパース結果が空でもローカルを上書きしない
**失敗**: XMLパース失敗時に空配列 `[]` をそのまま保存 → マスタ全消失  
**解決**: パース結果が空またはエラーの場合はローカルデータを保護する（sync-service.js）

### ❌ npm version をGitHub Actionsで使う
**失敗**: .envファイル作成でgitが汚れ、npm versionが失敗 → タグと違うバージョンでビルド  
**解決**: `node -e` でpackage.jsonを直接書き換える方式に変更

---

## 🔄 変更履歴

### 2026-03-06（v2.0.8）

- **XMLパース失敗時のマスタ全消失バグ修正**（services/sync-service.js）
  - パース結果が空・エラー時はローカルデータを保護
- **build-windows.yml バージョン更新修正**
  - `npm version` → `node -e` でpackage.jsonを直接書き換える方式に変更
  - .envファイル作成によるgit汚染でバージョンがタグと一致しない問題を解消
- **Syncthing node_modules 無視設定**
  - node_modulesをSyncthing無視リストに追加（Mac↔Windows間の競合解消）

---

## 🗓️ TODO

### 🟡 改善
- 個別スニペットのクラウド同期（Mac・iOS版は実装済み、Windows版は未着手）
- main.jsのモジュール分割（ongoing）

### 🟢 将来
- contextIsolation / preload.js 移行（セキュリティ強化）
- Electron バージョンアップ
- IMEホットキー問題解消

---

## 🔍 トラブルシューティング

### ホットキーが効かない
| 原因 | 対処 |
|------|------|
| IME有効時 | 英数モードに切り替え |
| 他アプリと競合 | 別のホットキーに変更 |

### Google Drive 同期失敗
| 原因 | 対処 |
|------|------|
| URL不正 | `https://drive.google.com/file/d/FILE_ID/view` 形式に |
| 共有設定 | 「リンクを知っている全員」に設定 |

### アクションが走らない
タグのpushが失敗している可能性が高い。`git push origin win-vX.X.X` を単体で再実行。

### リベース中断でpushできない
```bash
git rebase --abort && git pull origin main --rebase && git push origin main && git push origin win-vX.X.X
```

### デバッグ
```javascript
ipcRenderer.send('log', 'message'); // rendererのconsole.logは使わない
```