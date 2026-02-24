# Workflow: Quick Health Check

Use when the user asks "server/service đang ổn không" or wants a fast first-pass.

## Inputs
- `host` (required)
- `service` (default: `sigma-media-server`)
- `since` (default: `15m`)

## Steps
1. Run bounded status checks:
   - `systemctl is-active <service>`
   - `systemctl show <service> -p SubState -p ActiveEnterTimestamp -p ExecMainStatus --no-pager`
2. Collect short recent logs:
   - `journalctl -u <service> --since "<since>" --no-pager -n 200`
3. Check host pressure signals:
   - `uptime`
   - `df -h /`
   - `free -m`
4. Classify:
   - `healthy`: active + no repeating errors
   - `degraded`: active + frequent warnings/errors or high resource pressure
   - `down`: inactive/failed

## Output
- One-line status summary.
- 3-5 strongest evidence points.
- Suggested next workflow (`02-error-triage.md` if degraded/down).
