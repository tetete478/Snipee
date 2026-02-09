# Snipee HANDOVER — iOS (Swift)

**最終更新**: 2026-02-09

---

## 🚩 現在地

- App Store提出準備中
- クラウド同期は Phase 4 待ち（Mac版Phase 3完了後に移植）

---

## 進め方の方針

- コードはすぐに書き換えない → まず改善案を出して許可をもらう
- 修正箇所が少なければ修正前/修正後のマークダウンで指示
- 完全なコード生成後は自身で検証ステップを入れる
- str_replace方式で差分修正（ファイル全体書き換えは避ける）

---

## 📋 プロジェクト概要

Snipeeはクリップボード履歴とスニペット管理ツール。チームで共有できるマスタスニペットと個人用スニペットを使い分けられる。

- **iOS版**: Swift/SwiftUI（Snipee Tap）+ カスタムキーボード拡張（本ドキュメントの対象）
- **Mac版**: Swift/SwiftUI（SnipeeMac）
- **Windows版**: Electron

---

## ⚠️ 絶対やってはいけないこと

### 5. ❌ Swift 6 Strict Concurrency を有効にする

**失敗**: Codable構造体でnonisolatedエラー多発
**解決**: Swift 5 + Minimal設定を維持

### 6. ❌ Google Drive APIで共有ドライブを忘れる

**失敗**: 404エラーでアップロード失敗
**解決**: `supportsAllDrives=true` パラメータを追加

### 10. ❌ SwiftUIのbodyに.onChange()を大量につけない

**失敗**: コンパイラが型チェックできない（reasonable time エラー）
**解決**: ViewModifierに分離するか、関数に切り出す

### 11. ❌ iOSアイコンにアルファチャンネルを含める

**失敗**: App Store Connectでアップロード拒否
**解決**: `convert icon.png -background white -alpha remove -alpha off icon_fixed.png`

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

## 📱 iOS版 詳細機能

### カスタムキーボード（SnipeeiOSKeyboard）

- **スニペット挿入**: キーボードから直接スニペットを選択・挿入
- **変数置換**: Mac版互換の変数形式対応（{日付}, {名前}, {曜日}等）
- **App Group**: メインアプリとキーボード間でデータ共有

### メインアプリ

- **タブ構成**: スニペット一覧、検索、フォルダ、設定
- **スワイプナビゲーション**: タブ間をスワイプで移動
- **Google同期**: Mac版と同じマスタスニペットを同期
- **同期中の操作無視**: 同期処理中はタブ切り替えを無視

### VSCode Swift開発設定

```bash
# xcode-build-server インストール
brew install xcode-build-server

# プロジェクト設定
cd SnipeeIOS
xcode-build-server config -scheme SnipeeIOS -project SnipeeIOS.xcodeproj
```

**settings.json設定**:
```json
{
  "swift.autoGenerateLaunchConfigurations": false
}
```

---

## 📁 ファイル構成

```
SnipeeIOS/
├── SnipeeIOS/
│   ├── SnipeeIOSApp.swift              # アプリエントリーポイント
│   ├── Assets.xcassets/                # アイコン、カラー
│   └── Shared/
│       ├── Models/
│       │   ├── AppSettings.swift       # 設定データモデル
│       │   ├── Member.swift            # メンバー情報モデル
│       │   └── Snippet.swift           # スニペットモデル
│       ├── Services/
│       │   ├── GoogleAuthService.swift # OAuth認証、トークン管理
│       │   ├── GoogleDriveService.swift# Drive API（XMLダウンロード）
│       │   ├── GoogleSheetsService.swift# Sheets API（メンバー認証）
│       │   ├── SecurityService.swift   # Keychain操作
│       │   ├── StorageService.swift    # UserDefaults保存
│       │   ├── SyncService.swift       # マスタスニペット同期
│       │   ├── VariableService.swift   # 変数置換（Mac版互換）
│       │   └── XMLParserHelper.swift   # XMLパース
│       ├── Theme/
│       │   └── ColorTheme.swift        # テーマ定義
│       └── Views/
│           ├── MainTabView.swift       # メインタブ（スワイプ対応）
│           ├── Folder/
│           │   ├── FolderDetailView.swift  # フォルダ詳細
│           │   └── FolderListView.swift    # フォルダ一覧
│           ├── List/
│           │   ├── SnippetListView.swift   # スニペット一覧
│           │   └── SnippetRowView.swift    # スニペット行
│           ├── Onboarding/
│           │   └── WelcomeView.swift       # オンボーディング
│           ├── Search/
│           │   └── SearchView.swift        # 検索画面
│           └── Settings/
│               ├── AccountView.swift       # アカウント設定
│               └── SettingsView.swift      # 設定画面
└── SnipeeiOSKeyboard/
    ├── Info.plist                      # キーボード設定
    ├── KeyboardViewController.swift    # カスタムキーボード本体
    └── SnipeeiOSKeyboard.entitlements  # App Group設定
```

