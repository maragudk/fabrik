#!/usr/bin/env bash
# Pick a random file from the project directory.

set -euo pipefail

find . -not -path './.git/*' -type f \
  | awk -v seed="$RANDOM" 'BEGIN{srand(seed)} {lines[NR]=$0} END{print lines[int(rand()*NR)+1]}'
