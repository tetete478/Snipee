const { app, BrowserWindow, globalShortcut, ipcMain, clipboard, Tray, Menu, shell, dialog } = require('electron');

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
const sheetsApi = require('./services/google-sheets-service');
const driveApi = require('./services/google-drive-service');
const memberManager = require('./services/member-manager');
const variableService = require('./services/variable-service');
const pasteService = require('./services/paste-service');
const syncService = require('./services/sync-service');
const userReportService = require('./services/user-report-service');
const snippetImportExportService = require('./services/snippet-import-export-service');
const snippetPromotionService = require('./services/snippet-promotion-service');

const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });
const Store = require('electron-store');
const fs = require('fs');

const axios = require('axios');
const xml2js = require('xml2js');
let autoUpdater = null;
try {
  autoUpdater = require('electron-updater').autoUpdater;
  console.log('autoUpdater 読み込み成功');
} catch (error) {
  console.error('autoUpdater 読み込み失敗:', error.message);
}

// Windows自動ペースト用
const { exec, execSync } = require('child_process');

// ストアの初期化
const { store, personalStore } = require('./services/storage-service');

// デフォルトホットキー設定
const DEFAULT_CLIPBOARD_SHORTCUT = 'Ctrl+Alt+C';
const DEFAULT_SNIPPET_SHORTCUT = 'Ctrl+Alt+V';
const DEFAULT_HISTORY_SHORTCUT = 'Ctrl+Alt+X';

let tray = null;

// アクセシビリティ権限チェック
function hasAccessibilityPermission() {
  return true;
}

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
      console.log(`スコープバージョン更新検出: ${savedScopeVersion} → ${SCOPE_VERSION}`);
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
    console.error('checkLoginAndStart: エラー', error);
    createLoginWindow();
  }
}

function startApp() {
  createMainWindow();
  createTray();
  
  // 部署XMLを読み込み
  syncService.loadDepartmentSnippets();

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
        console.log(`ホットキー登録: ${accelerator} -> ${success ? '成功' : '失敗'}`);
        if (!success && remaining > 0) {
          setTimeout(() => attempt(remaining - 1), 500);
        }
      } catch (error) {
        console.log(`ホットキー登録エラー: ${accelerator} -> ${error.message}`);
        if (remaining > 0) {
          setTimeout(() => attempt(remaining - 1), 500);
        }
      }
    };
    attempt(retries);
  };

  registerWithRetry(mainHotkey, () => {
    pasteService.captureActiveApp();
    showClipboardWindow();
  });

  registerWithRetry(snippetHotkey, () => {
    pasteService.captureActiveApp();
    showSnippetWindow();
  });

  const historyHotkey = store.get('customHotkeyHistory', DEFAULT_HISTORY_SHORTCUT);
  registerWithRetry(historyHotkey, () => {
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

  setTimeout(() => {
    registerGlobalShortcuts();
  }, 500);

  if (app.isPackaged && autoUpdater) {
    autoUpdater.checkForUpdatesAndNotify();
  }

  checkLoginAndStart();
});

// IPCハンドラー
ipcMain.handle('get-all-items', () => {
  const masterSnippets = store.get('masterSnippets', { snippets: [] });
  const personalSnippets = personalStore.get('snippets', []);
  
  return {
    history: appState.clipboard.history,
    personalSnippets: personalSnippets,
    masterSnippets: masterSnippets.snippets || [],
    lastSync: store.get('lastSync', null),
    hasPermission: hasAccessibilityPermission()
  };
});

ipcMain.handle('check-permission', () => {
  return hasAccessibilityPermission();
});

ipcMain.handle('request-permission', () => {
  return true;
});

// ホットキー管理
ipcMain.handle('get-current-hotkey', (event, type) => {
  if (type === 'main') {
    return store.get('customHotkeyMain', DEFAULT_CLIPBOARD_SHORTCUT);
  } else if (type === 'snippet') {
    return store.get('customHotkeySnippet', DEFAULT_SNIPPET_SHORTCUT);
  } else if (type === 'history') {
    return store.get('customHotkeyHistory', DEFAULT_HISTORY_SHORTCUT);
  }
  return DEFAULT_CLIPBOARD_SHORTCUT;
});

