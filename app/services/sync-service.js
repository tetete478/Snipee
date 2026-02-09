const axios = require('axios');
const xml2js = require('xml2js');
const { store } = require('./storage-service');
const memberManager = require('./member-manager');

function generateSnippetId(folder, title, content) {
  const base = `${folder}_${title}_${content.substring(0, 100)}`;
  let hash = 0;
  for (let i = 0; i < base.length; i++) {
    hash = ((hash << 5) - hash) + base.charCodeAt(i);
    hash = hash & hash;
  }
  return `snippet_${Math.abs(hash).toString(36)}`;
}

async function parseXml(xml, department) {
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

  const result = await parser.parseStringPromise(xml);
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
        const title = snippet.title || '';
        const content = snippet.content || '';
        const description = snippet.description || '';
        const id = snippet.id || generateSnippetId(folderName, title, content);

        snippets.push({
          id,
          title,
          content,
          description,
          folder: folderName,
          department: department || null
        });
      });
    });
  }

  return snippets;
}

async function loadDepartmentSnippets() {
  try {
    const xmlDataArray = await memberManager.getAllAccessibleXml();
    console.log('loadDepartmentSnippets: 取得した部署XML数 =', xmlDataArray.length);

    if (xmlDataArray.length === 0) {
      console.log('loadDepartmentSnippets: 部署XMLがありません');
      return;
    }

    const allSnippets = [];

    for (const { department, xml } of xmlDataArray) {
      console.log(`loadDepartmentSnippets: ${department} のXMLをパース中...`);

      try {
        const snippets = await parseXml(xml, department);
        allSnippets.push(...snippets);
      } catch (parseError) {
        console.error(`loadDepartmentSnippets: ${department} のパースエラー`, parseError.message);
      }
    }

    console.log('loadDepartmentSnippets: 統合スニペット数 =', allSnippets.length);

    const xmlFolders = [...new Set(allSnippets.map(s => s.folder))];
    store.set('masterFolders', xmlFolders);
    store.set('masterSnippets', { snippets: allSnippets });
    store.set('lastSync', new Date().toISOString());

  } catch (error) {
    console.error('loadDepartmentSnippets: エラー', error);
  }
}

function extractFileIdFromUrl(url) {
  const match = url.match(/\/d\/([a-zA-Z0-9_-]+)/);
  return match ? match[1] : url;
}

async function fetchMasterSnippets() {
  const url = store.get('masterSnippetUrl', 'https://drive.google.com/file/d/1MIHYx_GUjfqv591h6rzIbcxm_FQZwAXY/view?usp=sharing');
  if (!url) return { error: 'URLが設定されていません' };

  try {
    const fileId = extractFileIdFromUrl(url);
    const downloadUrl = `https://drive.usercontent.google.com/download?id=${fileId}&export=download&confirm=t`;

    const response = await axios.get(downloadUrl, { responseType: 'text' });
    const xmlData = response.data;

    const lowerData = xmlData.toLowerCase();
    if (lowerData.includes('<!doctype html>') || lowerData.includes('<html')) {
      return { error: 'アクセスが制限されています。Google Driveの共有設定で「リンクを知っている全員」に変更してください。' };
    }

    if (!xmlData.includes('<folders>') && !xmlData.includes('<FOLDERS>')) {
      return { error: 'XMLファイルの形式が正しくありません。Clipyのエクスポート形式を確認してください。' };
    }

    const snippets = await parseXml(xmlData, null);
    return { snippets };
  } catch (error) {
    return { error: `同期エラー: ${error.message}` };
  }
}

async function syncSnippets() {
  const result = await fetchMasterSnippets();

  if (!result || result.error) {
    return { success: false, error: result?.error || '同期に失敗しました' };
  }

  if (!result.snippets || !Array.isArray(result.snippets)) {
    return { success: false, error: 'スニペットデータが無効です' };
  }

  const xmlSnippets = result.snippets;
  const existingMaster = store.get('masterSnippets', { snippets: [] });
  let masterSnippets = existingMaster.snippets || [];
  const xmlIds = xmlSnippets.map(s => s.id);

  xmlSnippets.forEach(xmlSnip => {
    const existing = masterSnippets.find(s => s.id === xmlSnip.id);

    if (existing) {
      existing.title = xmlSnip.title;
      existing.folder = xmlSnip.folder;
      existing.content = xmlSnip.content;

      if (!existing.description) {
        existing.description = xmlSnip.description;
      }
    } else {
      masterSnippets.push(xmlSnip);
    }
  });

  masterSnippets = masterSnippets.filter(s => xmlIds.includes(s.id));
  const xmlFolders = [...new Set(xmlSnippets.map(s => s.folder))];

  store.set('masterFolders', xmlFolders);
  store.set('masterSnippets', { snippets: masterSnippets });
  store.set('lastSync', new Date().toISOString());

  return { success: true };
}

let syncInterval = null;

function startAutoSync(intervalMs = 1 * 60 * 60 * 1000) {
  syncInterval = setInterval(async () => {
    console.log('部署スニペット自動同期開始...');
    await loadDepartmentSnippets();
    console.log('部署スニペット自動同期完了');
  }, intervalMs);
}

function stopAutoSync() {
  if (syncInterval) {
    clearInterval(syncInterval);
    syncInterval = null;
  }
}

module.exports = {
  loadDepartmentSnippets,
  fetchMasterSnippets,
  extractFileIdFromUrl,
  syncSnippets,
  parseXml,
  generateSnippetId,
  startAutoSync,
  stopAutoSync
};