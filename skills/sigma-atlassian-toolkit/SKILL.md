---
name: sigma-atlassian-toolkit
description: Jira custom field context toolkit for cloning contexts and synchronizing options across contexts using MCP discovery plus Jira Cloud REST execution.
---

# Sigma Atlassian Toolkit

Use this skill to manage Jira custom field contexts and options safely, with a focus on `(BU) Project` by default.

This skill supports two main use cases:

1. Clone one existing context to a new context on a target field.
2. Update options for all existing contexts of a target field from a provided value list.

## Trigger Phrases

- "clone context for BU Project"
- "create one more context for custom field"
- "sync options across all contexts"
- "update BU Project options"
- "bulk update options for field contexts"

## Tools

- Atlassian MCP (discovery/read):
  - `jira_search_fields`
  - `jira_get_field_options`
- Jira Cloud REST API (write actions via shell):
  - `GET /rest/api/3/field/{fieldId}/context`
  - `GET /rest/api/3/project/search` (validate project scope before create context)
  - `POST /rest/api/3/field/{fieldId}/context`
  - `GET /rest/api/3/field/{fieldId}/context/{contextId}/option`
  - `POST /rest/api/3/field/{fieldId}/context/{contextId}/option`
  - `PUT /rest/api/3/field/{fieldId}/context/{contextId}/option` (enable/disable option state)
  - `PUT /rest/api/3/field/{fieldId}/context/{contextId}/option/move`
- Local shell tools: `curl`, `jq`

## Preconditions

- Jira Cloud site and API credentials are available:
  - `JIRA_BASE_URL` or `JIRA_URL` (for example `https://your-domain.atlassian.net`)
  - `JIRA_EMAIL` or `JIRA_USERNAME`
  - `JIRA_API_TOKEN`
- Caller has `Administer Jira` global permission.
- Input value list is available for option sync operations.
- Default field is `(BU) Project`; known id hint is `customfield_10232`, but always verify at runtime.

## Guardrails

- Read/validate first, then write.
- Require explicit confirmation before any `POST`/`PUT` write operation.
- Keep operations idempotent:
  - Clone should not create duplicate context names.
  - Option sync should add missing values and disable out-of-target values instead of hard delete.
- Prefer source context with non-empty options when cloning.
- If source context has `0` options, stop and ask user to confirm using another source context.
- Preserve option order to match the provided value list.
- Always report exact API step and payload fragment on failure.

## Workflow Router

1. Resolve field:
   - If user provides field id/name, use it.
   - Otherwise default to `(BU) Project`.
   - Verify exact field id using `jira_search_fields`.
2. Determine use case:
   - Clone one context: load `references/workflows/01-clone-context.md`.
   - Sync options for all contexts: load `references/workflows/02-update-options-all-contexts.md`.
3. Execute write flow with Jira REST API via `curl` and parse with `jq`.
4. Render final output with `references/templates/operation-summary-template.md`.

## Inputs

- `field`: optional, default `(BU) Project`
- `values`: required for option sync (array of strings)
- `clone_source_context`: optional for clone flow (id or exact name). If omitted, choose global context with options first.
- `clone_new_context_name`: required for clone flow
- `projectIds` and `issueTypeIds`: optional context scope controls

## Minimal Response Contract

Always return:

- `Field`: name + id used.
- `Operation`: clone-context or sync-options-all-contexts.
- `Contexts processed`: source/target ids and names.
- `Changes`: created options, disabled options, reordered options.
- `Result`: success/partial/failed with failed step if any.

## Failure Handling

- Field not found: show top candidate fields from `jira_search_fields` and ask user to choose.
- Source context not found: show available contexts and stop.
- Source context has no options: stop and ask user to select another source context.
- Duplicate target context name: stop and ask for a new name.
- Invalid/unknown target project id: show candidate projects from `GET /rest/api/3/project/search` and stop.
- API permission error (`401/403`): report required permission and stop.
- Large payload/error retry: process in chunks and resume from last successful context.