ipcMain.handle('set-hotkey', (event, type, accelerator) => {
  try {
    if (type === 'main') {
      store.set('customHotkeyMain', accelerator);
    } else if (type === 'snippet') {
      store.set('customHotkeySnippet', accelerator);
    } else if (type === 'history') {
      store.set('customHotkeyHistory', accelerator);
    }
    
    registerGlobalShortcuts();
    
    return { success: true };
  } catch (error) {
    return { success: false, error: error.message };
  }
});

ipcMain.handle('reset-all-hotkeys', () => {
  store.delete('customHotkeyMain');
  store.delete('customHotkeySnippet');
  store.delete('customHotkeyHistory');
  registerGlobalShortcuts();
  return true;
});

ipcMain.handle('get-snippets', () => {
  const masterSnippets = store.get('masterSnippets', { snippets: [] });
  
  return {
    master: masterSnippets,
    lastSync: store.get('lastSync', null)
  };
});

ipcMain.handle('save-master-snippet', (event, snippet) => {
  const masterSnippets = store.get('masterSnippets', { snippets: [] });
  masterSnippets.snippets.push(snippet);
  store.set('masterSnippets', masterSnippets);
  return true;
});

ipcMain.handle('update-master-snippet', (event, snippet) => {
  const masterSnippets = store.get('masterSnippets', { snippets: [] });
  const index = masterSnippets.snippets.findIndex(s => s.id === snippet.id);
  if (index !== -1) {
    masterSnippets.snippets[index] = snippet;
    store.set('masterSnippets', masterSnippets);
  }
  return true;
});

ipcMain.handle('delete-master-snippet', (event, snippetId) => {
  const masterSnippets = store.get('masterSnippets', { snippets: [] });
  masterSnippets.snippets = masterSnippets.snippets.filter(s => s.id !== snippetId);
  store.set('masterSnippets', masterSnippets);
  return true;
});

ipcMain.handle('delete-history-item', (event, itemId) => {
  appState.clipboard.history = appState.clipboard.history.filter(item => item.id !== itemId);
  store.set('clipboardHistory', appState.clipboard.history);
  return true;
});

ipcMain.handle('clear-all-history', () => {
  appState.clipboard.history = [];
  store.set('clipboardHistory', []);
  return true;
});

ipcMain.handle('toggle-pin-item', (event, itemId) => {
  const index = appState.clipboard.pinnedItems.indexOf(itemId);
  
  if (index > -1) {
    appState.clipboard.pinnedItems.splice(index, 1);
  } else {
    appState.clipboard.pinnedItems.push(itemId);
  }
  
  store.set('pinnedItems', appState.clipboard.pinnedItems);
  return { pinnedItems: appState.clipboard.pinnedItems };
});

ipcMain.handle('get-pinned-items', () => {
  return appState.clipboard.pinnedItems;
});

ipcMain.handle('copy-to-clipboard', (event, text) => {
  clipboard.writeText(text);
  appState.clipboard.lastText = text;
  return true;
});

ipcMain.handle('set-master-url', async (event, url) => {
  store.set('masterSnippetUrl', url);
  const result = await syncService.syncSnippets();
  return result;
});

ipcMain.handle('manual-sync', async () => {
  const result = await syncService.syncSnippets();
  return {
    success: result.success,
    error: result.error,
    lastSync: store.get('lastSync', null)
  };
});

ipcMain.handle('remove-master-url', async () => {
  try {
    store.delete('masterSnippetUrl');
    store.set('masterSnippets', { snippets: [] });
    store.delete('lastSync');
    
    const orderFile = path.join(app.getPath('userData'), 'master-snippets-order.json');
    try {
      require('fs').unlinkSync(orderFile);
    } catch (e) {
      // ファイルが存在しない場合は無視
    }
    
    return true;
  } catch (error) {
    return false;
  }
});

ipcMain.handle('hide-window', () => {
  if (appState.windows.clipboard) {
    appState.windows.clipboard.hide();
  }
  return true;
});

ipcMain.handle('hide-snippet-window', () => {
  if (appState.windows.snippet) {
    appState.windows.snippet.hide();
  }
  return true;
});