---

## 🔧 ビルド・リリース

### iOS版ビルド

```bash
# 開発ビルド
cd ~/Desktop/Snipee/SnipeeIOS
xcodebuild -scheme SnipeeIOS -configuration Debug build

# アイコンのアルファチャンネル削除（App Store提出前）
convert AppIcon1024x1024.png -background white -alpha remove -alpha off AppIcon1024x1024_fixed.png

# リリース（Xcode → Product → Archive → Distribute App）
```

---

## 🔄 クラウド同期計画

### 現状（iOSの個別スニペット保存）

| 項目 | 内容 |
|------|------|
| **保存先** | App Group UserDefaults |
| **キー** | `snippets` |
| **形式** | JSON (`[SnippetFolder]`) |
| **バックアップ** | なし |
| **保存トリガー** | 不明（要確認） |

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

### iOS版の実装計画

#### 変更が必要なファイル

| ファイル | 変更内容 | 規模 |
|---------|----------|------|
| `Services/GoogleDriveService.swift` | `createFile`, `findFile` 追加 | 中 |
| `Services/PersonalSyncService.swift` | **新規作成**: 個別スニペット同期サービス | 大 |
| `Services/StorageService.swift` | 同期用インターフェース追加 | 小 |
| `Models/Snippet.swift` | `description` フィールド追加 | 小 |
| `Views/Settings/AccountView.swift` | 同期状態表示追加 | 小 |
| `SnipeeIOSApp.swift` | 起動時同期、バックグラウンド同期 | 中 |

#### iOS固有の考慮事項

- **バックグラウンド同期**: `BGAppRefreshTask` 登録が必要
- **App Group**: キーボードExtensionとの共有はローカルデータのみ（同期はメインアプリで実行）
- **データ有効期限**: 既存の7日expiry設定との整合性

### 実装フェーズ

#### Phase 1: 基盤（Drive API拡張）
**目的**: ファイル作成・検索・メタデータ取得を可能にする

**対象**: `GoogleDriveService.swift` に `createFile`, `findFile` 追加

**完了条件**: `Snipee/personal_snippets.json` の作成・読み書きが可能

#### Phase 2: モデル統一
**目的**: Snippetモデルに不足フィールドを追加

**対象**: `Snippet.swift` に `description` フィールド追加

**マイグレーション**: 既存データ読み込み時に `createdAt`/`updatedAt` が無ければ現在日時で補完

#### Phase 4: iOS展開（Mac版からの移植）
**目的**: Mac版で検証済みのロジックをiOSに移植

**対象**: `PersonalSyncService.swift`

**注意**: Mac版とほぼ同じコードを使用可能。マージロジックは全プラットフォームで同一にする（テストケースも共通化）

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

## 🗓️ TODO / ロードマップ

### 🔴 最優先
- App Store提出

### 🟡 進行中
- クラウド同期 Phase 4（Mac版完了待ち）

### 🟢 将来
- タグ機能、検索機能強化
- Android版

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

### Google API スコープ

```
https://www.googleapis.com/auth/userinfo.email
https://www.googleapis.com/auth/spreadsheets
https://www.googleapis.com/auth/drive
```

### VSCode Swift開発設定

```bash
# xcode-build-server インストール
brew install xcode-build-server

# プロジェクト設定
cd SnipeeIOS
xcode-build-server config -scheme SnipeeIOS -project SnipeeIOS.xcodeproj
```

**settings.json設定**:
```json
{
  "swift.autoGenerateLaunchConfigurations": false
}
```

---

## 🔄 変更履歴

### 2026-02-02

- **iOS版（SnipeeIOS）機能追加**
  - VariableService.swift: Mac版互換の変数形式追加（{日付}, {名前}, {曜日}等）
  - KeyboardViewController.swift: カスタムキーボードに変数処理を追加
  - MainTabView.swift: スワイプでタブ切り替え機能、同期中の操作無視
  - AccountView.swift: ログアウト処理を非同期化
  - SnipeeIOSApp.swift: 起動時ローディング状態修正
  - App Storeアイコン: アルファチャンネル削除（ImageMagick使用）
- **VSCode Swift設定**
  - xcode-build-server をインストール・設定
  - settings.json に swift.autoGenerateLaunchConfigurations: false 等を追加
