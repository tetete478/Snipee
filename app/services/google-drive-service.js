const { google } = require('googleapis');
const googleAuth = require('./google-auth-service')

async function getDrive() {
  const client = await googleAuth.getAuthenticatedClient();
  if (!client) return null;
  return google.drive({ version: 'v3', auth: client });
}

async function getFileContent(fileId) {
  const drive = await getDrive();
  if (!drive) return null;

  try {
    const response = await drive.files.get({
      fileId: fileId,
      alt: 'media',
      supportsAllDrives: true
    }, {
      responseType: 'text'
    });
    return typeof response.data === 'string' ? response.data : JSON.stringify(response.data);
  } catch (error) {
    console.error('Drive API error:', error.message);
    return null;
  }
}

async function uploadFile(fileId, content, mimeType = 'application/xml') {
  const drive = await getDrive();
  if (!drive) return null;

  try {
    const response = await drive.files.update({
      fileId: fileId,
      media: {
        mimeType: mimeType,
        body: content
      },
      supportsAllDrives: true
    });
    return response.data;
  } catch (error) {
    console.error('Drive upload error:', error.message);
    return null;
  }
}

async function createFile(name, content, folderId = null, mimeType = 'application/xml') {
  const drive = await getDrive();
  if (!drive) return null;

  try {
    const fileMetadata = {
      name: name,
      mimeType: mimeType
    };
    
    if (folderId) {
      fileMetadata.parents = [folderId];
    }

    const response = await drive.files.create({
      resource: fileMetadata,
      media: {
        mimeType: mimeType,
        body: content
      },
      fields: 'id, name',
      supportsAllDrives: true
    });
    return response.data;
  } catch (error) {
    console.error('Drive create error:', error.message);
    return null;
  }
}

// フォルダを検索または作成
async function findOrCreateFolder(name) {
  const drive = await getDrive();
  if (!drive) return null;

  try {
    const res = await drive.files.list({
      q: `name='${name}' and mimeType='application/vnd.google-apps.folder' and trashed=false`,
      fields: 'files(id, name)',
      spaces: 'drive'
    });

    if (res.data.files.length > 0) {
      return res.data.files[0].id;
    }

    const folder = await drive.files.create({
      resource: { name, mimeType: 'application/vnd.google-apps.folder' },
      fields: 'id'
    });
    return folder.data.id;
  } catch (error) {
    console.error('findOrCreateFolder error:', error.message);
    return null;
  }
}

// フォルダ内のファイルを名前で検索
async function findFile(name, folderId) {
  const drive = await getDrive();
  if (!drive) return null;

  try {
    const q = folderId
      ? `name='${name}' and '${folderId}' in parents and trashed=false`
      : `name='${name}' and trashed=false`;

    const res = await drive.files.list({ q, fields: 'files(id, name, modifiedTime)' });
    return res.data.files.length > 0 ? res.data.files[0] : null;
  } catch (error) {
    console.error('findFile error:', error.message);
    return null;
  }
}

// JSONファイルをアップロード（新規 or 上書き）
async function uploadJsonFile(fileId, folderId, fileName, data) {
  const drive = await getDrive();
  if (!drive) return null;

  const content = JSON.stringify(data, null, 2);
  const { Readable } = require('stream');

  try {
    if (fileId) {
      const res = await drive.files.update({
        fileId,
        media: { mimeType: 'application/json', body: Readable.from([content]) }
      });
      return res.data;
    } else {
      const res = await drive.files.create({
        resource: { name: fileName, parents: [folderId], mimeType: 'application/json' },
        media: { mimeType: 'application/json', body: Readable.from([content]) },
        fields: 'id'
      });
      return res.data;
    }
  } catch (error) {
    console.error('uploadJsonFile error:', error.message);
    return null;
  }
}

// JSONファイルをダウンロード
async function downloadJsonFile(fileId) {
  const drive = await getDrive();
  if (!drive) return null;

  try {
    const res = await drive.files.get(
      { fileId, alt: 'media' },
      { responseType: 'text' }
    );
    return typeof res.data === 'string' ? JSON.parse(res.data) : res.data;
  } catch (error) {
    console.error('downloadJsonFile error:', error.message);
    return null;
  }
}

module.exports = {
  getFileContent,
  uploadFile,
  createFile,
  findOrCreateFolder,
  findFile,
  uploadJsonFile,
  downloadJsonFile
};