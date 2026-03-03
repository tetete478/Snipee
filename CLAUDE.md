# CLAUDE.md — Snipee

## Project Overview

Snipee is a multi-platform clipboard history and snippet management tool for team collaboration. It supports synchronized master snippets shared via Google Drive and personal snippets stored locally.

- **Windows**: Electron (v27) — `app/` directory
- **macOS**: Swift/SwiftUI — `SnipeeMac/`
- **iOS**: Swift/SwiftUI + custom keyboard — `SnipeeTap/`

Current version: **1.10.8**

## Repository Structure

```
Snipee/
├── app/                          # Windows Electron app (primary)
│   ├── main.js                   # Main process (~1,486 lines)
│   ├── app-state.js              # Shared application state singleton
│   ├── models/                   # Data models (6 files)
│   │   ├── snippet.js            # Snippet & SnippetFolder classes
│   │   ├── history-item.js       # HistoryItem model
│   │   ├── app-settings.js       # SettingsKeys & DefaultSettings
│   │   ├── department.js         # Department model
│   │   ├── member.js             # Member + MemberRole enum
│   │   └── user-status.js        # UserStatus model
│   ├── services/                 # Business logic (11 files)
│   │   ├── google-auth-service.js    # OAuth 2.0 PKCE authentication
│   │   ├── google-drive-service.js   # Drive API (XML sync)
│   │   ├── google-sheets-service.js  # Sheets API (members, status)
│   │   ├── member-manager.js         # Member caching & auth
│   │   ├── variable-service.js       # Template variable substitution
│   │   ├── storage-service.js        # electron-store wrapper
│   │   ├── paste-service.js          # Windows clipboard paste (koffi)
│   │   ├── sync-service.js           # Master snippet sync
│   │   ├── user-report-service.js    # Status reporting to Sheets
│   │   ├── snippet-import-export-service.js
│   │   └── snippet-promotion-service.js
│   ├── views/                    # HTML renderer pages (7 files)
│   │   ├── index.html            # Main popup (history + snippets)
│   │   ├── snippets.html         # Snippets-only popup
│   │   ├── history.html          # History-only popup
│   │   ├── snippet-editor.html   # Snippet editor (largest view)
│   │   ├── settings.html         # Settings window
│   │   ├── welcome.html          # 5-step onboarding
│   │   └── login.html            # OAuth login window
│   ├── utilities/                # Helpers (4 files)
│   │   ├── constants.js          # UI, Clipboard, Sync constants
│   │   ├── utils.js              # KeyboardNavigator + utilities
│   │   ├── theme.js              # Theme switching logic
│   │   └── drag-drop.js          # DragDropManager class
│   └── theme/                    # CSS theming
│       ├── variables.css         # 9 color themes via CSS variables
│       └── common.css            # Base component styles
├── SnipeeMac/                    # macOS Swift app (~45 Swift files)
├── SnipeeTap/                    # iOS app + keyboard extension
├── build/                        # Build resources (icons, installer)
├── docs/                         # Release notes
├── .github/workflows/
│   ├── build.yml                 # Windows CI/CD (tag: v*)
│   └── build-mac.yml             # macOS CI/CD (tag: mac-v*)
├── HANDOVER-Electron.md          # Electron architecture & refactoring plan
├── HANDOVER-Mac.md               # macOS Swift architecture
└── HANDOVER-iOS.md               # iOS architecture
```

## Development Commands

```bash
# Windows Electron
npm run start          # Run app
npm run dev            # Run with --debug flag
npm run build          # Build Windows NSIS installer
npm run publish        # Build and publish to GitHub Releases

# Release (triggers CI/CD)
git tag win-v<version> && git push origin win-v<version>   # Windows
git tag mac-v<version> && git push origin mac-v<version>   # macOS
```

## Key Architecture Details

### Electron (Windows)

- **Entry point**: `app/main.js` — manages windows, IPC, clipboard monitoring, hotkeys
- **State**: `app-state.js` singleton for runtime state; `electron-store` for persistence
- **IPC pattern**: `ipcRenderer.invoke()` / `ipcMain.handle()` for async request-response
- **Window management**: Each view is a separate `BrowserWindow`; popups auto-hide on blur
- **Clipboard monitoring**: 500ms polling interval via `setInterval`
- **Auto-paste**: Uses `koffi` to call Windows `user32.dll` (keybd_event for Ctrl+V simulation)
- **Authentication**: Google OAuth 2.0 PKCE via local HTTP server on port 8085
- **Token storage**: System keytar (Windows Credential Manager)
- **Snippet sync**: Fetches XML from Google Drive, parses with xml2js (Clipy-compatible format)
- **Styling**: Vanilla CSS with CSS custom properties; 9 built-in color themes

### macOS (Swift)

