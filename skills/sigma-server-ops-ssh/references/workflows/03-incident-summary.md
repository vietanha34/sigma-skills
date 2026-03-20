# Workflow: Incident Summary

Use when user asks for a concise report to share with team.

## Inputs

- Collected `dump`, `progress`, log, process, and config evidence from workflows 01/02.

## Steps

1. State the scope first: named channel or whole server.
2. Build timeline: earliest anomaly -> peak impact -> current state.
3. Separate machine symptoms from channel symptoms.
4. Call out affected plugins/apps explicitly when relevant (`origin`, `nginx`, `srs`, `portal-local`).
5. Quantify impact if possible (affected channels, bitrate loss, app down, duration).
6. Produce next-step plan with owner/action/ETA placeholders.
7. Render using `references/templates/incident-report-template.md`.

## Output Quality Rules

- No vague statements without evidence.
- Every hypothesis references at least one concrete API, log, or process signal.
- Keep report short enough for chat handoff (typically <= 250 words).
