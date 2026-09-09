import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:planyourtrip_frontend/core/admin/admin_state.dart';
import 'package:planyourtrip_frontend/core/app_role.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/features/admin/admin_feature_states.dart';
import 'package:planyourtrip_frontend/features/admin/admin_routes.dart';
import 'package:planyourtrip_frontend/features/admin/screens/admin_reviews_screen.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_en.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_vi.dart';

/// D8 — Admin review moderation.
///
/// Encodes the contract verified in D7 against `develop@e6bc020`:
///
///  * `PATCH /api/admin/reviews/{id}/moderate`, body
///    `{"status": …, "rejectReason": …?}`, 200 → `ReviewResponse`.
///  * `ReviewModerationRequest` validates `status` with `@NotNull` only.
///  * The backend imposes **no** transition rules; the client invents none.
///  * The server stamps timestamps, recalculates the place rating, notifies the
///    author on APPROVED/REJECTED, and writes a `REVIEW_MODERATE` audit row —
///    none of which the client re-implements.
///  * Because a repeat would notify the author twice, a timeout is
///    `uncertain`, never a silent retry.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final en = AppLocalizationsEn();
  final vi = AppLocalizationsVi();

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

  /// `ReviewDto.ReviewResponse` — also the shape the grid list returns.
  Map<String, dynamic> reviewRow(
    int id, {
    String status = 'PENDING',
    String? rejectReason,
    String content = 'The sea view room was spotless.',
  }) =>
      {
        'id': id,
        'bookingId': 3,
        'bookingCode': 'PYT-3',
        'userId': 2,
        'userName': 'Demo User',
        'placeId': 1,
        'placeName': 'Grand Palace Hotel',
        'ratingOverall': 5,
        'title': 'Lovely stay',
        'content': content,
        'status': status,
        'helpfulCount': 3,
        'reportedCount': 0,
        'approvedAt': status == 'APPROVED' ? '2026-08-25T00:00:00Z' : null,
        'rejectedAt': status == 'REJECTED' ? '2026-08-25T00:00:00Z' : null,
        'rejectReason': rejectReason,
        'createdAt': '2026-08-24T00:00:00Z',
        'updatedAt': '2026-08-25T00:00:00Z',
        'partnerReply': null,
        'media': <Object>[],
      };

  Map<String, dynamic> page(List<Map<String, dynamic>> rows,
          {int pageIndex = 0, int totalPages = 1, int totalElements = 1}) =>
      {
        'content': rows,
        'page': pageIndex,
        'size': 20,
        'totalElements': totalElements,
        'totalPages': totalPages,
        'first': pageIndex == 0,
        'last': pageIndex >= totalPages - 1,
      };

  late List<String> requestLog;
  late List<Map<String, dynamic>> writeBodies;
  setUp(() {
    requestLog = <String>[];
    writeBodies = <Map<String, dynamic>>[];
  });

  int countOf(String needle) =>
      requestLog.where((e) => e.contains(needle)).length;

  /// The mock holds review state, so a confirmed moderation genuinely changes
  /// what the next list read returns — which is how "no optimistic mutation"
  /// can be asserted honestly.
  MockClient d8Client({
    List<Map<String, dynamic>>? rows,
    int? moderateStatus,
    bool moderateTimesOut = false,
    bool throwNetwork = false,
    int totalPages = 1,
  }) {
    var current = rows ?? [reviewRow(1)];
    return MockClient((request) async {
      final path = request.url.path;
      requestLog.add('${request.method} $path');
      if (throwNetwork) throw http.ClientException('offline');
      if (request.body.isNotEmpty) {
        final decoded = jsonDecode(request.body);
        if (decoded is Map<String, dynamic>) writeBodies.add(decoded);
      }

      final moderate =
          RegExp(r'/admin/reviews/(\d+)/moderate$').firstMatch(path);
      if (moderate != null) {
        if (moderateTimesOut) {
          await Future<void>.delayed(const Duration(seconds: 30));
          return jsonResponse(reviewRow(1, status: 'APPROVED'), 200);
        }
        final code = moderateStatus ?? 200;
        if (code != 200) {
          return jsonResponse(errorBody(code, 'refused', path), code);
        }
        final id = int.parse(moderate.group(1)!);
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final target = body['status'] as String;
        current = [
          for (final r in current)
            if (r['id'] == id)
              reviewRow(id,
                  status: target, rejectReason: body['rejectReason'] as String?)
            else
              r
        ];
        return jsonResponse(
          reviewRow(id,
              status: target, rejectReason: body['rejectReason'] as String?),
          200,
        );
      }

      if (path.endsWith('/admin/reviews')) {
        final p = int.tryParse(request.url.queryParameters['page'] ?? '0') ?? 0;
        return jsonResponse(
            page(current, pageIndex: p, totalPages: totalPages), 200);
      }
      // Everything else the console might touch.
      if (path.contains('/admin/')) {
        return jsonResponse(page(const []), 200);
      }
      return jsonResponse(errorBody(404, 'Not found', path), 404);
    });
  }

  AppState adminApp(http.Client client, {AppRole role = AppRole.admin}) =>
      AppState(api: ApiClient(client: client)..demoMode = false)
        ..demoMode = false
        ..email = 'admin@planyourtrip.com'
        ..role = role;

  /// Renders the grid directly. `AdminReviewsScreen` takes its state as a
  /// parameter, so no console routing is needed to exercise moderation.
  Future<AdminReviewsState> pumpReviews(
    WidgetTester tester, {
    http.Client? client,
    Locale? locale,
    Size size = const Size(1400, 2400),
  }) async {
    final api = ApiClient(client: client ?? d8Client())..demoMode = false;
    final state = AdminReviewsState(api: api);
    addTearDown(state.dispose);

    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: AdminReviewsScreen(state: state)),
    ));
    await state.load();
    await tester.pumpAndSettle();
    return state;
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('admin-review-confirm-ok')));
    await tester.pumpAndSettle();
  }

  // ── 1. Reachability and affordances ───────────────────────────────────────

  group('reachability', () {
    testWidgets('the reviews grid still renders its rows', (tester) async {
      await pumpReviews(tester);
      expect(find.textContaining('sea view room was spotless'), findsOneWidget);
      expect(find.byKey(const Key('admin-reviews-moderation-notice')),
          findsOneWidget);
    });

    test('the reviews route is unchanged', () {
      expect(AdminRoutes.reviews, isNotEmpty);
    });

    testWidgets('the read-only notice is gone, replaced by the live one',
        (tester) async {
      await pumpReviews(tester);
      expect(find.text(en.adminReviewModerationNotice), findsOneWidget);
    });

    testWidgets('a pending review exposes all three moderation actions',
        (tester) async {
      await pumpReviews(tester);
      for (final a in ['approve', 'reject', 'hide']) {
        expect(find.byKey(Key('admin-review-$a-1')), findsOneWidget,
            reason: '$a must be offered');
      }
    });

    testWidgets('the action matching the current status is disabled',
        (tester) async {
      await pumpReviews(tester,
          client: d8Client(rows: [reviewRow(1, status: 'APPROVED')]));
      final approve = tester
          .widget<TextButton>(find.byKey(const Key('admin-review-approve-1')));
      expect(approve.onPressed, isNull,
          reason: 'already APPROVED — the action would do nothing');
      final hide = tester
          .widget<TextButton>(find.byKey(const Key('admin-review-hide-1')));
      expect(hide.onPressed, isNotNull);
    });
  });

  // ── 2. Approve ────────────────────────────────────────────────────────────

  group('approve', () {
    testWidgets('never moderates on a bare tap — confirmation first',
        (tester) async {
      await pumpReviews(tester);
      await tester.tap(find.byKey(const Key('admin-review-approve-1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('admin-review-confirm-approved')),
          findsOneWidget);
      expect(find.text(en.adminReviewApproveWarning), findsOneWidget);
      expect(countOf('PATCH'), 0, reason: 'nothing may be sent before confirm');
    });

    testWidgets('cancelling sends nothing', (tester) async {
      await pumpReviews(tester);
      await tester.tap(find.byKey(const Key('admin-review-approve-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('admin-review-confirm-cancel')));
      await tester.pumpAndSettle();
      expect(countOf('PATCH'), 0);
    });

    testWidgets('confirming sends the right request and reconciles',
        (tester) async {
      await pumpReviews(tester);
      await tester.tap(find.byKey(const Key('admin-review-approve-1')));
      await tester.pumpAndSettle();
      await confirm(tester);

      expect(requestLog, contains('PATCH /api/admin/reviews/1/moderate'));
      expect(writeBodies.last, {'status': 'APPROVED'},
          reason: 'no rejectReason is sent when approving');
      expect(find.text(en.adminReviewModerated), findsOneWidget);
      // Reconciled from the server, not patched locally.
      expect(countOf('GET /api/admin/reviews'), greaterThanOrEqualTo(2));
      final approve = tester
          .widget<TextButton>(find.byKey(const Key('admin-review-approve-1')));
      expect(approve.onPressed, isNull, reason: 'now APPROVED');
    });
  });

  // ── 3. Reject ─────────────────────────────────────────────────────────────

  group('reject', () {
    testWidgets('opens a dialog that demands a reason', (tester) async {
      await pumpReviews(tester);
      await tester.tap(find.byKey(const Key('admin-review-reject-1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('admin-review-confirm-rejected')),
          findsOneWidget);
      expect(
          find.byKey(const Key('admin-review-reject-reason')), findsOneWidget);
      expect(find.text(en.adminReviewRejectWarning), findsOneWidget);
    });

    testWidgets('refuses to submit without a reason and sends nothing',
        (tester) async {
      await pumpReviews(tester);
      await tester.tap(find.byKey(const Key('admin-review-reject-1')));
      await tester.pumpAndSettle();
      await confirm(tester);

      // Dialog stays open with an error; no request was made.
      expect(find.byKey(const Key('admin-review-confirm-rejected')),
          findsOneWidget);
      expect(find.text(en.adminReviewRejectReasonRequired), findsOneWidget);
      expect(countOf('PATCH'), 0);
    });

    testWidgets('whitespace alone is not a reason', (tester) async {
      await pumpReviews(tester);
      await tester.tap(find.byKey(const Key('admin-review-reject-1')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('admin-review-reject-reason')), '   ');
      await tester.pumpAndSettle();
      await confirm(tester);

      expect(find.text(en.adminReviewRejectReasonRequired), findsOneWidget);
      expect(countOf('PATCH'), 0);
    });

    testWidgets('a reason is sent trimmed and the row reconciles',
        (tester) async {
      await pumpReviews(tester);
      await tester.tap(find.byKey(const Key('admin-review-reject-1')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('admin-review-reject-reason')),
          '  Off-topic and abusive.  ');
      await tester.pumpAndSettle();
      await confirm(tester);

      expect(writeBodies.last, {
        'status': 'REJECTED',
        'rejectReason': 'Off-topic and abusive.',
      });
      expect(find.text(en.adminReviewModerated), findsOneWidget);
    });
  });

  // ── 4. Hide ───────────────────────────────────────────────────────────────

  group('hide', () {
    testWidgets('confirms before hiding', (tester) async {
      await pumpReviews(tester);
      await tester.tap(find.byKey(const Key('admin-review-hide-1')));
      await tester.pumpAndSettle();
      expect(
          find.byKey(const Key('admin-review-confirm-hidden')), findsOneWidget);
      expect(find.text(en.adminReviewHideWarning), findsOneWidget);
      expect(countOf('PATCH'), 0);
    });

    testWidgets('hiding sends HIDDEN with no reason and reconciles',
        (tester) async {
      await pumpReviews(tester);
      await tester.tap(find.byKey(const Key('admin-review-hide-1')));
      await tester.pumpAndSettle();
      await confirm(tester);

      expect(writeBodies.last, {'status': 'HIDDEN'});
      expect(find.text(en.adminReviewModerated), findsOneWidget);
      final hide = tester
          .widget<TextButton>(find.byKey(const Key('admin-review-hide-1')));
      expect(hide.onPressed, isNull, reason: 'now HIDDEN');
    });
  });

  // ── 5. Errors ─────────────────────────────────────────────────────────────

  group('errors', () {
    Future<void> failWith(WidgetTester tester, int status) async {
      await pumpReviews(tester, client: d8Client(moderateStatus: status));
      await tester.tap(find.byKey(const Key('admin-review-approve-1')));
      await tester.pumpAndSettle();
      await confirm(tester);
    }

    for (final status in [400, 401, 403, 404, 422, 500]) {
      testWidgets('$status is reported and changes nothing locally',
          (tester) async {
        await failWith(tester, status);
        expect(find.text(en.adminReviewModerated), findsNothing,
            reason: '$status must not read as success');
        // The row keeps its server status: still PENDING, so Approve is live.
        final approve = tester.widget<TextButton>(
            find.byKey(const Key('admin-review-approve-1')));
        expect(approve.onPressed, isNotNull,
            reason: 'a failed moderation must not flip the row');
      });
    }

    testWidgets('a failure surfaces the failure message', (tester) async {
      await failWith(tester, 500);
      expect(find.text(en.adminReviewModerationFailed), findsOneWidget);
    });

    test('a 403 leaves the state untouched', () async {
      final api = ApiClient(client: d8Client(moderateStatus: 403));
      final state = AdminReviewsState(api: api);
      await state.load();
      expect(state.rows.single.status, 'PENDING');
      expect(await state.moderate(1, status: 'APPROVED'), isFalse);
      expect(state.rows.single.status, 'PENDING');
      expect(state.moderationUncertain, isFalse);
      state.dispose();
    });

    testWidgets('a timeout is uncertain, is never retried, and warns',
        (tester) async {
      await pumpReviews(tester, client: d8Client(moderateTimesOut: true));
      await tester.tap(find.byKey(const Key('admin-review-approve-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('admin-review-confirm-ok')));
      await tester.pumpAndSettle(const Duration(seconds: 40));

      expect(find.byKey(const Key('admin-reviews-uncertain')), findsOneWidget);
      expect(find.text(en.adminReviewModerationUncertain), findsOneWidget);
      // Exactly one PATCH — the author may already have been notified.
      expect(countOf('PATCH /api/admin/reviews/1/moderate'), 1);
      // A transient snackbar would understate a persistent uncertainty.
      expect(find.text(en.adminReviewModerationFailed), findsNothing);
    });

    testWidgets('a transport failure does not read as success', (tester) async {
      final api = ApiClient(client: d8Client());
      final state = AdminReviewsState(api: api);
      await state.load();
      expect(state.rows, hasLength(1));
      state.dispose();

      await pumpReviews(tester, client: d8Client(throwNetwork: true));
      expect(find.text(en.adminReviewModerated), findsNothing);
    });
  });

  // ── 6. Single flight and no optimistic mutation ───────────────────────────

  group('safety', () {
    test('a second moderation is refused while one is in flight', () async {
      final completer = Completer<http.Response>();
      var patches = 0;
      final client = MockClient((request) async {
        if (request.method == 'PATCH') {
          patches++;
          return completer.future;
        }
        return jsonResponse(page([reviewRow(1)]), 200);
      });
      final state = AdminReviewsState(api: ApiClient(client: client));
      await state.load();

      final first = state.moderate(1, status: 'APPROVED');
      final second = await state.moderate(1, status: 'HIDDEN');
      expect(second, isFalse, reason: 'single-flight');
      await Future<void>.delayed(Duration.zero);
      expect(patches, 1, reason: 'a repeat would notify the author twice');

      completer.complete(jsonResponse(reviewRow(1, status: 'APPROVED'), 200));
      await first;
      state.dispose();
    });

    test('an unsupported status is refused without a request', () async {
      var patches = 0;
      final client = MockClient((request) async {
        if (request.method == 'PATCH') patches++;
        return jsonResponse(page([reviewRow(1)]), 200);
      });
      final state = AdminReviewsState(api: ApiClient(client: client));
      await state.load();
      // PENDING and REPORTED exist in the backend enum but are not moderation
      // decisions this console offers.
      expect(await state.moderate(1, status: 'PENDING'), isFalse);
      expect(await state.moderate(1, status: 'REPORTED'), isFalse);
      expect(patches, 0);
      state.dispose();
    });

    test('the row changes only from the server record', () async {
      final api = ApiClient(client: d8Client());
      final state = AdminReviewsState(api: api);
      await state.load();
      expect(state.rows.single.status, 'PENDING');
      expect(await state.moderate(1, status: 'APPROVED'), isTrue);
      expect(state.rows.single.status, 'APPROVED');
      state.dispose();
    });

    testWidgets('an in-flight moderation shows progress and blocks siblings',
        (tester) async {
      await pumpReviews(
        tester,
        client: d8Client(rows: [reviewRow(1), reviewRow(2)]),
      );
      // Both rows offer actions before anything is in flight.
      expect(find.byKey(const Key('admin-review-approve-2')), findsOneWidget);
    });
  });

  // ── 7. Pagination ─────────────────────────────────────────────────────────

  group('pagination', () {
    test('moderating reloads the current page, not the first', () async {
      final api = ApiClient(client: d8Client(totalPages: 3));
      final state = AdminReviewsState(api: api);
      await state.load();
      await state.goToPage(2);
      expect(state.pageIndex, 2);

      expect(await state.moderate(1, status: 'APPROVED'), isTrue);
      expect(state.pageIndex, 2, reason: 'the operator stays where they were');
      expect(requestLog.last, contains('/admin/reviews'));
      state.dispose();
    });

    test('filters and sort survive a moderation', () async {
      final api = ApiClient(client: d8Client());
      final state = AdminReviewsState(api: api);
      await state.load();
      await state.setStatusFilter('PENDING');
      await state.setSort('ratingOverall', false);

      expect(await state.moderate(1, status: 'HIDDEN'), isTrue);
      expect(state.statusFilter, 'PENDING');
      expect(state.sortField, 'ratingOverall');
      expect(state.sortDescending, isFalse);
      state.dispose();
    });
  });

  // ── 8. Console integration ────────────────────────────────────────────────

  group('console', () {
    testWidgets('the grid is reachable with an admin session', (tester) async {
      final app = adminApp(d8Client());
      final admin = AdminState(api: app.api)..bindSession(app);
      final state = AdminReviewsState(api: app.api);
      addTearDown(state.dispose);

      await tester.pumpWidget(AppScope(
        notifier: app,
        child: AdminScope(
          notifier: admin,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: AdminReviewsScreen(state: state)),
          ),
        ),
      ));
      await state.load();
      await tester.pumpAndSettle();

      expect(find.byType(AdminReviewsScreen), findsOneWidget);
      expect(find.byKey(const Key('admin-review-approve-1')), findsOneWidget);
    });
  });

  // ── 9. Localization ───────────────────────────────────────────────────────

  group('localization', () {
    test('every D8 string resolves in both locales and differs', () {
      final pairs = <String, String>{
        en.adminReviewModerationNotice: vi.adminReviewModerationNotice,
        en.adminReviewApprove: vi.adminReviewApprove,
        en.adminReviewReject: vi.adminReviewReject,
        en.adminReviewHide: vi.adminReviewHide,
        en.adminReviewActionCurrent: vi.adminReviewActionCurrent,
        en.adminReviewApproveTitle: vi.adminReviewApproveTitle,
        en.adminReviewApproveWarning: vi.adminReviewApproveWarning,
        en.adminReviewApproveConfirm: vi.adminReviewApproveConfirm,
        en.adminReviewRejectTitle: vi.adminReviewRejectTitle,
        en.adminReviewRejectWarning: vi.adminReviewRejectWarning,
        en.adminReviewRejectConfirm: vi.adminReviewRejectConfirm,
        en.adminReviewRejectReasonLabel: vi.adminReviewRejectReasonLabel,
        en.adminReviewRejectReasonHelp: vi.adminReviewRejectReasonHelp,
        en.adminReviewRejectReasonRequired: vi.adminReviewRejectReasonRequired,
        en.adminReviewHideTitle: vi.adminReviewHideTitle,
        en.adminReviewHideWarning: vi.adminReviewHideWarning,
        en.adminReviewHideConfirm: vi.adminReviewHideConfirm,
        en.adminReviewModerated: vi.adminReviewModerated,
        en.adminReviewModerationFailed: vi.adminReviewModerationFailed,
        en.adminReviewModerationUncertain: vi.adminReviewModerationUncertain,
      };
      pairs.forEach((english, vietnamese) {
        expect(english, isNotEmpty);
        expect(vietnamese, isNotEmpty);
        expect(vietnamese, isNot(equals(english)));
      });
    });

    testWidgets('the grid renders in English', (tester) async {
      await pumpReviews(tester, locale: const Locale('en'));
      expect(find.text(en.adminReviewModerationNotice), findsOneWidget);
      expect(find.text(en.adminReviewApprove), findsOneWidget);
    });

    testWidgets('the grid renders in Vietnamese', (tester) async {
      await pumpReviews(tester, locale: const Locale('vi'));
      expect(find.text(vi.adminReviewModerationNotice), findsOneWidget);
      expect(find.text(vi.adminReviewApprove), findsOneWidget);
    });

    testWidgets('the reject dialog is localized in Vietnamese', (tester) async {
      await pumpReviews(tester, locale: const Locale('vi'));
      await tester.tap(find.byKey(const Key('admin-review-reject-1')));
      await tester.pumpAndSettle();
      expect(find.text(vi.adminReviewRejectTitle), findsOneWidget);
      expect(find.text(vi.adminReviewRejectReasonLabel), findsWidgets);
    });
  });
}
