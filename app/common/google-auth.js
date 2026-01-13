const { google } = require('googleapis');
const keytar = require('keytar');
const { BrowserWindow } = require('electron');

const SERVICE_NAME = 'Snipee';
const ACCOUNT_NAME = 'google-oauth';

const SCOPES = [
  'https://www.googleapis.com/auth/spreadsheets.readonly',
  'https://www.googleapis.com/auth/drive.readonly',
  'https://www.googleapis.com/auth/drive.file',
  'https://www.googleapis.com/auth/userinfo.email'
];

let oauth2Client = null;

function getOAuth2Client() {
  if (!oauth2Client) {
    oauth2Client = new google.auth.OAuth2(
      process.env.GOOGLE_CLIENT_ID,
      process.env.GOOGLE_CLIENT_SECRET,
      'http://localhost:8085/callback'
    );
  }
  return oauth2Client;
}

async function saveTokens(tokens) {
  await keytar.setPassword(SERVICE_NAME, ACCOUNT_NAME, JSON.stringify(tokens));
}

async function getStoredTokens() {
  const tokens = await keytar.getPassword(SERVICE_NAME, ACCOUNT_NAME);
  return tokens ? JSON.parse(tokens) : null;
}

async function clearTokens() {
  await keytar.deletePassword(SERVICE_NAME, ACCOUNT_NAME);
}

async function authenticate() {
  return new Promise((resolve, reject) => {
    const client = getOAuth2Client();
    
    const authUrl = client.generateAuthUrl({
      access_type: 'offline',
      scope: SCOPES,
      prompt: 'consent'
    });

    const authWindow = new BrowserWindow({
      width: 500,
      height: 700,
      webPreferences: {
        nodeIntegration: false,
        contextIsolation: true
      }
    });

    const http = require('http');
    const server = http.createServer(async (req, res) => {
      if (req.url.startsWith('/callback')) {
        const url = new URL(req.url, 'http://localhost:8085');
        const code = url.searchParams.get('code');
        
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end('<html><body><script>window.close()</script></body></html>');
        
        server.close();
        authWindow.close();

        try {
          const { tokens } = await client.getToken(code);
          client.setCredentials(tokens);
          await saveTokens(tokens);
          resolve({ success: true, tokens });
        } catch (error) {
          reject(error);
        }
      }
    });

    server.listen(8085, () => {
      authWindow.loadURL(authUrl);
    });

    authWindow.on('closed', () => {
      server.close();
    });
  });
}

async function getAuthenticatedClient() {
  const client = getOAuth2Client();
  const tokens = await getStoredTokens();
  
  if (!tokens) {
    return null;
  }

  client.setCredentials(tokens);

  if (tokens.expiry_date && tokens.expiry_date < Date.now()) {
    try {
      const { credentials } = await client.refreshAccessToken();
      await saveTokens(credentials);
      client.setCredentials(credentials);
    } catch (error) {
      await clearTokens();
      return null;
    }
  }

  return client;
}

async function getUserEmail() {
  const client = await getAuthenticatedClient();
  if (!client) return null;

  const oauth2 = google.oauth2({ version: 'v2', auth: client });
  const { data } = await oauth2.userinfo.get();
  return data.email;
}

async function isLoggedIn() {
  const client = await getAuthenticatedClient();
  return client !== null;
}

async function logout() {
  await clearTokens();
}

module.exports = {
  authenticate,
  getAuthenticatedClient,
  getUserEmail,
  isLoggedIn,
  logout,
  getOAuth2Client
};