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
2. `MINIO_PORT` - MinIO S3 API endpoint (also used for `AWS_ENDPOINT_URL`)
3. `MINIO_CONSOLE_PORT` - MinIO web console
4. `MINIO_TEST_PORT` - MinIO test instance

### Allocate and Update .env

```bash
# Find 4 available ports
ports=($(bash scripts/allocate-ports.sh))
SERVER_PORT=${ports[1]}
MINIO_PORT=${ports[2]}
MINIO_CONSOLE_PORT=${ports[3]}
MINIO_TEST_PORT=${ports[4]}

# Update .env with allocated ports
sed -i '' "s|^SERVER_ADDRESS=.*|SERVER_ADDRESS=:${SERVER_PORT}|" .env
sed -i '' "s|^BASE_URL=.*|BASE_URL=http://localhost:${SERVER_PORT}|" .env
sed -i '' "s|^AWS_ENDPOINT_URL=.*|AWS_ENDPOINT_URL=http://localhost:${MINIO_PORT}|" .env
sed -i '' "s|^MINIO_PORT=.*|MINIO_PORT=${MINIO_PORT}|" .env
sed -i '' "s|^MINIO_CONSOLE_PORT=.*|MINIO_CONSOLE_PORT=${MINIO_CONSOLE_PORT}|" .env
sed -i '' "s|^MINIO_TEST_PORT=.*|MINIO_TEST_PORT=${MINIO_TEST_PORT}|" .env
```

**Note:** The `scripts/` directory is part of this skill, not the project repository. Array uses 1-based indexing (zsh).

## Starting Services

After updating `.env`:

```bash
# 1. Start docker-compose (if docker-compose.yml exists)
docker compose up -d

# 2. Start the app with file watching (if Makefile has a watch target)
make watch &
```

Report back to the user with the worktree path and allocated ports:
- App URL: `http://localhost:${SERVER_PORT}`
- MinIO S3: `http://localhost:${MINIO_PORT}`
- MinIO Console: `http://localhost:${MINIO_CONSOLE_PORT}`

## Stopping Services

```bash
bash scripts/shutdown-services.sh
```

This stops docker compose services and kills the app server process by port. **Always stop services before removing a worktree.**
