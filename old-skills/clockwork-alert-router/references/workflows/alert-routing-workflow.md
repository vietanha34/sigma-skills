# Alert Routing Workflow

## Routing Policy

1. `status=compliant`: no action.
2. `status=warning` and first occurrence:
   - send member reminder email.
3. `status=warning` repeated in same day:
   - send member + manager email.
4. `status=high` or repeat on 2 consecutive workdays:
   - send member + manager + admin digest recipient.
   - create or update Jira escalation issue.

## Procedure

1. Load compliance records from `clockwork-compliance-check`.
2. Group by member/date and merge duplicate violations.
3. Check cooldown and past alerts.
4. Generate action list:
   - `email_member`
   - `email_member_manager`
   - `jira_create_or_update`
5. Execute actions in order: email first, Jira second.
6. Return execution log for audit.
7. Persist execution log as input for `clockwork-daily-digest`.
