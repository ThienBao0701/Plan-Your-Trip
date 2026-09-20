# Partner properties (Phase C)

How a Partner creates and edits a property in the workspace, and what the client deliberately cannot
do. The backend side is `PARTNER_PROPERTY.md` in the backend repository; this covers the Flutter
client only. The account lifecycle that leads here is `PARTNER_ACCOUNT.md`, and the step-by-step
setup built on top of these endpoints is `PARTNER_PROPERTY_ONBOARDING.md` — **Add property** opens
that wizard; the single-form editor described here is reached from a property's detail panel.

## 1. The flow

```
Partner signs in ─► Account ─► business profile ─► submitted ─► admin approves
                                                                      │
                                                                      ▼
                                          Workspace ─► Hotels ("My properties")
                                                                      │
                          ┌───────────────────────────────────────────┤
                          ▼                                           ▼
                   + Add property                              open a property
                          │                                           │
                   editor (new draft)                          editor (edit)
                          │                                           │
                   Save draft ─► POST /api/partner/hotels      Save changes ─► the section PUTs
                          │                                           │
                          └────────────► list reloads from the backend ◄──┘
```

Nothing here publishes. A property stays `DRAFT` until an administrator publishes it, and the screens
say so rather than implying a listing is live.

## 2. Screens and files

| Screen | File | Backend |
|---|---|---|
| My properties | `features/partner/properties/partner_properties_screen.dart` | `GET /api/partner/hotels` |
| Property editor | `features/partner/properties/partner_property_editor_screen.dart` | `POST /api/partner/hotels`, the four section `PUT`s, `PUT /{id}/amenities` |
| Editor state | `partner_property_editor_state.dart` | the catalogue + the writes |
| Payloads | `core/partner/partner_property_form_models.dart` | `PartnerHotelCreateRequest` and friends |
| Record | `core/partner/partner_property_models.dart` | `PartnerHotelResponse` |
| Error copy | `core/partner/property_messages.dart` | Phase A `code` / `fieldErrors` |

The editor is reached from inside the Hotels destination (a pushed route), not from a new browser
location: the Partner surface's locations are its thirteen destinations, and Phase C adds none.

## 3. Editor sections

1. **Property basics** — name, short description, description, property type, specific type. On an
   existing property the URL slug is shown read-only: it is the public identifier, so editing the
   name never moves it.
2. **Location** — country → province/city → area (the D13 hierarchy, walked one level at a time),
   street address, optional latitude/longitude.
3. **Contact** — phone, email, website. Facebook and Instagram are not shown, and are carried
   through unchanged rather than erased.
4. **Details and policies** — property rating, check-in/check-out, children/pet/smoking/cancellation
   policies, parking, Wi-Fi, languages, payment methods.
5. **Amenities** — the admin catalogue's `GENERAL` and `HOTEL` groups only; room amenities belong to
   a room.

There is no image upload, no room configuration and no rates: each has its own backend and its own
phase.

## 4. Where the options come from

Property types, administrative areas and amenities are read from the admin-managed catalogue
(`GET /api/categories`, `/api/locations/roots`, `/api/locations/{id}/children`, `/api/amenities`).
The editor can offer nothing else, and the backend validates every id again. If the catalogue cannot
be read, the editor shows an error and **no form at all** — a form without it could only offer ids
the client invented.

## 5. Property rating

The backend requires a 1–5 rating on `HotelDetail` and has no value meaning "unclassified", so the
editor asks for one and labels it as the partner's own declaration: *"Your own classification from 1
to 5. It is not a verified star rating."* The client never fills it in silently.

## 6. Errors

Every write returns an `ApiWriteResult` carrying an `ApiFailure` with the backend's `code` and
`fieldErrors` (`core/network/api_failure.dart`). `core/partner/property_messages.dart` is the only
place a failure becomes copy:

| Code / kind | Shown as |
|---|---|
| `VALIDATION_FAILED`, 400/422 | Please check the highlighted fields |
| `CATEGORY_INVALID`, `SUBCATEGORY_INVALID` | That property type is not available |
| `LOCATION_INVALID` | A property cannot sit in that location |
| `AMENITY_INVALID` | One of the selected amenities is not available any more |
| `SLUG_CONFLICT`, 409 | Another property already uses that address |
| 401 | session expired |
| 403 | your business profile must be approved |
| 404 | that property is no longer available to your account |
| timeout | the connection dropped before the server confirmed — never a success or a clean failure |

A field the server named is marked on its own control in the server's English wording, always beside
the localized summary. No status line, exception name or stack trace reaches a screen.

## 7. Saving an existing property

The backend has one endpoint per section, so an edit is a short sequence: basics → location →
contact → details → amenities. **Only the sections that actually changed are written** — each
section endpoint creates the backend's "Property updated" notification, and nobody needs four of
them for a corrected phone number; saving an untouched form writes nothing at all. The first refusal
stops the sequence; the sections already accepted stay saved, and the screen reports the refusal
rather than a save. Nothing is reported as saved that the server did not return.

## 8. What the client cannot do

* **Publish.** No partner endpoint changes `PlaceStatus`, and no control here pretends to. "Turn
  listing on" is the workspace `active` switch and is worded as one.
* **See another partner's property.** The list is owner-scoped in the backend's own query, and a
  property that is not yours answers 404 exactly like one that does not exist. The client never
  fetches a wider list and filters it.
* **Delete.** There is no delete endpoint yet (sixteen tables reference `places`), so there is no
  delete affordance.

## 9. Running it

```powershell
cd "D:\Plan Your Trip\Plan-Your-Trip-backend-v1"
$env:VOUCHER_SIGNING_SECRET="local-dev-voucher-secret-2026-plan-your-trip-32chars"
$env:SERVER_PORT="8081"
.\mvnw.cmd spring-boot:run
```

```powershell
cd "D:\Plan Your Trip\Plan-Your-Trip-integration\frontend"
flutter run -d chrome -t lib/main_partner.dart --web-port 64118
flutter test test/phase_c_property_list_test.dart test/phase_c_property_editor_test.dart
```

Sign in as an approved Partner → Hotels → **Add property** → fill the five sections → **Save draft**.
The property appears in My Properties as a draft and survives a refresh, because it is a row in the
backend, not client state.

## 10. Known limitations

- **The location of an existing property is shown, not pre-selected.** The backend returns the unit
  and its full path but no ancestors, so the cascade starts empty and the current unit is displayed
  until a new one is picked. Re-picking replaces it.
- **The slug cannot be changed from the editor.** The endpoint supports it; the editor does not
  offer it, because it is a published identifier.
- **Changing several sections at once writes one notification per section.** That is the backend's
  existing behaviour on those endpoints; the editor keeps it to a minimum by writing only what
  changed.
- **An amenity that was retired after being linked cannot be removed here.** The editor offers only
  the amenities the catalogue still returns, so a deactivated one stays selected invisibly; changing
  the rest of the set then sends it back and the backend refuses the whole set with "one of the
  selected amenities is not available any more". Nothing is silently dropped, which is the point —
  but clearing it needs an administrator to reinstate or unlink the amenity.
- **No draft is kept locally.** Closing the editor without saving discards what was typed; nothing
  is written to browser storage.