- **Framework**: Swift/SwiftUI + AppKit hybrid
- **Updates**: Sparkle framework for auto-updates
- **Cloud sync**: Phase 3 complete (PersonalSyncService.swift)
- **Hotkeys**: Cmd+Ctrl+C/V/X

### iOS (Swift)

- **Custom keyboard extension**: `SnipeeiOSKeyboard` for direct snippet insertion
- **Cloud sync**: Phase 4 pending (awaiting Mac Phase 3 completion)
- **Status**: App Store submission preparation

## Environment Variables

Required in `.env` (git-ignored):
```
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
SPREADSHEET_ID=...
```

These are set via GitHub Secrets in CI/CD workflows.

## Refactoring Status (Electron)

| Phase | Description | Status |
|-------|-------------|--------|
| Phase 0 | File renaming (Mac naming conventions) | Complete |
| Phase 1 | Model files (6 files) | Complete |
| Phase 2 | constants.js | Complete |
| Phase 3 | Service extraction (6 services) | Complete |
| Phase 4 Step 1 | appState consolidation + main.js reduction | Complete |
| Phase 4 Step 2 | IPC handler separation (8 files in `ipc/`) | Not started |
| Phase 5 | Final main.js cleanup (target: <500 lines) | Pending |

## Coding Conventions

### General
- **Language**: JavaScript (no TypeScript); Swift for macOS/iOS
- **Naming**: camelCase for variables/functions, PascalCase for classes/models
- **UI text**: Japanese (日本語) — all user-facing labels, settings keys, and variable names
- **Comments**: Japanese or English depending on context
- **No test suite** — no Jest, Mocha, or other test frameworks are configured
- **No linter config** — no ESLint/Prettier configured in the project

### Workflow Rules
- Do not rewrite entire files — use targeted edits (str_replace / diff approach)
- Propose changes first, then implement after confirmation
- Validate generated code before finalizing

### Critical Don'ts
1. **No multi-window IPC** — causes freezing; use inline display within a single HTML file
2. **No heavy sync on startup** — prioritize hotkey registration; sync must be async
3. **No single-modifier hotkeys** — use 2+ modifier keys to avoid conflicts (e.g. Ctrl+Alt+C)
4. **No secrets in repo** — CLIENT_SECRET goes in `.env` + `.gitignore`
5. **No Google Drive API without `supportsAllDrives=true`** — causes 404 on shared drives
6. **No big-bang refactoring** — use phased approach with validation at each step
7. **No direct clipboard history export** — use the `appState` singleton
8. **No Swift 6 Strict Concurrency** (iOS/Mac) — causes Codable struct errors; keep Swift 5 + Minimal

### IPC Handlers
- ~67 handlers currently live in `main.js`
- Planned separation into 8 files under `app/ipc/` (Phase 4 Step 2)
- Handler categories: clipboard, snippet, settings, window, auth, admin, update, sync

### Theme System
- 9 themes defined via CSS custom properties in `theme/variables.css`
- Themes: silver (default), pearl, blush, peach, cream, pistachio, aqua, periwinkle, wisteria
- Applied via `data-theme` attribute on root element

### Template Variables (variable-service.js)
16 Japanese-named template variables for snippet expansion:
`{名前}`, `{今日}`, `{明日}`, `{明後日}`, `{昨日}`, `{一昨日}`, `{時刻}`, `{曜日}`, `{年}`, `{月}`, `{日}`, `{来週の月曜}`, `{今週の月曜}`, `{今週の金曜}`, `{来月1日}`, `{カーソル}`

## Key Dependencies (Electron)

| Package | Purpose |
|---------|---------|
| `electron` ^27 | Desktop app framework |
| `electron-builder` | Build & packaging (NSIS) |
| `electron-store` | Persistent JSON storage |
| `electron-updater` | Auto-update via GitHub Releases |
| `googleapis` ^170 | Google Sheets & Drive APIs |
| `keytar` ^7.9 | Secure credential storage (OS keychain) |
| `koffi` ^2.14 | Native Windows API bindings (user32.dll) |
| `axios` | HTTP client |
| `xml2js` | XML parsing (Clipy format) |
| `dotenv` | Environment variable loading |

### Native Module Notes
- `googleapis`, `gaxios`, `google-auth-library` must be unpacked from ASAR (`asarUnpack` in package.json)
- `keytar` requires native rebuild for Electron (`@electron/rebuild` in CI)
- `koffi` is Windows-only (paste automation)

## CI/CD

- **Windows**: `.github/workflows/build.yml` — triggered by `v*` tags; builds NSIS installer, publishes to GitHub Releases
- **macOS**: `.github/workflows/build-mac.yml` — triggered by `mac-v*` tags; builds, signs, notarizes, creates DMG, updates Sparkle appcast
- **Node version**: v20
- **Required GitHub Secrets**: `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `SPREADSHEET_ID`, `GH_TOKEN` (Windows); additional Apple signing secrets for macOS
