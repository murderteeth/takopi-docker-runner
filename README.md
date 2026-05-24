# Takopi Docker Runner

Docker-based runtime for using released Takopi without tying runtime state to the Takopi source checkout.

This repository versions only the image, Compose config, documentation, and examples. Local runtime state is private and persistent in `home/`; checked-out projects or working files belong in `workspace/`.

## Layout

- `docker/` - Dockerfile and Compose service.
- `home/` - ignored persistent container home. Takopi config, Telegram state, and agent CLI auth live here.
- `workspace/` - ignored workspace for target repos or files mounted at `/workspace`.
- `.env.example` - placeholder for optional future local knobs. Do not store secrets in git.

## Build

```sh
docker compose -f docker/compose.yml build
```

## First Setup

Open an interactive shell:

```sh
docker compose -f docker/compose.yml run --rm takopi bash
```

Inside the container, log in to whichever agent CLIs you want to use:

```sh
codex
claude
opencode
pi
```

Then run Takopi onboarding:

```sh
takopi
```

The wizard writes config to `/home/takopi/.takopi/takopi.toml`, which persists in local `home/` along with Telegram state and CLI auth.

## Run

Start Takopi in the foreground:

```sh
docker compose -f docker/compose.yml up takopi
```

Start Takopi in the background:

```sh
docker compose -f docker/compose.yml up -d takopi
```

Open an interactive shell in the running background container:

```sh
docker compose -f docker/compose.yml exec takopi bash
```

Use this to log in to agent CLIs or rerun Takopi onboarding against the
persistent `/home/takopi` state:

```sh
codex
claude
opencode
pi
takopi
```

View logs:

```sh
docker compose -f docker/compose.yml logs -f takopi
```

## Stop

Stop the service:

```sh
docker compose -f docker/compose.yml stop takopi
```

Stop and remove the container:

```sh
docker compose -f docker/compose.yml down
```

## Upgrade

Rebuild the image to pick up the latest released Takopi and agent CLIs:

```sh
docker compose -f docker/compose.yml build --pull --no-cache
docker compose -f docker/compose.yml up -d takopi
```

## Useful Checks

```sh
docker compose -f docker/compose.yml run --rm takopi takopi --version
docker compose -f docker/compose.yml run --rm takopi takopi doctor
docker compose -f docker/compose.yml run --rm takopi takopi config list
```
