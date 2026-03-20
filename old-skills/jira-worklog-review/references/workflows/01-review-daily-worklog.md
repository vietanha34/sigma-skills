# 01. Review Daily Worklog

## Goal

Compute total worklog for a target date and identify whether user is below 8 hours.

## Inputs

- `date` in `YYYY-MM-DD` (default: today)
- `user` (prefer `currentUser()` in JQL)

## Steps

1. Search issues that contain worklogs for the date/user:
   - Tool: `mcp_mcp-atlassian_jira_search`
   - JQL: `worklogDate = "YYYY-MM-DD" AND worklogAuthor = currentUser()`
   - Fields: `summary,status,worklog`
2. For each issue, fetch full worklogs if embedded worklog data is partial:
   - Tool: `mcp_mcp-atlassian_jira_get_worklog`
3. Filter logs:
   - Match `started` date with target `date`
   - Match author with current user
4. Sum `timeSpentSeconds` and convert to hours/minutes.
5. Output:
   - total logged
   - gap to 8h (if any)
   - issue-level breakdown

## Decision

- If `total >= 8h`: stop and report success.
- If `total < 8h`: continue with `02-suggestions-under-8h.md`.
