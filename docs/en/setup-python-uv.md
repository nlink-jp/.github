# Python + uv Setup Guide

Environment setup instructions for using Python-based tools. This covers installing Python and setting up the uv package manager.

## Target

All projects that have a `pyproject.toml` or `uv.lock` file are covered. Major tools include:

| Tool | Series | Description |
|------|--------|-------------|
| gem-rag | util-series | RAG search |
| ai-ir2 | cybersecurity-series | Incident response analysis |
| ir-tracker | cybersecurity-series | Live IR tracking |
| ioc-collector | cybersecurity-series | IoC collection |
| mail-triage | cybersecurity-series | Email triage |
| news-collector | cybersecurity-series | News collection |
| product-research | cybersecurity-series | Product risk research |
| cti-primer | cybersecurity-series | CTI PIR generation |
| meeting-note | lab-series | Meeting minutes structuring |
| magi-system | lab-series | Multi-persona discussion |
| magi-system2 | lab-series | Multi-AI discussion |
| sai | lab-series | Slack AI bot |
| virtual-reviewer | lab-series | AI security review |
| confl-cli | cli-series | Confluence CLI client |

## Prerequisites

- Windows 10/11 or macOS
- Internet connection
- Available disk space: approximately 500MB (Python + uv + package cache)

## Steps

### Step 1: Install Python

**Windows:**

1. Visit [python.org](https://www.python.org/downloads/)
2. Download the latest Python 3.12 or later
3. Run the installer
4. **Important: Check "Add python.exe to PATH" at the bottom of the install screen**
5. Click "Install Now"

> If you forgot to check the PATH option, you won't be able to use the `python` command from PowerShell. In that case, re-run the installer and select "Modify" -> "Add to PATH".

**macOS:**

```bash
brew install python@3.12
```

**Verify installation:**

Open a **new** PowerShell (Windows) or Terminal (macOS):

```
python --version
```

```
Python 3.12.x
```

> On Windows, if `python` is not found, try `python3 --version`.

### Step 2: Install uv

uv is a Python package manager. It is faster than pip and automatically manages dependencies per project.

**Windows (PowerShell):**

```powershell
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

> If you see an execution policy warning, select "Yes".

**macOS (Terminal):**

```bash
brew install uv
```

**Verify installation:**

Open a **new** PowerShell / Terminal:

```
uv --version
```

```
uv 0.x.x
```

### Step 3: Install Tool Dependencies

Navigate to the directory of the tool you want to use and install dependencies with uv.

**Windows (PowerShell):**

```powershell
cd C:\path\to\tool-directory
uv sync
```

**macOS (Terminal):**

```bash
cd /path/to/tool-directory
uv sync
```

`uv sync` reads `pyproject.toml` and `uv.lock` and automatically installs all required packages.

**Expected output:**

```
Resolved XX packages in X.XXs
Installed XX packages in X.XXs
```

### Step 4: Run the Tool

Run tools installed with uv using `uv run`.

```
uv run python main.py --help
```

Or, if the tool has a script entry point defined:

```
uv run <tool-name> --help
```

Refer to each tool's README for specific commands.

## Verification

Verify that Python and uv are set up correctly:

```
python --version
uv --version
```

If both display a version number, you're all set.

## Troubleshooting

### "python: command not found" (macOS) / "python is not recognized" (Windows)

- You may have forgotten to check "Add to PATH" during Python installation
- Windows: Re-run the installer -> "Modify" -> Enable PATH
- Restart PowerShell / Terminal

### "uv: command not found" / "uv is not recognized"

- Restart PowerShell / Terminal after installing uv
- On Windows, verify that `%USERPROFILE%\.local\bin` has been added to PATH:
  ```powershell
  $env:PATH -split ";" | Select-String "\.local\\bin"
  ```

### "No Python found" during "uv sync"

- uv cannot find the system Python
- Run `uv python install 3.12` to have uv automatically download Python

### Version error during "uv sync"

- The Python version required by the tool may differ from the installed version
- Install the required version with `uv python install 3.12`

### Garbled text on Windows

- Set PowerShell's character encoding to UTF-8:
  ```powershell
  [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
  ```

## Next Steps

Once setup is complete, run the tools following each tool's README.

- For tools that use Vertex AI: [Vertex AI Setup](setup-vertex-ai.md) is also required
- For tools that use a local LLM: [Local LLM Setup](setup-local-llm.md) is also required
