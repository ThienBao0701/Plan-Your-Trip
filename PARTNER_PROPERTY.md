# Partner property management (Phase C)

How an approved partner creates and edits the properties it owns, and what the backend refuses. The
account side is Phase A (`ACCOUNT_LIFECYCLE.md`); the moderation side stays administrative
(`ROLE_UI_PERMISSION_FREEZE.md`).

## 1. The canonical record

A property is the existing accommodation pair, unchanged:

```
Place  ──1:1──  HotelDetail
  │                 check-in / check-out, star rating, policies,
  │                 parking, Wi-Fi, languages, payment methods
  ├── category / subcategory   → categories      (admin-managed)
  ├── administrativeUnit       → administrative_units (admin-managed, D13)
  ├── owner                    → partner_profiles
  ├── createdBy                → users
  └── PlaceAmenity[]           → amenities       (admin-managed)
```

No entity, table or column was added for Phase C, and no migration: V1–V3 already carry every field
these endpoints write. A property created by a partner is the same row an administrator would create
through `/api/admin/places`.

## 2. The rules

| Rule | Where it lives |
|---|---|
| Only an **approved** partner profile may read or write | `PartnerPropertyService.myApprovedProfileOrThrow` — 404 without a profile, 403 when it is not APPROVED |
| A property is reachable only by its **owner** | `ownedPlaceOrThrow` → `findByIdAndOwnerId`; another partner's property is a uniform **404** |
| Owner and author come from the **authenticated principal** | `createProperty`; no request carries an owner, partner id or author |
| A created property is **DRAFT** | `createProperty`; no field of this contract moves the status |
| Category must be an **active ACCOMMODATION** category | `accommodationCategoryOrThrow` — 422 `CATEGORY_INVALID` |
| Subcategory must be a **direct child** of it | `subcategoryOrThrow` — 422 `SUBCATEGORY_INVALID` |
| Location must be an **active PROVINCE, CITY or AREA** | `propertyLocationOrThrow` — 422 `LOCATION_INVALID` |
| Amenities must be **active** and in a property group (`GENERAL`, `HOTEL`) | `propertyAmenitiesOrThrow` — 422 `AMENITY_INVALID` |
| Coordinates, when given, are in range | `@DecimalMin/@DecimalMax` on the requests — 400 `VALIDATION_FAILED` |
| Slug is derived server-side and unique | `PlaceSlugService` (extracted from `PlaceService`, same algorithm) |

`PartnerPropertyCrudTest` proves each of them, including that a second partner is refused on every
read and every mutation and that the target's data is unchanged afterwards.

## 3. The API

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/api/partner/hotels` | my properties (owner-scoped in the query) |
| `GET` | `/api/partner/hotels/{id}` | one of mine, in full |
| `POST` | `/api/partner/hotels` | **Phase C** — create one DRAFT property, 201 |
| `PUT` | `/api/partner/hotels/{id}` | name, descriptions, and (Phase C) classification |
| `PUT` | `/api/partner/hotels/{id}/location` | address, coordinates, and (Phase C) administrative unit |
| `PUT` | `/api/partner/hotels/{id}/contact` | phone, email, website, social |
| `PUT` | `/api/partner/hotels/{id}/policies` | check-in/out, house rules, and (Phase C) star rating, cancellation, parking, Wi-Fi, languages, payment methods |
| `PUT` | `/api/partner/hotels/{id}/amenities` | **Phase C** — replace the amenity set |
| `PATCH` | `/api/partner/hotels/{id}/activate` \| `/deactivate` | the listing switch — **not** publication |

`POST` creates the `Place`, its `HotelDetail` and its amenity links in **one transaction**; a
refusal anywhere leaves no half-built property.

### Additive by design

Every field Phase C added to an existing request is optional, and **absent means unchanged**:

* `categoryId` absent → the classification is untouched. Sent → replaced wholesale, and
  `subcategoryId` then means exactly what it says (a value sets it, null clears it).
* `administrativeUnitId` absent → the property stays where it is.
* the new policy fields absent → the stored values stay. (The three original policy strings keep
  their existing wholesale-replace behaviour, so nothing an older client does changes meaning.)

## 4. Star rating

`hotel_details.star_rating` is `NOT NULL CHECK (star_rating BETWEEN 1 AND 5)`: the schema has no
value meaning "not classified". Phase C therefore makes `starRating` **required on create** and
treats it as the partner's own declaration — the client labels it that way. Nothing assigns a rating
on the partner's behalf.

The pre-existing fallback in `updatePolicies` (which invents `1` when a property has no
`HotelDetail` row at all) is unchanged, because an administratively imported place still has to be
editable. It now accepts a declared rating instead when one is sent. A property created through
Phase C always has its own.

## 5. Status, publication and deletion

`PlaceStatus` is untouched: `DRAFT, PENDING_REVIEW, APPROVED, PUBLISHED, HIDDEN, ARCHIVED,
REJECTED`. A partner can reach none of it — there is no status field in any request here and no
status route on the partner surface. Publication remains `PlaceService.updateStatus`, behind
`/api/admin/**`.

`active` is a listing switch inside the workspace and deliberately **not** public visibility: Phase A
(`PublicListingVisibility`) makes `PUBLISHED` the only status the public APIs return, and
`PartnerPropertyCrudTest` re-proves that a freshly created draft is absent from `/api/places`,
`/api/places/{id}` and `/api/places/slug/{slug}` while the seeded published catalogue is still there.

**Delete is not implemented, deliberately.** Sixteen tables carry a foreign key to `places`
(bookings, invoices, reviews, wishlists, trip items, recommendations, …), `ARCHIVED` is an
administrative moderation state that must not be quietly repurposed, and `active=false` must not
become a pseudo-delete because public visibility depends on the status instead. A partner-owned
deletion needs its own decision about dependent records; until that exists, creating and editing are
what Phase C ships.

## 6. Audit

Property mutations use the existing partner trail (`PartnerActivityLogService`, `<ENTITY>_<VERB>`):

* `PROPERTY_CREATED` — new in Phase C, on create
* `PROPERTY_UPDATED` — existing; also emitted for an amenity replacement

No administrative audit action was added, so the pinned inventory in `AdminAuditInfrastructureTest`
(114 deliberate actions) is unchanged. No password, token or credential is ever logged.

## 7. Running it locally

```powershell
cd "D:\Plan Your Trip\Plan-Your-Trip-backend-v1"
$env:VOUCHER_SIGNING_SECRET="local-dev-voucher-secret-2026-plan-your-trip-32chars"
$env:SERVER_PORT="8081"
.\mvnw.cmd spring-boot:run
```

```powershell
.\mvnw.cmd test -Dtest='PartnerPropertyCrudTest,PartnerPropertyTest,PublicListingVisibilityTest'
.\mvnw.cmd test
```

`DataInitializer` seeds the catalogue these endpoints validate against: the `Accommodation` category
with its eight children, the D13 location tree, and 64 amenities across `GENERAL`, `HOTEL`, `ROOM`,
`RESTAURANT`, `CAFE` and `ATTRACTION`.

## 8. Not in Phase C

Media and images, rooms, rate plans, pricing, availability and inventory, publication, deletion,
public/traveller integration, and any change to the role model. Each is a later phase with its own
backend surface.
