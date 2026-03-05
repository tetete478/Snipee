const { app, BrowserWindow, globalShortcut, ipcMain, clipboard, Tray, Menu, dialog } = require('electron');



// 単一インスタンスを保証
const gotTheLock = app.requestSingleInstanceLock();

if (!gotTheLock) {
  app.quit();
}

app.on('second-instance', () => {
  // 通知を表示
  const { Notification } = require('electron');
  if (Notification.isSupported()) {
    new Notification({
      title: 'Snipee',
      body: 'Snipeeは既に起動しています。タスクトレイのアイコンから操作してください。'
    }).show();
  }
  
  // クリップボードウィンドウを表示
});

const appState = require('./app-state');
const googleAuth = require('./services/google-auth-service');
const memberManager = require('./services/member-manager');
const pasteService = require('./services/paste-service');
const syncService = require('./services/sync-service');
const personalSync = require('./services/personal-sync-service');
const userReportService = require('./services/user-report-service');

const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env'), quiet: true });

let autoUpdater = null;
try {
  autoUpdater = require('electron-updater').autoUpdater;
} catch (error) {
}

// ストアの初期化
const { store, personalStore } = require('./services/storage-service');

// デフォルトホットキー設定
const DEFAULT_CLIPBOARD_SHORTCUT = 'Ctrl+Alt+C';
const DEFAULT_SNIPPET_SHORTCUT = 'Ctrl+Alt+V';
const DEFAULT_HISTORY_SHORTCUT = 'Ctrl+Alt+X';

let tray = null;

// クリップボード履歴管理
appState.clipboard.pinnedItems = store.get('pinnedItems', []);
const DEFAULT_MAX_HISTORY = 100;

function getMaxHistory() {
  return store.get('historyMaxCount', DEFAULT_MAX_HISTORY);
}

function createMainWindow() {
  appState.windows.main = new BrowserWindow({
    width: 500,
    height: 400,
    show: false,
    frame: false,
    visibleOnAllWorkspaces: true,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false
    }
  });

  appState.windows.main.loadFile(path.join(__dirname, 'views/settings.html'));

  appState.windows.main.on('close', (event) => {
    if (!app.isQuitting) {
      event.preventDefault();
      appState.windows.main.hide();
    }
  });
}

// 汎用ウィンドウ作成関数
function createGenericWindow(type) {
  const config = {
    clipboard: {
      htmlFile: 'index.html',
      positionKey: 'clipboardWindowPosition'
    },
    snippet: {
      htmlFile: 'snippets.html',
      positionKey: 'snippetWindowPosition'
    },
    history: {
      htmlFile: 'history.html',
      positionKey: 'historyWindowPosition'
    }
  };

  const { htmlFile, positionKey } = config[type];

  const window = new BrowserWindow({
    width: 230,
    height: 600,
    show: false,
    frame: false,
    alwaysOnTop: true,
    skipTaskbar: true,
    resizable: false,
    transparent: true,
    movable: true,
    hasShadow: false,
    visibleOnAllWorkspaces: true,
    fullscreenable: false,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false
    }
  });

  window.loadFile(path.join(__dirname, 'views', htmlFile));

  window.on('moved', () => {
    if (window && !window.isDestroyed()) {
      const bounds = window.getBounds();
      store.set(positionKey, { x: bounds.x, y: bounds.y });
    }
  });

  // フォーカスを失ったら自動的にhide
  window.on('blur', () => {
    if (window && !window.isDestroyed() && window.isVisible()) {
      window.hide();
    }
  });

  return window;
}

// ラッパー関数
function createClipboardWindow() {
  appState.windows.clipboard = createGenericWindow('clipboard');
}

function createSnippetWindow() {
  appState.windows.snippet = createGenericWindow('snippet');
}

function createHistoryWindow() {
  appState.windows.history = createGenericWindow('history');
}

