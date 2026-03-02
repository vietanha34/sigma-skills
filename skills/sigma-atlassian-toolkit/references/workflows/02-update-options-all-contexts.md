# Workflow 02: Update Options For All Contexts

Use this workflow to synchronize options for every existing context of a field using a single target value list.

## Required Inputs
- `fieldId`
- `values` (target list, ordered, unique, non-empty strings)

## Sync Policy
- Non-destructive default:
  - Add missing values.
  - Keep existing values that are still in target list enabled.
  - Disable values not present in target list.
- Preserve target order exactly using move/reorder API.

## Steps
1. Resolve field and validate input list.
   - Default field: `(BU) Project`.
   - Normalize `values`: trim, deduplicate, keep first-seen order.
2. Fetch all contexts for field.
   - `GET /rest/api/3/field/{fieldId}/context`
   - Stop if no contexts.
3. For each context:
   - Read existing options with pagination:
   - `GET /rest/api/3/field/{fieldId}/context/{contextId}/option`
   - Compute diff:
     - `to_create`: target values missing in existing options.
     - `to_enable`: existing options in target list but currently disabled.
     - `to_disable`: existing options not in target list and currently enabled.
4. Apply changes per context:
   - Create missing values in bulk:
   - `POST /rest/api/3/field/{fieldId}/context/{contextId}/option`
   - Update option disabled state:
   - `PUT /rest/api/3/field/{fieldId}/context/{contextId}/option`
   - Use option ids from current context for `to_enable` and `to_disable`.
   - If update endpoint is blocked by permission/policy, report this limitation clearly.
5. Reorder to match target list.
   - `PUT /rest/api/3/field/{fieldId}/context/{contextId}/option/move`
6. Continue until all contexts complete.
   - If one context fails, continue others and mark partial failure.
7. Return consolidated summary.

## Output Expectations
- Total contexts scanned/updated
- Contexts skipped (if any) and skip reasons
- Per-context create/enable/disable/reorder counts
- Contexts failed with exact API step and reason
- Final status: success or partial
