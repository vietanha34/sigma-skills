---
name: sigma-server-ops-ssh
description: Use when diagnosing sigma-media-server over SSH on remote hosts where the machine API is only reachable locally. Supports localhost API checks for dump and progress, channel-specific checks when a channel name is provided, full-server checks when it is not, and bounded plugin/log triage for origin, nginx, srs, and portal-local.
---

# Sigma Server Ops (SSH)

Use this skill to diagnose `sigma-media-server` by SSHing to the host, querying the local machine API on `localhost:9999`, and then using bounded file/process/config checks only when API evidence is not enough.

## Trigger Phrases

- "check sigma-media-server status"
- "analyze sigma server errors"
- "collect logs from prod server"
- "triage incident on sigma host"
- "check this channel"
- "check origin/nginx/srs on media server"

## Tools

- Local shell with `ssh` access from the client machine.
- Optional `vast-ssh` resolver for host aliases or short-lived sessions.
- `scripts/resolve_credential.sh` for local credential/session setup.
- `scripts/collect_sigma_diagnostics.sh` for deterministic bounded collection.

## When Not to Use

- Do not use for restart, deploy, config edits, or any write operation unless the user asks in a separate step.
- Do not use when the user needs unrestricted shell access.
- Do not use when SSH auth requires interactive passwords or MFA prompts in the middle of the workflow.

## Preconditions

- Target host is explicitly provided by user, or resolved from an approved alias.
- Credential setup is non-interactive and ephemeral where possible.
- Remote user can read:
  - `http://localhost:9999`
  - `/var/log/sigma-machine/*`
  - `/etc/sigma-machine/config/*`
  - process state for sigma apps
- SSH can run with `BatchMode=yes` and `StrictHostKeyChecking=yes`.
- If SSH is not ready, load `references/templates/ssh-prerequisites.md` and guide setup first.

## Inputs

- `host` or approved alias (required)
- `channel` (optional)
- `since` (default `30m`)
- `lines` (default `200`, max `1000`)
- `mode` (`server-health`, `channel-health`, `plugin-triage`, `incident-summary`)

## Guardrails

- Read-only diagnostics only.
- Resolve credentials or sessions without printing secrets to stdout/stderr.
- Never paste raw private keys, passwords, tokens, or session blobs into the conversation.
- Only connect to approved aliases/hosts for the environment.
- Never run restart/kill/write operations unless user explicitly asks in a separate step.
- Never execute free-form remote shell assembled from raw user input.
- Prefer the helper script and bounded command templates over ad hoc SSH commands.
- Use `dump` and `progress` on `localhost:9999` before reading raw logs.
- If the user provides a channel, check only that channel first.
- If the user does not provide a channel, inspect the whole server and identify affected channels from `progress`.
- Always bound collection by time and line count.
- Redact secrets/tokens from output.

## Workflow Router

1. Resolve inputs: `host`, optional `channel`, `since`, `lines`, and `mode`.
2. Resolve access:
   - Prefer `scripts/resolve_credential.sh` or an approved `vast-ssh` session/profile resolver.
   - Accept only a resolved alias, session handle, or short-lived key path.
   - If the resolver prints secret material, stop and report the credential flow as unsafe.
3. Choose workflow:
   - Server health: load `references/workflows/01-quick-health-check.md`.
   - Channel health or root-cause hints: load `references/workflows/02-error-triage.md`.
   - Incident write-up: load `references/workflows/03-incident-summary.md`.
4. Use `scripts/collect_sigma_diagnostics.sh` for deterministic collection when possible.
5. Render the final answer using `references/templates/incident-report-template.md`.

## Operating Model

- The default log directory is `/var/log/sigma-machine`.
- `master` on `http://localhost:9999/master` is the fastest summary endpoint for whole-server scans.
- `dump` from `POST http://localhost:9999/master` with `{"type":"dump"}` is the machine-level truth source:
  - machine resources
  - app states
  - started/error task counts
  - monitor health
  - storage policies
  - log folder and usage
  - license and nats connectivity
- `progress` is the channel-level truth source:
  - channel state
  - speed
  - pts/life
  - errors
  - input/output bitrate
  - `metadata.name` and `metadata.nameModifier` for human channel names
  - `process.pid`, `process.cpu`, `process.ram` for per-job footprint
- log files are supporting evidence:
  - `now.debug` is the main sigma-media-server job log
  - `now.debug` points to a daily rotated file such as `YYYY-MM-DD.debug`
  - `now.cmd` captures command-level activity
  - `now.origin` is the Go origin log for manifest and origin-side processing
  - `now.nginx` is the nginx log for origin serving
  - `now.srs`, `now.portal-local`
  - `now.sys`
- config and process checks are fallback evidence:
  - `/etc/sigma-machine/config/*.yaml`
  - process list and listening ports