// スニペット編集ウィンドウ作成
function createSnippetEditorWindow() {
  // 既存のウィンドウがあれば再利用
  if (appState.windows.snippetEditor && !appState.windows.snippetEditor.isDestroyed()) {
    appState.windows.snippetEditor.show();
    appState.windows.snippetEditor.focus();
    return;
  }

  appState.windows.snippetEditor = new BrowserWindow({
    width: 720,
    height: 600,
    frame: true,
    resizable: true,
    visibleOnAllWorkspaces: true,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false
    }
  });

  appState.windows.snippetEditor.loadFile(path.join(__dirname, 'views/snippet-editor.html'));

  appState.windows.snippetEditor.once('ready-to-show', () => {
    appState.windows.snippetEditor.show();
  });

  appState.windows.snippetEditor.on('closed', () => {
    appState.windows.snippetEditor = null;
  });
}

// ウェルカムウィンドウ作成
function createWelcomeWindow() {
  appState.windows.welcome = new BrowserWindow({
    width: 480,
    height: 520,
    show: false,
    frame: false,
    resizable: false,
    center: true,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false
    }
  });

  appState.windows.welcome.loadFile(path.join(__dirname, 'views/welcome.html'));

  appState.windows.welcome.once('ready-to-show', () => {
    appState.windows.welcome.show();
  });

  appState.windows.welcome.on('closed', () => {
    appState.windows.welcome = null;
  });
}

function createLoginWindow() {
  if (appState.windows.login && !appState.windows.login.isDestroyed()) {
    appState.windows.login.show();
    appState.windows.login.focus();
    return;
  }

  appState.windows.login = new BrowserWindow({
    width: 450,
    height: 500,
    resizable: false,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false
    }
  });

  appState.windows.login.loadFile(path.join(__dirname, 'views/login.html'));

  appState.windows.login.on('closed', () => {
    appState.windows.login = null;
  });
}

function handleLogout() {
  // ログイン画面を先に作成（window-all-closedの発火を防ぐ）
  createLoginWindow();

  // 各ウィンドウを閉じる
  ['clipboard', 'snippet', 'history', 'snippetEditor', 'welcome'].forEach(key => {
    const win = appState.windows[key];
    if (win && !win.isDestroyed()) win.close();
    appState.windows[key] = null;
  });

  // 設定ウィンドウはclose防止があるためdestroyで閉じる
  if (appState.windows.main && !appState.windows.main.isDestroyed()) {
    appState.windows.main.destroy();
    appState.windows.main = null;
  }

  // ホットキー・トレイ・同期を停止
  globalShortcut.unregisterAll();
  syncService.stopAutoSync();
  if (tray) { tray.destroy(); tray = null; }
}

function createNotRegisteredWindow(email) {
  dialog.showMessageBox({
    type: 'warning',
    title: 'アクセス権限がありません',
    message: `${email} はメンバーリストに登録されていません。\n\n管理者に連絡してください。`,
    buttons: ['OK']
  }).then(() => {
    app.quit();
  });
}



async function checkLoginAndStart() {
  try {
    const SCOPE_VERSION = 3;
    const savedScopeVersion = store.get('scopeVersion', 0);
    if (savedScopeVersion < SCOPE_VERSION) {
      await googleAuth.logout();
      store.set('scopeVersion', SCOPE_VERSION);
    }

    const loggedIn = await googleAuth.isLoggedIn();
    if (!loggedIn) {
      createLoginWindow();
    } else {
      const result = await memberManager.initialize();
      if (result.success) {
        startApp();
      } else if (result.error === 'not_registered') {
        createNotRegisteredWindow(result.email);
      } else {
        createLoginWindow();
      }
    }
  } catch (error) {
    createLoginWindow();
  }
}

