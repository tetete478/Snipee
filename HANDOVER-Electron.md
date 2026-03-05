# Snipee HANDOVER — Electron (Windows)

**最終更新**: 2026-03-05

---

## 🚩 現在地

### やっていること
マスタスニペットの編集機能強化（フォルダ名・スニペット名変更）+ リリース準備。

### 完了済み
- Phase 0〜4: リファクタリング全フェーズ ✅
- 個別スニペットのクラウド同期 ✅
- ログアウト処理の完全実装（方針A） ✅
- ロール別権限のバックエンド強化 ✅
- IPCハンドラー重複3件修正 ✅
- Syncthing sync-conflictファイル・「2付き」ファイル削除 ✅

### 今ここ
マスタのフォルダ名・スニペット名変更対応、その後リリース。

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

### 3. ❌ CLIENT_SECRETをPublicリポジトリに公開
**対策**: .envに分離 + .gitignore + GCP「内部」設定

### 4. ❌ Google Drive APIで共有ドライブを忘れる
**失敗**: 404エラーでアップロード失敗
**解決**: `supportsAllDrives=true` パラメータを追加

### 5. ❌ handleLogout() でログイン画面より先にウィンドウを全閉じする
**失敗**: window-all-closed → app.quit() が発火してアプリが終了する
**解決**: createLoginWindow() を先に呼んでから他のウィンドウを閉じる

### 6. ❌ openDevTools() を resizable: false のウィンドウで呼ぶ
**失敗**: ウィンドウがネイティブレベルで破棄される（closed イベントのみ発火）
**解決**: DevTools が必要なら resizable: true にするか別ウィンドウで開く

### 7. ❌ querySelector の属性セレクタで日本語を含む値を検索する
**失敗**: `querySelector('[data-folder="担当決め_管理"]')` → NULL を返す
**解決**: `querySelectorAll` で全要素取得後に `dataset` で比較する
```javascript
const el = [...document.querySelectorAll('.folder-header')]
  .find(el => el.dataset.folder === folderName);
```

### 8. ❌ Electronリファクタリングで一度に全ファイル書き換え
**解決**: フェーズ分割＋各フェーズ後に検証。str_replaceで差分修正。

### 9. ❌ Electron clipboardHistoryを単純export
**解決**: appState.clipboard.historyとして共有オブジェクト内に保持

### 10. ❌ ログアウト後に startApp() を呼んでもホットキーが反応しない
**解決**: startApp() の先頭で registerGlobalShortcuts() を呼ぶ

---

## 📊 機能対応表

| 機能                         | Windows (Electron) | Mac (Swift) | iOS (Swift) |
| ---------------------------- | :----------------: | :---------: | :---------: |
| クリップボード履歴           |         ✅         |     ✅      |     ❌      |
| 履歴ピン留め                 |         ✅         |     ✅      |     ❌      |
| スニペット表示・編集         |         ✅         |     ✅      |     ✅      |
| フォルダ管理                 |         ✅         |     ✅      |     ✅      |
| ホットキー起動・カスタマイズ |         ✅         |     ✅      |     ❌      |
| 自動ペースト                 |         ✅         |     ✅      |     ❌      |
| Google OAuth（PKCE）         |         ✅         |     ✅      |     ✅      |
| メンバー認証（スプシ）       |         ✅         |     ✅      |     ✅      |
| マスタ同期・アップロード     |         ✅         |     ✅      |     ❌      |
| 個別スニペット同期           |         ✅         |     ✅      |     ✅      |
| 自動アップデート             |         ✅         |     ✅      |     ✅      |
| XMLインポート/エクスポート   |         ✅         |     ✅      |     ❌      |
| 管理者機能                   |         ✅         |     ✅      |     ❌      |
| 変数置換（16種）             |         ✅         |     ✅      |     ✅      |

---

## 🔧 リファクタリング状況

| フェーズ | 内容 | 状態 |
|---------|------|------|
| Phase 0 | ファイルリネーム | ✅ |
| Phase 1 | モデル作成（6ファイル） | ✅ |
| Phase 2 | constants.js 作成 | ✅ |
| Phase 3 | サービス抽出（6サービス） | ✅ |
| Phase 4 Step 1 | appState集約 + main.js変換 | ✅ |
| Phase 4 Step 2 | IPCハンドラ分離（4ファイル） | ✅ |
| Phase 4 クリーンアップ | 未使用require・空行削除 | ✅ |
| Phase 5 | console.log削除（Claude Code依頼済み） | 🔄 |

- main.js: **1,922行 → 約600行**

---

## 📁 ファイル構成

```
app/
├── main.js
├── app-state.js
├── ipc/
│   ├── auth-handlers.js
│   ├── clipboard-handlers.js
│   ├── settings-handlers.js
│   ├── snippet-handlers.js
│   └── window-handlers.js
├── models/
│   ├── app-settings.js / department.js / history-item.js
│   ├── member.js / snippet.js / user-status.js
├── services/
│   ├── google-auth-service.js
│   ├── google-drive-service.js
│   ├── google-sheets-service.js
│   ├── member-manager.js
│   ├── variable-service.js
│   ├── storage-service.js / paste-service.js / sync-service.js
│   ├── user-report-service.js / snippet-import-export-service.js
│   ├── snippet-promotion-service.js / personal-sync-service.js
├── theme/ utilities/ views/
```

---

## 🔧 ビルド・リリース

```bash
# リリース
git tag win-v1.9.9
git push origin win-v1.9.9
```

---

## 🚨 未解決の問題

なし（現時点）

---

## 🗓️ TODO

### 🔴 最優先
1. **マスタのフォルダ名・スニペット名変更対応**（snippet-editor.html）
   - `startRenameFolder`: querySelector → dataset比較方式に修正（修正案作成済み）
   - マスタスニペット名変更も同様に対応
2. **Windowsからマスタ更新**（⬆️ マスタ更新ボタン）動作確認
3. **v1.9.9リリース → 自動アップデート確認**
4. Phase 5: console.log削除

### 🟡 差分埋め
- 履歴グループ分け表示 / Pキーピン留め / エディタ前後移動 / バックアップ復元UI

---

## 🔄 変更履歴

### 2026-03-05

- **snippet-editor.html: startRenameFolder バグ特定**
  - `querySelector('[data-folder="日本語"]')` がNULLを返す問題を確認（デバッグログで特定）
  - 修正案: dataset比較方式に変更（明日適用予定）
- **Syncthing競合ファイル削除**（`* 2.*` / `*.sync-conflict-*`）
- **IPCハンドラー重複3件修正**
- **window-handlers.js 復元**（Syncthing同期トラブルで消失）
- **google-sheets-service.js: require パス修正**（`./google-auth` → `./google-auth-service`）

### 2026-03-04

- ログアウト処理の完全実装（方針A）
- ロール別権限のバックエンド強化（12ハンドラー）

### 2026-02-28

- 個別スニペット クラウド同期実装
- Phase 4 Step 2: IPCハンドラ分離完了

### 2026-02-03

- Windows版：Mac版との完全機能統一
- Electronリファクタリング（Phase 0〜4）