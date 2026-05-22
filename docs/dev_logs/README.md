# Development & debug logs

Agents and developers record **implementation and debugging** work here. Rules: `docs/AI/rule.md` §12.

## Where to write

| Type of work | File |
|--------------|------|
| Large module, major feature, big refactor, long debug investigation | **New file:** `YYYY-MM-DD_<short-topic>.md` |
| Small patches, quick fixes, short debug notes | **Append:** [`small_patches.md`](small_patches.md) (newest entry at top) |

## Entry checklist

- Date (and agent/human author if useful)
- Goal or problem
- Files / areas touched
- What changed and why
- Debug steps (failures + fixes), if applicable
- How it was verified (`flutter analyze`, build, manual test, etc.)

## Do not log

- API keys, `.env` contents
- Full user `text_payload` or clipboard text (PII)
