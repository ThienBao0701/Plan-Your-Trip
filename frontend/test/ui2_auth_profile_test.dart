import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/auth/email_verification_screen.dart';
import 'package:planyourtrip_frontend/features/auth/forgot_password_screen.dart';
import 'package:planyourtrip_frontend/features/auth/login_screen.dart';
import 'package:planyourtrip_frontend/features/auth/register_screen.dart';
import 'package:planyourtrip_frontend/features/profile/notifications_screen.dart';
import 'package:planyourtrip_frontend/features/profile/profile_screen.dart';
import 'package:planyourtrip_frontend/features/profile/saved_places_screen.dart';
import 'package:planyourtrip_frontend/features/profile/settings_screen.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  void ignoreNetworkImageErrors() {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exception is NetworkImageLoadException) return;
      originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);
  }

  Widget testApp({
    required Widget child,
    AppState? app,
    Locale? locale,
    double textScaleFactor = 1,
  }) {
    final state = app ?? AppState();
    return AppScope(
      notifier: state,
      child: Builder(
        builder: (context) {
          final scoped = AppScope.of(context);
          return MaterialApp(
            theme: AppTheme.light(),
            locale: locale ?? scoped.localeOverride,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) {
              final media = MediaQuery.of(context);
              return MediaQuery(
                data: media.copyWith(
                  textScaler: TextScaler.linear(textScaleFactor),
                ),
                child: child!,
              );
            },
            home: child,
          );
        },
      ),
    );
  }

  Future<void> pumpSize(
    WidgetTester tester,
    Widget widget,
    Size size,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  testWidgets('login form validates email and password', (tester) async {
    await pumpSize(
      tester,
      testApp(child: const LoginScreen()),
      const Size(390, 900),
    );

    await tester.ensureVisible(find.byKey(const Key('login-submit')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
  });

  testWidgets('password visibility toggle changes login field', (tester) async {
    await pumpSize(
      tester,
      testApp(child: const LoginScreen()),
      const Size(390, 900),
    );

    var field = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('login-password-field')),
        matching: find.byType(EditableText),
      ),
    );
    expect(field.obscureText, isTrue);

    await tester.tap(find.byIcon(Icons.visibility_rounded));
    await tester.pump();

    field = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('login-password-field')),
        matching: find.byType(EditableText),
      ),
    );
    expect(field.obscureText, isFalse);
  });

  testWidgets('duplicate login submission is guarded', (tester) async {
    final completer = Completer<http.Response>();
    var calls = 0;
    final api = ApiClient(
      client: MockClient((request) {
        calls++;
        return completer.future;
      }),
    )..demoMode = false;
    final app = AppState(api: api)..demoMode = false;

    await pumpSize(
      tester,
      testApp(child: const LoginScreen(), app: app),
      const Size(390, 900),
    );

    await tester.enterText(
      find.byKey(const Key('login-email-field')),
      'real@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('login-password-field')),
      'password123',
    );
    await tester.ensureVisible(find.byKey(const Key('login-submit')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();

    expect(calls, 1);
    completer.complete(
      http.Response(
        jsonEncode({'token': 'real-token'}),
        200,
        headers: {'content-type': 'application/json'},
      ),
    );
    await tester.pumpAndSettle();

    expect(app.demoMode, isFalse);
    expect(app.api.token, 'real-token');
  });

  testWidgets('registration validation and confirm-password mismatch',
      (tester) async {
    await pumpSize(
      tester,
      testApp(child: const RegisterScreen()),
      const Size(390, 900),
    );

    await tester.ensureVisible(find.byKey(const Key('register-submit')));
    await tester.tap(find.byKey(const Key('register-submit')));
    await tester.pump();
    expect(find.text('Enter your full name.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('register-name-field')), 'Bao');
    await tester.enterText(
      find.byKey(const Key('register-email-field')),
      'bao@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('register-password-field')),
      'password123',
    );
    await tester.enterText(
      find.byKey(const Key('register-confirm-field')),
      'password456',
    );
    await tester.ensureVisible(find.byKey(const Key('register-submit')));
    await tester.tap(find.byKey(const Key('register-submit')));
    await tester.pump();

    expect(find.text('Passwords do not match.'), findsOneWidget);
  });

  testWidgets('duplicate registration submission is guarded', (tester) async {
    final completer = Completer<http.Response>();
    var calls = 0;
    final app = AppState(
      api: ApiClient(
        client: MockClient((request) {
          calls++;
          return completer.future;
        }),
      ),
    );

    await pumpSize(
      tester,
      testApp(child: const RegisterScreen(), app: app),
      const Size(390, 900),
    );

    await tester.enterText(find.byKey(const Key('register-name-field')), 'Bao');
    await tester.enterText(
      find.byKey(const Key('register-email-field')),
      'bao@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('register-password-field')),
      'password123',
    );
    await tester.enterText(
      find.byKey(const Key('register-confirm-field')),
      'password123',
    );
    await tester.ensureVisible(find.byKey(const Key('register-submit')));
    await tester.tap(find.byKey(const Key('register-submit')));
    await tester.tap(find.byKey(const Key('register-submit')));
    await tester.pump();

    expect(calls, 1);
    completer.complete(http.Response('{}', 201));
    await tester.pumpAndSettle();
  });

  testWidgets('forgot-password validates email and does not fake success',
      (tester) async {
    await pumpSize(
      tester,
      testApp(child: const ForgotPasswordScreen()),
      const Size(390, 780),
    );

    await tester.ensureVisible(find.byKey(const Key('forgot-submit')));
    await tester.tap(find.byKey(const Key('forgot-submit')));
    await tester.pump();
    expect(find.text('Enter a valid email address.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('forgot-email-field')),
      'bao@example.com',
    );
    await tester.ensureVisible(find.byKey(const Key('forgot-submit')));
    await tester.tap(find.byKey(const Key('forgot-submit')));
    await tester.pump();

    expect(
      find.text('Password reset is not connected to the backend yet.'),
      findsOneWidget,
    );
  });

  testWidgets('six-digit verification input and unsupported verify behavior',
      (tester) async {
    await pumpSize(
      tester,
      testApp(
        child: const EmailVerificationScreen(
          email: 'bao@example.com',
          initialCountdown: Duration.zero,
        ),
      ),
      const Size(390, 780),
    );

    await tester.enterText(find.byKey(const Key('otp-0')), '123456');
    await tester.pump();

    for (var i = 0; i < 6; i++) {
      final field = tester.widget<TextField>(find.byKey(Key('otp-$i')));
      expect(field.controller?.text, '${i + 1}');
    }

    await tester.tap(find.byKey(const Key('verification-submit')));
    await tester.pump();

    expect(
      find.text('Email verification is not connected to the backend yet.'),
      findsOneWidget,
    );
  });

  testWidgets('verification resend restarts countdown deterministically',
      (tester) async {
    var resendCalls = 0;
    await pumpSize(
      tester,
      testApp(
        child: EmailVerificationScreen(
          email: 'bao@example.com',
          initialCountdown: const Duration(seconds: 1),
          onResend: () async {
            resendCalls++;
            return true;
          },
        ),
      ),
      const Size(390, 780),
    );

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('Resend code'), findsOneWidget);

    await tester.tap(find.text('Resend code'));
    await tester.pump();

    expect(resendCalls, 1);
    expect(find.text('Resend code in 00:1'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('Resend code'), findsOneWidget);
  });

  testWidgets('profile separates real and demo account presentation',
      (tester) async {
    final realApp = AppState()
      ..demoMode = false
      ..email = 'real@example.com';

    await pumpSize(
      tester,
      testApp(child: const ProfileScreen(), app: realApp),
      const Size(390, 900),
    );

    expect(find.text('Signed-in account'), findsOneWidget);
    expect(
      find.text('Profile details are not connected to a backend endpoint yet.'),
      findsWidgets,
    );
    expect(find.text('Demo Traveler'), findsNothing);

    final demoApp = AppState()
      ..demoMode = true
      ..email = 'demo@planyourtrip.com';
    await pumpSize(
      tester,
      testApp(child: const ProfileScreen(), app: demoApp),
      const Size(390, 900),
    );

    expect(find.text('Demo Traveler'), findsOneWidget);
    expect(find.text('Demo data active'), findsOneWidget);
  });

  testWidgets('settings language selection updates local app locale',
      (tester) async {
    final app = AppState()
      ..demoMode = true
      ..email = 'demo@planyourtrip.com';

    await pumpSize(
      tester,
      testApp(child: const SettingsScreen(), app: app),
      const Size(390, 900),
    );

    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vietnamese'));
    await tester.pumpAndSettle();

    expect(app.localeOverride?.languageCode, 'vi');
    expect(find.text('Cài đặt'), findsOneWidget);
  });

  testWidgets('saved places shows real empty state and demo saved places',
      (tester) async {
    ignoreNetworkImageErrors();
    final realApp = AppState()
      ..demoMode = false
      ..email = 'real@example.com';

    await pumpSize(
      tester,
      testApp(child: const SavedPlacesScreen(), app: realApp),
      const Size(390, 900),
    );

    expect(find.text('No saved places yet'), findsOneWidget);

    final demoApp = AppState()
      ..demoMode = true
      ..email = 'demo@planyourtrip.com';
    await pumpSize(
      tester,
      testApp(child: const SavedPlacesScreen(), app: demoApp),
      const Size(390, 900),
    );

    expect(find.text('Mây Lang Thang Villa'), findsOneWidget);
    expect(find.text('4 places'), findsWidgets);
  });

  testWidgets('notifications show real empty state and demo notifications',
      (tester) async {
    final realApp = AppState()
      ..demoMode = false
      ..email = 'real@example.com';

    await pumpSize(
      tester,
      testApp(child: const NotificationsScreen(), app: realApp),
      const Size(390, 900),
    );

    expect(find.text('No notifications'), findsOneWidget);

    final demoApp = AppState()
      ..demoMode = true
      ..email = 'demo@planyourtrip.com';
    await pumpSize(
      tester,
      testApp(child: const NotificationsScreen(), app: demoApp),
      const Size(390, 900),
    );

    expect(find.text('Booking changes saved'), findsOneWidget);
    expect(find.text('Demo payment completed'), findsOneWidget);
  });

  testWidgets('UI-2 screens avoid narrow overflow and support text scaling',
      (tester) async {
    await pumpSize(
      tester,
      testApp(child: const LoginScreen()),
      const Size(320, 680),
    );
    expect(tester.takeException(), isNull);

    final app = AppState()
      ..demoMode = true
      ..email = 'demo@planyourtrip.com';
    await pumpSize(
      tester,
      testApp(
        child: const ProfileScreen(),
        app: app,
        textScaleFactor: 1.8,
      ),
      const Size(360, 760),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('important UI-2 controls expose semantic labels', (tester) async {
    ignoreNetworkImageErrors();
    final semantics = tester.ensureSemantics();
    try {
      await pumpSize(
        tester,
        testApp(child: const LoginScreen()),
        const Size(390, 900),
      );
      expect(find.bySemanticsLabel('Show password'), findsOneWidget);

      await pumpSize(
        tester,
        testApp(
          child: const EmailVerificationScreen(
            email: 'bao@example.com',
            initialCountdown: Duration.zero,
          ),
        ),
        const Size(390, 780),
      );
      expect(find.bySemanticsLabel('Verification digit 1'), findsOneWidget);

      final app = AppState()
        ..demoMode = true
        ..email = 'demo@planyourtrip.com';
      await pumpSize(
        tester,
        testApp(child: const SavedPlacesScreen(), app: app),
        const Size(390, 900),
      );
      expect(
        find.bySemanticsLabel(RegExp('Remove saved place')),
        findsWidgets,
      );

      await pumpSize(
        tester,
        testApp(child: const ProfileScreen(), app: app),
        const Size(390, 900),
      );
      await tester.scrollUntilVisible(find.text('Logout'), 200);
      await tester.pump();
      expect(
        find.bySemanticsLabel('Log out of this account'),
        findsOneWidget,
      );
    } finally {
      semantics.dispose();
    }
  });
}
