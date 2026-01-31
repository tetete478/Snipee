# Electron Mac版 削除精査レポート

**作成日**: 2026-01-23
**対象**: Snipeeプロジェクト
**目的**: Electron Mac版のコードを安全に削除し、Electron Windows版のみを維持する

---

## 📋 サマリー

### 削除対象の概要
- **完全削除ファイル**: 6個（Mac専用リソース、権限案内画面）
- **修正が必要なファイル**: 3個（main.js, settings.html, welcome.html）
- **Mac専用コード総数**: 約30箇所
- **Windows版への影響**: すべて対応済み（条件分岐で分離されている）

### 作業の安全性
✅ **安全に削除可能**
- すべてのMac専用コードは `process.platform === 'darwin'` で条件分岐されている
- Windows版のコードとは完全に独立している
- 削除によるWindows版への影響はゼロ

---

## 🗂️ 1. 削除可能なファイル一覧

### 安全度: 高（完全にMac専用）

| # | ファイルパス | 説明 | 理由 |
|---|-------------|------|------|
| 1 | `build/icon.icns` | Mac用アイコン | Macビルドでのみ使用 |
| 2 | `build/dmg-background.png` | DMGインストーラー背景画像 | Macビルドでのみ使用 |
| 3 | `build/tray_icon_16.png` | Macトレイアイコン（16x16） | main.js:95でMac時のみ参照 |
| 4 | `docs/mac.html` | Mac版ユーザーマニュアル | Mac版配布時のドキュメント |
| 5 | `docs/appcast-mac.xml` | Mac自動更新フィード（Sparkle形式） | Swift版Mac専用 |
| 6 | `app/permission-guide.html` | Macアクセシビリティ権限案内画面 | Mac専用機能（357行すべてMac専用） |

**削除コマンド例**:
```bash
rm build/icon.icns
rm build/dmg-background.png
rm build/tray_icon_16.png
rm docs/mac.html
rm docs/appcast-mac.xml
rm app/permission-guide.html
```

---

## ✏️ 2. 修正が必要なファイル一覧

### 2-1. `app/main.js`

**概要**: メインプロセスファイル。Mac専用コードが約20箇所存在。すべて条件分岐で分離されており、該当部分を削除すればWindows版は正常動作。

#### 修正箇所の詳細

---

#### **[1] デフォルトショートカット定義**

**行番号**: 79-81

**修正前**:
```javascript
const DEFAULT_CLIPBOARD_SHORTCUT = process.platform === 'darwin' ? 'Command+Control+C' : 'Ctrl+Alt+C';
const DEFAULT_SNIPPET_SHORTCUT = process.platform === 'darwin' ? 'Command+Control+V' : 'Ctrl+Alt+V';
const DEFAULT_HISTORY_SHORTCUT = process.platform === 'darwin' ? 'Command+Control+X' : 'Ctrl+Alt+X';
```

**修正後**:
```javascript
const DEFAULT_CLIPBOARD_SHORTCUT = 'Ctrl+Alt+C';
const DEFAULT_SNIPPET_SHORTCUT = 'Ctrl+Alt+V';
const DEFAULT_HISTORY_SHORTCUT = 'Ctrl+Alt+X';
```

**Windows版への影響**: なし（Windows用の値をそのまま使用）

---

#### **[2] トレイアイコン選択**

**行番号**: 93-100

**修正前**:
```javascript
function captureActiveApp() {
  if (process.platform === 'darwin') {
    try {
      const bundleId = execSync('osascript -e \'tell application "System Events" to get bundle identifier of first application process whose frontmost is true\'').toString().trim();
      if (bundleId !== 'com.electron.snipee' && bundleId !== 'com.github.Electron') {
        previousActiveApp = bundleId;
      }
    } catch (error) {
      console.log('Mac: Bundle ID取得スキップ:', error.message);
    }
  } else if (process.platform === 'win32') {
```

**修正後**:
```javascript
function captureActiveApp() {
  if (process.platform === 'win32') {
```

**説明**: Mac専用の `osascript` 実行部分を削除

**Windows版への影響**: なし（Windows用の処理はそのまま残る）

---

#### **[3] アクセシビリティ権限チェック関数**

**行番号**: 116-119

**修正前**:
```javascript
function hasAccessibilityPermission() {
  if (process.platform !== 'darwin') return true;
  return systemPreferences.isTrustedAccessibilityClient(false);
}
```

**修正後**:
```javascript
function hasAccessibilityPermission() {
  return true;
}
```

