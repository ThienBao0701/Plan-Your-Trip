# Account lifecycle (Phase A)

This document describes how accounts are created, verified, signed in, secured and ended on the backend
after Phase A. It covers the backend only; the Partner registration, verification and reset pages are
Phase B.

## 1. Roles and lifecycles

There are exactly three system roles: `USER`, `PARTNER`, `ADMIN`. Partner team roles (`OWNER`, `MANAGER`,
`FRONT_DESK`, `FINANCE`, `VIEWER`) are inside a Partner organization and are not sign-in roles.

| Role | How the account is created | Before it can operate |
|---|---|---|
| `USER` | `POST /api/auth/register` — self-registration, signed in immediately (unchanged V1 behaviour) | nothing |
| `PARTNER` | `POST /api/auth/partner/register` — self-registration, **no session returned** | verify email → sign in → create the business profile (`POST /api/partner/profile`) → submit → **Admin approval** → property operations |
| `ADMIN` | controlled provisioning only: `ProductionBootstrap` (prod, env-gated) or `DataInitializer` (dev/test). No public Admin registration exists. | nothing |

The role is decided by the endpoint that creates the account. Request bodies have no role field, and an
unknown JSON property such as `"role":"ADMIN"` is ignored.

Admin approval of the Partner **business profile** is unchanged and still gates every Partner property,
room, rate, calendar and booking endpoint. Property publication by an approved Partner is a later phase and
is not implemented here.

## 2. Partner registration

`POST /api/auth/partner/register`

```json
{ "fullName": "Pat Partner", "email": "pat@example.com", "password": "at-least-8", "acceptTerms": true }
```

- `acceptTerms` must be exactly `true`; absent or `false` is a 400 and nothing is created.
- The account is stored with `role = PARTNER`, `emailVerificationRequired = true`, `termsAcceptedAt` and
  `termsVersion` (the configured `app.auth.partner-terms-version`).
- One verification link is issued and handed to the email sender.
- `201 {"email", "status":"PENDING_VERIFICATION", "verificationRequired": true, "message"}` — no token.
- A duplicate email is `409 EMAIL_ALREADY_REGISTERED`, including a duplicate that races past the pre-check
  into the unique index.
- When email delivery is unavailable the request is `503 EMAIL_DELIVERY_UNAVAILABLE` and nothing is created.

The phone number and other business details belong to the Partner business profile, not to the account.

## 3. Input rules (all registration and password endpoints)

| Field | Rule |
|---|---|
| email | trimmed; valid; at most 254 characters; stored and looked up lowercased (`Locale.ROOT`) |
| fullName | trimmed; required; at most 120 characters |
| password | required; at least 8 characters; **at most 72 bytes of UTF-8** (BCrypt's limit) |

Every violation is a `400` with `code: "VALIDATION_FAILED"` and a `fieldErrors` list. None of them is a 500
any more. Sign-in with a password longer than 72 bytes is the ordinary `401`.

## 4. Email verification

- `POST /api/auth/verify-email` `{"token": "..."}` →
  `200 {"status":"VERIFIED"}`, or `200 {"status":"ALREADY_VERIFIED"}` for an account that was already
  verified.
- `400 TOKEN_INVALID` — unknown, already used, superseded by a newer link, meant for another purpose, or
  belonging to a disabled account. `400 TOKEN_EXPIRED` — past its lifetime (24 hours by default).
- `POST /api/auth/resend-verification` `{"email": "..."}` → always the same `202` body. A new link is issued
  only for an enabled account that still requires verification, and only once per cooldown (60 seconds by
  default). `503 EMAIL_DELIVERY_UNAVAILABLE` when no email can be sent — for every address alike.

A self-registered Partner that has not verified cannot sign in: `403 EMAIL_NOT_VERIFIED`, returned only
after the password has been checked.

**Scope of the gate.** Verification is enforced only for accounts created by Partner self-registration
(`emailVerificationRequired = true`). Traveller accounts are not gated. Accounts that existed before V3 were
marked verified by the migration. An account that becomes `PARTNER` through the existing Admin approval of a
traveller's partner application is not gated either (see §11).

## 5. One-time tokens

Verification and password-reset tokens share one model (`auth_tokens`, `AuthTokenService`):

- 32 random bytes from `SecureRandom`, base64url — 43 characters.
- Only the SHA-256 hash is stored. The raw token exists only in the link given to the email sender.
- One active token per account and purpose: issuing a new one retires the previous one, and consuming one
  retires the rest.
- Consumption is a conditional update, so a token is used at most once even under concurrent requests.
- Issuance cooldown per account and purpose, serialised with a row lock on the account.
- Links point at the surface of the account's role (`app.auth.user-app-url`, `partner-app-url`,
  `admin-app-url`) with the token in the URL **fragment** — `/verify-email#token=…`,
  `/reset-password#token=…` — so it is not sent to any server in a request line or `Referer` header.

