# Assignment 1 — Linux, Bash & Networking

A small Bash-based diagnostic toolkit for Linux systems. It reports system
information, checks disk usage against a threshold, and checks basic network
connectivity to a given host (with an optional port check).

## Contents

- `system-info.sh` — displays hostname, current user, date/time, OS, kernel
  version, uptime, CPU info, memory info, and current working directory.
- `disk-check.sh` — checks disk usage percentage against a threshold.
- `network-check.sh` — validates a host, resolves it, checks connectivity,
  displays network interfaces, and optionally checks a TCP port.
- `logs/` — timestamped log entries written by each script.
- `grade.sh` — instructor-supplied local grading script.

## Installation / Setup

No installation is required beyond a standard Linux environment with `bash`.

```bash
git clone <this-repository-url>
cd assignment-1
chmod +x *.sh
```

**Requirements:** `bash`, and standard coreutils (`hostname`, `whoami`, `date`,
`uname`, `df`, `awk`). `lscpu` and `free` are used for CPU/memory detail with
a fallback to `/proc/cpuinfo` / `/proc/meminfo` if unavailable. `network-check.sh`
uses `getent` for DNS resolution (with a `python3` fallback), `ping` for
connectivity, and `ip`/`ifconfig` for interface listing, whichever is present.

## Usage

**System information:**
```bash
./system-info.sh
```

**Disk usage check:**
```bash
./disk-check.sh <threshold> [path]
# example:
./disk-check.sh 80        # checks / against an 80% threshold
./disk-check.sh 90 /home  # checks /home against a 90% threshold
```
Exit codes: `0` = usage below threshold, `1` = usage at/above threshold,
`2` = invalid input (threshold not 1-100, non-numeric, or bad path).

**Network check:**
```bash
./network-check.sh <hostname-or-ip> [port]
# example:
./network-check.sh localhost
./network-check.sh example.com 443
```
Exit codes: `0` = reachable (and port open, if checked), `1` = unreachable
or port closed, `2` = invalid input (missing host, bad host format, or
port outside 1-65535).

## Testing

Each script was tested manually against both valid and invalid input,
including:

- Missing arguments
- Non-numeric thresholds/ports
- Out-of-range thresholds (0, 101) and ports (0, 65536)
- Valid input against the local machine (`/`, `localhost`)

The instructor-supplied grader can be run with:
```bash
chmod +x grade.sh *.sh
./grade.sh
```

## Assumptions

- The grading/target environment is Linux (GNU coreutils), not macOS/BSD.
- `bash` is available (scripts are not POSIX `sh`-only).
- The user running the scripts has permission to read `/proc`, run `ping`,
  and query DNS; no root privileges are required.
- Default path for `disk-check.sh` is `/` when no path is supplied.
- Log files under `logs/` are append-only and not rotated.