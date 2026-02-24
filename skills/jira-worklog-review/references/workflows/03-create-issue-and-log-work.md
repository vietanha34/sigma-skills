# 03. Create Issue In TL And Log Work

## Goal
Create a new Jira task in project `TL`, assign `(BU) Project`, and add worklog to reduce daily gap.

## Required Tools
- `jira_search_fields`
- `jira_get_field_options`
- Jira create issue tool (Atlassian Jira MCP)
- `mcp_mcp-atlassian_jira_add_worklog`

## Steps
1. Find `(BU) Project` field:
   - Tool: `jira_search_fields`
   - Params: `keyword = "(BU) Project"`, `limit = 10`
2. Validate expected field metadata:
   - `id = "customfield_10232"`
   - `name = "(BU) Project"`
   - `schema.type = "array"`
   - `schema.items = "option"`
   - `custom = "com.atlassian.jira.plugin.system.customfieldtypes:multiselect"`
3. Load all options for `(BU) Project`:
   - Tool: `jira_get_field_options`
   - Params: `field_id = "customfield_10232"`
   - Expected item format: `{ id, value, disabled? }`
4. Ask user for:
   - task `name` (summary)
   - task `description`
   - `worklog time`
   - selected `(BU) Project` option(s)
5. Create issue in project key `TL` with provided fields.
6. Add worklog to newly created issue:
   - Tool: `mcp_mcp-atlassian_jira_add_worklog`
7. Return created issue key and logged duration.
8. Hand control back to `02-suggestions-under-8h.md` for loop check.

## Failure Handling
- If field metadata does not match expected schema/type: stop create flow and ask to verify Jira field mapping.
- If options list is empty: stop create flow and request Jira admin check.
- If create or add-worklog fails: show exact failing step and error; offer logging to existing issues instead.
