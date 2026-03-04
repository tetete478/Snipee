const { ipcMain, app, dialog } = require('electron');
const path = require('path');
const xml2js = require('xml2js');
const appState = require('../app-state');
const { store, personalStore } = require('../services/storage-service');
const syncService = require('../services/sync-service');
const personalSync = require('../services/personal-sync-service');
const snippetImportExportService = require('../services/snippet-import-export-service');

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

module.exports = function registerSnippetHandlers() {

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

  ipcMain.handle('save-master-folders', (event, folders) => {
    store.set('masterFolders', folders);
    return true;
  });

  ipcMain.handle('get-master-folders', () => {
    return store.get('masterFolders', []);
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
      } catch (e) {}
      return true;
    } catch (error) {
      return false;
    }
  });

  ipcMain.handle('get-personal-snippets', () => {
    if (!store.get('personalDataMigrated', false)) {
      const oldFolders = store.get('personalFolders', null);
      const oldSnippets = store.get('personalSnippets', null);
      if (oldFolders !== null || oldSnippets !== null) {
        if (oldFolders) personalStore.set('folders', oldFolders);
        if (oldSnippets) personalStore.set('snippets', oldSnippets);
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
    personalSync.uploadPersonalDataDebounced();
    return true;
  });

  ipcMain.handle('save-personal-snippets', (event, snippets) => {
    const current = personalStore.get('snippets', []);
    personalStore.set('snippets_backup', current);
    // updatedAtを付与して保存
    const now = new Date().toISOString();
    const snippetsWithTimestamp = snippets.map(s => ({ ...s, updatedAt: s.updatedAt || now }));
    personalStore.set('snippets', snippetsWithTimestamp);
    personalSync.uploadPersonalDataDebounced();
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
      // createSnippetEditorWindowはmain.jsの関数のため、ipcMain経由で呼び出す
      const { BrowserWindow } = require('electron');
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
      appState.windows.snippetEditor.loadFile(path.join(__dirname, '../views/snippet-editor.html'));
      appState.windows.snippetEditor.once('ready-to-show', () => {
        appState.windows.snippetEditor.show();
      });
      appState.windows.snippetEditor.on('closed', () => {
        appState.windows.snippetEditor = null;
      });
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

  ipcMain.handle('export-snippets-xml', async (event, { xml, filename }) => {
    return await snippetImportExportService.exportSnippetsXml(xml, filename);
  });

  ipcMain.handle('import-personal-xml', async (event, xmlContent) => {
    return await snippetImportExportService.importPersonalXml(xmlContent);
  });

  ipcMain.handle('select-xml-file', async () => {
    return await snippetImportExportService.selectXmlFile();
  });

  // マスタスニペットを手動で再同期
  ipcMain.handle('sync-master-snippets', async () => {
    try {
      await syncService.loadDepartmentSnippets();
      return { success: true, lastSync: store.get('lastSync', null) };
    } catch (error) {
      return { success: false, error: error.message };
    }
  });

  // 個別フォルダをマスタに昇格（フォルダ内の全スニペットも移動）
  ipcMain.handle('promote-folder', (event, folderName) => {
    const personalSnippets = personalStore.get('snippets', []);
    const personalFolders = personalStore.get('folders', []);
    const masterData = store.get('masterSnippets', { snippets: [] });
    const masterFolders = store.get('masterFolders', []);

    const targetSnippets = personalSnippets.filter(s => s.folder === folderName);

    masterData.snippets.push(...targetSnippets);
    store.set('masterSnippets', masterData);

    if (!masterFolders.includes(folderName)) {
      masterFolders.push(folderName);
      store.set('masterFolders', masterFolders);
    }

    personalStore.set('snippets', personalSnippets.filter(s => s.folder !== folderName));
    personalStore.set('folders', personalFolders.filter(f => f !== folderName));
    return { success: true };
  });

  // マスタフォルダを個別に降格（フォルダ内の全スニペットも移動）
  ipcMain.handle('demote-folder', (event, folderName) => {
    const masterData = store.get('masterSnippets', { snippets: [] });
    const masterFolders = store.get('masterFolders', []);
    const personalSnippets = personalStore.get('snippets', []);
    const personalFolders = personalStore.get('folders', []);

    const targetSnippets = masterData.snippets.filter(s => s.folder === folderName);

    personalSnippets.push(...targetSnippets);
    personalStore.set('snippets', personalSnippets);

    if (!personalFolders.includes(folderName)) {
      personalFolders.push(folderName);
      personalStore.set('folders', personalFolders);
    }

    masterData.snippets = masterData.snippets.filter(s => s.folder !== folderName);
    store.set('masterSnippets', masterData);

    const newMasterFolders = masterFolders.filter(f => f !== folderName);
    store.set('masterFolders', newMasterFolders);
    return { success: true };
  });

  // 個別スニペットをマスタに昇格
  ipcMain.handle('promote-snippet', (event, snippetId) => {
    const personalSnippets = personalStore.get('snippets', []);
    const snippet = personalSnippets.find(s => s.id === snippetId);
    if (!snippet) return { success: false, error: 'スニペットが見つかりません' };

    const masterData = store.get('masterSnippets', { snippets: [] });
    const masterFolders = store.get('masterFolders', []);

    masterData.snippets.push({ ...snippet });
    store.set('masterSnippets', masterData);

    if (!masterFolders.includes(snippet.folder)) {
      masterFolders.push(snippet.folder);
      store.set('masterFolders', masterFolders);
    }

    personalStore.set('snippets', personalSnippets.filter(s => s.id !== snippetId));
    return { success: true };
  });

  // 個別スニペットをクラウドから手動同期
  ipcMain.handle('sync-personal-snippets', async () => {
    try {
      await personalSync.downloadPersonalData();
      if (appState.windows.snippetEditor && !appState.windows.snippetEditor.isDestroyed()) {
        appState.windows.snippetEditor.webContents.send('personal-snippets-updated');
      }
      return { success: true };
    } catch (error) {
      return { success: false, error: error.message };
    }
  });

  // マスタスニペットを個別に降格
  ipcMain.handle('demote-snippet', (event, snippetId) => {
    const masterData = store.get('masterSnippets', { snippets: [] });
    const snippet = masterData.snippets.find(s => s.id === snippetId);
    if (!snippet) return { success: false, error: 'スニペットが見つかりません' };

    const personalFolders = personalStore.get('folders', []);
    const personalSnippets = personalStore.get('snippets', []);

    personalSnippets.push({ ...snippet });
    personalStore.set('snippets', personalSnippets);

    if (!personalFolders.includes(snippet.folder)) {
      personalFolders.push(snippet.folder);
      personalStore.set('folders', personalFolders);
    }

    masterData.snippets = masterData.snippets.filter(s => s.id !== snippetId);
    store.set('masterSnippets', masterData);
    return { success: true };
  });

};