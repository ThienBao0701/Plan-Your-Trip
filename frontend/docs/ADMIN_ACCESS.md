# Admin access — profiles in the console (RBAC R6)

The admin console renders from the caller's access document. It never decides access: the backend authorizes every `/api/admin/**` request (`RBAC_ADMIN_PROFILES.md` at the repository root). Hiding a destination is a convenience, not a control. Design: `docs/security/PLAN_YOUR_TRIP_RBAC_PERMISSION_MATRIX_V1.md` §7, §9.2, §23, §25.4.

## Access document

`AdminState.loadAccess()` reads `GET /api/admin/me/access` into `AdminAccess` (`lib/core/admin/admin_access_models.dart`): profiles, active permission keys and `stepUp.freshUntil`. It is held in memory only and cleared by `AdminState.reset()` when the session changes.

| Answer | `AdminAccessStatus` | Console |
|---|---|---|
| 200 | `ready` | Menu and landing as below |
| 403 | `noAccess` | "No admin profile" (`admin-no-access`); no other admin request is made |
| anything else | `error` | Retryable error (`admin-access-error`); never treated as empty access |

`AdminState.holds(key)` is false until a document is loaded (fail closed). Unknown profile names parse as `AdminProfile.unknown`, and unknown permission keys match nothing.

## Menu and landing

Each `AdminDestination` names the permission its own read needs (`requiresPermission`): dashboard A04, bookings A24, partners A08, catalog A13, media A20, reference data A01, payments A30, invoices A32, reviews A34, activity log A03, administrators A02. The shell:
- lists only granted destinations and the sections that contain one;
- loads nothing until the document is ready, then stays on the requested route if it is granted, otherwise moves to the first granted one;
- ignores selection of a route that is not granted, including a direct route to one.

## Administrators screen (`/admin/access`)

`AdminAccessScreen` + `AdminAccessManagementState` list `GET /api/admin/access/admins` and replace profiles with `PUT /api/admin/access/admins/{userId}/profiles`. Only a `PLATFORM_OWNER` sees the destination.
- The caller's own row cannot be edited (AP-1).
- A row holding a profile this build does not know is read-only, because saving would silently revoke it.
- `STEP_UP_REQUIRED` opens the shared step-up dialog (`showPartnerStepUpDialog`, `POST /api/me/step-up`) and retries once. Cancelling sends nothing further.
- `LAST_PLATFORM_OWNER_REQUIRED`, `SELF_MODIFICATION_FORBIDDEN`, `PERMISSION_DENIED` and `VALIDATION_FAILED` are worded and never reported as saved.
- After a success, an uncertain outcome, a conflict or a 404, the list is re-read from the server.

## Tests

- `test/r6_admin_profiles_test.dart` covers parsing, the menu and landing, no access and errors, and the Administrators screen.
- The existing admin tests stub the access document with `test/support/admin_access_stub.dart` (`withAdminAccess`, a platform owner by default). The stub answers before the wrapped client, so those tests' request logs and counts are unchanged.

## Not in the console

A16 dual control (RBAC R6, `RBAC_ADMIN_PROFILES.md` §6 at the repository root) is API-only: `POST /api/admin/hotels/{id}/assign-owner` submits a request (202) and a second platform owner approves it under `/api/admin/dual-control/requests`. The console has no assign-owner screen (the D3B catalogue freeze) and therefore no approval queue; adding one is a separate product decision.