**説明**: Windows版では常にtrueを返していたので、単純化

**Windows版への影響**: なし

---

#### **[4] アクセシビリティ権限リクエスト関数**

**行番号**: 122-125

**修正前**:
```javascript
function requestAccessibilityPermission() {
  if (process.platform !== 'darwin') return;
  systemPreferences.isTrustedAccessibilityClient(true);
}
```

**修正後**:
```javascript
function requestAccessibilityPermission() {
  return;
}
```

**または完全に削除**: この関数はMac専用なので、関数自体を削除可能

**Windows版への影響**: なし

---

#### **[5] メインウィンドウのMac専用設定**

**行番号**: 156-163

**修正前**:
```javascript
  // Mac: 表示のたびに全Workspaceで表示を再設定
  if (process.platform === 'darwin') {
    mainWindow.on('show', () => {
      mainWindow.setVisibleOnAllWorkspaces(true, {
        visibleOnFullScreen: true,
        skipTransformProcessType: true
      });
    });
  }
```

**修正後**:
```javascript
  // 削除
```

**Windows版への影響**: なし

---

#### **[6] スニペット編集ウィンドウのMac専用設定**

**行番号**: 261-266

**修正前**:
```javascript
    // Mac: 全Workspaceで表示
    if (process.platform === 'darwin') {
      snippetEditorWindow.setVisibleOnAllWorkspaces(true, {
        visibleOnFullScreen: true,
        skipTransformProcessType: true
      });
    }
```

**修正後**:
```javascript
    // 削除
```

**Windows版への影響**: なし

---

#### **[7] 起動時の権限ガイド表示**

**行番号**: 465-473

**修正前**:
```javascript
  if (process.platform === 'darwin') {
    const hasPermission = hasAccessibilityPermission();
    if (!hasPermission && !store.get('permissionGuideShown', false)) {
      store.set('permissionGuideShown', true);
      setTimeout(() => {
        createPermissionWindow();
      }, 1000);
    }
  }
```

**修正後**:
```javascript
  // 削除
```

**Windows版への影響**: なし

---

#### **[8] 設定ウィンドウを開く際のMac専用処理**

**行番号**: 574-578

**修正前**:
```javascript
      click: () => {
        if (mainWindow) {
          if (process.platform === 'darwin') {
            mainWindow.setVisibleOnAllWorkspaces(true, {
              visibleOnFullScreen: true,
              skipTransformProcessType: true
            });
          }
          mainWindow.show();
          mainWindow.focus();
        }
      }
```

**修正後**:
```javascript
      click: () => {
        if (mainWindow) {
          mainWindow.show();
          mainWindow.focus();
        }
      }
```

**Windows版への影響**: なし

---

#### **[9] ウィンドウ表示位置設定（Mac専用処理）**

**行番号**: 695-701

**修正前**:
```javascript
  if (process.platform === 'darwin') {
    window.setVisibleOnAllWorkspaces(true, {
      visibleOnFullScreen: true,
      skipTransformProcessType: true
    });
    window.setAlwaysOnTop(true, 'floating');
  }
```

**修正後**:
```javascript
  // 削除（必要に応じてWindows用の処理を追加）
  window.setAlwaysOnTop(true);
```

**注意**: `'floating'` パラメータはMac専用。Windows版では引数なしで使用

**Windows版への影響**: なし（引数なしで正常動作）

---

#### **[10] show()後のMac専用再設定**

**行番号**: 739-748

**修正前**:
```javascript
  // Mac: show()後に再設定（仮想デスクトップ固定化防止）
  if (process.platform === 'darwin') {
    setTimeout(() => {
      if (window && !window.isDestroyed()) {
        window.setVisibleOnAllWorkspaces(true, {
          visibleOnFullScreen: true,
          skipTransformProcessType: true
        });
      }
    }, 100);
  }
```

**修正後**:
```javascript
  // 削除
```

**Windows版への影響**: なし

---

#### **[11] システム設定を開く**

**行番号**: 944-947

**修正前**:
```javascript
ipcMain.handle('open-system-preferences', () => {
  if (process.platform === 'darwin') {
    shell.openExternal('x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility');
  }
  return true;
});
```

**修正後**:
```javascript
// 削除（permission-guide.htmlからのみ呼ばれるため、不要になる）
```

**Windows版への影響**: なし

---

#### **[12] 権限ウィンドウを閉じる**

**行番号**: 950-955

