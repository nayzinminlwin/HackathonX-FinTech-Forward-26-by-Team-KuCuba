# Test logs

Formal **test run reports** and validation notes (checklists, curl/API results, emulator runs).

This folder is separate from **`docs/dev_logs/`**, which is split by git branch (`dev0` / `dev1` = backend, `dev2` = frontend). See [`../dev_logs/README.md`](../dev_logs/README.md).

## Naming

Prefer: `YYYY-MM-DD_<scope>.md` or a descriptive title (e.g. `Phase_1_and_2_Test_Results.md`).

Include in each report header: **date**, **branch** (`dev0` / `dev1` / `dev2`), and **what was tested**.

## Do not include

- API keys or `.env` contents
- Full user message / clipboard payloads (PII)
