# litellm-local — Justfile
# Task runner for common operations. Requires `just`: https://github.com/casey/just
#
# If you don't have `just`, the commands are simple enough to run directly.

set dotenv-load := false
set quiet := true

# Default: show available recipes
default:
    @just --list

# ── Setup ──────────────────────────────────────────────────────────────

# First-time setup: activate Hermit, install Python, install deps
setup: hermit-install pip-install
    @echo "✓ Setup complete. Run 'just start' to launch the proxy."

# Install Python via Hermit (idempotent)
hermit-install:
    @echo "Installing Python via Hermit..."
    source bin/activate && hermit install python@3

# Install Python dependencies into a venv
pip-install:
    @echo "Installing Python dependencies..."
    source bin/activate
    python3 -m venv .venv
    .venv/bin/pip install --quiet --upgrade pip
    .venv/bin/pip install --quiet -r requirements.txt

# ── Proxy ──────────────────────────────────────────────────────────────

# Start the LiteLLM proxy server (foreground)
start:
    source bin/activate && .venv/bin/litellm --config config.yaml

# Start the proxy in the background
start-bg:
    source bin/activate && .venv/bin/litellm --config config.yaml &; echo "LiteLLM proxy started on http://localhost:4000"

# Stop a background proxy
stop:
    @pkill -f "litellm --config" 2>/dev/null && echo "Proxy stopped." || echo "No running proxy found."

# Check if the proxy is running
status:
    @curl -sf http://localhost:4000/health > /dev/null 2>&1 && echo "✓ Proxy is running on http://localhost:4000" || echo "✗ Proxy is not running"

# ── LaunchAgent (macOS) ───────────────────────────────────────────────

# Install the LaunchAgent for auto-start at login
install-launchd:
    @sed "s|{{REPO_DIR}}|$(pwd)|g" launchd/com.cdrxyz.litellm-local.plist > ~/Library/LaunchAgents/com.cdrxyz.litellm-local.plist
    @launchctl load ~/Library/LaunchAgents/com.cdrxyz.litellm-local.plist 2>/dev/null || true
    @echo "✓ LaunchAgent installed. Proxy will start at login."

# Uninstall the LaunchAgent
uninstall-launchd:
    @launchctl unload ~/Library/LaunchAgents/com.cdrxyz.litellm-local.plist 2>/dev/null || true
    @rm -f ~/Library/LaunchAgents/com.cdrxyz.litellm-local.plist
    @echo "✓ LaunchAgent removed."

# ── Testing ────────────────────────────────────────────────────────────

# Quick test: send a chat completion to the local proxy
test:
    @curl -s http://localhost:4000/v1/chat/completions \
      -H "Content-Type: application/json" \
      -d '{"model":"local-default","messages":[{"role":"user","content":"Say hello in one word."}]}' | python3 -m json.tool

# ── Cleanup ────────────────────────────────────────────────────────────

# Remove the virtual environment
clean:
    rm -rf .venv
    @echo "✓ Cleaned .venv"