## 6. Password reset and change

- `POST /api/auth/forgot-password` `{"email"}` → always the same `202`. A link is issued only for an enabled
  account with a recognised role, once per cooldown. `503` when email delivery is unavailable.
- `POST /api/auth/reset-password` `{"token", "newPassword"}` → `200`. The link expires after 30 minutes by
  default and works once. A refused new password (400) does not use up the link.
- `PUT /api/me/password` `{"currentPassword", "newPassword"}` (authenticated) → `200 {"token", "user"}`.
  The account is always the session's; an id in the body is ignored. Wrong current password:
  `400 CURRENT_PASSWORD_INCORRECT` (`fieldErrors: currentPassword`). Same password: `400 PASSWORD_UNCHANGED`.
  Outstanding reset links are retired.

Both a reset and a change end **every** existing session of the account (see §7). A change returns a fresh
token so the session that made it continues.

## 7. Account status and session invalidation

`JwtAuthenticationFilter` loads the account on every request and authenticates it only when:

1. the account exists and `enabled` is true;
2. the token's `ver` claim equals the account's `tokenVersion` — tokens issued before Phase A carry no `ver`
   and read as 0;
3. the stored role is exactly `USER`, `PARTNER` or `ADMIN`.

Otherwise the request is anonymous and protected endpoints answer the standard 401. Disabling an account
therefore takes effect on the next request, and a password reset or change (which increment `tokenVersion`)
ends every older token. The JWT format is otherwise unchanged (HS256, `sub`, `email`, `exp`, 24 hours).

Sign-in refusals, all after the password has been checked (a wrong password or unknown email is always the
same `401 INVALID_CREDENTIALS`):

| Condition | Response |
|---|---|
| `enabled = false` | `403 ACCOUNT_DISABLED` |
| role not exactly USER/PARTNER/ADMIN (unknown, differently cased, padded, blank, null) | `403 ACCOUNT_UNAVAILABLE` |
| self-registered Partner not yet verified | `403 EMAIL_NOT_VERIFIED` |

## 8. Admin authentication audit

Recorded through `AdminActivityLogService` (target type `USER`, target id = the admin):

| Action | When |
|---|---|
| `ADMIN_LOGIN_SUCCESS` | an ADMIN signs in |
| `ADMIN_LOGIN_FAILED` | a sign-in to an **ADMIN** account is refused (wrong password, disabled) |
| `ADMIN_PASSWORD_CHANGE` | an ADMIN changes their own password |
| `ADMIN_PASSWORD_RESET` | an ADMIN resets their password by link |

A refused sign-in for an unknown address or a non-admin account writes nothing. No row contains a password
or token; the audit service also refuses credential-shaped text. Sign-in is not transactional, so a refused
attempt's row is kept.

`ProductionBootstrap` normalizes `ADMIN_BOOTSTRAP_EMAIL` exactly like sign-in (trim, lowercase), checks for
an existing account ignoring case, never overwrites one, marks the bootstrap admin verified, and stops
start-up — without printing it — if the password is longer than 72 bytes.

## 9. Local development: verifying an account

There is no email provider. Under every profile except `prod`, `DevelopmentLogEmailSender` writes the link to
the backend console instead of sending anything:

