import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/mock/app_models.dart';
import 'package:planyourtrip_frontend/core/mock/mock_data.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/home/app_shell.dart';
import 'package:planyourtrip_frontend/features/places/place_detail_screen.dart';
import 'package:planyourtrip_frontend/features/profile/profile_screen.dart';
import 'package:planyourtrip_frontend/features/profile/saved_places_screen.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:planyourtrip_frontend/shared/widgets/glass_widgets.dart';
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
    return AppScope(
      notifier: app ?? AppState(),
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

  AppState realApp() => AppState()
    ..demoMode = false
    ..email = 'real@example.com'
    ..savedPlaces = []
    ..savedCollections = []
    ..savedCollectionPlaces = [];

  test('saved-place model matches committed wishlist fields', () {
    final record = MockData.demoSavedPlaces.first;

    expect(record.backendId, isNotNull);
    expect(record.ownerUserId, 'demo-owner');
    expect(record.placeId, 1);
    expect(record.note, isNotEmpty);
    expect(record.savedAt.isUtc, isTrue);
    expect(record.demoOnly, isTrue);
  });

  test('saved-collection model matches latest committed collection fields', () {
    final collection = MockData.demoSavedCollections.first;
    final item = MockData.demoSavedCollectionPlaces.first;

    expect(collection.backendId, 9101);
    expect(collection.ownerUserId, 'demo-owner');
    expect(collection.name, 'Da Lat shortlist');
    expect(collection.description, isNotEmpty);
    expect(collection.coverImageUrl, isNull);
    expect(collection.privateCollection, isTrue);
    expect(collection.sortOrder, 0);
    expect(collection.createdAt.isUtc, isTrue);
    expect(collection.updatedAt.isUtc, isTrue);
    expect(collection.demoOnly, isTrue);
    expect(SavedCollectionRecord.maxNameLength, 120);
    expect(SavedCollectionRecord.maxDescriptionLength, 1000);
    expect(SavedCollectionRecord.maxCoverImageUrlLength, 2048);
    expect(SavedCollectionRecord.maxCollectionsPerUser, 100);

    expect(item.collectionId, collection.id);
    expect(item.placeId, 1);
    expect(item.position, 0);
    expect(item.addedAt.isUtc, isTrue);
    expect(SavedCollectionPlaceRecord.maxPlacesPerCollection, 500);
  });

  test(
      'canonical AppState seed, sorting, search, and filters are deterministic',
      () {
    final app = AppState();

    expect(app.visibleSavedPlaces.map((item) => item.id), [
      'wishlist-demo-1',
      'wishlist-demo-2',
      'wishlist-demo-3',
      'wishlist-demo-5',
    ]);
    expect(app.savedPlaceCount, 4);

    final vietnamese = app.savedPlaceResults(query: 'tui mo');
    expect(vietnamese.single.place?.name, 'Túi Mơ To Cafe');

    final hotels = app.savedPlaceResults(category: 'Hotels');
    expect(hotels.map((item) => item.place?.name), ['Mây Lang Thang Villa']);

    app.savedPlaces = [
      SavedPlaceRecord(
        id: 'wishlist-demo-b',
        ownerUserId: 'demo-owner',
        placeId: 2,
        savedAt: DateTime.utc(2026, 7, 20),
      ),
      SavedPlaceRecord(
        id: 'wishlist-demo-a',
        ownerUserId: 'demo-owner',
        placeId: 3,
        savedAt: DateTime.utc(2026, 7, 20),
      ),
    ];
    expect(app.savedPlaceResults().map((item) => item.record.id), [
      'wishlist-demo-a',
      'wishlist-demo-b',
    ]);
  });

  test('canonical collection seed, item ordering, and membership are stable',
      () {
    final app = AppState();

    expect(app.visibleSavedCollections.map((item) => item.id), [
      'collection-demo-dalat',
      'collection-demo-family',
      'collection-demo-views',
    ]);
    expect(app.savedCollectionCount, 3);
    expect(app.savedCollectionItemCount('collection-demo-dalat'), 2);
    expect(app.savedCollectionItemCount('collection-demo-family'), 0);
    expect(app.savedCollectionItemCount('collection-demo-views'), 2);
    expect(
      app.resolvedCollectionPlaces('collection-demo-dalat').map(
            (item) => item.place?.name,
          ),
      ['Mây Lang Thang Villa', 'Kombi Land'],
    );
    expect(
      app.isPlaceInCollection(
        collectionId: 'collection-demo-dalat',
        placeId: 1,
      ),
      isTrue,
    );
    expect(
      app.isPlaceInCollection(
        collectionId: 'collection-demo-family',
        placeId: 1,
      ),
      isFalse,
    );
    expect(
      app.savedCollectionItems('missing-collection'),
      isEmpty,
    );
  });

  test('collection create and update follow backend validation boundaries', () {
    final now = DateTime.utc(2026, 7, 24, 10);
    final app = AppState(now: () => now);

    expect(
      app.createSavedCollection(name: '   '),
      SavedCollectionActionResult.invalidName,
    );
    expect(
      app.createSavedCollection(
        name: 'x' * (SavedCollectionRecord.maxNameLength + 1),
      ),
      SavedCollectionActionResult.invalidName,
    );
    expect(
      app.createSavedCollection(
        name: 'Valid',
        description: 'x' * (SavedCollectionRecord.maxDescriptionLength + 1),
      ),
      SavedCollectionActionResult.invalidDescription,
    );
    expect(
      app.createSavedCollection(
        name: 'Valid',
        coverImageUrl: 'x' * (SavedCollectionRecord.maxCoverImageUrlLength + 1),
      ),
      SavedCollectionActionResult.invalidCover,
    );

    expect(
      app.createSavedCollection(
        name: '  Đà Nẵng family  ',
        description: '',
        coverImageUrl: '',
        privateCollection: false,
      ),
      SavedCollectionActionResult.success,
    );
    final created = app.visibleSavedCollections.last;
    expect(created.name, '  Đà Nẵng family  ');
    expect(created.description, '');
    expect(created.coverImageUrl, '');
    expect(created.privateCollection, isFalse);
    expect(created.createdAt, now);
    expect(created.updatedAt, now);

    expect(
      app.createSavedCollection(name: '  Đà Nẵng family  '),
      SavedCollectionActionResult.success,
      reason: 'Backend does not enforce duplicate collection names.',
    );

    expect(
      app.updateSavedCollection(
        collectionId: created.id,
        name: 'Sa Pa cuối tuần',
        description: 'Núi và cafe',
        coverImageUrl: 'https://example.com/cover.jpg',
        privateCollection: true,
      ),
      SavedCollectionActionResult.success,
    );
    final updated = app.savedCollectionById(created.id)!;
    expect(updated.name, 'Sa Pa cuối tuần');
    expect(updated.description, 'Núi và cafe');
    expect(updated.coverImageUrl, 'https://example.com/cover.jpg');
    expect(updated.privateCollection, isTrue);
    expect(updated.createdAt, now);
    expect(updated.updatedAt, now);

    expect(
      app.updateSavedCollection(
        collectionId: 'missing',
        name: 'Nope',
      ),
      SavedCollectionActionResult.collectionNotFound,
    );

    final limitApp = AppState();
    limitApp.savedCollections = List.generate(
      SavedCollectionRecord.maxCollectionsPerUser,
      (index) => SavedCollectionRecord(
        id: 'limit-$index',
        ownerUserId: 'demo-owner',
        name: 'Collection $index',
        sortOrder: index,
        createdAt: DateTime.utc(2026, 7, 1, index % 24),
        updatedAt: DateTime.utc(2026, 7, 1, index % 24),
      ),
    );
    expect(
      limitApp.createSavedCollection(name: 'Over limit'),
      SavedCollectionActionResult.collectionLimitReached,
    );
  });

  test('collection membership stays separate from wishlist and place data', () {
    final app = AppState(now: () => DateTime.utc(2026, 7, 24, 11));
    final beforeTrips = app.trips.length;
    final beforeBookings = app.demoBookings.length;
    final beforePayments = app.demoPaymentAttempts.length;
    final beforeWallet = app.travelWalletItems.length;
    final beforeReviews = app.reviews.length;
    final beforeNotifications = app.userNotifications.length;
    final beforePlace = app.placeById(4);
    final wishlistPlaceIds =
        app.visibleSavedPlaces.map((record) => record.placeId).toSet();

    expect(
      app.addPlaceToCollection(
        collectionId: 'collection-demo-family',
        placeId: 4,
      ),
      SavedCollectionActionResult.success,
    );
    expect(
      app.addPlaceToCollection(
        collectionId: 'collection-demo-family',
        placeId: 4,
      ),
      SavedCollectionActionResult.duplicateItem,
    );
    expect(
      app.isPlaceInCollection(
        collectionId: 'collection-demo-family',
        placeId: 4,
      ),
      isTrue,
    );
    expect(app.isPlaceSaved(4), isFalse,
        reason: 'Collection membership does not auto-save to wishlist.');

    expect(
      app.removePlaceFromCollection(
        collectionId: 'collection-demo-family',
        placeId: 4,
      ),
      SavedCollectionActionResult.success,
    );
    expect(
      app.removePlaceFromCollection(
        collectionId: 'collection-demo-family',
        placeId: 4,
      ),
      SavedCollectionActionResult.itemNotFound,
    );
    expect(
      app.addPlaceToCollection(
        collectionId: 'missing',
        placeId: 4,
      ),
      SavedCollectionActionResult.collectionNotFound,
    );
    expect(
      app.addPlaceToCollection(
        collectionId: 'collection-demo-family',
        placeId: 999,
      ),
      SavedCollectionActionResult.placeNotFound,
    );

    expect(app.isPlaceSaved(1), isTrue);
    expect(
      app.isPlaceInCollection(
        collectionId: 'collection-demo-dalat',
        placeId: 1,
      ),
      isTrue,
    );
    expect(app.removeSavedPlace(1), SavedPlaceActionResult.success);
    expect(app.isPlaceSaved(1), isFalse);
    expect(
      app.isPlaceInCollection(
        collectionId: 'collection-demo-dalat',
        placeId: 1,
      ),
      isTrue,
      reason: 'Wishlist deletion does not cascade collection membership.',
    );

    expect(
      app.deleteSavedCollection('collection-demo-dalat'),
      SavedCollectionActionResult.success,
    );
    expect(app.savedCollectionById('collection-demo-dalat'), isNull);
    expect(
      app.savedCollectionPlaces
          .where((item) => item.collectionId == 'collection-demo-dalat'),
      isEmpty,
    );
    expect(app.visibleSavedPlaces.map((record) => record.placeId).toSet(),
        wishlistPlaceIds.difference({1}));
    expect(app.placeById(4), same(beforePlace));
    expect(app.trips, hasLength(beforeTrips));
    expect(app.demoBookings, hasLength(beforeBookings));
    expect(app.demoPaymentAttempts, hasLength(beforePayments));
    expect(app.travelWalletItems, hasLength(beforeWallet));
    expect(app.reviews, hasLength(beforeReviews));
    expect(app.userNotifications, hasLength(beforeNotifications));

    final limitApp = AppState();
    limitApp.savedCollectionPlaces = List.generate(
      SavedCollectionPlaceRecord.maxPlacesPerCollection,
      (index) => SavedCollectionPlaceRecord(
        id: 'family-limit-$index',
        collectionId: 'collection-demo-family',
        placeId: 1000 + index,
        position: index,
        addedAt: DateTime.utc(2026, 7, 1),
      ),
    );
    expect(
      limitApp.addPlaceToCollection(
        collectionId: 'collection-demo-family',
        placeId: 4,
      ),
      SavedCollectionActionResult.itemLimitReached,
    );
  });

  test('save and unsave are owner-safe, idempotent, and isolated', () {
    final app = AppState(now: () => DateTime.utc(2026, 7, 24, 9));
    final beforeTrips = app.trips.length;
    final beforeBookings = app.demoBookings.length;
    final beforePayments = app.demoPaymentAttempts.length;
    final beforeWallet = app.travelWalletItems.length;
    final beforeReviews = app.reviews.length;
    final beforeNotifications = app.userNotifications.length;
    final overlongNote = 'x' * (SavedPlaceRecord.maxNoteLength + 1);

    expect(app.savePlace(4, note: overlongNote),
        SavedPlaceActionResult.invalidNote);
    expect(app.isPlaceSaved(4), isFalse);

    expect(app.savePlace(4, note: ''), SavedPlaceActionResult.success);
    expect(app.savedPlaceForPlaceId(4)?.note, '');
    expect(app.savePlace(4), SavedPlaceActionResult.duplicate);
    expect(app.visibleSavedPlaces.where((item) => item.placeId == 4),
        hasLength(1));
    expect(app.savedPlaceForPlaceId(4)?.savedAt, DateTime.utc(2026, 7, 24, 9));
    expect(app.updateSavedPlaceNote(4, '  keep spaces  '),
        SavedPlaceActionResult.success);
    expect(app.savedPlaceForPlaceId(4)?.note, '  keep spaces  ');
    expect(app.updateSavedPlaceNote(4, overlongNote),
        SavedPlaceActionResult.invalidNote);
    expect(app.savedPlaceForPlaceId(4)?.note, '  keep spaces  ');
    expect(app.savedPlaceForPlaceId(4)?.savedAt, DateTime.utc(2026, 7, 24, 9));
    expect(app.updateSavedPlaceNote(4, null), SavedPlaceActionResult.success);
    expect(app.savedPlaceForPlaceId(4)?.note, isNull);

    expect(app.removeSavedPlace(4), SavedPlaceActionResult.success);
    expect(app.removeSavedPlace(4), SavedPlaceActionResult.notFound);
    expect(app.isPlaceSaved(4), isFalse);

    app.savedPlaces = [
      SavedPlaceRecord(
        id: 'foreign-save',
        ownerUserId: 'other-user',
        placeId: 4,
        savedAt: DateTime.utc(2026, 7, 20),
      ),
    ];
    expect(app.removeSavedPlace(4), SavedPlaceActionResult.forbidden);
    expect(app.updateSavedPlaceNote(4, 'not mine'),
        SavedPlaceActionResult.forbidden);
    expect(app.updateSavedPlaceNote(999, 'missing'),
        SavedPlaceActionResult.notFound);

    expect(app.trips, hasLength(beforeTrips));
    expect(app.demoBookings, hasLength(beforeBookings));
    expect(app.demoPaymentAttempts, hasLength(beforePayments));
    expect(app.travelWalletItems, hasLength(beforeWallet));
    expect(app.reviews, hasLength(beforeReviews));
    expect(app.userNotifications, hasLength(beforeNotifications));
  });

  test('real mode and reset do not leak or accumulate saved places', () async {
    final app = realApp();

    expect(app.visibleSavedPlaces, isEmpty);
    expect(app.visibleSavedCollections, isEmpty);
    expect(app.savePlace(1), SavedPlaceActionResult.unavailable);
    expect(app.removeSavedPlace(1), SavedPlaceActionResult.unavailable);
    expect(app.updateSavedPlaceNote(1, 'real note'),
        SavedPlaceActionResult.unavailable);
    expect(
      app.createSavedCollection(name: 'Real collection'),
      SavedCollectionActionResult.unavailable,
    );
    expect(
      app.addPlaceToCollection(collectionId: 'any', placeId: 1),
      SavedCollectionActionResult.unavailable,
    );

    app.demoMode = true;
    app.savedPlaces = List.from(MockData.demoSavedPlaces);
    app.savedCollections = List.from(MockData.demoSavedCollections);
    app.savedCollectionPlaces = List.from(MockData.demoSavedCollectionPlaces);
    expect(app.savePlace(4), SavedPlaceActionResult.success);
    expect(
      app.createSavedCollection(name: 'Reset candidate'),
      SavedCollectionActionResult.success,
    );
    expect(app.savedPlaceCount, 5);
    expect(app.savedCollectionCount, 4);

    await app.logout();
    expect(app.demoMode, isTrue);
    expect(app.savedPlaceCount, 4);
    expect(app.savedCollectionCount, 3);
    expect(app.savedCollectionItemCount('collection-demo-dalat'), 2);
    await app.logout();
    expect(app.savedPlaceCount, 4);
    expect(app.savedCollectionCount, 3);
  });

  test('missing public place references stay safe and removable', () {
    final app = AppState();
    app.savedPlaces = [
      SavedPlaceRecord(
        id: 'wishlist-demo-missing',
        ownerUserId: 'demo-owner',
        placeId: 999,
        savedAt: DateTime.utc(2026, 7, 21),
        note: 'Old place reference.',
      ),
    ];

    final results = app.savedPlaceResults();
    expect(results.single.place, isNull);
    expect(app.removeSavedPlace(999), SavedPlaceActionResult.success);
    expect(app.visibleSavedPlaces, isEmpty);
  });

  test('missing collection place references stay safe and removable', () {
    final app = AppState();
    app.savedCollectionPlaces = [
      SavedCollectionPlaceRecord(
        id: 'stale-membership',
        collectionId: 'collection-demo-family',
        placeId: 999,
        position: 0,
        addedAt: DateTime.utc(2026, 7, 21),
      ),
    ];

    final resolved = app.resolvedCollectionPlaces('collection-demo-family');
    expect(resolved.single.place, isNull);
    expect(
      app.removePlaceFromCollection(
        collectionId: 'collection-demo-family',
        placeId: 999,
      ),
      SavedCollectionActionResult.success,
    );
    expect(app.savedCollectionItems('collection-demo-family'), isEmpty);
  });

  testWidgets('Profile opens Saved Places with counts and collection section',
      (tester) async {
    ignoreNetworkImageErrors();
    final app = AppState();

    await pumpSize(
      tester,
      testApp(child: const ProfileScreen(), app: app),
      const Size(430, 932),
    );

    await tester.ensureVisible(find.text('Saved places').last);
    await tester.tap(find.text('Saved places').last);
    await tester.pumpAndSettle();

    expect(find.text('Saved places'), findsWidgets);
    expect(find.text('4 places'), findsWidgets);
    expect(find.text('3 collections'), findsWidgets);
    expect(find.text('Collections (3)'), findsOneWidget);
  });

  testWidgets('Saved Places search, no-results, stale card, and details work',
      (tester) async {
    ignoreNetworkImageErrors();
    final app = AppState();

    await pumpSize(
      tester,
      testApp(child: const SavedPlacesScreen(), app: app),
      const Size(430, 932),
    );

    await tester.enterText(
      find.byKey(const Key('saved-places-search-field')),
      'tui mo',
    );
    await tester.pumpAndSettle();
    expect(find.text('Túi Mơ To Cafe'), findsOneWidget);
    expect(find.text('Mây Lang Thang Villa'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('saved-places-search-field')),
      'does-not-exist',
    );
    await tester.pumpAndSettle();
    expect(find.text('No matching saved places'), findsOneWidget);

    app.savedPlaces = [
      SavedPlaceRecord(
        id: 'wishlist-demo-missing',
        ownerUserId: 'demo-owner',
        placeId: 999,
        savedAt: DateTime.utc(2026, 7, 21),
      ),
    ];
    await pumpSize(
      tester,
      testApp(
        child: const SavedPlacesScreen(key: ValueKey('missing-saved-place')),
        app: app,
      ),
      const Size(430, 932),
    );
    expect(find.text('Saved place unavailable'), findsOneWidget);

    app.savedPlaces = List.from(MockData.demoSavedPlaces);
    await pumpSize(
      tester,
      testApp(
        child: const SavedPlacesScreen(key: ValueKey('restored-saved-place')),
        app: app,
      ),
      const Size(430, 932),
    );
    final detailsButton = tester
        .widgetList<OceanSecondaryButton>(
          find.byKey(const Key('saved-place-details-1')),
        )
        .first;
    detailsButton.onPressed?.call();
    await tester.pumpAndSettle();
    expect(find.byType(PlaceDetailScreen), findsOneWidget);
  });

  testWidgets('bookmark toggle is consistent between detail and saved list',
      (tester) async {
    ignoreNetworkImageErrors();
    final app = AppState(now: () => DateTime.utc(2026, 7, 24, 9));
    final place = MockData.places[3];

    await pumpSize(
      tester,
      testApp(child: PlaceDetailScreen(place: place), app: app),
      const Size(430, 932),
    );

    await tester.tap(find.byTooltip('Save ${place.name}').first);
    await tester.pumpAndSettle();
    expect(app.isPlaceSaved(place.id), isTrue);
    expect(find.text('Saved ${place.name} locally.'), findsOneWidget);
    expect(find.byTooltip('Remove saved place ${place.name}'), findsOneWidget);

    await pumpSize(
      tester,
      testApp(child: const SavedPlacesScreen(), app: app),
      const Size(430, 932),
    );
    expect(find.text(place.name), findsOneWidget);
    expect(find.byTooltip('Remove saved place ${place.name}'), findsOneWidget);
  });

  testWidgets('Saved Places Add to Trip reuses existing sheet', (tester) async {
    ignoreNetworkImageErrors();
    final app = AppState();

    await pumpSize(
      tester,
      testApp(child: const SavedPlacesScreen(), app: app),
      const Size(430, 932),
    );

    final addButton = tester
        .widgetList<OceanSecondaryButton>(
          find.byKey(const Key('saved-place-add-trip-1')),
        )
        .first;
    addButton.onPressed?.call();
    await tester.pumpAndSettle();

    expect(find.text('Quick Add'), findsOneWidget);
    expect(find.text('Select trip'), findsOneWidget);
    expect(app.savedPlaceCount, 4);
  });

  testWidgets('Saved Places collections can be created, edited, and deleted',
      (tester) async {
    ignoreNetworkImageErrors();
    final app = AppState(now: () => DateTime.utc(2026, 7, 24, 12));

    await pumpSize(
      tester,
      testApp(child: const SavedPlacesScreen(), app: app),
      const Size(430, 932),
    );

    await tester.tap(find.text('Collections (3)'));
    await tester.pumpAndSettle();
    expect(find.text('Da Lat shortlist'), findsOneWidget);
    expect(find.text('Family ideas'), findsOneWidget);
    expect(find.text('0 places'), findsWidgets);

    await tester.tap(find.byKey(const Key('saved-collection-create')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('saved-collection-name-field')),
      'Hội An weekend',
    );
    await tester.enterText(
      find.byKey(const Key('saved-collection-description-field')),
      'Lantern walks',
    );
    await tester.tap(find.byKey(const Key('saved-collection-save')));
    await tester.pumpAndSettle();

    expect(app.savedCollectionCount, 4);
    expect(find.text('Created collection Hội An weekend.'), findsOneWidget);
    expect(find.text('Hội An weekend'), findsOneWidget);

    final editFamily = tester
        .widgetList<OceanSecondaryButton>(
          find.byKey(const Key('saved-collection-edit-collection-demo-family')),
        )
        .first;
    editFamily.onPressed?.call();
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('saved-collection-name-field')),
      'Family stays',
    );
    await tester.tap(find.byKey(const Key('saved-collection-save')));
    await tester.pumpAndSettle();
    expect(app.savedCollectionById('collection-demo-family')?.name,
        'Family stays');

    final deleteFamily = tester
        .widgetList<IconButton>(
          find.byKey(
              const Key('saved-collection-delete-collection-demo-family')),
        )
        .first;
    deleteFamily.onPressed?.call();
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Places, wishlist notes, trips, bookings'),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(
        const Key('saved-collection-delete-confirm-collection-demo-family'),
      ),
    );
    await tester.pumpAndSettle();
    expect(app.savedCollectionById('collection-demo-family'), isNull);
    expect(app.savedPlaceCount, 4);
    expect(app.placeById(1)?.name, 'Mây Lang Thang Villa');
  });

  testWidgets('collection membership and detail actions are reachable',
      (tester) async {
    ignoreNetworkImageErrors();
    final app = AppState(now: () => DateTime.utc(2026, 7, 24, 13));

    await pumpSize(
      tester,
      testApp(child: const SavedPlacesScreen(), app: app),
      const Size(430, 932),
    );

    final collectionButton = tester
        .widgetList<OceanSecondaryButton>(
          find.byKey(const Key('saved-place-collections-1')),
        )
        .first;
    collectionButton.onPressed?.call();
    await tester.pumpAndSettle();
    expect(find.text('Collections for Mây Lang Thang Villa'), findsOneWidget);

    await tester.tap(
      find.byKey(
        const Key('saved-collection-toggle-1-collection-demo-family'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      app.isPlaceInCollection(
        collectionId: 'collection-demo-family',
        placeId: 1,
      ),
      isTrue,
    );
    expect(
      find.text('Added Mây Lang Thang Villa to Family ideas.'),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(
        const Key('saved-collection-toggle-1-collection-demo-family'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      app.isPlaceInCollection(
        collectionId: 'collection-demo-family',
        placeId: 1,
      ),
      isFalse,
    );

    Navigator.of(
      tester.element(find.text('Collections for Mây Lang Thang Villa')),
    ).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Collections (3)'));
    await tester.pumpAndSettle();
    final openCollection = tester
        .widgetList<OceanPrimaryButton>(
          find.byKey(const Key('saved-collection-open-collection-demo-dalat')),
        )
        .first;
    openCollection.onPressed?.call();
    await tester.pumpAndSettle();
    expect(find.text('Da Lat shortlist'), findsWidgets);
    expect(find.text('Mây Lang Thang Villa'), findsOneWidget);

    final addButton = tester
        .widgetList<OceanSecondaryButton>(
          find.byKey(const Key('saved-collection-place-add-trip-1')),
        )
        .first;
    addButton.onPressed?.call();
    await tester.pumpAndSettle();
    expect(find.text('Quick Add'), findsOneWidget);
  });

  testWidgets(
      'wishlist notes prefill, save explicitly, and reject overlong text',
      (tester) async {
    ignoreNetworkImageErrors();
    final app = AppState();
    final originalSavedAt = app.savedPlaceForPlaceId(1)!.savedAt;

    await pumpSize(
      tester,
      testApp(child: const SavedPlacesScreen(), app: app),
      const Size(430, 932),
    );

    final editButton = tester
        .widgetList<OceanSecondaryButton>(
          find.byKey(const Key('saved-place-edit-note-1')),
        )
        .first;
    editButton.onPressed?.call();
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(
      find.byKey(const Key('saved-place-note-field')),
    );
    expect(field.controller?.text, 'Shortlisted hillside stay for Da Lat.');

    await tester.enterText(
      find.byKey(const Key('saved-place-note-field')),
      'x' * (SavedPlaceRecord.maxNoteLength + 1),
    );
    await tester.tap(find.byKey(const Key('saved-place-note-save')));
    await tester.pumpAndSettle();
    expect(find.text('Private notes are limited to 500 characters.'),
        findsOneWidget);
    expect(app.savedPlaceForPlaceId(1)?.note,
        'Shortlisted hillside stay for Da Lat.');

    await tester.enterText(
      find.byKey(const Key('saved-place-note-field')),
      'Quiet balcony request',
    );
    await tester.tap(find.byKey(const Key('saved-place-note-save')));
    await tester.pumpAndSettle();
    expect(find.text('Updated the private note for Mây Lang Thang Villa.'),
        findsOneWidget);
    expect(app.savedPlaceForPlaceId(1)?.note, 'Quiet balcony request');
    expect(app.savedPlaceForPlaceId(1)?.savedAt, originalSavedAt);

    final reopenButton = tester
        .widgetList<OceanSecondaryButton>(
          find.byKey(const Key('saved-place-edit-note-1')),
        )
        .first;
    reopenButton.onPressed?.call();
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('saved-place-note-field')), '');
    await tester.tap(find.byKey(const Key('saved-place-note-save')));
    await tester.pumpAndSettle();
    expect(app.savedPlaceForPlaceId(1)?.note, '');
  });

  testWidgets('real mode boundary shows no seeded saved places',
      (tester) async {
    ignoreNetworkImageErrors();

    await pumpSize(
      tester,
      testApp(child: const SavedPlacesScreen(), app: realApp()),
      const Size(430, 932),
    );

    expect(find.text('No saved places yet'), findsOneWidget);
    expect(find.text('Mây Lang Thang Villa'), findsNothing);
  });

  testWidgets('saved places layout supports narrow, wide, and large text',
      (tester) async {
    ignoreNetworkImageErrors();

    for (final scenario in const [
      (Size(430, 932), 1.0),
      (Size(1440, 900), 1.0),
      (Size(1920, 1080), 1.0),
      (Size(430, 932), 1.7),
    ]) {
      await pumpSize(
        tester,
        testApp(
          child: const SavedPlacesScreen(),
          textScaleFactor: scenario.$2,
        ),
        scenario.$1,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Saved places'), findsWidgets);
    }
  });

  testWidgets('saved places exposes useful semantics', (tester) async {
    ignoreNetworkImageErrors();
    final semantics = tester.ensureSemantics();
    try {
      await pumpSize(
        tester,
        testApp(child: const SavedPlacesScreen()),
        const Size(430, 932),
      );

      expect(find.bySemanticsLabel(RegExp('4 saved places')), findsWidgets);
      expect(
        find.bySemanticsLabel(RegExp('3 saved collections')),
        findsWidgets,
      );
      expect(
        find.bySemanticsLabel('Remove saved place Mây Lang Thang Villa'),
        findsWidgets,
      );
      expect(find.bySemanticsLabel('Saved place filters'), findsOneWidget);

      await tester.tap(find.text('Collections (3)'));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel('Open collection Da Lat shortlist'),
        findsWidgets,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('AppShell remains exactly four tabs and nonblank',
      (tester) async {
    ignoreNetworkImageErrors();
    await pumpSize(
      tester,
      testApp(child: const AppShell()),
      const Size(430, 932),
    );

    final nav = tester.widget<OceanBottomNavigationBar>(
      find.byType(OceanBottomNavigationBar),
    );
    expect(nav.destinations, hasLength(4));

    for (final label in ['Trips', 'Planner', 'Profile', 'Explore']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(find.byType(AppShell), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  test('English and Vietnamese saved-place localization parity holds', () {
    final en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
        as Map<String, dynamic>;
    final vi = jsonDecode(File('lib/l10n/app_vi.arb').readAsStringSync())
        as Map<String, dynamic>;

    final enKeys = en.keys.where((key) => !key.startsWith('@')).toSet();
    final viKeys = vi.keys.where((key) => !key.startsWith('@')).toSet();
    expect(viKeys, enKeys);

    for (final key in enKeys.where((key) => key.startsWith('savedPlaces'))) {
      final enMeta = en['@$key'];
      final viMeta = vi['@$key'];
      final enPlaceholders = enMeta is Map<String, dynamic>
          ? (enMeta['placeholders'] as Map<String, dynamic>?)?.keys.toSet() ??
              const <String>{}
          : const <String>{};
      final viPlaceholders = viMeta is Map<String, dynamic>
          ? (viMeta['placeholders'] as Map<String, dynamic>?)?.keys.toSet() ??
              const <String>{}
          : const <String>{};
      expect(viPlaceholders, enPlaceholders, reason: key);
    }
  });
}
