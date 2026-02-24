# 02. Suggestions If Under 8 Hours

## Goal
Provide multiple ways to close daily worklog gap when total is below 8 hours.

## Inputs
- `gap_seconds`
- `date`
- current user context

## Suggestion Options
1. Existing in-progress issues:
   - Tool: `mcp_mcp-atlassian_jira_search`
   - JQL: `assignee = currentUser() AND statusCategory = "In Progress" ORDER BY updated DESC`
2. Recently active issues (fallback):
   - Tool: `mcp_mcp-atlassian_jira_search`
   - JQL: `updated >= -1d AND (assignee = currentUser() OR worklogAuthor = currentUser()) ORDER BY updated DESC`
3. Create new issue in `TL` and log work:
   - Run `03-create-issue-and-log-work.md`

## User Interaction
Ask user to choose one option and provide duration to log.

## Loop Rule
After any logging action (existing issue or new issue):
1. Re-run `01-review-daily-worklog.md` for the same date.
2. If still `< 8h`, offer suggestions again.
3. Repeat until `>= 8h` or user stops.
