# Vertex AI (Gemini) セットアップガイド

Google Cloud の Vertex AI を使うツールのための環境構築手順です。

## 対象ツール

以下のツールを使う場合、このセットアップが必要です。

| ツール | シリーズ | 言語 | 説明 |
|-------|--------|------|------|
| gem-cli | cli-series | Go | Gemini チャットCLI |
| gem-query | util-series | Go | 自然言語DB分析 |
| gem-search | util-series | Go | AI Web検索 |
| gem-image | util-series | Go | AI画像生成 |
| gem-rag | util-series | Python | RAG検索 |
| mail-analyzer | util-series | Go | 不審メール分析 |
| ai-ir2 | cybersecurity-series | Python | インシデント対応分析 |
| ir-tracker | cybersecurity-series | Python | ライブIR追跡 |
| ioc-collector | cybersecurity-series | Python | IoC収集 |
| mail-triage | cybersecurity-series | Python | メールトリアージ |
| news-collector | cybersecurity-series | Python | ニュース収集 |
| product-research | cybersecurity-series | Python | 製品リスク調査 |
| meeting-note | lab-series | Python | 議事録構造化 |
| magi-system2 | lab-series | Python | マルチAI議論 |
| virtual-reviewer | lab-series | Python | AIセキュリティレビュー |

## 必要なもの

- Windows 10/11 または macOS
- インターネット接続
- Google アカウント（組織のアカウント）
- 共有GCPプロジェクトへのアクセス権（管理者から付与されます）
- ディスク容量: 約 200MB（Google Cloud CLI）

## 手順

### ステップ 1: Google Cloud CLI のインストール

Google Cloud CLI（gcloud コマンド）をインストールします。

**Windows（PowerShell）:**

```powershell
winget install Google.CloudSDK
```

> インストール後、**PowerShell を一度閉じて開き直してください**（PATHを反映するため）。

**macOS（Terminal）:**

```bash
brew install --cask google-cloud-sdk
```

**インストール確認:**

```
gcloud version
```

以下のような出力が表示されれば成功です:

```
Google Cloud SDK 5xx.x.x
...
```

### ステップ 2: Google Cloud の初期設定

Google Cloud CLI を初期化し、共有プロジェクトに接続します。

```
gcloud init
```

対話形式で以下を聞かれます:

1. **ログイン**: `Y` を入力 → ブラウザが開くので Google アカウントでログイン
2. **プロジェクト選択**: 共有プロジェクトの ID を選択（リストに表示されます）
   - 表示されない場合は、管理者にプロジェクトへのアクセス権を依頼してください

**期待される出力:**

```
Your Google Cloud SDK is configured and ready to use!
```

### ステップ 3: ADC（認証情報）の設定

ADC（Application Default Credentials = アプリケーション既定認証情報）を設定します。nlink-jp のツールはこの認証情報を使って Vertex AI にアクセスします。

```
gcloud auth application-default login
```

ブラウザが開くので、ステップ 2 と同じ Google アカウントでログインしてください。

**期待される出力:**

```
Credentials saved to file: [C:\Users\<ユーザー名>\AppData\Roaming\gcloud\application_default_credentials.json]
```

### ステップ 4: Quota プロジェクトの設定

API の利用料が正しいプロジェクトに請求されるよう、quota プロジェクトを設定します。

```
gcloud auth application-default set-quota-project your-shared-project
```

> `your-shared-project` は管理者から伝えられた共有プロジェクトIDに置き換えてください。

**期待される出力:**

```
Credentials saved to file: [...]

Quota project "your-shared-project" was added to ADC...
```

### ステップ 5: config.toml の作成（ツールごと）

多くのツールは `config.toml` ファイルで GCP プロジェクトとリージョンを指定します。各ツールの README に従って作成してください。

共通的なパターンは以下の通りです:

**Windows の場合の保存先:** `%APPDATA%\<ツール名>\config.toml` または `%USERPROFILE%\.config\<ツール名>\config.toml`

**macOS の場合の保存先:** `~/.config/<ツール名>/config.toml`

**ファイル内容の例:**

```toml
[gcp]
project  = "your-shared-project"
location = "us-central1"

[model]
name = "gemini-2.5-flash"
```

> - `project`: 共有プロジェクトの ID
> - `location`: 通常は `us-central1` を使います
> - `name`: 使用するモデル名（ツールによって異なります。各ツールの README を参照）

各ツールのリポジトリには `config.example.toml` が含まれているので、それをコピーして編集するのが簡単です。

## 動作確認

セットアップが正しいか確認するには、以下のコマンドを実行します:

```
gcloud auth application-default print-access-token
```

長い文字列（トークン）が表示されれば、認証は正常です。エラーが出る場合はステップ 3 からやり直してください。

## 環境変数での設定（代替方法）

config.toml の代わりに、環境変数で設定することもできます。

**Windows（PowerShell）:**

```powershell
$env:GOOGLE_CLOUD_PROJECT = "your-shared-project"
$env:GOOGLE_CLOUD_LOCATION = "us-central1"
```

> この方法は一時的です。PowerShell を閉じると消えます。永続化するには「システム環境変数」に設定してください。

**macOS（Terminal）:**

```bash
export GOOGLE_CLOUD_PROJECT="your-shared-project"
export GOOGLE_CLOUD_LOCATION="us-central1"
```

## トラブルシューティング

### 「Permission denied」「403」エラー

- 共有プロジェクトへのアクセス権がない可能性があります。管理者に Vertex AI User ロールの付与を依頼してください。
- quota プロジェクトが未設定の場合もこのエラーが出ます。ステップ 4 を確認してください。

### 「Could not automatically determine credentials」

- ADC が設定されていません。ステップ 3 を実行してください。

### 「Quota exceeded」

- API の利用上限に達しています。しばらく待ってから再試行するか、管理者に quota 増量を依頼してください。

### 「Region not available」

- `location` を `us-central1` に変更してみてください。一部のモデルは特定のリージョンでのみ利用可能です。

### 「gcloud: command not found」(macOS) / 「gcloud は認識されていません」(Windows)

- Google Cloud CLI のインストール後に、ターミナル/PowerShell を再起動してください。
- Windows の場合: スタートメニューから「Google Cloud SDK Shell」を検索して起動する方法もあります。

## 次のステップ

セットアップが完了したら、使いたいツールの README に従ってツールをインストール・実行してください。

- Python 製ツールの場合: [Python + uv セットアップ](setup-python-uv.ja.md) も必要です
- Go 製ツールの場合: ビルド済みバイナリを使うか、[Go ビルド環境セットアップ](setup-go-build.ja.md) でビルドしてください
