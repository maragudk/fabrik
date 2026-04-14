#!/usr/bin/env bash
# Pick a random file from the project directory.
# Excludes hidden directories (.git, .claude, etc.) and binary files.

set -euo pipefail

find . \
  -not -path '*/.*' \
  -not -path '*/node_modules/*' \
  -not -path '*/vendor/*' \
  -type f \
  | awk -v seed="$RANDOM" 'BEGIN{srand(seed)} {lines[NR]=$0} END{print lines[int(rand()*NR)+1]}'
