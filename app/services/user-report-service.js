const { app } = require('electron');
const googleAuth = require('./google-auth-service');
const sheetsApi = require('./google-sheets-service');
const { personalStore, store } = require('./storage-service');

async function report() {
  try {
    const email = await googleAuth.getUserEmail();
    if (!email) return;

    const version = app.getVersion();
    const personalSnippets = personalStore.get('snippets', []);
    const masterData = store.get('masterSnippets', { snippets: [] });
    const masterSnippets = masterData.snippets || [];
    const snippetCount = personalSnippets.length + masterSnippets.length;

    await sheetsApi.updateUserStatus(email, version, snippetCount);
  } catch (error) {
    // サイレント（Mac準拠）
  }
}

module.exports = { report };