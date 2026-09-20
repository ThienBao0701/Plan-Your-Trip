import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/core/app_role.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/core/partner/partner_state.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/partner/properties/partner_properties_screen.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_en.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Phase C — My Properties: the list, the create affordance, and the gate.
///
/// The payloads are `PartnerHotelSummaryResponse` and `PartnerHotelResponse`
/// exactly as Phase C returns them, and the ownership semantics are the
/// backend's: the list is owner-scoped server-side, and a property that is not
/// the caller's answers 404 like one that does not exist.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final en = AppLocalizationsEn();

  http.Response jsonResponse(Object body, int status) => http.Response(
        jsonEncode(body),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  Map<String, dynamic> errorBody(int status, String message) => {
        'timestamp': DateTime.now().toIso8601String(),
        'status': status,
        'error': 'Error',
        'message': message,
        'path': '/api/partner/hotels',
      };

  Map<String, dynamic> profileJson({String verificationStatus = 'APPROVED'}) =>
      {
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
        'ownedHotelCount': 0,
        'activeRoomCount': 0,
        'todaysArrivals': 0,
        'todaysDepartures': 0,
        'unreadMessages': 0,
        'unreadNotifications': 0,
        'pendingReviews': 0,
        'activePromotions': 0,
        'quickActions': <Object>[],
      };

  /// `PartnerHotelSummaryResponse`, with the Phase C catalogue references.
  Map<String, dynamic> summaryJson({
    int id = 11,
    String name = 'Bay View Danang',
    String status = 'DRAFT',
    bool active = true,
  }) =>
      {
        'id': id,
        'name': name,
        'slug': 'bay-view-danang',
        'shortDescription': 'Beachfront stay',
        'address': '12 Vo Nguyen Giap, Da Nang',
        'active': active,
        'featured': false,
        'verified': false,
        'ratingAvg': 0,
        'reviewCount': 0,
        'status': status,
        'category': {
          'id': 1,
          'name': 'Accommodation',
          'slug': 'accommodation',
          'type': 'ACCOMMODATION',
        },
        'subcategory': {
          'id': 2,
          'name': 'Hotel',
          'slug': 'hotel',
          'type': 'ACCOMMODATION',
        },
        'administrativeUnit': {
          'id': 120,
          'name': 'My Khe',
          'slug': 'my-khe',
          'fullPath': 'Vietnam > Da Nang > My Khe',
        },
        'createdAt': '2026-09-01T02:00:00Z',
        'updatedAt': '2026-09-02T02:00:00Z',
      };

  Map<String, dynamic> detailJson({int id = 11, String status = 'DRAFT'}) => {
        ...summaryJson(id: id, status: status),
        'description': 'A longer description.',
        'latitude': 16.0544,
        'longitude': 108.2022,
        'phone': null,
        'email': null,
        'website': null,
        'facebook': null,
        'instagram': null,
        'checkIn': '14:00:00',
        'checkOut': '12:00:00',
        'childrenPolicy': null,
        'petPolicy': null,
        'smokingPolicy': null,
        'ownerProfileId': 7,
        'ownerBusinessName': 'Bay View Resorts',
        'starRating': 3,
        'cancellationPolicy': null,
        'freeCancellation': false,
        'paymentPolicy': null,
        'prepaymentRequired': false,
        'parkingAvailable': false,
        'parkingFree': false,
        'parkingDescription': null,
        'wifiAvailable': false,
        'wifiFree': false,
        'internetDescription': null,
        'languages': <String>[],
        'paymentMethods': <String>[],
        'amenities': <Object>[],
      };

  final requestLog = <String>[];

  http.Client propertiesClient({
    List<Map<String, dynamic>>? hotels,
    Map<String, http.Response>? overrides,
  }) =>
      MockClient((request) async {
        final path = request.url.path;
        requestLog.add('${request.method} $path');

        if (overrides != null) {
          for (final entry in overrides.entries) {
            if (path.endsWith(entry.key)) return entry.value;
          }
        }
        if (path.endsWith('/partner/profile')) {
          return jsonResponse(profileJson(), 200);
        }
        if (path.endsWith('/partner/extranet/home')) {
          return jsonResponse(extranetHomeJson(), 200);
        }
        if (path.endsWith('/partner/team')) {
          return jsonResponse(<Object>[], 200);
        }
        // The admin-managed catalogue the editor chooses from, trimmed to what
        // one property needs.
        if (path.endsWith('/categories')) {
          return jsonResponse([
            {
              'id': 1,
              'parentId': null,
              'name': 'Accommodation',
              'slug': 'accommodation',
              'type': 'ACCOMMODATION',
              'active': true,
            },
          ], 200);
        }
        if (path.endsWith('/amenities')) return jsonResponse(<Object>[], 200);
        if (path.endsWith('/locations/roots')) {
          return jsonResponse([
            {
              'id': 100,
              'parentId': null,
              'name': 'Vietnam',
              'slug': 'vietnam',
              'type': 'COUNTRY',
              'active': true,
            },
          ], 200);
        }
        if (path.endsWith('/locations/100/children')) {
          return jsonResponse([
            {
              'id': 110,
              'parentId': 100,
              'name': 'Da Nang',
              'slug': 'da-nang',
              'type': 'CITY',
              'fullPath': 'Vietnam > Da Nang',
              'active': true,
            },
          ], 200);
        }
        if (path.contains('/locations/')) return jsonResponse(<Object>[], 200);
        if (request.method == 'POST' && path.endsWith('/partner/hotels')) {
          return jsonResponse(detailJson(id: 12), 201);
        }
        final detail = RegExp(r'/partner/hotels/(\d+)$').firstMatch(path);
        if (detail != null) {
          final id = int.parse(detail.group(1)!);
          final list = hotels ?? [summaryJson()];
          if (!list.any((hotel) => hotel['id'] == id)) {
            return jsonResponse(errorBody(404, 'Hotel not found: $id'), 404);
          }
          return jsonResponse(detailJson(id: id), 200);
        }
        if (path.endsWith('/partner/hotels')) {
          return jsonResponse(hotels ?? [summaryJson()], 200);
        }
        return jsonResponse(errorBody(404, 'Not found'), 404);
      });

  Future<({AppState app, PartnerState partner})> pumpProperties(
    WidgetTester tester, {
    http.Client? client,
    Size size = const Size(1440, 2000),
  }) async {
    final app = AppState(
        api: ApiClient(client: client ?? propertiesClient())..demoMode = false)
      ..demoMode = false
      ..email = 'partner@planyourtrip.com'
      ..role = AppRole.partner;
    final partner = PartnerState(api: app.api)..bindSession(app);
    await partner.loadWorkspace(app);

    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(AppScope(
      notifier: app,
      child: PartnerScope(
        notifier: partner,
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: SingleChildScrollView(child: PartnerPropertiesScreen()),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return (app: app, partner: partner);
  }

  int countOf(String entry) =>
      requestLog.where((logged) => logged.endsWith(entry)).length;

  setUp(requestLog.clear);

  // ── 1. Empty state ───────────────────────────────────────────────────────

  group('empty state', () {
    testWidgets('invites the partner to create their first property',
        (tester) async {
      await pumpProperties(
        tester,
        client: propertiesClient(hotels: const []),
      );

      expect(find.text(en.partnerPropertiesEmptyTitle), findsOneWidget);
      expect(find.text(en.partnerPropertiesEmptyMessage), findsOneWidget);
      // The copy must not suggest the property is already listed anywhere.
      expect(find.text(en.partnerPropertyVisibilityPublic), findsNothing);
      // Two ways to start: the empty state's own action and the header button.
      expect(find.text(en.partnerPropertyAddAction), findsNWidgets(2));
    });

    testWidgets('the empty state is not a failure', (tester) async {
      await pumpProperties(
        tester,
        client: propertiesClient(hotels: const []),
      );

      expect(find.text(en.partnerStatusForbiddenTitle), findsNothing);
      expect(find.text(en.partnerStatusAwaitingApprovalTitle), findsNothing);
      expect(find.text(en.partnerDashboardErrorGeneric), findsNothing);
    });
  });

  // ── 2. Create affordance ─────────────────────────────────────────────────

  group('add property', () {
    testWidgets('the header action opens the editor', (tester) async {
      await pumpProperties(tester);

      await tester.tap(find.byKey(const Key('property-add-action')));
      await tester.pumpAndSettle();

      expect(find.text(en.partnerPropertyEditorCreateTitle), findsWidgets);
      expect(find.byKey(const Key('property-editor-name')), findsOneWidget);
      // The editor reads the catalogue, not another partner's data.
      expect(countOf('/api/categories'), 1);
      expect(countOf('/api/locations/roots'), 1);
    });

    testWidgets('the empty state action opens the same editor', (tester) async {
      await pumpProperties(
        tester,
        client: propertiesClient(hotels: const []),
      );

      await tester.tap(find.text(en.partnerPropertyAddAction).last);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('property-editor-name')), findsOneWidget);
    });

    testWidgets(
        'a saved property comes back from the server, not from the form',
        (tester) async {
      await pumpProperties(
        tester,
        client: propertiesClient(hotels: const []),
      );
      expect(find.text(en.partnerPropertiesEmptyTitle), findsOneWidget);
      final before = countOf('/api/partner/hotels');

      await tester.tap(find.byKey(const Key('property-add-action')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('property-editor-name')), 'Bay View Danang');
      await tester.enterText(find.byKey(const Key('property-editor-address')),
          '12 Vo Nguyen Giap, Da Nang');
      await tester.tap(find.byKey(const Key('property-editor-province')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Da Nang').last);
      await tester.pumpAndSettle();

      final save = find.byKey(const Key('property-editor-save'));
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();

      // The editor closed, and the list was re-read from the backend rather
      // than patched locally with what was typed.
      expect(find.byKey(const Key('property-editor-name')), findsNothing);
      expect(countOf('/api/partner/hotels'), greaterThan(before));
    });

    testWidgets('leaving the editor without saving reloads nothing',
        (tester) async {
      await pumpProperties(tester);
      final listLoads = countOf('/api/partner/hotels');

      await tester.tap(find.byKey(const Key('property-add-action')));
      await tester.pumpAndSettle();
      final cancel = find.byKey(const Key('property-editor-cancel'));
      await tester.ensureVisible(cancel);
      await tester.pumpAndSettle();
      await tester.tap(cancel);
      await tester.pumpAndSettle();

      expect(countOf('/api/partner/hotels'), listLoads);
      expect(find.text('Bay View Danang'), findsOneWidget);
    });
  });

  // ── 3. The list itself ───────────────────────────────────────────────────

  group('list', () {
    testWidgets('shows exactly the properties the backend returned',
        (tester) async {
      await pumpProperties(
        tester,
        client: propertiesClient(hotels: [
          summaryJson(),
          summaryJson(id: 12, name: 'Bay View Hoi An'),
        ]),
      );

      expect(find.text('Bay View Danang'), findsOneWidget);
      expect(find.text('Bay View Hoi An'), findsOneWidget);
      expect(find.text(en.partnerPropertiesCount(2)), findsOneWidget);
      // Two owner-scoped reads — the workspace's own and this module's — and
      // nothing else: no unscoped catalogue request the client would have to
      // filter, and no admin endpoint.
      expect(countOf('/api/partner/hotels'), 2);
      expect(
          requestLog.where((entry) => entry.contains('/api/places')), isEmpty);
      expect(
          requestLog.where((entry) => entry.contains('/api/admin')), isEmpty);
    });

    testWidgets('a draft is shown as a draft and as not public',
        (tester) async {
      await pumpProperties(tester);

      expect(find.text(en.partnerPropertyStatusDraft), findsWidgets);
      expect(find.text(en.partnerPropertyStatusPublished), findsNothing);
    });

    testWidgets('there is no publish action anywhere on the screen',
        (tester) async {
      await pumpProperties(tester);

      // The only listing control is the workspace switch, which is worded as
      // one — turning it off or on is not publication, and the seeded row is
      // listed, so its action is the "off" one.
      expect(find.text(en.partnerPropertyDeactivateAction), findsWidgets);
      expect(find.text(en.partnerPropertyVisibilityPublic), findsNothing);
    });
  });

  // ── 4. Editing an existing property ──────────────────────────────────────

  group('edit', () {
    testWidgets('the detail panel opens the editor with the stored record',
        (tester) async {
      await pumpProperties(tester);

      await tester.tap(find.text('Bay View Danang'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('property-edit-action')), findsOneWidget);

      await tester.tap(find.byKey(const Key('property-edit-action')));
      await tester.pumpAndSettle();

      expect(find.text(en.partnerPropertyEditorEditTitle), findsWidgets);
      // The form is filled from the record the backend returned for this
      // caller — the same property, never another one.
      expect(find.text('12 Vo Nguyen Giap, Da Nang'), findsOneWidget);
      expect(find.text('Vietnam > Da Nang > My Khe'), findsWidgets);
    });
  });

  // ── 5. The approval gate ─────────────────────────────────────────────────

  group('approval gate', () {
    testWidgets('a profile that is not approved gets no create affordance',
        (tester) async {
      await pumpProperties(
        tester,
        client: propertiesClient(
          overrides: {
            '/partner/hotels': jsonResponse(
                errorBody(403, 'Partner profile is not approved'), 403),
          },
        ),
      );

      expect(find.text(en.partnerStatusForbiddenTitle), findsOneWidget);
      expect(find.byKey(const Key('property-add-action')), findsNothing);
      expect(find.byKey(const Key('property-edit-action')), findsNothing);
    });

    testWidgets('an expired session is reported as one, with no create action',
        (tester) async {
      await pumpProperties(
        tester,
        client: propertiesClient(
          overrides: {
            '/partner/hotels':
                jsonResponse(errorBody(401, 'Authentication required'), 401),
          },
        ),
      );

      expect(find.byKey(const Key('property-add-action')), findsNothing);
      expect(find.text(en.partnerPropertiesEmptyTitle), findsNothing);
    });

    testWidgets('a partner with no profile at all is sent to onboarding',
        (tester) async {
      await pumpProperties(
        tester,
        client: propertiesClient(
          overrides: {
            '/partner/hotels':
                jsonResponse(errorBody(404, 'Partner profile not found'), 404),
          },
        ),
      );

      expect(find.byKey(const Key('property-add-action')), findsNothing);
    });
  });
}
