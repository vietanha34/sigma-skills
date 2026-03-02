---
name: clockwork-daily-digest
description: Use when generating end-of-day Clockwork compliance digests for members and admins, summarizing missing hours, idle gaps, and escalation outcomes.
---

# Clockwork Daily Digest

Use this skill to produce and send end-of-day compliance summaries.

Default schedule target:
- Daily at 17:10 Asia/Ho_Chi_Minh

## Trigger Phrases
- "send clockwork end of day digest"
- "generate admin timer compliance report"
- "summarize who is missing hours today"
- "send personal compliance summary"

## Tools
- Input source:
  - compliance output from `clockwork-compliance-check` (`run_type=eod_check`)
  - action log from `clockwork-alert-router`
- Gmail MCP (built-in Manus): send digest emails
- Jira MCP (mcp-atlassian, optional):
  - `mcp_mcp-atlassian_jira_search` for open escalations

## Preconditions
- Recipient groups are defined:
  - member recipients (individual)
  - admin digest recipients
- Target date is known (default: today in Asia/Ho_Chi_Minh).
- Compliance thresholds are included in digest metadata.

## Guardrails
- Use one digest per member per date.
- Exclude users on approved leave from non-compliance counts.
- Separate facts from interpretation.
- Include explicit timezone and policy thresholds in every digest.

## Workflow Router
1. Load `references/workflows/daily-digest-workflow.md`.
2. Use templates from `references/templates/daily-digest-email-template.md`.
3. Require both upstream artifacts:
   - compliance records from `clockwork-compliance-check`
   - execution log from `clockwork-alert-router`

## Output Contract
Always return:
- `date`, `timezone`
- `member_digest_sent_count`
- `admin_digest_sent_count`
- `non_compliant_member_count`
- `high_severity_count`
- `open_escalation_count`
- `delivery_failures`

## Failure Handling
- Partial email delivery failure: return failed recipient list and keep successful sends.
- Missing compliance input: stop and return `missing_upstream_data=true`.
- Jira lookup failure for escalation summary: continue digest with `escalation_data_partial=true`.
