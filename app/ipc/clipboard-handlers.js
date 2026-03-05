const { ipcMain, clipboard } = require('electron');
const appState = require('../app-state');
const { store } = require('../services/storage-service');
const variableService = require('../services/variable-service');
const pasteService = require('../services/paste-service');

const DEFAULT_MAX_HISTORY = 100;

function getMaxHistory() {
  return store.get('historyMaxCount', DEFAULT_MAX_HISTORY);
}

// マウストラッキング用変数
let isMouseOverClipboard = false;
let clipboardCloseTimer = null;

module.exports = function registerClipboardHandlers() {

  ipcMain.handle('get-all-items', () => {
    const masterSnippets = store.get('masterSnippets', { snippets: [] });
    const personalSnippets = require('../services/storage-service').personalStore.get('snippets', []);
    return {
      history: appState.clipboard.history,
      personalSnippets: personalSnippets,
      masterSnippets: masterSnippets.snippets || [],
      lastSync: store.get('lastSync', null),
      hasPermission: true
    };
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

  ipcMain.handle('paste-text', async (event, text) => {
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

    await new Promise(resolve => setTimeout(resolve, 10));
    await pasteService.pasteToActiveApp();

    return { success: true };
  });

  ipcMain.handle('get-history-max-count', () => {
    return getMaxHistory();
  });

  ipcMain.handle('set-history-max-count', (event, count) => {
    store.set('historyMaxCount', count);
    return true;
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
    if (clipboardCloseTimer) clearTimeout(clipboardCloseTimer);
    clipboardCloseTimer = setTimeout(() => {
      if (!isMouseOverClipboard && appState.windows.clipboard) {
        appState.windows.clipboard.hide();
      }
    }, 150);
  });

};