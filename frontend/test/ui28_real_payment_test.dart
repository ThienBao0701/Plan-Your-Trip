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
import 'package:planyourtrip_frontend/features/hotels/booking_result_screen.dart';
import 'package:planyourtrip_frontend/features/payments/real_payment_screen.dart';
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

  // Mirror of PaymentDto.PaymentResponse.
  Map<String, dynamic> paymentJson({
    int id = 88,
    String status = 'PENDING',
    int bookingId = 55,
    String paymentCode = 'PAY-20300601-000088',
    num? amount = 3300000,
    String method = 'MOCK',
    String provider = 'MOCK',
    String? failureReason,
  }) =>
      {
        'id': id,
        'paymentCode': paymentCode,
        'bookingId': bookingId,
        'bookingCode': 'PYT-20300601-000055',
        'amount': amount,
        'currency': 'VND',
        'paymentMethod': method,
        'status': status,
        'provider': provider,
        'providerTransactionId': status == 'PAID' ? 'MOCK-TX-1' : null,
        'checkoutUrl': null,
        'failureReason': failureReason,
        'paidAt': status == 'PAID' ? '2030-05-01T11:00:00Z' : null,
        'failedAt': status == 'FAILED' ? '2030-05-01T11:00:00Z' : null,
        'refundedAt': null,
        'createdAt': '2030-05-01T10:30:00Z',
        'updatedAt': '2030-05-01T11:00:00Z',
      };

  bool mockSuccessPath(http.Request r) =>
      r.method == 'POST' &&
      RegExp(r'/payments/\d+/mock-success$').hasMatch(r.url.path);
  bool mockFailPath(http.Request r) =>
      r.method == 'POST' &&
      RegExp(r'/payments/\d+/mock-fail$').hasMatch(r.url.path);
  bool createPath(http.Request r) =>
      r.method == 'POST' && r.url.path.endsWith('/payments');
  bool listPath(http.Request r) =>
      r.method == 'GET' &&
      RegExp(r'/bookings/\d+/payments$').hasMatch(r.url.path);
  bool getPath(http.Request r) =>
      r.method == 'GET' && RegExp(r'/payments/\d+$').hasMatch(r.url.path);

  AppState routedApp({
    Future<http.Response> Function(http.Request)? onCreate,
    Future<http.Response> Function(http.Request)? onList,
    Future<http.Response> Function(http.Request)? onGet,
    Future<http.Response> Function(http.Request)? onSuccess,
    Future<http.Response> Function(http.Request)? onFail,
    void Function(http.Request)? onRequest,
  }) =>
      realApp(MockClient((request) async {
        onRequest?.call(request);
        if (mockSuccessPath(request)) {
          return (onSuccess ??
              (_) async =>
                  jsonResponse(paymentJson(status: 'PAID'), 200))(request);
        }
        if (mockFailPath(request)) {
          return (onFail ??
              (_) async =>
                  jsonResponse(paymentJson(status: 'FAILED'), 200))(request);
        }
        if (createPath(request)) {
          return (onCreate ??
              (_) async => jsonResponse(paymentJson(), 201))(request);
        }
        if (listPath(request)) {
          return (onList ??
              (_) async => jsonResponse([paymentJson()], 200))(request);
        }
        if (getPath(request)) {
          return (onGet ??
              (_) async => jsonResponse(paymentJson(), 200))(request);
        }
        return jsonResponse(const <Map<String, dynamic>>[], 200);
      }));

  Place sampleHotel() => const Place(
        id: 7,
        name: 'Backend Villa',
        category: 'Hotels',
        categorySlug: 'hotel',
        locationName: 'Da Lat',
        city: 'Da Lat',
        province: 'Lam Dong',
        description: 'Villa.',
        imageUrl: '',
        rating: 4.6,
      );

  BookingCreateRecord pendingBooking() => const BookingCreateRecord(
        id: 55,
        bookingCode: 'PYT-20300601-000055',
        hotelName: 'Backend Villa',
        roomId: 100,
        roomName: 'Deluxe Garden View',
        status: 'PENDING',
        currency: 'VND',
        finalPrice: 3300000,
      );

  // ── Contract parsing ───────────────────────────────────────────────────────

  group('Contract parsing', () {
    test('createPayment POSTs /api/payments with {bookingId, MOCK method}',
        () async {
      http.Request? captured;
      final app = routedApp(onRequest: (r) {
        if (createPath(r)) captured = r;
      });
      final outcome = await app.createRealPayment(55);
      expect(outcome, PaymentActionOutcome.success);
      expect(captured, isNotNull);
      expect(captured!.url.path.endsWith('/payments'), isTrue);
      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['bookingId'], 55);
      expect(body['paymentMethod'], 'MOCK');
    });

    test('RealPaymentRecord.fromJson maps every field; checkoutUrl is null',
        () async {
      final app =
          routedApp(onCreate: (_) async => jsonResponse(paymentJson(), 201));
      await app.createRealPayment(55);
      final p = app.realPayment!;
      expect(p.id, 88);
      expect(p.paymentCode, 'PAY-20300601-000088');
      expect(p.bookingId, 55);
      expect(p.bookingCode, 'PYT-20300601-000055');
      expect(p.amount, 3300000);
      expect(p.currency, 'VND');
      expect(p.paymentMethod, 'MOCK');
      expect(p.provider, 'MOCK');
      expect(p.status, 'PENDING');
      expect(p.statusView, PaymentStatusView.pending);
      expect(p.checkoutUrl, isNull);
      expect(p.createdAt, isNotNull);
    });

    test('unknown status degrades to unknown but keeps the raw string',
        () async {
      final app = routedApp(
        onCreate: (_) async =>
            jsonResponse(paymentJson(status: 'DISPUTED'), 201),
      );
      await app.createRealPayment(55);
      expect(app.realPayment!.statusView, PaymentStatusView.unknown);
      expect(app.realPayment!.status, 'DISPUTED');
    });

    test('getBookingPayments parses a bare array, latest first', () async {
      final app = routedApp(
        onList: (_) async => jsonResponse([
          paymentJson(id: 99, status: 'PENDING'),
          paymentJson(id: 88, status: 'FAILED'),
        ], 200),
      );
      final outcome = await app.loadPaymentForBooking(55);
      expect(outcome, PaymentActionOutcome.success);
      expect(app.realPayment!.id, 99);
    });

    test('an empty payment list leaves realPayment null (no payment yet)',
        () async {
      final app = routedApp(onList: (_) async => jsonResponse(const [], 200));
      final outcome = await app.loadPaymentForBooking(55);
      expect(outcome, PaymentActionOutcome.success);
      expect(app.realPayment, isNull);
    });
  });

  // ── Demo Mode (zero HTTP) ────────────────────────────────────────────────────

  group('Demo Mode', () {
    test('all payment actions make zero HTTP in Demo Mode', () async {
      var calls = 0;
      final app = demoApp(MockClient((r) async {
        calls++;
        return jsonResponse(paymentJson(), 200);
      }));
      expect(await app.loadPaymentForBooking(55),
          PaymentActionOutcome.demoUnavailable);
      expect(await app.createRealPayment(55),
          PaymentActionOutcome.demoUnavailable);
      expect(await app.settleRealPaymentSandbox(success: true),
          PaymentActionOutcome.demoUnavailable);
      expect(calls, 0);
      expect(app.realPayment, isNull);
    });
  });

  // ── Settlement flow ──────────────────────────────────────────────────────────

  group('Settlement', () {
    test('mock-success settles PAID and confirms the booking side effects',
        () async {
      final app = routedApp(
        onList: (_) async => jsonResponse([paymentJson()], 200),
        onSuccess: (_) async => jsonResponse(paymentJson(status: 'PAID'), 200),
      );
      await app.loadPaymentForBooking(55);
      // Pretend the history + detail were already cached.
      app.realBookingsLoaded = true;
      app.bookingDetailCache[55] = pendingBooking();

      final outcome = await app.settleRealPaymentSandbox(success: true);
      expect(outcome, PaymentActionOutcome.success);
      expect(app.realPayment!.statusView, PaymentStatusView.paid);
      // A PAID payment confirms the booking → caches invalidated for a re-fetch.
      expect(app.realBookingsLoaded, isFalse);
      expect(app.bookingDetailCache.containsKey(55), isFalse);
    });

    test('mock-fail settles FAILED and does NOT invalidate booking caches',
        () async {
      final app = routedApp(
        onList: (_) async => jsonResponse([paymentJson()], 200),
        onFail: (_) async => jsonResponse(
            paymentJson(status: 'FAILED', failureReason: 'declined'), 200),
      );
      await app.loadPaymentForBooking(55);
      app.realBookingsLoaded = true;
      final outcome = await app.settleRealPaymentSandbox(success: false);
      expect(outcome, PaymentActionOutcome.success);
      expect(app.realPayment!.statusView, PaymentStatusView.failed);
      expect(app.realPayment!.failureReason, 'declined');
      expect(app.realBookingsLoaded, isTrue);
    });

    test('refreshRealPayment re-fetches the current payment', () async {
      var gets = 0;
      final app = routedApp(
        onList: (_) async => jsonResponse([paymentJson()], 200),
        onGet: (_) async {
          gets++;
          return jsonResponse(paymentJson(status: 'PAID'), 200);
        },
      );
      await app.loadPaymentForBooking(55);
      final outcome = await app.refreshRealPayment();
      expect(outcome, PaymentActionOutcome.success);
      expect(gets, 1);
      expect(app.realPayment!.statusView, PaymentStatusView.paid);
    });

    test('a second create while one is in flight returns busy (single-flight)',
        () async {
      final gate = Completer<http.Response>();
      final app = routedApp(onCreate: (_) => gate.future);
      final first = app.createRealPayment(55);
      final second = await app.createRealPayment(55);
      expect(second, PaymentActionOutcome.busy);
      gate.complete(jsonResponse(paymentJson(), 201));
      expect(await first, PaymentActionOutcome.success);
    });
  });

  // ── Error mapping ────────────────────────────────────────────────────────────

  group('Errors', () {
    test('create 401 → sessionExpired, NO auto-logout / no demo switch',
        () async {
      final app = routedApp(
        onCreate: (_) async =>
            jsonResponse(errorBody(401, 'expired', '/api/payments'), 401),
      );
      app.email = 'mai@example.com';
      app.api.token = 'jwt-token';
      final outcome = await app.createRealPayment(55);
      expect(outcome, PaymentActionOutcome.sessionExpired);
      expect(app.email, 'mai@example.com');
      expect(app.api.token, 'jwt-token');
      expect(app.demoMode, isFalse);
    });

    test('create 403 → forbidden', () async {
      final app = routedApp(
        onCreate: (_) async =>
            jsonResponse(errorBody(403, 'denied', '/api/payments'), 403),
      );
      expect(await app.createRealPayment(55), PaymentActionOutcome.forbidden);
    });

    test('create 404 → notFound', () async {
      final app = routedApp(
        onCreate: (_) async =>
            jsonResponse(errorBody(404, 'missing', '/api/payments'), 404),
      );
      expect(await app.createRealPayment(55), PaymentActionOutcome.notFound);
    });

    test('create 422 → unprocessable (not payable / already paid)', () async {
      final app = routedApp(
        onCreate: (_) async =>
            jsonResponse(errorBody(422, 'already paid', '/api/payments'), 422),
      );
      expect(
          await app.createRealPayment(55), PaymentActionOutcome.unprocessable);
    });

    test('settle 409 → conflict', () async {
      final app = routedApp(
        onList: (_) async => jsonResponse([paymentJson()], 200),
        onSuccess: (_) async => jsonResponse(
            errorBody(409, 'conflict', '/api/payments/88/mock-success'), 409),
      );
      await app.loadPaymentForBooking(55);
      expect(await app.settleRealPaymentSandbox(success: true),
          PaymentActionOutcome.conflict);
    });

    test('create 500 → serverError', () async {
      final app = routedApp(
        onCreate: (_) async =>
            jsonResponse(errorBody(500, 'boom', '/api/payments'), 500),
      );
      expect(await app.createRealPayment(55), PaymentActionOutcome.serverError);
    });

    test('transport failure → network; timeout → network', () async {
      final netApp = realApp(MockClient((_) async {
        throw http.ClientException('offline');
      }));
      expect(await netApp.createRealPayment(55), PaymentActionOutcome.network);
      final toApp = realApp(MockClient((_) async {
        throw TimeoutException('slow');
      }));
      expect(await toApp.createRealPayment(55), PaymentActionOutcome.network);
    });
  });

  // ── Session isolation ────────────────────────────────────────────────────────

  group('Session isolation', () {
    test('logout clears the payment context', () async {
      final app = routedApp();
      await app.loadPaymentForBooking(55);
      expect(app.realPayment, isNotNull);
      await app.logout();
      expect(app.realPayment, isNull);
      expect(app.realPaymentBookingId, isNull);
      expect(app.realPaymentError, isNull);
    });
  });

  // ── Widgets ──────────────────────────────────────────────────────────────────

  group('Payment screen', () {
    testWidgets('no payment yet → create → status card appears', (t) async {
      final app = routedApp(
        onList: (_) async => jsonResponse(const [], 200),
        onCreate: (_) async => jsonResponse(paymentJson(), 201),
      );
      await pumpSize(
        t,
        testApp(
          child: const RealPaymentScreen(
            bookingId: 55,
            bookingCode: 'PYT-20300601-000055',
            amount: 3300000,
          ),
          app: app,
        ),
        const Size(1200, 2200),
      );
      expect(find.byKey(const Key('payment-sandbox-notice')), findsOneWidget);
      expect(find.byKey(const Key('payment-none')), findsOneWidget);

      await t.tap(find.byKey(const Key('payment-create')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('payment-status-card')), findsOneWidget);
      expect(find.byKey(const Key('payment-complete')), findsOneWidget);
    });

    testWidgets('completing a payment confirms it after the confirm dialog',
        (t) async {
      final app = routedApp(
        onList: (_) async => jsonResponse([paymentJson()], 200),
        onSuccess: (_) async => jsonResponse(paymentJson(status: 'PAID'), 200),
      );
      await pumpSize(
        t,
        testApp(
          child: const RealPaymentScreen(
            bookingId: 55,
            bookingCode: 'PYT-20300601-000055',
            amount: 3300000,
          ),
          app: app,
        ),
        const Size(1200, 2200),
      );
      expect(find.byKey(const Key('payment-complete')), findsOneWidget);
      await t.tap(find.byKey(const Key('payment-complete')));
      await t.pumpAndSettle();
      // Explicit confirmation is required (CLAUDE.md §11).
      expect(find.byKey(const Key('payment-confirm-complete')), findsOneWidget);
      await t.tap(find.byKey(const Key('payment-confirm-complete')));
      await t.pumpAndSettle();
      expect(app.realPayment!.statusView, PaymentStatusView.paid);
      expect(find.byKey(const Key('payment-done')), findsOneWidget);
      final l10n = AppLocalizationsEn();
      expect(find.text(l10n.paymentSuccessHeadline), findsWidgets);
    });

    testWidgets('a list load error shows the retryable error state', (t) async {
      final app = routedApp(
        onList: (_) async => jsonResponse(
            errorBody(500, 'boom', '/api/bookings/55/payments'), 500),
      );
      await pumpSize(
        t,
        testApp(
          child: const RealPaymentScreen(
            bookingId: 55,
            bookingCode: 'PYT-20300601-000055',
          ),
          app: app,
        ),
        const Size(1200, 2000),
      );
      expect(find.byKey(const Key('payment-error')), findsOneWidget);
    });

    testWidgets('a 401 shows the inline session-expired state', (t) async {
      final app = routedApp(
        onList: (_) async => jsonResponse(
            errorBody(401, 'expired', '/api/bookings/55/payments'), 401),
      );
      await pumpSize(
        t,
        testApp(
          child: const RealPaymentScreen(
            bookingId: 55,
            bookingCode: 'PYT-20300601-000055',
          ),
          app: app,
        ),
        const Size(1200, 2000),
      );
      expect(find.byKey(const Key('payment-session-expired')), findsOneWidget);
    });

    testWidgets('booking result shows Pay now for a PENDING booking',
        (t) async {
      final app = routedApp(onList: (_) async => jsonResponse(const [], 200));
      app.lastCreatedBooking = pendingBooking();
      await pumpSize(
        t,
        testApp(
          child: BookingResultScreen(hotel: sampleHotel()),
          app: app,
        ),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('booking-result-pay')), findsOneWidget);
      await t.tap(find.byKey(const Key('booking-result-pay')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('payment-content')), findsOneWidget);
    });
  });

  // ── Localization parity ──────────────────────────────────────────────────────

  group('Localization parity', () {
    test('every new UI28 key is present in both EN and VI', () {
      final en = AppLocalizationsEn();
      final vi = AppLocalizationsVi();
      final values = <String>[
        en.paymentTitle,
        vi.paymentTitle,
        en.paymentPayNowAction,
        vi.paymentPayNowAction,
        en.paymentSandboxNotice,
        vi.paymentSandboxNotice,
        en.paymentAmountToPayLabel,
        vi.paymentAmountToPayLabel,
        en.paymentCreateAction,
        vi.paymentCreateAction,
        en.paymentCompleteSandboxAction,
        vi.paymentCompleteSandboxAction,
        en.paymentConfirmMessage,
        vi.paymentConfirmMessage,
        en.paymentActionNotPayableMessage,
        vi.paymentActionNotPayableMessage,
      ];
      for (final s in values) {
        expect(s.trim(), isNotEmpty);
      }
      expect(en.paymentSandboxNotice != vi.paymentSandboxNotice, isTrue);
    });
  });
}
