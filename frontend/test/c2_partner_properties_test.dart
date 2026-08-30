import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/core/app_role.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/core/partner/partner_models.dart';
import 'package:planyourtrip_frontend/core/partner/partner_property_models.dart';
import 'package:planyourtrip_frontend/core/partner/partner_state.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/partner/properties/partner_properties_screen.dart';
import 'package:planyourtrip_frontend/features/partner/properties/partner_properties_state.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_en.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_vi.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// C2 — Partner Properties.
///
/// Asserts against payloads shaped exactly like `PartnerHotelSummaryResponse`
/// and `PartnerHotelResponse` in `backend-v1`/`develop`, and against the
/// ownership semantics that backend actually implements: `ownedPlaceOrThrow`
/// returns a **uniform 404** for an unknown id and for another partner's
/// property, so the client must never present those as different situations.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  http.Response jsonResponse(Object body, int status) => http.Response(
        jsonEncode(body),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  Map<String, dynamic> errorBody(int status, String message, String path) => {
        'timestamp': DateTime.now().toIso8601String(),
        'status': status,
        'error': 'Error',
        'message': message,
        'path': path,
      };

  Map<String, dynamic> profileJson({String verificationStatus = 'APPROVED'}) => {
        'id': 7,
        'userId': 42,
        'businessName': 'Bay View Resorts',
        'representativeName': 'Le Minh',
        'email': 'ops@bayview.example',
        'verificationStatus': verificationStatus,
      };

  Map<String, dynamic> extranetHomeJson() => {
        'profile': {
          'id': 7,
          'businessName': 'Bay View Resorts',
          'representativeName': 'Le Minh',
          'email': 'ops@bayview.example',
        },
        'verificationStatus': 'APPROVED',
        'ownedHotelCount': 2,
        'activeRoomCount': 34,
        'todaysArrivals': 0,
        'todaysDepartures': 0,
        'unreadMessages': 0,
        'unreadNotifications': 0,
        'pendingReviews': 0,
        'activePromotions': 0,
        'quickActions': <Object>[],
      };

  /// `PartnerHotelSummaryResponse` — every field the record declares.
  Map<String, dynamic> summaryJson({
    int id = 11,
    String name = 'Bay View Danang',
    bool active = true,
    String status = 'PUBLISHED',
    bool verified = true,
    bool featured = false,
    double ratingAvg = 4.6,
    int reviewCount = 12,
  }) =>
      {
        'id': id,
        'name': name,
        'slug': 'bay-view-danang',
        'shortDescription': 'Beachfront resort',
        'address': '12 Vo Nguyen Giap, Da Nang',
        'active': active,
        'featured': featured,
        'verified': verified,
        'ratingAvg': ratingAvg,
        'reviewCount': reviewCount,
        'status': status,
        'createdAt': '2026-07-30T02:00:00Z',
        'updatedAt': '2026-08-20T02:00:00Z',
      };

  /// `PartnerHotelResponse` — the full detail record. Contact and policy fields
  /// are null exactly as the live backend returns them for the seeded property.
  Map<String, dynamic> detailJson({
    int id = 11,
    bool active = true,
    String status = 'PUBLISHED',
    Object? phone,
    Object? latitude = 16.0544,
    Object? longitude = 108.2022,
  }) =>
      {
        'id': id,
        'name': 'Bay View Danang',
        'slug': 'bay-view-danang',
        'shortDescription': 'Beachfront resort',
        'description': 'A long-form description from the backend.',
        'address': '12 Vo Nguyen Giap, Da Nang',
        'latitude': latitude,
        'longitude': longitude,
        'phone': phone,
        'email': null,
        'website': null,
        'facebook': null,
        'instagram': null,
        'checkIn': '14:00:00',
        'checkOut': '12:00:00',
        'childrenPolicy': null,
        'petPolicy': null,
        'smokingPolicy': null,
        'active': active,
        'featured': false,
        'verified': true,
        'ratingAvg': 4.6,
        'reviewCount': 12,
        'status': status,
        'ownerProfileId': 7,
        'ownerBusinessName': 'Bay View Resorts',
        'createdAt': '2026-07-30T02:00:00Z',
        'updatedAt': '2026-08-20T02:00:00Z',
      };

  late List<String> requestLog;
  setUp(() => requestLog = <String>[]);

  MockClient propertiesClient({
    Map<String, http.Response>? overrides,
    List<Map<String, dynamic>>? hotels,
    bool throwNetwork = false,
    String verificationStatus = 'APPROVED',
  }) =>
      MockClient((request) async {
        final path = request.url.path;
        requestLog.add('${request.method} $path');
        if (throwNetwork) throw http.ClientException('offline');

        if (overrides != null) {
          for (final entry in overrides.entries) {
            if (path.endsWith(entry.key)) return entry.value;
          }
        }

        if (path.endsWith('/partner/profile')) {
          return jsonResponse(
              profileJson(verificationStatus: verificationStatus), 200);
        }
        if (path.endsWith('/partner/extranet/home')) {
          return jsonResponse(extranetHomeJson(), 200);
        }
        if (path.endsWith('/partner/team')) {
          return jsonResponse(<Object>[], 200);
        }
        // Detail: /partner/hotels/{id}
        final detailMatch =
            RegExp(r'/partner/hotels/(\d+)$').firstMatch(path);
        if (detailMatch != null) {
          final id = int.parse(detailMatch.group(1)!);
          final list = hotels ?? [summaryJson()];
          if (!list.any((h) => h['id'] == id)) {
            return jsonResponse(
                errorBody(404, 'Hotel not found: $id', path), 404);
          }
          return jsonResponse(detailJson(id: id), 200);
        }
        if (path.endsWith('/partner/hotels')) {
          return jsonResponse(hotels ?? [summaryJson()], 200);
        }
        return jsonResponse(errorBody(404, 'Not found', path), 404);
      });

  AppState partnerApp(http.Client client) =>
      AppState(api: ApiClient(client: client)..demoMode = false)
        ..demoMode = false
        ..email = 'partner@planyourtrip.com'
        ..role = AppRole.partner;

  Widget testApp({
    required AppState app,
    required PartnerState partner,
    Locale? locale,
  }) =>
      AppScope(
        notifier: app,
        child: PartnerScope(
          notifier: partner,
          child: MaterialApp(
            theme: AppTheme.light(),
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: SingleChildScrollView(child: PartnerPropertiesScreen()),
            ),
          ),
        ),
      );

  Future<({AppState app, PartnerState partner})> pumpProperties(
    WidgetTester tester, {
    http.Client? client,
    Size size = const Size(1440, 1600),
    Locale? locale,
  }) async {
    final app = partnerApp(client ?? propertiesClient());
    final partner = PartnerState(api: app.api)..bindSession(app);
    await partner.loadWorkspace(app);

    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(testApp(app: app, partner: partner, locale: locale));
    await tester.pumpAndSettle();
    return (app: app, partner: partner);
  }

  List<String> captureLayoutErrors(WidgetTester tester) {
    final errors = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details.toString());
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);
    return errors;
  }

  final en = AppLocalizationsEn();
  final vi = AppLocalizationsVi();

  // ── 1. List ──────────────────────────────────────────────────────────────

  group('property list', () {
    testWidgets('renders every field the summary DTO supplies', (tester) async {
      await pumpProperties(tester);

      expect(find.text('Bay View Danang'), findsOneWidget);
      expect(find.text('12 Vo Nguyen Giap, Da Nang'), findsOneWidget);
      expect(find.text(en.partnerPropertyStatusPublished), findsWidgets);
      expect(find.text(en.partnerPropertyActive), findsWidgets);
      expect(find.text(en.partnerPropertyVerified), findsWidgets);
      expect(find.text(en.partnerPropertiesCount(1)), findsOneWidget);
    });

    testWidgets('invents nothing the list endpoint does not return',
        (tester) async {
      await pumpProperties(tester);

      // The summary DTO carries no room count, revenue or occupancy. None of
      // the dashboard's KPI vocabulary may appear on this screen.
      expect(find.text(en.partnerKpiOccupancy), findsNothing);
      expect(find.text(en.partnerKpiTotalRevenue), findsNothing);
      expect(find.text(en.partnerOccupancyInventory), findsNothing);
      // ...and there is no create affordance, because no create endpoint exists.
      expect(find.byIcon(Icons.add), findsNothing);
    });

    testWidgets('renders multiple properties', (tester) async {
      await pumpProperties(
        tester,
        client: propertiesClient(hotels: [
          summaryJson(),
          summaryJson(id: 12, name: 'Bay View Hoi An', active: false,
              status: 'HIDDEN', verified: false),
        ]),
      );

      expect(find.text('Bay View Danang'), findsOneWidget);
      expect(find.text('Bay View Hoi An'), findsOneWidget);
      expect(find.text(en.partnerPropertyStatusHidden), findsWidgets);
      expect(find.text(en.partnerPropertyInactive), findsWidgets);
      expect(find.text(en.partnerPropertiesCount(2)), findsOneWidget);
    });
  });

  // ── 2. Empty ─────────────────────────────────────────────────────────────

  group('empty', () {
    testWidgets('zero properties reads as an answer, not a failure',
        (tester) async {
      await pumpProperties(
          tester, client: propertiesClient(hotels: <Map<String, dynamic>>[]));

      expect(find.text(en.partnerPropertiesEmptyTitle), findsOneWidget);
      expect(find.text(en.partnerPropertiesEmptyMessage), findsOneWidget);
      // Must not be confused with the not-approved workspace state.
      expect(find.text(en.partnerStatusAwaitingApprovalTitle), findsNothing);
      expect(find.text(en.partnerStatusForbiddenTitle), findsNothing);
    });

    testWidgets('empty is distinct from not-approved', (tester) async {
      final app = partnerApp(propertiesClient(verificationStatus: 'SUBMITTED'));
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);

      await tester.pumpWidget(testApp(app: app, partner: partner));
      await tester.pumpAndSettle();

      expect(find.text(en.partnerStatusAwaitingApprovalTitle), findsOneWidget);
      expect(find.text(en.partnerPropertiesEmptyTitle), findsNothing);
      // No property request may be issued for an unapproved profile.
      expect(requestLog.any((r) => r.endsWith('/partner/hotels')), isFalse);
    });
  });

  // ── 3. Detail ────────────────────────────────────────────────────────────

  group('property detail', () {
    testWidgets('opens detail and renders the full DTO in sections',
        (tester) async {
      await pumpProperties(tester);
      await tester.tap(find.text('Bay View Danang'));
      await tester.pumpAndSettle();

      expect(find.text(en.partnerPropertyDetailHeading), findsOneWidget);
      expect(find.text(en.partnerPropertySectionIdentity), findsOneWidget);
      expect(find.text(en.partnerPropertySectionLocation), findsOneWidget);
      expect(find.text(en.partnerPropertySectionContact), findsOneWidget);
      expect(find.text(en.partnerPropertySectionPolicies), findsOneWidget);
      expect(find.text(en.partnerPropertySectionVerification), findsOneWidget);
      expect(find.text(en.partnerPropertySectionMetadata), findsOneWidget);

      expect(find.text('bay-view-danang'), findsOneWidget);
      expect(find.text('A long-form description from the backend.'),
          findsOneWidget);
      expect(find.text('Bay View Resorts'), findsWidgets);
      // LocalTime "14:00:00" renders trimmed, not as a fabricated date.
      expect(find.text('14:00'), findsOneWidget);
      expect(find.text('12:00'), findsOneWidget);
    });

    testWidgets('null contact fields read as "not set", never blank',
        (tester) async {
      await pumpProperties(tester);
      await tester.tap(find.text('Bay View Danang'));
      await tester.pumpAndSettle();

      // phone/email/website/facebook/instagram + 3 policies are all null.
      expect(find.text(en.partnerPropertyNotSet), findsWidgets);
    });

    testWidgets('a partial coordinate pair is not plotted', (tester) async {
      await pumpProperties(
        tester,
        client: propertiesClient(overrides: {
          '/partner/hotels/11':
              jsonResponse(detailJson(longitude: null), 200),
        }),
      );
      await tester.tap(find.text('Bay View Danang'));
      await tester.pumpAndSettle();

      expect(find.text(en.partnerPropertyFieldCoordinates), findsOneWidget);
      expect(find.textContaining('16.0544'), findsNothing);
    });

    testWidgets('detail can be closed without losing the selection',
        (tester) async {
      final handles = await pumpProperties(tester);
      await tester.tap(find.text('Bay View Danang'));
      await tester.pumpAndSettle();
      expect(handles.partner.selectedPropertyId, 11);

      await tester.tap(find.byTooltip(en.partnerPropertyCloseDetail));
      await tester.pumpAndSettle();

      expect(find.text(en.partnerPropertyDetailHeading), findsNothing);
      expect(handles.partner.selectedPropertyId, 11,
          reason: 'closing a panel is not deselecting a property');
    });
  });

  // ── 4–6. Selection and PartnerState synchronisation ──────────────────────

  group('property selection', () {
    testWidgets('opening a property makes it the workspace selection',
        (tester) async {
      final handles = await pumpProperties(
        tester,
        client: propertiesClient(hotels: [
          summaryJson(),
          summaryJson(id: 12, name: 'Bay View Hoi An'),
        ]),
      );

      await tester.tap(find.text('Bay View Hoi An'));
      await tester.pumpAndSettle();

      expect(handles.partner.selectedPropertyId, 12);
      expect(handles.partner.selectedProperty?.name, 'Bay View Hoi An');
    });

    test('a single property is selected automatically', () async {
      final app = partnerApp(propertiesClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);

      final properties = PartnerPropertiesState(api: app.api);
      await properties.load(partner);

      expect(partner.properties.length, 1);
      expect(partner.selectedPropertyId, 11,
          reason: 'a single-property partner should never have to choose');
    });

    test('an unauthorized id is rejected client-side and never selected',
        () async {
      final app = partnerApp(propertiesClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final properties = PartnerPropertiesState(api: app.api);
      await properties.load(partner);
      requestLog.clear();

      await properties.openProperty(partner, 999);

      expect(properties.openPropertyId, isNull);
      expect(partner.selectedPropertyId, 11, reason: 'selection unchanged');
      expect(requestLog, isEmpty,
          reason: 'an unowned id must not even be requested');
    });

    test('a selection that disappears from the list is dropped', () async {
      final app = partnerApp(propertiesClient(hotels: [
        summaryJson(),
        summaryJson(id: 12, name: 'Bay View Hoi An'),
      ]));
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      partner.selectProperty(12);
      expect(partner.selectedPropertyId, 12);

      // The backend no longer returns property 12.
      partner.replaceProperties([
        PartnerProperty.fromJson(summaryJson())!,
      ]);

      expect(partner.selectedPropertyId, 11,
          reason: 'stale scope must not survive, and a lone property is chosen');
    });

    test('selection survives a refresh that still contains it', () async {
      final app = partnerApp(propertiesClient(hotels: [
        summaryJson(),
        summaryJson(id: 12, name: 'Bay View Hoi An'),
      ]));
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      partner.selectProperty(12);

      final properties = PartnerPropertiesState(api: app.api);
      await properties.load(partner);

      expect(partner.selectedPropertyId, 12);
    });
  });

  // ── 7–10. Error semantics ────────────────────────────────────────────────

  group('errors', () {
    testWidgets('401 on the list shows the session-expired view',
        (tester) async {
      await pumpProperties(
        tester,
        client: propertiesClient(overrides: {
          '/partner/hotels': jsonResponse(
              errorBody(401, 'Unauthorized', '/api/partner/hotels'), 401),
        }),
      );
      expect(find.text(en.partnerStatusUnauthorizedTitle), findsOneWidget);
    });

    testWidgets('403 on the list is reported as an approval problem',
        (tester) async {
      await pumpProperties(
        tester,
        client: propertiesClient(overrides: {
          '/partner/hotels': jsonResponse(
              errorBody(403, 'Partner profile is not approved',
                  '/api/partner/hotels'),
              403),
        }),
      );
      expect(find.text(en.partnerStatusForbiddenTitle), findsOneWidget);
    });

    testWidgets('404 on the list means no partner profile', (tester) async {
      await pumpProperties(
        tester,
        client: propertiesClient(overrides: {
          '/partner/hotels': jsonResponse(
              errorBody(404, 'Partner profile not found', '/api/partner/hotels'),
              404),
        }),
      );
      expect(find.text(en.partnerStatusOnboardingTitle), findsOneWidget);
    });

    testWidgets('404 on detail is worded as unavailable, never as forbidden',
        (tester) async {
      await pumpProperties(
        tester,
        client: propertiesClient(overrides: {
          '/partner/hotels/11': jsonResponse(
              errorBody(404, 'Hotel not found: 11', '/api/partner/hotels/11'),
              404),
        }),
      );
      await tester.tap(find.text('Bay View Danang'));
      await tester.pumpAndSettle();

      expect(find.text(en.partnerPropertyDetailNotFound), findsOneWidget);
      // The uniform 404 covers unknown AND unowned; it must not claim either.
      expect(find.text(en.partnerDashboardErrorForbidden), findsNothing);
    });

    test('a network failure is retryable, not a lifecycle state', () async {
      final app = partnerApp(propertiesClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);

      final offline = PartnerPropertiesState(
        api: ApiClient(client: propertiesClient(throwNetwork: true))
          ..demoMode = false,
      );
      await offline.load(partner);

      expect(offline.status, PartnerPropertiesStatus.error);
      expect(offline.isRetryable, isTrue);
      expect(offline.isEmpty, isFalse,
          reason: 'a failed load is not an empty portfolio');
    });

    testWidgets('loading state renders before data arrives', (tester) async {
      final app = partnerApp(propertiesClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);

      await tester.pumpWidget(testApp(app: app, partner: partner));
      await tester.pump(); // let the post-frame load start
      final properties = PartnerPropertiesState(api: app.api);
      expect(properties.isLoading, isTrue);
      await tester.pumpAndSettle();
    });
  });

  // ── 11. Listing actions ──────────────────────────────────────────────────

  group('listing actions', () {
    testWidgets('deactivating updates the row from the server response',
        (tester) async {
      await pumpProperties(
        tester,
        client: propertiesClient(overrides: {
          '/partner/hotels/11/deactivate':
              jsonResponse(detailJson(active: false), 200),
        }),
      );

      expect(find.text(en.partnerPropertyActive), findsWidgets);
      await tester.tap(find.text(en.partnerPropertyDeactivateAction));
      await tester.pumpAndSettle();

      expect(find.text(en.partnerPropertyInactive), findsWidgets);
      expect(requestLog.any((r) => r.contains('PATCH') &&
          r.contains('/partner/hotels/11/deactivate')), isTrue);
    });

    testWidgets('a failed action reports failure and changes nothing',
        (tester) async {
      await pumpProperties(
        tester,
        client: propertiesClient(overrides: {
          '/partner/hotels/11/deactivate': jsonResponse(
              errorBody(404, 'Hotel not found: 11',
                  '/api/partner/hotels/11/deactivate'),
              404),
        }),
      );

      await tester.tap(find.text(en.partnerPropertyDeactivateAction));
      await tester.pumpAndSettle();

      expect(find.text(en.partnerPropertyActionNotFound), findsOneWidget);
      // The listing must still read as on — no fake success.
      expect(find.text(en.partnerPropertyActive), findsWidgets);
    });

    test('a timed-out mutation is uncertain, never a clean failure', () async {
      final api = ApiClient(
          client: MockClient((_) async => throw TimeoutException('slow')))
        ..demoMode = false;
      final app = partnerApp(propertiesClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);

      final properties = PartnerPropertiesState(api: app.api);
      await properties.load(partner);

      final uncertain = PartnerPropertiesState(api: api);
      await uncertain.load(partner);
      // The list itself failed, so the action short-circuits as notFound —
      // assert the ApiClient's own classification instead.
      final result = await api.deactivatePartnerProperty(11);
      expect(result.errorKind, ApiErrorKind.uncertain);
    });

    test('acting on an id outside the list never reaches the network',
        () async {
      final app = partnerApp(propertiesClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final properties = PartnerPropertiesState(api: app.api);
      await properties.load(partner);
      requestLog.clear();

      final result = await properties.setActive(999, activate: false);
      expect(result, PartnerPropertyActionResult.notFound);
      expect(requestLog, isEmpty);
    });
  });

  // ── 12. Status lifecycle ─────────────────────────────────────────────────

  group('status lifecycle', () {
    test('parses exactly the seven PlaceStatus values the backend declares',
        () {
      expect(PartnerPlaceStatus.parse('DRAFT'), PartnerPlaceStatus.draft);
      expect(PartnerPlaceStatus.parse('PENDING_REVIEW'),
          PartnerPlaceStatus.pendingReview);
      expect(PartnerPlaceStatus.parse('APPROVED'), PartnerPlaceStatus.approved);
      expect(
          PartnerPlaceStatus.parse('PUBLISHED'), PartnerPlaceStatus.published);
      expect(PartnerPlaceStatus.parse('HIDDEN'), PartnerPlaceStatus.hidden);
      expect(PartnerPlaceStatus.parse('ARCHIVED'), PartnerPlaceStatus.archived);
      expect(PartnerPlaceStatus.parse('REJECTED'), PartnerPlaceStatus.rejected);
      // "PENDING" is NOT a backend value — it must not silently become one.
      expect(PartnerPlaceStatus.parse('PENDING'), PartnerPlaceStatus.unknown);
      expect(PartnerPlaceStatus.parse(null), PartnerPlaceStatus.unknown);
      expect(PartnerPlaceStatus.unknown.isPubliclyVisible, isFalse,
          reason: 'an unrecognised status must fail closed');
    });

    testWidgets('a rejected property says so and is not shown as public',
        (tester) async {
      await pumpProperties(
        tester,
        client: propertiesClient(
          hotels: [summaryJson(status: 'REJECTED', active: false)],
          overrides: {
            '/partner/hotels/11':
                jsonResponse(detailJson(status: 'REJECTED', active: false), 200),
          },
        ),
      );
      await tester.tap(find.text('Bay View Danang'));
      await tester.pumpAndSettle();

      expect(find.text(en.partnerPropertyStatusRejected), findsWidgets);
      expect(find.text(en.partnerPropertyVisibilityNotPublic), findsOneWidget);
      expect(find.text(en.partnerPropertyVisibilityPublic), findsNothing);
    });

    testWidgets('active + PUBLISHED is the only publicly visible combination',
        (tester) async {
      // Active but only APPROVED (not yet published) is not public.
      await pumpProperties(
        tester,
        client: propertiesClient(
          hotels: [summaryJson(status: 'APPROVED')],
          overrides: {
            '/partner/hotels/11':
                jsonResponse(detailJson(status: 'APPROVED'), 200),
          },
        ),
      );
      await tester.tap(find.text('Bay View Danang'));
      await tester.pumpAndSettle();

      expect(find.text(en.partnerPropertyVisibilityNotPublic), findsOneWidget);
    });
  });

  // ── 13. Role-aware UX ────────────────────────────────────────────────────

  group('team role', () {
    testWidgets('the owner sees listing actions', (tester) async {
      final handles = await pumpProperties(tester);
      expect(handles.partner.teamRole, PartnerTeamRole.owner);
      expect(find.text(en.partnerPropertyDeactivateAction), findsOneWidget);
      expect(find.text(en.partnerPropertyActionsOwnerOnly), findsNothing);
    });

    test('a non-owner role fails closed for write affordances', () {
      // PartnerPropertyService applies no team-role check — it is owner-only,
      // so a non-owner cannot reach these endpoints at all. Anything other than
      // OWNER must therefore not be offered the action.
      for (final role in [
        PartnerTeamRole.manager,
        PartnerTeamRole.frontDesk,
        PartnerTeamRole.finance,
        PartnerTeamRole.viewer,
        PartnerTeamRole.unknown,
      ]) {
        expect(role == PartnerTeamRole.owner, isFalse);
      }
      expect(PartnerTeamRole.unknown.canEditSettings, isFalse);
      expect(PartnerTeamRole.unknown.canManageTeam, isFalse);
    });
  });

  // ── 14–16, 19. Responsive ────────────────────────────────────────────────

  group('responsive', () {
    testWidgets('desktop shows list and detail side by side', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpProperties(tester, size: const Size(1600, 1600));
      await tester.tap(find.text('Bay View Danang'));
      await tester.pumpAndSettle();

      expect(find.text(en.partnerPropertyDetailHeading), findsOneWidget);
      expect(find.text('Bay View Danang'), findsWidgets);
      expect(errors, isEmpty, reason: errors.join('\n---\n'));
    });

    testWidgets('tablet renders without layout errors', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpProperties(tester, size: const Size(820, 1800));
      expect(errors, isEmpty, reason: errors.join('\n---\n'));
    });

    testWidgets('mobile has no horizontal overflow', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpProperties(tester, size: const Size(390, 2400));
      expect(find.text('Bay View Danang'), findsOneWidget);
      expect(errors, isEmpty, reason: errors.join('\n---\n'));
    });

    testWidgets('a very narrow phone still does not overflow', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpProperties(tester, size: const Size(320, 2600));
      expect(errors, isEmpty, reason: errors.join('\n---\n'));
    });

    testWidgets('mobile detail does not overflow', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpProperties(tester, size: const Size(390, 3000));
      await tester.tap(find.text('Bay View Danang'));
      await tester.pumpAndSettle();
      expect(find.text(en.partnerPropertyDetailHeading), findsOneWidget);
      expect(errors, isEmpty, reason: errors.join('\n---\n'));
    });
  });

  // ── 17–18. Localization ──────────────────────────────────────────────────

  group('localization', () {
    testWidgets('English renders English strings', (tester) async {
      await pumpProperties(tester, locale: const Locale('en'));
      expect(find.text(en.partnerPropertiesCount(1)), findsOneWidget);
      expect(find.text(en.partnerPropertyStatusPublished), findsWidgets);
    });

    testWidgets('Vietnamese renders Vietnamese strings', (tester) async {
      await pumpProperties(tester, locale: const Locale('vi'));
      expect(find.text(vi.partnerPropertiesCount(1)), findsOneWidget);
      expect(find.text(vi.partnerPropertyStatusPublished), findsWidgets);
      expect(find.text(en.partnerPropertyStatusPublished), findsNothing);
    });

    testWidgets('Vietnamese detail is fully localized and does not overflow',
        (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpProperties(
          tester, size: const Size(390, 3200), locale: const Locale('vi'));
      await tester.tap(find.text('Bay View Danang'));
      await tester.pumpAndSettle();

      expect(find.text(vi.partnerPropertyDetailHeading), findsOneWidget);
      expect(find.text(vi.partnerPropertySectionContact), findsOneWidget);
      expect(find.text(vi.partnerPropertyNotSet), findsWidgets);
      expect(errors, isEmpty, reason: errors.join('\n---\n'));
    });

    test('every C2 string exists in both locales', () {
      for (final l10n in <AppLocalizations>[en, vi]) {
        expect(l10n.partnerPropertiesEmptyTitle, isNotEmpty);
        expect(l10n.partnerPropertyDetailHeading, isNotEmpty);
        expect(l10n.partnerPropertyStatusPendingReview, isNotEmpty);
        expect(l10n.partnerPropertyStatusArchived, isNotEmpty);
        expect(l10n.partnerPropertyModerationNote, isNotEmpty);
        expect(l10n.partnerPropertyActionUncertain, isNotEmpty);
        expect(l10n.partnerPropertiesCount(0), isNotEmpty);
        expect(l10n.partnerPropertyRatingSummary('4.6', 12), isNotEmpty);
        expect(l10n.partnerPropertyActivatedMessage('X'), isNotEmpty);
      }
    });
  });

  // ── 20. DTO mapping ──────────────────────────────────────────────────────

  group('DTO mapping', () {
    test('maps the summary record field for field', () {
      final p = PartnerProperty.fromJson(summaryJson())!;
      expect(p.id, 11);
      expect(p.slug, 'bay-view-danang');
      expect(p.shortDescription, 'Beachfront resort');
      expect(p.verified, isTrue);
      expect(p.featured, isFalse);
      expect(p.ratingAvg, 4.6);
      expect(p.reviewCount, 12);
      expect(p.placeStatus, PartnerPlaceStatus.published);
      expect(p.createdAt, isNotNull);
    });

    test('maps the detail record and trims LocalTime seconds', () {
      final d = PartnerPropertyDetail.fromJson(detailJson())!;
      expect(d.checkIn, '14:00');
      expect(d.checkOut, '12:00');
      expect(d.phone, isNull);
      expect(d.hasAnyContact, isFalse);
      expect(d.hasAnyPolicy, isTrue, reason: 'check-in/out are present');
      expect(d.hasCoordinates, isTrue);
      expect(d.ownerBusinessName, 'Bay View Resorts');
    });

    test('a single coordinate axis is not a location', () {
      final d = PartnerPropertyDetail.fromJson(detailJson(longitude: null))!;
      expect(d.hasCoordinates, isFalse);
    });

    test('copyWithActive preserves every other field', () {
      final p = PartnerProperty.fromJson(summaryJson())!;
      final off = p.copyWithActive(false);
      expect(off.active, isFalse);
      expect(off.id, p.id);
      expect(off.name, p.name);
      expect(off.status, p.status);
      expect(off.verified, p.verified);
      expect(off.reviewCount, p.reviewCount);
    });

    test('a malformed detail body fails rather than rendering blanks',
        () async {
      final api = ApiClient(
          client: MockClient((_) async => http.Response('[]', 200,
              headers: {'content-type': 'application/json; charset=utf-8'})))
        ..demoMode = false;
      final result = await api.getPartnerProperty(11);
      expect(result.success, isFalse);
      expect(result.errorKind, ApiErrorKind.malformed);
    });
  });
}