**修正前**:
```javascript
ipcMain.handle('close-permission-window', () => {
  if (permissionWindow) {
    permissionWindow.close();
  }
  return true;
});
```

**修正後**:
```javascript
// 削除（permission-guide.htmlからのみ呼ばれるため、不要になる）
```

**Windows版への影響**: なし

---

#### **[13] 設定画面を表示（Mac専用処理）**

**行番号**: 1137-1142

**修正前**:
```javascript
  if (mainWindow) {
    if (process.platform === 'darwin') {
      mainWindow.setVisibleOnAllWorkspaces(true, {
        visibleOnFullScreen: true,
        skipTransformProcessType: true
      });
    }
    mainWindow.show();
    mainWindow.focus();
  }
```

**修正後**:
```javascript
  if (mainWindow) {
    mainWindow.show();
    mainWindow.focus();
  }
```

**Windows版への影響**: なし

---

#### **[14] ペースト処理（前面アプリ復帰）**

**行番号**: 1213-1218

**修正前**:
```javascript
  // Mac: 元のアプリをアクティブにする
  if (process.platform === 'darwin' && previousActiveApp) {
    await new Promise((resolve) => {
      exec(`osascript -e 'tell application id "${previousActiveApp}" to activate'`, () => resolve());
    });
    await new Promise(resolve => setTimeout(resolve, 30));
  }
```

**修正後**:
```javascript
  // 削除
```

**Windows版への影響**: なし（Windows用の処理は1221-1232行に独立して存在）

---

#### **[15] ペースト処理（osascriptでペースト）**

**行番号**: 1234-1237

**修正前**:
```javascript
  // Mac: ペースト（osascript使用）
  if (process.platform === 'darwin') {
    exec('osascript -e \'tell application "System Events" to keystroke "v" using command down\'');
  }
```

**修正後**:
```javascript
  // 削除
```

**Windows版への影響**: なし（Windows用の処理は1221-1232行に独立して存在）

---

#### **[16] window-all-closedイベント**

**行番号**: 1475-1477

**修正前**:
```javascript
app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});
```

**修正後**:
```javascript
app.on('window-all-closed', () => {
  app.quit();
});
```

**説明**: Macでは全ウィンドウを閉じてもアプリを終了しない慣習があるが、Windows専用になるため単純化

**Windows版への影響**: なし

---

#### **[17] Import文の整理**

**行番号**: 3

**修正前**:
```javascript
const { app, BrowserWindow, globalShortcut, ipcMain, clipboard, Tray, Menu, systemPreferences, shell, dialog } = require('electron');
```

**修正後**:
```javascript
const { app, BrowserWindow, globalShortcut, ipcMain, clipboard, Tray, Menu, shell, dialog } = require('electron');
```

**説明**: `systemPreferences` はMac専用なので削除

**Windows版への影響**: なし

---

#### **[18] createPermissionWindow関数**

**行番号**: 未特定（検索が必要）

**修正方法**: `createPermissionWindow` 関数全体を削除

**Windows版への影響**: なし

---

### 2-2. `app/settings.html`

**概要**: 設定画面。isMac変数を使用してデフォルトショートカット表示を切り替えている。

#### 修正箇所の詳細

---

#### **[1] デフォルトショートカット表示（HTML）**

**行番号**: 197, 205

**修正前**:
```html
<div class="help-text">クリップボード履歴を開きます（デフォルト: <span id="default-main">Command+Control+C</span>）</div>
...
<div class="help-text">スニペットのみを開きます（デフォルト: <span id="default-snippet">Command+Control+V</span>）</div>
```

**修正後**:
```html
<div class="help-text">クリップボード履歴を開きます（デフォルト: Ctrl+Alt+C）</div>
...
<div class="help-text">スニペットのみを開きます（デフォルト: Ctrl+Alt+V）</div>
```

**説明**: spanタグとidを削除し、直接Windows用のショートカットを記載

**Windows版への影響**: なし

---

#### **[2] isMac変数とプラットフォーム判定**

**行番号**: 313-319

**修正前**:
```javascript
const isMac = process.platform === 'darwin';

window.addEventListener('DOMContentLoaded', async () => {
  if (!isMac) {
    document.getElementById('default-main').textContent = 'Ctrl+Alt+C';
    document.getElementById('default-snippet').textContent = 'Ctrl+Alt+V';
  }
```

**修正後**:
```javascript
window.addEventListener('DOMContentLoaded', async () => {
  // isMac変数と条件分岐を削除
```

