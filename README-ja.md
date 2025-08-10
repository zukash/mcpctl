# mcpctl - MCP設定コントローラー

**[English README is here](./README.md)**

Claude CodeやGitHub Copilotなど、異なるAIクライアント間でMCP（Model Context Protocol）サーバー設定を管理するためのシンプルで強力なツールです。

## 特徴

- **一元管理**: 単一のJSON設定ファイルからMCPサーバーを管理
- **複数ターゲット**: 異なるAIクライアントの設定ファイルに同時に適用
- **2つの動作モード**:
  - **置換モード**（デフォルト）: 既存のサーバー設定を完全に置き換え
  - **マージモード**: 既存サーバーを保持しつつ新しいサーバーを追加
- **環境変数サポート**: 環境変数置換による機密データの安全な管理
- **変更プレビュー**: 適用前にdiffコマンドで変更内容を確認

## クイックスタート

### インストール

1. **依存関係をインストール**:
   ```bash
   brew install jq gettext
   ```

2. **mcpctlをダウンロード**:
   ```bash
   curl -O https://raw.githubusercontent.com/zukash/mcpctl/main/mcpctl
   chmod +x mcpctl
   
   # 例: /usr/local/binにインストール
   mv mcpctl /usr/local/bin/
   ```

### 基本的な使用方法

1. **設定ファイルを作成**（例: `mcp.json`）:
   ```json
   {
     "targets": [
       {
         "name": "claude-code",
         "path": "~/.claude.json",
         "key": "mcpServers"
       }
     ],
     "mcpServers": {
       "filesystem": {
         "command": "npx",
         "args": ["-y", "@modelcontextprotocol/server-filesystem", "/workspace"]
       },
       "github": {
         "command": "npx",
         "args": ["-y", "@modelcontextprotocol/server-github"],
         "env": {
           "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
         }
       }
     }
   }
   ```

2. **設定を適用**:
   ```bash
   # 既存サーバーを置き換え（デフォルト）
   ./mcpctl apply -f mcp.json
   
   # 既存サーバーとマージ
   ./mcpctl apply -f mcp.json --merge
   
   # まず変更内容をプレビュー
   ./mcpctl diff -f mcp.json --merge
   ```

## コマンド

### apply
設定をターゲットファイルに適用します。

```bash
mcpctl apply -f <設定ファイル> [-e <環境変数ファイル>] [--merge]
```

**オプション:**
- `-f <ファイル>`: 設定ファイル（必須）
- `-e <ファイル>`: 環境変数ファイル（オプション）
- `--merge`: 置換ではなく既存設定とマージ

**例:**
```bash
# 置換モード（既存サーバーを削除）
mcpctl apply -f team-config.json

# マージモード（既存サーバーを保持）
mcpctl apply -f additional-servers.json --merge

# 環境変数ファイルと併用
mcpctl apply -f mcp.json -e .env --merge
```

### diff
設定とターゲットファイルの差分を表示します。

```bash
mcpctl diff -f <設定ファイル> [-e <環境変数ファイル>] [--merge]
```

**例:**
```bash
# 置換操作のプレビュー
mcpctl diff -f mcp.json

# マージ操作のプレビュー
mcpctl diff -f mcp.json --merge
```

## 設定ファイル形式

### 基本構造
```json
{
  "targets": [
    {
      "name": "表示名",
      "path": "/ターゲット/ファイル/パス.json",
      "key": "mcpServers"
    }
  ],
  "mcpServers": {
    "サーバー名": {
      "command": "実行コマンド",
      "args": ["引数1", "引数2"],
      "env": {
        "変数名": "値"
      }
    }
  }
}
```

### ターゲット設定
- **name**: ターゲットの表示名（出力メッセージで使用）
- **path**: 更新するファイルパス（チルダ `~` 展開をサポート）
- **key**: ターゲットファイル内で更新するJSONキー（デフォルト: "mcpServers"）

### サポート対象クライアント

| クライアント | 設定パス | キー |
|-------------|---------|------|
| Claude Code | `~/.claude.json` | `mcpServers` |
| GitHub Copilot | `~/Library/Application Support/Code/User/mcp.json` | `servers` |
| カスタム | 任意のJSONファイル | 任意のキー |

## 環境変数

APIトークンなどの機密データには環境変数を使用:

1. **`.env`ファイルを作成**:
   ```bash
   GITHUB_TOKEN=ghp_your_token_here
   WORKSPACE_PATH=/Users/username/projects
   ```

2. **設定ファイルで参照**:
   ```json
   {
     "mcpServers": {
       "github": {
         "env": {
           "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
         }
       },
       "filesystem": {
         "args": ["-y", "@modelcontextprotocol/server-filesystem", "${WORKSPACE_PATH}"]
       }
     }
   }
   ```

3. **環境変数ファイルと一緒に適用**:
   ```bash
   mcpctl apply -f mcp.json -e .env
   ```

## 動作モード

### 置換モード（デフォルト）
ターゲット設定セクションを新しいサーバーで完全に置き換えます。

**適用前:**
```json
{
  "mcpServers": {
    "old-server": { "command": "old-cmd" }
  }
}
```

**`new-server`を含む設定を適用後:**
```json
{
  "mcpServers": {
    "new-server": { "command": "new-cmd" }
  }
}
```

### マージモード
既存サーバーを保持し、新しいサーバーを追加します。重複するサーバー名は上書きされます。

**適用前:**
```json
{
  "mcpServers": {
    "old-server": { "command": "old-cmd" }
  }
}
```

**`new-server`を含む設定を`--merge`で適用後:**
```json
{
  "mcpServers": {
    "old-server": { "command": "old-cmd" },
    "new-server": { "command": "new-cmd" }
  }
}
```

## 使用例

### チーム設定管理
```bash
# ベースとなるチーム設定
mcpctl apply -f team-base.json

# 個人開発者の追加設定
mcpctl apply -f personal-servers.json --merge

# 個人設定が何を追加するかプレビュー
mcpctl diff -f personal-servers.json --merge
```

### 複数クライアント設定
```json
{
  "targets": [
    {
      "name": "claude-code",
      "path": "~/.claude.json",
      "key": "mcpServers"
    },
    {
      "name": "github-copilot",
      "path": "~/Library/Application Support/Code/User/mcp.json",
      "key": "servers"
    }
  ],
  "mcpServers": {
    "shared-filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "${PROJECT_ROOT}"]
    }
  }
}
```