function startApp() {
  createMainWindow();
  createTray();
  registerGlobalShortcuts();
  
  // 部署XMLを読み込み
  syncService.loadDepartmentSnippets();
  // 個別スニペットをクラウドからダウンロード
  personalSync.downloadPersonalData();

  if (!store.get('welcomeCompleted', false)) {
    createWelcomeWindow();
  }

  const existingSnippets = personalStore.get('snippets', []);
  if (!store.get('initialSnippetsCreated', false) && existingSnippets.length === 0) {
    const defaultFolders = ['Sample1', 'Sample2', 'Sample3'];
    const defaultSnippets = [
      { id: Date.now().toString() + '-1', title: 'Sample1-1', content: 'Sample1-1\nSample1-1\nSample1-1', folder: 'Sample1' },
      { id: Date.now().toString() + '-2', title: 'Sample1-2', content: 'Sample1-2の内容', folder: 'Sample1' },
      { id: Date.now().toString() + '-3', title: 'Sample1-3', content: 'Sample1-3の内容', folder: 'Sample1' },
      { id: Date.now().toString() + '-4', title: 'Sample2-1', content: 'Sample2-1の内容', folder: 'Sample2' },
      { id: Date.now().toString() + '-5', title: 'Sample2-2', content: 'Sample2-2の内容', folder: 'Sample2' },
      { id: Date.now().toString() + '-6', title: 'Sample2-3', content: 'Sample2-3の内容', folder: 'Sample2' },
      { id: Date.now().toString() + '-7', title: 'Sample3-1', content: 'Sample3-1の内容', folder: 'Sample3' },
      { id: Date.now().toString() + '-8', title: 'Sample3-2', content: 'Sample3-2の内容', folder: 'Sample3' },
      { id: Date.now().toString() + '-9', title: 'Sample3-3', content: 'Sample3-3の内容', folder: 'Sample3' },
    ];
    personalStore.set('folders', defaultFolders);
    personalStore.set('snippets', defaultSnippets);
    store.set('initialSnippetsCreated', true);
  }

  startClipboardMonitoring();

  // 2時間ごとに部署スニペットを自動同期
  syncService.startAutoSync();

  // 日次自動アップデートチェック開始
  scheduleDailyUpdateCheck();

  // ユーザーステータス報告
  userReportService.report();
}

// グローバルショートカット登録(リトライ機能付き)
function registerGlobalShortcuts() {
  globalShortcut.unregisterAll();

  const mainHotkey = store.get('customHotkeyMain', DEFAULT_CLIPBOARD_SHORTCUT);
  const snippetHotkey = store.get('customHotkeySnippet', DEFAULT_SNIPPET_SHORTCUT);

  const registerWithRetry = (accelerator, callback, retries = 3) => {
    const attempt = (remaining) => {
      try {
        const success = globalShortcut.register(accelerator, callback);
        if (!success && remaining > 0) {
          setTimeout(() => attempt(remaining - 1), 500);
        }
      } catch (error) {
        if (remaining > 0) {
          setTimeout(() => attempt(remaining - 1), 500);
        }
      }
    };
    attempt(retries);
  };

  registerWithRetry(mainHotkey, async () => {
    const loggedIn = await googleAuth.isLoggedIn();
    if (!loggedIn) { createLoginWindow(); return; }
    pasteService.captureActiveApp();
    showClipboardWindow();
  });

  registerWithRetry(snippetHotkey, async () => {
    const loggedIn = await googleAuth.isLoggedIn();
    if (!loggedIn) { createLoginWindow(); return; }
    pasteService.captureActiveApp();
    showSnippetWindow();
  });

  const historyHotkey = store.get('customHotkeyHistory', DEFAULT_HISTORY_SHORTCUT);
  registerWithRetry(historyHotkey, async () => {
    const loggedIn = await googleAuth.isLoggedIn();
    if (!loggedIn) { createLoginWindow(); return; }
    pasteService.captureActiveApp();
    showHistoryWindow();
  });
}

