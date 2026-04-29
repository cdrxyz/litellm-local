# Connecting Claude Code / Conductor to LiteLLM Local

This guide covers how to configure Claude Code (running inside Conductor or standalone) to use local LM Studio models through the LiteLLM proxy.

## Architecture

```
┌─────────────────────┐
│  Claude Code        │  Your AI coding assistant
│  (or Conductor)     │
└─────────┬───────────┘
          │  OpenAI API calls
          ▼
┌─────────────────────┐
│  LiteLLM Proxy      │  localhost:4000
│  (this repo)        │  Translates & routes requests
└─────────┬───────────┘
          │  OpenAI API calls (with lm_studio/ prefix)
          ▼
┌─────────────────────┐
│  LM Studio          │  localhost:1234
│  (local models)     │  Runs inference on your Mac
└─────────────────────┘
```

## Setup

### 1. Start the proxy

```bash
cd litellm-local
just start
```

Or if you've installed the LaunchAgent, it's already running.

### 2. Configure Claude Code environment variables

Claude Code uses the OpenAI SDK under the hood. Point it at the LiteLLM proxy:

```bash
# Required — any non-empty string works (no real key needed for local)
export OPENAI_API_KEY="sk-litellm-local"

# Required — point to the LiteLLM proxy, not LM Studio directly
export OPENAI_API_BASE="http://localhost:4000"
```

Add these to your shell profile (`~/.zshrc`) for persistence:

```bash
# ~/.zshrc
export OPENAI_API_KEY="sk-litellm-local"
export OPENAI_API_BASE="http://localhost:4000"
```

### 3. Use a model from your config.yaml

When Claude Code asks which model to use, or in your Conductor configuration, use the `model_name` you defined in `config.yaml`:

```yaml
# config.yaml
model_list:
  - model_name: local-default        # ← Use this name
    litellm_params:
      model: lm_studio/local-default
      api_base: http://localhost:1234/v1
```

So you'd tell Claude Code to use model `local-default`.

### 4. Conductor-specific configuration

If you're using Conductor (Anthropic's multi-agent orchestration), configure it to route through the proxy:

In your Conductor project settings or environment:

```bash
# Conductor respects the same OpenAI env vars
OPENAI_API_KEY="sk-litellm-local"
OPENAI_API_BASE="http://localhost:4000"
```

Or in a Conductor config file if it uses one:

```json
{
  "model": "local-default",
  "api_base": "http://localhost:4000",
  "api_key": "sk-litellm-local"
}
```

## Choosing a Model

Not all models work equally well for coding assistance. Recommendations for Claude Code / Conductor:

| Model | Size | Best For | Notes |
|-------|------|----------|-------|
| Qwen 2.5 Coder 7B | 7B | Code completion | Fast, good code understanding |
| Qwen 2.5 Coder 32B | 32B | Code + reasoning | Slower but much stronger |
| DeepSeek Coder V2 Lite | 16B | Code + reasoning | Strong open-source coder |
| Llama 3.1 8B Instruct | 8B | General chat | Good all-rounder |
| Phi-4 | 14B | Reasoning | Strong for its size |

**Important:** For coding tasks, prefer models with "coder" in the name. General chat models will produce worse code suggestions.

## Model Configuration Tips

### Adding multiple models

You can expose several LM Studio models simultaneously:

```yaml
model_list:
  - model_name: fast-coder
    litellm_params:
      model: lm_studio/qwen2.5-coder-7b-instruct
      api_base: http://localhost:1234/v1

  - model_name: strong-coder
    litellm_params:
      model: lm_studio/qwen2.5-coder-32b-instruct
      api_base: http://localhost:1234/v1

  - model_name: general
    litellm_params:
      model: lm_studio/llama-3.1-8b-instruct
      api_base: http://localhost:1234/v1
```

Then switch between them by changing the model name in Claude Code's config.

### LM Studio server settings

In LM Studio's Local Server settings:

- **Port:** 1234 (default — matches `config.yaml`)
- **CORS:** Enabled (not strictly required for localhost, but avoids issues)
- **Context Length:** Set appropriately for your model (4096 minimum for coding tasks)
- **GPU Offload:** Max layers for best performance on Apple Silicon

## Verifying the Connection

```bash
# 1. Check the proxy is up
just status

# 2. Send a test request
just test

# 3. Or manually:
curl http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "local-default",
    "messages": [{"role": "user", "content": "Hello"}]
  }'
```

## Limitations

- **No streaming by default** — some Claude Code features may work better with streaming enabled. LiteLLM supports it; check that LM Studio has streaming enabled in its server settings.
- **First prompt is slow** — local models need to load into memory. Subsequent prompts are faster.
- **Context window** — local models have smaller context windows than cloud models. Long files may need to be chunked.
- **Tool use** — not all local models support function/tool calling well. If Claude Code's tool use fails, try a model specifically trained for it.
