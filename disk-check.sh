#!/usr/bin/env bash
#
# disk-check.sh
# Assignment 1 - Linux, Bash & Networking
#
# Usage: ./disk-check.sh <threshold> [path]
#   threshold : integer 1-100 (percent)
#   path      : filesystem path to check (default: /)
#
# Exit codes:
#   0 - usage is below threshold
#   1 - usage is at or above threshold
#   2 - invalid input (bad threshold, bad path, missing args)

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${LOG_DIR}/disk-check.log"

log() {
    mkdir -p "$LOG_DIR"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

usage() {
    echo "Usage: $0 <threshold 1-100> [path]" >&2
}

THRESHOLD="${1:-}"
PATH_ARG="${2:-/}"

# --- Validate threshold ---
if [[ -z "$THRESHOLD" ]]; then
    echo "Error: threshold is required." >&2
    usage
    log "disk-check.sh failed: missing threshold argument"
    exit 2
fi

if ! [[ "$THRESHOLD" =~ ^[0-9]+$ ]]; then
    echo "Error: threshold must be a whole number." >&2
    usage
    log "disk-check.sh failed: non-numeric threshold '$THRESHOLD'"
    exit 2
fi

if (( THRESHOLD < 1 || THRESHOLD > 100 )); then
    echo "Error: threshold must be between 1 and 100." >&2
    usage
    log "disk-check.sh failed: threshold '$THRESHOLD' out of range"
    exit 2
fi

# --- Validate path ---
if [[ ! -e "$PATH_ARG" ]]; then
    echo "Error: path '$PATH_ARG' does not exist." >&2
    log "disk-check.sh failed: path '$PATH_ARG' does not exist"
    exit 2
fi

# --- Get disk usage percentage for the path ---
USAGE=$(df -P "$PATH_ARG" | awk 'NR==2 {gsub("%","",$5); print $5}')

if ! [[ "$USAGE" =~ ^[0-9]+$ ]]; then
    echo "Error: unable to determine disk usage for '$PATH_ARG'." >&2
    log "disk-check.sh failed: could not parse df output for '$PATH_ARG'"
    exit 2
fi

echo "Path            : $PATH_ARG"
echo "Threshold       : ${THRESHOLD}%"
echo "Disk Usage      : ${USAGE}%"

log "disk-check.sh checked '$PATH_ARG': usage=${USAGE}% threshold=${THRESHOLD}%"

if (( USAGE >= THRESHOLD )); then
    echo "Status          : ALERT - usage has reached or exceeded the threshold"
    log "disk-check.sh ALERT: usage ${USAGE}% >= threshold ${THRESHOLD}%"
    exit 1
else
    echo "Status          : OK - usage is below the threshold"
    log "disk-check.sh OK: usage ${USAGE}% < threshold ${THRESHOLD}%"
    exit 0
fi