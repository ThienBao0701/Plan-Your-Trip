import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/mock/app_models.dart';
import 'package:planyourtrip_frontend/core/mock/mock_data.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/home/app_shell.dart';
import 'package:planyourtrip_frontend/features/reviews/reviews_screen.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final fixedNow = DateTime(2026, 7, 18, 10);

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

  AppState demoState() => AppState(now: () => fixedNow)
    ..demoMode = true
    ..email = MockData.demoEmail;

  // Real-mode AppState whose ApiClient returns an empty reviews list so the
  // real review screen (delegated to by the wrapper in real mode) resolves to
  // its empty state deterministically instead of hitting the network.
  AppState realStateWithEmptyReviews() => AppState(
        now: () => fixedNow,
        api: ApiClient(
          client: MockClient((request) async => http.Response(
                '[]',
                200,
                headers: {'content-type': 'application/json; charset=utf-8'},
              )),
        )..demoMode = false,
      )..demoMode = false;

  Widget harness({
    required Widget child,
    AppState? app,
    Locale? locale,
    double textScaleFactor = 1,
  }) {
    return AppScope(
      notifier: app ?? demoState(),
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: locale,
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
      ),
    );
  }

  Future<void> pumpSize(
    WidgetTester tester,
    Widget child,
    Size size, {
    AppState? app,
    Locale? locale,
    double textScaleFactor = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(harness(
      child: child,
      app: app,
      locale: locale,
      textScaleFactor: textScaleFactor,
    ));
    await tester.pumpAndSettle();
  }

  test('UI-11 review media values match committed backend contract', () {
    expect(ReviewMediaType.values.map((type) => type.code), [
      'IMAGE',
      'VIDEO',
      'DOCUMENT',
    ]);

    final review = TravelerReview(
      id: 100,
      authorUserId: 'demo-owner',
      authorName: 'Demo Traveler',
      placeId: 1,
      placeName: 'Mây Lang Thang Villa',
      ratingOverall: 5,
      createdAt: fixedNow,
      updatedAt: fixedNow,
      media: const [
        ReviewMediaItem(
          id: 'cover-later',
          url: 'https://example.com/cover.jpg',
          mediaType: ReviewMediaType.image,
          sortOrder: 2,
          cover: true,
        ),
        ReviewMediaItem(
          id: 'first-by-order',
          url: 'https://example.com/first.jpg',
          mediaType: ReviewMediaType.image,
          sortOrder: 1,
        ),
        ReviewMediaItem(
          id: 'inactive',
          url: 'https://example.com/inactive.jpg',
          mediaType: ReviewMediaType.image,
          active: false,
        ),
        ReviewMediaItem(
          id: 'unsafe',
          url: 'https://user:secret@example.com/private.jpg',
          mediaType: ReviewMediaType.image,
        ),
      ],
    );

    expect(isSafeReviewMediaUrl('https://example.com/photo.jpg'), isTrue);
    expect(isSafeReviewMediaUrl('http://example.com/photo.jpg'), isTrue);
    expect(isSafeReviewMediaUrl('HTTPS://example.com/photo.jpg'), isTrue);
    expect(isSafeReviewMediaUrl('javascript:alert(1)'), isFalse);
    expect(isSafeReviewMediaUrl('data:image/png;base64,aaa'), isFalse);
    expect(isSafeReviewMediaUrl('file:///tmp/photo.jpg'), isFalse);
    expect(isSafeReviewMediaUrl('ftp://example.com/photo.jpg'), isFalse);
    expect(isSafeReviewMediaUrl('blob:https://example.com/id'), isFalse);
    expect(isSafeReviewMediaUrl('https:///missing-host.jpg'), isFalse);
    expect(isSafeReviewMediaUrl('not a url'), isFalse);
    expect(
        isSafeReviewMediaUrl('https://user:pw@example.com/photo.jpg'), isFalse);
    const unsafeThumbnail = ReviewMediaItem(
      id: 'unsafe-thumb',
      url: 'https://example.com/original.jpg',
      thumbnailUrl: 'javascript:alert(1)',
      mediaType: ReviewMediaType.image,
    );
    const unsafePrimary = ReviewMediaItem(
      id: 'unsafe-primary',
      url: 'file:///tmp/original.jpg',
      thumbnailUrl: 'https://example.com/thumb.jpg',
      mediaType: ReviewMediaType.image,
    );
    expect(unsafeThumbnail.presentationUrl, 'https://example.com/original.jpg');
    expect(unsafePrimary.isVisible, isFalse);
    expect(unsafePrimary.presentationUrl, isEmpty);
    expect(review.visibleMedia.map((item) => item.id), [
      'first-by-order',
      'cover-later',
    ]);

    final mutableMedia = [
      const ReviewMediaItem(
        id: 'stable',
        url: 'https://example.com/stable.jpg',
        mediaType: ReviewMediaType.image,
      ),
    ];
    final stableReview = TravelerReview(
      id: 101,
      authorUserId: 'demo-owner',
      authorName: 'Demo Traveler',
      placeId: 1,
      placeName: 'Mây Lang Thang Villa',
      ratingOverall: 5,
      createdAt: fixedNow,
      updatedAt: fixedNow,
      media: mutableMedia,
    );
    mutableMedia.add(
      const ReviewMediaItem(
        id: 'late',
        url: 'https://example.com/late.jpg',
        mediaType: ReviewMediaType.image,
      ),
    );
    expect(stableReview.media, hasLength(1));
    expect(
      () => stableReview.media.add(
        const ReviewMediaItem(
          id: 'mutation',
          url: 'https://example.com/mutation.jpg',
          mediaType: ReviewMediaType.image,
        ),
      ),
      throwsUnsupportedError,
    );

    final reply = PartnerReviewReply(
      content: 'Reply body',
      repliedAt: fixedNow,
      updatedAt: fixedNow.add(const Duration(hours: 1)),
      partnerDisplayName: 'Property team',
    );
    expect(reply.content, 'Reply body');
    expect(reply.repliedAt, fixedNow);
    expect(reply.updatedAt, fixedNow.add(const Duration(hours: 1)));
    expect(reply.partnerDisplayName, 'Property team');
    expect(const PartnerReviewReply(content: '   ').isVisible, isFalse);
  });

  test('demo media and replies stay approved-only in public aggregates', () {
    final app = demoState();
    final publicReviews = app.publicReviewsForPlace(1);
    final reviewWithMedia = app.reviewById(1)!;
    final pendingReview = app.reviewById(3)!;
    final summary = app.reviewSummaryForPlace(1);

    expect(publicReviews.map((review) => review.status).toSet(),
        {ReviewStatus.approved});
    expect(reviewWithMedia.visibleMedia.map((item) => item.id), [
      'review-media-1a',
      'review-media-1b',
      'review-media-1c',
    ]);
    expect(reviewWithMedia.hasPartnerReply, isTrue);
    expect(pendingReview.visibleMedia, hasLength(1));
    expect(pendingReview.hasPartnerReply, isFalse);
    expect(app.publicReviewsForPlace(6), isEmpty);
    expect(summary.total, 2);
    expect(summary.average, 4.5);
    expect(summary.distribution[5], 1);
    expect(summary.distribution[4], 1);
  });

  testWidgets('public review cards show safe media and response indicators',
      (tester) async {
    ignoreNetworkImageErrors();

    await pumpSize(
      tester,
      PlaceReviewsScreen(place: MockData.places.first),
      const Size(1440, 900),
    );

    expect(find.byKey(const Key('reviews-list-screen')), findsOneWidget);
    expect(find.text('3 media items'), findsOneWidget);
    expect(find.text('Property response'), findsWidgets);
    expect(find.textContaining('secret'), findsNothing);
    expect(find.textContaining('PYT-DEMO'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('public detail shows gallery and read-only partner response',
      (tester) async {
    ignoreNetworkImageErrors();

    await pumpSize(
      tester,
      PlaceReviewsScreen(place: MockData.places.first),
      const Size(1440, 900),
    );

    await tester.ensureVisible(find.byKey(const Key('review-card-2')));
    await tester.tap(find.byKey(const Key('review-card-2')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('review-detail-screen')), findsOneWidget);
    expect(find.byKey(const Key('review-media-gallery-2')), findsOneWidget);
    expect(find.text('Review media'), findsOneWidget);
    expect(find.text('1 media item'), findsOneWidget);
    expect(find.text('Response from the property'), findsOneWidget);
    expect(find.textContaining('breakfast pacing'), findsOneWidget);
    expect(find.textContaining('PYT-DEMO-7002'), findsNothing);
    expect(find.textContaining('distribution tests'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('document media and legacy reply values fall back safely',
      (tester) async {
    final app = demoState()
      ..reviews = [
        TravelerReview(
          id: 120,
          authorUserId: 'demo-editor',
          authorName: 'Minh Editor',
          placeId: 1,
          placeName: 'Mây Lang Thang Villa',
          ratingOverall: 4,
          title: 'Legacy reply',
          status: ReviewStatus.approved,
          partnerReply: const PartnerReviewReply(
            content: 'A timestamp-free reply remains readable.',
            partnerDisplayName: 'Property team',
          ),
          createdAt: fixedNow,
          updatedAt: fixedNow,
        ),
        TravelerReview(
          id: 121,
          authorUserId: 'demo-editor',
          authorName: 'Minh Editor',
          placeId: 1,
          placeName: 'Mây Lang Thang Villa',
          ratingOverall: 4,
          title: 'Blank reply',
          status: ReviewStatus.approved,
          partnerReply: const PartnerReviewReply(
            content: '   ',
            partnerDisplayName: 'Property team',
          ),
          createdAt: fixedNow,
          updatedAt: fixedNow,
        ),
        TravelerReview(
          id: 122,
          authorUserId: 'demo-editor',
          authorName: 'Minh Editor',
          placeId: 1,
          placeName: 'Mây Lang Thang Villa',
          ratingOverall: 4,
          title: 'Document media',
          status: ReviewStatus.approved,
          media: const [
            ReviewMediaItem(
              id: 'review-document',
              url: 'https://example.com/review-document.pdf',
              mediaType: ReviewMediaType.document,
              sortOrder: 1,
              altText: 'Review document metadata',
            ),
          ],
          createdAt: fixedNow,
          updatedAt: fixedNow,
        ),
      ];

    await pumpSize(
      tester,
      const ReviewDetailScreen(reviewId: 120),
      const Size(900, 1400),
      app: app,
    );
    expect(find.text('Response from the property'), findsOneWidget);
    expect(find.textContaining('timestamp-free reply'), findsOneWidget);
    expect(find.textContaining('Responded on'), findsNothing);
    expect(tester.takeException(), isNull);

    await pumpSize(
      tester,
      const ReviewDetailScreen(reviewId: 121),
      const Size(900, 1400),
      app: app,
    );
    expect(find.text('Response from the property'), findsNothing);
    expect(tester.takeException(), isNull);

    await pumpSize(
      tester,
      const ReviewDetailScreen(reviewId: 122),
      const Size(900, 1400),
      app: app,
    );
    expect(find.byKey(const Key('review-media-gallery-122')), findsOneWidget);
    expect(find.text('Document'), findsOneWidget);
    expect(find.text('Unsupported media'), findsOneWidget);
    expect(find.textContaining('review-document.pdf'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('author detail shows private pending media and upload boundary',
      (tester) async {
    ignoreNetworkImageErrors();

    await pumpSize(
      tester,
      const MyReviewsScreen(),
      const Size(900, 1400),
    );

    await tester.tap(find.byKey(const Key('review-card-3')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('review-media-gallery-3')), findsOneWidget);
    expect(find.text('1 media item'), findsOneWidget);
    expect(find.text('Response from the property'), findsNothing);
    expect(find.text('Media unavailable'), findsNothing);
    expect(find.text('****-7003'), findsOneWidget);
    expect(find.text('PYT-DEMO-7003'), findsNothing);
    expect(find.text('Review metadata'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('composer explains media attachment boundary without fake upload',
      (tester) async {
    final app = demoState();
    final booking = app.demoBookings.singleWhere(
      (booking) => booking.code == MockData.demoReviewBookingCode,
    );
    final summaryBefore = app.reviewSummaryForPlace(booking.hotel.id);

    await pumpSize(
      tester,
      WriteReviewScreen(booking: booking),
      const Size(900, 1400),
      app: app,
    );

    expect(find.byKey(const Key('review-media-boundary')), findsOneWidget);
    expect(
      find.text(
        'Photo and video attachments will be available when the review media API is connected.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Add photo'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('review-title-field')),
      'Media boundary stay',
    );
    await tester.enterText(
      find.byKey(const Key('review-content-field')),
      'Text-only review creation remains available in Demo Mode.',
    );
    await tester.tap(find.byKey(const Key('review-submit-action')));
    await tester.pumpAndSettle();

    final created = app.reviews.firstWhere(
      (review) => review.bookingCode == booking.code,
    );
    expect(created.status, ReviewStatus.pending);
    expect(created.visibleMedia, isEmpty);
    expect(created.hasPartnerReply, isFalse);
    expect(
        app.reviewSummaryForPlace(booking.hotel.id).total, summaryBefore.total);
    expect(app.reviewSummaryForPlace(booking.hotel.id).average,
        summaryBefore.average);
  });

  testWidgets('real mode does not expose seeded personal media or fake actions',
      (tester) async {
    // Real Mode delegates to RealMyReviewsScreen, which loads from the backend
    // (empty here) and never shows seeded demo media or fabricated actions.
    await pumpSize(
      tester,
      const MyReviewsScreen(),
      const Size(900, 1400),
      app: realStateWithEmptyReviews(),
    );

    expect(find.text('My Reviews is not connected yet'), findsNothing);
    expect(find.byKey(const Key('my-reviews-empty')), findsOneWidget);
    expect(find.text('Review media'), findsNothing);
    expect(find.text('Property response'), findsNothing);
  });

  testWidgets(
      'review media and AppShell remain stable on narrow and wide sizes',
      (tester) async {
    ignoreNetworkImageErrors();

    for (final size in [
      const Size(430, 932),
      const Size(1920, 1080),
    ]) {
      await pumpSize(
        tester,
        const ReviewDetailScreen(reviewId: 1),
        size,
        textScaleFactor: size.width < 500 ? 1.35 : 1,
      );
      expect(find.byKey(const Key('review-detail-screen')), findsOneWidget);
      expect(find.byKey(const Key('review-media-gallery-1')), findsOneWidget);
      expect(
          tester.getSize(find.byKey(const Key('review-detail-screen'))).height,
          greaterThan(0));
      expect(tester.takeException(), isNull);
    }

    final semantics = tester.ensureSemantics();
    try {
      await pumpSize(
        tester,
        const AppShell(),
        const Size(1920, 1080),
      );
      expect(find.bySemanticsLabel('Explore tab'), findsOneWidget);
      expect(find.bySemanticsLabel('Trips tab'), findsOneWidget);
      expect(find.bySemanticsLabel('Planner tab'), findsOneWidget);
      expect(find.bySemanticsLabel('Profile tab'), findsOneWidget);
      expect(find.bySemanticsLabel('Reviews tab'), findsNothing);
      for (final label in ['Profile', 'Explore', 'Trips', 'Planner']) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('review media strings localize in Vietnamese', (tester) async {
    ignoreNetworkImageErrors();

    await pumpSize(
      tester,
      const ReviewDetailScreen(reviewId: 1),
      const Size(430, 932),
      locale: const Locale('vi'),
      textScaleFactor: 1.25,
    );

    expect(find.text('Media đánh giá'), findsOneWidget);
    expect(find.text('Chưa có xem trước video'), findsOneWidget);
    expect(find.text('Phản hồi từ nơi lưu trú'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('English and Vietnamese ARB files keep UI-11 key and placeholder parity',
      () {
    final en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
        as Map<String, dynamic>;
    final vi = jsonDecode(File('lib/l10n/app_vi.arb').readAsStringSync())
        as Map<String, dynamic>;
    final enKeys = en.keys.where((key) => !key.startsWith('@')).toSet();
    final viKeys = vi.keys.where((key) => !key.startsWith('@')).toSet();
    final enPlaceholders = {
      for (final entry in en.entries)
        if (entry.key.startsWith('@') && entry.value is Map)
          entry.key:
              ((entry.value as Map)['placeholders'] as Map?)?.keys.toSet()
    };
    final viPlaceholders = {
      for (final entry in vi.entries)
        if (entry.key.startsWith('@') && entry.value is Map)
          entry.key:
              ((entry.value as Map)['placeholders'] as Map?)?.keys.toSet()
    };

    expect(enKeys.difference(viKeys), isEmpty);
    expect(viKeys.difference(enKeys), isEmpty);
    expect(enKeys, contains('reviewMediaTitle'));
    expect(enKeys, contains('reviewPartnerResponseTitle'));
    expect(enPlaceholders, viPlaceholders);
  });
}
