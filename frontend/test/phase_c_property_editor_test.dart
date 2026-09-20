import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/core/partner/partner_property_models.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/partner/properties/partner_property_editor_screen.dart';
import 'package:planyourtrip_frontend/features/partner/properties/partner_property_editor_state.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_en.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_vi.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Phase C — the Partner property editor.
///
/// Every payload here is shaped exactly like the backend's own records at
/// `Plan-Your-Trip-backend-v1`:
///
///   * `PartnerHotelCreateRequest` / `PartnerHotelResponse` — `/api/partner/hotels`
///   * `CategoryResponse`, `LocationResponse`, `AmenityResponse` — the public
///     reference data the editor chooses from
///   * the Phase A error body, with `code` and `fieldErrors`
///
/// The rules asserted are the backend's, not invented ones: only accommodation
/// categories, only province/city/area locations, only property-level
/// amenities, a created property is a DRAFT, and nothing publishes.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final en = AppLocalizationsEn();
  final vi = AppLocalizationsVi();

  http.Response jsonResponse(Object body, int status) => http.Response(
        jsonEncode(body),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  /// The Phase A uniform error body.
  Map<String, dynamic> errorBody(
    int status,
    String message, {
    String? code,
    List<Map<String, String>>? fieldErrors,
  }) =>
      {
        'timestamp': DateTime.now().toIso8601String(),
        'status': status,
        'error': 'Error',
        'message': message,
        'path': '/api/partner/hotels',
        if (code != null) 'code': code,
        if (fieldErrors != null) 'fieldErrors': fieldErrors,
      };

  // ── Reference data, as the public endpoints return it ────────────────────

  const accommodationId = 1;
  const hotelId = 2;
  const resortId = 3;
  const foodId = 9;
  const restaurantId = 10;
  const retiredCategoryId = 11;

  const countryId = 100;
  const cityId = 110;
  const provinceId = 111;
  const areaId = 120;

  const wifiAmenityId = 200;
  const poolAmenityId = 201;
  const roomAmenityId = 202;
  const retiredAmenityId = 203;

  final categories = [
    {
      'id': accommodationId,
      'parentId': null,
      'name': 'Accommodation',
      'slug': 'accommodation',
      'type': 'ACCOMMODATION',
      'active': true,
    },
    {
      'id': hotelId,
      'parentId': accommodationId,
      'name': 'Hotel',
      'slug': 'hotel',
      'type': 'ACCOMMODATION',
      'active': true,
    },
    {
      'id': resortId,
      'parentId': accommodationId,
      'name': 'Resort',
      'slug': 'resort',
      'type': 'ACCOMMODATION',
      'active': true,
    },
    {
      'id': retiredCategoryId,
      'parentId': accommodationId,
      'name': 'Retired Type',
      'slug': 'retired-type',
      'type': 'ACCOMMODATION',
      'active': false,
    },
    {
      'id': foodId,
      'parentId': null,
      'name': 'Food',
      'slug': 'food',
      'type': 'FOOD',
      'active': true,
    },
    {
      'id': restaurantId,
      'parentId': foodId,
      'name': 'Restaurant',
      'slug': 'restaurant',
      'type': 'FOOD',
      'active': true,
    },
  ];

  final roots = [
    {
      'id': countryId,
      'parentId': null,
      'name': 'Vietnam',
      'slug': 'vietnam',
      'type': 'COUNTRY',
      'fullPath': 'Vietnam',
      'active': true,
    },
  ];

  final countryChildren = [
    {
      'id': cityId,
      'parentId': countryId,
      'name': 'Da Nang',
      'slug': 'da-nang',
      'type': 'CITY',
      'fullPath': 'Vietnam > Da Nang',
      'active': true,
    },
    {
      'id': provinceId,
      'parentId': countryId,
      'name': 'Lam Dong',
      'slug': 'lam-dong',
      'type': 'PROVINCE',
      'fullPath': 'Vietnam > Lam Dong',
      'active': true,
    },
  ];

  final cityChildren = [
    {
      'id': areaId,
      'parentId': cityId,
      'name': 'My Khe',
      'slug': 'my-khe',
      'type': 'AREA',
      'fullPath': 'Vietnam > Da Nang > My Khe',
      'active': true,
    },
  ];

  final amenities = [
    {
      'id': wifiAmenityId,
      'name': 'Free WiFi',
      'slug': 'free-wifi',
      'groupName': 'GENERAL',
      'active': true,
    },
    {
      'id': poolAmenityId,
      'name': 'Swimming Pool',
      'slug': 'swimming-pool',
      'groupName': 'HOTEL',
      'active': true,
    },
    {
      'id': roomAmenityId,
      'name': 'Private Bathroom',
      'slug': 'private-bathroom',
      'groupName': 'ROOM',
      'active': true,
    },
    {
      'id': retiredAmenityId,
      'name': 'Retired Amenity',
      'slug': 'retired-amenity',
      'groupName': 'HOTEL',
      'active': false,
    },
  ];

  /// `PartnerHotelResponse` as Phase C sends it back.
  Map<String, dynamic> hotelResponse({
    int id = 77,
    String name = 'Bay View Stay',
    String status = 'DRAFT',
    List<Map<String, dynamic>>? amenityRefs,
  }) =>
      {
        'id': id,
        'name': name,
        'slug': 'bay-view-stay',
        'shortDescription': 'A quiet beachfront stay',
        'description': 'A longer description.',
        'address': '15 Thuy Van',
        'latitude': 10.3459,
        'longitude': 107.0843,
        'phone': '0254123456',
        'email': 'stay@example.com',
        'website': 'https://stay.example.com',
        'facebook': null,
        'instagram': null,
        'checkIn': '14:00:00',
        'checkOut': '12:00:00',
        'childrenPolicy': null,
        'petPolicy': null,
        'smokingPolicy': null,
        'active': true,
        'featured': false,
        'verified': false,
        'ratingAvg': 0,
        'reviewCount': 0,
        'status': status,
        'ownerProfileId': 7,
        'ownerBusinessName': 'Bay View Resorts',
        'category': {
          'id': accommodationId,
          'name': 'Accommodation',
          'slug': 'accommodation',
          'type': 'ACCOMMODATION',
        },
        'subcategory': {
          'id': hotelId,
          'name': 'Hotel',
          'slug': 'hotel',
          'type': 'ACCOMMODATION',
        },
        'administrativeUnit': {
          'id': areaId,
          'name': 'My Khe',
          'slug': 'my-khe',
          'fullPath': 'Vietnam > Da Nang > My Khe',
        },
        'starRating': 3,
        'cancellationPolicy': null,
        'freeCancellation': false,
        'paymentPolicy': null,
        'prepaymentRequired': false,
        'parkingAvailable': false,
        'parkingFree': false,
        'parkingDescription': null,
        'wifiAvailable': true,
        'wifiFree': true,
        'internetDescription': null,
        'languages': ['Vietnamese'],
        'paymentMethods': ['Cash'],
        'amenities': amenityRefs ??
            [
              {
                'id': wifiAmenityId,
                'name': 'Free WiFi',
                'slug': 'free-wifi',
                'groupName': 'GENERAL',
              },
            ],
        'createdAt': '2026-09-01T02:00:00Z',
        'updatedAt': '2026-09-01T02:00:00Z',
      };

  /// Everything each request asked for, so a test can assert what was sent —
  /// and what was never sent.
  final requests = <({String method, String path, String body})>[];

  http.Client editorClient({
    Map<String, http.Response> Function()? overrides,
    bool referenceFails = false,
    bool writeThrows = false,
    Duration? delay,
  }) =>
      MockClient((request) async {
        final path = request.url.path;
        requests.add((
          method: request.method,
          path: path,
          body: request.body,
        ));
        if (delay != null) await Future<void>.delayed(delay);
        // Only the write drops: the catalogue loaded, so the editor is showing
        // a real form when the connection fails.
        if (writeThrows && request.method != 'GET') {
          throw http.ClientException('offline');
        }

        final custom = overrides?.call();
        if (custom != null) {
          for (final entry in custom.entries) {
            if (path.endsWith(entry.key)) return entry.value;
          }
        }

        if (referenceFails) {
          return jsonResponse(errorBody(500, 'boom'), 500);
        }
        if (path.endsWith('/categories')) return jsonResponse(categories, 200);
        if (path.endsWith('/amenities')) return jsonResponse(amenities, 200);
        if (path.endsWith('/locations/roots')) return jsonResponse(roots, 200);
        if (path.endsWith('/locations/$countryId/children')) {
          return jsonResponse(countryChildren, 200);
        }
        if (path.endsWith('/locations/$cityId/children')) {
          return jsonResponse(cityChildren, 200);
        }
        if (path.endsWith('/locations/$provinceId/children')) {
          return jsonResponse(<Object>[], 200);
        }
        if (request.method == 'POST' && path.endsWith('/partner/hotels')) {
          return jsonResponse(hotelResponse(), 201);
        }
        if (request.method == 'PUT' && path.contains('/partner/hotels/')) {
          return jsonResponse(hotelResponse(), 200);
        }
        return jsonResponse(errorBody(404, 'Not found'), 404);
      });

  Future<PartnerPropertyEditorState> pumpEditor(
    WidgetTester tester, {
    required http.Client client,
    PartnerPropertyDetail? existing,
    Locale? locale,
    void Function(PartnerPropertyDetail)? onSaved,
    bool settle = true,
  }) async {
    final state = PartnerPropertyEditorState(
      api: ApiClient(client: client)..demoMode = false,
      original: existing,
    );
    addTearDown(state.dispose);

    tester.view.physicalSize = const Size(1200, 3600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: PartnerPropertyEditorScreen(state: state, onSaved: onSaved),
    ));
    if (settle) await tester.pumpAndSettle();
    return state;
  }

  /// Taps a control after scrolling it into view — the editor is a long form,
  /// and a control below the fold is a real one, not a missing one.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Picks [label] from the dropdown identified by [key].
  Future<void> choose(WidgetTester tester, String key, String label) async {
    await tapVisible(tester, find.byKey(Key(key)));
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<void> fillRequired(WidgetTester tester,
      {String name = 'Bay View Stay'}) async {
    await tester.enterText(find.byKey(const Key('property-editor-name')), name);
    await tester.enterText(
        find.byKey(const Key('property-editor-address')), '15 Thuy Van');
    await tester.pumpAndSettle();
  }

  Map<String, dynamic> lastBody(String method, String pathEnd) {
    final match = requests.lastWhere(
      (entry) => entry.method == method && entry.path.endsWith(pathEnd),
    );
    return jsonDecode(match.body) as Map<String, dynamic>;
  }

  bool sent(String method, String pathEnd) => requests
      .any((entry) => entry.method == method && entry.path.endsWith(pathEnd));

  setUp(requests.clear);

  // ── 1. Reference data ────────────────────────────────────────────────────

  group('reference data', () {
    testWidgets(
        'offers only the accommodation categories the catalogue returned',
        (tester) async {
      await pumpEditor(tester, client: editorClient());

      // The only accommodation root is pre-selected, so the partner does not
      // have to make a choice with one option.
      expect(find.text('Accommodation'), findsOneWidget);

      await tester.tap(find.byKey(const Key('property-editor-subcategory')));
      await tester.pumpAndSettle();
      expect(find.text('Hotel'), findsWidgets);
      expect(find.text('Resort'), findsWidgets);
      // Not an accommodation type, and a deactivated one: neither is offered,
      // because the backend would refuse both.
      expect(find.text('Restaurant'), findsNothing);
      expect(find.text('Retired Type'), findsNothing);
    });

    testWidgets('offers only amenities that describe a property',
        (tester) async {
      await pumpEditor(tester, client: editorClient());

      expect(find.byKey(const Key('property-editor-amenity-$wifiAmenityId')),
          findsOneWidget);
      expect(find.byKey(const Key('property-editor-amenity-$poolAmenityId')),
          findsOneWidget);
      // ROOM belongs to a room, and an inactive amenity to nobody.
      expect(find.byKey(const Key('property-editor-amenity-$roomAmenityId')),
          findsNothing);
      expect(find.byKey(const Key('property-editor-amenity-$retiredAmenityId')),
          findsNothing);
    });

    testWidgets('a catalogue that cannot be read shows an error, not a form',
        (tester) async {
      await pumpEditor(tester, client: editorClient(referenceFails: true));

      expect(find.byKey(const Key('property-editor-reference-error')),
          findsOneWidget);
      expect(find.text(en.partnerPropertyReferenceError), findsOneWidget);
      // No form at all: an editor without the catalogue could only offer ids it
      // invented.
      expect(find.byKey(const Key('property-editor-name')), findsNothing);
      expect(find.byKey(const Key('property-editor-save')), findsNothing);
    });

    testWidgets('shows a loading state while the catalogue is read',
        (tester) async {
      await pumpEditor(
        tester,
        client: editorClient(delay: const Duration(milliseconds: 80)),
        settle: false,
      );
      await tester.pump();

      expect(find.text(en.partnerPropertyReferenceLoading), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('property-editor-name')), findsOneWidget);
    });
  });

  // ── 2. Validation ────────────────────────────────────────────────────────

  group('validation', () {
    testWidgets('refuses to submit an empty form and sends nothing',
        (tester) async {
      await pumpEditor(tester, client: editorClient());

      await tapVisible(tester, find.byKey(const Key('property-editor-save')));

      expect(find.text(en.partnerPropertyValidationName), findsOneWidget);
      expect(find.text(en.partnerPropertyValidationAddress), findsOneWidget);
      expect(sent('POST', '/partner/hotels'), isFalse);
    });

    testWidgets('refuses coordinates outside the geographic range',
        (tester) async {
      await pumpEditor(tester, client: editorClient());
      await fillRequired(tester);

      await tester.enterText(
          find.byKey(const Key('property-editor-latitude')), '95');
      await tester.enterText(
          find.byKey(const Key('property-editor-longitude')), '200');
      await tapVisible(tester, find.byKey(const Key('property-editor-save')));

      expect(find.text(en.partnerPropertyValidationLatitude), findsOneWidget);
      expect(find.text(en.partnerPropertyValidationLongitude), findsOneWidget);
      expect(sent('POST', '/partner/hotels'), isFalse);
    });

    testWidgets('refuses a malformed time and a malformed email',
        (tester) async {
      await pumpEditor(tester, client: editorClient());
      await fillRequired(tester);

      await tester.enterText(
          find.byKey(const Key('property-editor-check-in')), '25:00');
      await tester.enterText(
          find.byKey(const Key('property-editor-email')), 'not-an-email');
      await tapVisible(tester, find.byKey(const Key('property-editor-save')));

      expect(find.text(en.partnerPropertyValidationTime), findsOneWidget);
      expect(find.text(en.partnerPropertyValidationEmail), findsOneWidget);
      expect(sent('POST', '/partner/hotels'), isFalse);
    });

    testWidgets('a property with no location chosen is not submitted',
        (tester) async {
      // The country has exactly one child level in this catalogue, and nothing
      // below it is picked, so there is no province or area yet.
      await pumpEditor(tester, client: editorClient());
      await fillRequired(tester);

      await tapVisible(tester, find.byKey(const Key('property-editor-save')));

      expect(find.text(en.partnerPropertyValidationLocation), findsOneWidget);
      expect(sent('POST', '/partner/hotels'), isFalse);
    });
  });

  // ── 3. Create ────────────────────────────────────────────────────────────

  group('create', () {
    testWidgets('sends exactly what the form describes, and no status or owner',
        (tester) async {
      PartnerPropertyDetail? saved;
      await pumpEditor(
        tester,
        client: editorClient(),
        onSaved: (detail) => saved = detail,
      );
      await fillRequired(tester);
      await choose(tester, 'property-editor-subcategory', 'Hotel');
      await choose(tester, 'property-editor-province', 'Da Nang');
      await choose(tester, 'property-editor-area', 'My Khe');
      await tapVisible(tester,
          find.byKey(const Key('property-editor-amenity-$poolAmenityId')));
      await tester.enterText(find.byKey(const Key('property-editor-languages')),
          'Vietnamese, English');

      await tapVisible(tester, find.byKey(const Key('property-editor-save')));

      final body = lastBody('POST', '/partner/hotels');
      expect(body['name'], 'Bay View Stay');
      expect(body['address'], '15 Thuy Van');
      expect(body['categoryId'], accommodationId);
      expect(body['subcategoryId'], hotelId);
      // The deepest unit chosen — the area, not the city it sits in.
      expect(body['administrativeUnitId'], areaId);
      expect(body['checkIn'], '14:00:00');
      expect(body['checkOut'], '12:00:00');
      expect(body['starRating'], 3);
      expect(body['amenityIds'], [poolAmenityId]);
      expect(body['languages'], ['Vietnamese', 'English']);
      // Nothing that would publish, re-own or moderate the property.
      expect(body.containsKey('status'), isFalse);
      expect(body.containsKey('ownerProfileId'), isFalse);
      expect(body.containsKey('featured'), isFalse);
      expect(body.containsKey('verified'), isFalse);
      expect(body.containsKey('slug'), isFalse);

      expect(saved, isNotNull);
      expect(saved!.status, PartnerPlaceStatus.draft);
      expect(find.text(en.partnerPropertyCreatedMessage('Bay View Stay')),
          findsOneWidget);
    });

    testWidgets('a save in flight cannot be submitted twice', (tester) async {
      final state = await pumpEditor(
        tester,
        client: editorClient(delay: const Duration(milliseconds: 120)),
      );
      await tester.pumpAndSettle();
      await fillRequired(tester);
      await choose(tester, 'property-editor-province', 'Da Nang');

      await tester.ensureVisible(find.byKey(const Key('property-editor-save')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('property-editor-save')));
      await tester.pump();

      // The control itself is gone while the request is in flight, so there is
      // nothing left to tap a second time…
      expect(find.byKey(const Key('property-editor-save')), findsNothing);
      expect(state.isSaving, isTrue);

      // …and the state refuses a concurrent save regardless of the UI.
      const text = PropertyFormText(
        name: 'Second',
        address: '1 Second Street',
        checkIn: '14:00',
        checkOut: '12:00',
      );
      expect(await state.save(text), isNull);
      await tester.pumpAndSettle();

      final creates = requests
          .where((entry) =>
              entry.method == 'POST' && entry.path.endsWith('/partner/hotels'))
          .length;
      expect(creates, 1);
    });

    testWidgets('the editor offers no publish action at all', (tester) async {
      await pumpEditor(tester, client: editorClient());

      expect(find.text(en.partnerPropertyStatusPublished), findsNothing);
      expect(find.text(en.partnerPropertyActivateAction), findsNothing);
      expect(find.text(en.partnerPropertyVisibilityPublic), findsNothing);
      expect(find.text(en.partnerPropertyDraftNotice), findsOneWidget);
    });

    testWidgets('says plainly that the rating is the partner\'s own claim',
        (tester) async {
      await pumpEditor(tester, client: editorClient());
      expect(find.text(en.partnerPropertyStarRatingHelp), findsOneWidget);
    });
  });

  // ── 4. Server refusals ───────────────────────────────────────────────────

  group('server refusals', () {
    Future<void> submitCreate(WidgetTester tester) async {
      await fillRequired(tester);
      await choose(tester, 'property-editor-province', 'Da Nang');
      await tapVisible(tester, find.byKey(const Key('property-editor-save')));
    }

    testWidgets('a field error is shown on the field the backend named',
        (tester) async {
      await pumpEditor(
        tester,
        client: editorClient(
          overrides: () => {
            '/partner/hotels': jsonResponse(
              errorBody(422, 'A property must use an accommodation category: 9',
                  code: 'CATEGORY_INVALID',
                  fieldErrors: [
                    {
                      'field': 'categoryId',
                      'message':
                          'A property must use an accommodation category',
                    }
                  ]),
              422,
            ),
          },
        ),
      );
      await submitCreate(tester);

      // The localized summary, plus the backend's own wording on the control.
      expect(find.text(en.partnerPropertyErrorCategory), findsOneWidget);
      expect(find.text('A property must use an accommodation category'),
          findsOneWidget);
      // Nothing claims a save.
      expect(find.text(en.partnerPropertyCreatedMessage('Bay View Stay')),
          findsNothing);
    });

    testWidgets('a validation failure keeps every typed value', (tester) async {
      await pumpEditor(
        tester,
        client: editorClient(
          overrides: () => {
            '/partner/hotels': jsonResponse(
              errorBody(400, 'name: must not be blank',
                  code: 'VALIDATION_FAILED',
                  fieldErrors: [
                    {'field': 'name', 'message': 'must not be blank'}
                  ]),
              400,
            ),
          },
        ),
      );
      await submitCreate(tester);

      expect(find.text(en.partnerPropertyErrorValidation), findsOneWidget);
      expect(find.text('must not be blank'), findsOneWidget);
      // The form still holds what was typed.
      expect(find.text('Bay View Stay'), findsOneWidget);
      expect(find.text('15 Thuy Van'), findsOneWidget);
    });

    testWidgets('a session that is gone reads as a session, not a form error',
        (tester) async {
      await pumpEditor(
        tester,
        client: editorClient(
          overrides: () => {
            '/partner/hotels':
                jsonResponse(errorBody(401, 'Authentication required'), 401),
          },
        ),
      );
      await submitCreate(tester);

      expect(find.text(en.partnerDashboardErrorUnauthorized), findsOneWidget);
    });

    testWidgets('403 is reported as the approval gate it is', (tester) async {
      await pumpEditor(
        tester,
        client: editorClient(
          overrides: () => {
            '/partner/hotels': jsonResponse(
                errorBody(403, 'Partner profile is not approved'), 403),
          },
        ),
      );
      await submitCreate(tester);

      expect(find.text(en.partnerPropertyErrorApproval), findsOneWidget);
    });

    testWidgets('a dropped connection never reports a save', (tester) async {
      await pumpEditor(tester, client: editorClient(writeThrows: true));
      await submitCreate(tester);

      expect(find.text(en.partnerDashboardErrorNetwork), findsOneWidget);
      expect(find.text(en.partnerPropertyCreatedMessage('Bay View Stay')),
          findsNothing);
      // Still on the editor, with the typed values intact.
      expect(find.byKey(const Key('property-editor-save')), findsOneWidget);
      expect(find.text('Bay View Stay'), findsOneWidget);
    });
  });

  // ── 5. Edit ──────────────────────────────────────────────────────────────

  group('edit', () {
    PartnerPropertyDetail existing() =>
        PartnerPropertyDetail.fromJson(hotelResponse())!;

    testWidgets('loads the stored property into the form', (tester) async {
      await pumpEditor(tester, client: editorClient(), existing: existing());

      expect(find.text('Bay View Stay'), findsOneWidget);
      expect(find.text('15 Thuy Van'), findsOneWidget);
      // The location it already has is shown rather than re-derived.
      expect(find.text('Vietnam > Da Nang > My Khe'), findsOneWidget);
      expect(find.text(en.partnerPropertyEditorEditTitle), findsWidgets);
      // The slug is shown and cannot be typed into: it is the public address.
      expect(find.text('bay-view-stay'), findsOneWidget);
      expect(find.text(en.partnerPropertySlugHelp), findsOneWidget);
    });

    testWidgets('saves every changed section and keeps the slug',
        (tester) async {
      await pumpEditor(tester, client: editorClient(), existing: existing());

      await tester.enterText(
          find.byKey(const Key('property-editor-name')), 'Bay View Renamed');
      await tester.enterText(
          find.byKey(const Key('property-editor-address')), '9 New Street');
      await tester.enterText(
          find.byKey(const Key('property-editor-email')), 'new@example.com');
      await tester.enterText(
          find.byKey(const Key('property-editor-check-in')), '15:00');
      await tapVisible(tester, find.byKey(const Key('property-editor-save')));

      final basics = lastBody('PUT', '/partner/hotels/77');
      expect(basics['name'], 'Bay View Renamed');
      // The public identifier goes back exactly as it was read.
      expect(basics['slug'], 'bay-view-stay');
      expect(basics['categoryId'], accommodationId);

      final placement = lastBody('PUT', '/partner/hotels/77/location');
      expect(placement['address'], '9 New Street');
      // Untouched location: the unit the property already has.
      expect(placement['administrativeUnitId'], areaId);

      final contact = lastBody('PUT', '/partner/hotels/77/contact');
      expect(contact['email'], 'new@example.com');

      final details = lastBody('PUT', '/partner/hotels/77/policies');
      expect(details['checkIn'], '15:00:00');
      expect(details['starRating'], 3);

      // The amenity set was not touched, so it is not rewritten.
      expect(sent('PUT', '/partner/hotels/77/amenities'), isFalse);
      expect(find.text(en.partnerPropertySavedMessage('Bay View Stay')),
          findsOneWidget);
    });

    testWidgets('writes only the sections that changed', (tester) async {
      await pumpEditor(tester, client: editorClient(), existing: existing());

      await tester.enterText(
          find.byKey(const Key('property-editor-name')), 'Bay View Renamed');
      await tapVisible(tester, find.byKey(const Key('property-editor-save')));

      // Each section endpoint writes its own "Property updated" notification,
      // so an untouched section must not be written at all.
      expect(sent('PUT', '/partner/hotels/77'), isTrue);
      expect(sent('PUT', '/partner/hotels/77/location'), isFalse);
      expect(sent('PUT', '/partner/hotels/77/contact'), isFalse);
      expect(sent('PUT', '/partner/hotels/77/policies'), isFalse);
      expect(sent('PUT', '/partner/hotels/77/amenities'), isFalse);
    });

    testWidgets('saving an untouched form writes nothing at all',
        (tester) async {
      await pumpEditor(tester, client: editorClient(), existing: existing());

      await tapVisible(tester, find.byKey(const Key('property-editor-save')));

      expect(
        requests.where((entry) => entry.method != 'GET'),
        isEmpty,
        reason: 'nothing changed, so there is nothing to write',
      );
    });

    testWidgets('a changed amenity set is replaced wholesale', (tester) async {
      await pumpEditor(tester, client: editorClient(), existing: existing());

      await tapVisible(tester,
          find.byKey(const Key('property-editor-amenity-$poolAmenityId')));
      await tapVisible(tester, find.byKey(const Key('property-editor-save')));

      final body = lastBody('PUT', '/partner/hotels/77/amenities');
      expect(
        (body['amenityIds'] as List).cast<int>().toSet(),
        {wifiAmenityId, poolAmenityId},
      );
    });

    testWidgets('a refusal stops the sequence and says so', (tester) async {
      await pumpEditor(
        tester,
        client: editorClient(
          overrides: () => {
            '/partner/hotels/77': jsonResponse(
                errorBody(409, 'Slug already in use: bay-view-stay',
                    code: 'SLUG_CONFLICT'),
                409),
          },
        ),
        existing: existing(),
      );

      // Change something in every section, so the refusal below is what stops
      // the sequence rather than the section simply not being dirty.
      await tester.enterText(
          find.byKey(const Key('property-editor-name')), 'Bay View Renamed');
      await tester.enterText(
          find.byKey(const Key('property-editor-address')), '9 New Street');
      await tapVisible(tester, find.byKey(const Key('property-editor-save')));

      expect(find.text(en.partnerPropertyErrorSlugConflict), findsOneWidget);
      // The first section failed, so nothing after it was attempted.
      expect(sent('PUT', '/partner/hotels/77/location'), isFalse);
      expect(sent('PUT', '/partner/hotels/77/policies'), isFalse);
      expect(find.text(en.partnerPropertySavedMessage('Bay View Stay')),
          findsNothing);
    });
  });

  // ── 6. Localization ──────────────────────────────────────────────────────

  group('localization', () {
    testWidgets('Vietnamese renders Vietnamese strings', (tester) async {
      await pumpEditor(
        tester,
        client: editorClient(),
        locale: const Locale('vi'),
      );

      expect(find.text(vi.partnerPropertyEditorCreateTitle), findsWidgets);
      expect(find.text(vi.partnerPropertyFieldName), findsOneWidget);
      expect(find.text(en.partnerPropertyFieldName), findsNothing);
    });

    testWidgets('every Phase C editor string exists in both locales',
        (tester) async {
      for (final pair in <List<String>>[
        [en.partnerPropertyAddAction, vi.partnerPropertyAddAction],
        [en.partnerPropertyEditAction, vi.partnerPropertyEditAction],
        [en.partnerPropertyEditorIntro, vi.partnerPropertyEditorIntro],
        [en.partnerPropertyFieldStarRating, vi.partnerPropertyFieldStarRating],
        [en.partnerPropertyStarRatingHelp, vi.partnerPropertyStarRatingHelp],
        [en.partnerPropertyErrorCategory, vi.partnerPropertyErrorCategory],
        [en.partnerPropertyErrorLocation, vi.partnerPropertyErrorLocation],
        [en.partnerPropertyErrorAmenity, vi.partnerPropertyErrorAmenity],
        [en.partnerPropertyGateTitle, vi.partnerPropertyGateTitle],
        [en.partnerPropertyDraftNotice, vi.partnerPropertyDraftNotice],
      ]) {
        expect(pair[0].isNotEmpty, isTrue);
        expect(pair[1].isNotEmpty, isTrue);
        expect(pair[0], isNot(pair[1]));
      }
    });
  });
}
