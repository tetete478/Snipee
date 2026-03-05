const { ipcMain, app, shell } = require('electron');
const appState = require('../app-state');
const { store } = require('../services/storage-service');

const DEFAULT_MAX_HISTORY = 100;

module.exports = function registerWindowHandlers() {

  ipcMain.handle('get-login-item-settings', () => {
    return app.getLoginItemSettings().openAtLogin;
  });

  ipcMain.handle('set-login-item-settings', (event, enabled) => {
    app.setLoginItemSettings({ openAtLogin: enabled });
    return { success: true };
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

  

  ipcMain.handle('close-welcome-window', () => {
    if (appState.windows.welcome && !appState.windows.welcome.isDestroyed()) {
      appState.windows.welcome.destroy();
      appState.windows.welcome = null;
    }
    return true;
  });

  ipcMain.on('window-ready', () => {
    // ウィンドウ準備完了通知（現在は使用なし）
  });

  ipcMain.on('log', (event, message) => {
    console.log('[Renderer]', message);
  });

};