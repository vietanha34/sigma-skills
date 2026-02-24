# Workflow: Incident Summary

Use when user asks for a concise report to share with team.

## Inputs
- Collected status/log evidence from workflows 01/02.

## Steps
1. Build timeline: earliest anomaly -> peak impact -> current state.
2. Separate facts vs hypotheses.
3. Quantify impact if possible (duration, affected component, severity).
4. Produce next-step plan with owner/action/ETA placeholders.
5. Render using `references/templates/incident-report-template.md`.

## Output Quality Rules
- No vague statements without evidence.
- Every hypothesis references at least one concrete log/status signal.
- Keep report short enough for chat handoff (typically <= 250 words).
