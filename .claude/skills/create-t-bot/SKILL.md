---
name: create-t-bot
description: Scaffold and deploy a new Telegram t-bot as a sibling instance repo overlaying the takopi-docker-runner base image. Use when asked to create a new t-bot, takopi bot, or telegram agent bot on this host.
---

# Create a t-bot

A **t-bot** is a Telegram bot that runs coding agents (codex/claude) via
[takopi](https://github.com/banteg/takopi), deployed as a docker container.
This skill scaffolds a new one from the generic base image in this repo.

## Architecture — two tiers

1. **Base** (this repo, `takopi-docker-runner`): the generic image — takopi,
   agent CLIs, toolchains. Build-only; no bot runs from this checkout.
2. **Instance repo** (`../<bot-name>/`): one per bot. Deployment harness —
   Dockerfile overlay, compose project, bootstrap, and the *untracked* live
   state (`home/`, `workspace/`). Local git repo, **no remote by default**:
   it sits next to credential dirs and matters only to this host.

What the bot actually works with — checkouts in `workspace/git/`, takopi
project registration — is ordinary takopi usage, out of scope here.

Reference instances to crib from: `../section9-bot` (minimal, no-op overlay),
`../safe-review-bot` (overlay with extra tooling, reports chat, state file).

## Scaffold

Create `/root/git/<bot-name>/` with this layout. Always give the bot its own
Dockerfile overlay, even when it adds nothing yet — it costs nothing (all
layers shared with the base) and gives the bot a slot for its own layers
without restructuring later.

```
<bot-name>/
├── .gitignore            home/* !home/.gitkeep  workspace/* !workspace/.gitkeep  .env
├── .env.example          documented placeholders, no secrets
├── README.md             what the bot does, layout, setup, operations
├── docker/
│   ├── Dockerfile        overlay (template below)
│   └── compose.yml       compose service (template below)
├── bootstrap/
│   └── setup.sh          one-time workspace setup (template below)
├── home/.gitkeep
└── workspace/.gitkeep
```

`docker/Dockerfile`:

```dockerfile
# Concrete overlay on the generic takopi runner image.
# Build takopi-docker-runner first:
#   docker compose -f ../takopi-docker-runner/docker/compose.yml build
FROM takopi-docker-runner:latest

# Bot-specific tooling goes here. Two base-image constraints:
#  - install system-wide (USER root, then USER takopi): /home/takopi is
#    shadowed by the volume mount at runtime
#  - `uv python install <ver>` must run as root, then
#    `chown -R takopi:takopi /opt/uv` (the uv registry has root-owned files)

WORKDIR /workspace
```

`docker/compose.yml` — the project name and service name are the bot name;
everything else is convention (host networking + explicit DNS work around
docker DNS issues on this host; `restart: unless-stopped` survives reboots):

```yaml
name: <bot-name>

services:
  <bot-name>:
    build:
      context: .
      dockerfile: Dockerfile
      network: host
    image: <bot-name>:latest
    restart: unless-stopped
    network_mode: host
    stdin_open: true
    tty: true
    working_dir: /workspace
    volumes:
      - ../home:/home/takopi
      - ../workspace:/workspace
      - ../bootstrap:/bootstrap:ro
    env_file:
      - path: ../.env
        required: false
    environment:
      HOME: /home/takopi
      TERM: xterm-256color
    dns:
      - 1.1.1.1
      - 8.8.8.8
    command: takopi
```

`bootstrap/setup.sh` — idempotent, runs inside the container. Whatever this
bot's workspace needs before first run: repo checkouts, deps, gh auth
(`gh auth setup-git` if GH_TOKEN is in .env), runtime skills versioned in
`bootstrap/skills/` and copied into place. Always end by echoing the manual
steps that can't be scripted:

```bash
echo "bootstrap complete. remaining manual steps in an interactive shell:"
echo "  1. codex / claude       # agent logins"
echo "  2. takopi               # onboarding: NEW bot token, ops chat"
```

## Telegram setup (user does this part)

- **Fresh BotFather token per bot, always.** Two takopi processes long-polling
  one token clash on `getUpdates`; never reuse another bot's token.
- Create a group for the bot; enable topics if the bot separates concerns
  (e.g. a Cron topic for scheduled trigger messages, a Reports topic the
  agent posts into via plain Bot API `sendMessage` — which does NOT conflict
  with takopi's long-poll).
- **No daemons or pollers.** The scheduler is Telegram itself: recurring
  scheduled messages in the ops chat ("check for new X") wake takopi, which
  runs the agent. Cadence is controlled from the phone, not from cron.

## Deploy

```sh
docker compose -f ../takopi-docker-runner/docker/compose.yml build   # base
docker compose -f docker/compose.yml build                          # overlay
docker compose -f docker/compose.yml run --rm <bot-name> bash /bootstrap/setup.sh
docker compose -f docker/compose.yml run --rm <bot-name> bash       # logins (above)
docker compose -f docker/compose.yml up -d
docker compose -f docker/compose.yml logs -f                        # verify long-poll
```

Verify: logs show `startup.sent` with the ops chat id, and a test message in
the chat gets a response.

## Host conventions and costs

- Instance repos live flat under `/root/git/`, named `<purpose>-bot` or
  similar. Don't collide with existing repo names (`section9` vs `section9-bot`).
- A new bot costs ~100–200 MiB idle RAM, ~0% idle CPU, and only its overlay
  layers on disk (an empty overlay is free — all 3.5 GB of base layers are
  shared).
- Agent auth lives in the instance's `home/` and expires eventually; when a
  scheduled run fails on auth, re-login via
  `docker compose -f docker/compose.yml exec <bot-name> <agent-cli>`.
- Upgrades: rebuild base (`--pull --no-cache`), rebuild overlay, `up -d`.
- Never commit `home/`, `workspace/`, or `.env`; check `git status` after the
  initial commit to confirm the gitignore is doing its job.