ipcMain.handle('hide-history-window', () => {
  if (appState.windows.history) {
    appState.windows.history.hide();
  }
  return true;
});

ipcMain.handle('quit-app', () => {
  app.isQuitting = true;
  app.quit();
  return true;
});

ipcMain.handle('show-settings', () => {
  if (appState.windows.clipboard && !appState.windows.clipboard.isDestroyed()) {
    appState.windows.clipboard.destroy();
    appState.windows.clipboard = null;
  }
  
  if (appState.windows.snippet && !appState.windows.snippet.isDestroyed()) {
    appState.windows.snippet.destroy();
    appState.windows.snippet = null;
  }
  
  if (appState.windows.history && !appState.windows.history.isDestroyed()) {
    appState.windows.history.destroy();
    appState.windows.history = null;
  }
  
  // 設定画面を表示
  if (appState.windows.main) {
    appState.windows.main.show();
    appState.windows.main.focus();
  }
});

ipcMain.handle('hide-settings-window', () => {
  if (appState.windows.main) {
    appState.windows.main.hide();
  }
  return true;
});

// マウストラッキング
let isMouseOverClipboard = false;
let clipboardCloseTimer = null;

ipcMain.on('log', (event, msg) => {
  console.log(msg);
});

ipcMain.on('clipboard-mouse-enter', () => {
  isMouseOverClipboard = true;
  
  if (clipboardCloseTimer) {
    clearTimeout(clipboardCloseTimer);
    clipboardCloseTimer = null;
  }
});

ipcMain.on('clipboard-mouse-leave', () => {
  isMouseOverClipboard = false;
  
  if (clipboardCloseTimer) {
    clearTimeout(clipboardCloseTimer);
  }
  
  clipboardCloseTimer = setTimeout(() => {
    if (!isMouseOverClipboard) {
      if (appState.windows.clipboard) {
        appState.windows.clipboard.hide();
      }
    }
  }, 150);
});

ipcMain.handle('paste-text', async (event, text) => {
  // 変数を置換
  const processedText = variableService.replaceVariables(text, store);
  
  clipboard.writeText(processedText);

  // 使用した履歴を最新に移動
  const existingIndex = appState.clipboard.history.findIndex(item => item.content === processedText);
  if (existingIndex > 0) {
    const [usedItem] = appState.clipboard.history.splice(existingIndex, 1);
    usedItem.timestamp = new Date().toISOString();
    appState.clipboard.history.unshift(usedItem);
    store.set('clipboardHistory', appState.clipboard.history);
  }

  appState.clipboard.lastText = processedText;

  if (appState.windows.clipboard) appState.windows.clipboard.hide();
  if (appState.windows.snippet) appState.windows.snippet.hide();
  if (appState.windows.history) appState.windows.history.hide();

  // ウィンドウ閉じ待ち
  await new Promise(resolve => setTimeout(resolve, 10));

  // Windows: フォーカスを戻してペースト
  await pasteService.pasteToActiveApp();

  return { success: true };
});

// 個別スニペット管理
ipcMain.handle('get-personal-snippets', () => {
  // 旧データの移行チェック（一度だけ実行）
  if (!store.get('personalDataMigrated', false)) {
    const oldFolders = store.get('personalFolders', null);
    const oldSnippets = store.get('personalSnippets', null);
    
    if (oldFolders !== null || oldSnippets !== null) {
      // 旧データがあれば移行
      if (oldFolders) personalStore.set('folders', oldFolders);
      if (oldSnippets) personalStore.set('snippets', oldSnippets);
      
      // 旧データを削除
      store.delete('personalFolders');
      store.delete('personalSnippets');
    }
    store.set('personalDataMigrated', true);
  }
  
  return {
    folders: personalStore.get('folders', []),
    snippets: personalStore.get('snippets', [])
  };
});

ipcMain.handle('save-personal-folders', (event, folders) => {
  const current = personalStore.get('folders', []);
  personalStore.set('folders_backup', current);
  personalStore.set('folders', folders);
  return true;
});

