const { google } = require('googleapis');
const googleAuth = require('./google-auth');

async function getSheets() {
  const client = await googleAuth.getAuthenticatedClient();
  if (!client) return null;
  return google.sheets({ version: 'v4', auth: client });
}

async function getMemberList() {
  const sheets = await getSheets();
  if (!sheets) return null;

  const response = await sheets.spreadsheets.values.get({
    spreadsheetId: process.env.SPREADSHEET_ID,
    range: 'メンバーリスト!A:D'
  });

  const rows = response.data.values;
  if (!rows || rows.length < 2) return [];

  const headers = rows[0];
  const members = rows.slice(1)
  .filter(row => row[1])  // 空行スキップ（メールアドレスがない行）
  .map(row => ({
    name: row[0] || '',
    email: row[1] || '',
    departments: row[2] ? row[2].split(',').map(d => d.trim()) : [],
    role: row[3] || '一般'
  }));

  return members;
}

async function getDepartmentSettings() {
  const sheets = await getSheets();
  if (!sheets) return null;

  const response = await sheets.spreadsheets.values.get({
    spreadsheetId: process.env.SPREADSHEET_ID,
    range: '部署設定!A:B'
  });

  const rows = response.data.values;
  if (!rows || rows.length < 2) return [];

  const departments = rows.slice(1).map(row => ({
    name: row[0] || '',
    xmlFileId: row[1] || ''
  }));

  return departments;
}

async function getMemberByEmail(email) {
  const members = await getMemberList();
  if (!members) return null;
  return members.find(m => m.email.toLowerCase() === email.toLowerCase());
}

module.exports = {
  getMemberList,
  getDepartmentSettings,
  getMemberByEmail
};