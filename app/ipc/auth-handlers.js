const { ipcMain } = require('electron');
const xml2js = require('xml2js');
const appState = require('../app-state');
const { store } = require('../services/storage-service');
const googleAuth = require('../services/google-auth-service');
const sheetsApi = require('../services/google-sheets-service');
const driveApi = require('../services/google-drive-service');
const memberManager = require('../services/member-manager');
const snippetPromotionService = require('../services/snippet-promotion-service');
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

module.exports = function registerAuthHandlers(startApp, createNotRegisteredWindow) {

  ipcMain.handle('google-login', async () => {
    try {
      if (appState.windows.login) appState.windows.login.hide();
      const result = await googleAuth.authenticate();
      if (result.success) {
        const initResult = await memberManager.initialize();
        if (initResult.success) {
          if (appState.windows.login) appState.windows.login.close();
          store.set('scopeVersion', 3);
          startApp();
          return { success: true };
        } else if (initResult.error === 'not_registered') {
          if (appState.windows.login) appState.windows.login.close();
          createNotRegisteredWindow(initResult.email);
          return { success: false, error: 'not_registered' };
        }
      }
      if (appState.windows.login) appState.windows.login.show();
      return result;
    } catch (error) {
      if (appState.windows.login) appState.windows.login.show();
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
    return await googleAuth.getUserEmail();
  });

  ipcMain.handle('is-logged-in', async () => {
    return await googleAuth.isLoggedIn();
  });

  ipcMain.handle('get-member-info', async () => {
    const email = await googleAuth.getUserEmail();
    if (!email) return null;
    return await sheetsApi.getMemberByEmail(email);
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
      return { departments: allDepartments, role: member.role, userDepartments: member.departments };
    } else if (member.role === '管理者') {
      const editableDepts = allDepartments.filter(d => member.departments.includes(d.name));
      return { departments: editableDepts, role: member.role, userDepartments: member.departments };
    }
    return { departments: [], role: member.role, userDepartments: member.departments };
  });

  ipcMain.handle('get-viewable-departments', async () => {
    try {
      const member = memberManager.getCurrentMember();
      if (!member || (member.role !== '最高管理者' && member.role !== '管理者')) {
        return { departments: [], role: member?.role };
      }
      const allDepartments = await sheetsApi.getDepartmentSettings();
      const otherDepartments = allDepartments.filter(d => !member.departments.includes(d.name));
      return { departments: otherDepartments, role: member.role, userDepartments: member.departments };
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
            ? (Array.isArray(folder.snippets.snippet) ? folder.snippets.snippet : [folder.snippets.snippet])
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

};