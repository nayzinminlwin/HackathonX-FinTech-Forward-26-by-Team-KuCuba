# Development & debug logs

Agents and developers record **implementation and debugging** work here, **one subfolder per git branch** so parallel work on `dev0`, `dev1`, and `dev2` does not overwrite each other.

**Archived workflow:** [`docs/bin/SOP_blueprint.md`](../bin/SOP_blueprint.md)  
Archived rules: `docs/bin/AI/rule.md` §12.

---

## Branch folders (where to write)

| Folder | Git branch | Team focus | Typical paths & work |
|--------|------------|------------|----------------------|
| [`dev0/`](dev0/) | `dev0` | **Backend** (developer 1) | `backend/` — Shelf, `POST /analyze`, Safe Browsing, Gemini |
| [`dev1/`](dev1/) | `dev1` | **Backend** (developer 2) | Same as `dev0` — second backend branch for parallel backend tasks |
| [`dev2/`](dev2/) | `dev2` | **Frontend** | `lib/`, `android/` (manifest, themes, share overlay), Flutter UI, Dio → backend; Phase 3 UI/native bridge as assigned |

**Always log under the folder that matches your current git branch.** Do not add dated logs or patches at the `docs/dev_logs/` root (only this `README.md` and shared redirect notes belong here).

Both **`dev0` and `dev1` are backend branches** — use your own folder so two backend developers do not edit the same log files. **`dev2` is the frontend branch.**

---

## What to create in your branch folder

| Type of work | Path |
|--------------|------|
| Large module, major feature, big refactor, long debug investigation | **New file:** `docs/dev_logs/<branch>/YYYY-MM-DD_<short-topic>.md` |
| Small patches, quick fixes, short debug notes | **Append:** `docs/dev_logs/<branch>/small_patches.md` (newest entry at top) |

Examples:

- Backend sector on **`dev0`** → `docs/dev_logs/dev0/2026-05-23_phase1_backend_sector3_gemini_pipeline.md`
- Backend experiment on **`dev1`** → `docs/dev_logs/dev1/2026-05-24_safe_browsing_tuning.md`
- Share-sheet / Flutter on **`dev2`** → `docs/dev_logs/dev2/YYYY-MM-DD_phase2_share_overlay.md`

---

## Entry checklist

- Date (and agent/human author if useful)
- **Branch:** `dev0` / `dev1` / `dev2`
- Goal or problem
- Files / areas touched
- What changed and why
- Debug steps (failures + fixes), if applicable
- How it was verified (`dart analyze`, `flutter analyze`, build, manual test, etc.)

---

## Related: test logs

Formal test run write-ups live in **`docs/test_logs/`** (separate from dev logs). Name files by date and scope; mention your branch in the doc header when relevant.

---

## Do not log

- API keys, `.env` contents
- Full user `text_payload` or clipboard text (PII)
