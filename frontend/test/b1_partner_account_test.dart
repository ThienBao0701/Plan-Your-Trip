import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:planyourtrip_frontend/app/app_surface.dart';
import 'package:planyourtrip_frontend/app/routing/invitation_link.dart';
import 'package:planyourtrip_frontend/app/routing/partner_router.dart';
import 'package:planyourtrip_frontend/app/routing/surface_router.dart';
import 'package:planyourtrip_frontend/app/surface_app.dart';
import 'package:planyourtrip_frontend/core/app_role.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/core/partner/partner_state.dart';
import 'package:planyourtrip_frontend/features/auth/login_screen.dart';
import 'package:planyourtrip_frontend/features/auth/partner_register_screen.dart';
import 'package:planyourtrip_frontend/features/auth/verify_email_screen.dart';

/// Phase B — the Partner account experience against the Phase A contracts.
///
/// Every backend answer here is the shape Phase A actually returns: `201` with
/// `status: PENDING_VERIFICATION` and **no token** for registration, `{status}`
/// for verification, a generic `202` for resend, and errors carrying a stable
/// `code` plus `fieldErrors`. No mock invents a field the backend does not send.
///
/// What is pinned: a Partner can register, is never signed in by registering,
/// reaches verification, and can complete and submit a business profile — and
/// the client never claims an email was delivered or an application approved.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late List<_Call> calls;
  setUp(() => calls = <_Call>[]);

  /// A backend that answers each path from [routes]; anything else is 404.
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
  }) {
    final app = AppState(api: ApiClient(client: client))..demoMode = false;
    if (email != null) {
      app
        ..email = email
        ..role = role;
      app.api.token = 'partner-test-token';
    }
    return app;
  }

  Future<void> pumpPartner(
    WidgetTester tester, {
    required AppState app,
    String location = SurfaceRouter.root,
    Size size = const Size(1200, 1600),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      AppScope(
        notifier: app,
        child: PartnerScope(
          notifier: PartnerState(api: app.api)..bindSession(app),
          child: SurfaceApp(
            surface: AppSurface.partner,
            initialLocation: location,
          ),
        ),
      ),
    );
    await _settle(tester);
  }

  Future<void> fillRegistration(
    WidgetTester tester, {
    String name = 'Pat Partner',
    String email = 'pat@example.com',
    String password = 'Valid-Pass-123',
    String? confirm,
    bool acceptTerms = true,
  }) async {
    await tester.enterText(find.byKey(const Key('partner-register-name')), name);
    await tester.enterText(find.byKey(const Key('partner-register-email')), email);
    await tester.enterText(
        find.byKey(const Key('partner-register-password')), password);
    await tester.enterText(
        find.byKey(const Key('partner-register-confirm')), confirm ?? password);
    if (acceptTerms) {
      await tester.tap(find.byKey(const Key('partner-register-terms')));
      await tester.pump();
    }
  }

  Future<void> submitRegistration(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const Key('partner-register-submit')));
    await tester.tap(find.byKey(const Key('partner-register-submit')));
    await _settle(tester);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 1. Partner sign-in offers the Partner path, and only that
  // ══════════════════════════════════════════════════════════════════════════

  group('Partner sign-in', () {
    testWidgets('offers Become a Partner, and never Demo Mode or a User sign-up',
        (tester) async {
      await pumpPartner(tester, app: session(client: backend(const {})));

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byKey(const Key('login-become-partner')), findsOneWidget);
      expect(find.byKey(const Key('login-demo')), findsNothing);
      expect(find.byKey(const Key('login-forgot-password')), findsOneWidget);
      expect(find.text('Create account'), findsNothing);
      expect(calls, isEmpty, reason: 'nothing is requested before a sign-in');
    });

    testWidgets('Become a Partner opens registration at /register',
        (tester) async {
      await pumpPartner(tester, app: session(client: backend(const {})));

      await tester.tap(find.byKey(const Key('login-become-partner')));
      await _settle(tester);

      expect(find.byType(PartnerRegisterScreen), findsOneWidget);
    });

    testWidgets('an unverified sign-in is explained and offers verification',
        (tester) async {
      final app = session(
        client: backend({
          '/auth/login': (_) => _json({
                'timestamp': 'now',
                'status': 403,
                'error': 'Forbidden',
                'code': 'EMAIL_NOT_VERIFIED',
                'message': 'Verify your email address before signing in',
              }, 403),
        }),
      );
      await pumpPartner(tester, app: app);

      await tester.enterText(
          find.byKey(const Key('login-email-field')), 'pat@example.com');
      await tester.enterText(
          find.byKey(const Key('login-password-field')), 'Valid-Pass-123');
      await tester.tap(find.byKey(const Key('login-submit')));
      await _settle(tester);

      expect(find.text('Verify your email address before signing in.'),
          findsOneWidget,
          reason: 'the localized message, mapped from the code');
      expect(find.byKey(const Key('login-verify-email')), findsOneWidget);
      expect(app.email, isNull, reason: 'no session was created');
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 2. Registration
  // ══════════════════════════════════════════════════════════════════════════

  group('Partner registration', () {
    testWidgets('refuses to submit an incomplete or unaccepted form',
        (tester) async {
      await pumpPartner(
        tester,
        app: session(client: backend(const {})),
        location: SurfaceRouter.register,
      );

      await submitRegistration(tester);
      expect(calls, isEmpty, reason: 'an empty form is never sent');
      expect(find.text('Enter a valid email address.'), findsOneWidget);

      await fillRegistration(tester, acceptTerms: false);
      await submitRegistration(tester);
      expect(calls, isEmpty, reason: 'the terms must be accepted first');
      expect(find.text('Accept the Partner terms to continue.'), findsOneWidget);

      await fillRegistration(tester, confirm: 'Different-Pass-9');
      await submitRegistration(tester);
      expect(calls, isEmpty);
      expect(find.text('Passwords do not match.'), findsOneWidget);

      await fillRegistration(tester, password: 'short1', confirm: 'short1');
      await submitRegistration(tester);
      expect(calls, isEmpty);
      expect(find.text('Password must be at least 8 characters.'), findsOneWidget);
    });

    testWidgets('sends exactly the Phase A body and never a role',
        (tester) async {
      await pumpPartner(
        tester,
        app: session(
          client: backend({
            '/auth/partner/register': (_) => _json({
                  'email': 'pat@example.com',
                  'status': 'PENDING_VERIFICATION',
                  'verificationRequired': true,
                  'message': 'Check your email',
                }, 201),
          }),
        ),
        location: SurfaceRouter.register,
      );

      await fillRegistration(tester, name: '  Pat Partner  ');
      await submitRegistration(tester);

      final call = calls.single;
      expect(call.method, 'POST');
      expect(call.path, endsWith('/auth/partner/register'));
      final body = jsonDecode(call.body) as Map<String, dynamic>;
      expect(body.keys.toSet(),
          {'fullName', 'email', 'password', 'acceptTerms'});
      expect(body['fullName'], 'Pat Partner', reason: 'trimmed');
      expect(body['acceptTerms'], true);
      expect(body.containsKey('role'), isFalse);
    });

    testWidgets('a created account is not signed in and goes to verification',
        (tester) async {
      final app = session(
        client: backend({
          '/auth/partner/register': (_) => _json({
                'email': 'pat@example.com',
                'status': 'PENDING_VERIFICATION',
                'verificationRequired': true,
              }, 201),
        }),
      );
      await pumpPartner(tester, app: app, location: SurfaceRouter.register);

      await fillRegistration(tester);
      await submitRegistration(tester);

      expect(find.byType(VerifyEmailScreen), findsOneWidget);
      expect(find.text('Verify your email'), findsWidgets);
      expect(app.email, isNull, reason: 'registration returns no session');
      expect(app.api.token, isNull);
      expect(find.byKey(const Key('verify-email-delivery-notice')), findsOneWidget,
          reason: 'no delivery is claimed');
    });

    testWidgets('a duplicate address is reported, and the form keeps its values',
        (tester) async {
      await pumpPartner(
        tester,
        app: session(
          client: backend({
            '/auth/partner/register': (_) => _json({
                  'status': 409,
                  'code': 'EMAIL_ALREADY_REGISTERED',
                  'message': 'Email already registered',
                }, 409),
          }),
        ),
        location: SurfaceRouter.register,
      );

      await fillRegistration(tester);
      await submitRegistration(tester);

      expect(find.byType(PartnerRegisterScreen), findsOneWidget);
      expect(find.text('That email address already has an account.'),
          findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.descendant(
              of: find.byKey(const Key('partner-register-email')),
              matching: find.byType(TextField),
            ))
            .controller
            ?.text,
        'pat@example.com',
        reason: 'a refused submit never clears the form',
      );
    });

    testWidgets('server field errors mark their own fields', (tester) async {
      await pumpPartner(
        tester,
        app: session(
          client: backend({
            '/auth/partner/register': (_) => _json({
                  'status': 400,
                  'code': 'VALIDATION_FAILED',
                  'message': 'password: must be at most 72 bytes',
                  'fieldErrors': [
                    {'field': 'password', 'message': 'must be at most 72 bytes'},
                  ],
                }, 400),
          }),
        ),
        location: SurfaceRouter.register,
      );

      await fillRegistration(tester);
      await submitRegistration(tester);

      expect(find.text('must be at most 72 bytes'), findsOneWidget);
      expect(find.text('Please check the highlighted fields.'), findsOneWidget);
    });

    testWidgets('no email delivery is reported as such, not as success',
        (tester) async {
      final app = session(
        client: backend({
          '/auth/partner/register': (_) => _json({
                'status': 503,
                'code': 'EMAIL_DELIVERY_UNAVAILABLE',
                'message': 'Email delivery is not available right now.',
              }, 503),
        }),
      );
      await pumpPartner(tester, app: app, location: SurfaceRouter.register);

      await fillRegistration(tester);
      await submitRegistration(tester);

      expect(find.byType(PartnerRegisterScreen), findsOneWidget);
      expect(
        find.text('Email delivery is unavailable right now. Please try again later.'),
        findsOneWidget,
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 3. Verification
  // ══════════════════════════════════════════════════════════════════════════

  group('Email verification', () {
    Future<void> pumpVerify(
      WidgetTester tester, {
      required http.Client client,
      String? token,
      String? email = 'pat@example.com',
    }) async {
      final app = session(client: client);
      await tester.pumpWidget(
        AppScope(
          notifier: app,
          child: PartnerScope(
            notifier: PartnerState(api: app.api)..bindSession(app),
            child: const SurfaceApp(
              surface: AppSurface.partner,
              initialLocation: SurfaceRouter.verifyEmail,
            ),
          ),
        ),
      );
      await _settle(tester);
      if (token != null) {
        await tester.enterText(
            find.byKey(const Key('verify-email-token')), token);
      }
      if (email != null && find.byKey(const Key('verify-email-address')).evaluate().isNotEmpty) {
        await tester.enterText(
            find.byKey(const Key('verify-email-address')), email);
      }
    }

    Future<void> submitVerification(WidgetTester tester) async {
      await tester.ensureVisible(find.byKey(const Key('verify-email-submit')));
      await tester.tap(find.byKey(const Key('verify-email-submit')));
      await _settle(tester);
    }

    testWidgets('a valid token verifies and leads back to sign-in',
        (tester) async {
      await pumpVerify(
        tester,
        client: backend({
          '/auth/verify-email': (_) =>
              _json({'status': 'VERIFIED', 'message': 'ok'}, 200),
        }),
        token: 'a-real-token',
      );

      await submitVerification(tester);

      expect(find.text('Email verified successfully'), findsOneWidget);
      expect(find.byKey(const Key('verify-email-continue')), findsOneWidget);
      expect(jsonDecode(calls.single.body)['token'], 'a-real-token');
    });

    testWidgets('an already verified address is handled as success',
        (tester) async {
      await pumpVerify(
        tester,
        client: backend({
          '/auth/verify-email': (_) => _json({'status': 'ALREADY_VERIFIED'}, 200),
        }),
        token: 'a-real-token',
      );

      await submitVerification(tester);
      expect(find.text('Already verified'), findsOneWidget);
    });

    testWidgets('an invalid or expired token is explained, not swallowed',
        (tester) async {
      await pumpVerify(
        tester,
        client: backend({
          '/auth/verify-email': (_) => _json({
                'status': 400,
                'code': 'TOKEN_INVALID',
                'message': 'This link is invalid or has already been used',
              }, 400),
        }),
        token: 'used-token',
      );
      await submitVerification(tester);
      expect(find.text('This link is invalid or has already been used.'),
          findsOneWidget);
      expect(find.byKey(const Key('verify-email-continue')), findsNothing);

      await pumpVerify(
        tester,
        client: backend({
          '/auth/verify-email': (_) => _json({
                'status': 400,
                'code': 'TOKEN_EXPIRED',
                'message': 'This link has expired',
              }, 400),
        }),
        token: 'old-token',
      );
      await submitVerification(tester);
      expect(
          find.text('This link has expired. Request a new one.'), findsOneWidget);
    });

    testWidgets('an empty token is never sent', (tester) async {
      await pumpVerify(tester, client: backend(const {}));
      await submitVerification(tester);
      expect(calls, isEmpty);
      expect(find.text('Paste the token from your link.'), findsOneWidget);
    });

    testWidgets('resend asks once, then waits out the cooldown',
        (tester) async {
      final app = session(
        client: backend({
          '/auth/resend-verification': (_) =>
              _json({'message': 'If that address...'}, 202),
        }),
      );
      await tester.pumpWidget(
        AppScope(
          notifier: app,
          child: const SurfaceApp(
            surface: AppSurface.partner,
            initialLocation: SurfaceRouter.verifyEmail,
          ),
        ),
      );
      await _settle(tester);
      await tester.enterText(
          find.byKey(const Key('verify-email-address')), 'pat@example.com');
      await tester.pump();

      await tester.tap(find.byKey(const Key('verify-email-resend')));
      await _settle(tester);

      expect(calls.length, 1);
      expect(jsonDecode(calls.single.body)['email'], 'pat@example.com');
      expect(find.byKey(const Key('verify-email-resend-ack')), findsOneWidget,
          reason: 'the generic acknowledgement, not "we sent an email"');
      expect(find.byKey(const Key('verify-email-cooldown')), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('verify-email-resend')),
        warnIfMissed: false,
      );
      await _settle(tester);
      expect(calls.length, 1, reason: 'the cooldown blocks a second request');
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 4. Routing
  // ══════════════════════════════════════════════════════════════════════════

  group('Partner account routing', () {
    const router = PartnerSurfaceRouter();

    test('account locations are served, and stay inside the surface', () {
      for (final location in [
        SurfaceRouter.register,
        SurfaceRouter.verifyEmail,
        SurfaceRouter.forgotPassword,
        SurfaceRouter.resetPassword,
        SurfaceRouter.account,
      ]) {
        expect(router.resolve(location), location);
      }
      // A path this surface does not own still resolves to its own root.
      expect(router.resolve('/partner/register'), SurfaceRouter.root);
      expect(router.resolve('/nope'), SurfaceRouter.root);
    });

    test('only the signed-out account locations are public', () {
      expect(router.publicLocations, {
        SurfaceRouter.register,
        SurfaceRouter.verifyEmail,
        SurfaceRouter.forgotPassword,
        SurfaceRouter.resetPassword,
        // R5: an emailed team invitation opens before signing in.
        PartnerInvitationLink.location,
      });
      expect(router.publicScreenAt(SurfaceRouter.account), isNull,
          reason: 'the account area needs a session');
      expect(router.publicScreenAt(SurfaceRouter.root), isNull);
    });

    testWidgets('a wrong role never reaches the account area', (tester) async {
      final app = session(
        client: backend(const {}),
        email: 'traveller@example.com',
        role: AppRole.user,
      );
      await pumpPartner(tester, app: app, location: SurfaceRouter.account);

      expect(find.byKey(const Key('surface-sign-out')), findsOneWidget);
      expect(find.byKey(const Key('account-change-password')), findsNothing);
      expect(calls.where((c) => c.path.contains('/partner/')), isEmpty);
      expect(calls.where((c) => c.path.endsWith('/me')), isEmpty);
    });
  });
}

/// One request the app made.
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
