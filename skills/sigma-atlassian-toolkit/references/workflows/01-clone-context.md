# Workflow 01: Clone One Context

Use this workflow to clone one existing context and its full option set into a new context for the same field.

## Required Inputs
- `fieldId`
- `sourceContext` (id or exact name, optional if auto-select mode is used)
- `newContextName`
- Optional scope: `projectIds`, `issueTypeIds`

## Steps
1. Resolve and validate field.
   - Default resolution target: `(BU) Project`.
   - Confirm exact `fieldId` before API writes.
2. Load all contexts for field.
   - `GET /rest/api/3/field/{fieldId}/context`
   - If `sourceContext` provided: find by id or exact name.
   - If not provided: prefer global context with non-zero options; if multiple, choose one with most options.
   - Fail if source not found.
3. Validate source options before create.
   - `GET /rest/api/3/field/{fieldId}/context/{sourceContextId}/option`
   - Handle pagination until all options are collected.
   - If total options is `0`, stop and ask user to choose another source context.
4. Ensure target context name does not exist.
   - If existing context has the same name, stop and ask user for a new name.
5. Validate target scope.
   - If `projectIds` provided, verify they exist via `GET /rest/api/3/project/search`.
   - If `projectIds` omitted, create as global only when user explicitly asks.
6. Create new context.
   - `POST /rest/api/3/field/{fieldId}/context`
   - Include `name`, optional `description`, and optional `projectIds` / `issueTypeIds`.
7. Bulk create options into new context.
   - `POST /rest/api/3/field/{fieldId}/context/{newContextId}/option`
   - Copy `value` and `disabled` from source.
   - Batch by safe chunk size if needed.
8. Preserve display order.
   - If creation order differs, call:
   - `PUT /rest/api/3/field/{fieldId}/context/{newContextId}/option/move`
9. Return operation summary.

## Output Expectations
- Source context id/name
- New context id/name
- Target scope (global/project ids/issue type ids)
- Number of options cloned
- Any disabled options preserved
- Reorder action status
