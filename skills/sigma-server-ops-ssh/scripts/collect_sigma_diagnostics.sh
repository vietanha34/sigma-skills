#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage:
  $0 --host <host> [--service sigma-media-server] [--since 30m] [--lines 400]

Examples:
  $0 --host prod-media-01
  $0 --host 10.10.1.25 --service sigma-media-server --since 2h --lines 800
USAGE
}

HOST=""
SERVICE="sigma-media-server"
SINCE="30m"
LINES="400"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host) HOST="${2:-}"; shift 2 ;;
    --service) SERVICE="${2:-}"; shift 2 ;;
    --since) SINCE="${2:-}"; shift 2 ;;
    --lines) LINES="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

if [[ -z "$HOST" ]]; then
  echo "--host is required" >&2
  usage
  exit 2
fi

SSH_OPTS=(
  -o BatchMode=yes
  -o ConnectTimeout=8
  -o StrictHostKeyChecking=accept-new
)

remote_cmd=$(cat <<RCMD
set -euo pipefail

echo "=== host ==="
hostname || true

echo "=== service-active ==="
systemctl is-active "$SERVICE" || true

echo "=== service-state ==="
systemctl show "$SERVICE" -p SubState -p ActiveEnterTimestamp -p ExecMainStatus --no-pager || true

echo "=== logs ==="
journalctl -u "$SERVICE" --since "$SINCE ago" --no-pager -n "$LINES" || true

echo "=== host-pressure ==="
uptime || true
free -m || true
df -h / || true
RCMD
)

ssh "${SSH_OPTS[@]}" "$HOST" "$remote_cmd"
