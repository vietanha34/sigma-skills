# AGENTS.md

This file provides guidance to AI coding agents (Claude Code, Cursor, Trae, etc.) when working with the `sigma-skills` repository.

## Repository Overview

`sigma-skills` is a collection of **Agent Skills** designed to extend the capabilities of AI agents through **Model Context Protocol (MCP)** tools and prompt-based orchestration.

Unlike traditional script-based skills, the skills in this repository primarily rely on **existing MCP servers** (e.g., Atlassian, GitHub, Filesystem) to perform actions. The `SKILL.md` serves as the "driver" or "playbook" that teaches the Agent how to use these tools to complete complex tasks effectively.

## Creating a New Skill

### Directory Structure

```
skills/
  {skill-name}/           # kebab-case directory name (e.g., jira-worklog-review)
    SKILL.md              # Required: The skill definition and prompt instructions
```

### Naming Conventions

- **Skill directory**: `kebab-case` (e.g., `jira-worklog-review`, `daily-standup`)
- **SKILL.md**: Must be named exactly `SKILL.md`.

### SKILL.md Format

The `SKILL.md` file defines the skill metadata and the instructional prompt. It follows the standard format compatible with `npx skills`.

```markdown
---
name: {skill-name}
description: {Concise description of the skill. Used for skill discovery.}
---

# {Skill Title}

{Detailed description of what the skill does and the problem it solves.}

## Trigger Phrases
- "{Phrase 1}"
- "{Phrase 2}"

## Tools
List the MCP tools required for this skill.
- `mcp_server_name_tool_name`

## Procedure
Step-by-step instructions for the Agent to follow.

1. **Step 1**: ...
2. **Step 2**: ...

## Example Conversation
(Optional but recommended)
**User**: ...
**Agent**: ...
```

### Best Practices

1.  **Leverage MCP**: Prefer using available MCP tools over writing custom scripts. This makes the skill portable, secure, and easier to maintain.
2.  **Clear Instructions**: Be explicit about which tools to call and in what order.
3.  **Error Handling**: Instruct the Agent on how to handle missing data or tool failures (e.g., "If the search returns no results, ask the user for clarification").
4.  **Context Efficiency**: Keep the instructions focused. Don't include unnecessary conversational filler.

## Installation & Usage

To use these skills, they must be installed into the Agent's context.

**Standard Installation:**
```bash
npx skills add <path-to-repo>/skills/{skill-name}
```

**Manual Usage:**
Copy the content of `SKILL.md` into the Agent's system prompt or active conversation context.

## Troubleshooting

- **Tool Not Found**: Ensure the Agent has the required MCP server configured and running.
- **Permission Errors**: Verify that the MCP server has the necessary credentials (e.g., Jira API Token).
