# nlink-jp ツール はじめに

nlink-jp のツールを使い始めるためのガイドです。ツールごとに「どう入手するか」「動かすのに何が要るか」「どんな形態で使うか」の3点を押さえれば、必要なセットアップが分かります。

## 1. ツールの入手方法

| やりたいこと | 必要な準備 |
|------------|----------|
| **macOS (Apple Silicon)** で CLI / GUI を使う | Homebrew tap から入手（署名 + notarize 済みのビルド済みバイナリ）。追加準備は基本不要 |
| ビルド済みバイナリ（他OSのGo製など）を使う | 特別な準備不要（[GitHub Releases](https://github.com/orgs/nlink-jp/repositories) からダウンロード） |
| **Claude Code Skill** を使う | 各 skill リポジトリの Releases から skill zip を取得し、`~/.claude/skills/` に展開（または claude.ai の Settings → Skills にアップロード） |
| Go製ツールをソースからビルドする | [Go ビルド環境セットアップ](setup-go-build.ja.md) |
| Python製ツールを使う | [Python + uv セットアップ](setup-python-uv.ja.md) |

macOS の Homebrew tap:

```sh
brew tap nlink-jp/tap
brew install nlink-jp/tap/<name>          # CLI ツール
brew install --cask nlink-jp/tap/<name>   # GUI アプリ
```

全ラインナップは [nlink-jp/homebrew-tap](https://github.com/nlink-jp/homebrew-tap) を参照。tap に無いものは Releases のバイナリかソースビルドで入手します。

## 2. ツールの前提環境

「そのツールが動くのに外部の何が要るか」で分類しています。**1つのツールが複数に該当することがあります**（例: news-collector は Vertex AI ＋ Slack、quick-translate はローカルLLM ＋ macOS GUI）。正確な要件は各ツールの README が最終根拠です。

| 前提 | 必要なセットアップ | 対象ツールの例 |
|------|----------------|-------------|
| **認証情報なし・オフライン** | 追加準備不要 | json-to-table, json-filter, csv-to-json, rex, sdate, jstats, jviz, lookup, eml-to-jsonl, msg-to-jsonl, markdown-viewer, instant-translate と、lookup 系の大半（tor-exit-lookup, icloud-relay-lookup, mac-lookup, whois-lookup, doh-lookup, rdns-lookup） |
| **サードパーティのAPIキー/トークン** | 各サービスでキーを取得（手順は各README） | abuse-lookup（AbuseIPDB キー）, urlscan-lookup（urlscan.io キー）, asn-lookup（IPinfo トークン。DB取得時のみ、照合はオフライン）, malware-lookup（abuse.ch キーは任意） |
| **Vertex AI (Gemini)** | [Vertex AI セットアップ](setup-vertex-ai.ja.md) | gem-cli, gem-query, gem-search, gem-image, gem-rag, gem-summary, gem-transcribe, mail-analyzer, news-collector, ask-gemini-mcp 等 |
| **ローカルLLM (LM Studio / Ollama)** | [ローカルLLM セットアップ](setup-local-llm.ja.md) | llm-cli, data-analyzer, lite-rag, lite-switch, mail-analyzer-local, quick-translate, slack-monitor, ask-llm-mcp 等 |
| **Slack / Confluence / Splunk API** | 各ツールのREADMEを参照 | scat, stail, swrite, slack-router, md-to-slack, slack-mcp-extender, scli, ir-hub / confl-cli / splunk-cli, splunk-mcp |
| **コンテナ (Podman)** | 各READMEのコンテナ手順 | data-toolbox-mcp, pcap-analyzer-mcp（解析サンドボックス）, shell-agent-v2（サンドボックス実行）, cclaude |
| **クラウド (GCP / AWS)** | 各READMEのデプロイ手順 | webhook-relay, m5-data-receiver |
| **macOS (Apple Silicon) 専用** | Homebrew cask か Releases の zip（.app） | active-lens-gui, claude-usage-lens-gui, load-spinner, image-forge / image-forge-gui, grid-edit, instant-translate, share-mounter, url-shelf, zip-porter 等 |

## 3. 使い方の形態

同じツールでも、次のどの形態で使うかで導線が変わります。

- **CLI**: stdin/stdout でパイプ連携。多くのツールがこれ。入手方法は §1 のとおり。
- **GUI アプリ**: メニューバー常駐 or 通常ウィンドウ。macOS 中心で、Homebrew cask か Releases の zip（署名 + notarize 済み .app）で配布。
- **MCP サーバー**: Claude Code などの AI エージェントに登録して使う。多くは `<tool> mcp` で stdio 起動し、エージェント側の MCP 設定に登録します。
  - 専用MCP: ask-gemini-mcp, ask-llm-mcp, data-toolbox-mcp, pcap-analyzer-mcp, splunk-mcp, chrome-pilot-mcp, voice-studio-mcp, video-studio-mcp
  - CLI兼MCP: lookup 系全般（asn-lookup, abuse-lookup, tor-exit-lookup, icloud-relay-lookup, mac-lookup, whois-lookup, doh-lookup, rdns-lookup, malware-lookup, urlscan-lookup）, image-forge
  - MCPプロキシ: mcp-guardian（ガバナンス）, slack-mcp-extender（公式 Slack MCP の拡張）
  - **MCPサーバーの前提環境は、その裏で使うサービス（§2）に従います**（例: ask-gemini-mcp は Vertex AI、ask-llm-mcp はローカルLLM）。
  - どの MCP をいつ使うかの選択指針は [mcp-tactics](https://github.com/nlink-jp/mcp-tactics) Skill にまとまっています。
- **Claude Code Skill**: 組織のワークフロー（調査・議事録・規定レビュー等）を Claude Code / claude.ai のスラッシュコマンドとして使う形態。skills-series が該当します（compliance-review, incident-research, incident-review, meeting-notes, service-research, rfp, mcp-tactics）。導入は §1 のとおり skill zip を展開するだけで、バイナリのビルドは不要です。

## 4. 判定フロー

```
使いたいツールは何をする？
  │
  ├─ ローカルのデータ変換・整形・照合（JSON/CSV/正規表現/日付 等）
  │   → 多くは 追加準備不要（オフライン・認証情報なし）
  │   → macOS は brew、その他は Releases のバイナリ / ソースビルド
  │
  ├─ IP / ドメイン / URL / ハッシュ / MAC の調査（lookup 系）
  │   → 大半はオフライン or 認証情報なしでそのまま動く
  │   → abuse-lookup / urlscan-lookup / asn-lookup のみ APIキー・トークン取得（各README）
  │
  ├─ Gemini を使う（gem-* / mail-analyzer / news-collector 等）
  │   → Vertex AI セットアップ
  │
  ├─ ローカルLLM を使う（llm-cli / *-local / lite-* / quick-translate 等）
  │   → ローカルLLM セットアップ
  │
  ├─ Slack / Confluence / Splunk を操作
  │   → 各ツールのREADMEで認証設定
  │
  ├─ AIエージェントから MCPツールとして呼ぶ
  │   → エージェントにMCPサーバーを登録。前提環境は裏のサービスに従う
  │   → 選択指針は mcp-tactics Skill
  │
  ├─ Claude Code で組織のワークフローを使う（調査レポート / 議事録 / 規定レビュー等）
  │   → skills-series の skill zip を ~/.claude/skills/ に導入
  │
  ├─ macOS GUI アプリ（メニューバー / ウィンドウ）
  │   → brew --cask か Releases の zip。Apple Silicon 専用が多い
  │
  └─ コンテナ / クラウドが要るもの（data-toolbox-mcp, webhook-relay 等）
      → 各READMEの Podman / GCP / AWS 手順

  ※ 上記に加えて: Python製はどれも Python + uv、
    Go製をソースからビルドするなら Go ビルド環境 も必要
```

## ツールの言語を調べる

各ツールが何製かは、リポジトリを見れば分かります。

- **Go 製**: `go.mod` がある。ビルド済みバイナリが GitHub Releases / Homebrew tap にあることが多い
- **Python 製**: `pyproject.toml` や `uv.lock` がある
- **Swift / Rust 製（GUI）**: macOS 向け。Homebrew cask か Releases の zip（.app）で配布
- **Skill**: `SKILL.md` がある。言語環境は不要（Claude Code / claude.ai 上で動く）

わからない場合は各ツールの README を参照してください。

## セットアップガイド一覧

| ガイド | 内容 | 所要時間の目安 |
|-------|------|-------------|
| [Vertex AI セットアップ](setup-vertex-ai.ja.md) | Google Cloud CLI、認証情報、設定ファイル | 15-20分 |
| [ローカルLLM セットアップ](setup-local-llm.ja.md) | LM Studio、モデルダウンロード、APIサーバー | 20-30分（モデルDL時間除く） |
| [Python + uv セットアップ](setup-python-uv.ja.md) | Python、uv パッケージマネージャ | 10-15分 |
| [Go ビルド環境セットアップ](setup-go-build.ja.md) | Go、make、ソースビルド | 10-15分 |

macOS の Homebrew tap（[nlink-jp/homebrew-tap](https://github.com/nlink-jp/homebrew-tap)）は、上記の準備なしで署名済みバイナリを入れられる最短経路です。ツールが Vertex AI やローカルLLM を使う場合は、入手後に該当する前提環境のセットアップが別途必要です。

## 開発に参加する場合

ツールを使うだけでなく開発・改修する場合は、[CONVENTIONS.md](../../CONVENTIONS.md)（組織規約）と [nlink-jp/knowledge](https://github.com/nlink-jp/knowledge)（エンジニアリングナレッジベース — 作る前に該当テーマを読む）を参照してください。

## サポート

セットアップで問題が起きた場合は、各ガイドのトラブルシューティングセクションを確認してください。それでも解決しない場合は、チームの Slack チャンネルで質問してください。
