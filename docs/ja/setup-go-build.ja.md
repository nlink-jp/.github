# Go ビルド環境セットアップガイド

Go 製ツールをソースコードからビルドするための環境構築手順です。

> **ビルド済みバイナリを使う場合、このガイドは不要です。** 多くの Go 製ツールは [GitHub Releases](https://github.com/orgs/nlink-jp/repositories) にビルド済みバイナリ（Windows/macOS/Linux）が公開されています。ダウンロードして展開するだけで使えます。

## ビルド済みバイナリを使う場合（推奨）

ソースからビルドするよりも簡単です。

### ステップ 1: Releases ページを開く

使いたいツールの GitHub リポジトリにアクセスし、右側の **Releases** をクリックします。

例: `https://github.com/nlink-jp/<ツール名>/releases`

### ステップ 2: ダウンロード

最新バージョンの Assets から、お使いの OS に合ったファイルをダウンロードします。

| OS | ファイル名の例 |
|----|--------------|
| Windows (64bit) | `<ツール名>_windows_amd64.zip` |
| macOS (Apple Silicon) | `<ツール名>_darwin_arm64.zip` |
| macOS (Intel) | `<ツール名>_darwin_amd64.zip` |

### ステップ 3: 展開と配置

1. ダウンロードした zip を展開
2. 中の実行ファイルを任意のフォルダに配置
3. そのフォルダを PATH に追加（任意）

**Windows で PATH に追加する場合:**

```powershell
# 例: C:\Tools に配置した場合
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
[Environment]::SetEnvironmentVariable("PATH", "$currentPath;C:\Tools", "User")
```

> PATH に追加すると、どのフォルダからでもツール名だけで実行できるようになります。追加しない場合は、フルパスで実行してください。

---

## ソースからビルドする場合

### 必要なもの

- Windows 10/11 または macOS
- インターネット接続
- ディスク空き容量: 約 500MB（Go + ツールのソース）

### ステップ 1: Go のインストール

**Windows（PowerShell）:**

```powershell
winget install GoLang.Go
```

**macOS（Terminal）:**

```bash
brew install go
```

**インストール確認（PowerShell / Terminal を再起動後）:**

```
go version
```

```
go version go1.26.x ...
```

### ステップ 2: make のインストール（任意）

nlink-jp のプロジェクトは `make build` でビルドする規約ですが、Windows には make が標準搭載されていません。

**方法 A: make をインストールする**

```powershell
winget install GnuWin32.Make
```

> インストール後に PowerShell を再起動してください。`make --version` で確認できます。

**方法 B: make なしでビルドする**

make がなくても、Go コマンドで直接ビルドできます:

```powershell
# ツールのディレクトリに移動
cd C:\path\to\tool-directory

# ビルド（出力先は dist/ ディレクトリ）
go build -o dist/<ツール名>.exe ./cmd/<ツール名>
```

> `cmd/<ツール名>` の部分はツールによって異なります。`main.go` が直下にある場合は `go build -o dist/<ツール名>.exe .` としてください。

**macOS の場合:**

macOS には make がプリインストールされています。追加作業は不要です。

### ステップ 3: ソースの取得とビルド

```powershell
# リポジトリをクローン
git clone https://github.com/nlink-jp/<ツール名>.git
cd <ツール名>

# ビルド
make build
```

ビルドが成功すると、`dist/` ディレクトリに実行ファイルが生成されます。

**動作確認:**

```powershell
.\dist\<ツール名>.exe --version
```

### CGO が必要なツール

以下のツールは CGO（C言語連携）が必要です。通常の Go 環境に加えて C コンパイラが必要になります。

| ツール | 理由 |
|-------|------|
| gem-query | DuckDB の CGO バインディング |
| json-to-sqlite | SQLite の CGO バインディング |

**Windows の場合:** [TDM-GCC](https://jmeubank.github.io/tdm-gcc/) のインストールが必要です。

**macOS の場合:** Xcode Command Line Tools（`xcode-select --install`）で C コンパイラが入ります。

> CGO ツールのビルドが難しい場合は、GitHub Releases のビルド済みバイナリをお使いください。

## トラブルシューティング

### 「go: command not found」/ 「go は認識されていません」

- Go インストール後に PowerShell / Terminal を再起動してください
- Windows の場合、PATH に `C:\Program Files\Go\bin` が含まれているか確認

### 「make: command not found」(Windows)

- make をインストールしていない場合は「方法 B: make なしでビルドする」を参照
- インストール済みの場合は PowerShell を再起動

### ビルドエラー「module not found」

- インターネット接続を確認してください（初回ビルド時に依存パッケージをダウンロードします）
- `go mod download` を実行してから再度ビルドしてください

### CGO 関連のエラー

- C コンパイラがインストールされているか確認してください
- Windows: `gcc --version` が実行できるか確認
- ビルドが難しい場合は GitHub Releases のバイナリを使ってください

## 次のステップ

ツールのビルドが完了したら、各ツールの README に従って設定・実行してください。

- Vertex AI を使うツールの場合: [Vertex AI セットアップ](setup-vertex-ai.ja.md) も必要です
- ローカルLLM を使うツールの場合: [ローカルLLM セットアップ](setup-local-llm.ja.md) も必要です
