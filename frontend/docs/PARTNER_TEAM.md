# Partner team management (RBAC R5)

The Partner workspace's **Team** destination and the invitation-acceptance page. It is the UI for the R4
backend (`docs/security/PLAN_YOUR_TRIP_RBAC_PERMISSION_MATRIX_V1.md` §10–§14, §23). The server decides
every permission; the client only hides what the caller's access document says it cannot do, and still
handles each refusal the backend returns.

## 1. Where things live

| Concern | File |
|---|---|
| Access document (`GET /api/partner/me/access`), permission keys | `lib/core/partner/partner_access_models.dart` |
| Grants, scopes, statuses, invitations | `lib/core/partner/partner_team_models.dart` (+ `PartnerTeamMember` in `partner_models.dart`) |
| Team list state, capabilities, actions | `lib/features/partner/team/partner_team_state.dart` |
| Team screen (members, invitations) | `lib/features/partner/team/partner_team_screen.dart` |
| Invite / edit-grants / confirm dialogs, grant editor | `lib/features/partner/team/partner_team_dialogs.dart` |
| Step-up (re-enter password) | `lib/features/partner/team/partner_step_up_dialog.dart`, `AppState.stepUp` |
| Error codes → words | `lib/features/partner/team/partner_team_messages.dart` |
| Role / scope / status labels (shared by shell, dashboard, settings) | `lib/features/partner/team/partner_team_labels.dart` |
| Invitation link capture | `lib/app/routing/invitation_link.dart` |
| Acceptance page (signed out / signed in) | `lib/features/partner/team/accept_invitation_screen.dart` |

Team management moved out of Settings: Settings now holds only the payout account.

## 2. Endpoints

`GET /api/partner/me/access` · `GET /api/partner/team` · `PUT /api/partner/team/{id}/grants` ·
`POST /api/partner/team/{id}/suspend` · `POST /api/partner/team/{id}/reactivate` ·
`DELETE /api/partner/team/{id}` · `POST /api/partner/team/leave` · `GET|POST /api/partner/team/invitations` ·
`POST /api/partner/team/invitations/{id}/resend` · `DELETE /api/partner/team/invitations/{id}` ·
`GET /api/me/partner-invitations` · `POST /api/me/partner-invitations/accept|decline` · `POST /api/me/step-up`.

## 3. Permission-aware behaviour

- The access document is kept **in memory only** (`PartnerState.access`), and it is cleared on sign-out or reset.
- The **Team** destination appears only when the caller holds `partner.team.view` anywhere.
- Invite, edit, suspend, reactivate and remove each depend on their own key (`partner.team.invite`,
  `.role.assign`, `.suspend`, `.remove`). The client never checks a role name.
- Nobody can act on themselves, on the primary owner or on a revoked membership.
- Only an owner actor may grant OWNER, MANAGER or FINANCE, or act on a member who holds one of those roles.
- The scopes on offer follow §11.3. OWNER and FINANCE are company-wide; HOUSEKEEPING is per property or per room type;
  every other role is company-wide or per property. The company scope and the property list come from what the caller holds.
- `STEP_UP_REQUIRED` opens the password dialog. A successful step-up retries the action **once**.
- A `CONCURRENT_MODIFICATION` refusal, a stale invitation or a timed-out (uncertain) write reloads the list.
- `PERMISSION_DENIED` or `ROLE_NOT_DELEGABLE` also refreshes the access document.
- A suspended membership gets its own workspace state (`membershipSuspended`). An active member reaches the
  workspace just as an owner does.

## 4. Invitation link and token handling

The emailed link is `<partner app>/accept-invitation#token=…`. The token sits in the **fragment**, so it is never sent to a server
in the URL.

1. When the page opens, `PartnerInvitationLink.capture()` reads the token and clears the fragment from the address bar.
2. The token is then held only in a static in-memory field. It is never written to SharedPreferences, logs,
   analytics, team state or error text.
3. Signed out, the page shows the normal Partner sign-in with neutral guidance. Signing in turns the same
   location into the acceptance screen, which reads the token from memory.
4. The token is sent only in the JSON body of accept or decline. A final refusal (invalid, expired, stale,
   validation) drops it. A network or server failure keeps it so the invitee can retry.
5. Accepting resets `PartnerState`, so the workspace reloads with the new membership.

**Known limitation.** A full page reload, or registering a new Partner account and verifying its email,
discards the in-memory token. This is deliberate, because the token is never persisted. The invitee opens the
emailed link again.
