# Log Signals

Use this file when `now.debug`, `now.origin`, or `now.nginx` contains actionable error signals.

If the log line already includes an explicit code such as `(code: INPUT_TIMEOUT)`, also read `error-codes.md`.

## File Roles

- Default log root: `/var/log/sigma-machine`
- `now.debug`: primary sigma-media-server runtime log for active jobs
- `YYYY-MM-DD.debug`: rotated daily job log files; inspect current file first, then previous day once if the failure window crosses rotation
- `now.origin`: Go origin log for manifest and origin-side processing
- `now.nginx`: nginx log for origin serving and HTTP access behavior

## Correlation

- Bracketed IDs like `[uuid-package]` identify a job/session. Keep evidence grouped by the same ID.
- Typical structured worker log format is:
  - `[05-26 02:32:55] Input timeout (code: INPUT_TIMEOUT)`
  - timestamp is UTC
  - middle text is the human-readable message
  - code in parentheses is the normalized reason to use for triage
- A retry sequence often looks like:
  - `Connection ... failed`
  - `Retry`
  - `Starting`
  - `Process started`
- If the same ID shows the same transport failure repeatedly, treat it as one persistent incident, not many unrelated incidents.

## Common Signals

### SRT output/connectivity failure

Example pattern:

- `Connection to srt://... failed: Input/output error`
- `tee ... error opening`
- `Could not write header for output file #0`

Interpretation:

- Most likely an output transport or remote endpoint problem, not an encoder startup problem.
- Check whether the remote SRT listener is reachable and accepting the stream.
- Check whether only one target fails while others continue; that points to a target-side issue.
- If the failure appears immediately after `Process started`, the job starts but cannot establish the output session.

### Retry loop

Pattern:

- `Retry`
- `Starting`
- repeated connection failure within seconds

Interpretation:

- The job manager is attempting automatic recovery.
- If retries continue without a successful steady state, classify as degraded even if the process is repeatedly restarting itself.

### Manifest or origin issue

Look in `now.origin` and `now.nginx` for:

- missing path
- permission denied
- 404/403/5xx around manifest or segment paths

Interpretation:

- Usually origin/nginx/path/config related rather than transcoder-core failure.

### Machine-pressure issue

Pair log spikes with:

- high CPU/RAM/GPU in `dump`
- `task.error > 0`
- app not running in `dump.apps`

Interpretation:

- Prefer machine-level or dependency-level hypothesis over a single-channel hypothesis.

## Triage Order

1. Confirm host and scope with `dump` and `progress`.
2. Read `now.debug` first.
3. Correlate by job/session ID.
4. Open `now.origin` or `now.nginx` only when symptoms point to origin/serving.
5. Widen to the previous rotated `.debug` file once if the timeline crosses rotation.

## Progress Response Hints

- The top-level `result` is a map of runtime jobs, not a flat channel list.
- Common suffixes:
  - `-transcode`: main transcode job
  - `-package`: packaging/output fanout job
  - `-catchup`: timeshift/catchup job
- Use `metadata.name` as the user-facing channel name.
- Use `_id` plus the map key to distinguish related jobs for the same channel.
- Healthy-looking jobs can still have historical `error[]`; check whether the errors are recent and repeated.
- `input.state="empty"` with `showing="blackout"` usually means the channel is alive but not consuming its expected main input.
- `bitrate: 0` on targets is not automatically an error; correlate with `state`, recent errors, and logs before classifying.

## Master Response Hints

- `GET /master` is the fastest whole-server snapshot.
- `#9999` contains one compact line per runtime job.
- Prioritize lines marked with `!`.
- Treat lines marked with `*` as primary jobs worth correlating with related `-package` or `-catchup` jobs.
- Use `master` for shortlist, not final diagnosis; verify with `progress` and logs.

## Dump Response Hints

- `dump` is the authoritative machine snapshot.
- `speed`, `queue`, `total`, and `task.started` are the first four fields to read when deciding whether the host is simply busy or actually degraded.
- Non-zero `system.monitor[].error` is a direct signal that an internal monitor is failing.
- `system.log.folder` tells you the effective log directory; prefer it over defaults when present.
- `system.storage[]` helps explain live/timeshift retention and cleanup behavior.
- `system.gpu[].enc`, `system.gpu[].dec`, `system.gpu[].percent`, and `system.gpu[].count` together describe GPU pressure better than any single field.
- `apps[]` should be checked before blaming channel-level jobs; a missing `origin` or `nginx` process changes the diagnosis quickly.
- Expected steady-state app list usually includes `portal-local`, `nginx`, `prometheus-nginxlog-exporter`, `origin`, and `victoria-metrics`.
- `queue=0`, `task.started=total`, `nats.connected=1`, and `licenseStatus=VALID` are strong healthy-machine signals.
- `licenseStatus` and `nats.connected` are control-plane signals worth calling out when unhealthy.