ipcMain.handle('save-personal-snippets', (event, snippets) => {
  const current = personalStore.get('snippets', []);
  personalStore.set('snippets_backup', current);
  personalStore.set('snippets', snippets);
  
  if (appState.windows.clipboard && !appState.windows.clipboard.isDestroyed()) {
    appState.windows.clipboard.webContents.send('personal-snippets-updated');
  }
  if (appState.windows.snippet && !appState.windows.snippet.isDestroyed()) {
    appState.windows.snippet.webContents.send('personal-snippets-updated');
  }
  
  return true;
});

ipcMain.handle('open-snippet-editor', () => {
  if (appState.windows.clipboard && !appState.windows.clipboard.isDestroyed()) {
    appState.windows.clipboard.destroy();
    appState.windows.clipboard = null;
  }
  
  if (appState.windows.snippet && !appState.windows.snippet.isDestroyed()) {
    appState.windows.snippet.destroy();
    appState.windows.snippet = null;
  }
  
  if (appState.windows.history && !appState.windows.history.isDestroyed()) {
    appState.windows.history.destroy();
    appState.windows.history = null;
  }
  
  if (!appState.windows.snippetEditor || appState.windows.snippetEditor.isDestroyed()) {
    createSnippetEditorWindow();
  } else {
    appState.windows.snippetEditor.show();
    appState.windows.snippetEditor.focus();
  }
  return true;
});

ipcMain.handle('close-snippet-editor', () => {
  if (appState.windows.snippetEditor) {
    appState.windows.snippetEditor.close();
  }
  return true;
});

ipcMain.handle('get-snippet-window-bounds', () => {
  if (appState.windows.snippet && !appState.windows.snippet.isDestroyed()) {
    return appState.windows.snippet.getBounds();
  }
  return { x: 0, y: 0, width: 460, height: 650 };
});

ipcMain.handle('get-window-position-mode', () => {
  return store.get('windowPositionMode', 'cursor');
});

ipcMain.handle('set-window-position-mode', (event, mode) => {
  store.set('windowPositionMode', mode);
  return true;
});

ipcMain.handle('get-hidden-folders', () => {
  return store.get('hiddenFolders', []);
});

ipcMain.handle('set-hidden-folders', (event, folders) => {
  store.set('hiddenFolders', folders);
  return true;
});

ipcMain.handle('update-master-description', (event, snippetId, description) => {
  const masterData = store.get('masterSnippets', { snippets: [] });
  const snippet = masterData.snippets.find(s => s.id === snippetId);
  
  if (snippet) {
    snippet.description = description;
    store.set('masterSnippets', masterData);
    return { success: true };
  }
  
  return { success: false };
});

// マスタフォルダ保存
ipcMain.handle('save-master-folders', (event, folders) => {
  store.set('masterFolders', folders);
  return true;
});

// マスタフォルダ取得
ipcMain.handle('get-master-folders', () => {
  return store.get('masterFolders', []);
});

ipcMain.handle('get-login-item-settings', () => {
  const settings = app.getLoginItemSettings();
  return settings.openAtLogin;
});

ipcMain.handle('set-login-item-settings', (event, enabled) => {
  app.setLoginItemSettings({ openAtLogin: enabled });
  return { success: true };
});

ipcMain.handle('get-history-max-count', () => {
  return store.get('historyMaxCount', DEFAULT_MAX_HISTORY);
});

ipcMain.handle('set-history-max-count', (event, count) => {
  const value = Math.max(10, Math.min(1000, parseInt(count) || DEFAULT_MAX_HISTORY));
  store.set('historyMaxCount', value);
  
  const maxHistory = getMaxHistory();
  if (appState.clipboard.history.length > maxHistory) {
    appState.clipboard.history = appState.clipboard.history.slice(0, maxHistory);
    store.set('clipboardHistory', appState.clipboard.history);
  }
  
  return { success: true, value };
});

ipcMain.handle('save-master-order', async (event, orderData) => {
  try {
    const orderFile = path.join(app.getPath('userData'), 'master-snippets-order.json');
    require('fs').writeFileSync(orderFile, JSON.stringify(orderData, null, 2), 'utf-8');
    return { success: true };
  } catch (error) {
    return { success: false, error: error.message };
  }
});

ipcMain.handle('get-master-order', async () => {
  try {
    const orderFile = path.join(app.getPath('userData'), 'master-snippets-order.json');
    const data = require('fs').readFileSync(orderFile, 'utf-8');
    return JSON.parse(data);
  } catch (error) {
    return [];
  }
});

