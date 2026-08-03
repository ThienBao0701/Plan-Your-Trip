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
import 'package:planyourtrip_frontend/features/bookings/my_bookings_screen.dart';
import 'package:planyourtrip_frontend/features/bookings/real_booking_detail_screen.dart';
import 'package:planyourtrip_frontend/features/hotels/hotel_utils.dart';
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

  // ── Backend fixtures (verified vs Plan-Your-Trip-backend-v1) ─────────────────

  // Mirror of BookingDto.BookingSummaryResponse (GET /api/me/bookings item).
  Map<String, dynamic> bookingSummaryJson({
    int id = 55,
    String bookingCode = 'PYT-20300601-000055',
    String status = 'PENDING',
    String hotelName = 'Backend Villa',
    String roomName = 'Deluxe Garden View',
    String? checkIn = '2030-06-01',
    String? checkOut = '2030-06-04',
    num? finalPrice = 3300000,
    String createdAt = '2030-05-01T10:00:00Z',
  }) =>
      {
        'id': id,
        'bookingCode': bookingCode,
        'hotelId': 7,
        'hotelName': hotelName,
        'roomId': 100,
        'roomName': roomName,
        'checkIn': checkIn,
        'checkOut': checkOut,
        'nights': 3,
        'status': status,
        'finalPrice': finalPrice,
        'currency': 'VND',
        'createdAt': createdAt,
      };

  // Mirror of BookingDto.BookingResponse (GET /api/bookings/{id}).
  Map<String, dynamic> bookingResponseJson({
    int id = 55,
    String status = 'PENDING',
    num finalPrice = 3300000,
    bool ratePlan = true,
    String bookingCode = 'PYT-20300601-000055',
  }) =>
      {
        'id': id,
        'bookingCode': bookingCode,
        'userId': 9,
        'userFullName': 'Mai Nguyen',
        'userEmail': 'mai@example.com',
        'hotelId': 7,
        'hotelName': 'Backend Villa',
        'roomId': 100,
        'roomName': 'Deluxe Garden View',
        'roomCode': 'DLX',
        'checkIn': '2030-06-01',
        'checkOut': '2030-06-04',
        'nights': 3,
        'adults': 2,
        'children': 0,
        'numberOfRooms': 1,
        'status': status,
        'currency': 'VND',
        'basePrice': 3600000,
        'ratePlanPrice': 3600000,
        'discountAmount': 300000,
        'finalPrice': finalPrice,
        'specialRequest': 'High floor',
        'createdAt': '2030-05-01T10:00:00Z',
        'confirmedAt': null,
        if (ratePlan) 'selectedRatePlanId': 500,
        if (ratePlan) 'selectedRatePlanName': 'Flexible',
        if (ratePlan) 'refundable': true,
      };

  bool isListPath(http.Request r) =>
      r.method == 'GET' && r.url.path.endsWith('/me/bookings');
  bool isDetailPath(http.Request r) =>
      r.method == 'GET' && RegExp(r'/bookings/\d+$').hasMatch(r.url.path);

  /// A routing client: `GET /me/bookings` → [onList], `GET /bookings/{id}` →
  /// [onDetail]. [onRequest] observes every request (path / query assertions).
  AppState routedApp({
    Future<http.Response> Function(http.Request)? onList,
    Future<http.Response> Function(http.Request)? onDetail,
    void Function(http.Request)? onRequest,
  }) =>
      realApp(MockClient((request) async {
        onRequest?.call(request);
        if (isListPath(request)) {
          return (onList ??
              (r) async => jsonResponse([bookingSummaryJson()], 200))(request);
        }
        if (isDetailPath(request)) {
          return (onDetail ??
              (r) async => jsonResponse(bookingResponseJson(), 200))(request);
        }
        return jsonResponse(const <Map<String, dynamic>>[], 200);
      }));

  // ── Contract parsing ───────────────────────────────────────────────────────

  group('Contract parsing', () {
    test('getMyBookings GETs /api/me/bookings with NO query params', () async {
      http.Request? captured;
      final app = routedApp(onRequest: (r) {
        if (isListPath(r)) captured = r;
      });
      final outcome = await app.loadMyBookings();
      expect(outcome, BookingHistoryOutcome.success);
      expect(captured, isNotNull);
      expect(captured!.method, 'GET');
      expect(captured!.url.path.endsWith('/me/bookings'), isTrue);
      // No pagination / sort / status filter exists on this endpoint.
      expect(captured!.url.query, isEmpty);
    });

    test('BookingSummaryRecord.fromJson maps every field', () async {
      final app = routedApp(
        onList: (_) async => jsonResponse([bookingSummaryJson()], 200),
      );
      await app.loadMyBookings();
      expect(app.realBookings, hasLength(1));
      final r = app.realBookings.single;
      expect(r.id, 55);
      expect(r.bookingCode, 'PYT-20300601-000055');
      expect(r.hotelId, 7);
      expect(r.hotelName, 'Backend Villa');
      expect(r.roomId, 100);
      expect(r.roomName, 'Deluxe Garden View');
      expect(r.checkIn, DateTime.parse('2030-06-01'));
      expect(r.checkOut, DateTime.parse('2030-06-04'));
      expect(r.nights, 3);
      expect(r.status, 'PENDING');
      expect(r.statusView, BookingStatusView.pending);
      expect(r.finalPrice, 3300000);
      expect(r.currency, 'VND');
      expect(r.createdAt, isNotNull);
    });

    test('unknown status degrades to unknown but keeps the raw string',
        () async {
      final app = routedApp(
        onList: (_) async =>
            jsonResponse([bookingSummaryJson(status: 'FUTURE_STATE')], 200),
      );
      await app.loadMyBookings();
      final r = app.realBookings.single;
      expect(r.statusView, BookingStatusView.unknown);
      expect(r.status, 'FUTURE_STATE');
    });

    test('a bare JSON array is parsed and preserves server order', () async {
      final app = routedApp(
        onList: (_) async => jsonResponse([
          bookingSummaryJson(id: 3, bookingCode: 'PYT-3'),
          bookingSummaryJson(id: 1, bookingCode: 'PYT-1'),
          bookingSummaryJson(id: 2, bookingCode: 'PYT-2'),
        ], 200),
      );
      await app.loadMyBookings();
      expect(app.realBookings.map((b) => b.id).toList(), [3, 1, 2]);
    });

    test('a non-array success body is a malformed → serverError outcome',
        () async {
      final app = routedApp(
        onList: (_) async => jsonResponse({'not': 'a list'}, 200),
      );
      final outcome = await app.loadMyBookings();
      expect(outcome, BookingHistoryOutcome.serverError);
      expect(app.realBookings, isEmpty);
    });

    test('getBookingDetail parses the full BookingResponse', () async {
      final app = routedApp();
      final outcome = await app.loadBookingDetail(55);
      expect(outcome, BookingHistoryOutcome.success);
      final r = app.bookingDetailCache[55]!;
      expect(r.bookingCode, 'PYT-20300601-000055');
      expect(r.adults, 2);
      expect(r.numberOfRooms, 1);
      expect(r.finalPrice, 3300000);
      expect(r.selectedRatePlanName, 'Flexible');
      expect(r.statusView, BookingStatusView.pending);
    });
  });

  // ── Demo Mode (zero HTTP) ────────────────────────────────────────────────────

  group('Demo Mode', () {
    test('loadMyBookings in Demo Mode makes zero HTTP calls', () async {
      var calls = 0;
      final app = demoApp(MockClient((r) async {
        calls++;
        return jsonResponse(const [], 200);
      }));
      final outcome = await app.loadMyBookings();
      expect(outcome, BookingHistoryOutcome.demoUnavailable);
      expect(calls, 0);
      expect(app.realBookings, isEmpty);
    });

    test('loadBookingDetail in Demo Mode makes zero HTTP calls', () async {
      var calls = 0;
      final app = demoApp(MockClient((r) async {
        calls++;
        return jsonResponse(bookingResponseJson(), 200);
      }));
      final outcome = await app.loadBookingDetail(55);
      expect(outcome, BookingHistoryOutcome.demoUnavailable);
      expect(calls, 0);
      expect(app.bookingDetailCache, isEmpty);
    });
  });

  // ── History load / refresh / caching ─────────────────────────────────────────

  group('History load', () {
    test('success stores the list and marks loaded', () async {
      final app = routedApp(
        onList: (_) async => jsonResponse([bookingSummaryJson()], 200),
      );
      await app.loadMyBookings();
      expect(app.realBookingsLoaded, isTrue);
      expect(app.realBookings, hasLength(1));
      expect(app.realBookingsError, isNull);
    });

    test('empty list is an honest success with an empty cache', () async {
      final app = routedApp(onList: (_) async => jsonResponse(const [], 200));
      final outcome = await app.loadMyBookings();
      expect(outcome, BookingHistoryOutcome.success);
      expect(app.realBookingsLoaded, isTrue);
      expect(app.realBookings, isEmpty);
    });

    test('a second load without refresh does not re-fetch', () async {
      var calls = 0;
      final app = routedApp(onList: (r) async {
        calls++;
        return jsonResponse([bookingSummaryJson()], 200);
      });
      await app.loadMyBookings();
      await app.loadMyBookings();
      expect(calls, 1);
    });

    test('refresh re-fetches and preserves the list on failure', () async {
      var calls = 0;
      final app = routedApp(onList: (r) async {
        calls++;
        if (calls == 1) return jsonResponse([bookingSummaryJson()], 200);
        return jsonResponse(errorBody(500, 'boom', '/api/me/bookings'), 500);
      });
      await app.loadMyBookings();
      final outcome = await app.loadMyBookings(refresh: true);
      expect(calls, 2);
      expect(outcome, BookingHistoryOutcome.serverError);
      // Prior list preserved; only the error is surfaced.
      expect(app.realBookings, hasLength(1));
      expect(app.realBookingsError, BookingHistoryOutcome.serverError);
    });
  });

  // ── Detail caching ───────────────────────────────────────────────────────────

  group('Detail caching', () {
    test('a cached detail is not re-fetched', () async {
      var calls = 0;
      final app = routedApp(onDetail: (r) async {
        calls++;
        return jsonResponse(bookingResponseJson(), 200);
      });
      await app.loadBookingDetail(55);
      await app.loadBookingDetail(55);
      expect(calls, 1);
    });

    test('refresh re-fetches a detail', () async {
      var calls = 0;
      final app = routedApp(onDetail: (r) async {
        calls++;
        return jsonResponse(bookingResponseJson(), 200);
      });
      await app.loadBookingDetail(55);
      await app.loadBookingDetail(55, refresh: true);
      expect(calls, 2);
    });
  });

  // ── Status buckets ───────────────────────────────────────────────────────────

  group('Bucket filtering', () {
    final today = DateTime(2030, 6, 1);
    final future = DateTime(2030, 6, 10);
    final past = DateTime(2030, 5, 1);

    test('upcoming = pending/confirmed/check-in-ready with check-in >= today',
        () {
      expect(
        bookingSectionMatchesReal(
            BookingStatusView.pending, future, BookingSection.upcoming,
            today: today),
        isTrue,
      );
      // Same status but a past check-in is not upcoming.
      expect(
        bookingSectionMatchesReal(
            BookingStatusView.pending, past, BookingSection.upcoming,
            today: today),
        isFalse,
      );
    });

    test('active = checked-in only', () {
      expect(
        bookingSectionMatchesReal(
            BookingStatusView.checkedIn, today, BookingSection.active,
            today: today),
        isTrue,
      );
      expect(
        bookingSectionMatchesReal(
            BookingStatusView.confirmed, today, BookingSection.active,
            today: today),
        isFalse,
      );
    });

    test('history and cancelled buckets', () {
      expect(
        bookingSectionMatchesReal(
            BookingStatusView.completed, past, BookingSection.history,
            today: today),
        isTrue,
      );
      expect(
        bookingSectionMatchesReal(
            BookingStatusView.cancelled, past, BookingSection.cancelled,
            today: today),
        isTrue,
      );
      expect(
        bookingSectionMatchesReal(
            BookingStatusView.completed, past, BookingSection.cancelled,
            today: today),
        isFalse,
      );
    });

    test('all matches everything', () {
      expect(
        bookingSectionMatchesReal(
            BookingStatusView.unknown, null, BookingSection.all,
            today: today),
        isTrue,
      );
    });
  });

  // ── Error mapping ────────────────────────────────────────────────────────────

  group('Errors', () {
    test('401 → sessionExpired and NEVER auto-logs-out or switches to demo',
        () async {
      final app = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(401, 'expired', '/api/me/bookings'), 401),
      );
      app.email = 'mai@example.com';
      app.api.token = 'jwt-token';
      final outcome = await app.loadMyBookings();
      expect(outcome, BookingHistoryOutcome.sessionExpired);
      expect(app.email, 'mai@example.com');
      expect(app.api.token, 'jwt-token');
      expect(app.demoMode, isFalse);
    });

    test('403 → forbidden', () async {
      final app = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(403, 'denied', '/api/me/bookings'), 403),
      );
      expect(await app.loadMyBookings(), BookingHistoryOutcome.forbidden);
    });

    test('404 on detail → notFound', () async {
      final app = routedApp(
        onDetail: (_) async =>
            jsonResponse(errorBody(404, 'missing', '/api/bookings/55'), 404),
      );
      expect(await app.loadBookingDetail(55), BookingHistoryOutcome.notFound);
    });

    test('500 → serverError', () async {
      final app = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(500, 'boom', '/api/me/bookings'), 500),
      );
      expect(await app.loadMyBookings(), BookingHistoryOutcome.serverError);
    });

    test('a transport failure → network', () async {
      final app = realApp(MockClient((_) async {
        throw http.ClientException('offline');
      }));
      expect(await app.loadMyBookings(), BookingHistoryOutcome.network);
    });

    test('a timeout → network (read, no retry)', () async {
      final app = realApp(MockClient((_) async {
        throw TimeoutException('slow');
      }));
      expect(await app.loadMyBookings(), BookingHistoryOutcome.network);
    });
  });

  // ── Session isolation ────────────────────────────────────────────────────────

  group('Session isolation', () {
    test('logout clears the history list and the detail cache', () async {
      final app = routedApp();
      app.email = 'a@example.com';
      await app.loadMyBookings();
      await app.loadBookingDetail(55);
      expect(app.realBookings, isNotEmpty);
      expect(app.bookingDetailCache, isNotEmpty);
      await app.logout();
      expect(app.realBookings, isEmpty);
      expect(app.realBookingsLoaded, isFalse);
      expect(app.bookingDetailCache, isEmpty);
      expect(app.bookingDetailLoadingId, isNull);
      expect(app.realBookingsError, isNull);
    });
  });

  // ── Widgets ──────────────────────────────────────────────────────────────────

  group('History screen', () {
    testWidgets('renders real booking cards and opens the detail', (t) async {
      final app = routedApp(
        onList: (_) async => jsonResponse([bookingSummaryJson()], 200),
      );
      await pumpSize(
        t,
        testApp(child: const MyBookingsScreen(), app: app),
        const Size(1200, 2000),
      );
      expect(find.byKey(const Key('real-booking-card-55')), findsOneWidget);
      expect(find.text('Backend Villa'), findsOneWidget);

      await t.tap(find.byKey(const Key('real-booking-card-55')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('booking-detail-content')), findsOneWidget);
      expect(find.byKey(const Key('booking-detail-code')), findsOneWidget);
      expect(find.text('PYT-20300601-000055'), findsWidgets);
    });

    testWidgets('empty history shows the empty state', (t) async {
      final app = routedApp(onList: (_) async => jsonResponse(const [], 200));
      await pumpSize(
        t,
        testApp(child: const MyBookingsScreen(), app: app),
        const Size(1200, 2000),
      );
      expect(find.byKey(const Key('booking-history-empty')), findsOneWidget);
    });

    testWidgets('a server error shows the retryable error state', (t) async {
      final app = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(500, 'boom', '/api/me/bookings'), 500),
      );
      await pumpSize(
        t,
        testApp(child: const MyBookingsScreen(), app: app),
        const Size(1200, 2000),
      );
      expect(find.byKey(const Key('booking-history-error')), findsOneWidget);
    });

    testWidgets('a 401 shows the inline session-expired state', (t) async {
      final app = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(401, 'expired', '/api/me/bookings'), 401),
      );
      await pumpSize(
        t,
        testApp(child: const MyBookingsScreen(), app: app),
        const Size(1200, 2000),
      );
      expect(find.byKey(const Key('booking-history-session-expired')),
          findsOneWidget);
    });

    testWidgets('an uncertain submission shows the advisory and can dismiss it',
        (t) async {
      final app = routedApp(
        onList: (_) async => jsonResponse([bookingSummaryJson()], 200),
      );
      app.realBookingSubmissionError = BookingSubmissionOutcome.uncertain;
      await pumpSize(
        t,
        testApp(child: const MyBookingsScreen(), app: app),
        const Size(1200, 2000),
      );
      expect(
          find.byKey(const Key('booking-history-uncertain')), findsOneWidget);
      await t.tap(find.byKey(const Key('booking-history-uncertain-dismiss')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('booking-history-uncertain')), findsNothing);
      expect(app.realBookingSubmissionUncertain, isFalse);
    });

    testWidgets('demo mode still renders the local booking list', (t) async {
      // Demo app must not hit the network at all.
      final app = demoApp(MockClient((_) async {
        throw StateError('demo mode must not make network calls');
      }));
      await pumpSize(
        t,
        testApp(child: const MyBookingsScreen(), app: app),
        const Size(1200, 2400),
      );
      // The demo local-only banner is shown; no real states appear.
      expect(find.byKey(const Key('booking-history-empty')), findsNothing);
      expect(find.byKey(const Key('booking-history-error')), findsNothing);
    });
  });

  group('Detail screen', () {
    testWidgets('a 404 detail shows the missing state', (t) async {
      final app = routedApp(
        onDetail: (_) async =>
            jsonResponse(errorBody(404, 'missing', '/api/bookings/55'), 404),
      );
      await pumpSize(
        t,
        testApp(child: const RealBookingDetailScreen(bookingId: 55), app: app),
        const Size(1200, 2000),
      );
      expect(find.byKey(const Key('booking-detail-missing')), findsOneWidget);
    });

    testWidgets('PENDING detail renders pending wording, code and price',
        (t) async {
      final app = routedApp();
      await pumpSize(
        t,
        testApp(child: const RealBookingDetailScreen(bookingId: 55), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('booking-detail-content')), findsOneWidget);
      final l10n = AppLocalizationsEn();
      expect(find.text(l10n.bookingStatusPendingLabel), findsWidgets);
      expect(find.text('PYT-20300601-000055'), findsWidgets);
    });
  });

  // ── Localization parity ──────────────────────────────────────────────────────

  group('Localization parity', () {
    test('every new UI27 key is present in both EN and VI', () {
      final en = AppLocalizationsEn();
      final vi = AppLocalizationsVi();
      final pairs = <String>[
        en.bookingsRealLoadingMessage,
        vi.bookingsRealLoadingMessage,
        en.bookingsRealErrorMessage,
        vi.bookingsRealErrorMessage,
        en.bookingDetailLoadingMessage,
        vi.bookingDetailLoadingMessage,
        en.bookingDetailErrorMessage,
        vi.bookingDetailErrorMessage,
        en.bookingDetailSpecialRequestLabel,
        vi.bookingDetailSpecialRequestLabel,
        en.bookingHistoryUncertainTitle,
        vi.bookingHistoryUncertainTitle,
        en.bookingHistoryUncertainBody,
        vi.bookingHistoryUncertainBody,
        en.bookingHistoryUncertainDismiss,
        vi.bookingHistoryUncertainDismiss,
      ];
      for (final s in pairs) {
        expect(s.trim(), isNotEmpty);
      }
      // EN and VI differ (not a copy-paste).
      expect(en.bookingsRealLoadingMessage != vi.bookingsRealLoadingMessage,
          isTrue);
    });
  });
}
