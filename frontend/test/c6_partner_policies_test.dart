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
import 'package:planyourtrip_frontend/core/partner/partner_policy_models.dart';
import 'package:planyourtrip_frontend/core/partner/partner_state.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/partner/policies/partner_policies_screen.dart';
import 'package:planyourtrip_frontend/features/partner/policies/partner_policies_state.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_en.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_vi.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// C6 — Partner Policies (and the Assets audit outcome).
///
/// Encodes what the backend audit established:
///
///  * **Two domains, two authorization rules.** Property policies are
///    owner-only (`PartnerPropertyService` is not team-aware); workspace
///    settings are OWNER-or-MANAGER via the one team-aware resolver.
///  * **Both payloads are complete** (5 and 9 fields), so a full editor cannot
///    erase anything by omission — unlike the C2 and C5 PUTs.
///  * **No partner asset API exists.** Every media mutation is ADMIN-only, so
///    no upload/delete/reorder affordance is rendered.
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
        'ownedHotelCount': 1,
        'activeRoomCount': 2,
        'todaysArrivals': 0,
        'todaysDepartures': 0,
        'unreadMessages': 0,
        'unreadNotifications': 0,
        'pendingReviews': 0,
        'activePromotions': 0,
        'quickActions': <Object>[],
      };

  Map<String, dynamic> hotelListJson({int id = 11, String name = 'Bay View Danang'}) => {
        'id': id,
        'name': name,
        'slug': 'bay-view-danang',
        'shortDescription': null,
        'address': '12 Vo Nguyen Giap',
        'active': true,
        'featured': false,
        'verified': true,
        'ratingAvg': 4.6,
        'reviewCount': 12,
        'status': 'PUBLISHED',
        'createdAt': '2026-07-30T02:00:00Z',
        'updatedAt': '2026-08-20T02:00:00Z',
      };

  /// `PartnerHotelResponse` — the policy slice is read from here.
  Map<String, dynamic> hotelDetailJson({
    int id = 11,
    String? checkIn = '14:00:00',
    String? checkOut = '12:00:00',
    String? childrenPolicy,
    String? petPolicy,
    String? smokingPolicy,
  }) =>
      {
        'id': id,
        'name': 'Bay View Danang',
        'slug': 'bay-view-danang',
        'shortDescription': null,
        'description': null,
        'address': '12 Vo Nguyen Giap',
        'latitude': 16.05,
        'longitude': 108.2,
        'phone': null,
        'email': null,
        'website': null,
        'facebook': null,
        'instagram': null,
        'checkIn': checkIn,
        'checkOut': checkOut,
        'childrenPolicy': childrenPolicy,
        'petPolicy': petPolicy,
        'smokingPolicy': smokingPolicy,
        'active': true,
        'featured': false,
        'verified': true,
        'ratingAvg': 4.6,
        'reviewCount': 12,
        'status': 'PUBLISHED',
        'ownerProfileId': 7,
        'ownerBusinessName': 'Bay View Resorts',
        'createdAt': '2026-07-30T02:00:00Z',
        'updatedAt': '2026-08-20T02:00:00Z',
      };

  /// `PartnerSettingsResponse` — all 13 fields.
  Map<String, dynamic> settingsJson({
    bool email = true,
    bool sms = false,
    bool inApp = true,
    bool booking = true,
    bool payment = true,
    bool review = true,
    bool promotion = true,
    String? language = 'en',
    String? timezone = 'Asia/Ho_Chi_Minh',
  }) =>
      {
        'id': 1,
        'partnerProfileId': 7,
        'defaultLanguage': language,
        'timezone': timezone,
        'notificationEmailEnabled': email,
        'notificationSmsEnabled': sms,
        'notificationInAppEnabled': inApp,
        'bookingNotificationEnabled': booking,
        'paymentNotificationEnabled': payment,
        'reviewNotificationEnabled': review,
        'promotionNotificationEnabled': promotion,
        'createdAt': '2026-08-29T08:26:10Z',
        'updatedAt': '2026-08-29T08:26:10Z',
      };

  late List<String> requestLog;
  late List<Map<String, dynamic>> putBodies;
  setUp(() {
    requestLog = <String>[];
    putBodies = <Map<String, dynamic>>[];
  });

  MockClient policiesClient({
    Map<String, http.Response>? overrides,
    List<Map<String, dynamic>>? hotels,
    Map<String, dynamic>? detail,
    Map<String, dynamic>? settings,
    bool throwNetwork = false,
    String verificationStatus = 'APPROVED',
  }) =>
      MockClient((request) async {
        final path = request.url.path;
        requestLog.add('${request.method} $path');
        if (throwNetwork) throw http.ClientException('offline');
        if (request.method == 'PUT' && request.body.isNotEmpty) {
          putBodies.add(jsonDecode(request.body) as Map<String, dynamic>);
        }

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
        if (path.endsWith('/partner/team')) return jsonResponse(<Object>[], 200);
        if (path.endsWith('/partner/hotels')) {
          return jsonResponse(hotels ?? [hotelListJson()], 200);
        }
        if (path.endsWith('/partner/settings')) {
          return jsonResponse(settings ?? settingsJson(), 200);
        }

        final policyPut =
            RegExp(r'/partner/hotels/(\d+)/policies$').firstMatch(path);
        if (policyPut != null) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          // Mirror the backend's @NotNull bean validation.
          if (body['checkIn'] == null || body['checkOut'] == null) {
            return jsonResponse(
                errorBody(400, 'checkIn: must not be null', path), 400);
          }
          return jsonResponse(
            hotelDetailJson(
              checkIn: body['checkIn'] as String?,
              checkOut: body['checkOut'] as String?,
              childrenPolicy: body['childrenPolicy'] as String?,
              petPolicy: body['petPolicy'] as String?,
              smokingPolicy: body['smokingPolicy'] as String?,
            ),
            200,
          );
        }

        final hotelDetail =
            RegExp(r'/partner/hotels/(\d+)$').firstMatch(path);
        if (hotelDetail != null) {
          final id = int.parse(hotelDetail.group(1)!);
          final owned = (hotels ?? [hotelListJson()]).map((h) => h['id']);
          if (!owned.contains(id)) {
            return jsonResponse(
                errorBody(404, 'Hotel not found: $id', path), 404);
          }
          return jsonResponse(detail ?? hotelDetailJson(id: id), 200);
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
              body: SingleChildScrollView(child: PartnerPoliciesScreen()),
            ),
          ),
        ),
      );

  Future<({AppState app, PartnerState partner})> pumpPolicies(
    WidgetTester tester, {
    http.Client? client,
    Size size = const Size(1600, 2600),
    Locale? locale,
  }) async {
    final app = partnerApp(client ?? policiesClient());
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

  // ── Assets: the audit outcome ────────────────────────────────────────────

  group('assets', () {
    testWidgets('no asset management affordance is rendered', (tester) async {
      await pumpPolicies(tester);

      // Every media mutation is ADMIN-only, so none of these may exist.
      expect(find.byIcon(Icons.upload_rounded), findsNothing);
      expect(find.byIcon(Icons.upload_file_rounded), findsNothing);
      expect(find.byIcon(Icons.add_a_photo_rounded), findsNothing);
      expect(find.byIcon(Icons.delete_rounded), findsNothing);
      expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
      expect(find.byType(ReorderableListView), findsNothing);
    });

    testWidgets('the absence is stated rather than left blank', (tester) async {
      await pumpPolicies(tester);
      expect(find.text(en.partnerAssetsSection), findsOneWidget);
      expect(find.text(en.partnerAssetsDeferredBadge), findsOneWidget);
      expect(find.text(en.partnerAssetsDeferredMessage), findsOneWidget);
    });

    testWidgets('no media request is ever issued', (tester) async {
      await pumpPolicies(tester);
      expect(
        requestLog.any((r) => r.contains('media') || r.contains('/assets')),
        isFalse,
      );
    });
  });

  // ── Property policies ────────────────────────────────────────────────────

  group('property policies', () {
    testWidgets('renders the five policy fields from the hotel detail',
        (tester) async {
      await pumpPolicies(tester);

      expect(find.text(en.partnerPoliciesPropertySection), findsOneWidget);
      expect(find.text('${en.partnerPoliciesCheckIn} *'), findsOneWidget);
      expect(find.text('${en.partnerPoliciesCheckOut} *'), findsOneWidget);
      expect(find.text(en.partnerPoliciesChildren), findsOneWidget);
      expect(find.text(en.partnerPoliciesPets), findsOneWidget);
      expect(find.text(en.partnerPoliciesSmoking), findsOneWidget);
      // LocalTime renders trimmed, not as a fabricated date.
      expect(find.text('14:00'), findsOneWidget);
      expect(find.text('12:00'), findsOneWidget);
    });

    testWidgets('warns that policy changes are live for existing bookings',
        (tester) async {
      await pumpPolicies(tester);
      // The backend does not snapshot property policies onto bookings.
      expect(find.text(en.partnerPoliciesLiveWarning), findsOneWidget);
    });

    testWidgets('shows no unsaved-changes prompt until the draft differs',
        (tester) async {
      await pumpPolicies(tester);
      expect(find.text(en.partnerPoliciesNoChanges), findsWidgets);
      expect(find.text(en.partnerPoliciesSave), findsNothing);
    });

    test('editing marks the draft dirty; reverting clears it', () async {
      final app = partnerApp(policiesClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final policies = PartnerPoliciesState(api: app.api);
      await policies.load(partner, 11);

      expect(policies.policiesDirty, isFalse);
      policies.setCheckIn('15:00');
      expect(policies.policiesDirty, isTrue);
      policies.revertPolicies();
      expect(policies.policiesDirty, isFalse);
      expect(policies.draftPolicies!.checkIn, '14:00');
    });

    test('saving sends the complete five-field body', () async {
      final app = partnerApp(policiesClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final policies = PartnerPoliciesState(api: app.api);
      await policies.load(partner, 11);
      putBodies.clear();

      policies.setCheckIn('15:00');
      policies.setChildrenPolicy('Children under 6 stay free');
      final result = await policies.savePolicies();

      expect(result, PartnerPolicySaveResult.success);
      final body = putBodies.single;
      // Every field the record declares is present — nothing can be erased by
      // omission the way the C2/C5 PUTs could.
      expect(body.keys.toSet(), {
        'checkIn',
        'checkOut',
        'childrenPolicy',
        'petPolicy',
        'smokingPolicy',
      });
      expect(body['checkIn'], '15:00');
      expect(body['checkOut'], '12:00');
      expect(body['childrenPolicy'], 'Children under 6 stay free');
      expect(body['petPolicy'], isNull);
    });

    test('an emptied house rule is sent as null, not an empty string',
        () async {
      final app = partnerApp(policiesClient(
          detail: hotelDetailJson(childrenPolicy: 'Existing rule')));
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final policies = PartnerPoliciesState(api: app.api);
      await policies.load(partner, 11);
      expect(policies.draftPolicies!.childrenPolicy, 'Existing rule');
      putBodies.clear();

      policies.setChildrenPolicy('   ');
      await policies.savePolicies();

      expect(putBodies.single['childrenPolicy'], isNull,
          reason: 'clearing a rule must remove it, not store whitespace');
    });

    test('the state refuses to submit without both required times', () async {
      final app = partnerApp(
          policiesClient(detail: hotelDetailJson(checkIn: null)));
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final policies = PartnerPoliciesState(api: app.api);
      await policies.load(partner, 11);
      requestLog.clear();

      expect(policies.canSubmitPolicies, isFalse);
      final result = await policies.savePolicies();
      expect(result, PartnerPolicySaveResult.validation);
      expect(requestLog.any((r) => r.startsWith('PUT')), isFalse,
          reason: 'the backend @NotNull rule is known, so do not ask');
    });

    test('a 400 from the backend is reported as validation', () async {
      final app = partnerApp(policiesClient(overrides: {
        '/policies': jsonResponse(
            errorBody(400, 'checkIn: must not be null', '/policies'), 400),
      }));
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final policies = PartnerPoliciesState(api: app.api);
      await policies.load(partner, 11);

      policies.setCheckIn('15:00');
      final result = await policies.savePolicies();
      expect(result, PartnerPolicySaveResult.validation);
      expect(policies.policiesErrorMessage, 'checkIn: must not be null');
      // A failed save must not look like it worked.
      expect(policies.savedPolicies!.checkIn, '14:00');
    });

    test('the saved value is re-read from the server response', () async {
      final app = partnerApp(policiesClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final policies = PartnerPoliciesState(api: app.api);
      await policies.load(partner, 11);

      policies.setCheckIn('16:30');
      await policies.savePolicies();

      expect(policies.savedPolicies!.checkIn, '16:30');
      expect(policies.policiesDirty, isFalse);
    });
  });

  // ── Workspace settings ───────────────────────────────────────────────────

  group('workspace settings', () {
    testWidgets('renders channels and topics separately', (tester) async {
      await pumpPolicies(tester);

      expect(find.text(en.partnerPoliciesSettingsSection), findsOneWidget);
      expect(find.text(en.partnerPoliciesChannels), findsOneWidget);
      expect(find.text(en.partnerPoliciesTopics), findsOneWidget);
      expect(find.text(en.partnerPoliciesChannelEmail), findsOneWidget);
      expect(find.text(en.partnerPoliciesTopicBooking), findsOneWidget);
      // Language/timezone are free text on the backend, so shown not edited.
      expect(find.text('Asia/Ho_Chi_Minh'), findsOneWidget);
    });

    test('toggling marks dirty and saving sends all nine fields', () async {
      final app = partnerApp(policiesClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final policies = PartnerPoliciesState(api: app.api);
      await policies.load(partner, 11);
      putBodies.clear();

      expect(policies.settingsDirty, isFalse);
      policies.toggleSetting(PartnerSettingsToggle.sms, true);
      expect(policies.settingsDirty, isTrue);

      final result = await policies.saveSettings();
      expect(result, PartnerPolicySaveResult.success);
      final body = putBodies.single;
      expect(body.keys.toSet(), {
        'defaultLanguage',
        'timezone',
        'notificationEmailEnabled',
        'notificationSmsEnabled',
        'notificationInAppEnabled',
        'bookingNotificationEnabled',
        'paymentNotificationEnabled',
        'reviewNotificationEnabled',
        'promotionNotificationEnabled',
      });
      expect(body['notificationSmsEnabled'], isTrue);
      // Echoed back untouched — the service only applies them when non-null.
      expect(body['timezone'], 'Asia/Ho_Chi_Minh');
    });

    test('a 403 is the team-role refusal, with the server message', () async {
      final app = partnerApp(policiesClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final policies = PartnerPoliciesState(api: app.api);
      await policies.load(partner, 11);

      final refusing = PartnerPoliciesState(
        api: ApiClient(
            client: policiesClient(overrides: {
          '/partner/settings': jsonResponse(
              errorBody(
                  403,
                  'Your role does not allow you to manage business/notification settings',
                  '/api/partner/settings'),
              403),
        }))
          ..demoMode = false,
      );
      // The settings GET also 403s, so the panel reports it rather than
      // silently rendering nothing.
      await refusing.load(partner, 11);
      expect(refusing.draftSettings, isNull);
      expect(refusing.settingsLoadErrorKind, ApiErrorKind.forbidden);
      // ...and the property policy form is unaffected.
      expect(refusing.draftPolicies, isNotNull);
    });

    test('a settings failure does not blank the policy form', () async {
      final app = partnerApp(policiesClient(overrides: {
        '/partner/settings':
            jsonResponse(errorBody(500, 'boom', '/api/partner/settings'), 500),
      }));
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final policies = PartnerPoliciesState(api: app.api);
      await policies.load(partner, 11);

      expect(policies.status, PartnerPoliciesStatus.ready);
      expect(policies.draftPolicies, isNotNull,
          reason: 'the two domains load independently');
      expect(policies.draftSettings, isNull);
      expect(policies.settingsLoadErrorKind, ApiErrorKind.server);
    });

    test('a timed-out save is uncertain, never a clean failure', () async {
      final api = ApiClient(
          client: MockClient((_) async => throw TimeoutException('slow')))
        ..demoMode = false;
      final result = await api.updatePartnerWorkspaceSettings(
        PartnerWorkspaceSettings.fromJson(settingsJson())!,
      );
      expect(result.errorKind, ApiErrorKind.uncertain);
    });
  });

  // ── Team roles — two different rules on one screen ───────────────────────

  group('team roles', () {
    test('property policies are owner-only; settings are OWNER or MANAGER', () {
      // PartnerPropertyService is not team-aware.
      expect(
          PartnerPolicyPermissions.canEditPropertyPolicies(
              PartnerTeamRole.owner),
          isTrue);
      for (final role in [
        PartnerTeamRole.manager,
        PartnerTeamRole.frontDesk,
        PartnerTeamRole.finance,
        PartnerTeamRole.viewer,
        PartnerTeamRole.unknown,
      ]) {
        expect(PartnerPolicyPermissions.canEditPropertyPolicies(role), isFalse,
            reason: '$role must not be offered a property-policy write');
      }

      // SETTINGS_WRITE_ROLES = OWNER, MANAGER.
      expect(
          PartnerPolicyPermissions.canEditWorkspaceSettings(
              PartnerTeamRole.owner),
          isTrue);
      expect(
          PartnerPolicyPermissions.canEditWorkspaceSettings(
              PartnerTeamRole.manager),
          isTrue);
      for (final role in [
        PartnerTeamRole.frontDesk,
        PartnerTeamRole.finance,
        PartnerTeamRole.viewer,
        PartnerTeamRole.unknown,
      ]) {
        expect(
            PartnerPolicyPermissions.canEditWorkspaceSettings(role), isFalse);
      }
    });

    testWidgets('the owner sees both editors', (tester) async {
      final handles = await pumpPolicies(tester);
      expect(handles.partner.teamRole, PartnerTeamRole.owner);
      expect(find.text(en.partnerPoliciesOwnerOnly), findsNothing);
      expect(find.text(en.partnerPoliciesSettingsRoleNote), findsNothing);
    });
  });

  // ── Property context ─────────────────────────────────────────────────────

  group('property context', () {
    test('no properties is its own state', () async {
      final app =
          partnerApp(policiesClient(hotels: <Map<String, dynamic>>[]));
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final policies = PartnerPoliciesState(api: app.api);
      await policies.load(partner, null);
      expect(policies.status, PartnerPoliciesStatus.noProperties);
    });

    test('no property selected makes no request', () async {
      final app = partnerApp(policiesClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final policies = PartnerPoliciesState(api: app.api);
      requestLog.clear();
      await policies.load(partner, null);
      expect(policies.status, PartnerPoliciesStatus.noPropertySelected);
      expect(requestLog, isEmpty);
    });

    test('an unauthorized property id is refused before any request', () async {
      final app = partnerApp(policiesClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final policies = PartnerPoliciesState(api: app.api);
      requestLog.clear();
      await policies.load(partner, 999);
      expect(policies.status, PartnerPoliciesStatus.notFound);
      expect(requestLog, isEmpty);
    });

    test('switching property discards the previous draft', () async {
      final app = partnerApp(policiesClient(hotels: [
        hotelListJson(),
        hotelListJson(id: 12, name: 'Hoi An'),
      ]));
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final policies = PartnerPoliciesState(api: app.api);

      await policies.load(partner, 11);
      policies.setCheckIn('19:00');
      expect(policies.policiesDirty, isTrue);

      await policies.load(partner, 12);

      expect(policies.loadedPropertyId, 12);
      expect(policies.policiesDirty, isFalse,
          reason: 'a draft must never leak across properties');
      expect(policies.draftPolicies!.checkIn, '14:00');
    });
  });

  // ── Errors ───────────────────────────────────────────────────────────────

  group('errors', () {
    testWidgets('401 shows the session-expired view', (tester) async {
      await pumpPolicies(
        tester,
        client: policiesClient(overrides: {
          '/partner/hotels/11': jsonResponse(
              errorBody(401, 'Unauthorized', '/api/partner'), 401),
        }),
      );
      expect(find.text(en.partnerStatusUnauthorizedTitle), findsOneWidget);
    });

    testWidgets('403 on the property is an approval problem', (tester) async {
      await pumpPolicies(
        tester,
        client: policiesClient(overrides: {
          '/partner/hotels/11': jsonResponse(
              errorBody(403, 'Partner profile is not approved', '/api/partner'),
              403),
        }),
      );
      expect(find.text(en.partnerStatusForbiddenTitle), findsOneWidget);
    });

    testWidgets('404 shows the unavailable view', (tester) async {
      await pumpPolicies(
        tester,
        client: policiesClient(overrides: {
          '/partner/hotels/11': jsonResponse(
              errorBody(404, 'Hotel not found: 11', '/api/partner'), 404),
        }),
      );
      expect(find.text(en.partnerPoliciesUnavailableTitle), findsOneWidget);
    });

    test('a network failure is retryable', () async {
      final app = partnerApp(policiesClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);

      final offline = PartnerPoliciesState(
        api: ApiClient(client: policiesClient(throwNetwork: true))
          ..demoMode = false,
      );
      await offline.load(partner, 11);
      expect(offline.status, PartnerPoliciesStatus.error);
      expect(offline.isRetryable, isTrue);
    });

    testWidgets('a non-approved partner never reaches policies',
        (tester) async {
      final app = partnerApp(policiesClient(verificationStatus: 'SUBMITTED'));
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);

      await tester.pumpWidget(testApp(app: app, partner: partner));
      await tester.pumpAndSettle();

      expect(find.text(en.partnerStatusAwaitingApprovalTitle), findsOneWidget);
      expect(requestLog.any((r) => r.contains('/partner/settings')), isFalse);
    });
  });

  // ── Responsive ───────────────────────────────────────────────────────────

  group('responsive', () {
    testWidgets('desktop shows the two domains side by side', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpPolicies(tester, size: const Size(1700, 2600));
      expect(find.text(en.partnerPoliciesPropertySection), findsOneWidget);
      expect(find.text(en.partnerPoliciesSettingsSection), findsOneWidget);
      expect(errors, isEmpty, reason: errors.join('\n---\n'));
    });

    testWidgets('tablet renders without layout errors', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpPolicies(tester, size: const Size(820, 3000));
      expect(errors, isEmpty, reason: errors.join('\n---\n'));
    });

    testWidgets('mobile stacks with no horizontal overflow', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpPolicies(tester, size: const Size(390, 3400));
      expect(find.text(en.partnerPoliciesPropertySection), findsOneWidget);
      expect(errors, isEmpty, reason: errors.join('\n---\n'));
    });

    testWidgets('a very narrow phone does not overflow', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpPolicies(tester, size: const Size(320, 3600));
      expect(errors, isEmpty, reason: errors.join('\n---\n'));
    });
  });

  // ── Localization ─────────────────────────────────────────────────────────

  group('localization', () {
    testWidgets('English renders English strings', (tester) async {
      await pumpPolicies(tester, locale: const Locale('en'));
      expect(find.text(en.partnerPoliciesPropertySection), findsOneWidget);
      expect(find.text(en.partnerAssetsDeferredBadge), findsOneWidget);
    });

    testWidgets('Vietnamese renders Vietnamese strings', (tester) async {
      await pumpPolicies(tester, locale: const Locale('vi'));
      expect(find.text(vi.partnerPoliciesPropertySection), findsOneWidget);
      expect(find.text(vi.partnerAssetsDeferredBadge), findsOneWidget);
      expect(find.text(en.partnerPoliciesPropertySection), findsNothing);
    });

    testWidgets('Vietnamese mobile does not overflow', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpPolicies(
          tester, size: const Size(390, 3800), locale: const Locale('vi'));
      expect(errors, isEmpty, reason: errors.join('\n---\n'));
    });

    test('every C6 string exists in both locales', () {
      for (final l10n in <AppLocalizations>[en, vi]) {
        expect(l10n.partnerPoliciesTitle, isNotEmpty);
        expect(l10n.partnerPoliciesLiveWarning, isNotEmpty);
        expect(l10n.partnerPoliciesOwnerOnly, isNotEmpty);
        expect(l10n.partnerPoliciesSettingsRoleNote, isNotEmpty);
        expect(l10n.partnerPoliciesSaveValidation, isNotEmpty);
        expect(l10n.partnerAssetsDeferredMessage, isNotEmpty);
        expect(l10n.partnerPoliciesForProperty('X'), isNotEmpty);
        expect(l10n.partnerPoliciesSettingsUpdated('now'), isNotEmpty);
      }
    });
  });

  // ── DTO mapping ──────────────────────────────────────────────────────────

  group('DTO mapping', () {
    test('policy times are trimmed to HH:mm, nulls stay null', () {
      final p = PartnerPropertyPolicies.fromHotelJson(hotelDetailJson());
      expect(p.checkIn, '14:00');
      expect(p.checkOut, '12:00');
      expect(p.childrenPolicy, isNull);
      expect(p.hasHouseRules, isFalse);
      expect(p.canSubmit, isTrue);

      final missing = PartnerPropertyPolicies.fromHotelJson(
          hotelDetailJson(checkIn: null));
      expect(missing.canSubmit, isFalse);
    });

    test('copyWith can clear a rule back to null', () {
      const p = PartnerPropertyPolicies(
          checkIn: '14:00', checkOut: '12:00', petPolicy: 'No pets');
      expect(p.copyWith(petPolicy: null).petPolicy, isNull);
      // ...and leaves it alone when not mentioned.
      expect(p.copyWith(checkIn: '15:00').petPolicy, 'No pets');
    });

    test('maps the settings record and counts channels and topics', () {
      final s = PartnerWorkspaceSettings.fromJson(settingsJson())!;
      expect(s.defaultLanguage, 'en');
      expect(s.timezone, 'Asia/Ho_Chi_Minh');
      expect(s.notificationSmsEnabled, isFalse);
      expect(s.enabledChannelCount, 2);
      expect(s.enabledTopicCount, 4);
    });

    test('a body without the boolean fields is not a settings payload', () {
      expect(PartnerWorkspaceSettings.fromJson({'id': 1}), isNull);
    });

    test('sameAs ignores fields the form cannot change', () {
      final a = PartnerWorkspaceSettings.fromJson(settingsJson())!;
      final b = PartnerWorkspaceSettings.fromJson(
          settingsJson(language: 'vi', timezone: 'UTC'))!;
      expect(a.sameAs(b), isTrue,
          reason: 'language/timezone are not editable here, so not "dirty"');
      expect(a.sameAs(a.copyWith(notificationSmsEnabled: true)), isFalse);
    });
  });
}