// システムトレイ作成
function createTray() {
  const iconPath = path.join(__dirname, '../build/icon.ico');
  
  try {
    tray = new Tray(iconPath);
  } catch (error) {
    return;
  }

  const contextMenu = Menu.buildFromTemplate([
    { 
      label: 'クリップボード履歴を開く', 
      click: () => showClipboardWindow() 
    },
    { type: 'separator' },
    { 
      label: '設定', 
      click: () => {
        if (appState.windows.main) {
          appState.windows.main.show();
          appState.windows.main.focus();
        }
      }
    },
    { type: 'separator' },
    { 
      label: '終了', 
      click: () => {
        app.isQuitting = true;
        app.quit();
      }
    }
  ]);

  tray.setToolTip('Snipee');
  tray.setContextMenu(contextMenu);

  tray.on('click', () => {
    showClipboardWindow();
  });
}

// クリップボード監視
function startClipboardMonitoring() {
  appState.clipboard.lastText = clipboard.readText();
  appState.clipboard.history = store.get('clipboardHistory', []);

  setInterval(() => {
    const currentText = clipboard.readText();
    
    if (currentText && currentText !== appState.clipboard.lastText) {
      appState.clipboard.lastText = currentText;
      addToClipboardHistory(currentText);
    }
  }, 500);
}

// クリップボード履歴に追加
function addToClipboardHistory(text) {
  appState.clipboard.history = appState.clipboard.history.filter(item => item.content !== text);

  appState.clipboard.history.unshift({
    id: Date.now().toString(),
    content: text,
    timestamp: new Date().toISOString(),
    type: 'history'
  });

  const maxHistory = getMaxHistory();
  if (appState.clipboard.history.length > maxHistory) {
    appState.clipboard.history = appState.clipboard.history.slice(0, maxHistory);
  }

  store.set('clipboardHistory', appState.clipboard.history);

  if (appState.windows.clipboard && !appState.windows.clipboard.isDestroyed()) {
    appState.windows.clipboard.webContents.send('clipboard-updated');
  }
}

// 汎用ウィンドウ表示関数
function showGenericWindow(type) {
  const createMap = {
    clipboard: createClipboardWindow,
    snippet: createSnippetWindow,
    history: createHistoryWindow
  };

  // 他のウィンドウを閉じる
  ['clipboard', 'snippet', 'history'].forEach(winType => {
    if (winType !== type) {
      const win = appState.windows[winType];
      if (win && !win.isDestroyed() && win.isVisible()) {
        win.hide();
      }
    }
  });

  let currentWindow = appState.windows[type];

  if (!currentWindow || currentWindow.isDestroyed()) {
    createMap[type]();
    currentWindow = appState.windows[type];
  }

  if (currentWindow.isVisible()) {
    currentWindow.hide();
  } else {
    positionAndShowWindow(type, currentWindow);
  }
}

// ラッパー関数
function showClipboardWindow() {
  showGenericWindow('clipboard');
}

function showSnippetWindow() {
  showGenericWindow('snippet');
}

function showHistoryWindow() {
  showGenericWindow('history');
}

// 汎用ポジショニング&表示関数
function positionAndShowWindow(type, window) {
  const { screen } = require('electron');
  
  window.setAlwaysOnTop(true);
  
  const positionKey = type === 'clipboard' ? 'clipboardWindowPosition' : 
                      type === 'snippet' ? 'snippetWindowPosition' : 'historyWindowPosition';
  const positionMode = store.get('windowPositionMode', 'cursor');

  if (positionMode === 'previous') {
    const savedPosition = store.get(positionKey);
    if (savedPosition) {
      window.setPosition(savedPosition.x, savedPosition.y);
    } else {
      const display = screen.getPrimaryDisplay();
      const x = Math.floor((display.bounds.width - 460) / 2);
      const y = Math.floor((display.bounds.height - 650) / 2);
      window.setPosition(x, y);
    }
  } else {
    const point = screen.getCursorScreenPoint();
    const display = screen.getDisplayNearestPoint(point);
    
    let x = point.x + 25;
    let y = point.y + 100;

    if (x + 460 > display.bounds.x + display.bounds.width) {
      x = display.bounds.x + display.bounds.width - 470;
    }
    
    if (y + 650 > display.bounds.y + display.bounds.height) {
      y = display.bounds.y + display.bounds.height - 660;
    }

    window.setPosition(Math.floor(x), Math.floor(y));
  }

  window.show();
  window.focus();
}

