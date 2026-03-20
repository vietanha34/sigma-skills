# 03. Create Issue And Log Work

## Goal

Create a new Jira task (either custom or preset "Leave") and log work to reduce daily gap.

## Required Tools

- `jira_search_fields`
- `jira_get_field_options`
- `mcp_mcp-atlassian_jira_create_issue`
- `mcp_mcp-atlassian_jira_add_worklog`

## Steps

1. **Prepare `(BU) Project` Options**:
   - Find field: `jira_search_fields(keyword="(BU) Project", limit=1)`
   - Verify metadata: `id="customfield_10232"`.
   - Load options: `jira_get_field_options(field_id="customfield_10232")`.
   - Store options list for user selection/validation.

2. **User Interaction - Select Mode**:
   Ask user to choose a creation mode:

   ### Option A: Log Time Off (Nghỉ phép)

   - **Target Project**: `TTSX` (Fixed)
   - **(BU) Project**: `Nghỉ phép` (Auto-select this option if available)
   - **Inputs to gather**:
     - Summary (default: "Nghỉ phép [Date]")
     - Description (optional)
     - Worklog duration

   ### Option B: Create Custom Task

   - **Target Project**: Ask user to select (Suggest: `TL`, `TTSX`, or "Other" to input key).
   - **(BU) Project**: Ask user to select from loaded options.
   - **Inputs to gather**:
     - Summary
     - Description
     - Worklog duration

3. **Create Issue**:
   - Tool: `mcp_mcp-atlassian_jira_create_issue`
   - Params:
     - `project_key`: `TTSX` (for Option A) or user selection (for Option B).
     - `summary`: User input.
     - `description`: User input.
     - `issue_type`: "Task" (or ask user if needed, default to Task).
     - `additional_fields`: Set `customfield_10232` (BU Project) to the selected option(s).

4. **Add Worklog**:
   - Tool: `mcp_mcp-atlassian_jira_add_worklog`
   - Params:
     - `issue_key`: Key from Step 3.
     - `timeSpent`: User duration.
     - `started`: Target date.

5. **Completion**:
   - Return created issue key and logged duration.
   - Hand control back to `02-suggestions-under-8h.md` for loop check.

## Failure Handling

- `(BU) Project` not found/empty: Warn user, allow creation without it (if project allows) or abort.
- "Nghỉ phép" option missing: Warn user if Option A selected, ask to select closest alternative.
- Create/Log failed: Report error, try to recover (e.g., if issue created but log failed, show issue key and ask user to log manually).
