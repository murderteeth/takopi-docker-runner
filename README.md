# Takopi Docker Runner

Generic base image for Telegram t-bots built on released
[Takopi](https://github.com/banteg/takopi): node + python toolchains, the
agent CLIs (codex, claude, opencode, pi), and a compose service definition.

**This repo is build-only.** No bot runs from this checkout. Each live bot is
a sibling *instance repo* that overlays this image with its own Dockerfile,
compose project, and private `home/` / `workspace/` state:

- [../safe-review-bot](../safe-review-bot) — signing reviews for the yearn
  strategist multisigs
- [../section9-bot](../section9-bot) — the Section9 bot (glasswing)

To create a new bot, use the **create-t-bot** skill in this repo
(`.claude/skills/create-t-bot`, also linked for codex) — it scaffolds an
instance repo and walks through Telegram/bootstrap setup.

## Layout

- `docker/` — Dockerfile and the build-only compose service.
- `home/`, `workspace/` — empty placeholders. Instance repos have the real
  ones; nothing stateful belongs in this checkout.
- `.env.example` — placeholder for optional future local knobs. Do not store
  secrets in git.

## Build

```sh
docker compose -f docker/compose.yml build
```

Instance images build `FROM takopi-docker-runner:latest`, so build this one
first.

## Upgrade

Rebuild to pick up the latest released Takopi and agent CLIs, then rebuild
each instance image and restart its container:

```sh
docker compose -f docker/compose.yml build --pull --no-cache
# then, per instance repo:
#   docker compose -f docker/compose.yml build && docker compose -f docker/compose.yml up -d
```

## Ad-hoc shell

```sh
docker compose -f docker/compose.yml run --rm takopi bash
```

Useful for poking at the base image (`takopi --version`, `takopi doctor`).
Don't run takopi onboarding or agent logins here — that state belongs in an
instance repo's `home/`.

## History

Until 2026-07-07 the Section9 bot ran directly from this checkout's untracked
`home/` and `workspace/`. That deployment now lives in
[../section9-bot](../section9-bot).
