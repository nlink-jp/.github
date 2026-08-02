# Python + uv セットアップガイド

Python 製ツールを使うための環境構築手順です。Python のインストールと、パッケージマネージャ uv のセットアップを行います。

## 対象

`pyproject.toml` や `uv.lock` ファイルがあるプロジェクトすべてが対象です。主なツール:

| ツール | シリーズ | 説明 |
|-------|--------|------|
| gem-rag | util-series | RAG検索 |
| gem-transcribe | util-series | 音声文字起こし |
| pptx-to-markdown | util-series | pptx→Markdown変換 |
| news-collector | cybersecurity-series | ニュース収集 |
| slack-monitor | lab-series | Slackチャンネル要約 |
| agent-skeleton | lab-series | 自律エージェント |
| mcp-skeleton | lab-series | MCP学習用スケルトン |
| confl-cli | cli-series | Confluence CLIクライアント |

## 必要なもの

- Windows 10/11 または macOS
- インターネット接続
- ディスク空き容量: 約 500MB（Python + uv + パッケージキャッシュ）

## 手順

### ステップ 1: Python のインストール

**Windows:**

1. [python.org](https://www.python.org/downloads/) にアクセス
2. 最新の Python 3.12 以降をダウンロード
3. インストーラを実行
4. **重要: インストール画面の一番下にある「Add python.exe to PATH」にチェックを入れてください**
5. 「Install Now」をクリック

> PATH にチェックを入れ忘れた場合、PowerShell から `python` コマンドが使えません。その場合はインストーラを再実行し、「Modify」→「Add to PATH」を選択してください。

**macOS:**

```bash
brew install python@3.12
```

**インストール確認:**

PowerShell（Windows）または Terminal（macOS）を**新しく開いて**:

```
python --version
```

```
Python 3.12.x
```

> Windows で `python` が見つからない場合は `python3 --version` を試してください。

### ステップ 2: uv のインストール

uv は Python のパッケージマネージャです。pip より高速で、プロジェクトごとの依存関係を自動管理します。

**Windows（PowerShell）:**

```powershell
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

> 実行ポリシーの警告が出た場合は「はい」を選択してください。

**macOS（Terminal）:**

```bash
brew install uv
```

**インストール確認:**

PowerShell / Terminal を**新しく開いて**:

```
uv --version
```

```
uv 0.x.x
```

### ステップ 3: ツールの依存関係をインストール

使いたいツールのディレクトリに移動し、uv で依存関係をインストールします。

**Windows（PowerShell）:**

```powershell
cd C:\path\to\tool-directory
uv sync
```

**macOS（Terminal）:**

```bash
cd /path/to/tool-directory
uv sync
```

`uv sync` は `pyproject.toml` と `uv.lock` を読み取り、必要なパッケージをすべて自動でインストールします。

**期待される出力:**

```
Resolved XX packages in X.XXs
Installed XX packages in X.XXs
```

### ステップ 4: ツールの実行

uv でインストールしたツールは `uv run` で実行します。

```
uv run python main.py --help
```

または、ツールにスクリプトが定義されている場合:

```
uv run <ツール名> --help
```

具体的なコマンドは各ツールの README を参照してください。

## 動作確認

Python と uv が正しくセットアップされているか確認:

```
python --version
uv --version
```

両方ともバージョンが表示されれば OK です。

## トラブルシューティング

### 「python: command not found」(macOS) / 「python は認識されていません」(Windows)

- Python インストール時に「Add to PATH」をチェックし忘れた可能性があります
- Windows: インストーラを再実行 →「Modify」→ PATH を有効化
- PowerShell / Terminal を再起動してください

### 「uv: command not found」/ 「uv は認識されていません」

- uv インストール後に PowerShell / Terminal を再起動してください
- Windows の場合、PATH に `%USERPROFILE%\.local\bin` が追加されているか確認:
  ```powershell
  $env:PATH -split ";" | Select-String "\.local\\bin"
  ```

### 「uv sync」で「No Python found」

- uv がシステムの Python を見つけられていません
- `uv python install 3.12` を実行すると、uv が自動で Python をダウンロードします

### 「uv sync」でバージョンエラー

- ツールが要求する Python バージョンがインストール済みのものと異なる場合があります
- `uv python install 3.12` で必要なバージョンをインストールしてください

### Windows で文字化け

- PowerShell の文字コードを UTF-8 に設定:
  ```powershell
  [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
  ```

## 次のステップ

セットアップが完了したら、使いたいツールの README に従って実行してください。

- Vertex AI を使うツールの場合: [Vertex AI セットアップ](setup-vertex-ai.ja.md) も必要です
- ローカルLLM を使うツールの場合: [ローカルLLM セットアップ](setup-local-llm.ja.md) も必要です
