---
name: deploy
description: Build and deploy garmin_api backend and/or frontend. Rebuilds WASM, Docker images, and restarts containers.
argument-hint: [all|api|dash]
---

Build and deploy the Garmin API stack. Target: $ARGUMENTS (default: all).

## Targets

| Argument | What it does |
|----------|-------------|
| `all` (or empty) | Deploy both API backend and dashboard frontend |
| `api` | Backend only: cargo build --release + docker compose up --build |
| `dash` | Frontend only: trunk build --release + docker compose up --build |

## Steps

### API backend
1. `cd /home/mo/data/Documents/git/garmin_api`
2. `cargo build --release`
3. `docker compose up -d --build`
4. Health check: `docker compose exec app wget -qO- http://localhost:3000/health`

### Dashboard frontend
1. `cd /home/mo/data/Documents/git/garmin_api/frontend`
2. `trunk build --release`
3. `docker compose up -d --build`
4. Health check: `docker compose exec app curl -sf http://localhost:80/ | head -1`

## Output

Report container status after deploy:
- `docker compose ps` for each stack
- Health check results
- Any errors encountered

If a build fails, stop and report the error — do not deploy a broken build.
