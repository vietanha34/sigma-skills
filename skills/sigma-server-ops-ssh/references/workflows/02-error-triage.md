# Workflow: Error Triage

Use when a channel is degraded/down, the user asks for root-cause hints, or server-health found affected plugins/channels.

## Inputs

- `host` (required)
- `channel` (optional)
- `since` (default: `30m`, can expand to `2h` once)
- `lines` (default: `400`)

## Steps

1. Resolve access through the approved alias/session flow before opening SSH.
2. Call local API:
   - `master` for a quick shortlist when scanning the whole server
   - `dump` for machine, app, monitor, storage, and log-root state
   - `progress` for the requested channel when `channel` is provided
   - `progress` with only `{"type":"progress"}` when `channel` is absent
3. If a channel is provided:
   - verify the channel exists by matching `metadata.name`, `metadata.nameModifier`, or `_id`
   - inspect all related jobs for that channel, not just one map entry
   - inspect `state`, `speed`, `life`, `pts`, `error`, `warn`, `input`, `target`, `process`
4. If no channel is provided:
   - inspect `master` first and prioritize jobs marked with `!`
   - group jobs by `metadata.name`
   - identify channels in non-healthy states
   - rank by explicit errors, missing bitrate, or stalled progress
5. Read bounded logs from `/var/log/sigma-machine`:
   - `now.debug` first; it is the main sigma-media-server job log
   - resolve the `now.debug` symlink and inspect the current daily `.debug` file
   - inspect the previous daily `.debug` file once if the issue may cross rotation
   - `now.cmd`
   - `now.origin`, `now.nginx`, `now.srs`, `now.portal-local` as indicated by `dump.apps` or symptoms
   - read `references/log-signals.md` for pattern interpretation
   - read `references/error-codes.md` whenever the log includes explicit `(code: XYZ)` values
6. Check failure adjacency:
   - recent app state changes from `dump.apps`
   - repeated failures under the same bracketed job/session ID in `now.debug`
   - dependency hints in logs such as timeout, connection refused, DNS, permission, missing path
   - config references under `/etc/sigma-machine/config/` if a plugin/path issue is suspected
7. If root cause is still unclear, load `references/advanced-tools.md` and use the remote helper tools selectively:
   - `cmd <jobprefix>` to inspect the exact ffmpeg command and real input/output URLs
   - `probe <input>` to inspect stream structure and codec details
   - `pts <input>` to compare first PTS across related inputs
   - `kf <input>` with timeout/line bounds to inspect keyframe cadence for async issues
   - `logd` or `log` helpers when raw file paths or rotation handling are inconvenient
8. Rank hypotheses:
   - H1 most likely + reason
   - H2 fallback + reason
9. Decide next safe action:
   - widen logs once, compare another host, verify dependency health, inspect path/manifest, escalate.

## Heuristics

- Channel issue indicators: `state != started`, `speed < 1`, `pts` not advancing, repeated `error[]`, missing target bitrate.
- Channel issue indicators: `state != started`, `speed < 1`, `pts` not advancing, repeated `error[]`, repeated `warn[]`, `input.state=empty`, `showing=blackout`, or `input.msg` reporting immediate exit/timeout.
- Machine issue indicators: high CPU/RAM, GPU saturation, `task.error > 0`, critical app not running.
- Machine issue indicators: high CPU/RAM, sustained queue growth, `task.started < total`, high GPU `percent` plus high encoder `count`, non-zero `system.monitor[].error`, invalid `licenseStatus`, or disconnected `nats`.
- Plugin issue indicators:
  - `origin`: manifest/path/content issues
  - `nginx`: serving or access-log/error-log symptoms
  - `srs`: ingest/session symptoms
  - `portal-local`: UI/API wrapper symptoms while engine is still alive
- Transport issue indicators:
  - `Connection to srt://... failed: Input/output error`
  - `tee ... error opening`
  - `Could not write header for output file`
  These usually point to remote target connectivity/output failure rather than transcoder startup failure.
- Config/path issue indicators: missing file/path or permission errors in logs near the first failure.

## Output

- Top 3 error signatures or API anomalies with timestamps/fields.
- Root-cause hypothesis with confidence.
- Explicit next actions with expected signal to confirm/refute.
