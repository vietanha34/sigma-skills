# Compliance Check Workflow

## Inputs

- `run_type`: `am_start_check` | `pm_resume_check` | `eod_check`
- `date`: default today (`Asia/Ho_Chi_Minh`)
- `csv_url`: roster CSV URL (required if roster not embedded)
- `target_hours`: default `7.5`
- `gap_threshold_minutes`: default `75`

## 1) Load roster from CSV URL

1. Resolve `csv_url` from prompt.
2. If missing, ask user for `csv_url` and stop.
3. Download file:
   - `curl -L --fail "<csv_url>"`
4. Detect delimiter (`;` or `,`) from header row.
5. Map columns with aliases:
   - `accountId`: `account_id`, `accountId`, `User id`
   - `displayName`: `display_name`, `name`, `User name`
   - `email` (optional): `email`, `Email address`
   - `active` (optional): `active`, `User status` (`Active` -> true)
6. Drop invalid rows (missing `accountId` or `displayName`) and keep row-level error list.
7. If `active` exists, only keep active users.

## 2) Pull compliance data from `clockwork mcp`

1. Call `get_all_active_timers` once:
   - arguments: `{}`
   - expected shape:
     - `total_accounts`
     - `total_timers`
     - `cached_at`
     - `timers_by_account_id[]` with `account_id` + `timers[]`
2. Build map `activeTimersByAccountId` from `timers_by_account_id`.
3. Compare roster `accountId` against this map to identify:
   - users with active timer(s)
   - users with zero active timers (candidates for `missing_start` / `missing_resume`)
4. Call `get_worklogs` for each roster member for target date:
   - arguments: `{ "account_id": "<accountId>", "from_date": "YYYY-MM-DD", "to_date": "YYYY-MM-DD" }`
5. Optional: call `search_issues` only when issue-key enrichment is needed.

## 3) Exclusion check (Calendar)

1. Match leave/out-of-office by `email` (preferred) or configured calendar identity.
2. If user is out-of-office in the checked window, set `exclusion_reason` and skip violation scoring.

## 4) Compliance scoring

1. `am_start_check`:
   - no timer started by `09:05` -> `missing_start` (`warning`)
2. `pm_resume_check`:
   - no timer resumed by `13:45` -> `missing_resume` (`warning`)
3. `eod_check`:
   - total logged hours `< target_hours` -> `hours_below_target` (`warning`/`high`)
4. Any run type:
   - longest idle gap `> gap_threshold_minutes` in working windows -> `long_idle_gap` (`warning`)

## 5) Output

Emit one structured record per member:

- `date`, `timezone`, `run_type`
- `member`: `displayName`, `accountId`, `email`
- `status`, `violations`, `metrics`
- `exclusion_reason`, `recommended_action`
- `roster_source`, `invalid_roster_rows`
- `timer_snapshot_meta`: `total_accounts`, `total_timers`, `cached_at`

## Failure Handling

- CSV fetch fails: return `roster_fetch_error` with HTTP/tool details.
- CSV schema invalid: return `invalid_roster_schema` with expected columns.
- `get_all_active_timers` fails: retry once, fallback to per-user `get_active_timers` only if explicitly allowed.
- MCP call fails for one user (worklogs/fallback timer call): mark that user `status=unknown`, continue remaining users.
- `clockwork mcp` fails globally: stop with `clockwork_mcp_error`.