## Log Reading Rules

- Assume logs live under `/var/log/sigma-machine` unless the user provides a different path or evidence shows a custom config.
- Start with `now.debug` for active job failures.
- Resolve the `now.debug` symlink to find the active daily file when more context is needed.
- If the issue may have started before midnight or before the current rotation, inspect the previous daily `.debug` file once.
- Treat bracketed IDs like `[c7810be4-fb5a-4898-be13-923f96fd66c7-package]` as job/session correlation keys.
- Use `now.origin` when symptoms involve manifest generation, origin path handling, or upstream origin processing.
- Use `now.nginx` when symptoms involve HTTP serving, manifest fetches, access failures, or origin nginx behavior.
- Use `now.srs` for ingest/session symptoms.
- Read `references/log-signals.md` when logs show transport, retry, manifest, or plugin-specific errors.
- Read `references/error-codes.md` when logs contain `(code: ...)` fields or when you need to map a code to likely input/output/processing/config root cause.

## Progress API Notes

- If a specific channel is provided, call `progress` with `{"type":"progress","name":"<channel>"}` first.
- If no channel is provided, call `progress` with `{"type":"progress"}` and inspect the full `result` map.
- Do not rely only on the job key such as `uuid-package` or `uuid-transcode`; use `metadata.name`, `metadata.nameModifier`, and `_id` to describe channels in the response.
- Treat one business channel as a group of related jobs, for example `*-transcode`, `*-package`, `*-catchup`.
- Prioritize these fields when summarizing channel health:
  - `state`
  - `speed`
  - `pts` vs `life`
  - `error[]`
  - `warn[]`
  - `input[].state`
  - `input[].msg`
  - `process.cpu`, `process.ram`
  - `target[].url`

## Master API Notes

- Use `GET http://localhost:9999/master` for a quick whole-server pass before deeper inspection.
- Treat `#9999` as the compact runtime list.
- Use `master` when the user does not provide a channel, or when you need a fast summary before calling full `progress`.
- Common interpretations from the compact lines:
  - leading `100` or `101` is the current speed percentage
  - duration shows job age
  - `*` usually marks a main transcode job
  - `!` marks a job with recent warnings or errors and should be prioritized
  - the last tokens often indicate output format(s) such as `udp`, `hls`, `rtmp`, `mux`
- Use `master` to shortlist suspicious jobs, then confirm details with `progress` and logs.

## Dump API Notes

- Use `POST http://localhost:9999/master` with `{"type":"dump"}` for the full machine snapshot.
- Prioritize these fields when summarizing machine health:
  - `version`, `branch`, `build`, `start`, `timezone`
  - `total`, `queue`, `task.started`
  - `system.cpu`, `system.thread`, `system.heapUsed`, `system.heapCommit`, `system.heapMax`
  - `system.ramTotal`, `system.ramUsed`, `system.swapUsed`
  - `system.monitor[]` and any non-zero `error`
  - `system.network[]`
  - `system.storage[]`
  - `system.log.folder`, `system.log.used`
  - `system.gpu[].enc`, `system.gpu[].dec`, `system.gpu[].percent`, `system.gpu[].count`
  - `system.process`
  - `apps[]`
  - `nats.connected`, `nats.startup`
  - `licenseStatus`
- Prefer `system.log.folder` over assumptions if it is present in `dump`.
- Treat this `dump` shape as operationally important:
  - `queue=0` and `task.started=total` usually means the scheduler is not obviously backlogged
  - `speed=1.0` at machine level is a healthy baseline, not proof that every channel is healthy
  - `system.gpu[].enc`, `system.gpu[].dec`, `system.gpu[].count`, and `system.gpu[].percent` are stronger capacity signals than raw `gpu` utilization alone
  - `apps[]` should normally include `portal-local`, `nginx`, `prometheus-nginxlog-exporter`, `origin`, and `victoria-metrics`
  - `system.log.folder` is the effective log root and should normally resolve to `/var/log/sigma-machine/`
  - `nats.connected=1` and `licenseStatus=VALID` are expected control-plane signals

## Minimal Response Contract

Always return:

- `Current status`: healthy/degraded/down
- `Scope`: specific channel or whole server
- `Evidence`: 3-10 key API/log/process signals with timestamps or field names
- `Likely cause`: top hypothesis + confidence (low/med/high)
- `Next actions`: safe, ordered, and explicit

## Failure Handling

- SSH unreachable: classify `network/auth` and stop.
- Permission denied: report exact command that failed and required scope.
- Unsafe credential flow: stop and recommend a resolver that returns only alias/session handle/key path.
- Local API unavailable: collect process state, listening ports, and log files, then classify as `api/process/config`.
- No channel found: report the requested channel name, show top available channel names from `progress`, and stop.
