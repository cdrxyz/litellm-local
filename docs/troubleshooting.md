# Troubleshooting

## Proxy won't start

**Error: `Address already in use`**

Port 4000 is already occupied. Either stop whatever's using it or change the port:

```bash
# Find what's using port 4000
lsof -i :4000

# Kill it
kill <PID>

# Or start on a different port
litellm --config config.yaml --port 4001
```

**Error: `No module named 'litellm'`**

The virtual environment isn't activated or deps aren't installed:

```bash
just pip-install
```

**Error: `python3: command not found`**

Hermit hasn't installed Python yet:

```bash
just hermit-install
```

## LM Studio connection errors

**Error: `Connection refused` on localhost:1234**

LM Studio's local server isn't running. Open LM Studio, load a model, and click "Start Server" in the Local Server tab.

**Error: `Model not found`**

The model name in `config.yaml` doesn't match what LM Studio has loaded. Check the model identifier in LM Studio's server tab and update your config:

```yaml
litellm_params:
  model: lm_studio/exact-model-name-from-lm-studio
```

**Error: `Timeout`**

Local inference can be slow, especially on the first prompt (model loading). The default timeout is 300 seconds. Increase it in `config.yaml`:

```yaml
litellm_settings:
  request_timeout: 600
```

## Claude Code / Conductor issues

**Claude Code can't connect**

Verify the environment variables are set:

```bash
echo $OPENAI_API_BASE
# Should output: http://localhost:4000

echo $OPENAI_API_KEY
# Should output: sk-litellm-local (or any non-empty string)
```

**Claude Code uses the wrong model**

Make sure the model name in your Claude Code config matches a `model_name` entry in `config.yaml` — not the LM Studio model ID.

**Responses are garbled or low-quality**

This is a model issue, not a proxy issue. Try:
1. A model specifically trained for coding (e.g., Qwen 2.5 Coder)
2. A larger model if you have the RAM
3. Increasing the context length in LM Studio's server settings

## LaunchAgent issues

**Proxy doesn't start at login**

1. Check the plist was installed:

```bash
ls ~/Library/LaunchAgents/com.cdrxyz.litellm-local.plist
```

2. Check the logs:

```bash
cat logs/litellm-proxy.err
```

3. The `{{REPO_DIR}}` placeholder wasn't replaced. Re-install:

```bash
just uninstall-launchd
just install-launchd
```

4. Verify the path in the plist is correct:

```bash
cat ~/Library/LaunchAgents/com.cdrxyz.litellm-local.plist | grep REPO_DIR
# Should show no results (placeholder should be replaced)
```

**Proxy keeps restarting**

This usually means LM Studio isn't running when the proxy starts. Since `KeepAlive` is `true`, launchd will keep trying. Either:
- Start LM Studio first (it should be in your Login Items too)
- Set `KeepAlive` to `false` in the plist if you prefer manual control

## Hermit issues

**Hermit won't bootstrap**

If the `bin/activate` script fails to download Hermit, you may need to install it manually:

```bash
# Download directly
curl -fsSL https://github.com/cashapp/hermit/releases/latest/download/hermit-darwin-arm64 -o bin/hermit
chmod +x bin/hermit
```

For Intel Macs, replace `arm64` with `amd64`.

**Python install fails**

Hermit's Python packages can be large. If the download fails:

```bash
# Clear Hermit cache and retry
rm -rf ~/.cache/hermit
hermit install python@3
```
