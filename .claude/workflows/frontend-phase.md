# Frontend Phase Workflow

Operational checklist for any UI-N phase in `frontend/`. Distills `frontend/CLAUDE.md` §5, §12,
§13 into a run-order checklist — read that file for the full rationale.

## 1. Preconditions

- `git rev-parse --abbrev-ref HEAD` matches the authorized branch (currently `feature/frontend-ui-v2`).
- `git rev-parse HEAD` matches `git rev-parse origin/<branch>` — no unpushed/unpulled drift.
- `git status --short` is clean of the previous phase's work before starting a new UI-N.

## 2. Inspect before coding

- Read the target screen(s), the relevant `AppState` methods/fields, `app_models.dart` types,
  `mock_data.dart` seeds, and any existing test file for the feature before writing code.
- Never assume a widget, model, or backend route exists — grep/read it first.

## 3. Real gap analysis

- State explicitly what already exists (models, `AppState` methods, screens, tests) versus what
  this phase must add. Don't re-implement what's already there.

## 4. Frontend-only changes

- Touch only `frontend/**` unless the task explicitly authorizes backend changes.
- Never edit `../src`, `../pom.xml`, `../mvnw`, `../mvnw.cmd`, `../CLAUDE_backend.md` during a
  UI phase.

## 5. Backend contract inspection (read-only)

- When wiring Real Mode, read the actual controller/DTO/service classes for the endpoint being
  integrated (`../src/main/java/com/example/planyourtrip/{controller,dto,service}`). Map every
  field explicitly — never assume the backend shape matches the frontend's demo model.

## 6. Demo Mode / Real Mode honesty

- Demo Mode stays fully local and deterministic, seeded from `MockData`.
- Real Mode only reports success after a backend-confirmed response. If the backend doesn't
  support an operation yet, return the appropriate `*.unavailable` result — never fabricate
  success.

## 7. Verification commands (run in this order)

1. `dart format .`
2. `flutter analyze`
3. `flutter test test/ui<N>_..._test.dart` (focused)
4. `flutter test` (full suite)
5. `flutter build web` — only when the phase touches web-specific behavior

## 8. Exact scope report

- Report exact changed paths and `git status --short` at the end of the phase, using
  `.claude/templates/phase-report.md`.

## 9. No Git write actions

- Never run `git add`, `commit`, `push`, `reset`, `clean`, `checkout`, `switch`, `merge`, or
  `rebase`. The user stages and commits every phase.
