---
name: clockwork-alert-router
description: Use when routing Clockwork compliance violations into notification actions across email and Jira, with cooldown, escalation rules, and repeat-violation handling.
---

# Clockwork Alert Router

Use this skill to convert compliance violations into concrete notification and escalation actions.

Current channel policy:

- Google Chat is disabled for now.
- Primary channels are Gmail and Jira.

## Trigger Phrases

- "route compliance alerts"
- "send timer violation notifications"
- "escalate repeated missing timer cases"
- "apply cooldown before sending alerts"
- "create jira escalation for repeat offenders"

## Tools

- Input source: output records from `clockwork-compliance-check` (which is based on `clockwork mcp`)
- Gmail MCP (built-in Manus):
  - list/search threads (optional for dedupe)
  - send email
- Jira MCP (mcp-atlassian):
  - `mcp_mcp-atlassian_jira_search`
  - `mcp_mcp-atlassian_jira_create_issue`
  - `mcp_mcp-atlassian_jira_add_comment`
  - `mcp_mcp-atlassian_jira_update_issue` (optional)

## Preconditions

- Alert recipients are resolvable:
  - member email
  - manager email
  - admin distribution list
- Jira escalation project/key is configured (example: `TL`).
- Cooldown storage or trace source is available (email subject/Jira key matching is acceptable for MVP).

## Guardrails

- Respect cooldown: max 1 email per member per run type in 90 minutes.
- Do not create duplicate Jira escalation issues for the same member/date unless prior issue is closed.
- Keep messages concise, include violation facts and expected recovery action.
- Never escalate users with explicit exclusion reason (leave/out-of-office).

## Workflow Router

1. Load `references/workflows/alert-routing-workflow.md`.
2. Use templates from `references/templates/alert-notification-templates.md`.
3. Return action log for `clockwork-daily-digest`.

## Output Contract

Always return:

- `date`, `run_type`
- `actions_planned`
- `actions_executed`
- `actions_skipped` with reason (`cooldown`, `excluded`, `duplicate`)
- `emails_sent` (recipient list)
- `jira_updates` (issue key, action)
- `failures` (tool step + error)

## Failure Handling

- Gmail send fails: retry once, then queue to `pending_email_actions` and continue Jira path.
- Jira create fails: attempt comment on existing issue if found; if not, report hard failure.
- Missing manager email: continue with member-only email and flag `manager_missing=true`.
