# Snipee Swift 化 引き継ぎドキュメント

**作成日**: 2026-01-13  
**最終更新**: 2026-01-14  
**目標**: Electron 版の全機能をネイティブ Swift アプリとして再実装

---

## 📊 進捗サマリー

| Phase | 内容 | 状態 | 備考 |
|-------|------|------|------|
| Phase 1 | Xcodeプロジェクト準備 | ✅ 完了 | |
| Phase 2 | コア機能移植 | ✅ 完了 | 15ファイル作成 |
| Phase 3 | ポップアップUI | ✅ 完了 | 8ファイル作成 |
| Phase 4 | システム連携 | ✅ 完了 | ホットキー・ペースト動作確認済 |
| Phase 5 | 設定画面 | ✅ 完了 | 4タブ構成 |
| Phase 6 | スニペットエディタ | ✅ 完了 | 3ペイン構成 |
| Phase 7 | Google連携 | 🎯 次 | OAuth設定必要 |
| Phase 8 | オンボーディング | ⬜ 未着手 | |
| Phase 9 | 仕上げ | ⬜ 未着手 | |

**進捗率**: 約 65%（6/9 Phase完了）

---

## 🏗️ 作成済みファイル一覧

### App/ (2ファイル)
- [x] `SnipeeMacApp.swift` - エントリーポイント
- [x] `AppDelegate.swift` - NSApplicationDelegate

### Models/ (5ファイル)
- [x] `Snippet.swift` - スニペット構造体
- [x] `HistoryItem.swift` - 履歴アイテム
- [x] `Member.swift` - メンバー情報
- [x] `Department.swift` - 部署情報
- [x] `AppSettings.swift` - 設定

### Services/ (5ファイル)
- [x] `StorageService.swift` - データ永続化
- [x] `ClipboardService.swift` - クリップボード監視
- [x] `VariableService.swift` - 変数置換
- [x] `HotkeyService.swift` - グローバルホットキー
- [x] `PasteService.swift` - 自動ペースト

### Utilities/ (4ファイル)
- [x] `Constants.swift` - 定数定義
- [x] `KeychainHelper.swift` - Keychain操作
- [x] `XMLParserHelper.swift` - XML解析
- [x] `KeyboardNavigator.swift` - キーボード操作

### Theme/ (1ファイル)
- [x] `ColorTheme.swift` - 9テーマ定義

### Views/Popup/ (5ファイル)
- [x] `PopupWindowController.swift` - ポップアップ制御
- [x] `MainPopupView.swift` - メインポップアップ
- [x] `SnippetPopupView.swift` - スニペット専用
- [x] `HistoryPopupView.swift` - 履歴専用
- [x] `SubmenuView.swift` - サブメニュー

### Views/Components/ (3ファイル)
- [x] `ThemePicker.swift` - テーマ選択
- [x] `HotkeyField.swift` - ホットキー入力
- [x] `SearchField.swift` - 検索ボックス

### Views/Settings/ (5ファイル)
- [x] `SettingsView.swift` - 設定メイン
- [x] `GeneralTab.swift` - 一般タブ
- [x] `DisplayTab.swift` - 表示・操作タブ
- [x] `AccountTab.swift` - アカウントタブ
- [x] `AdminTab.swift` - 管理者タブ

### Views/Editor/ (4ファイル)
- [x] `SnippetEditorWindow.swift` - エディタウィンドウ
- [x] `SnippetEditorView.swift` - エディタメイン
- [x] `FolderSidebar.swift` - フォルダサイドバー
- [x] `ContentPanel.swift` - コンテンツパネル

**合計: 34ファイル作成済み**

---

## ✅ 動作確認済み機能

| 機能 | 状態 | 備考 |
|------|------|------|
| メニューバーアイコン | ✅ | クリップボードアイコン表示 |
| 左クリック → ポップアップ | ✅ | |
| 右クリック → メニュー | ✅ | |
| ホットキー Cmd+Ctrl+C | ✅ | メインポップアップ |
| ホットキー Cmd+Ctrl+V | ✅ | スニペットポップアップ |
| ホットキー Cmd+Ctrl+X | ✅ | 履歴ポップアップ |
| ホットキートグル（2回で閉じる） | ✅ | |
| クリップボード履歴 | ✅ | 自動収集動作 |
| 設定画面 | ✅ | 4タブ表示 |
| スニペットエディタ | ✅ | 3ペイン表示 |
| テーマ切り替え | ⚠️ | UI実装済、反映は部分的 |
| Google OAuth | ⬜ | 未実装 |
| マスタスニペット同期 | ⬜ | 未実装 |

