const { ipcMain, app } = require('electron');
const appState = require('../app-state');
const { store } = require('../services/storage-service');

const DEFAULT_CLIPBOARD_SHORTCUT = 'Ctrl+Alt+C';
const DEFAULT_SNIPPET_SHORTCUT = 'Ctrl+Alt+V';
const DEFAULT_HISTORY_SHORTCUT = 'Ctrl+Alt+X';

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

  ipcMain.handle('get-app-version', () => {
    return app.getVersion();
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