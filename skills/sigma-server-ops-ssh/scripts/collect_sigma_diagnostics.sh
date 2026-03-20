#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage:
  $0 --host <host-or-alias> [--channel <channel-name>] [--since 30m] [--lines 200] [--identity-file /path/to/key]

Examples:
  $0 --host prod-media-01
  $0 --host sigma-prod-01 --channel vtv3 --since 2h --lines 400
USAGE
}

HOST=""
CHANNEL=""
SINCE="30m"
LINES="200"
IDENTITY_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host) HOST="${2:-}"; shift 2 ;;
    --channel) CHANNEL="${2:-}"; shift 2 ;;
    --since) SINCE="${2:-}"; shift 2 ;;
    --lines) LINES="${2:-}"; shift 2 ;;
    --identity-file) IDENTITY_FILE="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

if [[ -z "$HOST" ]]; then
  echo "--host is required" >&2
  usage
  exit 2
fi

if [[ ! "$HOST" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "unsupported host or alias format" >&2
  exit 2
fi

if [[ -n "$CHANNEL" && ! "$CHANNEL" =~ ^[A-Za-z0-9_.@:-]+$ ]]; then
  echo "unsupported channel format" >&2
  exit 2
fi

if [[ ! "$SINCE" =~ ^[0-9]+[mhd]$ ]]; then
  echo "--since must look like 30m, 2h, or 1d" >&2
  exit 2
fi

if [[ ! "$LINES" =~ ^[0-9]+$ ]]; then
  echo "--lines must be numeric" >&2
  exit 2
fi

if (( LINES > 1000 )); then
  echo "--lines must be <= 1000" >&2
  exit 2
fi

SSH_OPTS=(
  -o BatchMode=yes
  -o ConnectTimeout=8
  -o IdentitiesOnly=yes
  -o StrictHostKeyChecking=yes
)

if [[ -n "$IDENTITY_FILE" ]]; then
  if [[ ! -f "$IDENTITY_FILE" ]]; then
    echo "identity file not found" >&2
    exit 2
  fi
  SSH_OPTS+=(-i "$IDENTITY_FILE")
fi

ssh "${SSH_OPTS[@]}" "$HOST" bash -s -- "$CHANNEL" "$LINES" <<'RCMD'
set -euo pipefail

channel="$1"
lines="$2"
api_url="http://localhost:9999"
log_dir="/var/log/sigma-machine"

echo "=== host ==="
hostname || true

echo "=== api-health ==="
curl -sS --max-time 10 "$api_url" || true

echo "=== master ==="
curl -sS --max-time 10 "$api_url/master" || true

echo "=== dump ==="
curl -sS --max-time 20 -X POST \
  -H 'Content-Type: application/json' \
  --data '{"type":"dump"}' \
  "$api_url/master" || true

if [[ -n "$channel" ]]; then
  progress_payload=$(printf '{"type":"progress","name":"%s"}' "$channel")
else
  progress_payload='{"type":"progress"}'
fi

echo "=== progress ==="
curl -sS --max-time 20 -X POST \
  -H 'Content-Type: application/json' \
  --data "$progress_payload" \
  "$api_url" || true

echo "=== processes ==="
ps -eo pid,ppid,comm,args | grep -E 'sigma-video|origin|nginx|srs|sigma-client-portal|victoria|promtail' | grep -v grep || true

echo "=== ports ==="
ss -lntp | grep -E ':9999|:8080|:1935|:8019|:9972|:9125|:4040|:9428' || true

echo "=== host-pressure ==="
uptime || true
free -m || true
df -h / || true

echo "=== config-paths ==="
ls -1 /etc/sigma-machine/config 2>/dev/null || true

echo "=== log-files ==="
ls -l "$log_dir" 2>/dev/null | grep -E 'debug|origin|nginx|srs|portal-local|sys|cmd' || true

echo "=== log-now-debug-target ==="
readlink "$log_dir/now.debug" 2>/dev/null || true

echo "=== log-tail-debug ==="
tail -n "$lines" "$log_dir/now.debug" 2>/dev/null || true

echo "=== log-tail-cmd ==="
tail -n "$lines" "$log_dir/now.cmd" 2>/dev/null || true

echo "=== log-tail-sys ==="
tail -n "$lines" "$log_dir/now.sys" 2>/dev/null || true

echo "=== log-tail-origin ==="
tail -n "$lines" "$log_dir/now.origin" 2>/dev/null || true

echo "=== log-tail-nginx ==="
tail -n "$lines" "$log_dir/now.nginx" 2>/dev/null || true

echo "=== log-tail-srs ==="
tail -n "$lines" "$log_dir/now.srs" 2>/dev/null || true

echo "=== log-tail-portal ==="
tail -n "$lines" "$log_dir/now.portal-local" 2>/dev/null || true

echo "=== log-error-summary ==="
grep -Eh 'error|failed|timeout|refused|permission|Could not write header|Retry' \
  "$log_dir"/now.debug "$log_dir"/now.origin "$log_dir"/now.nginx "$log_dir"/now.srs "$log_dir"/now.portal-local 2>/dev/null | tail -n "$lines" || true
RCMD
