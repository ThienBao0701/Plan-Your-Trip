import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/mock/app_models.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/profile/profile_screen.dart';
import 'package:planyourtrip_frontend/features/profile/real_customer_profile_screen.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_en.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_vi.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget testApp({required Widget child, AppState? app, Locale? locale}) {
    return AppScope(
      notifier: app ?? AppState(),
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  Future<void> pumpSize(WidgetTester tester, Widget widget, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

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

  AppState realApp(http.Client client) => AppState(
        api: ApiClient(client: client)..demoMode = false,
      )..demoMode = false;

  AppState demoApp(http.Client client) =>
      AppState(api: ApiClient(client: client));

  Map<String, dynamic> identityJson({
    int id = 42,
    String fullName = 'Tran Thien Bao',
    String email = 'bao@example.com',
    String role = 'CUSTOMER',
  }) =>
      {
        'id': id,
        'fullName': fullName,
        'email': email,
        'role': role,
      };

  Map<String, dynamic> profileJson({
    String? preferredLanguage = 'en',
    String? preferredCurrency = 'VND',
    String? dietaryPreference = 'Vegetarian',
    String? passportNumberMasked = '••••1234',
    bool marketingConsent = true,
    int completionPercentage = 80,
  }) =>
      {
        'id': 5,
        'userId': 42,
        'avatarUrl': 'https://cdn.example.com/a.png',
        'preferredLanguage': preferredLanguage,
        'preferredCurrency': preferredCurrency,
        'preferredPaymentMethod': 'VNPay',
        'nationality': 'VN',
        'passportNumberMasked': passportNumberMasked,
        'emergencyContactName': 'Mai',
        'emergencyContactPhone': '0900000000',
        'accessibilityNeeds': 'None',
        'dietaryPreference': dietaryPreference,
        'travelStyle': 'Explorer',
        'marketingConsent': marketingConsent,
        'profileCompleted': false,
        'completionPercentage': completionPercentage,
        'createdAt': '2030-01-01T00:00:00Z',
        'updatedAt': '2030-02-01T00:00:00Z',
      };

  bool identityGet(http.Request r) =>
      r.method == 'GET' && r.url.path.endsWith('/me');
  bool profileGet(http.Request r) =>
      r.method == 'GET' && r.url.path.endsWith('/me/profile');
  bool profilePut(http.Request r) =>
      r.method == 'PUT' && r.url.path.endsWith('/me/profile');

  AppState routedApp({
    Future<http.Response> Function(http.Request)? onIdentity,
    Future<http.Response> Function(http.Request)? onProfile,
    Future<http.Response> Function(http.Request)? onUpdate,
    void Function(http.Request)? onRequest,
  }) =>
      realApp(MockClient((request) async {
        onRequest?.call(request);
        if (profilePut(request)) {
          return (onUpdate ??
              (_) async => jsonResponse(profileJson(), 200))(request);
        }
        if (profileGet(request)) {
          return (onProfile ??
              (_) async => jsonResponse(profileJson(), 200))(request);
        }
        if (identityGet(request)) {
          return (onIdentity ??
              (_) async => jsonResponse(identityJson(), 200))(request);
        }
        return jsonResponse(const <String, dynamic>{}, 200);
      }));

  // ── Contract parsing ───────────────────────────────────────────────────────

  group('Contract parsing', () {
    test('getAccountIdentity GETs /api/me and parses UserDto', () async {
      http.Request? seen;
      final app = routedApp(onRequest: (r) => seen = r);
      expect(
          await app.loadRealAccountIdentity(), CustomerProfileOutcome.success);
      expect(seen!.method, 'GET');
      expect(seen!.url.path.endsWith('/me'), isTrue);
      final id = app.realIdentity!;
      expect(id.id, 42);
      expect(id.fullName, 'Tran Thien Bao');
      expect(id.email, 'bao@example.com');
      expect(id.role, 'CUSTOMER');
    });

    test('getCustomerProfile parses every CustomerProfileResponse field',
        () async {
      final app = routedApp();
      expect(
          await app.loadRealCustomerProfile(), CustomerProfileOutcome.success);
      final p = app.realProfile!;
      expect(p.id, 5);
      expect(p.userId, 42);
      expect(p.avatarUrl, 'https://cdn.example.com/a.png');
      expect(p.preferredLanguage, 'en');
      expect(p.preferredCurrency, 'VND');
      expect(p.preferredPaymentMethod, 'VNPay');
      expect(p.nationality, 'VN');
      expect(p.passportNumberMasked, '••••1234');
      expect(p.emergencyContactName, 'Mai');
      expect(p.emergencyContactPhone, '0900000000');
      expect(p.accessibilityNeeds, 'None');
      expect(p.dietaryPreference, 'Vegetarian');
      expect(p.travelStyle, 'Explorer');
      expect(p.marketingConsent, isTrue);
      expect(p.profileCompleted, isFalse);
      expect(p.completionPercentage, 80);
      expect(p.createdAt, isNotNull);
      expect(p.updatedAt, isNotNull);
    });

    test('CustomerProfileUpdate.toJson emits all 12 write keys', () {
      final json = const CustomerProfileUpdate(
        avatarUrl: 'a',
        preferredLanguage: 'en',
        preferredCurrency: 'VND',
        preferredPaymentMethod: 'VNPay',
        nationality: 'VN',
        passportNumber: 'A1234567',
        emergencyContactName: 'Mai',
        emergencyContactPhone: '090',
        accessibilityNeeds: 'None',
        travelStyle: 'Explorer',
        dietaryPreference: 'Vegetarian',
        marketingConsent: true,
      ).toJson();
      expect(
        json.keys.toSet(),
        {
          'avatarUrl',
          'preferredLanguage',
          'preferredCurrency',
          'preferredPaymentMethod',
          'nationality',
          'passportNumber',
          'emergencyContactName',
          'emergencyContactPhone',
          'accessibilityNeeds',
          'travelStyle',
          'dietaryPreference',
          'marketingConsent',
        },
      );
      expect(json['passportNumber'], 'A1234567');
      expect(json['marketingConsent'], true);
    });

    test('toJson emits null (not omit) for cleared string fields', () {
      final json =
          const CustomerProfileUpdate(marketingConsent: false).toJson();
      expect(json.containsKey('passportNumber'), isTrue);
      expect(json['passportNumber'], isNull);
      expect(json['avatarUrl'], isNull);
    });

    test('non-object identity body → serverError (malformed)', () async {
      final app = realApp(MockClient((_) async => http.Response('null', 200)));
      expect(await app.loadRealAccountIdentity(),
          CustomerProfileOutcome.serverError);
    });
  });

  // ── Demo Mode (zero HTTP) ────────────────────────────────────────────────────

  group('Demo Mode', () {
    test('all profile methods return demoUnavailable with zero HTTP', () async {
      var calls = 0;
      final app = demoApp(MockClient((_) async {
        calls++;
        return jsonResponse(const <String, dynamic>{}, 200);
      }));
      expect(await app.loadRealAccountIdentity(),
          CustomerProfileOutcome.demoUnavailable);
      expect(await app.loadRealCustomerProfile(),
          CustomerProfileOutcome.demoUnavailable);
      expect(await app.updateRealCustomerProfile(const CustomerProfileUpdate()),
          CustomerProfileOutcome.demoUnavailable);
      expect(calls, 0);
      expect(app.realIdentity, isNull);
      expect(app.realProfile, isNull);
    });
  });

  // ── Load and update ──────────────────────────────────────────────────────────

  group('Load and update', () {
    test('identity + profile stored; a cached re-read makes no HTTP call',
        () async {
      var gets = 0;
      final app = routedApp(
        onRequest: (r) {
          if (r.method == 'GET') gets++;
        },
      );
      await app.loadRealAccountIdentity();
      await app.loadRealCustomerProfile();
      expect(app.realIdentityLoaded, isTrue);
      expect(app.realProfileLoaded, isTrue);
      final afterFirst = gets;
      // Cached — no refresh → no new HTTP.
      await app.loadRealAccountIdentity();
      await app.loadRealCustomerProfile();
      expect(gets, afterFirst);
    });

    test('refresh re-fetches the profile', () async {
      var profileGets = 0;
      final app = routedApp(
        onRequest: (r) {
          if (profileGet(r)) profileGets++;
        },
      );
      await app.loadRealCustomerProfile();
      expect(profileGets, 1);
      await app.loadRealCustomerProfile(refresh: true);
      expect(profileGets, 2);
    });

    test('update PUTs /me/profile with the full body and stores the response',
        () async {
      Map<String, dynamic>? sentBody;
      final app = routedApp(
        onUpdate: (r) async {
          sentBody = jsonDecode(r.body) as Map<String, dynamic>;
          return jsonResponse(
              profileJson(
                  completionPercentage: 100, dietaryPreference: 'Vegan'),
              200);
        },
      );
      await app.loadRealCustomerProfile();
      final outcome = await app.updateRealCustomerProfile(
        const CustomerProfileUpdate(
          preferredLanguage: 'vi',
          passportNumber: 'A1234567',
          marketingConsent: false,
        ),
      );
      expect(outcome, CustomerProfileOutcome.success);
      // Full-replace: passportNumber key is always present in the request body.
      expect(sentBody!.containsKey('passportNumber'), isTrue);
      expect(sentBody!['passportNumber'], 'A1234567');
      expect(sentBody!['preferredLanguage'], 'vi');
      // Stored record is the server response (no optimistic mutation).
      expect(app.realProfile!.completionPercentage, 100);
      expect(app.realProfile!.dietaryPreference, 'Vegan');
    });

    test('a second concurrent save returns busy', () async {
      final gate = Completer<http.Response>();
      final app = routedApp(onUpdate: (_) => gate.future);
      await app.loadRealCustomerProfile();
      final first =
          app.updateRealCustomerProfile(const CustomerProfileUpdate());
      final second =
          await app.updateRealCustomerProfile(const CustomerProfileUpdate());
      expect(second, CustomerProfileOutcome.busy);
      gate.complete(jsonResponse(profileJson(), 200));
      expect(await first, CustomerProfileOutcome.success);
    });
  });

  // ── Errors ───────────────────────────────────────────────────────────────────

  group('Errors', () {
    test('401 → sessionExpired, no auto-logout / no demo switch', () async {
      final app = routedApp(
        onProfile: (_) async =>
            jsonResponse(errorBody(401, 'x', '/api/me/profile'), 401),
      );
      app.email = 'bao@example.com';
      app.api.token = 'jwt-token';
      expect(await app.loadRealCustomerProfile(),
          CustomerProfileOutcome.sessionExpired);
      expect(app.email, 'bao@example.com');
      expect(app.api.token, 'jwt-token');
      expect(app.demoMode, isFalse);
    });

    test('404 → notFound; 500 → serverError; network', () async {
      final nf = routedApp(
        onProfile: (_) async =>
            jsonResponse(errorBody(404, 'x', '/api/me/profile'), 404),
      );
      expect(
          await nf.loadRealCustomerProfile(), CustomerProfileOutcome.notFound);

      final se = routedApp(
        onProfile: (_) async =>
            jsonResponse(errorBody(500, 'x', '/api/me/profile'), 500),
      );
      expect(await se.loadRealCustomerProfile(),
          CustomerProfileOutcome.serverError);

      final net = realApp(MockClient((_) async {
        throw http.ClientException('offline');
      }));
      expect(
          await net.loadRealCustomerProfile(), CustomerProfileOutcome.network);
    });

    test('a failed load preserves the previously loaded profile', () async {
      var fail = false;
      final app = routedApp(
        onProfile: (_) async => fail
            ? jsonResponse(errorBody(500, 'x', '/api/me/profile'), 500)
            : jsonResponse(profileJson(), 200),
      );
      await app.loadRealCustomerProfile();
      expect(app.realProfile, isNotNull);
      fail = true;
      expect(await app.loadRealCustomerProfile(refresh: true),
          CustomerProfileOutcome.serverError);
      expect(app.realProfile, isNotNull);
    });
  });

  // ── Session isolation ────────────────────────────────────────────────────────

  group('Session isolation', () {
    test('logout clears identity and profile state', () async {
      final app = routedApp();
      await app.loadRealAccountIdentity();
      await app.loadRealCustomerProfile();
      expect(app.realIdentity, isNotNull);
      expect(app.realProfile, isNotNull);
      await app.logout();
      expect(app.realIdentity, isNull);
      expect(app.realProfile, isNull);
      expect(app.realIdentityLoaded, isFalse);
      expect(app.realProfileLoaded, isFalse);
    });
  });

  // ── Widgets ──────────────────────────────────────────────────────────────────

  group('Widgets', () {
    testWidgets('renders the edit form and shows the passport warning',
        (t) async {
      final app = routedApp();
      await pumpSize(
        t,
        testApp(child: const RealCustomerProfileScreen(), app: app),
        const Size(1200, 2600),
      );
      expect(find.byKey(const Key('customer-profile-content')), findsOneWidget);
      expect(
          find.byKey(const Key('customer-profile-passport')), findsOneWidget);
      expect(find.byKey(const Key('customer-profile-save')), findsOneWidget);
      // Warning surfaces the current masked passport (never the raw number).
      expect(find.textContaining('••••1234'), findsOneWidget);
    });

    testWidgets('save PUTs and shows the saved snackbar', (t) async {
      var putCalled = false;
      final app = routedApp(
        onUpdate: (_) async {
          putCalled = true;
          return jsonResponse(profileJson(completionPercentage: 90), 200);
        },
      );
      await pumpSize(
        t,
        testApp(child: const RealCustomerProfileScreen(), app: app),
        const Size(1200, 2600),
      );
      await t.ensureVisible(find.byKey(const Key('customer-profile-save')));
      await t.tap(find.byKey(const Key('customer-profile-save')));
      await t.pumpAndSettle();
      expect(putCalled, isTrue);
      expect(app.realProfile!.completionPercentage, 90);
      final l10n = AppLocalizationsEn();
      expect(find.text(l10n.profileEditSavedMessage), findsOneWidget);
    });

    testWidgets('a 401 shows the inline session-expired state', (t) async {
      final app = routedApp(
        onProfile: (_) async =>
            jsonResponse(errorBody(401, 'x', '/api/me/profile'), 401),
      );
      await pumpSize(
        t,
        testApp(child: const RealCustomerProfileScreen(), app: app),
        const Size(1200, 2600),
      );
      expect(find.byKey(const Key('customer-profile-session-expired')),
          findsOneWidget);
    });

    testWidgets('a 500 shows the recoverable error state', (t) async {
      final app = routedApp(
        onProfile: (_) async =>
            jsonResponse(errorBody(500, 'x', '/api/me/profile'), 500),
      );
      await pumpSize(
        t,
        testApp(child: const RealCustomerProfileScreen(), app: app),
        const Size(1200, 2600),
      );
      expect(find.byKey(const Key('customer-profile-error')), findsOneWidget);
    });

    testWidgets('profile screen real header shows the backend full name',
        (t) async {
      final app = routedApp();
      app.email = 'bao@example.com';
      await pumpSize(
        t,
        testApp(child: const Scaffold(body: ProfileScreen()), app: app),
        const Size(1200, 2600),
      );
      expect(find.text('Tran Thien Bao'), findsOneWidget);
      expect(find.byKey(const Key('profile-edit')), findsOneWidget);
    });

    testWidgets('profile-edit card is absent in Demo Mode', (t) async {
      final app = demoApp(MockClient((_) async {
        return jsonResponse(const <String, dynamic>{}, 200);
      }));
      await pumpSize(
        t,
        testApp(child: const Scaffold(body: ProfileScreen()), app: app),
        const Size(1200, 2600),
      );
      expect(find.byKey(const Key('profile-edit')), findsNothing);
    });
  });

  // ── Localization parity ──────────────────────────────────────────────────────

  group('Localization parity', () {
    test('every new UI32 key is present in both EN and VI', () {
      final en = AppLocalizationsEn();
      final vi = AppLocalizationsVi();
      final enValues = <String>[
        en.profileEditTitle,
        en.profileEditLoadingMessage,
        en.profileEditErrorMessage,
        en.profileEditMissingMessage,
        en.profileEditSaveAction,
        en.profileEditSavedMessage,
        en.profileEditSaveErrorMessage,
        en.profileEditForbiddenMessage,
        en.profileEditNetworkMessage,
        en.profileEditIdentitySection,
        en.profileEditPreferencesSection,
        en.profileEditContactSection,
        en.profileFieldAvatar,
        en.profileFieldLanguage,
        en.profileFieldCurrency,
        en.profileFieldPaymentMethod,
        en.profileFieldNationality,
        en.profileFieldEmergencyName,
        en.profileFieldEmergencyPhone,
        en.profileFieldAccessibility,
        en.profileFieldDietaryPreference,
        en.profileFieldTravelStyle,
        en.profileEditPassportLabel,
        en.profileEditPassportHint,
        en.profileEditMarketingLabel,
        en.profileEditOptionalHint,
        en.profileEditEmptyPreferences,
      ];
      final viValues = <String>[
        vi.profileEditTitle,
        vi.profileEditLoadingMessage,
        vi.profileEditErrorMessage,
        vi.profileEditMissingMessage,
        vi.profileEditSaveAction,
        vi.profileEditSavedMessage,
        vi.profileEditSaveErrorMessage,
        vi.profileEditForbiddenMessage,
        vi.profileEditNetworkMessage,
        vi.profileEditIdentitySection,
        vi.profileEditPreferencesSection,
        vi.profileEditContactSection,
        vi.profileFieldAvatar,
        vi.profileFieldLanguage,
        vi.profileFieldCurrency,
        vi.profileFieldPaymentMethod,
        vi.profileFieldNationality,
        vi.profileFieldEmergencyName,
        vi.profileFieldEmergencyPhone,
        vi.profileFieldAccessibility,
        vi.profileFieldDietaryPreference,
        vi.profileFieldTravelStyle,
        vi.profileEditPassportLabel,
        vi.profileEditPassportHint,
        vi.profileEditMarketingLabel,
        vi.profileEditOptionalHint,
        vi.profileEditEmptyPreferences,
      ];
      for (final v in enValues) {
        expect(v.trim(), isNotEmpty);
      }
      for (final v in viValues) {
        expect(v.trim(), isNotEmpty);
      }
      expect(en.profileEditTitle, isNot(vi.profileEditTitle));
    });

    test('parameterized keys resolve in both locales', () {
      final en = AppLocalizationsEn();
      final vi = AppLocalizationsVi();
      expect(en.profileEditPassportWarning('••••9'), contains('••••9'));
      expect(vi.profileEditPassportWarning('••••9'), contains('••••9'));
      expect(en.profileCompletionSemantic(80), contains('80'));
      expect(vi.profileCompletionSemantic(80), contains('80'));
      expect(en.profileRoleSemantic('CUSTOMER'), contains('CUSTOMER'));
      expect(vi.profileRoleSemantic('CUSTOMER'), contains('CUSTOMER'));
    });
  });
}
