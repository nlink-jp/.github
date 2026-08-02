# Vertex AI (Gemini) Setup Guide

Environment setup instructions for tools that use Google Cloud's Vertex AI.

## Target Tools

This setup is required if you use any of the following tools.

| Tool | Series | Language | Description |
|------|--------|----------|-------------|
| gem-cli | cli-series | Go | Gemini chat CLI |
| gem-query | util-series | Go | Natural language DB analysis |
| gem-search | util-series | Go | AI web search |
| gem-image | util-series | Go | AI image generation |
| gem-rag | util-series | Python | RAG search |
| gem-summary | util-series | Go | Text summarisation |
| gem-transcribe | util-series | Python | Audio transcription |
| mail-analyzer | util-series | Go | Suspicious email analysis |
| ask-gemini-mcp | util-series | Go | MCP: Gemini second opinions |
| news-collector | cybersecurity-series | Python | News collection |

## Prerequisites

- Windows 10/11 or macOS
- Internet connection
- Google account (organization account)
- Access to the shared GCP project (granted by your administrator)
- Disk space: approximately 200MB (Google Cloud CLI)

## Steps

### Step 1: Install Google Cloud CLI

Install the Google Cloud CLI (gcloud command).

**Windows (PowerShell):**

```powershell
winget install Google.CloudSDK
```

> After installation, **close and reopen PowerShell** (to apply PATH changes).

**macOS (Terminal):**

```bash
brew install --cask google-cloud-sdk
```

**Verify installation:**

```
gcloud version
```

If you see output like the following, the installation was successful:

```
Google Cloud SDK 5xx.x.x
...
```

### Step 2: Google Cloud Initial Configuration

Initialize Google Cloud CLI and connect to the shared project.

```
gcloud init
```

You will be prompted interactively:

1. **Login**: Enter `Y` -> A browser will open, log in with your Google account
2. **Project selection**: Select the shared project ID (it will appear in the list)
   - If it does not appear, ask your administrator to grant you access to the project

**Expected output:**

```
Your Google Cloud SDK is configured and ready to use!
```

### Step 3: Set Up ADC (Credentials)

Set up ADC (Application Default Credentials). nlink-jp tools use these credentials to access Vertex AI.

```
gcloud auth application-default login
```

A browser will open. Log in with the same Google account as in Step 2.

**Expected output:**

```
Credentials saved to file: [C:\Users\<username>\AppData\Roaming\gcloud\application_default_credentials.json]
```

### Step 4: Set the Quota Project

Set the quota project so that API usage is billed to the correct project.

```
gcloud auth application-default set-quota-project your-shared-project
```

> Replace `your-shared-project` with the shared project ID provided by your administrator.

**Expected output:**

```
Credentials saved to file: [...]

Quota project "your-shared-project" was added to ADC...
```

### Step 5: Create config.toml (Per Tool)

Many tools specify the GCP project and region in a `config.toml` file. Create one following each tool's README.

The common pattern is as follows:

**Save location on Windows:** `%APPDATA%\<tool-name>\config.toml` or `%USERPROFILE%\.config\<tool-name>\config.toml`

**Save location on macOS:** `~/.config/<tool-name>/config.toml`

**Example file contents:**

```toml
[gcp]
project  = "your-shared-project"
location = "us-central1"

[model]
name = "gemini-2.5-flash"
```

> - `project`: The shared project ID
> - `location`: Typically `us-central1` is used
> - `name`: The model name to use (varies by tool; refer to each tool's README)

Each tool's repository includes a `config.example.toml` that you can copy and edit.

## Verification

To verify that the setup is correct, run the following command:

```
gcloud auth application-default print-access-token
```

If a long string (token) is displayed, authentication is working correctly. If you get an error, repeat from Step 3.

## Configuration via Environment Variables (Alternative)

Instead of config.toml, you can also configure via environment variables.

**Windows (PowerShell):**

```powershell
$env:GOOGLE_CLOUD_PROJECT = "your-shared-project"
$env:GOOGLE_CLOUD_LOCATION = "us-central1"
```

> This method is temporary. The values will be lost when PowerShell is closed. To persist them, set them as system environment variables.

**macOS (Terminal):**

```bash
export GOOGLE_CLOUD_PROJECT="your-shared-project"
export GOOGLE_CLOUD_LOCATION="us-central1"
```

## Troubleshooting

### "Permission denied" / "403" Error

- You may not have access to the shared project. Ask your administrator to grant you the Vertex AI User role.
- This error also occurs when the quota project is not set. Check Step 4.

### "Could not automatically determine credentials"

- ADC is not configured. Run Step 3.

### "Quota exceeded"

- You have reached the API usage limit. Wait a while and retry, or ask your administrator to increase the quota.

### "Region not available"

- Try changing `location` to `us-central1`. Some models are only available in specific regions.

### "gcloud: command not found" (macOS) / "gcloud is not recognized" (Windows)

- Restart Terminal/PowerShell after installing Google Cloud CLI.
- On Windows, you can also try searching for "Google Cloud SDK Shell" in the Start menu and launching it.

## Next Steps

Once setup is complete, install and run the tools following each tool's README.

- For Python tools: [Python + uv Setup](setup-python-uv.md) is also required
- For Go tools: Use pre-built binaries or build using [Go Build Environment Setup](setup-go-build.md)
