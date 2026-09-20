import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/core/partner/partner_models.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/partner/properties/wizard/property_wizard_screen.dart';
import 'package:planyourtrip_frontend/features/partner/properties/wizard/property_wizard_state.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_en.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_vi.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Phase D — the Partner property onboarding wizard.
///
/// The wizard is an orchestration layer over the Phase C API, so every payload
/// here is the backend's own: `PartnerHotelCreateRequest`, the section `PUT`s
/// and the Phase A error body with `code` and `fieldErrors`. What the tests
/// assert is the wizard's contract with the partner:
///
///   * an unapproved business profile cannot start a property;
///   * a step with missing required data cannot be left;
///   * a draft is created only when the server can actually store one, and only
///     the sections that changed are written afterwards;
///   * a resumed draft is read from the backend and opens where work stopped;
///   * nothing publishes, and nothing claims a save the server did not confirm.
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

  // ── The admin-managed catalogue ──────────────────────────────────────────

  const accommodationId = 1;
  const hotelId = 2;
  const resortId = 3;
  const foodId = 9;
  const countryId = 100;
  const cityId = 110;
  const otherCityId = 111;
  const areaId = 120;
  const otherAreaId = 121;
  const wifiAmenityId = 200;
  const poolAmenityId = 201;
  const roomAmenityId = 202;

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
      'id': foodId,
      'parentId': null,
      'name': 'Food',
      'slug': 'food',
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
      'id': otherCityId,
      'parentId': countryId,
      'name': 'Nha Trang',
      'slug': 'nha-trang',
      'type': 'CITY',
      'fullPath': 'Vietnam > Nha Trang',
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

  final otherCityChildren = [
    {
      'id': otherAreaId,
      'parentId': otherCityId,
      'name': 'Tran Phu',
      'slug': 'tran-phu',
      'type': 'AREA',
      'fullPath': 'Vietnam > Nha Trang > Tran Phu',
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
  ];

  /// `PartnerHotelResponse` — a complete DRAFT, as the backend returns one.
  Map<String, dynamic> hotelResponse({
    int id = 77,
    String name = 'Bay View Stay',
    String status = 'DRAFT',
    Object? phone = '0254123456',
    Object? checkIn = '14:00:00',
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
        'phone': phone,
        'email': 'stay@example.com',
        'website': 'https://stay.example.com',
        'facebook': null,
        'instagram': null,
        'checkIn': checkIn,
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

  PartnerProfile profile({
    PartnerVerificationStatus status = PartnerVerificationStatus.approved,
    String? rejectReason,
  }) =>
      PartnerProfile(
        id: 7,
        userId: 42,
        businessName: 'Bay View Resorts',
        representativeName: 'Le Minh',
        verificationStatus: status,
        phone: '0901234567',
        email: 'ops@bayview.example',
        rejectReason: rejectReason,
      );

  final requests = <({String method, String path, String body})>[];

  http.Client wizardClient({
    Map<String, http.Response> Function()? overrides,
    Map<String, dynamic> Function()? detail,
    List<Map<String, dynamic>>? categoryList,
    bool catalogueFails = false,
    bool writeThrows = false,
    Duration? delay,
  }) =>
      MockClient((request) async {
        final path = request.url.path;
        requests.add((method: request.method, path: path, body: request.body));
        if (delay != null) await Future<void>.delayed(delay);
        if (writeThrows && request.method != 'GET') {
          throw http.ClientException('offline');
        }

        final custom = overrides?.call();
        if (custom != null) {
          for (final entry in custom.entries) {
            if (path.endsWith(entry.key)) return entry.value;
          }
        }
        if (catalogueFails) return jsonResponse(errorBody(500, 'boom'), 500);

        if (path.endsWith('/categories')) {
          return jsonResponse(categoryList ?? categories, 200);
        }
        if (path.endsWith('/amenities')) return jsonResponse(amenities, 200);
        if (path.endsWith('/locations/roots')) return jsonResponse(roots, 200);
        if (path.endsWith('/locations/$countryId/children')) {
          return jsonResponse(countryChildren, 200);
        }
        if (path.endsWith('/locations/$cityId/children')) {
          return jsonResponse(cityChildren, 200);
        }
        if (path.endsWith('/locations/$otherCityId/children')) {
          return jsonResponse(otherCityChildren, 200);
        }
        if (request.method == 'POST' && path.endsWith('/partner/hotels')) {
          return jsonResponse(hotelResponse(), 201);
        }
        if (request.method == 'PUT' && path.contains('/partner/hotels/')) {
          return jsonResponse(hotelResponse(), 200);
        }
        if (request.method == 'GET' && path.contains('/partner/hotels/')) {
          return jsonResponse(detail?.call() ?? hotelResponse(), 200);
        }
        return jsonResponse(errorBody(404, 'Not found'), 404);
      });

  Future<PropertyWizardState> pumpWizard(
    WidgetTester tester, {
    required http.Client client,
    PartnerVerificationStatus profileStatus =
        PartnerVerificationStatus.approved,
    String? rejectReason,
    int? resumeId,
    Locale? locale,
    Size size = const Size(1280, 2400),
    bool settle = true,
  }) async {
    final state = PropertyWizardState(
      api: ApiClient(client: client)..demoMode = false,
      profile: profile(status: profileStatus, rejectReason: rejectReason),
      resumePropertyId: resumeId,
    );
    addTearDown(state.dispose);

    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: PartnerPropertyWizardScreen(state: state),
    ));
    if (settle) await tester.pumpAndSettle();
    return state;
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester, String key, String label) async {
    await tapVisible(tester, find.byKey(Key(key)));
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<void> continueStep(WidgetTester tester) =>
      tapVisible(tester, find.byKey(const Key('wizard-continue')));

  /// Fills every required field of a new property, leaving the wizard on the
  /// review step.
  Future<void> completeAllSteps(
    WidgetTester tester, {
    String name = 'Bay View Stay',
  }) async {
    await continueStep(tester); // business profile
    await tester.enterText(find.byKey(const Key('wizard-name')), name);
    await choose(tester, 'wizard-subcategory', 'Hotel');
    await choose(tester, 'wizard-star-rating', '3');
    await continueStep(tester); // basics
    await choose(tester, 'wizard-province', 'Da Nang');
    await choose(tester, 'wizard-area', 'My Khe');
    await tester.enterText(
        find.byKey(const Key('wizard-address')), '15 Thuy Van');
    await tester.pumpAndSettle();
    await continueStep(tester); // location
    await continueStep(tester); // contact
    await continueStep(tester); // amenities
    await continueStep(tester); // policies -> review
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

  // ── 1. Entry and the approval gate ───────────────────────────────────────

  group('entry and the approval gate', () {
    testWidgets('opens on the business-profile readiness step', (tester) async {
      await pumpWizard(tester, client: wizardClient());

      expect(find.text(en.partnerWizardStepBusinessProfile), findsWidgets);
      expect(find.byKey(const Key('wizard-profile-status')), findsOneWidget);
      expect(find.text(en.partnerWizardProfileApproved), findsOneWidget);
      // The draft nature of the whole flow is stated from the first screen.
      expect(find.byKey(const Key('wizard-draft-banner')), findsOneWidget);
      expect(find.text(en.partnerWizardStepOf(1, 7)), findsOneWidget);
    });

    testWidgets('an approved profile may continue', (tester) async {
      final state = await pumpWizard(tester, client: wizardClient());

      await continueStep(tester);

      expect(state.currentStep, PropertyWizardStep.basics);
      expect(find.byKey(const Key('wizard-name')), findsOneWidget);
    });

    testWidgets('a profile awaiting approval cannot continue', (tester) async {
      final state = await pumpWizard(
        tester,
        client: wizardClient(),
        profileStatus: PartnerVerificationStatus.submitted,
      );

      expect(find.text(en.partnerWizardProfileBlocked), findsOneWidget);
      expect(find.text(en.partnerBusinessStatusSubmittedBody), findsOneWidget);

      await continueStep(tester);

      expect(state.currentStep, PropertyWizardStep.businessProfile);
      expect(find.byKey(const Key('wizard-step-error')), findsOneWidget);
      // Nothing is created on the way past a gate that did not open.
      expect(sent('POST', '/partner/hotels'), isFalse);
    });

    testWidgets('a rejected profile shows the reason and the way to fix it',
        (tester) async {
      await pumpWizard(
        tester,
        client: wizardClient(),
        profileStatus: PartnerVerificationStatus.rejected,
        rejectReason: 'Business licence unreadable',
      );

      expect(find.text(en.partnerBusinessStatusRejectedBody), findsOneWidget);
      expect(
          find.text(
              en.partnerBusinessRejectReason('Business licence unreadable')),
          findsOneWidget);
      expect(find.byKey(const Key('wizard-profile-edit')), findsOneWidget);
    });

    testWidgets('the readiness step summarises the profile, never re-asks it',
        (tester) async {
      await pumpWizard(tester, client: wizardClient());

      expect(find.text('Bay View Resorts'), findsOneWidget);
      expect(find.text('Le Minh'), findsOneWidget);
      // A summary, not a second business-profile form.
      expect(find.byType(TextFormField), findsNothing);
    });

    testWidgets('a catalogue that cannot be read shows an error, not a form',
        (tester) async {
      await pumpWizard(tester, client: wizardClient(catalogueFails: true));

      expect(find.byKey(const Key('wizard-reference-error')), findsOneWidget);
      expect(find.byKey(const Key('wizard-continue')), findsNothing);
    });
  });

  // ── 2. Step validation ───────────────────────────────────────────────────

  group('step validation', () {
    testWidgets('basics cannot be left without name, type and rating',
        (tester) async {
      final state = await pumpWizard(tester, client: wizardClient());
      await continueStep(tester);

      await continueStep(tester);

      expect(state.currentStep, PropertyWizardStep.basics);
      expect(find.byKey(const Key('wizard-step-error')), findsOneWidget);
      expect(find.text(en.partnerPropertyValidationName), findsOneWidget);
      // Never defaulted: the rating is the partner's own declaration.
      expect(state.starRating, isNull);
      expect(find.text(en.partnerPropertyValidationStarRating), findsOneWidget);
    });

    testWidgets('choosing a category resets the specific type', (tester) async {
      // A catalogue with two accommodation roots, so the category itself is a
      // real choice rather than the single option the wizard pre-selects.
      const secondRootId = 20;
      const apartmentId = 21;
      final state = await pumpWizard(
        tester,
        client: wizardClient(categoryList: [
          ...categories,
          {
            'id': secondRootId,
            'parentId': null,
            'name': 'Serviced Living',
            'slug': 'serviced-living',
            'type': 'ACCOMMODATION',
            'active': true,
          },
          {
            'id': apartmentId,
            'parentId': secondRootId,
            'name': 'Apartment',
            'slug': 'apartment',
            'type': 'ACCOMMODATION',
            'active': true,
          },
        ]),
      );
      await continueStep(tester);

      await choose(tester, 'wizard-category', 'Accommodation');
      await choose(tester, 'wizard-subcategory', 'Resort');
      expect(state.subcategoryId, resortId);

      // Re-picking the parent cannot leave a child of the old one behind.
      await choose(tester, 'wizard-category', 'Serviced Living');
      expect(state.categoryId, secondRootId);
      expect(state.subcategoryId, isNull);
      await choose(tester, 'wizard-subcategory', 'Apartment');
      expect(state.subcategoryId, apartmentId);
    });

    testWidgets('location cannot be left without a unit and an address',
        (tester) async {
      final state = await pumpWizard(tester, client: wizardClient());
      await continueStep(tester);
      await tester.enterText(find.byKey(const Key('wizard-name')), 'Bay View');
      await choose(tester, 'wizard-star-rating', '3');
      await continueStep(tester);

      await continueStep(tester);
      expect(state.currentStep, PropertyWizardStep.location);
      expect(find.text(en.partnerPropertyValidationAddress), findsOneWidget);
    });

    testWidgets('changing the province clears the area below it',
        (tester) async {
      final state = await pumpWizard(tester, client: wizardClient());
      await continueStep(tester);
      await tester.enterText(find.byKey(const Key('wizard-name')), 'Bay View');
      await choose(tester, 'wizard-star-rating', '3');
      await continueStep(tester);

      await choose(tester, 'wizard-province', 'Da Nang');
      await choose(tester, 'wizard-area', 'My Khe');
      expect(state.selectedLocationId, areaId);

      await choose(tester, 'wizard-province', 'Nha Trang');
      // The area of the previous city is not a location in the new one.
      expect(state.catalogue.areaId, isNull);
      expect(state.selectedLocationId, otherCityId);
    });

    testWidgets('an invalid email blocks the contact step', (tester) async {
      final state = await pumpWizard(tester, client: wizardClient());
      await completeAllStepsUpToContact(tester);

      await tester.enterText(
          find.byKey(const Key('wizard-email')), 'not-an-email');
      await tester.pumpAndSettle();
      await continueStep(tester);

      expect(state.currentStep, PropertyWizardStep.contact);
      expect(find.text(en.partnerPropertyValidationEmail), findsOneWidget);
    });

    testWidgets('a malformed check-in time blocks the details step',
        (tester) async {
      final state = await pumpWizard(tester, client: wizardClient());
      await completeAllStepsUpToContact(tester);
      await continueStep(tester); // contact -> amenities
      await continueStep(tester); // amenities -> policies

      await tester.enterText(find.byKey(const Key('wizard-check-in')), '25:00');
      await tester.pumpAndSettle();
      await continueStep(tester);

      expect(state.currentStep, PropertyWizardStep.policies);
      expect(find.text(en.partnerPropertyValidationTime), findsOneWidget);
    });

    testWidgets('the progress rail cannot skip an unfinished required step',
        (tester) async {
      final state = await pumpWizard(tester, client: wizardClient());
      await continueStep(tester);

      // Basics is not complete, so nothing beyond it may be opened.
      await tapVisible(
          tester, find.byKey(const Key('wizard-rail-${'review'}')));
      expect(state.currentStep, PropertyWizardStep.basics);
    });
  });

  // ── 3. Amenities ─────────────────────────────────────────────────────────

  group('amenities', () {
    testWidgets('offers property amenities only, with a search and a count',
        (tester) async {
      final state = await pumpWizard(tester, client: wizardClient());
      await completeAllStepsUpToContact(tester);
      await continueStep(tester);

      expect(find.byKey(const Key('wizard-amenity-$wifiAmenityId')),
          findsOneWidget);
      expect(find.byKey(const Key('wizard-amenity-$poolAmenityId')),
          findsOneWidget);
      // A room amenity belongs to a room, and the backend would refuse it.
      expect(
          find.byKey(const Key('wizard-amenity-$roomAmenityId')), findsNothing);

      await tapVisible(
          tester, find.byKey(const Key('wizard-amenity-$poolAmenityId')));
      expect(state.amenityIds, {poolAmenityId});
      expect(find.text(en.partnerPropertyAmenitiesSelected(1)), findsOneWidget);

      await tester.enterText(
          find.byKey(const Key('wizard-amenity-search')), 'pool');
      await tester.pumpAndSettle();
      expect(
          find.byKey(const Key('wizard-amenity-$wifiAmenityId')), findsNothing);
      expect(find.byKey(const Key('wizard-amenity-$poolAmenityId')),
          findsOneWidget);
    });
  });

  // ── 4. Save draft ────────────────────────────────────────────────────────

  group('save draft', () {
    testWidgets('is blocked, with the reason, until the server could store one',
        (tester) async {
      final state = await pumpWizard(tester, client: wizardClient());
      await continueStep(tester);

      expect(state.saveBlock, PropertyWizardSaveBlock.incompleteForCreate);
      expect(find.text(en.partnerWizardSaveBlockedCreate), findsOneWidget);
      final save = tester.widget<Widget>(find.byKey(const Key('wizard-save')));
      expect(save, isNotNull);
      expect(state.canSaveDraft, isFalse);
      expect(sent('POST', '/partner/hotels'), isFalse);
    });

    testWidgets('creates the draft in one request once it can', (tester) async {
      final state = await pumpWizard(tester, client: wizardClient());
      await completeAllSteps(tester);

      expect(state.canSaveDraft, isTrue);
      await tapVisible(tester, find.byKey(const Key('wizard-save')));

      final body = lastBody('POST', '/partner/hotels');
      expect(body['name'], 'Bay View Stay');
      expect(body['categoryId'], accommodationId);
      expect(body['subcategoryId'], hotelId);
      expect(body['administrativeUnitId'], areaId);
      expect(body['address'], '15 Thuy Van');
      expect(body['starRating'], 3);
      expect(body['checkIn'], '14:00:00');
      // Nothing that would publish, re-own or moderate the property.
      expect(body.containsKey('status'), isFalse);
      expect(body.containsKey('ownerProfileId'), isFalse);

      // Exactly one create, and the record now comes from the server.
      expect(
        requests
            .where((entry) =>
                entry.method == 'POST' &&
                entry.path.endsWith('/partner/hotels'))
            .length,
        1,
      );
      expect(state.propertyExists, isTrue);
      expect(state.saved!.status.name, 'draft');
      expect(state.lastSavedAt, isNotNull);
      expect(find.text(en.partnerWizardSavedJustNow), findsOneWidget);
    });

    testWidgets('a second save with nothing changed writes nothing',
        (tester) async {
      final state = await pumpWizard(tester, client: wizardClient());
      await completeAllSteps(tester);
      await tapVisible(tester, find.byKey(const Key('wizard-save')));
      final after = requests.where((entry) => entry.method != 'GET').length;

      expect(state.saveBlock, PropertyWizardSaveBlock.nothingToSave);
      expect(state.canSaveDraft, isFalse);
      expect(requests.where((entry) => entry.method != 'GET').length, after);
    });

    testWidgets('a field error is shown on the field the backend named',
        (tester) async {
      await pumpWizard(
        tester,
        client: wizardClient(
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
      await completeAllSteps(tester);
      await tapVisible(tester, find.byKey(const Key('wizard-save')));

      expect(find.byKey(const Key('wizard-save-error')), findsOneWidget);
      expect(find.text(en.partnerPropertyErrorCategory), findsOneWidget);
      // Nothing claims a save, and the typed values are still there.
      expect(find.text(en.partnerWizardSavedJustNow), findsNothing);
    });

    testWidgets('403 reads as the approval gate', (tester) async {
      await pumpWizard(
        tester,
        client: wizardClient(
          overrides: () => {
            '/partner/hotels': jsonResponse(
                errorBody(403, 'Partner profile is not approved'), 403),
          },
        ),
      );
      await completeAllSteps(tester);
      await tapVisible(tester, find.byKey(const Key('wizard-save')));
      expect(find.text(en.partnerPropertyErrorApproval), findsOneWidget);
    });

    testWidgets('401 reads as the session, and stays on the Partner surface',
        (tester) async {
      final state = await pumpWizard(
        tester,
        client: wizardClient(
          overrides: () => {
            '/partner/hotels':
                jsonResponse(errorBody(401, 'Authentication required'), 401),
          },
        ),
      );
      await completeAllSteps(tester);
      await tapVisible(tester, find.byKey(const Key('wizard-save')));

      expect(find.text(en.partnerDashboardErrorUnauthorized), findsOneWidget);
      // The wizard reports it and stays put: signing back in is the surface
      // gate's job, and nothing here routes to another surface.
      expect(state.propertyExists, isFalse);
      expect(find.byKey(const Key('wizard-save')), findsOneWidget);
    });

    testWidgets('a dropped connection never reports a save', (tester) async {
      final state =
          await pumpWizard(tester, client: wizardClient(writeThrows: true));
      await completeAllSteps(tester);
      await tapVisible(tester, find.byKey(const Key('wizard-save')));

      expect(find.text(en.partnerDashboardErrorNetwork), findsOneWidget);
      expect(state.propertyExists, isFalse);
      expect(state.lastSavedAt, isNull);
      expect(find.text(en.partnerWizardSavedJustNow), findsNothing);
    });

    testWidgets('a conflict is reported as one', (tester) async {
      await pumpWizard(
        tester,
        client: wizardClient(
          overrides: () => {
            '/partner/hotels': jsonResponse(
                errorBody(409, 'Slug already in use', code: 'SLUG_CONFLICT'),
                409),
          },
        ),
      );
      await completeAllSteps(tester);
      await tapVisible(tester, find.byKey(const Key('wizard-save')));
      expect(find.text(en.partnerPropertyErrorSlugConflict), findsOneWidget);
    });
  });

  // ── 5. Review ────────────────────────────────────────────────────────────

  group('review', () {
    testWidgets('summarises every section with its completeness',
        (tester) async {
      await pumpWizard(tester, client: wizardClient());
      await completeAllSteps(tester);

      expect(find.text(en.partnerWizardStepReview), findsWidgets);
      expect(find.text('Bay View Stay'), findsWidgets);
      expect(find.text('15 Thuy Van'), findsWidgets);
      expect(
          find.byKey(const Key('wizard-review-status-basics')), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('wizard-review-status-basics')))
            .data,
        en.partnerWizardReviewComplete,
      );
      // There is no publish action anywhere in the wizard.
      expect(find.text(en.partnerPropertyStatusPublished), findsNothing);
      expect(find.text(en.partnerPropertyActivateAction), findsNothing);
      expect(find.byKey(const Key('wizard-continue')), findsNothing);
    });

    testWidgets('the fix action jumps to the step that owns the problem',
        (tester) async {
      final state = await pumpWizard(tester, client: wizardClient());
      await completeAllSteps(tester);

      await tapVisible(
          tester, find.byKey(const Key('wizard-review-fix-location')));
      expect(state.currentStep, PropertyWizardStep.location);
    });
  });

  // ── 6. Dirty state ───────────────────────────────────────────────────────

  group('unsaved changes', () {
    testWidgets('leaving with unsaved work asks first', (tester) async {
      await pumpWizard(tester, client: wizardClient());
      await continueStep(tester);
      await tester.enterText(
          find.byKey(const Key('wizard-name')), 'Half typed');
      await tester.pumpAndSettle();

      await tapVisible(tester, find.byKey(const Key('wizard-close')));

      expect(find.byKey(const Key('wizard-leave-dialog')), findsOneWidget);
      expect(find.text(en.partnerWizardLeaveTitle), findsOneWidget);
    });

    testWidgets('keep editing returns to the form with the text intact',
        (tester) async {
      await pumpWizard(tester, client: wizardClient());
      await continueStep(tester);
      await tester.enterText(
          find.byKey(const Key('wizard-name')), 'Half typed');
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const Key('wizard-close')));

      await tapVisible(tester, find.byKey(const Key('wizard-leave-cancel')));

      expect(find.byKey(const Key('wizard-leave-dialog')), findsNothing);
      expect(find.text('Half typed'), findsOneWidget);
    });

    testWidgets('discard clears the unsaved work', (tester) async {
      final state = await pumpWizard(tester, client: wizardClient());
      await continueStep(tester);
      await tester.enterText(
          find.byKey(const Key('wizard-name')), 'Half typed');
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const Key('wizard-close')));

      await tapVisible(tester, find.byKey(const Key('wizard-leave-discard')));

      expect(state.name, isEmpty);
      expect(state.hasUnsavedChanges, isFalse);
      // Nothing was written on the way out.
      expect(sent('POST', '/partner/hotels'), isFalse);
    });

    testWidgets('an untouched wizard closes without asking', (tester) async {
      await pumpWizard(tester, client: wizardClient());

      await tapVisible(tester, find.byKey(const Key('wizard-close')));

      expect(find.byKey(const Key('wizard-leave-dialog')), findsNothing);
    });
  });

  // ── 7. Resuming a draft ──────────────────────────────────────────────────

  group('resume', () {
    testWidgets('loads the stored draft and opens at the review when complete',
        (tester) async {
      final state =
          await pumpWizard(tester, client: wizardClient(), resumeId: 77);

      expect(state.propertyExists, isTrue);
      expect(state.name, 'Bay View Stay');
      // Everything required is present, so there is nothing left to complete.
      expect(state.currentStep, PropertyWizardStep.review);
      expect(sent('GET', '/partner/hotels/77'), isTrue);
    });

    testWidgets('opens at the first incomplete step', (tester) async {
      // `starRating` is null for a place with no HotelDetail row — an
      // administratively imported property. Basics is then the first gap, and
      // the wizard opens there rather than at the review.
      final state = await pumpWizard(
        tester,
        client: wizardClient(detail: () {
          final record = hotelResponse();
          record['starRating'] = null;
          return record;
        }),
        resumeId: 77,
      );

      expect(state.currentStep, PropertyWizardStep.basics);
      expect(state.starRating, isNull);
      expect(state.isStepComplete(PropertyWizardStep.basics), isFalse);
    });

    testWidgets('a draft that is not available is reported, not invented',
        (tester) async {
      final state = await pumpWizard(
        tester,
        client: wizardClient(
          overrides: () => {
            '/partner/hotels/77':
                jsonResponse(errorBody(404, 'Hotel not found: 77'), 404),
          },
        ),
        resumeId: 77,
      );

      expect(state.status, PropertyWizardStatus.propertyError);
      expect(find.byKey(const Key('wizard-property-error')), findsOneWidget);
      expect(find.byKey(const Key('wizard-name')), findsNothing);
    });

    testWidgets('saving a resumed draft writes only the changed section',
        (tester) async {
      await pumpWizard(tester, client: wizardClient(), resumeId: 77);

      await tapVisible(tester, find.byKey(const Key('wizard-rail-basics')));
      await tester.enterText(
          find.byKey(const Key('wizard-name')), 'Bay View Renamed');
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const Key('wizard-save')));

      expect(lastBody('PUT', '/partner/hotels/77')['name'], 'Bay View Renamed');
      // Untouched sections are not rewritten: each would raise its own
      // "Property updated" notification for nothing.
      expect(sent('PUT', '/partner/hotels/77/location'), isFalse);
      expect(sent('PUT', '/partner/hotels/77/contact'), isFalse);
      expect(sent('PUT', '/partner/hotels/77/policies'), isFalse);
      expect(sent('PUT', '/partner/hotels/77/amenities'), isFalse);
    });

    testWidgets('a changed amenity set is the only thing written for it',
        (tester) async {
      await pumpWizard(tester, client: wizardClient(), resumeId: 77);

      await tapVisible(tester, find.byKey(const Key('wizard-rail-amenities')));
      await tapVisible(
          tester, find.byKey(const Key('wizard-amenity-$poolAmenityId')));
      await tapVisible(tester, find.byKey(const Key('wizard-save')));

      final body = lastBody('PUT', '/partner/hotels/77/amenities');
      expect((body['amenityIds'] as List).cast<int>().toSet(),
          {wifiAmenityId, poolAmenityId});
      expect(sent('PUT', '/partner/hotels/77'), isFalse);
    });

    testWidgets('a resumed draft keeps its location until another is picked',
        (tester) async {
      final state =
          await pumpWizard(tester, client: wizardClient(), resumeId: 77);

      expect(state.selectedLocationId, areaId);
      await tapVisible(tester, find.byKey(const Key('wizard-rail-location')));
      expect(find.text('Vietnam > Da Nang > My Khe'), findsWidgets);
    });
  });

  // ── 8. Draft status and layout ───────────────────────────────────────────

  group('draft status, layout and localization', () {
    testWidgets('says the property is not visible to travellers',
        (tester) async {
      await pumpWizard(tester, client: wizardClient(), resumeId: 77);

      expect(find.text(en.partnerWizardDraftNotice), findsWidgets);
      expect(find.text(en.partnerPropertyVisibilityPublic), findsNothing);
    });

    testWidgets('a phone width shows the compact progress line',
        (tester) async {
      await pumpWizard(
        tester,
        client: wizardClient(),
        size: const Size(390, 1600),
      );

      expect(find.byKey(const Key('wizard-compact-step')), findsOneWidget);
      expect(find.byKey(const Key('wizard-rail-basics')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a desktop width shows the step rail', (tester) async {
      await pumpWizard(tester, client: wizardClient());

      expect(find.byKey(const Key('wizard-rail-basics')), findsOneWidget);
      expect(find.byKey(const Key('wizard-compact-step')), findsNothing);
    });

    testWidgets('Vietnamese renders Vietnamese strings', (tester) async {
      await pumpWizard(
        tester,
        client: wizardClient(),
        locale: const Locale('vi'),
      );

      expect(find.text(vi.partnerWizardTitle), findsWidgets);
      expect(find.text(vi.partnerWizardStepBusinessProfile), findsWidgets);
      expect(find.text(en.partnerWizardTitle), findsNothing);
    });

    testWidgets('every Phase D string exists in both locales', (tester) async {
      for (final pair in <List<String>>[
        [en.partnerWizardTitle, vi.partnerWizardTitle],
        [en.partnerWizardSubtitle, vi.partnerWizardSubtitle],
        [en.partnerWizardDraftNotice, vi.partnerWizardDraftNotice],
        [en.partnerWizardProfileIntro, vi.partnerWizardProfileIntro],
        [en.partnerWizardProfileBlocked, vi.partnerWizardProfileBlocked],
        [en.partnerWizardSaveBlockedCreate, vi.partnerWizardSaveBlockedCreate],
        [en.partnerWizardStepIncomplete, vi.partnerWizardStepIncomplete],
        [en.partnerWizardReviewComplete, vi.partnerWizardReviewComplete],
        [en.partnerWizardLeaveTitle, vi.partnerWizardLeaveTitle],
        [
          en.partnerPropertyContinueSetupAction,
          vi.partnerPropertyContinueSetupAction
        ],
        [en.partnerPropertyDraftNotVisible, vi.partnerPropertyDraftNotVisible],
      ]) {
        expect(pair[0].isNotEmpty, isTrue);
        expect(pair[1].isNotEmpty, isTrue);
        expect(pair[0], isNot(pair[1]));
      }
    });
  });
}

/// Walks a new property as far as the contact step — the shared prefix of the
/// tests that care about what comes after it.
Future<void> completeAllStepsUpToContact(WidgetTester tester) async {
  Future<void> tapVisible(Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> choose(String key, String label) async {
    await tapVisible(find.byKey(Key(key)));
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  await tapVisible(find.byKey(const Key('wizard-continue')));
  await tester.enterText(find.byKey(const Key('wizard-name')), 'Bay View Stay');
  await choose('wizard-star-rating', '3');
  await tapVisible(find.byKey(const Key('wizard-continue')));
  await choose('wizard-province', 'Da Nang');
  await tester.enterText(
      find.byKey(const Key('wizard-address')), '15 Thuy Van');
  await tester.pumpAndSettle();
  await tapVisible(find.byKey(const Key('wizard-continue')));
}
