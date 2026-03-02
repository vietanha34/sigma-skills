# 02. Suggestions If Under 8 Hours

## Goal
Provide multiple ways to close daily worklog gap when total is below 8 hours.

## Inputs
- `gap_seconds`
- `date`
- current user context

## Suggestion Options
1. **In-progress & Recent**:
   - Find issues in progress updated recently (today/yesterday).
   - Tool: `mcp_mcp-atlassian_jira_search`
   - JQL: `assignee = currentUser() AND statusCategory = "In Progress" AND updated >= -1d ORDER BY updated DESC`

2. **Worked on Today**:
   - Find issues where user already logged work today (to add more time).
   - Tool: `mcp_mcp-atlassian_jira_search`
   - JQL: `worklogAuthor = currentUser() AND worklogDate >= startOfDay() ORDER BY updated DESC`

3. **Short-term Todos**:
   - Find assigned issues due soon (e.g. next 3 days) or overdue recently.
   - Tool: `mcp_mcp-atlassian_jira_search`
   - JQL: `assignee = currentUser() AND statusCategory != Done AND duedate >= -1d AND duedate <= 3d ORDER BY duedate ASC`

4. **Create new issue in `TL`**:
   - Run `03-create-issue-and-log-work.md`

## User Interaction
Ask user to choose one option and provide duration to log.

## Loop Rule
After any logging action (existing issue or new issue):
1. Re-run `01-review-daily-worklog.md` for the same date.
2. If still `< 8h`, offer suggestions again.
3. Repeat until `>= 8h` or user stops.
