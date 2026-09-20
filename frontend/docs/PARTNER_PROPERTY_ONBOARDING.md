# Partner property onboarding (Phase D)

The step-by-step way a Partner sets a property up. It is an **orchestration layer over the Phase C
property API** (`PARTNER_PROPERTY.md`) — no wizard entity, no wizard endpoint, no new table, and
nothing here publishes.

## 1. The flow

```
My properties ─► + Add property ─────────────────► Property onboarding
      │                                                    │
      │  a draft row ─► Continue setup ──────────►  (same wizard, same draft)
      │                                                    │
      ▼                                                    ▼
  0 Business profile ─ 1 Basics ─ 2 Location ─ 3 Contact ─ 4 Amenities ─ 5 Details ─ 6 Review
                                                                                       │
                                                                             Save draft │
                                                                                       ▼
                                                                          DRAFT in My properties
```

Editing an existing property one section at a time still opens the Phase C editor from the detail
panel (**Edit property**); the wizard is for setting one up.

## 2. The steps

| Step | What it asks | Required to continue |
|---|---|---|
| 0 Business profile | a **read-only summary** of the business profile and its status | the profile is `APPROVED` |
| 1 Property basics | name, short description, description, type, specific type, property rating | name, type, rating |
| 2 Location | country → province/city → area, street address, optional coordinates | a province/city/area **and** an address |
| 3 Contact | phone, email, website | nothing (a given email must be valid) |
| 4 Amenities | the catalogue's property-level amenities, searchable | nothing |
| 5 Details and policies | check-in/out, children/pet/smoking/cancellation, parking, Wi-Fi, languages, payment methods | valid `HH:MM` times |
| 6 Review | every section with its completeness, and **Fix** jumps | — |

Step 0 is a checkpoint, not a second business-profile form: the details belong to the account area,
and **Open business profile** goes there.

## 3. When the draft is actually created

`PartnerHotelCreateRequest` requires `name`, `categoryId`, `administrativeUnitId`, `address`,
`starRating`, `checkIn` **and** `checkOut` — the last two live in step 5, and the columns behind
them are `NOT NULL`. So for a **new** property:

* steps 1–4: **Save draft** is disabled and says why ("your draft is stored once the basics, the
  location and the check-in times are complete"). Nothing is fabricated to make an earlier save
  possible — no invented rating, no invented time.
* step 5 onward: **Save draft** creates the property with one `POST`, carrying everything collected
  so far (including the amenities).
* after that: each **Save draft** writes only the sections that changed.

For a **resumed** draft every step can save immediately, because the record already exists.

## 4. Save, resume, refresh

* **Save draft** is explicit. There is no keystroke auto-save; dirty tracking means an unchanged
  section is never written, and saving an untouched wizard sends nothing at all.
* The action bar states the save state honestly: *Saving…*, *Saved just now*, *Saved at 22:31*,
  *Everything here is already saved*, or the reason a save is not possible yet. "Saved" appears only
  after the server confirmed.
* **Resume**: a draft row shows **Continue setup**, which reopens *that* property (`GET
  /api/partner/hotels/{id}`) — never a second one. The wizard then computes which steps are complete
  from the loaded record and opens at the first that is not; everything already done stays
  reachable from the progress rail.
* **Refresh** loses nothing that was saved, because the draft is a row in the backend. Anything
  typed but not saved is not persisted anywhere — see §7.

## 5. Unsaved changes

Leaving with changes the draft does not have asks first: **Save draft**, **Discard changes** or
**Keep editing**. Discard returns every field to what the server holds (or clears the form for a
property that does not exist yet). A refused save keeps the wizard open with everything intact.

## 6. Draft, and nothing more

Every screen of the wizard carries *"Draft — not visible to travellers"*, and the property list
repeats it on each non-published row. There is **no publish action**: `PlaceStatus` is
administrative, `active` is a workspace switch and not publication, and Phase A's
`PublicListingVisibility` keeps everything but `PUBLISHED` out of the public APIs. Rooms, media,
pricing, availability and traveller-facing integration are later phases and appear nowhere here.

## 7. Files

| Piece | File |
|---|---|
| State machine, validation, dirty tracking, saving | `features/partner/properties/wizard/property_wizard_state.dart` |
| Shell: progress rail / compact line, action bar, exit dialog | `…/wizard/property_wizard_screen.dart` |
| Step bodies and the review | `…/wizard/property_wizard_steps.dart` |
| Catalogue + location cascade (shared with the Phase C editor) | `core/partner/property_catalogue.dart` |
| Payloads, failures, copy | the Phase C `partner_property_form_models.dart`, `api_failure.dart`, `property_messages.dart` |

## 8. Accessibility and layout

The step heading takes focus after every step change and is announced as "Step 3 of 7: Location".
Progress entries are buttons with their state in words ("Complete"), never colour alone. A desktop
width shows the rail beside the form; below a tablet it becomes a compact step line with a progress
bar, and the action bar stays at the bottom.

## 9. Known limitations

- **A new property cannot be saved before step 5** (§3). The alternative would be inventing a
  check-in time or a rating, which the product forbids; the other alternative is a schema change,
  which Phase D does not make.
- **The location cascade starts empty on a resumed draft.** The backend returns the unit and its
  full path but not its ancestors, so the wizard shows the stored location and only replaces it once
  a new province/area is picked.
- **Nothing typed is kept across a browser refresh until it is saved.** Browser storage is
  deliberately not used as a draft store: the backend record is the only source of truth.
- **The review reflects the wizard's own values**, which equal the stored record after a save. It is
  not a second read of the server.

## 10. Running it

```powershell
cd "D:\Plan Your Trip\Plan-Your-Trip-backend-v1"
$env:VOUCHER_SIGNING_SECRET="local-dev-voucher-secret-2026-plan-your-trip-32chars"
$env:SERVER_PORT="8081"
.\mvnw.cmd spring-boot:run
```

```powershell
cd "D:\Plan Your Trip\Plan-Your-Trip-integration\frontend"
flutter run -d chrome -t lib/main_partner.dart --web-port 64118
flutter test test/phase_d_property_wizard_test.dart
```

Sign in as an approved Partner → Hotels → **Add property** → walk the steps → **Save draft** →
leave → **Continue setup** on the draft row.