// アプリ起動
app.whenReady().then(() => {
  ipcMain.on('window-ready', (event) => {
    const sender = event.sender;
    
    if (appState.windows.clipboard && !appState.windows.clipboard.isDestroyed() && sender === appState.windows.clipboard.webContents) {
      if (!appState.windows.clipboard.isVisible()) {
        appState.windows.clipboard.show();
      }
    } else if (appState.windows.snippet && !appState.windows.snippet.isDestroyed() && sender === appState.windows.snippet.webContents) {
      if (!appState.windows.snippet.isVisible()) {
        appState.windows.snippet.show();
      }
    } else if (appState.windows.history && !appState.windows.history.isDestroyed() && sender === appState.windows.history.webContents) {
      if (!appState.windows.history.isVisible()) {
        appState.windows.history.show();
      }
    }
  });

  require('./ipc/clipboard-handlers')();
  require('./ipc/snippet-handlers')();
  require('./ipc/settings-handlers')(registerGlobalShortcuts);
  require('./ipc/auth-handlers')(startApp, createNotRegisteredWindow, handleLogout);
  require('./ipc/window-handlers')();

  setTimeout(() => {
    registerGlobalShortcuts();
  }, 500);

  if (app.isPackaged && autoUpdater) {
    autoUpdater.checkForUpdatesAndNotify();
  }

  checkLoginAndStart();
});

// IPCハンドラー



// アプリ終了時（システム再起動/シャットダウン対応）
app.on('before-quit', () => {
  app.isQuitting = true;
});

app.on('will-quit', () => {
  globalShortcut.unregisterAll();
});

app.on('window-all-closed', () => {
  app.quit();
});

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    createMainWindow();
  }
});




// =====================================
// 自動アップデート
// =====================================
// 設定画面からの手動ダウンロード用フラグ
let isManualDownload = false;

if (autoUpdater) autoUpdater.on('update-downloaded', () => {
  // 手動ダウンロードの場合は設定画面に通知
  if (isManualDownload && appState.windows.main && !appState.windows.main.isDestroyed()) {
    appState.windows.main.webContents.send('update-downloaded');
    isManualDownload = false;
    return;
  }
  
  // 自動ダウンロードの場合はダイアログ表示
  dialog.showMessageBox({
    type: 'info',
    title: 'Snipee アップデート',
    message: '新しいバージョンがダウンロードされました。再起動して適用しますか？',
    buttons: ['再起動', '後で']
  }).then((result) => {
    if (result.response === 0) {
      app.isQuitting = true;
      autoUpdater.quitAndInstall(false, true);
    }
  });
});

// ダウンロード進捗
if (autoUpdater) autoUpdater.on('download-progress', (progressObj) => {
  if (appState.windows.main && !appState.windows.main.isDestroyed()) {
    appState.windows.main.webContents.send('download-progress', progressObj.percent);
  }
});



// =====================================
// アップデートチェック（手動）
// =====================================


// =====================================
// 日次自動アップデートチェック
// =====================================
const UPDATE_CHECK_INTERVAL = 24 * 60 * 60 * 1000;
const UPDATE_CHECK_STARTUP_DELAY = 2 * 1000;

function scheduleDailyUpdateCheck() {
  if (!app.isPackaged || !autoUpdater) {
    return;
  }
  
  const checkIfNeeded = async () => {
    try {
      const lastCheck = store.get('lastAutoUpdateCheck', 0);
      const now = Date.now();
      
      if (now - lastCheck < UPDATE_CHECK_INTERVAL) {
        return;
      }
      
      store.set('lastAutoUpdateCheck', now);
      await autoUpdater.checkForUpdates();
    } catch (error) {
    }
  };
  
  setTimeout(checkIfNeeded, UPDATE_CHECK_STARTUP_DELAY);
  setInterval(checkIfNeeded, UPDATE_CHECK_INTERVAL);
}