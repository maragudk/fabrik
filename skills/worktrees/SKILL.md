---
name: worktrees
description: Project-specific worktree setup for applications with services (port allocation, service startup/shutdown). Use alongside Claude Code's built-in worktree support when the project runs web servers, docker-compose, or other services that need unique ports per worktree.
license: MIT
---

# Worktrees for Applications with Services

Claude Code has built-in worktree support (`--worktree`, `EnterWorktree`, `isolation: "worktree"`) that handles creating worktrees, branch management, cleanup, and copying gitignored files (via `.worktreeinclude`).

This skill covers the **project-specific** parts: allocating ports, starting services, and stopping them -- so multiple worktrees can run the same app in parallel without port conflicts.

## When to Use This Skill

Use these instructions after entering a worktree **only if**:
- The project has `.env*` files (should be listed in `.worktreeinclude` so they get copied automatically)
- The project runs services like web servers, databases, or docker-compose

If the project is a library or CLI tool without services, skip this entirely.

## Port Allocation

To avoid conflicts when running multiple instances, each worktree needs its own set of ports.

### Required Ports

Allocate 4 available ports for:
1. `SERVER_ADDRESS` - Main HTTP server port (also used for `BASE_URL`)
2. `VERSITYGW_PORT` - versitygw S3 API endpoint (also used for `AWS_ENDPOINT_URL`)
3. `VERSITYGW_WEBUI_PORT` - versitygw web UI
4. `VERSITYGW_TEST_PORT` - versitygw test instance

### Allocate and Update .env

All variables go in `.env`. Docker compose reads the project-directory `.env` for `${VAR:-default}` substitution in `docker-compose.yml` (port mappings). Do NOT put the `VERSITYGW_*` vars in `.env.docker` -- that file is an `env_file` for the *container's* environment and has no effect on port mappings; the containers would silently bind the default ports (7070-7072) and conflict with other worktrees or the main checkout.

The `VERSITYGW_*` vars are usually absent from `.env` (the compose defaults cover the main checkout), so set-or-append rather than sed-replace:

```bash
# Find 4 available ports
ports=($(bash scripts/allocate-ports.sh))
SERVER_PORT=${ports[1]}
VERSITYGW_PORT=${ports[2]}
VERSITYGW_WEBUI_PORT=${ports[3]}
VERSITYGW_TEST_PORT=${ports[4]}

# Replace a var in .env, or append it if absent
set_env() {
  if grep -q "^$1=" .env; then
    sed -i '' "s|^$1=.*|$1=$2|" .env
  else
    echo "$1=$2" >> .env
  fi
}

set_env SERVER_ADDRESS ":${SERVER_PORT}"
set_env BASE_URL "http://localhost:${SERVER_PORT}"
set_env AWS_ENDPOINT_URL "http://localhost:${VERSITYGW_PORT}"
set_env VERSITYGW_PORT "${VERSITYGW_PORT}"
set_env VERSITYGW_WEBUI_PORT "${VERSITYGW_WEBUI_PORT}"
set_env VERSITYGW_TEST_PORT "${VERSITYGW_TEST_PORT}"
```

**Note:** The `scripts/` directory is part of this skill, not the project repository. Array uses 1-based indexing (zsh).

If the project's `.env` contains stale `MINIO_*` vars (the app template used MinIO before switching to versitygw), nothing reads them -- ignore or remove them.

## Starting Services

After updating `.env`:

```bash
# 1. Start docker-compose (if docker-compose.yml exists)
docker compose up -d

# 2. Start the app with file watching (if Makefile has a watch target)
make watch &
```

After `docker compose up -d`, verify the port mappings took effect (substitution silently falls back to defaults if the vars aren't in `.env`):

```bash
docker ps --format '{{.Names}}\t{{.Ports}}'
```

Report back to the user with the worktree path and allocated ports:
- App URL: `http://localhost:${SERVER_PORT}`
- versitygw S3: `http://localhost:${VERSITYGW_PORT}`
- versitygw web UI: `http://localhost:${VERSITYGW_WEBUI_PORT}`

## Stopping Services

```bash
bash scripts/shutdown-services.sh
```

This stops docker compose services and kills the app server process by port. **Always stop services before removing a worktree.**
