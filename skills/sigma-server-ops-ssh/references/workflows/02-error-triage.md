# Workflow: Error Triage

Use when the service is degraded/down, or user asks for root-cause hints.

## Inputs
- `host` (required)
- `service` (default: `sigma-media-server`)
- `since` (default: `30m`, can expand to `2h` once)

## Steps
1. Collect logs with bounded window:
   - `journalctl -u <service> --since "<since>" --no-pager -n 800`
2. Extract repeated error signatures (same pattern appears >= 3 times).
3. Check failure adjacency:
   - deploy/restart markers around first failure timestamp
   - dependency errors (DB, Redis, network timeout, DNS, permission)
4. Rank hypotheses:
   - H1 most likely + reason
   - H2 fallback + reason
5. Decide next safe action:
   - widen logs once, compare another host, verify dependency health, escalate.

## Heuristics
- Restart loop indicators: frequent "Started" + crash traces.
- Resource issue indicators: OOM/ENOSPC/timeout spikes near failures.
- Config/permission indicators: startup errors immediately after deploy/restart.

## Output
- Top 3 error signatures with timestamps.
- Root-cause hypothesis with confidence.
- Explicit next actions with expected signal to confirm/refute.
