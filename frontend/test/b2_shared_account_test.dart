import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:planyourtrip_frontend/app/app_surface.dart';
import 'package:planyourtrip_frontend/app/routing/admin_router.dart';
import 'package:planyourtrip_frontend/app/routing/surface_router.dart';
import 'package:planyourtrip_frontend/app/routing/user_router.dart';
import 'package:planyourtrip_frontend/app/surface_app.dart';
import 'package:planyourtrip_frontend/core/app_role.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/auth/auth_error.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/core/partner/partner_state.dart';
import 'package:planyourtrip_frontend/features/auth/login_screen.dart';

/// Phase B — the account UX shared by the three surfaces: password recovery,
/// password change, the account area, and the Partner business profile.
///
/// The rules being pinned:
///
///  * a refused sign-in is explained from the backend's `code`, never by parsing
///    prose, and never reveals whether an address exists;
///  * password recovery answers the same way for every address;
///  * changing a password adopts the fresh token the backend returns, so the
///    session that changed it survives while the others end;
///  * the account area shows only what `GET /api/me` actually returns;
///  * submitting a business profile claims nothing about approval.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late List<_Call> calls;
  setUp(() => calls = <_Call>[]);

  http.Client backend(Map<String, http.Response Function(http.Request)> routes) =>
      MockClient((request) async {
        calls.add(_Call(request.method, request.url.path, request.body));
        for (final entry in routes.entries) {
          if (request.url.path.endsWith(entry.key)) return entry.value(request);
        }
        return _json({'status': 404, 'message': 'Not found'}, 404);
      });

  AppState session({
    required http.Client client,
    String? email,
    AppRole role = AppRole.partner,
    String token = 'session-token',
  }) {
    final app = AppState(api: ApiClient(client: client))..demoMode = false;
    if (email != null) {
      app
        ..email = email
        ..role = role;
      app.api.token = token;
    }
    return app;
  }

  Future<void> pumpSurface(
    WidgetTester tester, {
    required AppSurface surface,
    required AppState app,
    String location = SurfaceRouter.root,
    Size size = const Size(1200, 1800),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Widget child = SurfaceApp(surface: surface, initialLocation: location);
    if (surface == AppSurface.partner) {
      child = PartnerScope(
        notifier: PartnerState(api: app.api)..bindSession(app),
        child: child,
      );
    }
    await tester.pumpWidget(AppScope(notifier: app, child: child));
    await _settle(tester);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 1. Sign-in refusals are explained from the code
  // ══════════════════════════════════════════════════════════════════════════

  group('Sign-in refusals', () {
    /// Each case gets a fresh tree: pumping the same widget shape again reuses
    /// the element tree, which would keep the previous SnackBar on screen.
    Future<String> refusalText(
      WidgetTester tester, {
      required String code,
      required int status,
    }) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      final app = session(
        client: backend({
          '/auth/login': (_) => _json({
                'status': status,
                'code': code,
                'message': 'server prose that must not be shown verbatim',
              }, status),
        }),
      );
      await pumpSurface(tester, surface: AppSurface.partner, app: app);
      await tester.enterText(
          find.byKey(const Key('login-email-field')), 'someone@example.com');
      await tester.enterText(
          find.byKey(const Key('login-password-field')), 'Valid-Pass-123');
      await tester.tap(find.byKey(const Key('login-submit')));
      await _settle(tester);
      final snack = tester.widget<Text>(
        find.descendant(of: find.byType(SnackBar), matching: find.byType(Text)),
      );
      return snack.data ?? '';
    }

    testWidgets('each code maps to its own localized message', (tester) async {
      expect(
        await refusalText(tester, code: 'INVALID_CREDENTIALS', status: 401),
        'Email or password is incorrect.',
      );
      expect(
        await refusalText(tester, code: 'ACCOUNT_DISABLED', status: 403),
        'This account is disabled. Contact support to restore access.',
      );
      expect(
        await refusalText(tester, code: 'ACCOUNT_UNAVAILABLE', status: 403),
        'This account cannot sign in. Contact support.',
      );
    });

    testWidgets('a refusal with no code still says something safe',
        (tester) async {
      final text = await refusalText(tester, code: 'SOMETHING_NEW', status: 401);
      expect(text, 'Email or password is incorrect.',
          reason: 'an unknown code falls back to the status, not to prose');
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 2. Password recovery
  // ══════════════════════════════════════════════════════════════════════════

  group('Password recovery', () {
    testWidgets('forgot-password answers generically and never reveals accounts',
        (tester) async {
      final app = session(
        client: backend({
          '/auth/forgot-password': (_) => _json({'message': 'ack'}, 202),
        }),
      );
      await pumpSurface(
        tester,
        surface: AppSurface.partner,
        app: app,
        location: SurfaceRouter.forgotPassword,
      );

      await tester.enterText(
          find.byKey(const Key('forgot-email-field')), 'nobody@example.com');
      await tester.tap(find.byKey(const Key('forgot-submit')));
      await _settle(tester);

      expect(find.byKey(const Key('forgot-ack')), findsOneWidget);
      expect(find.byKey(const Key('forgot-delivery-notice')), findsOneWidget,
          reason: 'local development does not deliver email, and says so');
      expect(jsonDecode(calls.single.body)['email'], 'nobody@example.com');
    });

    testWidgets('no email delivery is reported honestly', (tester) async {
      final app = session(
        client: backend({
          '/auth/forgot-password': (_) => _json({
                'status': 503,
                'code': 'EMAIL_DELIVERY_UNAVAILABLE',
                'message': 'unavailable',
              }, 503),
        }),
      );
      await pumpSurface(
        tester,
        surface: AppSurface.partner,
        app: app,
        location: SurfaceRouter.forgotPassword,
      );

      await tester.enterText(
          find.byKey(const Key('forgot-email-field')), 'pat@example.com');
      await tester.tap(find.byKey(const Key('forgot-submit')));
      await _settle(tester);

      expect(find.byKey(const Key('forgot-ack')), findsNothing);
      expect(
        find.text('Email delivery is unavailable right now. Please try again later.'),
        findsOneWidget,
      );
    });

    testWidgets('a reset sets the password and sends only token and password',
        (tester) async {
      final app = session(
        client: backend({
          '/auth/reset-password': (_) => _json({'message': 'done'}, 200),
        }),
      );
      await pumpSurface(
        tester,
        surface: AppSurface.partner,
        app: app,
        location: SurfaceRouter.resetPassword,
      );

      await tester.enterText(
          find.byKey(const Key('reset-password-token')), 'reset-token');
      await tester.enterText(
          find.byKey(const Key('reset-password-new')), 'Brand-New-Pass-1');
      await tester.enterText(
          find.byKey(const Key('reset-password-confirm')), 'Brand-New-Pass-1');
      await tester.tap(find.byKey(const Key('reset-password-submit')));
      await _settle(tester);

      expect(find.text('Password reset'), findsOneWidget);
      expect(find.byKey(const Key('reset-password-continue')), findsOneWidget);
      final body = jsonDecode(calls.single.body) as Map<String, dynamic>;
      expect(body.keys.toSet(), {'token', 'newPassword'});
    });

    testWidgets('an expired reset link is explained and nothing is claimed',
        (tester) async {
      final app = session(
        client: backend({
          '/auth/reset-password': (_) => _json({
                'status': 400,
                'code': 'TOKEN_EXPIRED',
                'message': 'This link has expired',
              }, 400),
        }),
      );
      await pumpSurface(
        tester,
        surface: AppSurface.partner,
        app: app,
        location: SurfaceRouter.resetPassword,
      );

      await tester.enterText(
          find.byKey(const Key('reset-password-token')), 'old-token');
      await tester.enterText(
          find.byKey(const Key('reset-password-new')), 'Brand-New-Pass-1');
      await tester.enterText(
          find.byKey(const Key('reset-password-confirm')), 'Brand-New-Pass-1');
      await tester.tap(find.byKey(const Key('reset-password-submit')));
      await _settle(tester);

      expect(find.text('This link has expired. Request a new one.'),
          findsOneWidget);
      expect(find.text('Password reset'), findsNothing);
    });

    testWidgets('client rules keep an invalid reset off the wire',
        (tester) async {
      final app = session(client: backend(const {}));
      await pumpSurface(
        tester,
        surface: AppSurface.partner,
        app: app,
        location: SurfaceRouter.resetPassword,
      );

      await tester.tap(find.byKey(const Key('reset-password-submit')));
      await _settle(tester);
      expect(calls, isEmpty);
      expect(find.text('Paste the token from your link.'), findsOneWidget);

      await tester.enterText(
          find.byKey(const Key('reset-password-token')), 'reset-token');
      await tester.enterText(
          find.byKey(const Key('reset-password-new')), 'Brand-New-Pass-1');
      await tester.enterText(
          find.byKey(const Key('reset-password-confirm')), 'Different-Pass-2');
      await tester.tap(find.byKey(const Key('reset-password-submit')));
      await _settle(tester);
      expect(calls, isEmpty);
      expect(find.text('Passwords do not match.'), findsOneWidget);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 3. The account area and password change
  // ══════════════════════════════════════════════════════════════════════════

  group('Account area', () {
    Map<String, http.Response Function(http.Request)> accountRoutes({
      Map<String, Object?>? identity,
      http.Response Function(http.Request)? password,
    }) =>
        {
          '/me/password': password ??
              (_) => _json({
                    'token': 'fresh-token',
                    'user': {
                      'id': 7,
                      'fullName': 'Ada Admin',
                      'email': 'ada@example.com',
                      'role': 'ADMIN',
                    },
                  }, 200),
          '/me': (_) => _json(
                identity ??
                    {
                      'id': 7,
                      'fullName': 'Ada Admin',
                      'email': 'ada@example.com',
                      'role': 'ADMIN',
                    },
                200,
              ),
        };

    testWidgets('shows what the backend returns, and nothing security-internal',
        (tester) async {
      final app = session(
        client: backend(accountRoutes()),
        email: 'ada@example.com',
        role: AppRole.admin,
      );
      await pumpSurface(
        tester,
        surface: AppSurface.admin,
        app: app,
        location: SurfaceRouter.account,
      );

      expect(find.text('Ada Admin'), findsOneWidget);
      expect(find.text('ada@example.com'), findsWidgets);
      expect(find.text('Administrator'), findsOneWidget);
      expect(find.textContaining('session-token'), findsNothing);
      expect(find.textContaining('Bearer'), findsNothing);
      expect(find.byKey(const Key('account-change-password')), findsOneWidget);
    });

    testWidgets('a failed read offers a retry rather than an empty page',
        (tester) async {
      final app = session(
        client: backend({
          '/me': (_) => _json({'status': 500, 'message': 'boom'}, 500),
        }),
        email: 'ada@example.com',
        role: AppRole.admin,
      );
      await pumpSurface(
        tester,
        surface: AppSurface.admin,
        app: app,
        location: SurfaceRouter.account,
      );

      expect(find.byKey(const Key('account-error')), findsOneWidget);
      expect(find.byKey(const Key('account-retry')), findsOneWidget);
    });

    testWidgets('changing the password adopts the fresh token', (tester) async {
      final app = session(
        client: backend(accountRoutes()),
        email: 'ada@example.com',
        role: AppRole.admin,
        token: 'old-token',
      );
      await pumpSurface(
        tester,
        surface: AppSurface.admin,
        app: app,
        location: SurfaceRouter.account,
      );

      await tester.tap(find.byKey(const Key('account-change-password')));
      await _settle(tester);

      await tester.enterText(
          find.byKey(const Key('change-password-current')), 'Old-Pass-123');
      await tester.enterText(
          find.byKey(const Key('change-password-new')), 'New-Pass-456');
      await tester.enterText(
          find.byKey(const Key('change-password-confirm')), 'New-Pass-456');
      await tester.tap(find.byKey(const Key('change-password-submit')));
      await _settle(tester);

      expect(find.byKey(const Key('change-password-success')), findsOneWidget);
      expect(app.api.token, 'fresh-token',
          reason: 'the session that made the change keeps working');

      final change = calls.firstWhere((c) => c.path.endsWith('/me/password'));
      expect(change.method, 'PUT');
      final body = jsonDecode(change.body) as Map<String, dynamic>;
      expect(body.keys.toSet(), {'currentPassword', 'newPassword'},
          reason: 'identity comes from the session, never from the body');
    });

    testWidgets('a wrong current password is reported on its own field',
        (tester) async {
      final app = session(
        client: backend(accountRoutes(
          password: (_) => _json({
            'status': 400,
            'code': 'CURRENT_PASSWORD_INCORRECT',
            'message': 'currentPassword: is incorrect',
            'fieldErrors': [
              {'field': 'currentPassword', 'message': 'is incorrect'},
            ],
          }, 400),
        )),
        email: 'ada@example.com',
        role: AppRole.admin,
        token: 'old-token',
      );
      await pumpSurface(
        tester,
        surface: AppSurface.admin,
        app: app,
        location: SurfaceRouter.account,
      );

      await tester.tap(find.byKey(const Key('account-change-password')));
      await _settle(tester);
      await tester.enterText(
          find.byKey(const Key('change-password-current')), 'Wrong-Pass-1');
      await tester.enterText(
          find.byKey(const Key('change-password-new')), 'New-Pass-456');
      await tester.enterText(
          find.byKey(const Key('change-password-confirm')), 'New-Pass-456');
      await tester.tap(find.byKey(const Key('change-password-submit')));
      await _settle(tester);

      expect(find.text('is incorrect'), findsOneWidget);
      expect(find.text('Your current password is incorrect.'), findsOneWidget);
      expect(app.api.token, 'old-token', reason: 'nothing changed');
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 4. The Partner business profile
  // ══════════════════════════════════════════════════════════════════════════

  group('Partner business profile', () {
    Map<String, Object?> profile({
      String status = 'DRAFT',
      String? rejectReason,
    }) =>
        {
          'id': 3,
          'userId': 9,
          'businessName': 'KAS Hotel Saigon',
          'businessType': 'HOTEL',
          'representativeName': 'Pat Partner',
          'phone': '0909123456',
          'email': 'contact@kas.example',
          'address': '1 Le Loi',
          'verificationStatus': status,
          if (rejectReason != null) 'rejectReason': rejectReason,
        };

    Future<void> pumpAccount(
      WidgetTester tester,
      Map<String, http.Response Function(http.Request)> routes,
    ) async {
      // A fresh tree per case: reusing the element tree would keep the previous
      // account screen's state, and with it the profile it already loaded.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      final app = session(
        client: backend({
          '/me': (_) => _json({
                'id': 9,
                'fullName': 'Pat Partner',
                'email': 'pat@example.com',
                'role': 'PARTNER',
              }, 200),
          ...routes,
        }),
        email: 'pat@example.com',
      );
      await pumpSurface(
        tester,
        surface: AppSurface.partner,
        app: app,
        location: SurfaceRouter.account,
      );
    }

    testWidgets('an account with no profile is invited to add one',
        (tester) async {
      await pumpAccount(tester, {
        '/partner/profile': (_) =>
            _json({'status': 404, 'message': 'Partner profile not found'}, 404),
      });

      expect(find.byKey(const Key('business-profile-missing')), findsOneWidget);
      expect(find.byKey(const Key('business-profile-add')), findsOneWidget);
    });

    testWidgets('a draft can be edited and saved with the backend field names',
        (tester) async {
      await pumpAccount(tester, {
        '/partner/profile': (request) =>
            _json(profile(), request.method == 'POST' ? 200 : 200),
      });

      expect(find.byKey(const Key('business-profile-status')), findsOneWidget);
      expect(find.text('Draft'), findsWidgets);

      await tester.tap(find.byKey(const Key('business-profile-edit')));
      await _settle(tester);

      await tester.enterText(
          find.byKey(const Key('business-name')), 'KAS Hotel Saigon');
      await tester.ensureVisible(find.byKey(const Key('business-profile-save')));
      await tester.tap(find.byKey(const Key('business-profile-save')));
      await _settle(tester);

      final save = calls.lastWhere((c) => c.method == 'POST');
      final body = jsonDecode(save.body) as Map<String, dynamic>;
      expect(body['businessName'], 'KAS Hotel Saigon');
      expect(body['businessType'], 'HOTEL');
      expect(
        body.keys.toSet().difference({
          'businessName',
          'businessType',
          'representativeName',
          'phone',
          'email',
          'address',
          'taxCode',
          'website',
        }),
        isEmpty,
        reason: 'only fields PartnerProfileRequest declares',
      );
    });

    testWidgets('submitting hands the profile to review and claims no approval',
        (tester) async {
      await pumpAccount(tester, {
        '/partner/profile/submit': (_) => _json({
              'id': 3,
              'verificationStatus': 'SUBMITTED',
              'submittedAt': '2026-09-20T02:00:00Z',
              'message': 'Partner profile submitted for review',
            }, 200),
        '/partner/profile': (_) => _json(profile(), 200),
      });

      await tester.tap(find.byKey(const Key('business-profile-edit')));
      await _settle(tester);
      await tester
          .ensureVisible(find.byKey(const Key('business-profile-submit')));
      await tester.tap(find.byKey(const Key('business-profile-submit')));
      await _settle(tester);

      expect(calls.any((c) => c.path.endsWith('/partner/profile/submit')), isTrue);
      expect(find.text('Approved'), findsNothing,
          reason: 'submitting is not approval');
    });

    testWidgets('a rejected profile shows its reason and can be edited again',
        (tester) async {
      await pumpAccount(tester, {
        '/partner/profile': (_) => _json(
            profile(status: 'REJECTED', rejectReason: 'Tax code unreadable'), 200),
      });

      expect(find.byKey(const Key('business-profile-reject-reason')),
          findsOneWidget);
      expect(find.textContaining('Tax code unreadable'), findsOneWidget);
      expect(find.byKey(const Key('business-profile-edit')), findsOneWidget);
    });

    testWidgets('an approved or suspended profile is read-only here',
        (tester) async {
      await pumpAccount(tester, {
        '/partner/profile': (_) => _json(profile(status: 'APPROVED'), 200),
      });
      expect(find.byKey(const Key('business-profile-read-only')), findsOneWidget);
      expect(find.byKey(const Key('business-profile-edit')), findsNothing);

      await pumpAccount(tester, {
        '/partner/profile': (_) => _json(profile(status: 'SUSPENDED'), 200),
      });
      expect(find.byKey(const Key('business-profile-read-only')), findsOneWidget);
      expect(
        find.text('Your Partner access is currently suspended. Contact support.'),
        findsOneWidget,
      );
    });

    testWidgets('a failed read offers a retry', (tester) async {
      await pumpAccount(tester, {
        '/partner/profile': (_) => _json({'status': 500}, 500),
      });
      expect(find.byKey(const Key('business-profile-load-error')), findsOneWidget);
      expect(find.byKey(const Key('business-profile-retry')), findsOneWidget);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 5. Surfaces keep their own account rules
  // ══════════════════════════════════════════════════════════════════════════

  group('Surface account rules', () {
    test('Admin serves password recovery but never registration', () {
      const router = AdminSurfaceRouter();
      expect(router.publicLocations, {
        SurfaceRouter.forgotPassword,
        SurfaceRouter.resetPassword,
      });
      expect(router.publicScreenAt(SurfaceRouter.register), isNull);
      expect(router.resolve(SurfaceRouter.register), SurfaceRouter.root,
          reason: 'an Admin account is provisioned, never self-created');
    });

    test('the traveller app serves recovery and keeps its own sign-up flow', () {
      const router = UserSurfaceRouter();
      expect(router.publicLocations, {
        SurfaceRouter.forgotPassword,
        SurfaceRouter.resetPassword,
      });
      expect(router.resolve(SurfaceRouter.register), SurfaceRouter.root);
      expect(router.resolve('/trips'), '/trips', reason: 'tabs are untouched');
    });

    testWidgets('Admin sign-in offers neither Demo Mode nor any sign-up',
        (tester) async {
      await pumpSurface(
        tester,
        surface: AppSurface.admin,
        app: session(client: backend(const {})),
      );

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byKey(const Key('login-demo')), findsNothing);
      expect(find.byKey(const Key('login-become-partner')), findsNothing);
      expect(find.text('Create account'), findsNothing);
      expect(find.byKey(const Key('login-forgot-password')), findsOneWidget);
    });

    testWidgets('the traveller app still offers Demo Mode and sign-up',
        (tester) async {
      // Onboarding loads network images, which cannot resolve in a test.
      final original = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exception is NetworkImageLoadException) return;
        original?.call(details);
      };
      addTearDown(() => FlutterError.onError = original);
      await pumpSurface(
        tester,
        surface: AppSurface.user,
        app: session(client: backend(const {})),
      );

      // The traveller surface opens on onboarding; the sign-in behind it keeps
      // both actions, which Phase B does not touch.
      const router = UserSurfaceRouter();
      expect(router.publicScreenAt(SurfaceRouter.forgotPassword), isNotNull);
      expect(AppSurface.user.offersDemoMode, isTrue);
      expect(AppSurface.user.offersSelfRegistration, isTrue);
      expect(AppSurface.partner.offersDemoMode, isFalse);
      expect(AppSurface.admin.offersSelfRegistration, isFalse);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 6. The error contract itself
  // ══════════════════════════════════════════════════════════════════════════

  group('AuthFailure', () {
    test('reads the backend code, message and field errors', () {
      final failure = AuthFailure.fromResponse(400, {
        'code': 'VALIDATION_FAILED',
        'message': 'password: is required',
        'fieldErrors': [
          {'field': 'password', 'message': 'is required'},
        ],
      });
      expect(failure.code, AuthErrorCode.validationFailed);
      expect(failure.fieldError('password')?.message, 'is required');
      expect(failure.fieldError('email'), isNull);
    });

    test('an unknown code falls back to the status, never to a guess', () {
      expect(
        AuthFailure.fromResponse(401, {'code': 'BRAND_NEW'}).code,
        AuthErrorCode.unauthorized,
      );
      expect(
        AuthFailure.fromResponse(403, null).code,
        AuthErrorCode.forbidden,
      );
      expect(
        AuthFailure.fromResponse(500, {'message': 'boom'}).code,
        AuthErrorCode.server,
      );
    });
  });
}

class _Call {
  final String method;
  final String path;
  final String body;

  _Call(this.method, this.path, this.body);
}

http.Response _json(Object body, int status) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
}
