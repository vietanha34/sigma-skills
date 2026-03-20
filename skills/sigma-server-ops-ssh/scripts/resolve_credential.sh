#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  resolve_credential.sh --target <approved-alias> [--profile <profile>]

Purpose:
  Resolve an SSH target or ephemeral key path without printing secret material.

Environment:
  One of the following must already be prepared by the operator environment:
  - VAST_SSH_ALIAS_<TARGET>
  - VAST_SSH_KEY_PATH_<TARGET>

Examples:
  resolve_credential.sh --target sigma-prod-01
  resolve_credential.sh --target media-stg-01 --profile prod-readonly
USAGE
}

TARGET=""
PROFILE="default"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="${2:-}"; shift 2 ;;
    --profile) PROFILE="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

if [[ -z "$TARGET" ]]; then
  echo "--target is required" >&2
  usage
  exit 2
fi

if [[ ! "$TARGET" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "target contains unsupported characters" >&2
  exit 2
fi

alias_var="VAST_SSH_ALIAS_${TARGET//-/_}"
key_var="VAST_SSH_KEY_PATH_${TARGET//-/_}"

resolved_alias="${!alias_var-}"
resolved_key="${!key_var-}"

if [[ -n "$resolved_alias" ]]; then
  printf 'mode=alias\n'
  printf 'profile=%s\n' "$PROFILE"
  printf 'target=%s\n' "$TARGET"
  printf 'ssh_alias=%s\n' "$resolved_alias"
  exit 0
fi

if [[ -n "$resolved_key" ]]; then
  if [[ ! -f "$resolved_key" ]]; then
    echo "resolved key path does not exist" >&2
    exit 1
  fi

  printf 'mode=key_path\n'
  printf 'profile=%s\n' "$PROFILE"
  printf 'target=%s\n' "$TARGET"
  printf 'identity_file=%s\n' "$resolved_key"
  exit 0
fi

echo "no approved credential mapping found for target: $TARGET" >&2
exit 1