**説明**: 上記[1]でHTML側を修正したため、JavaScript側の動的変更処理は不要

**Windows版への影響**: なし

---

### 2-3. `app/welcome.html`

**概要**: ウェルカム画面。isMac変数を使用してショートカット表示とウィンドウを閉じる操作の案内を切り替えている。

#### 修正箇所の詳細

---

#### **[1] 閉じるショートカットのTips**

**行番号**: 461-467

**修正前**:
```javascript
const isMac = process.platform === 'darwin';
const closeTip = document.getElementById('close-shortcut-tip');
if (isMac) {
  closeTip.innerHTML = 'ウィンドウは <span class="key">⌘</span><span class="key">W</span> または <span class="key">Esc</span> で閉じられます';
} else {
  closeTip.innerHTML = 'ウィンドウは <span class="key">Ctrl</span><span class="key">W</span> または <span class="key">Esc</span> で閉じられます';
}
```

**修正後**:
```javascript
const closeTip = document.getElementById('close-shortcut-tip');
closeTip.innerHTML = 'ウィンドウは <span class="key">Ctrl</span><span class="key">W</span> または <span class="key">Esc</span> で閉じられます';
```

**Windows版への影響**: なし

---

#### **[2] ホットキー表示**

**行番号**: 474-479

**修正前**:
```javascript
const isMac = process.platform === 'darwin';

// デフォルト値を使用（main.jsから取得も可能だが、シンプルにする）
const mainKeys = isMac ? ['⌘', 'Ctrl', 'C'] : ['Ctrl', 'Alt', 'C'];
const snippetKeys = isMac ? ['⌘', 'Ctrl', 'V'] : ['Ctrl', 'Alt', 'V'];
const historyKeys = isMac ? ['⌘', 'Ctrl', 'X'] : ['Ctrl', 'Alt', 'X'];
```

**修正後**:
```javascript
const mainKeys = ['Ctrl', 'Alt', 'C'];
const snippetKeys = ['Ctrl', 'Alt', 'V'];
const historyKeys = ['Ctrl', 'Alt', 'X'];
```

**Windows版への影響**: なし

---

## 📦 4. package.json の変更点

### 削除するスクリプト

**行番号**: 15, 19

**修正前**:
```json
{
  "scripts": {
    "start": "electron .",
    "dev": "electron . --debug",
    "build": "electron-builder",
    "build:win": "electron-builder --win",
    "build:mac": "electron-builder --mac",
    "build:all": "electron-builder --win --mac",
    "publish": "electron-builder --mac --win --publish always",
    "publish:win": "electron-builder --win --publish always",
    "publish:mac": "electron-builder --mac --publish always"
  }
}
```

**修正後**:
```json
{
  "scripts": {
    "start": "electron .",
    "dev": "electron . --debug",
    "build": "electron-builder --win",
    "build:win": "electron-builder --win",
    "publish": "electron-builder --win --publish always",
    "publish:win": "electron-builder --win --publish always"
  }
}
```

**削除するスクリプト**:
- `build:mac`
- `build:all`（Macビルドを含むため）
- `publish:mac`
- `publish` の `--mac` オプション

---

### 削除する electron-builder 設定

**行番号**: 79-110

**修正前**:
```json
{
  "build": {
    "appId": "com.snipee.app",
    "productName": "Snipee",
    "publish": {
      "provider": "github",
      "owner": "tetete478",
      "repo": "snipee"
    },
    "directories": {
      "buildResources": "build",
      "output": "dist"
    },
    "files": [
      "app/**/*",
      ".env",
      "package.json",
      "!app/**/*.map"
    ],
    "asarUnpack": [
      "node_modules/gaxios/**/*",
      "node_modules/googleapis/**/*",
      "node_modules/google-auth-library/**/*"
    ],
    "win": {
      "target": [
        {
          "target": "nsis",
          "arch": [
            "x64"
          ]
        }
      ],
      "icon": "build/icon.ico"
    },
    "mac": {
      "target": [
        "dmg",
        "zip"
      ],
      "icon": "build/icon.icns",
      "category": "public.app-category.productivity",
      "hardenedRuntime": true,
      "gatekeeperAssess": false,
      "notarize": {
        "teamId": "F8KR53ZN3Y"
      }
    },
    "dmg": {
      "background": "build/dmg-background.png",
      "contents": [
        {
          "x": 170,
          "y": 190
        },
        {
          "x": 370,
          "y": 190,
          "type": "link",
          "path": "/Applications"
        }
      ],
      "window": {
        "width": 540,
        "height": 380
      }
    },
    "nsis": {
      "oneClick": true,
      "runAfterFinish": true,
      "createDesktopShortcut": true,
      "createStartMenuShortcut": true,
      "allowElevation": true,
      "include": "build/installer.nsh",
      "installerSidebar": "build/installerSidebar.bmp",
      "uninstallerSidebar": "build/installerSidebar.bmp"
    }
  }
}
```

