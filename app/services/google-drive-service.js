const { google } = require('googleapis');
const googleAuth = require('./google-auth');

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
    });
    return response.data;
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

module.exports = {
  getFileContent,
  uploadFile,
  createFile
};