# Syncthing チートシート

## 起動方法

### Mac
```bash
# 起動
brew services start syncthing

# 停止
brew services stop syncthing

# 再起動
brew services restart syncthing
```

### Windows
```powershell
# スタートメニューから「Syncthing」で検索して起動
# またはタスクトレイに常駐している場合はそこから起動

# コマンドで起動する場合（PowerShell）
Start-Process "C:\Users\<ユーザー名>\AppData\Local\Syncthing\syncthing.exe"
```

---

## 管理画面を開く

どちらのOSも同じURL

```
http://localhost:8384
```

ブラウザで開くだけでOK。

---

## フォルダ同期の設定手順

1. Mac側の管理画面（localhost:8384）を開く
2. **「フォルダを追加」** をクリック
3. 同期したいフォルダのパスを入力（例：`~/Desktop/Snipee/electron`）
4. **デバイスタブ** でWindows側のデバイスにチェック → 保存
5. Windows側の管理画面を開くと「共有の招待」が届くので承認
6. Windows側で保存先パスを指定して完了

---

## デバイスの追加（初回のみ）

### Mac側で行う
1. 管理画面 → 右下の **「デバイスを追加」**
2. WindowsのデバイスIDを入力
   - WindowsのデバイスIDは：管理画面右上 → **「アクション」→「IDを表示」**

### デバイスIDのコピー方法
```
管理画面 → 右上「アクション」→「IDを表示」→ QRコードまたはテキストをコピー
```

---

## 同期状態の確認

| 表示 | 意味 |
|------|------|
| 最新 | 同期完了 |
| 同期中 | ファイル転送中 |
| 未接続 | 相手デバイスがオフライン |
| エラー | パーミッションなど要確認 |

---

## よく使うトラブル対処

**同期されない場合**
- 両方の管理画面を開いて「未接続」になっていないか確認
- ファイアウォールで22000番ポートが開いているか確認（Windows）

**Windowsのファイアウォール設定**
```
Windowsセキュリティ → ファイアウォール → アプリを許可 → Syncthingを追加
```

**ログ確認**
```
管理画面 → 右上「アクション」→「ログを表示」
```