**修正後**:
```json
{
  "build": {
    "appId": "com.snipee.app",
    "productName": "Snipee",
    "publish": {
      "provider": "github",
      "owner": "tetete478",
      "repo": "snipee"
    },
    "directories": {
      "buildResources": "build",
      "output": "dist"
    },
    "files": [
      "app/**/*",
      ".env",
      "package.json",
      "!app/**/*.map"
    ],
    "asarUnpack": [
      "node_modules/gaxios/**/*",
      "node_modules/googleapis/**/*",
      "node_modules/google-auth-library/**/*"
    ],
    "win": {
      "target": [
        {
          "target": "nsis",
          "arch": [
            "x64"
          ]
        }
      ],
      "icon": "build/icon.ico"
    },
    "nsis": {
      "oneClick": true,
      "runAfterFinish": true,
      "createDesktopShortcut": true,
      "createStartMenuShortcut": true,
      "allowElevation": true,
      "include": "build/installer.nsh",
      "installerSidebar": "build/installerSidebar.bmp",
      "uninstallerSidebar": "build/installerSidebar.bmp"
    }
  }
}
```

**削除するセクション**:
- `"mac"` セクション全体（79-90行）
- `"dmg"` セクション全体（92-110行）

---

### 削除する依存関係

**行番号**: 41

**修正前**:
```json
{
  "devDependencies": {
    "@electron/notarize": "^3.1.1",
    "electron": "^27.0.0",
    "electron-builder": "^24.13.3"
  }
}
```

**修正後**:
```json
{
  "devDependencies": {
    "electron": "^27.0.0",
    "electron-builder": "^24.13.3"
  }
}
```

**削除する依存関係**:
- `@electron/notarize` - Mac公証専用ツール

---

## ⚙️ 5. その他の設定ファイル

### GitHub Actions（オプション）

**ファイル**: `.github/workflows/build.yml`

**現状**: ElectronのWin/Mac両方をビルド

**推奨対応**: Macビルドジョブを削除するか、Windows専用に変更

**ファイル**: `.github/workflows/build-mac.yml`

**現状**: Swift版Mac専用のビルド（`mac-v*` タグのみ）

**推奨対応**: 影響なし（Swift版は残すため）

---

## ⚠️ 6. 注意事項・確認が必要な点

### 6-1. 変数・関数の削除確認

以下の変数・関数は完全に削除可能:

| 変数・関数 | ファイル | 説明 |
|-----------|---------|------|
| `permissionWindow` | main.js | Mac権限案内ウィンドウ |
| `createPermissionWindow()` | main.js | 権限ウィンドウ作成関数 |
| `hasAccessibilityPermission()` | main.js | Mac権限チェック関数（簡略化可） |
| `requestAccessibilityPermission()` | main.js | Mac権限リクエスト関数（削除可） |
| `previousActiveApp`（Mac部分） | main.js | Mac前面アプリ記憶（Windows部分は残す） |

### 6-2. IPC通信ハンドラーの削除

以下のIPCハンドラーは削除可能（permission-guide.htmlからのみ使用）:

```javascript
ipcMain.handle('open-system-preferences', ...)  // 944-948行
ipcMain.handle('close-permission-window', ...)  // 950-955行
```

### 6-3. setAlwaysOnTop の修正

**行番号**: 700

**現状**:
```javascript
window.setAlwaysOnTop(true, 'floating');
```

**修正後**:
```javascript
window.setAlwaysOnTop(true);
```

**理由**: `'floating'` パラメータはMac専用。Windows版では引数なしで正常動作。

### 6-4. captureActiveApp関数の整理

**現状**: Mac/Win両方の処理が含まれる

**推奨対応**: Mac部分を削除し、Windows部分のみ残す

