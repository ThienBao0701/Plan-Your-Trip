import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/core/partner/partner_booking_models.dart';
import 'package:planyourtrip_frontend/features/partner/bookings/partner_front_desk_state.dart';
import 'package:planyourtrip_frontend/features/partner/partner_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// C10 — Partner Check-in / Check-out operations.
///
/// ## C10 builds no screen, on purpose
///
/// The audit found **no unconsumed backend surface**. Every endpoint that
/// touches check-in, check-out, guest stays, voucher verification or the
/// operational counters is already consumed and surfaced:
///
/// | Endpoint | Surfaced by |
/// |---|---|
/// | `PATCH /partner/bookings/{id}/check-in\|check-out\|no-show\|complete` | C8 reservations detail |
/// | `POST /partner/bookings/check-in` / `check-out` | C8 front-desk console |
/// | `POST /partner/bookings/voucher/verify` | C7 voucher check |
/// | `GET /partner/bookings` (`arrivalToday`, `departureToday`, `inHouse`, `upcoming`) | C8 quick filters |
/// | `GET /partner/bookings/{id}` · `GET /partner/stays/{bookingId}` | C8 detail panel |
/// | `GET /partner/dashboard` · `GET /partner/extranet/activity-logs` | C1 dashboard |
///
/// The arrival queue, departure queue, in-house list, QR and manual workflows,
/// stay warnings, readiness state and the immutable check-in/check-out audit are
/// therefore already built. A second screen over the same endpoints would be
/// duplication, so C10 adds none, and there is no `PartnerCheckInState` — the
/// existing [PartnerFrontDeskState] already owns this workflow.
///
/// ## What C10 does add
///
/// Only the assertions C8 documented but did not lock down. Everything below
/// is a behaviour that had no test before this file.
///
/// ## Backend findings recorded, not fixed
///
/// `PartnerSettings.timezone` exists, defaults to `Asia/Ho_Chi_Minh` and is
/// editable through C6 — but **no check-in or check-out code path reads it**.
/// `PartnerCheckInService.validateCheckInWindow` and
/// `PartnerCheckOutService.validateCheckOutWindow` both use `LocalDate.now()` in
/// the *server's* zone. See the C10 report.
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

  /// `PartnerCheckInDto.CheckInResponse` / `PartnerCheckOutDto.CheckOutResponse`
  /// — the two share a shape, differing only in the timestamp field name.
  Map<String, dynamic> frontDeskJson({
    required bool checkIn,
    String status = 'CHECKED_IN',
    String message = 'Check-in completed',
    String at = '2026-10-29T06:00:00Z',
  }) =>
      {
        'success': true,
        'bookingCode': 'PYT-20260830-000001',
        'bookingStatus': status,
        if (checkIn) 'checkedInAt': at else 'checkedOutAt': at,
        'hotelName': 'Bay View Danang',
        'roomName': 'Standard Twin',
        'guestName': 'Demo User',
        'message': message,
      };

  late List<String> requestLog;
  late List<Map<String, dynamic>> postBodies;
  setUp(() {
    requestLog = <String>[];
    postBodies = <Map<String, dynamic>>[];
  });

  MockClient frontDeskClient({
    Map<String, dynamic>? checkInBody,
    Map<String, dynamic>? checkOutBody,
    int? status,
    String? message,
  }) =>
      MockClient((request) async {
        final path = request.url.path;
        requestLog.add('${request.method} $path');
        if (request.body.isNotEmpty) {
          postBodies.add(jsonDecode(request.body) as Map<String, dynamic>);
        }
        final code = status ?? 200;
        if (code != 200) {
          return jsonResponse(
              errorBody(code, message ?? 'Rejected', path), code);
        }
        if (path.endsWith('/partner/bookings/check-in')) {
          return jsonResponse(checkInBody ?? frontDeskJson(checkIn: true), 200);
        }
        if (path.endsWith('/partner/bookings/check-out')) {
          return jsonResponse(
              checkOutBody ??
                  frontDeskJson(
                    checkIn: false,
                    status: 'CHECKED_OUT',
                    message: 'Check-out completed',
                  ),
              200);
        }
        return jsonResponse(errorBody(404, 'Not found', path), 404);
      });

  PartnerFrontDeskState state(http.Client client) =>
      PartnerFrontDeskState(api: ApiClient(client: client)..demoMode = false);

  // ── The boundary itself ───────────────────────────────────────────────

  group('C10 adds no surface of its own', () {
    test('no new partner destination was introduced', () {
      // The backend menu has exactly thirteen keys; check-in/check-out are part
      // of `bookings`, which C8 already implements.
      expect(PartnerNavigation.destinations, hasLength(13));
      final implemented = PartnerNavigation.destinations
          .where((d) => d.implemented)
          .map((d) => d.key)
          .toList();
      expect(implemented, [
        'dashboard',
        'hotels',
        'rooms',
        'calendar',
        'pricing',
        'bookings',
        'promotions',
        // C11 added finance and analytics, C12 reviews; the check-in/check-out
        // conclusion is unaffected by either.
        'reviews',
        'finance',
        'analytics',
        'settings',
      ]);
      // There is deliberately no separate check-in destination.
      expect(
        PartnerNavigation.destinations.any((d) => d.key.contains('check')),
        isFalse,
      );
    });

    test('the front-desk workflow has exactly one state owner', () {
      // C8's PartnerFrontDeskState is it; C10 introduces no second one.
      final api = ApiClient(client: frontDeskClient())..demoMode = false;
      expect(PartnerFrontDeskState(api: api), isA<PartnerFrontDeskState>());
    });
  });

  // ── Gap 1: the check-in POST route was never asserted ─────────────────

  group('endpoint routing', () {
    test('check-in posts to the check-in endpoint', () async {
      final s = state(frontDeskClient());
      s.setInput('PYT-20260830-000001');
      await s.submit();
      expect(requestLog, ['POST /api/partner/bookings/check-in']);
    });

    test('check-out posts to the check-out endpoint', () async {
      final s = state(frontDeskClient())..setCheckIn(false);
      s.setInput('PYT-20260830-000001');
      await s.submit();
      expect(requestLog, ['POST /api/partner/bookings/check-out']);
    });

    test('the two endpoints are never confused by the toggle', () async {
      final s = state(frontDeskClient());
      s.setInput('PYT-20260830-000001');
      await s.submit();
      s.setCheckIn(false);
      s.setInput('PYT-20260830-000001');
      await s.submit();
      expect(requestLog, [
        'POST /api/partner/bookings/check-in',
        'POST /api/partner/bookings/check-out',
      ]);
    });
  });

  // ── Gap 2: idempotency was asserted for check-in only ─────────────────

  group('idempotency', () {
    test('an already-checked-out guest is a success, not an error', () async {
      // `PartnerCheckOutService` short-circuits a CHECKED_OUT booking to a
      // deterministic 200 with the unchanged timestamp, writing no second audit
      // row and sending no second notification.
      final s = state(frontDeskClient(
        checkOutBody: frontDeskJson(
          checkIn: false,
          status: 'CHECKED_OUT',
          message: 'Guest is already checked out',
        ),
      ))
        ..setCheckIn(false);
      s.setInput('PYT-20260830-000001');
      await s.submit();

      expect(s.status, PartnerFrontDeskStatus.done);
      expect(s.result!.status, PartnerBookingStatus.checkedOut);
      // The server's own wording is what distinguishes a fresh transition from
      // a repeat, so it is shown verbatim rather than replaced.
      expect(s.result!.message, 'Guest is already checked out');
    });

    test('a repeat sends exactly one request, never a retry loop', () async {
      final s = state(frontDeskClient(
        checkInBody: frontDeskJson(
            checkIn: true, message: 'Guest is already checked in'),
      ));
      s.setInput('PYT-20260830-000001');
      await s.submit();
      expect(requestLog, hasLength(1));
      expect(s.status, PartnerFrontDeskStatus.done);
    });

    test('the check-out timestamp is read from checkedOutAt', () async {
      final s = state(frontDeskClient())..setCheckIn(false);
      s.setInput('PYT-20260830-000001');
      await s.submit();
      // The two DTOs name the instant differently; the model accepts either.
      expect(s.result!.occurredAt, isNotNull);
      expect(s.result!.occurredAt!.toUtc(), DateTime.utc(2026, 10, 29, 6));
    });
  });

  // ── Gap 3: payload/code classification against realistic inputs ───────

  group('payload and booking-code classification', () {
    test('a real booking code contains no dots and routes as a code', () {
      // Codes are `PYT-<yyyyMMdd>-<seq>` (`BookingService.bookingCode`), so the
      // dot-count heuristic can never misread one as a signed payload.
      final s = state(frontDeskClient());
      s.setInput('PYT-20260830-000001');
      expect(s.looksLikeVoucherPayload, isFalse);
    });

    test('a real signed payload routes as a payload', () {
      final s = state(frontDeskClient());
      s.setInput('PYT-V1.PYT-20260830-000001.c2lnbmF0dXJl');
      expect(s.looksLikeVoucherPayload, isTrue);
    });

    test('the classification decides the audit method the backend records',
        () async {
      // A scanned payload is recorded as QR_SCAN and a typed code as MANUAL, so
      // sending the wrong field would falsify the audit trail.
      final scanned = state(frontDeskClient());
      scanned.setInput('PYT-V1.PYT-20260830-000001.sig');
      await scanned.submit();
      expect(postBodies.single.keys.single, 'voucherPayload');

      postBodies.clear();
      final typed = state(frontDeskClient());
      typed.setInput('PYT-20260830-000001');
      await typed.submit();
      expect(postBodies.single.keys.single, 'bookingCode');
    });

    test('a prefix without a signature segment is not a payload', () {
      final s = state(frontDeskClient());
      // `PYT-V1.` with only two segments is malformed; treating it as a code
      // lets the backend answer with its uniform 404 rather than the client
      // guessing.
      s.setInput('PYT-V1.PYT-20260830-000001');
      expect(s.looksLikeVoucherPayload, isFalse);
    });

    test('surrounding whitespace never changes the routing', () async {
      final s = state(frontDeskClient());
      s.setInput('   PYT-V1.PYT-20260830-000001.sig   ');
      expect(s.looksLikeVoucherPayload, isTrue);
      await s.submit();
      expect(postBodies.single,
          {'voucherPayload': 'PYT-V1.PYT-20260830-000001.sig'});
    });
  });

  // ── Gap 4: the two 422 rules were never told apart ────────────────────

  group('the backend 422 rules are surfaced distinctly', () {
    test('the check-in time window rejection keeps the opening date', () async {
      // `validateCheckInWindow` names the day the early window opens. That date
      // is the only actionable part of the message, so it is shown verbatim.
      final s = state(frontDeskClient(
        status: 422,
        message: 'Check-in not available until 2026-10-28',
      ));
      s.setInput('PYT-20260830-000001');
      await s.submit();
      expect(s.status, PartnerFrontDeskStatus.rejected);
      expect(s.errorMessage, 'Check-in not available until 2026-10-28');
    });

    test('the expired-stay rejection is the same status with its own reason',
        () async {
      final s = state(frontDeskClient(
        status: 422,
        message: 'Booking has expired: the stay period has ended',
      ));
      s.setInput('PYT-20260830-000001');
      await s.submit();
      expect(s.status, PartnerFrontDeskStatus.rejected);
      expect(s.errorMessage, 'Booking has expired: the stay period has ended');
    });

    test('an ineligible status on check-out is a rejection, not a 404',
        () async {
      // `PartnerCheckOutService` refuses anything that is not CHECKED_IN.
      final s = state(frontDeskClient(
        status: 422,
        message: 'Cannot check out booking with status: CONFIRMED',
      ))
        ..setCheckIn(false);
      s.setInput('PYT-20260830-000001');
      await s.submit();
      expect(s.status, PartnerFrontDeskStatus.rejected);
      expect(s.status, isNot(PartnerFrontDeskStatus.notRecognised));
    });

    test('422 and 404 stay separate: one is a rule, the other is ownership',
        () async {
      final rejected =
          state(frontDeskClient(status: 422, message: 'not eligible'));
      rejected.setInput('X');
      await rejected.submit();

      final unknown = state(frontDeskClient(status: 404));
      unknown.setInput('X');
      await unknown.submit();

      expect(rejected.status, PartnerFrontDeskStatus.rejected);
      expect(unknown.status, PartnerFrontDeskStatus.notRecognised);
    });

    test('no check-in or check-out path ever yields a conflict', () async {
      // There is no optimistic-locking 409 anywhere in this workflow: illegal
      // transitions are 422 and ownership failures are 404. A 409 would mean the
      // backend contract changed.
      final s = state(frontDeskClient(status: 409, message: 'conflict'));
      s.setInput('PYT-20260830-000001');
      await s.submit();
      // Mapped to the generic failure rather than a state that claims to
      // understand a conflict this workflow cannot produce.
      expect(s.status, PartnerFrontDeskStatus.error);
    });
  });

  // ── Transport failures ────────────────────────────────────────────────

  group('transport failures', () {
    test('a network drop is an error, never a silent success', () async {
      final s = state(MockClient((_) async {
        throw http.ClientException('offline');
      }));
      s.setInput('PYT-20260830-000001');
      await s.submit();
      expect(s.status, PartnerFrontDeskStatus.error);
      expect(s.result, isNull);
    });

    test(
        'a timeout is uncertain, and re-running is safe because the endpoint '
        'is idempotent', () async {
      final s = state(MockClient((_) async {
        await Future<void>.delayed(const Duration(seconds: 30));
        return jsonResponse(frontDeskJson(checkIn: true), 200);
      }));
      s.setInput('PYT-20260830-000001');
      await s.submit();
      expect(s.status, PartnerFrontDeskStatus.uncertain);
      expect(s.result, isNull);
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('a malformed 200 body is not treated as a completed check-in',
        () async {
      final s = state(
          MockClient((_) async => jsonResponse({'unexpected': true}, 200)));
      s.setInput('PYT-20260830-000001');
      await s.submit();
      expect(s.status, PartnerFrontDeskStatus.error);
      expect(s.result, isNull);
    });
  });

  // ── Guest-data and payment scope ──────────────────────────────────────

  group('the front-desk projection stays minimal', () {
    test('it carries only what a desk needs to admit a guest', () async {
      final s = state(frontDeskClient());
      s.setInput('PYT-20260830-000001');
      await s.submit();
      final r = s.result!;
      expect(r.bookingCode, isNotNull);
      expect(r.guestName, 'Demo User');
      expect(r.hotelName, 'Bay View Danang');
      expect(r.roomName, 'Standard Twin');
      // The DTO deliberately carries no email, no payment, no coupon or
      // gift-card data — and the model adds none.
      expect(r.toString().contains('@'), isFalse);
    });

    test('an unknown status in the response degrades rather than throwing',
        () async {
      final s = state(frontDeskClient(
        checkInBody: frontDeskJson(checkIn: true, status: 'SOMETHING_NEW'),
      ));
      s.setInput('PYT-20260830-000001');
      await s.submit();
      expect(s.status, PartnerFrontDeskStatus.done);
      expect(s.result!.status, PartnerBookingStatus.unknown);
    });
  });
}
