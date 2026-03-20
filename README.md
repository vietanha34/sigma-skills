# Sigma Skills

This repository contains custom agent skills designed to enhance productivity and automate tasks. It follows the [Agent Skills](https://github.com/vercel-labs/agent-skills) standard.

## Structure

- `skills/`: Contains the skill definitions (Markdown files) instructing the Agent.
- `package.json`: Repository metadata.

## Available Skills

### Jira Worklog Review

Located in `skills/jira-worklog-review`.

**Description:**
A skill that guides the Agent to review your daily Jira worklogs using the Atlassian MCP server. It calculates total logged time and suggests issues to fill gaps if you are under 8 hours.

**Prerequisites:**

- An Agent capable of running MCP tools.
- **MCP Atlassian Server** configured and running (providing `jira_*` tools).

**Usage:**
Simply ask the Agent:

- "Review my worklog"
- "Check my jira hours for today"
- "Did I log enough time?"

The Agent will use its available tools to:

1. Fetch your worklogs for the specified date.
2. Calculate the total hours.
3. Suggest "In Progress" issues if you are short of 8 hours.

### Clockwork Compliance Check

Located in `skills/clockwork-compliance-check`.

**Description:**
Evaluates team timer compliance from Clockwork backend APIs with hybrid policy checks (missing start, missing resume, long idle gap, and end-of-day target hours).

### Clockwork Alert Router

Located in `skills/clockwork-alert-router`.

**Description:**
Routes compliance violations to Gmail and Jira with cooldown and escalation rules, while preventing duplicate escalations.

### Clockwork Daily Digest

Located in `skills/clockwork-daily-digest`.

**Description:**
Builds and sends end-of-day compliance digests for members and admins, including violation summary and escalation status.

## Installation

To install this skill to your agent (e.g., via `npx skills`):

```bash
npx skills add <path-to-this-repo>/skills/jira-worklog-review
npx skills add <path-to-this-repo>/skills/clockwork-compliance-check
npx skills add <path-to-this-repo>/skills/clockwork-alert-router
npx skills add <path-to-this-repo>/skills/clockwork-daily-digest
```

## Development

This is a prompt-based skill repository. No build step is required.
