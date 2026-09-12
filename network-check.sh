#!/usr/bin/env bash
#
# network-check.sh
# Assignment 1 - Linux, Bash & Networking
#
# Usage: ./network-check.sh <hostname-or-ip> [port]
#
# - Validates the host argument
# - Resolves the host and displays the resolved address
# - Performs a basic connectivity check
# - Displays network interface information
# - If a port is supplied, checks TCP connectivity to it (valid range 1-65535)
#
# Exit codes:
#   0 - host valid, connectivity (and port check, if requested) succeeded
#   1 - host valid, but connectivity or port check failed (operational failure)
#   2 - invalid input (missing/malformed host, malformed/out-of-range port)

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${LOG_DIR}/network-check.log"

log() {
    mkdir -p "$LOG_DIR"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

usage() {
    echo "Usage: $0 <hostname-or-ip> [port]" >&2
}

HOST="${1:-}"
PORT="${2:-}"

# --- Validate host argument ---
if [[ -z "$HOST" ]]; then
    echo "Error: host argument is required." >&2
    usage
    log "network-check.sh failed: missing host argument"
    exit 2
fi

if ! [[ "$HOST" =~ ^[A-Za-z0-9.:_-]+$ ]]; then
    echo "Error: '$HOST' is not a valid hostname or IP address." >&2
    log "network-check.sh failed: invalid host format '$HOST'"
    exit 2
fi

# --- Validate port argument, if supplied ---
if [[ -n "$PORT" ]]; then
    if ! [[ "$PORT" =~ ^[0-9]+$ ]]; then
        echo "Error: port must be a whole number." >&2
        usage
        log "network-check.sh failed: non-numeric port '$PORT'"
        exit 2
    fi
    if (( PORT < 1 || PORT > 65535 )); then
        echo "Error: port must be between 1 and 65535." >&2
        usage
        log "network-check.sh failed: port '$PORT' out of range"
        exit 2
    fi
fi

echo "===================================="
echo " Network Check: $HOST"
echo "===================================="

STATUS=0

# --- Resolve host ---
RESOLVED=""
if command -v getent >/dev/null 2>&1; then
    RESOLVED=$(getent hosts "$HOST" 2>/dev/null | awk '{print $1}' | head -n1)
elif command -v python3 >/dev/null 2>&1; then
    RESOLVED=$(python3 -c "import socket,sys
try:
    print(socket.gethostbyname(sys.argv[1]))
except Exception:
    pass" "$HOST")
fi

if [[ -n "$RESOLVED" ]]; then
    echo "Resolved Address: $RESOLVED"
    log "network-check.sh resolved '$HOST' -> $RESOLVED"
else
    echo "Resolved Address: could not resolve '$HOST'"
    log "network-check.sh could not resolve '$HOST'"
    STATUS=1
fi

# --- Basic connectivity check ---
if command -v ping >/dev/null 2>&1 && ping -c 1 -W 2 "$HOST" >/dev/null 2>&1; then
    echo "Connectivity    : REACHABLE (ping succeeded)"
    log "network-check.sh ping to '$HOST' succeeded"
else
    echo "Connectivity    : UNREACHABLE (ping failed or blocked)"
    log "network-check.sh ping to '$HOST' failed"
    STATUS=1
fi

# --- Network interface information ---
echo
echo "--- Network Interfaces ---"
if command -v ip >/dev/null 2>&1; then
    ip -brief addr show 2>/dev/null || ip addr show
elif command -v ifconfig >/dev/null 2>&1; then
    ifconfig
else
    echo "No interface tool (ip/ifconfig) available."
fi

# --- Optional TCP port check ---
if [[ -n "$PORT" ]]; then
    echo
    echo "--- Port Check ---"
    if timeout 3 bash -c "echo > /dev/tcp/${HOST}/${PORT}" 2>/dev/null; then
        echo "Port $PORT       : OPEN"
        log "network-check.sh port $PORT on '$HOST' is OPEN"
    else
        echo "Port $PORT       : CLOSED or unreachable"
        log "network-check.sh port $PORT on '$HOST' is CLOSED or unreachable"
        STATUS=1
    fi
fi

echo
echo "===================================="
if [[ "$STATUS" -eq 0 ]]; then
    echo "Overall Status  : OK"
else
    echo "Overall Status  : ISSUES DETECTED"
fi
echo "===================================="

log "network-check.sh completed for '$HOST' with status $STATUS"
exit "$STATUS"