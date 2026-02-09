const memberManager = require('./member-manager');
const sheetsApi = require('./google-sheets-service');
const driveApi = require('./google-drive-service');
const syncService = require('./sync-service');

async function uploadDepartmentXml(departmentName, xmlContent) {
  try {
    const member = memberManager.getCurrentMember();
    if (!member) return { success: false, error: '未ログイン' };

    if (member.role === '一般') {
      return { success: false, error: '権限がありません' };
    }

    if (member.role === '管理者' && !member.departments.includes(departmentName)) {
      return { success: false, error: 'この部署の編集権限がありません' };
    }

    const departments = await sheetsApi.getDepartmentSettings();
    const dept = departments.find(d => d.name === departmentName);

    if (!dept || !dept.xmlFileId) {
      return { success: false, error: '部署のXMLファイルが設定されていません' };
    }

    const result = await driveApi.uploadFile(dept.xmlFileId, xmlContent);

    if (result.success) {
      await syncService.loadDepartmentSnippets();
      return { success: true };
    }

    return { success: false, error: result.error || 'アップロード失敗' };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

module.exports = { uploadDepartmentXml };