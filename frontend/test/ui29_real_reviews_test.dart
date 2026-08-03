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
import 'package:planyourtrip_frontend/features/bookings/real_booking_detail_screen.dart';
import 'package:planyourtrip_frontend/features/reviews/real_my_reviews_screen.dart';
import 'package:planyourtrip_frontend/features/reviews/real_place_reviews_screen.dart';
import 'package:planyourtrip_frontend/features/reviews/real_write_review_screen.dart';
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

  Map<String, dynamic> reviewSummaryJson({
    int id = 77,
    String status = 'APPROVED',
    int placeId = 7,
    String userName = 'Mai Nguyen',
    int ratingOverall = 4,
    String? title = 'Lovely stay',
    Map<String, dynamic>? partnerReply,
    List<Map<String, dynamic>>? media,
  }) =>
      {
        'id': id,
        'placeId': placeId,
        'placeName': 'Backend Villa',
        'userId': 9,
        'userName': userName,
        'ratingOverall': ratingOverall,
        'title': title,
        'status': status,
        'createdAt': '2030-05-01T10:00:00Z',
        'partnerReply': partnerReply,
        'media': media ?? const [],
      };

  Map<String, dynamic> reviewResponseJson({
    int id = 77,
    String status = 'PENDING',
    int bookingId = 55,
  }) =>
      {
        'id': id,
        'bookingId': bookingId,
        'bookingCode': 'PYT-20300601-000055',
        'userId': 9,
        'userName': 'Mai Nguyen',
        'placeId': 7,
        'placeName': 'Backend Villa',
        'ratingOverall': 4,
        'ratingCleanliness': 5,
        'ratingService': 4,
        'ratingLocation': 5,
        'ratingValue': 4,
        'ratingFacilities': 3,
        'title': 'Lovely stay',
        'content': 'Great place.',
        'status': status,
        'helpfulCount': 0,
        'reportedCount': 0,
        'approvedAt': status == 'APPROVED' ? '2030-05-02T10:00:00Z' : null,
        'rejectedAt': null,
        'rejectReason': null,
        'createdAt': '2030-05-01T10:00:00Z',
        'updatedAt': '2030-05-01T10:00:00Z',
        'partnerReply': null,
        'media': const [],
      };

  Map<String, dynamic> bookingDetailJson({String status = 'COMPLETED'}) => {
        'id': 55,
        'bookingCode': 'PYT-20300601-000055',
        'hotelId': 7,
        'hotelName': 'Backend Villa',
        'roomId': 100,
        'roomName': 'Deluxe Garden View',
        'checkIn': '2030-06-01',
        'checkOut': '2030-06-04',
        'nights': 3,
        'adults': 2,
        'children': 0,
        'numberOfRooms': 1,
        'status': status,
        'currency': 'VND',
        'finalPrice': 3300000,
      };

  bool placeReviewsPath(http.Request r) =>
      r.method == 'GET' && RegExp(r'/places/\d+/reviews$').hasMatch(r.url.path);
  bool myReviewsPath(http.Request r) =>
      r.method == 'GET' && r.url.path.endsWith('/me/reviews');
  bool getReviewPath(http.Request r) =>
      r.method == 'GET' && RegExp(r'/reviews/\d+$').hasMatch(r.url.path);
  bool createReviewPath(http.Request r) =>
      r.method == 'POST' && r.url.path.endsWith('/reviews');
  bool bookingDetailPath(http.Request r) =>
      r.method == 'GET' && RegExp(r'/bookings/\d+$').hasMatch(r.url.path);

  AppState routedApp({
    Future<http.Response> Function(http.Request)? onPlaceList,
    Future<http.Response> Function(http.Request)? onMyList,
    Future<http.Response> Function(http.Request)? onGet,
    Future<http.Response> Function(http.Request)? onCreate,
    Future<http.Response> Function(http.Request)? onBookingDetail,
    void Function(http.Request)? onRequest,
  }) =>
      realApp(MockClient((request) async {
        onRequest?.call(request);
        if (placeReviewsPath(request)) {
          return (onPlaceList ??
              (_) async => jsonResponse([reviewSummaryJson()], 200))(request);
        }
        if (myReviewsPath(request)) {
          return (onMyList ??
              (_) async => jsonResponse(
                  [reviewSummaryJson(status: 'PENDING')], 200))(request);
        }
        if (getReviewPath(request)) {
          return (onGet ??
              (_) async => jsonResponse(reviewResponseJson(), 200))(request);
        }
        if (createReviewPath(request)) {
          return (onCreate ??
              (_) async => jsonResponse(reviewResponseJson(), 201))(request);
        }
        if (bookingDetailPath(request)) {
          return (onBookingDetail ??
              (_) async => jsonResponse(bookingDetailJson(), 200))(request);
        }
        return jsonResponse(const <Map<String, dynamic>>[], 200);
      }));

  // ── Contract parsing ───────────────────────────────────────────────────────

  group('Contract parsing', () {
    test('getPlaceReviews GETs /api/places/{id}/reviews as a bare array',
        () async {
      http.Request? captured;
      final app = routedApp(onRequest: (r) {
        if (placeReviewsPath(r)) captured = r;
      });
      final outcome = await app.loadPlaceReviews(7);
      expect(outcome, ReviewActionOutcome.success);
      expect(captured!.url.path.endsWith('/places/7/reviews'), isTrue);
      expect(app.placeReviews, hasLength(1));
    });

    test('ReviewSummaryRecord.fromJson maps fields, partner reply and media',
        () async {
      final app = routedApp(
        onPlaceList: (_) async => jsonResponse([
          reviewSummaryJson(
            partnerReply: {
              'content': 'Thanks for staying!',
              'partnerDisplayName': 'Backend Villa',
              'repliedAt': '2030-05-03T10:00:00Z',
            },
            media: [
              {'id': 1, 'url': 'x', 'mediaType': 'IMAGE', 'cover': true},
            ],
          ),
        ], 200),
      );
      await app.loadPlaceReviews(7);
      final r = app.placeReviews.single;
      expect(r.id, 77);
      expect(r.placeName, 'Backend Villa');
      expect(r.userName, 'Mai Nguyen');
      expect(r.ratingOverall, 4);
      expect(r.statusView, ReviewStatusView.approved);
      expect(r.partnerReply, isNotNull);
      expect(r.partnerReply!.content, 'Thanks for staying!');
      expect(r.media, hasLength(1));
      expect(r.media.single.cover, isTrue);
    });

    test('unknown status degrades to unknown but keeps the raw string',
        () async {
      final app = routedApp(
        onMyList: (_) async =>
            jsonResponse([reviewSummaryJson(status: 'ESCALATED')], 200),
      );
      await app.loadMyReviews();
      expect(app.realMyReviews.single.statusView, ReviewStatusView.unknown);
      expect(app.realMyReviews.single.status, 'ESCALATED');
    });

    test('createReview POSTs bookingId + ratingOverall and omits unset ratings',
        () async {
      http.Request? captured;
      final app = routedApp(onRequest: (r) {
        if (createReviewPath(r)) captured = r;
      });
      final outcome = await app.submitReview(
        const ReviewCreatePayload(bookingId: 55, ratingOverall: 4),
      );
      expect(outcome, ReviewActionOutcome.success);
      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['bookingId'], 55);
      expect(body['ratingOverall'], 4);
      expect(body.containsKey('ratingCleanliness'), isFalse);
      expect(body.containsKey('title'), isFalse);
    });

    test(
        'ReviewDetailRecord.fromJson maps sub-ratings; created review is PENDING',
        () async {
      final app = routedApp(
        onCreate: (_) async => jsonResponse(reviewResponseJson(), 201),
      );
      await app.submitReview(
        const ReviewCreatePayload(bookingId: 55, ratingOverall: 4),
      );
      final r = app.lastSubmittedReview!;
      expect(r.statusView, ReviewStatusView.pending);
      expect(r.ratingCleanliness, 5);
      expect(r.ratingFacilities, 3);
      expect(r.bookingId, 55);
    });
  });

  // ── Demo Mode ────────────────────────────────────────────────────────────────

  group('Demo Mode', () {
    test('all review actions make zero HTTP in Demo Mode', () async {
      var calls = 0;
      final app = demoApp(MockClient((r) async {
        calls++;
        return jsonResponse(const [], 200);
      }));
      expect(
          await app.loadPlaceReviews(7), ReviewActionOutcome.demoUnavailable);
      expect(await app.loadMyReviews(), ReviewActionOutcome.demoUnavailable);
      expect(
        await app.submitReview(
            const ReviewCreatePayload(bookingId: 55, ratingOverall: 4)),
        ReviewActionOutcome.demoUnavailable,
      );
      expect(calls, 0);
    });
  });

  // ── Load / submit ──────────────────────────────────────────────────────────

  group('Load and submit', () {
    test('loadMyReviews stores the list; empty is an honest success', () async {
      final app = routedApp(onMyList: (_) async => jsonResponse(const [], 200));
      final outcome = await app.loadMyReviews();
      expect(outcome, ReviewActionOutcome.success);
      expect(app.myReviewsLoaded, isTrue);
      expect(app.realMyReviews, isEmpty);
    });

    test('submitReview stores the pending review and invalidates my-reviews',
        () async {
      final app = routedApp();
      await app.loadMyReviews();
      expect(app.myReviewsLoaded, isTrue);
      final outcome = await app.submitReview(
        const ReviewCreatePayload(bookingId: 55, ratingOverall: 5),
      );
      expect(outcome, ReviewActionOutcome.success);
      expect(app.lastSubmittedReview, isNotNull);
      // The new review belongs in the user's list → invalidated for a re-fetch.
      expect(app.myReviewsLoaded, isFalse);
    });

    test('a second submit while one is in flight returns busy (single-flight)',
        () async {
      final gate = Completer<http.Response>();
      final app = routedApp(onCreate: (_) => gate.future);
      final first = app.submitReview(
          const ReviewCreatePayload(bookingId: 55, ratingOverall: 4));
      final second = await app.submitReview(
          const ReviewCreatePayload(bookingId: 55, ratingOverall: 4));
      expect(second, ReviewActionOutcome.busy);
      gate.complete(jsonResponse(reviewResponseJson(), 201));
      expect(await first, ReviewActionOutcome.success);
    });
  });

  // ── Error mapping ────────────────────────────────────────────────────────────

  group('Errors', () {
    test('place reviews 401 → sessionExpired, no auto-logout / no demo switch',
        () async {
      final app = routedApp(
        onPlaceList: (_) async => jsonResponse(
            errorBody(401, 'expired', '/api/places/7/reviews'), 401),
      );
      app.email = 'mai@example.com';
      app.api.token = 'jwt-token';
      expect(await app.loadPlaceReviews(7), ReviewActionOutcome.sessionExpired);
      expect(app.email, 'mai@example.com');
      expect(app.api.token, 'jwt-token');
      expect(app.demoMode, isFalse);
    });

    test('submit 409 → alreadyReviewed', () async {
      final app = routedApp(
        onCreate: (_) async =>
            jsonResponse(errorBody(409, 'exists', '/api/reviews'), 409),
      );
      expect(
        await app.submitReview(
            const ReviewCreatePayload(bookingId: 55, ratingOverall: 4)),
        ReviewActionOutcome.alreadyReviewed,
      );
    });

    test('submit 422 → notCompleted', () async {
      final app = routedApp(
        onCreate: (_) async =>
            jsonResponse(errorBody(422, 'not completed', '/api/reviews'), 422),
      );
      expect(
        await app.submitReview(
            const ReviewCreatePayload(bookingId: 55, ratingOverall: 4)),
        ReviewActionOutcome.notCompleted,
      );
    });

    test('submit 403 → forbidden; 500 → serverError; network → network',
        () async {
      final forbidden = routedApp(
        onCreate: (_) async =>
            jsonResponse(errorBody(403, 'denied', '/api/reviews'), 403),
      );
      expect(
        await forbidden.submitReview(
            const ReviewCreatePayload(bookingId: 55, ratingOverall: 4)),
        ReviewActionOutcome.forbidden,
      );
      final server = routedApp(
        onCreate: (_) async =>
            jsonResponse(errorBody(500, 'boom', '/api/reviews'), 500),
      );
      expect(
        await server.submitReview(
            const ReviewCreatePayload(bookingId: 55, ratingOverall: 4)),
        ReviewActionOutcome.serverError,
      );
      final net = realApp(MockClient((_) async {
        throw http.ClientException('offline');
      }));
      expect(
        await net.submitReview(
            const ReviewCreatePayload(bookingId: 55, ratingOverall: 4)),
        ReviewActionOutcome.network,
      );
    });
  });

  // ── Session isolation ────────────────────────────────────────────────────────

  group('Session isolation', () {
    test('logout clears place reviews, my reviews and the last submission',
        () async {
      final app = routedApp();
      await app.loadPlaceReviews(7);
      await app.loadMyReviews();
      await app.submitReview(
          const ReviewCreatePayload(bookingId: 55, ratingOverall: 4));
      expect(app.placeReviews, isNotEmpty);
      expect(app.lastSubmittedReview, isNotNull);
      await app.logout();
      expect(app.placeReviews, isEmpty);
      expect(app.realMyReviews, isEmpty);
      expect(app.lastSubmittedReview, isNull);
      expect(app.reviewsPlaceId, isNull);
    });
  });

  // ── Widgets ──────────────────────────────────────────────────────────────────

  group('Widgets', () {
    testWidgets('place reviews list renders cards', (t) async {
      final app = routedApp(
        onPlaceList: (_) async => jsonResponse([reviewSummaryJson()], 200),
      );
      await pumpSize(
        t,
        testApp(
          child: const RealPlaceReviewsScreen(placeId: 7, placeName: 'Villa'),
          app: app,
        ),
        const Size(1200, 2000),
      );
      expect(find.byKey(const Key('real-review-card-77')), findsOneWidget);
    });

    testWidgets('place reviews empty state', (t) async {
      final app =
          routedApp(onPlaceList: (_) async => jsonResponse(const [], 200));
      await pumpSize(
        t,
        testApp(
          child: const RealPlaceReviewsScreen(placeId: 7, placeName: 'Villa'),
          app: app,
        ),
        const Size(1200, 2000),
      );
      expect(find.byKey(const Key('place-reviews-empty')), findsOneWidget);
    });

    testWidgets('my reviews shows a moderation status chip', (t) async {
      final app = routedApp(
        onMyList: (_) async =>
            jsonResponse([reviewSummaryJson(status: 'PENDING')], 200),
      );
      await pumpSize(
        t,
        testApp(child: const RealMyReviewsScreen(), app: app),
        const Size(1200, 2000),
      );
      expect(find.byKey(const Key('real-review-card-77')), findsOneWidget);
      final l10n = AppLocalizationsEn();
      expect(find.text(l10n.reviewStatusPending), findsWidgets);
    });

    testWidgets('a place reviews 401 shows the inline session-expired state',
        (t) async {
      final app = routedApp(
        onPlaceList: (_) async =>
            jsonResponse(errorBody(401, 'x', '/api/places/7/reviews'), 401),
      );
      await pumpSize(
        t,
        testApp(
          child: const RealPlaceReviewsScreen(placeId: 7, placeName: 'Villa'),
          app: app,
        ),
        const Size(1200, 2000),
      );
      expect(find.byKey(const Key('place-reviews-session-expired')),
          findsOneWidget);
    });

    testWidgets('write review requires an overall rating, then submits',
        (t) async {
      final app = routedApp(
        onCreate: (_) async => jsonResponse(reviewResponseJson(), 201),
      );
      await pumpSize(
        t,
        testApp(
          child: const RealWriteReviewScreen(bookingId: 55, placeName: 'Villa'),
          app: app,
        ),
        const Size(1200, 2600),
      );
      // Submit disabled until an overall rating is chosen.
      final submit =
          t.widget<Widget>(find.byKey(const Key('write-review-submit')));
      expect(submit, isNotNull);
      final l10n = AppLocalizationsEn();
      // Tap the 4th star of the OVERALL rating input.
      await t.tap(
        find.descendant(
          of: find.byKey(const Key('write-review-overall')),
          matching: find.byTooltip(l10n.writeReviewRateStarSemantic(4)),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('write-review-submit')));
      await t.pumpAndSettle();
      expect(app.lastSubmittedReview, isNotNull);
      expect(find.byKey(const Key('write-review-submitted')), findsOneWidget);
      expect(find.text(l10n.writeReviewPendingHeadline), findsWidgets);
    });

    testWidgets('completed booking detail exposes the review entries',
        (t) async {
      final app = routedApp(
        onBookingDetail: (_) async =>
            jsonResponse(bookingDetailJson(status: 'COMPLETED'), 200),
      );
      await pumpSize(
        t,
        testApp(
          child: const RealBookingDetailScreen(bookingId: 55),
          app: app,
        ),
        const Size(1200, 3000),
      );
      expect(
          find.byKey(const Key('booking-detail-write-review')), findsOneWidget);
      expect(find.byKey(const Key('booking-detail-hotel-reviews')),
          findsOneWidget);
      expect(
          find.byKey(const Key('booking-detail-my-reviews')), findsOneWidget);
    });
  });

  // ── Localization parity ──────────────────────────────────────────────────────

  group('Localization parity', () {
    test('every new UI29 key is present in both EN and VI', () {
      final en = AppLocalizationsEn();
      final vi = AppLocalizationsVi();
      final values = <String>[
        en.reviewsListLoadingMessage,
        vi.reviewsListLoadingMessage,
        en.placeReviewsEmptyTitle,
        vi.placeReviewsEmptyTitle,
        en.reviewsMineTitle,
        vi.reviewsMineTitle,
        en.writeReviewTitle,
        vi.writeReviewTitle,
        en.writeReviewModerationNote,
        vi.writeReviewModerationNote,
        en.writeReviewPendingBody,
        vi.writeReviewPendingBody,
        en.reviewSubmitAlreadyMessage,
        vi.reviewSubmitAlreadyMessage,
        en.bookingDetailSeeReviewsAction,
        vi.bookingDetailSeeReviewsAction,
      ];
      for (final s in values) {
        expect(s.trim(), isNotEmpty);
      }
      expect(en.writeReviewTitle != vi.writeReviewTitle, isTrue);
      expect(en.reviewStarsSemantic(4), isNotEmpty);
      expect(vi.reviewStarsSemantic(4), isNotEmpty);
    });
  });
}
