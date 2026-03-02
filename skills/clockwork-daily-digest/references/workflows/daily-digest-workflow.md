# Daily Digest Workflow

## Procedure
1. Load EOD compliance records from `clockwork-compliance-check`.
2. Load action execution log from `clockwork-alert-router`.
3. Build member-level digest entries:
   - total logged vs target
   - key violations
   - required next action for tomorrow
4. Build admin summary:
   - total members evaluated
   - compliant count
   - warning/high count
   - top repeated offenders
   - Jira escalations created/updated
5. Send emails:
   - member digests to each member with non-compliant status
   - one admin digest to admin list
6. Return report metadata.
