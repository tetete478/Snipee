const { dialog } = require('electron');
const fs = require('fs');
const xml2js = require('xml2js');
const { personalStore } = require('./storage-service');

function escapeXmlForMerge(str) {
  if (!str) return '';
  return String(str).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&apos;');
}

async function importPersonalXml(xmlContent) {
  try {
    const parser = new xml2js.Parser({
      explicitArray: false,
      strict: false,
      trim: true,
      normalizeTags: true
    });

    const result = await parser.parseStringPromise(xmlContent);
    const foldersData = result.folders || result.FOLDERS;

    if (!foldersData) {
      return { success: false, error: 'XMLの形式が正しくありません' };
    }

    const folderArray = Array.isArray(foldersData.folder || foldersData.FOLDER)
      ? (foldersData.folder || foldersData.FOLDER)
      : [foldersData.folder || foldersData.FOLDER];

    const existingFolders = personalStore.get('folders', []);
    const existingSnippets = personalStore.get('snippets', []);

    let addedFolders = 0;
    let addedSnippets = 0;
    let updatedSnippets = 0;

    const newFolders = [...existingFolders];
    const newSnippets = [...existingSnippets];

    folderArray.forEach(folder => {
      if (!folder) return;
      const folderName = folder.title || 'Imported';

      if (!newFolders.includes(folderName)) {
        newFolders.push(folderName);
        addedFolders++;
      }

      const snippetArray = folder.snippets?.snippet
        ? (Array.isArray(folder.snippets.snippet)
            ? folder.snippets.snippet
            : [folder.snippets.snippet])
        : [];

      snippetArray.forEach(snippet => {
        if (!snippet) return;
        const snippetTitle = snippet.title || '無題';

        const existingIndex = newSnippets.findIndex(s =>
          s.folder === folderName && s.title === snippetTitle
        );

        if (existingIndex >= 0) {
          newSnippets[existingIndex] = {
            ...newSnippets[existingIndex],
            content: snippet.content || '',
            description: snippet.description || newSnippets[existingIndex].description || ''
          };
          updatedSnippets++;
        } else {
          newSnippets.push({
            id: Date.now().toString() + '-' + Math.random().toString(36).substr(2, 9),
            title: snippetTitle,
            content: snippet.content || '',
            description: snippet.description || '',
            folder: folderName
          });
          addedSnippets++;
        }
      });
    });

    personalStore.set('folders', newFolders);
    personalStore.set('snippets', newSnippets);

    return {
      success: true,
      importedFolders: addedFolders,
      importedSnippets: addedSnippets,
      updatedSnippets: updatedSnippets
    };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

async function exportSnippetsXml(xml, filename) {
  try {
    const result = await dialog.showSaveDialog({
      defaultPath: filename,
      filters: [
        { name: 'XML Files', extensions: ['xml'] }
      ]
    });

    if (result.canceled) {
      return { success: false, cancelled: true };
    }

    fs.writeFileSync(result.filePath, xml, 'utf-8');
    return { success: true, path: result.filePath };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

async function selectXmlFile() {
  try {
    const result = await dialog.showOpenDialog({
      title: 'XMLファイルを選択',
      filters: [{ name: 'XML Files', extensions: ['xml'] }],
      properties: ['openFile']
    });

    if (result.canceled || result.filePaths.length === 0) {
      return { success: false };
    }

    const filePath = result.filePaths[0];
    const content = fs.readFileSync(filePath, 'utf-8');
    return { success: true, content, path: filePath };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

module.exports = {
  escapeXmlForMerge,
  importPersonalXml,
  exportSnippetsXml,
  selectXmlFile
};