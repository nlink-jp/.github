# nlink-jp ツール はじめに

nlink-jp のツールを使い始めるためのガイドです。使いたいツールに合わせて、必要なセットアップガイドを確認してください。

## どのガイドを読むべきか

使いたいツールの種類に応じて、以下のガイドを参照してください。複数に該当する場合は、それぞれのガイドを順番にセットアップしてください。

### ツールの入手方法

| やりたいこと | 必要なガイド |
|------------|------------|
| Go製ツールのビルド済みバイナリをダウンロードして使う | 特別な準備不要（[GitHub Releases](https://github.com/orgs/nlink-jp/repositories) からダウンロード） |
| Go製ツールをソースからビルドする | [Go ビルド環境セットアップ](setup-go-build.ja.md) |
| Python製ツールを使う | [Python + uv セットアップ](setup-python-uv.ja.md) |

### ツールの前提環境

| ツールが使うサービス | 必要なガイド | 対象ツールの例 |
|-------------------|------------|-------------|
| Vertex AI (Gemini) | [Vertex AI セットアップ](setup-vertex-ai.ja.md) | gem-query, gem-search, gem-image, gem-cli, gem-rag, mail-analyzer, ai-ir2, ir-tracker, meeting-note 等 |
| ローカルLLM (LM Studio) | [ローカルLLM セットアップ](setup-local-llm.ja.md) | llm-cli, data-analyzer, lite-rag, magi-system, sai 等 |
| Slack API | 各ツールのREADMEを参照 | scat, stail, swrite, slack-router, sai 等 |
| Confluence API | 各ツールのREADMEを参照 | confl-cli |
| Splunk API | 各ツールのREADMEを参照 | splunk-cli |

### 判定フロー

```
使いたいツールは何？
  │
  ├─ gem-* / mail-analyzer / ai-ir2 / meeting-note 等
  │   → Vertex AI セットアップ が必要
  │   → ツールがPython製なら Python + uv も必要
  │   → ツールがGo製で、ソースからビルドするなら Go ビルド環境 も必要
  │
  ├─ llm-cli / data-analyzer / lite-* / magi-system 等
  │   → ローカルLLM セットアップ が必要
  │   → ツールがPython製なら Python + uv も必要
  │   → ツールがGo製で、ソースからビルドするなら Go ビルド環境 も必要
  │
  └─ その他のツール
      → 各ツールのREADMEに従う
      → ツールがPython製なら Python + uv が必要
      → ツールがGo製で、ソースからビルドするなら Go ビルド環境 が必要
```

## ツールの言語を調べる

各ツールが Go 製か Python 製かは、ツールのリポジトリを見ればわかります。

- **Go 製**: `go.mod` ファイルがある。ビルド済みバイナリが GitHub Releases にあることが多い
- **Python 製**: `pyproject.toml` や `uv.lock` ファイルがある

わからない場合は、各ツールの README を参照してください。

## セットアップガイド一覧

| ガイド | 内容 | 所要時間の目安 |
|-------|------|-------------|
| [Vertex AI セットアップ](setup-vertex-ai.ja.md) | Google Cloud CLI、認証情報、設定ファイル | 15-20分 |
| [ローカルLLM セットアップ](setup-local-llm.ja.md) | LM Studio、モデルダウンロード、APIサーバー | 20-30分（モデルDL時間除く） |
| [Python + uv セットアップ](setup-python-uv.ja.md) | Python、uv パッケージマネージャ | 10-15分 |
| [Go ビルド環境セットアップ](setup-go-build.ja.md) | Go、make、ソースビルド | 10-15分 |

## サポート

セットアップで問題が起きた場合は、各ガイドのトラブルシューティングセクションを確認してください。それでも解決しない場合は、チームの Slack チャンネルで質問してください。
