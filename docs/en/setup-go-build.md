# Go Build Environment Setup Guide

Environment setup instructions for building Go tools from source code.

> **This guide is not needed if you use pre-built binaries.** Many Go tools have pre-built binaries (Windows/macOS/Linux) available on [GitHub Releases](https://github.com/orgs/nlink-jp/repositories). Just download and extract them to use.

## Using Pre-built Binaries (Recommended)

This is easier than building from source.

### Step 1: Open the Releases Page

Visit the GitHub repository of the tool you want to use and click **Releases** on the right side.

Example: `https://github.com/nlink-jp/<tool-name>/releases`

### Step 2: Download

Download the file matching your OS from the Assets of the latest version.

| OS | Example filename |
|----|-----------------|
| Windows (64bit) | `<tool-name>_windows_amd64.zip` |
| macOS (Apple Silicon) | `<tool-name>_darwin_arm64.zip` |
| macOS (Intel) | `<tool-name>_darwin_amd64.zip` |

### Step 3: Extract and Place

1. Extract the downloaded zip
2. Place the executable in a folder of your choice
3. Add that folder to PATH (optional)

**To add to PATH on Windows:**

```powershell
# Example: if placed in C:\Tools
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
[Environment]::SetEnvironmentVariable("PATH", "$currentPath;C:\Tools", "User")
```

> Adding to PATH allows you to run the tool by name from any directory. If you don't add it, run the tool using its full path.

---

## Building from Source

### Prerequisites

- Windows 10/11 or macOS
- Internet connection
- Available disk space: approximately 500MB (Go + tool source)

### Step 1: Install Go

**Windows (PowerShell):**

```powershell
winget install GoLang.Go
```

**macOS (Terminal):**

```bash
brew install go
```

**Verify installation (after restarting PowerShell / Terminal):**

```
go version
```

```
go version go1.26.x ...
```

### Step 2: Install make (Optional)

nlink-jp projects follow the convention of building with `make build`, but make is not included by default on Windows.

**Option A: Install make**

```powershell
winget install GnuWin32.Make
```

> Restart PowerShell after installation. Verify with `make --version`.

**Option B: Build without make**

Even without make, you can build directly with the Go command:

```powershell
# Navigate to the tool's directory
cd C:\path\to\tool-directory

# Build (output to the dist/ directory)
go build -o dist/<tool-name>.exe ./cmd/<tool-name>
```

> The `cmd/<tool-name>` part varies by tool. If `main.go` is in the root directory, use `go build -o dist/<tool-name>.exe .` instead.

**On macOS:**

make is pre-installed on macOS. No additional steps needed.

### Step 3: Clone Source and Build

```powershell
# Clone the repository
git clone https://github.com/nlink-jp/<tool-name>.git
cd <tool-name>

# Build
make build
```

If the build succeeds, the executable will be generated in the `dist/` directory.

**Verification:**

```powershell
.\dist\<tool-name>.exe --version
```

### Tools Requiring CGO

The following tools require CGO (C language interop). A C compiler is needed in addition to the standard Go environment.

| Tool | Reason |
|------|--------|
| gem-query | DuckDB CGO bindings |
| json-to-sqlite | SQLite CGO bindings |

**On Windows:** Installing [TDM-GCC](https://jmeubank.github.io/tdm-gcc/) is required.

**On macOS:** A C compiler is included with Xcode Command Line Tools (`xcode-select --install`).

> If building CGO tools is difficult, use the pre-built binaries from GitHub Releases.

## Troubleshooting

### "go: command not found" / "go is not recognized"

- Restart PowerShell / Terminal after installing Go
- On Windows, verify that `C:\Program Files\Go\bin` is in PATH

### "make: command not found" (Windows)

- If you haven't installed make, refer to "Option B: Build without make"
- If already installed, restart PowerShell

### Build error "module not found"

- Check your internet connection (dependency packages are downloaded during the first build)
- Run `go mod download` and then rebuild

### CGO-related Errors

- Check that a C compiler is installed
- Windows: Verify that `gcc --version` runs successfully
- If building is difficult, use the binaries from GitHub Releases

## Next Steps

Once the tool is built, configure and run it following each tool's README.

- For tools that use Vertex AI: [Vertex AI Setup](setup-vertex-ai.md) is also required
- For tools that use a local LLM: [Local LLM Setup](setup-local-llm.md) is also required