---

## 🎯 次回セッションで実装するもの

### Phase 7: Google連携

#### 必要なファイル（Services/に追加）
- [ ] `GoogleAuthService.swift` - OAuth認証
- [ ] `SheetsAPIService.swift` - Sheets API
- [ ] `DriveAPIService.swift` - Drive API  
- [ ] `MemberManager.swift` - 権限管理
- [ ] `SyncService.swift` - 自動同期

#### 事前準備（必須）
1. **GCP プロジェクト設定**
   - OAuth 同意画面設定
   - OAuth クライアントID作成（macOS用）
   - リダイレクトURI: カスタムURLスキーム

2. **Xcode設定**
   - URL Schemes 追加（Info.plist）
   - xcconfig ファイル作成（Client ID/Secret）

---

## 🐛 既知の警告・課題

### 警告（動作に影響なし）
| ファイル | 内容 | 対応 |
|----------|------|------|
| ContentPanel.swift | Value 'snippet' was defined but never used | 後で対応可 |

### 課題（将来対応）
- フォルダ/スニペットのドラッグ&ドロップ並び替え（.onMove削除中）
- テーマ変更のリアルタイム反映
- 自動ペーストの安定性向上

---

## 🔧 プロジェクト設定メモ

### Bundle ID
`com.addness.SnipeeMac`

### Display Name
`Snipee`

### Team
`Teruya Komatsu`

### Deployment Target
`macOS 26.2`

### 追加済みライブラリ（SPM）
- Sparkle 2.8.1（自動更新用）

### 有効な権限（Entitlements）
- Outgoing Connections (Client) ✅
- Apple Events ✅

### Info.plist設定
- Application is agent (UIElement) = YES ✅

---

## 📁 プロジェクト構造
```
SnipeeMac/
├── SnipeeMac.xcodeproj
└── SnipeeMac/
    ├── App/
    │   ├── SnipeeMacApp.swift
    │   └── AppDelegate.swift
    ├── Models/
    │   ├── Snippet.swift
    │   ├── HistoryItem.swift
    │   ├── Member.swift
    │   ├── Department.swift
    │   └── AppSettings.swift
    ├── Services/
    │   ├── StorageService.swift
    │   ├── ClipboardService.swift
    │   ├── VariableService.swift
    │   ├── HotkeyService.swift
    │   └── PasteService.swift
    ├── Utilities/
    │   ├── Constants.swift
    │   ├── KeychainHelper.swift
    │   ├── XMLParserHelper.swift
    │   └── KeyboardNavigator.swift
    ├── Theme/
    │   └── ColorTheme.swift
    └── Views/
        ├── Popup/
        │   ├── PopupWindowController.swift
        │   ├── MainPopupView.swift
        │   ├── SnippetPopupView.swift
        │   ├── HistoryPopupView.swift
        │   └── SubmenuView.swift
        ├── Components/
        │   ├── ThemePicker.swift
        │   ├── HotkeyField.swift
        │   └── SearchField.swift
        ├── Settings/
        │   ├── SettingsView.swift
        │   ├── GeneralTab.swift
        │   ├── DisplayTab.swift
        │   ├── AccountTab.swift
        │   └── AdminTab.swift
        └── Editor/
            ├── SnippetEditorWindow.swift
            ├── SnippetEditorView.swift
            ├── FolderSidebar.swift
            └── ContentPanel.swift
```

---

## 📝 次回セッション用コマンド
```
Snipee Swift版の開発を続けます。

UPDATE_PLAN.md を確認してください。
Phase 7（Google連携）から再開します。

現在の状態:
- Phase 1-6: 完了
- 34ファイル作成済み
- 基本機能は動作確認済み

次のタスク:
1. GCP OAuth設定の確認
2. GoogleAuthService.swift 作成
3. Sheets/Drive API実装
```

---

**最終更新**: 2026-01-14 03:10