# litellm-local

A thin, self-contained setup for running [LiteLLM](https://github.com/BerriAI/litellm) as a local proxy to [LM Studio](https://lmstudio.ai/) — so Claude Code (via Conductor) can talk to models running on your Mac.

**What it does:** LiteLLM sits between your AI tools and LM Studio, translating OpenAI-compatible API requests into whatever the local model expects. Your tools think they're talking to OpenAI; LiteLLM routes to LM Studio.

```
Claude Code / Conductor
        │
        ▼  OpenAI-compatible API (localhost:4000)
   LiteLLM Proxy
        │
        ▼  OpenAI-compatible API (localhost:1234)
   LM Studio (local models)
```

## Prerequisites

- **macOS** (Apple Silicon or Intel)
- **[LM Studio](https://lmstudio.ai/)** with at least one model loaded and the local server running
- **Git** (to clone this repo)

That's it. Hermit handles the rest (Python, pip, litellm).

## Quick Start

```bash
# 1. Clone
git clone https://github.com/cdrxyz/litellm-local.git
cd litellm-local

# 2. Setup — activates Hermit, installs Python + LiteLLM
just setup

# 3. Make sure LM Studio is running with a model loaded
#    (Local Server → Start Server, default port 1234)

# 4. Edit config.yaml — set your model name
#    Change "local-default" to match the model in LM Studio

# 5. Start the proxy
just start
```

The proxy is now live at `http://localhost:4000`.

## Connecting Claude Code / Conductor

See [docs/claude-code-conductor.md](docs/claude-code-conductor.md) for full configuration instructions.

**TL;DR** — set these environment variables before launching Claude Code:

```bash
export OPENAI_API_KEY="sk-litellm-local"   # Any non-empty string
export OPENAI_API_BASE="http://localhost:4000"
```

Then tell Claude Code to use a model name from your `config.yaml` (e.g., `local-default`).

## Auto-Start at Login (macOS)

```bash
# Install the LaunchAgent (starts proxy at login, restarts on crash)
just install-launchd

# Check if it's running
just status

# Stop it from auto-starting
just uninstall-launchd
```

Logs go to `logs/litellm-proxy.log` and `logs/litellm-proxy.err`.

## Adding Models

Edit `config.yaml` to add more LM Studio models:

```yaml
model_list:
  - model_name: my-coder-model          # Name your tools will use
    litellm_params:
      model: lm_studio/qwen2.5-coder-7b  # Must match LM Studio model ID
      api_base: http://localhost:1234/v1
      api_key: ""
```

The `model_name` is what you reference from Claude Code. The `litellm_params.model` must be prefixed with `lm_studio/` and match the model identifier in LM Studio.

## Available Commands

| Command | Description |
|---------|-------------|
| `just setup` | First-time setup (Hermit + Python + deps) |
| `just start` | Start proxy in foreground |
| `just start-bg` | Start proxy in background |
| `just stop` | Stop background proxy |
| `just status` | Check if proxy is running |
| `just test` | Send a test request |
| `just install-launchd` | Enable auto-start at login |
| `just uninstall-launchd` | Disable auto-start at login |
| `just clean` | Remove the virtual environment |

## Troubleshooting

See [docs/troubleshooting.md](docs/troubleshooting.md).

## How It Works

1. **Hermit** bootstraps an isolated Python environment — no system Python pollution
2. **LiteLLM** runs as a lightweight proxy server on port 4000
3. **LM Studio** serves local models on port 1234 (OpenAI-compatible)
4. **LiteLLM translates** between the two, adding the `lm_studio/` routing prefix

## License

MIT
