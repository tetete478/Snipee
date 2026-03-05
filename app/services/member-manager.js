const googleAuth = require('./google-auth-service');
const sheetsApi = require('./google-sheets-service');
const driveApi = require('./google-drive-service');

let cachedMember = null;
let cachedDepartments = null;

async function initialize() {
  const email = await googleAuth.getUserEmail();
  if (!email) return { success: false, error: 'not_logged_in' };

  const member = await sheetsApi.getMemberByEmail(email);
  if (!member) return { success: false, error: 'not_registered', email };

  cachedMember = member;
  cachedDepartments = await sheetsApi.getDepartmentSettings();

  return { success: true, member, departments: cachedDepartments };
}

function getCurrentMember() {
  return cachedMember;
}

function getDepartments() {
  return cachedDepartments;
}

function isAdmin() {
  if (!cachedMember) return false;
  return cachedMember.role === '管理者' || cachedMember.role === '最高管理者';
}

function isSuperAdmin() {
  if (!cachedMember) return false;
  return cachedMember.role === '最高管理者';
}

function canEditDepartment(departmentName) {
  if (!cachedMember) return false;
  if (isSuperAdmin()) return true;
  if (cachedMember.role === '管理者') {
    return cachedMember.departments.includes(departmentName);
  }
  return false;
}

async function getDepartmentXml(departmentName) {
  if (!cachedDepartments) return null;
  
  const dept = cachedDepartments.find(d => d.name === departmentName);
  if (!dept || !dept.xmlFileId) return null;

  return await driveApi.getFileContent(dept.xmlFileId);
}

async function getAllAccessibleXml() {
  if (!cachedMember || !cachedDepartments) return [];

  const results = [];
  for (const deptName of cachedMember.departments) {
    const xml = await getDepartmentXml(deptName);
    if (xml) {
      results.push({ department: deptName, xml });
    }
  }
  return results;
}

function clearCache() {
  cachedMember = null;
  cachedDepartments = null;
}

module.exports = {
  initialize,
  getCurrentMember,
  getDepartments,
  isAdmin,
  isSuperAdmin,
  canEditDepartment,
  getDepartmentXml,
  getAllAccessibleXml,
  clearCache
};