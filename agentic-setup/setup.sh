#!/usr/bin/env bash
# Installs Hermes Agent (Nous Research) and OpenClaw (formerly Clawdbot) on macOS
# using each project's official installer. Both installers provision their own
# runtimes (Python/uv for Hermes, Node 24+ for OpenClaw) and start a setup wizard.
set -euo pipefail

[[ "$(uname -s)" == "Darwin" ]] || { echo "This script is for macOS." >&2; exit 1; }
for cmd in curl git; do
  command -v "$cmd" >/dev/null || { echo "Missing '$cmd'. Run: xcode-select --install" >&2; exit 1; }
done

echo "==> Installing Hermes Agent"
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash

echo "==> Installing OpenClaw"
curl -fsSL https://openclaw.ai/install.sh | bash

echo
echo "Done. Open a new terminal, then verify:"
echo "  hermes doctor"
echo "  openclaw gateway status"