ipcMain.handle('resize-window', (event, size) => {
  const sender = event.sender;
  
  if (appState.windows.clipboard && !appState.windows.clipboard.isDestroyed() && sender === appState.windows.clipboard.webContents) {
    const currentBounds = appState.windows.clipboard.getBounds();
    appState.windows.clipboard.setBounds({
      x: currentBounds.x,
      y: currentBounds.y,
      width: size.width,
      height: size.height
    });
  } else if (appState.windows.snippet && !appState.windows.snippet.isDestroyed() && sender === appState.windows.snippet.webContents) {
    const currentBounds = appState.windows.snippet.getBounds();
    appState.windows.snippet.setBounds({
      x: currentBounds.x,
      y: currentBounds.y,
      width: size.width,
      height: size.height
    });
  } else if (appState.windows.history && !appState.windows.history.isDestroyed() && sender === appState.windows.history.webContents) {
    const currentBounds = appState.windows.history.getBounds();
    appState.windows.history.setBounds({
      x: currentBounds.x,
      y: currentBounds.y,
      width: size.width,
      height: size.height
    });
  }
  
  return true;
});

ipcMain.handle('export-snippets-xml', async (event, { xml, filename }) => {
  return await snippetImportExportService.exportSnippetsXml(xml, filename);
});

ipcMain.handle('show-welcome-window', () => {
  store.set('welcomeCompleted', false);
  createWelcomeWindow();
  return true;
});

ipcMain.handle('close-welcome-window', () => {
  if (appState.windows.welcome) {
    appState.windows.welcome.close();
  }
  return true;
});

// 設定の取得・保存
ipcMain.on('get-config', (event, key) => {
  event.returnValue = store.get(key);
});

ipcMain.on('save-config', (event, key, value) => {
  store.set(key, value);
});

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

// スニペットID生成関数
function generateSnippetId(folder, title, content) {
  const base = `${folder}_${title}_${content.substring(0, 100)}`;
  let hash = 0;
  for (let i = 0; i < base.length; i++) {
    hash = ((hash << 5) - hash) + base.charCodeAt(i);
    hash = hash & hash;
  }
  return `snippet_${Math.abs(hash).toString(36)}`;
}


// =====================================
// 自動アップデート
// =====================================
// 設定画面からの手動ダウンロード用フラグ
let isManualDownload = false;

