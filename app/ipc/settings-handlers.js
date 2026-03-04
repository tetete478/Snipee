const { ipcMain, app, globalShortcut } = require('electron');
const appState = require('../app-state');
const { store } = require('../services/storage-service');

const DEFAULT_CLIPBOARD_SHORTCUT = 'Ctrl+Alt+C';
const DEFAULT_SNIPPET_SHORTCUT = 'Ctrl+Alt+V';
const DEFAULT_HISTORY_SHORTCUT = 'Ctrl+Alt+X';
const DEFAULT_MAX_HISTORY = 100;

module.exports = function registerSettingsHandlers(registerGlobalShortcuts) {

  ipcMain.handle('check-permission', () => {
    return true;
  });

  ipcMain.handle('request-permission', () => {
    return true;
  });

  ipcMain.handle('get-current-hotkey', (event, type) => {
    if (type === 'main') return store.get('customHotkeyMain', DEFAULT_CLIPBOARD_SHORTCUT);
    if (type === 'snippet') return store.get('customHotkeySnippet', DEFAULT_SNIPPET_SHORTCUT);
    if (type === 'history') return store.get('customHotkeyHistory', DEFAULT_HISTORY_SHORTCUT);
    return DEFAULT_CLIPBOARD_SHORTCUT;
  });

  ipcMain.handle('set-hotkey', (event, type, accelerator) => {
    try {
      if (type === 'main') store.set('customHotkeyMain', accelerator);
      else if (type === 'snippet') store.set('customHotkeySnippet', accelerator);
      else if (type === 'history') store.set('customHotkeyHistory', accelerator);
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

  ipcMain.handle('get-login-item-settings', () => {
    return app.getLoginItemSettings().openAtLogin;
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
    const maxHistory = store.get('historyMaxCount', DEFAULT_MAX_HISTORY);
    if (appState.clipboard.history.length > maxHistory) {
      appState.clipboard.history = appState.clipboard.history.slice(0, maxHistory);
      store.set('clipboardHistory', appState.clipboard.history);
    }
    return { success: true, value };
  });

  ipcMain.handle('hide-window', () => {
    if (appState.windows.clipboard) appState.windows.clipboard.hide();
    return true;
  });

  ipcMain.handle('hide-snippet-window', () => {
    if (appState.windows.snippet) appState.windows.snippet.hide();
    return true;
  });

  ipcMain.handle('hide-history-window', () => {
    if (appState.windows.history) appState.windows.history.hide();
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
    if (appState.windows.main) {
      appState.windows.main.show();
      appState.windows.main.focus();
    }
  });

  ipcMain.handle('hide-settings-window', () => {
    if (appState.windows.main) appState.windows.main.hide();
    return true;
  });

  ipcMain.handle('resize-window', (event, size) => {
    const sender = event.sender;
    const wins = appState.windows;
    if (wins.clipboard && !wins.clipboard.isDestroyed() && sender === wins.clipboard.webContents) {
      const b = wins.clipboard.getBounds();
      wins.clipboard.setBounds({ x: b.x, y: b.y, width: size.width, height: size.height });
    } else if (wins.snippet && !wins.snippet.isDestroyed() && sender === wins.snippet.webContents) {
      const b = wins.snippet.getBounds();
      wins.snippet.setBounds({ x: b.x, y: b.y, width: size.width, height: size.height });
    } else if (wins.history && !wins.history.isDestroyed() && sender === wins.history.webContents) {
      const b = wins.history.getBounds();
      wins.history.setBounds({ x: b.x, y: b.y, width: size.width, height: size.height });
    }
    return true;
  });

  ipcMain.handle('show-welcome-window', () => {
    store.set('welcomeCompleted', false);
    // createWelcomeWindowはmain.jsの関数のため直接呼び出せないので再実装
    const { BrowserWindow } = require('electron');
    const path = require('path');
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
    appState.windows.welcome.loadFile(path.join(__dirname, '../views/welcome.html'));
    appState.windows.welcome.once('ready-to-show', () => {
      appState.windows.welcome.show();
    });
    appState.windows.welcome.on('closed', () => {
      appState.windows.welcome = null;
    });
    return true;
  });

  ipcMain.handle('close-welcome-window', () => {
    if (appState.windows.welcome) appState.windows.welcome.close();
    return true;
  });

  ipcMain.handle('get-app-version', () => {
    return app.getVersion();
  });

  ipcMain.handle('check-for-updates', async () => {
    let autoUpdater = null;
    try {
      autoUpdater = require('electron-updater').autoUpdater;
    } catch (e) {}

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
          return { updateAvailable: false, currentVersion, latestVersion, message: '最新バージョンです！' };
        }
        return { updateAvailable: true, currentVersion, latestVersion, message: `新しいバージョン v${latestVersion} があります` };
      }
      return { updateAvailable: false, currentVersion: app.getVersion(), message: '最新バージョンです！' };
    } catch (error) {
      return { updateAvailable: false, currentVersion: app.getVersion(), error: true, message: 'アップデートの確認に失敗しました' };
    }
  });

  ipcMain.on('get-config', (event, key) => {
    event.returnValue = store.get(key);
  });

  ipcMain.on('save-config', (event, key, value) => {
    store.set(key, value);
  });

  ipcMain.on('download-update', () => {
    let autoUpdater = null;
    try { autoUpdater = require('electron-updater').autoUpdater; } catch (e) {}
    if (autoUpdater) autoUpdater.downloadUpdate();
  });

  ipcMain.on('quit-and-install', () => {
    let autoUpdater = null;
    try { autoUpdater = require('electron-updater').autoUpdater; } catch (e) {}
    app.isQuitting = true;
    if (autoUpdater) autoUpdater.quitAndInstall(false, true);
  });

};