```
[DEV ONLY — NO EMAIL SENT] EMAIL_VERIFICATION link for pat@example.com: http://localhost:64118/verify-email#token=…
```

Until the Phase B pages exist, post the token (the part after `#token=`) directly:

```powershell
curl.exe -X POST http://localhost:8081/api/auth/verify-email -H "Content-Type: application/json" -d '{\"token\":\"<token>\"}'
```

Password reset works the same way with `/api/auth/reset-password`. The logged link is a one-time credential;
this sender can never be active under the `prod` profile.

## 10. Configuration

| Property | Env | Default |
|---|---|---|
| `app.auth.verification-token-ttl` | `AUTH_VERIFICATION_TOKEN_TTL` | `PT24H` |
| `app.auth.password-reset-token-ttl` | `AUTH_PASSWORD_RESET_TOKEN_TTL` | `PT30M` |
| `app.auth.token-issue-cooldown` | `AUTH_TOKEN_ISSUE_COOLDOWN` | `PT60S` |
| `app.auth.partner-terms-version` | `PARTNER_TERMS_VERSION` | `partner-terms-2026-09` |
| `app.auth.user-app-url` | `USER_APP_URL` | `http://localhost:64117` |
| `app.auth.partner-app-url` | `PARTNER_APP_URL` | `http://localhost:64118` |
| `app.auth.admin-app-url` | `ADMIN_APP_URL` | `http://localhost:64119` |

Under `prod`, `UnconfiguredEmailSender` is always unavailable, so Partner registration, verification resend
and forgot-password answer `503` until a real provider implementation of `EmailSender` is added. Set the
three `*_APP_URL` values to the public origins when that happens.

## 11. Schema — `V3__account_lifecycle.sql`

Additive, forward-only, SQL Server conventions:

- `users`: `email_verified_at`, `email_verification_required` (bit, default 0), `token_version` (int,
  default 0), `terms_accepted_at`, `terms_version`.
- Every existing row is set verified, deterministically, to its own `created_at` (or the migration time when
  `created_at` is null). No existing account becomes gated, and no role, enabled flag or partner profile
  changes.
- `auth_tokens`: `user_id` (FK), `purpose`, `token_hash` (unique), `expires_at`, `consumed_at`, `created_at`.

No property, room, rate or inventory table is touched. `email_verification_required` was added beyond the
original column list so that the verification gate applies only to self-registered Partners and does not lock
out accounts promoted to PARTNER by the existing Admin approval flow.

## 12. Public listing visibility

Only a `PUBLISHED` place is public. `DRAFT`, `PENDING_REVIEW`, `APPROVED`, `HIDDEN`, `REJECTED` and
`ARCHIVED` are not. A room is publicly sellable only when it is active and its place is public.
`PublicListingVisibility` is the one rule, used by:

- `GET /api/places/{id}/availability`
- `GET /api/rooms/{id}/pricing` (legacy)
- `GET /api/rooms/{id}/rate-plans`, `…/{planId}/preview`, `…/{planId}/cancellation-preview`
- `POST /api/rooms/{id}/pricing/quote` (already enforced; now shares the rule)

A non-public place or room is a 404 identical to a missing id and carries none of its data. Place search,
detail and media already filtered to `PUBLISHED` in the database and are unchanged.

## 13. Known limitations and remaining security debt

- **No login brute-force protection.** Only token *issuance* is throttled. Sign-in has no rate limit or
  lockout, and repeated failures against an admin address each write an audit row.
- **No email provider.** Local development logs links; production answers 503. The development sender runs
  inside the registration transaction; a real provider should send after commit.
- **Logout is client-side.** Tokens are stateless; a signed-out token stays valid until it expires unless the
  account's token version changes or the account is disabled. There is no "sign out everywhere" endpoint.
- **No endpoint disables an account yet.** The filter honours `enabled` immediately, but nothing in the API
  sets it.
- **Accounts promoted to PARTNER by Admin approval** of a traveller application are not email-gated.
- **Public approved reviews** (`GET /api/places/{id}/reviews`) are still returned for places that are no
  longer published; this is not pricing or availability data and was outside S2.
- **No MFA.**
