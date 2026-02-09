const SettingsKeys = {
  USER_NAME: 'userName',
  HISTORY_MAX_COUNT: 'historyMaxCount',
  THEME: 'theme',
  HOTKEY_MAIN: 'customHotkeyMain',
  HOTKEY_SNIPPET: 'customHotkeySnippet',
  HOTKEY_HISTORY: 'customHotkeyHistory',
  WINDOW_POSITION_MODE: 'windowPositionMode',
  HIDDEN_FOLDERS: 'hiddenFolders',
  WELCOME_COMPLETED: 'welcomeCompleted',
  LAST_SYNC: 'lastSync',
  MASTER_SNIPPETS: 'masterSnippets',
  MASTER_FOLDERS: 'masterFolders',
  CLIPBOARD_HISTORY: 'clipboardHistory',
  PINNED_ITEMS: 'pinnedItems',
  MASTER_SNIPPET_URL: 'masterSnippetUrl',
  INITIAL_SNIPPETS_CREATED: 'initialSnippetsCreated',
  PERSONAL_DATA_MIGRATED: 'personalDataMigrated',
  LAST_AUTO_UPDATE_CHECK: 'lastAutoUpdateCheck',
  CLIPBOARD_WINDOW_POSITION: 'clipboardWindowPosition',
  SNIPPET_WINDOW_POSITION: 'snippetWindowPosition',
  HISTORY_WINDOW_POSITION: 'historyWindowPosition'
};

const DefaultSettings = {
  [SettingsKeys.USER_NAME]: '',
  [SettingsKeys.HISTORY_MAX_COUNT]: 100,
  [SettingsKeys.THEME]: 'silver',
  [SettingsKeys.HOTKEY_MAIN]: 'Ctrl+Alt+C',
  [SettingsKeys.HOTKEY_SNIPPET]: 'Ctrl+Alt+V',
  [SettingsKeys.HOTKEY_HISTORY]: 'Ctrl+Alt+X',
  [SettingsKeys.WINDOW_POSITION_MODE]: 'cursor',
  [SettingsKeys.HIDDEN_FOLDERS]: [],
  [SettingsKeys.WELCOME_COMPLETED]: false
};

module.exports = { SettingsKeys, DefaultSettings };