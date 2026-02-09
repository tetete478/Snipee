const Constants = {
  UI: {
    popupWidth: 230,
    popupHeight: 600
  },

  Clipboard: {
    monitorInterval: 500
  },

  Sync: {
    autoSyncInterval: 2 * 60 * 60 * 1000
  },

  Update: {
    checkInterval: 24 * 60 * 60 * 1000,
    startupDelay: 60 * 1000
  },

  Windows: {
    VK_CONTROL: 0x11,
    VK_V: 0x56,
    VK_MENU: 0x12,
    KEYEVENTF_KEYUP: 0x0002
  },

  Auth: {
    scopeVersion: 3
  },

  Admin: {
    masterEditPassword: '1108'
  }
};

module.exports = { Constants };