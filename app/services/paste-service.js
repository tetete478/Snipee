const { Constants } = require('../utilities/constants');

let user32 = null;
let GetForegroundWindow = null;
let SetForegroundWindow = null;
let keybd_event = null;
let previousActiveApp = null;

if (process.platform === 'win32') {
  try {
    const koffi = require('koffi');
    user32 = koffi.load('user32.dll');
    GetForegroundWindow = user32.func('GetForegroundWindow', 'void*', []);
    SetForegroundWindow = user32.func('SetForegroundWindow', 'bool', ['void*']);
    keybd_event = user32.func('keybd_event', 'void', ['uint8', 'uint8', 'uint32', 'void*']);
  } catch (error) {
    // koffi読み込み失敗時は自動ペースト無効
  }
}

function captureActiveApp() {
  try {
    if (GetForegroundWindow) {
      previousActiveApp = GetForegroundWindow();
    }
  } catch (error) {
    // HWND取得失敗時はスキップ
  }
}

async function pasteToActiveApp() {
  if (process.platform !== 'win32' || !previousActiveApp) {
    return;
  }

  const { VK_CONTROL, VK_V, VK_MENU, KEYEVENTF_KEYUP } = Constants.Windows;

  keybd_event(VK_MENU, 0, 0, null);
  SetForegroundWindow(previousActiveApp);
  keybd_event(VK_MENU, 0, KEYEVENTF_KEYUP, null);

  await new Promise(resolve => setTimeout(resolve, 20));

  keybd_event(VK_CONTROL, 0, 0, null);
  keybd_event(VK_V, 0, 0, null);
  keybd_event(VK_V, 0, KEYEVENTF_KEYUP, null);
  keybd_event(VK_CONTROL, 0, KEYEVENTF_KEYUP, null);
}

module.exports = { captureActiveApp, pasteToActiveApp };