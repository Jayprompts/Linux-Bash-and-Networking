#!/usr/bin/env bash
#
# system-info.sh
# Assignment 1 - Linux, Bash & Networking
#
# Displays hostname, current user, date/time, operating system, kernel
# version, uptime, CPU information, memory information, and current
# working directory. Every value is read live at runtime.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${LOG_DIR}/system-info.log"

log() {
    mkdir -p "$LOG_DIR"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

log "system-info.sh started"

echo "===================================="
echo " System Information"
echo "===================================="

echo "Hostname        : $(hostname)"
echo "Current User    : $(whoami)"
echo "Date/Time       : $(date '+%Y-%m-%d %H:%M:%S')"

if [ -f /etc/os-release ]; then
    OS_NAME=$(. /etc/os-release && echo "$PRETTY_NAME")
else
    OS_NAME=$(uname -s)
fi
echo "Operating System: ${OS_NAME}"

echo "Kernel Version  : $(uname -r)"
echo "Uptime          : $(uptime -p 2>/dev/null || uptime)"

echo
echo "--- CPU Information ---"
if command -v lscpu >/dev/null 2>&1; then
    lscpu | grep -E 'Model name|CPU\(s\)|Architecture'
else
    grep -m1 'model name' /proc/cpuinfo
    echo "CPU(s): $(grep -c ^processor /proc/cpuinfo)"
fi

echo
echo "--- Memory Information ---"
if command -v free >/dev/null 2>&1; then
    free -h
else
    grep -E 'MemTotal|MemFree|MemAvailable' /proc/meminfo
fi

echo
echo "Current Working Directory: $(pwd)"

log "system-info.sh completed successfully"

exit 0