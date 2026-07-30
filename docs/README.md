# Fridge2Table Documentation Index

Documentation for the Fridge2Table (F2T) Final Year Project. Start with **Project Overview** if you're new to the codebase; the rest can be read in any order depending on what you need.

| Doc | What's in it |
|---|---|
| [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md) | Problem statement, full tech stack, phase-by-phase development history, every working feature, and an honest list of known limitations and intentional design decisions. Start here. |
| [ARCHITECTURE.md](ARCHITECTURE.md) | System diagram and six detailed data-flow diagrams (auth, add ingredient, recipe matching, cooking, cloud sync, AI detection), plus a service-by-service reference for every class in `lib/services/`. |
| [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) | Every table (backend `pantry_items`, Supabase's separate `ingredients` sync table, `auth.users`) with full column/constraint listings and RLS policies, plus every local-storage key on the frontend and an ER diagram. |
| [USE_CASES.md](USE_CASES.md) | A use case diagram and 19 full use case write-ups (actors, preconditions, main flow, alternate/exception flows, postconditions) — written for direct use in the FYP report's requirements/analysis chapters. |
| [API_REFERENCE.md](API_REFERENCE.md) | Every backend endpoint: method, URL, params, request/response schema, worked examples, and the current Bearer-JWT auth model enforced by the backend. |
| [CODEBASE_GUIDE.md](CODEBASE_GUIDE.md) | Every source file in the repo (backend and frontend), what it does, and how it connects to the rest of the codebase. |
| [DATA_PERSISTENCE.md](DATA_PERSISTENCE.md) | For every kind of data the app holds: where it's stored, and whether it survives logout, uninstall, or shows up on a second device. Includes a quick-reference table. |
| [AUDIT_FIXES.md](AUDIT_FIXES.md) | What changed after the documentation audit surfaced real gaps (notifications, auth, privacy wording, backup wording, UI-only placeholders) — what was fixed, what was deliberately left alone, and the one manual Supabase/Render setup step still required. Read this alongside the docs above, which still describe pre-fix behavior in places. |
| [PROJECT_FLOW.md](PROJECT_FLOW.md) | *(Pre-existing doc.)* A shorter, narrative walkthrough of the same flows covered in more depth by ARCHITECTURE.md — kept for its screen-navigation map. |
| [UI.md](UI.md) | *(Pre-existing doc.)* Design tokens (colors, typography), the shared screen-header pattern, and the full 25-screen inventory. |

Two related documents exist **outside this folder and outside git** (kept local-only, listed in the root `.gitignore`) — not linked here since they aren't part of the tracked repo:
- `DISSERTATION_NOTES.md` (repo root) — plain extraction notes covering testing evidence, bug history, and evaluation-data status, written specifically for dissertation writing.
- `z_ALL_DOC.md` (repo root) — the FYP's client/supervisor meeting records, ethics paperwork, and heuristic evaluation.
