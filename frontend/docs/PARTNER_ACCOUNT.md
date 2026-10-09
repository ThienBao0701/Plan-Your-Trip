# Partner account UX (Phase B)

How a Partner creates an account, verifies it, signs in, recovers a password and completes the business
profile — and what the Admin and traveller surfaces share with it. The backend side is Phase A
(`ACCOUNT_LIFECYCLE.md` in the backend repository); this document covers only the Flutter client.

## 1. Surfaces and routes

All routes are root-relative: the origin already says which application it is.

| Location | Partner (64118) | Admin (64119) | User (64117) |
|---|---|---|---|
| `/` | sign-in, then workspace | sign-in, then console | onboarding, then traveller app |
| `/register` | **Partner registration** | — (Admin accounts are provisioned) | — (sign-up stays inside sign-in) |
| `/verify-email` | verification (link or pasted token) | — | — |
| `/forgot-password` | request a reset link | same | same |
| `/reset-password` | set a new password from a link | same | same |
| `/account` | account details, security, business profile | account details, security | — |
| `/accept-invitation` | team invitation: sign-in guidance, then accept/decline ([PARTNER_TEAM.md](PARTNER_TEAM.md)) | — | — |
| destinations | the 14 workspace destinations (`/team` only with `partner.team.view`) | the 10 console destinations | the 4 tabs |

`/register`, `/verify-email`, `/forgot-password`, `/reset-password` and (R5) `/accept-invitation` are the only
locations a signed-out visitor can open, because the emails carrying their tokens are opened without a session. `/account` needs a
session and the surface's own role; a wrong role gets the access-denied screen as before.

## 2. Partner account lifecycle

```
Partner sign-in ─ Become a Partner ─► /register ─► POST /api/auth/partner/register
                                                     │  201, no session
                                                     ▼
                                              /verify-email ─► POST /api/auth/verify-email
                                                     │  VERIFIED
                                                     ▼
                                              sign in ─► /account ─► business profile
                                                                      │ save (DRAFT)
                                                                      │ submit  ─► SUBMITTED
                                                                      ▼
                                                            Admin approves ─► workspace opens
```

Registration never returns a session and the app never creates one from it: the account signs in only after
verification. Approval is an administrator's decision; the client only displays the status the backend
reports.

## 3. Screens

| Screen | File | Backend call |
|---|---|---|
| Sign-in (all surfaces) | `features/auth/login_screen.dart` | `POST /api/auth/login` |
| Partner registration | `features/auth/partner_register_screen.dart` | `POST /api/auth/partner/register` |
| Verify email | `features/auth/verify_email_screen.dart` | `POST /api/auth/verify-email`, `/resend-verification` |
| Forgot password | `features/auth/forgot_password_screen.dart` | `POST /api/auth/forgot-password` |
| Reset password | `features/auth/reset_password_screen.dart` | `POST /api/auth/reset-password` |
| Change password | `features/auth/change_password_screen.dart` | `PUT /api/me/password` |
| Account area | `features/account/account_screen.dart` | `GET /api/me` |
| Business profile | `features/partner/account/*` | `GET/POST /api/partner/profile`, `/submit` |

`features/auth/auth_page_scaffold.dart` gives them one frame, and `auth_validators.dart` one set of form
rules (at least 8 characters, at most 72 bytes of UTF-8, matching confirmation) mirroring the backend's.

## 4. Errors

Every account call returns an `AuthResult` carrying an `AuthFailure` with the backend's stable `code`
(`core/auth/auth_error.dart`). `core/auth/auth_messages.dart` is the **only** place a code becomes copy:

| Code | Shown as |
|---|---|
| `EMAIL_ALREADY_REGISTERED` | That email address already has an account. |
| `EMAIL_NOT_VERIFIED` | Verify your email address before signing in. |
| `ACCOUNT_DISABLED` / `ACCOUNT_UNAVAILABLE` | disabled / cannot sign in — contact support |
| `TOKEN_INVALID` / `TOKEN_EXPIRED` | this link is invalid or has expired |
| `CURRENT_PASSWORD_INCORRECT` / `PASSWORD_UNCHANGED` | on the field that caused it |
| `EMAIL_DELIVERY_UNAVAILABLE` | Email delivery is unavailable right now. |
| `VALIDATION_FAILED` | Please check the highlighted fields — plus each `fieldErrors` entry on its field |

A code this build does not know falls back to the generic message; on the sign-in screen a bare 401/403
reads as "email or password is incorrect" rather than "session expired". Server prose is never shown as the
primary message, and no status line, exception name or stack trace ever reaches a screen.

## 5. Tokens in links

Verification and reset links put their one-time token in the URL **fragment**
(`/verify-email#token=…`), so it is never sent to a server in a request line and never lands in an access
log or `Referer` header. The screen reads it once (`app/routing/auth_link_token.dart`), clears it from the
address bar immediately, holds it only in the field until it is used, and stores or logs it nowhere.

## 6. Local development: no email is delivered

There is no email provider. The backend logs the link instead:

```
[DEV ONLY — NO EMAIL SENT] EMAIL_VERIFICATION link for pat@example.com: http://localhost:64118/verify-email#token=…
```

The verification and forgot-password screens say this plainly and never claim a message was sent. Two ways
to use the link locally:

1. paste the whole link into the browser — the screen picks the token out of the fragment; or
2. copy the part after `#token=` into the token field.

Resend is disabled for 60 seconds after a request, matching the backend's issuance cooldown, and its
acknowledgement is the same for every address.

## 7. Business profile

The form sends exactly the fields `PartnerProfileRequest` declares: business name, business type, the
representative's name, phone, email, address, and optionally tax code and website. The backend accepts an
edit only while the profile is DRAFT or REJECTED, so the account screen shows the form's entry point only
then and explains the read-only state otherwise. "Save and submit for review" saves first and submits only
if that succeeded.

Status copy comes from the backend's own value — DRAFT, SUBMITTED, APPROVED, REJECTED, SUSPENDED — and a
rejection shows its reason. Nothing here approves anything.

## 8. Running it

```powershell
cd "D:\Plan Your Trip\Plan-Your-Trip-backend-v1"
$env:VOUCHER_SIGNING_SECRET="local-dev-voucher-secret-2026-plan-your-trip-32chars"
$env:SERVER_PORT="8081"
.\mvnw.cmd spring-boot:run
```

```powershell
cd "D:\Plan Your Trip\Plan-Your-Trip-integration\frontend"
flutter run -d chrome -t lib/main_partner.dart --web-port 64118
```

Then: Become a Partner → register → copy the link from the backend console → verify → sign in → Account →
add business information → save and submit. The workspace stays closed until an administrator approves the
profile (Admin console → Partners).

## 9. Known limitations

- **Account status and email verification state are not displayed.** `GET /api/me` returns only id, name,
  email and role, so the account screen shows those and the business-profile status. Showing a verification
  badge would need a backend field that does not exist yet.
- **The Partner terms version is not shown.** The backend records the version it has configured; no endpoint
  exposes it, so the checkbox states the agreement without naming a version.
- **Server field messages are English.** A field error the client's own rules did not catch is shown in the
  backend's wording, with the localized summary next to it.
- **No email is delivered anywhere yet** (see §6), and production answers 503 for these flows.
- **Sign-in has no brute-force protection** — a backend gap recorded in Phase A, unchanged here.
