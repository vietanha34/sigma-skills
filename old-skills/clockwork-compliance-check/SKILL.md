---
name: clockwork-compliance-check
description: Use when running team timer compliance checks with clockwork mcp tools, including roster intake from CSV URL, missing start/resume detection, idle-gap checks, and end-of-day target validation.
---

# Clockwork Compliance Check

Use this skill to evaluate timer compliance for a team using `clockwork mcp` (not direct REST endpoints).

Working windows (Asia/Ho_Chi_Minh):

- Morning: 08:30-12:00
- Afternoon: 13:30-17:00

## Trigger Phrases

- "run morning timer compliance check"
- "check who has not started timer"
- "check who has not resumed after lunch"
- "find idle gaps longer than 75 minutes"
- "run end of day timer compliance"

## Tools

- `clockwork mcp`:
  - `get_all_active_timers` (required, primary for team-wide timer state)
  - `get_active_timers` (optional fallback)
  - `get_worklogs` (required)
  - `search_issues` (optional)
- Local shell tools for roster intake:
  - `curl` (download CSV roster from URL)
  - `python` or `awk` (CSV parse/validation)
- Calendar MCP (built-in Manus): out-of-office and leave exclusion
- Jira MCP (`sooperset/mcp-atlassian`, optional): enrichment and escalation context

## Preconditions

- `clockwork mcp` is configured and reachable.
- Team roster is fetched from a CSV URL (or provided directly by user).
- Timezone is fixed to `Asia/Ho_Chi_Minh`.
- Compliance policy is Hybrid:
  - Total logged time target per day: default `7.5` hours
  - Idle gap warning threshold: default `75` minutes

## Guardrails

- Ask for `csv_url` if not present in prompt.
- Validate roster schema before running compliance checks.
- Auto-detect CSV delimiter (`;` or `,`); Atlassian exports commonly use `;`.
- Accept Atlassian header aliases:
  - `User id` -> `accountId`
  - `User name` -> `displayName`
  - `User status` -> `active`
- Exclude users with approved leave/out-of-office in the checked window.
- Do not evaluate outside working windows.
- Use `get_all_active_timers` once per run and compare against roster to find missing users.
- Mark user as `unknown` when required source data is missing.
- Return machine-readable output for downstream alert routing.

## Workflow Router

1. Load `references/workflows/compliance-check-workflow.md`.
2. Output records are the required input for `clockwork-alert-router`.

## Output Contract

Return JSON-ready records with these fields:

- `date`
- `timezone`
- `run_type`
- `member`: `displayName`, `accountId`, `email`
- `status`: `compliant` | `warning` | `high` | `unknown`
- `violations`: `missing_start` | `missing_resume` | `hours_below_target` | `long_idle_gap`
- `metrics`: `total_logged_hours`, `longest_idle_gap_minutes`, `first_timer_at`, `last_timer_at`
- `exclusion_reason`
- `recommended_action`: `none` | `email` | `jira_escalation`
- `roster_source`: `csv_url`
- `invalid_roster_rows`
- `timer_snapshot_meta`: `total_accounts`, `total_timers`, `cached_at`

## Failure Handling

- Missing `csv_url`: ask user and stop.
- CSV download/parse failure: return `roster_fetch_error` or `invalid_roster_schema`.
- `get_all_active_timers` failure: retry once, fallback to per-user `get_active_timers` only if fallback is explicitly allowed for this run.
- `clockwork mcp` global failure: return partial result with `clockwork_mcp_error`.
- Calendar unavailable: continue and mark `calendar_unavailable=true`.
