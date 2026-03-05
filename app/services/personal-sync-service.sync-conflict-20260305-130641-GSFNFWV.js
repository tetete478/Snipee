const googleAuth = require('./google-auth-service');
const driveApi = require('./google-drive-service');
const { personalStore } = require('./storage-service');
const appState = require('../app-state');

const SYNC_FOLDER_NAME = 'Snipee_データ';
let uploadTimer = null;
let syncFolderId = null;
let syncFileId = null;

// ファイル名（Mac版と統一）
async function getSyncFileName() {
  return 'personal_snippets.json';
}

// フォルダIDをキャッシュしつつ取得
async function getSyncFolderId() {
  if (syncFolderId) return syncFolderId;
  syncFolderId = await driveApi.findOrCreateFolder(SYNC_FOLDER_NAME);
  return syncFolderId;
}

// 起動時にDriveからダウンロードしてローカルとマージ
async function downloadPersonalData() {
  try {
    const loggedIn = await googleAuth.isLoggedIn();
    if (!loggedIn) return;

    const fileName = await getSyncFileName();
    if (!fileName) return;

    const folderId = await getSyncFolderId();
    if (!folderId) return;

    const file = await driveApi.findFile(fileName, folderId);
    if (!file) {
      return;
    }

    syncFileId = file.id;
    const cloudData = await driveApi.downloadJsonFile(file.id);
    if (!cloudData) return;

    const localSnippets = personalStore.get('snippets', []);
    const localFolders = personalStore.get('folders', []);
    // Mac版（ネスト型）→ Windows版（フラット型）に変換
    const rawFolders = cloudData.folders || [];
    let cloudSnippets = [];
    let cloudFolders = [];

    if (rawFolders.length > 0 && typeof rawFolders[0] === 'object') {
      // Mac版フォーマット: folders は [{name, snippets:[...]}, ...]
      cloudFolders = rawFolders.map(f => f.name);
      cloudSnippets = rawFolders.flatMap(f => f.snippets || []);
    } else {
      // Windows版フォーマット: folders は文字列配列
      cloudFolders = rawFolders;
      cloudSnippets = cloudData.snippets || [];
    }

    // Last-Writer-Wins マージ
    const merged = mergeSnippets(localSnippets, cloudSnippets);
    const mergedFolders = mergeFolders(localFolders, cloudFolders, merged);

    personalStore.set('snippets', merged);
    personalStore.set('folders', mergedFolders);

    // デバッグ：保存内容確認
    const savedSnippets = personalStore.get('snippets', []);
    const savedFolders = personalStore.get('folders', []);

    // スニペット編集画面が開いていたらリロード通知
    if (appState.windows.snippetEditor && !appState.windows.snippetEditor.isDestroyed()) {
      appState.windows.snippetEditor.webContents.send('personal-snippets-updated');
    }
  } catch (error) {
    console.error('[PersonalSync] ダウンロードエラー:', error.message);
  }
}

// スニペットをLast-Writer-Winsでマージ
function mergeSnippets(local, cloud) {
  const map = new Map();

  // ローカルを先に登録
  local.forEach(s => map.set(s.id, s));

  // クラウドで上書き（updatedAtが新しい場合のみ）
  cloud.forEach(s => {
    const localItem = map.get(s.id);
    if (!localItem) {
      map.set(s.id, s);
    } else {
      const localTime = new Date(localItem.updatedAt || 0).getTime();
      const cloudTime = new Date(s.updatedAt || 0).getTime();
      if (cloudTime > localTime) {
        map.set(s.id, s);
      }
    }
  });

  return Array.from(map.values());
}

// フォルダをマージ（重複排除・順序保持）
function mergeFolders(local, cloud, snippets) {
  // 文字列のみに絞り込み（壊れたオブジェクトを除外）
  const localClean = local.filter(f => typeof f === 'string');
  const cloudClean = cloud.filter(f => typeof f === 'string');
  const snippetFolders = [...new Set(snippets.map(s => s.folder).filter(f => typeof f === 'string'))];
  return [...new Set([...localClean, ...cloudClean, ...snippetFolders])];
}

// 現在のローカルデータをDriveにアップロード
async function uploadCurrentData() {
  try {
    const loggedIn = await googleAuth.isLoggedIn();
    if (!loggedIn) return;

    const fileName = await getSyncFileName();
    if (!fileName) return;

    const folderId = await getSyncFolderId();
    if (!folderId) return;

    // fileIdが未取得なら検索
    if (!syncFileId) {
      const file = await driveApi.findFile(fileName, folderId);
      syncFileId = file ? file.id : null;
    }

    const snippets = personalStore.get('snippets', []);
    const folders = personalStore.get('folders', []);

    // updatedAtを付与
    const now = new Date().toISOString();
    const snippetsWithTimestamp = snippets.map(s => ({
      ...s,
      updatedAt: s.updatedAt || now
    }));

    const data = {
      snippets: snippetsWithTimestamp,
      folders,
      updatedAt: now
    };

    const result = await driveApi.uploadJsonFile(syncFileId, folderId, fileName, data);
    if (result) {
      if (!syncFileId) syncFileId = result.id;
    }
  } catch (error) {
    console.error('[PersonalSync] アップロードエラー:', error.message);
  }
}

// 5秒デバウンスでアップロード（頻繁な保存を抑制）
function uploadPersonalDataDebounced() {
  if (uploadTimer) clearTimeout(uploadTimer);
  uploadTimer = setTimeout(() => {
    uploadCurrentData();
  }, 5000);
}

module.exports = {
  downloadPersonalData,
  uploadPersonalDataDebounced
};