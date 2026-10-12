# Agentic AI setup (macOS)

Installs two open-source agents using their official installers:

- **Hermes Agent**, from Nous Research: https://github.com/NousResearch/hermes-agent
- **OpenClaw** (formerly Clawdbot/Moltbot): https://github.com/openclaw/openclaw

## Run

```bash
./agentic-setup/setup.sh
```

Each installer starts a setup wizard that asks for model API keys (Anthropic,
OpenRouter, etc.). Keys are stored in your home directory, never in this repo.

## Verify

Open a new terminal, then run:

```bash
hermes doctor
openclaw gateway status
```

If OpenClaw's wizard was skipped, run `openclaw onboard --install-daemon`.
If Hermes' was skipped, run `hermes setup`.

## Warning

Both agents can run shell commands and read connected chat apps. Only install them
on a machine where you're comfortable giving an agent that access.