**修正前** (94-113行):
```javascript
function captureActiveApp() {
  if (process.platform === 'darwin') {
    try {
      const bundleId = execSync('osascript -e ...').toString().trim();
      if (bundleId !== 'com.electron.snipee' && bundleId !== 'com.github.Electron') {
        previousActiveApp = bundleId;
      }
    } catch (error) {
      console.log('Mac: Bundle ID取得スキップ:', error.message);
    }
  } else if (process.platform === 'win32') {
    try {
      if (GetForegroundWindow) {
        previousActiveApp = GetForegroundWindow();
      }
    } catch (error) {
      // HWND取得失敗時はスキップ
    }
  }
}
```

**修正後**:
```javascript
function captureActiveApp() {
  try {
    if (GetForegroundWindow) {
      previousActiveApp = GetForegroundWindow();
    }
  } catch (error) {
    // HWND取得失敗時はスキップ
  }
}
```

### 6-5. execSync/exec のインポート削除確認

**現状**: `osascript` 実行のために使用

```javascript
const { execSync, exec } = require('child_process');
```

**推奨対応**: Mac専用コード削除後、これらが他で使用されていなければインポートを削除

**確認方法**: 全Mac専用コード削除後、`execSync` と `exec` を検索し、使用箇所がなければ削除

### 6-6. systemPreferences のインポート削除

**現状**: Mac権限チェックで使用

```javascript
const { ..., systemPreferences, ... } = require('electron');
```

**推奨対応**: `systemPreferences` を削除

### 6-7. テスト実施の推奨

削除後、以下の動作確認を推奨:

1. ✅ アプリ起動
2. ✅ グローバルショートカット（Ctrl+Alt+C/V/X）
3. ✅ クリップボード履歴表示
4. ✅ スニペット選択・ペースト
5. ✅ 設定画面の表示
6. ✅ ウェルカム画面の表示
7. ✅ 自動ペースト機能（Windows APIで正常動作）
8. ✅ ビルド（`npm run build`）
9. ✅ インストーラー作成・インストール

---

## 🎯 7. 削除作業の推奨手順

### ステップ1: バックアップ
```bash
git checkout -b remove-electron-mac
git add .
git commit -m "作業前のバックアップ"
```

### ステップ2: ファイル削除
```bash
rm build/icon.icns
rm build/dmg-background.png
rm build/tray_icon_16.png
rm docs/mac.html
rm docs/appcast-mac.xml
rm app/permission-guide.html
```

### ステップ3: main.js の修正
上記「2-1. app/main.js」の修正箇所を順番に修正

### ステップ4: settings.html の修正
上記「2-2. app/settings.html」の修正箇所を修正

### ステップ5: welcome.html の修正
上記「2-3. app/welcome.html」の修正箇所を修正

### ステップ6: package.json の修正
上記「4. package.json の変更点」を適用

### ステップ7: 依存関係のクリーンアップ
```bash
npm uninstall @electron/notarize
npm install
```

### ステップ8: 動作確認
```bash
npm start
```

### ステップ9: ビルド確認
```bash
npm run build
```

### ステップ10: コミット
```bash
git add .
git commit -m "Remove Electron Mac version code"
```

---

## 📊 8. 削除による影響の統計

| カテゴリ | 削除/修正数 |
|---------|-----------|
| 完全削除ファイル | 6個 |
| 修正が必要なファイル | 3個 |
| main.jsの修正箇所 | 18箇所 |
| settings.htmlの修正箇所 | 2箇所 |
| welcome.htmlの修正箇所 | 2箇所 |
| package.jsonの削除項目 | 7項目 |
| **合計作業量** | **38箇所** |

---

## ✅ 9. 作業完了チェックリスト

- [ ] ファイル削除（6個）
- [ ] main.js修正（18箇所）
- [ ] settings.html修正（2箇所）
- [ ] welcome.html修正（2箇所）
- [ ] package.json修正（7箇所）
- [ ] npm uninstall @electron/notarize
- [ ] npm install
- [ ] 動作確認（起動、ショートカット、ペースト）
- [ ] ビルド確認（npm run build）
- [ ] インストーラー確認
- [ ] Git commit

---

## 📝 10. 補足情報

### Swift版Macについて
- **影響なし**: `SnipeeMac/` フォルダとSwift版関連ファイルは今回の削除対象外
- **ビルドCI**: `.github/workflows/build-mac.yml` はSwift版専用なので残す
- **タグ**: `mac-v*` タグはSwift版用なので削除不要

### Windows APIの依存関係
- `koffi` ライブラリ（Windows API呼び出し）は引き続き必要
- `user32.dll` を使用した自動ペースト機能は正常動作

---

**作成者**: Claude Code
**最終更新**: 2026-01-23
