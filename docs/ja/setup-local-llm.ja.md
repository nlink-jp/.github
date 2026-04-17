# ローカルLLM セットアップガイド

ローカル PC 上で AI モデル（LLM）を動かすツールのための環境構築手順です。クラウドへのデータ送信なしに、手元の PC だけで AI を利用できます。

## 対象ツール

以下のツールを使う場合、このセットアップが必要です。

| ツール | シリーズ | 言語 | 説明 |
|-------|--------|------|------|
| llm-cli | cli-series | Go | ローカルLLM チャットCLI |
| data-analyzer | util-series | Go | 大規模JSON分析 |
| mail-analyzer-local | util-series | Go | メール分析（ローカル版） |
| lite-rag | lite-series | Go | ローカルRAG検索 |
| lite-switch | lite-series | Go | 自然言語分類器 |
| magi-system | lab-series | Python | マルチペルソナ議論 |
| sai | lab-series | Python | Slack AIボット |
| slack-monitor | lab-series | Python | Slackチャンネル要約 |
| agent-skeleton | lab-series | Python | 自律エージェント |
| cti-primer | cybersecurity-series | Python | CTI PIR生成 |

## 必要なもの

- Windows 10/11 または macOS
- **GPU（強く推奨）**: NVIDIA GPU（VRAM 8GB以上）または Apple Silicon Mac（M1以降）
  - GPU なしでも動作しますが、非常に遅くなります
- ディスク空き容量: 最低 10GB（モデルサイズにより 20-50GB 推奨）
- RAM: 16GB以上推奨

### GPU 要件の目安

| モデルサイズ | 必要VRAM | 用途 |
|------------|---------|------|
| 7-8B パラメータ | 6-8 GB | 基本的な対話、分類 |
| 14-15B パラメータ | 10-12 GB | より高品質な応答 |
| 30B パラメータ | 20-24 GB | 高精度な分析 |

> Apple Silicon Mac (M1/M2/M3) は統合メモリをVRAMとして使えるため、RAM 16GB のモデルなら 14B クラスまで動作します。

## 手順

### ステップ 1: LM Studio のインストール

LM Studio は、ローカル PC でAIモデルを簡単に動かせるアプリケーションです。

1. [LM Studio 公式サイト](https://lmstudio.ai/) にアクセス
2. お使いの OS に合わせたインストーラをダウンロード
3. インストーラを実行

> Windows の場合: ダウンロードした `.exe` ファイルを実行し、画面の指示に従ってインストールしてください。

### ステップ 2: AIモデルのダウンロード

LM Studio を起動し、モデルをダウンロードします。

1. LM Studio を起動
2. 画面上部の検索バーに、ダウンロードしたいモデル名を入力
3. モデルを選択し、「Download」をクリック

**推奨モデル:**

| モデル名 | サイズ | VRAM目安 | 用途 |
|---------|-------|---------|------|
| `qwen3-8b` | ~5 GB | 8 GB | 汎用（推奨スタート） |
| `qwen3-14b` | ~9 GB | 12 GB | より高品質 |
| `qwen3-30b-a3b` | ~18 GB | 24 GB | 高精度分析 |

> 初めての場合は **qwen3-8b** からお試しください。検索バーに `qwen3-8b` と入力すると候補が表示されます。

### ステップ 3: API サーバーの起動

nlink-jp のツールは LM Studio の API サーバー経由でモデルにアクセスします。

1. LM Studio で、ダウンロードしたモデルをロード（画面上部のモデル選択で選ぶ）
2. 左側メニューの **Developer** タブ（`<>` アイコン）をクリック
3. **Server Port** が `1234` であることを確認
4. **Start Server** をクリック

**サーバーが起動すると:**

- 画面に `Server started on port 1234` のようなメッセージが表示されます
- ツールからは `http://localhost:1234/v1` でアクセスできるようになります

> API サーバーは LM Studio を閉じると停止します。ツールを使う間は LM Studio を起動したままにしてください。

### ステップ 4: 動作確認

API サーバーが正常に動作しているか確認します。

**Windows（PowerShell）:**

```powershell
Invoke-RestMethod -Uri "http://localhost:1234/v1/models" | ConvertTo-Json
```

**macOS（Terminal）:**

```bash
curl http://localhost:1234/v1/models
```

ロード中のモデル名が JSON で返ってくれば成功です。

```json
{
  "data": [
    {
      "id": "qwen3-8b",
      ...
    }
  ]
}
```

## ツールの設定

多くのツールはデフォルトで `http://localhost:1234/v1` に接続します。特別な設定は不要ですが、モデル名の指定が必要な場合があります。

**環境変数の例（llm-cli の場合）:**

**Windows（PowerShell）:**

```powershell
$env:LLM_CLI_MODEL = "qwen3-8b"
```

**macOS（Terminal）:**

```bash
export LLM_CLI_MODEL="qwen3-8b"
```

各ツールの環境変数名は README を参照してください。

## Ollama（代替）

LM Studio の代わりに [Ollama](https://ollama.com/) を使うこともできます。

**インストール:**

- Windows: [ollama.com](https://ollama.com/) からインストーラをダウンロード
- macOS: `brew install ollama`

**モデルのダウンロードと起動:**

```
ollama pull qwen3:8b
ollama serve
```

Ollama は `http://localhost:11434/v1` でAPIを公開します。ツールの接続先URLを変更してください。

## トラブルシューティング

### API に接続できない（「Connection refused」）

- LM Studio が起動しているか確認してください
- Developer タブで API サーバーが起動しているか確認してください
- ファイアウォールが localhost:1234 をブロックしていないか確認してください

### モデルの応答が非常に遅い

- GPU が使われていない可能性があります。LM Studio の設定で GPU Offload が有効になっているか確認してください
- モデルサイズが PC のスペックに対して大きすぎる場合は、より小さいモデルをお試しください

### 「Out of memory」エラー

- モデルサイズが VRAM/RAM を超えています。より小さいモデルをダウンロードしてください
- 他のアプリケーション（ブラウザ等）を閉じてメモリを確保してください

### Windows で LM Studio が起動しない

- GPU ドライバが最新か確認してください（NVIDIA の場合: [NVIDIA ドライバ](https://www.nvidia.com/drivers)）
- Visual C++ 再頒布可能パッケージが必要な場合があります

## 次のステップ

セットアップが完了したら、使いたいツールの README に従ってツールをインストール・実行してください。

- Python 製ツールの場合: [Python + uv セットアップ](setup-python-uv.ja.md) も必要です
- Go 製ツールの場合: ビルド済みバイナリを使うか、[Go ビルド環境セットアップ](setup-go-build.ja.md) でビルドしてください
