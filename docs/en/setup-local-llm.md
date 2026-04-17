# Local LLM Setup Guide

Environment setup instructions for tools that run AI models (LLMs) on your local PC. You can use AI entirely on your own machine without sending data to the cloud.

## Target Tools

This setup is required if you use any of the following tools.

| Tool | Series | Language | Description |
|------|--------|----------|-------------|
| llm-cli | cli-series | Go | Local LLM chat CLI |
| data-analyzer | util-series | Go | Large-scale JSON analysis |
| mail-analyzer-local | util-series | Go | Email analysis (local version) |
| lite-rag | lite-series | Go | Local RAG search |
| lite-switch | lite-series | Go | Natural language classifier |
| magi-system | lab-series | Python | Multi-persona discussion |
| sai | lab-series | Python | Slack AI bot |
| slack-monitor | lab-series | Python | Slack channel summarization |
| agent-skeleton | lab-series | Python | Autonomous agent |
| cti-primer | cybersecurity-series | Python | CTI PIR generation |

## Prerequisites

- Windows 10/11 or macOS
- **GPU (strongly recommended)**: NVIDIA GPU (8GB+ VRAM) or Apple Silicon Mac (M1 or later)
  - It works without a GPU, but will be very slow
- Available disk space: at least 10GB (20-50GB recommended depending on model size)
- RAM: 16GB or more recommended

### GPU Requirement Guidelines

| Model size | Required VRAM | Use case |
|-----------|--------------|----------|
| 7-8B parameters | 6-8 GB | Basic dialogue, classification |
| 14-15B parameters | 10-12 GB | Higher quality responses |
| 30B parameters | 20-24 GB | High-precision analysis |

> Apple Silicon Macs (M1/M2/M3) can use unified memory as VRAM, so models up to the 14B class can run with 16GB RAM.

## Steps

### Step 1: Install LM Studio

LM Studio is an application that makes it easy to run AI models on your local PC.

1. Visit the [LM Studio official website](https://lmstudio.ai/)
2. Download the installer for your OS
3. Run the installer

> On Windows: Run the downloaded `.exe` file and follow the on-screen instructions to install.

### Step 2: Download an AI Model

Launch LM Studio and download a model.

1. Launch LM Studio
2. Enter the desired model name in the search bar at the top of the screen
3. Select the model and click "Download"

**Recommended model:**

| Model name | Size | VRAM estimate | Notes |
|-----------|------|--------------|-------|
| `google/gemma-4-27b-it` | ~18 GB | 20-24 GB | **nlink-jp standard model. Verified.** |

> nlink-jp tools are developed and tested with **gemma-4-27b-it** (Gemma 4 27B Instruct, MoE with effective 4B parameter activation) as the standard model. Other models may work but have not been verified.
>
> Type `gemma-4-27b-it` in the search bar and select a GGUF quantized version (e.g., Q4_K_M). If VRAM is insufficient, LM Studio will automatically use hybrid CPU/GPU execution.

### Step 3: Start the API Server

nlink-jp tools access the model through LM Studio's API server.

1. In LM Studio, load the downloaded model (select it from the model selector at the top of the screen)
2. Click the **Developer** tab (`<>` icon) in the left menu
3. Confirm that **Server Port** is `1234`
4. Click **Start Server**

**When the server starts:**

- A message like `Server started on port 1234` will appear on screen
- Tools can then access it at `http://localhost:1234/v1`

> The API server stops when LM Studio is closed. Keep LM Studio running while using the tools.

### Step 4: Verification

Verify that the API server is running correctly.

**Windows (PowerShell):**

```powershell
Invoke-RestMethod -Uri "http://localhost:1234/v1/models" | ConvertTo-Json
```

**macOS (Terminal):**

```bash
curl http://localhost:1234/v1/models
```

If the loaded model name is returned as JSON, the setup is successful.

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

## Tool Configuration

Most tools connect to `http://localhost:1234/v1` by default. No special configuration is needed, but you may need to specify the model name.

**Example environment variables (for llm-cli):**

**Windows (PowerShell):**

```powershell
$env:LLM_CLI_MODEL = "qwen3-8b"
```

**macOS (Terminal):**

```bash
export LLM_CLI_MODEL="qwen3-8b"
```

Refer to each tool's README for the specific environment variable names.

## Ollama (Alternative)

You can also use [Ollama](https://ollama.com/) instead of LM Studio.

**Installation:**

- Windows: Download the installer from [ollama.com](https://ollama.com/)
- macOS: `brew install ollama`

**Download and run a model:**

```
ollama pull qwen3:8b
ollama serve
```

Ollama exposes its API at `http://localhost:11434/v1`. Change the connection URL in your tool settings.

## Troubleshooting

### Cannot connect to API ("Connection refused")

- Check that LM Studio is running
- Check that the API server is started in the Developer tab
- Check that your firewall is not blocking localhost:1234

### Model responses are very slow

- The GPU may not be in use. Check that GPU Offload is enabled in LM Studio's settings
- If the model size is too large for your PC's specs, try a smaller model

### "Out of memory" Error

- The model size exceeds your VRAM/RAM. Download a smaller model
- Close other applications (browsers, etc.) to free up memory

### LM Studio won't start on Windows

- Check that your GPU drivers are up to date (for NVIDIA: [NVIDIA Drivers](https://www.nvidia.com/drivers))
- Visual C++ Redistributable may be required

## Next Steps

Once setup is complete, install and run the tools following each tool's README.

- For Python tools: [Python + uv Setup](setup-python-uv.md) is also required
- For Go tools: Use pre-built binaries or build using [Go Build Environment Setup](setup-go-build.md)