if (autoUpdater) if (autoUpdater) autoUpdater.on('update-downloaded', () => {
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
if (autoUpdater) if (autoUpdater) autoUpdater.on('download-progress', (progressObj) => {
  if (appState.windows.main && !appState.windows.main.isDestroyed()) {
    appState.windows.main.webContents.send('download-progress', progressObj.percent);
  }
});

// 手動ダウンロード開始
ipcMain.on('download-update', () => {
  isManualDownload = true;
  autoUpdater.downloadUpdate();
});

// 再起動してインストール
ipcMain.on('quit-and-install', () => {
  app.isQuitting = true;
  autoUpdater.quitAndInstall(false, true);
});

// =====================================
// アップデートチェック（手動）
// =====================================
ipcMain.handle('get-app-version', () => {
  return app.getVersion();
});

ipcMain.handle('check-for-updates', async () => {
  try {
    if (!app.isPackaged) {
      return { updateAvailable: false, currentVersion: app.getVersion(), message: '開発環境です' };
    }
    
    if (!autoUpdater) {
      return { updateAvailable: false, currentVersion: app.getVersion(), error: true, message: 'アップデーターが利用できません' };
    }
    
    const result = await autoUpdater.checkForUpdates();
    
    if (result && result.updateInfo) {
      const currentVersion = app.getVersion();
      const latestVersion = result.updateInfo.version;
      
      if (latestVersion === currentVersion) {
        return {
          updateAvailable: false,
          currentVersion,
          latestVersion,
          message: '最新バージョンです！'
        };
      }
      
      return {
        updateAvailable: true,
        currentVersion,
        latestVersion,
        message: `新しいバージョン v${latestVersion} があります`
      };
    }
    
    return { 
      updateAvailable: false, 
      currentVersion: app.getVersion(),
      message: '最新バージョンです！'
    };
  } catch (error) {
    console.error('Update check failed:', error);
    return { 
      updateAvailable: false, 
      currentVersion: app.getVersion(),
      error: true,
      message: 'アップデートの確認に失敗しました'
    };
  }
});

// =====================================
// 日次自動アップデートチェック
// =====================================
const UPDATE_CHECK_INTERVAL = 24 * 60 * 60 * 1000;
const UPDATE_CHECK_STARTUP_DELAY = 2 * 1000;

function scheduleDailyUpdateCheck() {
  if (!app.isPackaged || !autoUpdater) {
    console.log('📦 自動アップデートチェックをスキップ（開発環境 or autoUpdater無効）');
    return;
  }
  
  const checkIfNeeded = async () => {
    try {
      const lastCheck = store.get('lastAutoUpdateCheck', 0);
      const now = Date.now();
      
      if (now - lastCheck < UPDATE_CHECK_INTERVAL) {
        console.log('⏭️ 前回チェックから24時間未経過、スキップ');
        return;
      }
      
      console.log('🔄 日次アップデートチェック開始');
      store.set('lastAutoUpdateCheck', now);
      await autoUpdater.checkForUpdates();
    } catch (error) {
      console.error('⚠️ 日次アップデートチェック失敗:', error);
    }
  };
  
  setTimeout(checkIfNeeded, UPDATE_CHECK_STARTUP_DELAY);
  setInterval(checkIfNeeded, UPDATE_CHECK_INTERVAL);
}

ipcMain.handle('google-login', async () => {
  try {
    // ログイン画面を非表示
    if (appState.windows.login) {
      appState.windows.login.hide();
    }
    
    const result = await googleAuth.authenticate();
    if (result.success) {
      const initResult = await memberManager.initialize();
      if (initResult.success) {
        if (appState.windows.login) {
          appState.windows.login.close();
        }
        store.set('scopeVersion', 3);
        startApp();
        return { success: true };
      } else if (initResult.error === 'not_registered') {
        if (appState.windows.login) {
          appState.windows.login.close();
        }
        createNotRegisteredWindow(initResult.email);
        return { success: false, error: 'not_registered' };
      }
    }
    // 認証失敗時はログイン画面を再表示
    if (appState.windows.login) {
      appState.windows.login.show();
    }
    return result;
  } catch (error) {
    if (appState.windows.login) {
      appState.windows.login.show();
    }
    return { success: false, error: error.message };
  }
});

ipcMain.handle('google-login-for-onboarding', async () => {
  try {
    const result = await googleAuth.authenticate();
    if (result.success) {
      const initResult = await memberManager.initialize();
      if (initResult.success) {
        store.set('scopeVersion', 3);
        return { success: true };
      } else if (initResult.error === 'not_registered') {
        return { success: false, error: 'メンバーリストに登録されていません。\n管理者に連絡してください。' };
      }
    }
    return { success: false, error: '認証に失敗しました' };
  } catch (error) {
    return { success: false, error: error.message };
  }
});

ipcMain.handle('google-logout', async () => {
  await googleAuth.logout();
  return { success: true };
});

ipcMain.handle('get-user-email', async () => {
  const email = await googleAuth.getUserEmail();
  return email;
});

ipcMain.handle('is-logged-in', async () => {
  return await googleAuth.isLoggedIn();
});

ipcMain.handle('get-member-info', async () => {
  const email = await googleAuth.getUserEmail();
  if (!email) return null;
  
  const member = await sheetsApi.getMemberByEmail(email);
  return member;
});

ipcMain.handle('get-department-settings', async () => {
  return await sheetsApi.getDepartmentSettings();
});

ipcMain.handle('get-drive-file', async (event, fileId) => {
  return await driveApi.getFileContent(fileId);
});

ipcMain.handle('upload-drive-file', async (event, fileId, content) => {
  return await driveApi.uploadFile(fileId, content);
});

ipcMain.handle('initialize-member', async () => {
  return await memberManager.initialize();
});

ipcMain.handle('get-current-member', () => {
  return memberManager.getCurrentMember();
});

ipcMain.handle('get-editable-departments', async () => {
  const member = memberManager.getCurrentMember();
  if (!member) return { departments: [], role: null };
  
  const allDepartments = await sheetsApi.getDepartmentSettings();
  
  if (member.role === '最高管理者') {
    return { 
      departments: allDepartments, 
      role: member.role,
      userDepartments: member.departments
    };
  } else if (member.role === '管理者') {
    const editableDepts = allDepartments.filter(d => 
      member.departments.includes(d.name)
    );
    return { 
      departments: editableDepts, 
      role: member.role,
      userDepartments: member.departments
    };
  }
  
  return { 
    departments: [], 
    role: member.role,
    userDepartments: member.departments
  };
});

ipcMain.handle('get-viewable-departments', async () => {
  try {
    const member = memberManager.getCurrentMember();
    if (!member || (member.role !== '最高管理者' && member.role !== '管理者')) {
      return { departments: [], role: member?.role };
    }
    
    const allDepartments = await sheetsApi.getDepartmentSettings();
    const otherDepartments = allDepartments.filter(d => !member.departments.includes(d.name));
    
    return {
      departments: otherDepartments,
      role: member.role,
      userDepartments: member.departments
    };
  } catch (error) {
    return { departments: [], error: error.message };
  }
});

ipcMain.handle('get-other-department-snippets', async (event, departmentName) => {
  try {
    const member = memberManager.getCurrentMember();
    if (!member || (member.role !== '最高管理者' && member.role !== '管理者')) {
      return { success: false, error: '権限がありません' };
    }
    
    const xmlResult = await memberManager.getDepartmentXml(departmentName);
    if (!xmlResult || !xmlResult.xml) {
      return { success: false, error: 'XMLデータが取得できません' };
    }
    
    const parser = new xml2js.Parser({
      explicitArray: false,
      strict: false,
      trim: true,
      normalize: false,
      normalizeTags: true,
      attrkey: '$',
      charkey: '_',
      explicitCharkey: false,
      mergeAttrs: false
    });
    
    const result = await parser.parseStringPromise(xmlResult.xml);
    const foldersData = result.folders || result.FOLDERS;
    const snippets = [];
    
    if (foldersData && (foldersData.folder || foldersData.FOLDER)) {
      const folderArray = Array.isArray(foldersData.folder || foldersData.FOLDER)
        ? (foldersData.folder || foldersData.FOLDER)
        : [foldersData.folder || foldersData.FOLDER];
      
      folderArray.forEach(folder => {
        const folderName = folder.title || 'Uncategorized';
        const snippetArray = folder.snippets && folder.snippets.snippet
          ? (Array.isArray(folder.snippets.snippet)
              ? folder.snippets.snippet
              : [folder.snippets.snippet])
          : [];
        
        snippetArray.forEach(snippet => {
          snippets.push({
            id: snippet.id || generateSnippetId(folderName, snippet.title || '', (snippet.content || '').substring(0, 100)),
            title: snippet.title || '',
            content: snippet.content || '',
            description: snippet.description || '',
            folder: folderName,
            department: departmentName
          });
        });
      });
    }
    
    const folders = [...new Set(snippets.map(s => s.folder))];
    return { success: true, snippets, folders };
  } catch (error) {
    return { success: false, error: error.message };
  }
});

ipcMain.handle('upload-department-xml', async (event, { departmentName, xmlContent }) => {
  return await snippetPromotionService.uploadDepartmentXml(departmentName, xmlContent);
});

ipcMain.handle('import-personal-xml', async (event, xmlContent) => {
  return await snippetImportExportService.importPersonalXml(xmlContent);
});

ipcMain.handle('select-xml-file', async () => {
  return await snippetImportExportService.selectXmlFile();
});

ipcMain.handle('is-admin', () => {
  return memberManager.isAdmin();
});

ipcMain.handle('can-edit-department', (event, departmentName) => {
  return memberManager.canEditDepartment(departmentName);
});

ipcMain.handle('get-department-xml', async (event, departmentName) => {
  return await memberManager.getDepartmentXml(departmentName);
});

ipcMain.handle('get-all-accessible-xml', async () => {
  return await memberManager.getAllAccessibleXml();
});