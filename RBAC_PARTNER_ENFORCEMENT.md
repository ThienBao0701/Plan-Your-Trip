# RBAC R3b — partner permission enforcement

Activates the V1.1 permission matrix for every operational partner endpoint (RBAC V1.1 §4.5, §10.1, §11, §12,
§16 PA-4, §21, §23 F4, §24 B9, §25.1, §25.2). Builds on R1 (`security/rbac`), R2 (`RBAC_MEMBERSHIP_FOUNDATION.md`)
and R3a (`RBAC_OWNER_TEAM_SECURITY.md`). Design: `frontend/docs/security/PLAN_YOUR_TRIP_RBAC_PERMISSION_MATRIX_V1.md`.

**No migration.** R3b reads the V4–V7 schema as it is. No permission key was added, and no reserved permission
was activated.

## 1. Who holds what

| Caller | Grants evaluated |
|---|---|
| Registrant (primary owner) | `OWNER@COMPANY` (all 54 permissions over their company) |
| ACTIVE member of an APPROVED company | Their stored grants (`partner_member_grants`). Each grant gives the role's §10.1 bundle (`PartnerRoleBundles`) at that grant's scope. |
| SUSPENDED / REVOKED member, no membership, admin | No workspace. Operational endpoints return 404 "Partner profile not found". |
| Member of a company that is not APPROVED | 403 `PARTNER_NOT_APPROVED` |

- **MANAGER** holds its bundle minus P08–P11 (team invite, role assignment, suspend and remove). These are deferred to R4 (`PartnerRoleBundles.effective`), so team mutations stay owner-only.
- **Floors.** A permission whose floor is C (company) is never satisfied by a property or unit grant. A permission whose floor is P (property) is never satisfied by a unit grant.
- **Legacy endpoints.** `LegacyPartnerBundles` is now used only by `assignable()`, which limits the legacy `POST/PATCH /team` endpoints to the five pre-R2 roles. Any role at any scope can be granted through `PUT /team/{id}/grants`.

## 2. Endpoint kinds (§4.5)

The registry (`PartnerEndpointRules`) is the single source of truth: permission, kind, resource type, field gates and aggregate scope for every partner endpoint.

### RESOURCE

1. `PartnerResourceTargetResolver` resolves the stored target to its company, property and unit, never from the request body.
2. If the caller holds the permission over that target, the request is allowed.
3. Otherwise, if the caller can view a resource of that type, the response is 403.
4. Otherwise it is 404, so the resource's existence is not revealed.

Further rules:

- **Booking by voucher code.** These requests resolve through `bookingCodeTarget`.
- **Promotion body targets.** These resolve through `hotel_details` and `hotel_rooms`. `ALL` gives 403.
- **Rate plans.** Reads and edits addressed by room resolve through the room.

### COLLECTION

- The scope set S is computed for the permission; if S is empty the response is 403.
- Filtering happens in the query (`PartnerAccessService.propertyIds`) over the company's currently owned places within S.
- An optional `hotelId` outside S returns 404.
- Room lists show a whole property or only the granted units.
- Conversations are filtered by `booking.hotel ∈ S`.
- The team list shows members whose grants all lie inside S.

### COMPANY

- These endpoints require a COMPANY grant: settings edit, property create, finance statements and payouts, payout account, activity log.
- **AU-4.** The activity log (P05) is readable by OWNER and by MANAGER@COMPANY only.

### Aggregates

- **FILTERABLE BY PROPERTY.** Analytics, the finance overview and revenue, the dashboard and the home page are computed over S.
- **COMPANY ONLY.** Settlements, commissions, invoices, refunds and payouts require FINANCE or OWNER at company scope. `hotelId` remains a filter for those holders.

## 3. Field-level data (§21)

- **SD-1 / SD-2: permission-gated fields.**
  - The field is returned as `null`.
  - It is listed in the response's `redacted` array, as `{field, mode}`.
  - The name masking format is "T. T. B.".
  - List items carry their own `redacted` array.

| Data | Needs | Endpoints |
|---|---|---|
| Guest name (masked otherwise) | P54 | Bookings, stays, voucher verify, check-in and check-out by code, conversations (also USER sender names) |
| Guest email (omitted) | P35 | Bookings |
| `specialRequest`, `cancelReason`, `partnerNote` | P40 | Booking detail and list |
| Payments, invoice, price breakdown, coupon / credit / loyalty / gift-card amounts, gift-card reference, rate snapshots | P36 | Booking detail |
| Revenue figures (`totalRevenue`, ADR, `revenue*`, `financeSummary`, `topRoomsByRevenue`) | P49 over all of S | Analytics overview and rooms, dashboard, home |
| Individual review previews (`latestReviews`) | P44 over all of S | Analytics reviews |
| Representative and contact | P02 | Home, account summary |
| Payout block / team count | P52 / P07 | Account summary |

The per-booking `finalPrice` is booking data under P34 (FI-1).

- **SD-3 / NR: never-to-partner fields.** These fields are removed by partner-specific DTOs: they are absent from the response and not listed in `redacted`.
  - `PartnerBookingView`: no `userId`, no `loyaltyPointsRedeemed`.
  - `PartnerPaymentView`: no `checkoutUrl`, no raw `failureReason`.
  - `PartnerConversationView` and `PartnerMessageView`: no `userId`, no `senderUserId`.
  - `PartnerReviewView`: no `userId`.
  - Bearer instruments (QR payload, signature, full code, callback token) are never returned.

## 4. Mixed payloads (§24 B9)

`PUT /rooms/{id}` and calendar day and bulk writes are diffed against the stored row (`PartnerFieldDiff`).

**Rooms:**
- Content fields need P23.
- Commercial fields need P24.
- `active` needs P25.

**Calendar:**
- Inventory counts need P27.
- Restriction flags need P28.

The caller must first hold one of the endpoint's permissions on the target, then every permission the diff needs. Nothing is saved otherwise (no partial save).

## 5. Property moves (PA-4)

`POST /api/admin/hotels/{id}/assign-owner` moving a property to another company, in the same transaction:

- The previous company's grants on that property are revoked.
- A strict `TEAM_MEMBER_SCOPE_REVOKED` audit entry (reason `PROPERTY_MOVED`) is written to the previous company's trail.
- The previous company's owners receive the mandatory notification.
- The property's conversations are re-pointed to the new company.

Check-in and check-out audits recorded by another company keep their actor ids hidden.

## 6. `GET /api/partner/me/access` (§25.2)

- **Kind and caching.** SELF, `Cache-Control: no-store`.
- **Contents.** Workspace, membership, grants, and effective permissions after floors, by company, property and unit. Reserved permissions are excluded.
- **Context.** The §11.7 parent context, plus `stepUp.freshUntil`.
- **Who gets permissions.** A suspended member, or the owner of an unapproved company, gets the document with empty permissions.
- **404.** Callers with no company and no membership get 404, administrators included.

## 7. Unchanged

R3a still applies to every team mutation:

- owner protection (O-1…O-4);
- last-owner protection and the company row lock;
- step-up (P12 and P53);
- the strict, append-only team audit;
- mandatory security notifications;
- version checks.

Admin RBAC is untouched. No partner permission is granted to admins, and no admin permission to partners.

**Tests:** `RbacPartnerEnforcementTest` (the authorization matrix), plus the updated `RbacKernelHttpTest`, `RbacMembershipFoundationTest`, `RbacOwnerTeamSecurityTest` and `RbacEndpointRegistryTest`.
