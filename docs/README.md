# KuCuba documentation index

| Start here | Purpose |
|------------|---------|
| **[`SOP_blueprint.md`](SOP_blueprint.md)** | Standard workflow for AI and developers: status → read plans → code → dev_logs → test → test_logs |

## Plans & architecture

| Document | Purpose |
|----------|---------|
| [`Detailed_System_Requirement_Document.md`](Detailed_System_Requirement_Document.md) | SRD — requirements & architecture |
| [`Phase_1_Core_App_Module.md`](Phase_1_Core_App_Module.md) | Phase 1 plan |
| [`Phase_2_OS_Share_Sheet_Overlay.md`](Phase_2_OS_Share_Sheet_Overlay.md) | Phase 2 plan |
| [`Phase_3_Pinned_Notification_Banner.md`](Phase_3_Pinned_Notification_Banner.md) | Phase 3 plan (may run in parallel with Phase 2 after backend) |
| [`TECH_STACK_AND_PIPELINE.md`](TECH_STACK_AND_PIPELINE.md) | Stack, API, pipeline diagrams |

## Agent guardrails (`docs/AI/`)

| Document | Purpose |
|----------|---------|
| [`AI/rule.md`](AI/rule.md) | Mandatory DO/DON'T |
| [`AI/SKILL.md`](AI/SKILL.md) | Stack, commands, build order |
| [`AI/backend_dev.md`](AI/backend_dev.md) | Backend-only sessions |

## History & testing

| Folder | Purpose |
|--------|---------|
| [`dev_logs/`](dev_logs/) | Per-branch implementation logs (`dev0`/`dev1` backend, `dev2` frontend) |
| [`test_logs/`](test_logs/) | Formal test reports |

## Phase dependencies

- **Phase 1 backend** (`POST /analyze`) is required before Phase 2 or Phase 3.
- **Phase 2** (Share Sheet) and **Phase 3** (Notification) are **parallel** — both call the same backend. Details: [`AI/rule.md` §0.1](AI/rule.md).

## Quick prompts

See **§0** in [`SOP_blueprint.md`](SOP_blueprint.md).
