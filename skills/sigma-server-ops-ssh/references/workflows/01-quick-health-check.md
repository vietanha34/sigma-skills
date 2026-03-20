# Workflow: Server Health Check

Use when the user asks whether the media server is healthy, or when no specific channel is provided.

## Inputs

- `host` (required)
- `since` (default: `15m`)
- `lines` (default: `200`)

## Steps

1. Resolve access through the approved alias/session flow before opening SSH.
2. Call local machine API `master` on `localhost:9999/master` for a fast server-wide summary.
3. If `master` responds:
   - inspect `#9999`
   - prioritize lines marked with `!`
   - note lines marked with `*` as main jobs
4. Call local machine API `dump` on `POST localhost:9999/master` with `{"type":"dump"}`.
5. Inspect:
   - `speed`, `queue`, `total`, `task.started`
   - `system.cpu`, `system.thread`, `system.ramUsed`, `system.swapUsed`
   - `system.gpu[].enc`, `system.gpu[].dec`, `system.gpu[].count`, `system.gpu[].percent`, `system.gpu[].used`
   - `apps[].state`
   - `system.monitor[].error`
   - `system.log.folder`, `system.log.used`
   - `system.storage[]`
   - `nats.connected`, `licenseStatus`
6. When summarizing `dump`, prefer these interpretations:
   - `queue > 0` means pending work or scheduler pressure
   - `task.started < total` means not all expected jobs are active
   - high GPU `enc` plus high `count` is normal when the box is busy; call it degraded only if it coincides with channel errors, queue buildup, or monitor failures
   - missing or non-running `origin`/`nginx` means HLS-origin symptoms are likely machine/app-level, not channel-only
   - non-zero `swapUsed` is worth noting but is not enough alone to classify down
7. Call `progress` without channel filter using `{"type":"progress"}` to assess channel population and spot obvious failures.
8. Group related jobs by `metadata.name` and note channels with:
   - non-empty `error[]`
   - `input.state != normal`
   - `state != started`
   - suspicious `pts` drift
9. If `master`, `dump`, or `progress` is unavailable, check:
   - process list for `sigma-video`, `nginx`, `srs`, `origin`, `sigma-client-portal`
   - listening ports `9999`, `8080`, `1935`, `8019`, `9972`, `9125`
   - `/var/log/sigma-machine/now.sys` and `/var/log/sigma-machine/now.debug`
10. Classify:

- `healthy`: API responds, apps needed are running, no major task/channel errors
- `degraded`: API responds but app failures, channel errors, or high resource pressure exist
- `down`: API unavailable or critical apps/processes are missing

## Output

- One-line status summary.
- 3-5 strongest evidence points from `dump`, `progress`, and fallback checks.
- Suggested next workflow (`02-error-triage.md` if degraded/down).
