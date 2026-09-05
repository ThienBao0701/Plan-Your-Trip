import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:planyourtrip_frontend/core/admin/admin_models.dart';
import 'package:planyourtrip_frontend/core/admin/admin_state.dart';
import 'package:planyourtrip_frontend/core/app_role.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/features/admin/admin_catalog_states.dart';
import 'package:planyourtrip_frontend/features/admin/admin_navigation.dart';
import 'package:planyourtrip_frontend/features/admin/admin_routes.dart';
import 'package:planyourtrip_frontend/features/admin/screens/admin_catalog_screen.dart';
import 'package:planyourtrip_frontend/features/admin/screens/admin_place_detail_screen.dart';
import 'package:planyourtrip_frontend/features/admin/widgets/admin_widgets.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// D3C-A — Admin Catalog.
///
/// Fixtures mirror the real DTOs on `develop@3467d45`. Where a test asserts an
/// absence — no place editor, no delete, no restore, no inventory or rate
/// control, no media mutation, no assign-owner — that absence is the
/// requirement, because the backend either has no endpoint or the D3B freeze
/// placed it elsewhere.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // A short settle budget, so a tree that never stops scheduling frames fails
  // in seconds instead of burning the framework's ten-minute default.
  Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5));

  Map<String, dynamic> ref(int id, String name) =>
      {'id': id, 'name': name, 'slug': name.toLowerCase()};

  Map<String, dynamic> placeRow({
    int id = 1,
    String name = 'Grand Palace Hotel',
    String status = 'PUBLISHED',
    bool featured = false,
    bool verified = false,
  }) =>
      {
        'id': id,
        'name': name,
        'slug': 'grand-palace',
        'category': ref(9, 'Accommodation'),
        'subcategory': null,
        'administrativeUnit': ref(3, 'Vung Tau'),
        'address': '1 Beach Road',
        'googleMapUrl': null,
        'latitude': 10.3,
        'longitude': 107.0,
        'shortDescription': 'A hotel',
        'priceLevel': 3,
        'ratingAvg': 4.5,
        'reviewCount': 12,
        'status': status,
        'featured': featured,
        'verified': verified,
        'coverImageUrl': 'https://cdn.test/cover.jpg',
        'createdAt': '2026-07-30T09:00:00Z',
      };

  Map<String, dynamic> placeDetail({
    int id = 1,
    String status = 'PUBLISHED',
    bool featured = false,
    bool verified = false,
    bool hotel = true,
  }) =>
      {
        'id': id,
        'name': 'Grand Palace Hotel',
        'slug': 'grand-palace',
        'shortDescription': 'A hotel',
        'description': 'Long description',
        'address': '1 Beach Road',
        'googleMapUrl': null,
        'latitude': 10.3,
        'longitude': 107.0,
        'category': ref(9, 'Accommodation'),
        'subcategory': null,
        'location': ref(3, 'Vung Tau'),
        'ratingAvg': 4.5,
        'ratingCount': 12,
        'priceLevel': 3,
        'featured': featured,
        'verified': verified,
        'status': status,
        'tags': [
          {'id': 1, 'tag': 'beach'}
        ],
        'amenities': [
          {'id': 2, 'name': 'Pool', 'slug': 'pool'}
        ],
        'openingHours': const [],
        'groupedOpeningHours': const [],
        'coverImageUrl': 'https://cdn.test/cover.jpg',
        'galleryImages': [
          {
            'id': 5,
            'url': 'https://cdn.test/a.jpg',
            'thumbnailUrl': null,
            'altText': 'A',
            'sortOrder': 1,
            'cover': true
          }
        ],
        'openNow': true,
        'similarPlaces': const [],
        'metadata': null,
        if (hotel) 'hotelDetail': {'id': 7, 'starRating': 5},
      };

  final roomsJson = [
    {
      'id': 21,
      'roomName': 'Suite King',
      'roomCode': 'SUITE-KNG',
      'roomType': 'SUITE',
      'bedType': 'KING',
      'bedCount': 1,
      'maxAdults': 2,
      'maxChildren': 1,
      'maxGuests': 3,
      'roomSizeSqm': 40.0,
      'floorNumber': 5,
      'smokingAllowed': false,
      'breakfastIncluded': true,
      'freeCancellation': true,
      'instantConfirmation': true,
      'priceFrom': 1200000,
      'originalPrice': 1500000,
      'quantity': 18,
      'availableQuantity': 12,
      'active': true,
      'amenities': const [],
      'coverImageUrl': null,
      'galleryImages': const [],
      'createdAt': '2026-07-30T09:00:00Z',
      'updatedAt': '2026-07-30T09:00:00Z',
    }
  ];

  Map<String, dynamic> pageOf(List<Map<String, dynamic>> rows,
          {int page = 0, int size = 20, int? total}) =>
      {
        'content': rows,
        'page': page,
        'size': size,
        'totalElements': total ?? rows.length,
        'totalPages': ((total ?? rows.length) / size).ceil(),
      };

  ({ApiClient api, List<Uri> requests, List<http.Request> sent}) clientFor(
    Map<String, http.Response> Function(Uri uri) route,
  ) {
    final requests = <Uri>[];
    final sent = <http.Request>[];
    final mock = _RecordingClient(onRequest: (req) {
      requests.add(req.url);
      if (req is http.Request) sent.add(req);
      return route(req.url)[req.url.path] ??
          http.Response('{"message":"unmapped"}', 500);
    });
    return (
      api: ApiClient(client: mock, baseUrl: 'http://test/api'),
      requests: requests,
      sent: sent
    );
  }

  http.Response ok(Object json) => http.Response(jsonEncode(json), 200,
      headers: {'content-type': 'application/json'});

  Map<String, http.Response> routes({
    String status = 'PUBLISHED',
    bool featured = false,
    bool verified = false,
    bool hotel = true,
    http.Response? roomsOverride,
  }) =>
      {
        '/api/admin/places': ok(pageOf([
          placeRow(status: status, featured: featured, verified: verified)
        ])),
        '/api/admin/places/1': ok(placeDetail(
            status: status,
            featured: featured,
            verified: verified,
            hotel: hotel)),
        '/api/admin/hotels/1/rooms': roomsOverride ?? ok(roomsJson),
        '/api/admin/places/1/status': ok(placeRow(status: 'HIDDEN')),
        '/api/admin/places/1/verified': ok(placeRow(verified: true)),
        '/api/admin/places/1/featured': ok(placeRow(featured: true)),
      };

  Widget harness(Widget child, {Locale? locale}) => MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // 1 · Admin route
  // ═══════════════════════════════════════════════════════════════════════════

  group('route', () {
    test('Catalog is a registered destination', () {
      final d = AdminNavigation.byRoute(AdminRoutes.catalog);
      expect(d, isNotNull);
      expect(d!.section, AdminSection.catalog);
      expect(AdminRoutes.isAdminRoute(AdminRoutes.catalog), isTrue);
    });

    testWidgets('a signed-out session is refused the Catalog route',
        (tester) async {
      final app = AppState();
      await tester.pumpWidget(AppScope(
        notifier: app,
        child: AdminScope(
          notifier: AdminState(api: app.api),
          child:
              harness(const AdminRouteGuard(initialRoute: AdminRoutes.catalog)),
        ),
      ));
      await tester.pump();
      expect(find.byType(AdminAccessDeniedScreen), findsOneWidget);
    });

    test('only ADMIN may enter', () {
      expect(AppRole.admin.canEnterAdminConsole, isTrue);
      for (final r in [AppRole.user, AppRole.partner, AppRole.unknown]) {
        expect(r.canEnterAdminConsole, isFalse, reason: r.name);
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 2–6 · List, pagination, filters, the legacy sort vocabulary
  // ═══════════════════════════════════════════════════════════════════════════

  group('place list', () {
    test('loads a page and exposes the envelope', () async {
      final c = clientFor((_) => routes());
      final s = AdminCatalogPlacesState(api: c.api);
      await s.load();
      expect(s.status, AdminLoadStatus.ready);
      expect(s.rows.single.name, 'Grand Palace Hotel');
      expect(s.rows.single.status, AdminPlaceStatus.published);
    });

    test('an empty result is empty, not an error', () async {
      final c = clientFor((_) => {'/api/admin/places': ok(pageOf(const []))});
      final s = AdminCatalogPlacesState(api: c.api);
      await s.load();
      expect(s.status, AdminLoadStatus.ready);
      expect(s.isEmpty, isTrue);
    });

    test('a 403 becomes forbidden', () async {
      final c =
          clientFor((_) => {'/api/admin/places': http.Response('{}', 403)});
      final s = AdminCatalogPlacesState(api: c.api);
      await s.load();
      expect(s.status, AdminLoadStatus.forbidden);
    });

    test('sends only the backend sort vocabulary, never field,dir', () async {
      // PlaceService.resolveSort is a closed switch over these five tokens; an
      // unrecognised value is silently ignored and the default applied, so a
      // `field,dir` string would look like a working control that does nothing.
      expect(AdminCatalogPlacesState.sortTokens,
          ['newest', 'rating_desc', 'price_asc', 'price_desc', 'name_asc']);

      final c = clientFor((_) => routes());
      final s = AdminCatalogPlacesState(api: c.api);
      await s.load();
      for (final token in AdminCatalogPlacesState.sortTokens) {
        await s.setSortToken(token);
        expect(c.requests.last.queryParameters['sort'], token);
        expect(c.requests.last.queryParameters['sort'], isNot(contains(',')));
      }
    });

    test('refuses to send a sort token the backend does not know', () async {
      final c = clientFor((_) => routes());
      final s = AdminCatalogPlacesState(api: c.api);
      await s.load();
      final before = c.requests.length;
      await s.setSortToken('createdAt,desc');
      expect(c.requests.length, before, reason: 'nothing was sent');
      expect(s.sortField, 'newest');
    });

    test('never asks for more than the backend @Max(100)', () async {
      // This endpoint rejects an oversized size with 400 rather than clamping,
      // unlike every other admin grid.
      expect(AdminCatalogPlacesState.maxPageSize, 100);
      final c = clientFor((_) => routes());
      final s = AdminCatalogPlacesState(api: c.api);
      await s.setPageSize(100000);
      expect(int.parse(c.requests.last.queryParameters['size']!),
          lessThanOrEqualTo(100));
    });

    test('filters map to the backend query parameters', () async {
      final c = clientFor((_) => routes());
      final s = AdminCatalogPlacesState(api: c.api);
      await s.load();
      await s.setStatusFilter('PUBLISHED');
      await s.setFeaturedFilter(true);
      await s.setVerifiedFilter(true);
      await s.setQuery('  palace  ');

      final q = c.requests.last.queryParameters;
      expect(q['status'], 'PUBLISHED');
      expect(q['featured'], 'true');
      expect(q['verified'], 'true');
      expect(q['q'], 'palace', reason: 'trimmed');
      expect(q['page'], '0', reason: 'a filter change returns to page 0');
    });

    test('exposes no filter the endpoint does not support', () async {
      final c = clientFor((_) => routes());
      final s = AdminCatalogPlacesState(api: c.api);
      await s.load();
      final q = c.requests.last.queryParameters.keys.toSet();
      // AdminPlaceController declares exactly these; owner/date filters do not
      // exist and must never be sent.
      expect(
          q.difference({
            'q',
            'categoryId',
            'status',
            'locationId',
            'featured',
            'verified',
            'page',
            'size',
            'sort'
          }),
          isEmpty);
    });

    test('paging asks the server', () async {
      var served = 0;
      final c = clientFor((_) => {
            '/api/admin/places':
                ok(pageOf([placeRow()], page: served++ == 0 ? 0 : 1, total: 40))
          });
      final s = AdminCatalogPlacesState(api: c.api);
      await s.load();
      await s.goToPage(1);
      expect(c.requests.last.queryParameters['page'], '1');
      expect(s.pageIndex, 1);
    });

    test('surfaces the unstable ordering rather than hiding it', () {
      final c = clientFor((_) => routes());
      expect(AdminCatalogPlacesState(api: c.api).orderingIsUnstable, isTrue);
    });

    testWidgets('renders rows and opens one', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;

      final c = clientFor((_) => routes());
      final s = AdminCatalogPlacesState(api: c.api);
      await s.load();
      AdminPlaceRow? opened;
      await tester.pumpWidget(harness(
          AdminCatalogScreen(state: s, onOpenPlace: (r) => opened = r)));
      await tester.pumpAndSettle();

      expect(find.text('Grand Palace Hotel'), findsWidgets);
      await tester.tap(find.text('Open').first);
      await tester.pump();
      expect(opened?.id, 1);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 7–8 · Detail and not-found
  // ═══════════════════════════════════════════════════════════════════════════

  group('place detail', () {
    test('loads the place and its rooms', () async {
      final c = clientFor((_) => routes());
      final s = AdminPlaceDetailState(api: c.api, placeId: 1);
      await s.load();
      expect(s.isReady, isTrue);
      expect(s.place!.tags, ['beach']);
      expect(s.place!.amenities, ['Pool']);
      expect(s.rooms.single.roomCode, 'SUITE-KNG');
      expect(s.notAHotel, isFalse);
    });

    test('a non-hotel place reports no rooms without calling the endpoint',
        () async {
      final c = clientFor((_) => routes(hotel: false));
      final s = AdminPlaceDetailState(api: c.api, placeId: 1);
      await s.load();
      expect(s.isReady, isTrue);
      expect(s.notAHotel, isTrue);
      expect(s.rooms, isEmpty);
      expect(c.requests.map((u) => u.path),
          everyElement(isNot(contains('/rooms'))));
    });

    test('a 404 from the rooms endpoint is "not a hotel", not an error',
        () async {
      // The backend answers 404 for a place with no hotel detail.
      final c =
          clientFor((_) => routes(roomsOverride: http.Response('{}', 404)));
      final s = AdminPlaceDetailState(api: c.api, placeId: 1);
      await s.load();
      expect(s.notAHotel, isTrue);
      expect(s.roomsStatus, AdminLoadStatus.ready);
    });

    testWidgets('a missing place reads as not found', (tester) async {
      final c =
          clientFor((_) => {'/api/admin/places/9': http.Response('{}', 404)});
      final s = AdminPlaceDetailState(api: c.api, placeId: 9);
      await s.load();
      await tester
          .pumpWidget(harness(AdminPlaceDetailScreen(state: s, onBack: () {})));
      await tester.pumpAndSettle();
      expect(find.text('Place not found'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 9–12 · Lifecycle
  // ═══════════════════════════════════════════════════════════════════════════

  group('lifecycle', () {
    test('the transition table mirrors PlaceService exactly', () {
      expect(AdminPlaceStatus.draft.allowedNext, [
        AdminPlaceStatus.pendingReview,
        AdminPlaceStatus.approved,
        AdminPlaceStatus.published,
        AdminPlaceStatus.hidden,
        AdminPlaceStatus.archived,
      ]);
      expect(AdminPlaceStatus.pendingReview.allowedNext, [
        AdminPlaceStatus.approved,
        AdminPlaceStatus.rejected,
        AdminPlaceStatus.hidden,
        AdminPlaceStatus.archived,
      ]);
      expect(AdminPlaceStatus.approved.allowedNext, [
        AdminPlaceStatus.published,
        AdminPlaceStatus.hidden,
        AdminPlaceStatus.archived
      ]);
      expect(AdminPlaceStatus.published.allowedNext,
          [AdminPlaceStatus.hidden, AdminPlaceStatus.archived]);
      expect(AdminPlaceStatus.hidden.allowedNext,
          [AdminPlaceStatus.published, AdminPlaceStatus.archived]);
      expect(AdminPlaceStatus.rejected.allowedNext,
          [AdminPlaceStatus.draft, AdminPlaceStatus.archived]);
      expect(AdminPlaceStatus.archived.allowedNext, isEmpty);
    });

    test('PENDING_REVIEW cannot jump straight to PUBLISHED', () {
      // The real path is PENDING_REVIEW -> APPROVED -> PUBLISHED.
      expect(
          AdminPlaceStatus.pendingReview
              .canTransitionTo(AdminPlaceStatus.published),
          isFalse);
    });

    test('an unknown status offers no transition at all', () {
      expect(AdminPlaceStatus.parse('SOMETHING_NEW'), AdminPlaceStatus.unknown);
      expect(AdminPlaceStatus.unknown.allowedNext, isEmpty);
      expect(AdminPlaceStatus.unknown.canSetFlagsTrue, isFalse);
    });

    test('a disallowed transition is never sent', () async {
      final c = clientFor((_) => routes(status: 'PUBLISHED'));
      final s = AdminPlaceDetailState(api: c.api, placeId: 1);
      await s.load();
      final before = c.requests.length;
      final result = await s.changeStatus(AdminPlaceStatus.approved);
      expect(result, isFalse);
      expect(c.requests.length, before, reason: 'nothing was sent');
    });

    test('an allowed transition posts the backend body shape', () async {
      final c = clientFor((_) => routes(status: 'PUBLISHED'));
      final s = AdminPlaceDetailState(api: c.api, placeId: 1);
      await s.load();
      await s.changeStatus(AdminPlaceStatus.hidden);
      final body = jsonDecode(
          c.sent.firstWhere((r) => r.url.path.endsWith('/status')).body);
      expect(body, {'status': 'HIDDEN'});
    });

    testWidgets('only legal transitions are offered, and ARCHIVED is dangerous',
        (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1.0;

      final c = clientFor((_) => routes(status: 'PUBLISHED'));
      final s = AdminPlaceDetailState(api: c.api, placeId: 1);
      await s.load();
      await tester
          .pumpWidget(harness(AdminPlaceDetailScreen(state: s, onBack: () {})));
      await tester.pumpAndSettle();

      expect(find.text('HIDDEN'), findsOneWidget);
      expect(find.text('Archive'), findsOneWidget);
      // Not reachable from PUBLISHED.
      expect(find.text('APPROVED'), findsNothing);
      expect(find.text('DRAFT'), findsNothing);
    });

    testWidgets('archiving requires an explicit acknowledgement',
        (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1.0;

      final c = clientFor((_) => routes(status: 'PUBLISHED'));
      final s = AdminPlaceDetailState(api: c.api, placeId: 1);
      await s.load();
      await tester
          .pumpWidget(harness(AdminPlaceDetailScreen(state: s, onBack: () {})));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();
      expect(find.textContaining('cannot be reversed'), findsOneWidget);
      expect(
          find.textContaining('disappears from guest search'), findsOneWidget);
      expect(find.textContaining('not released'), findsOneWidget);

      final disabled = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Archive place'));
      expect(disabled.onPressed, isNull);
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      final enabled = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Archive place'));
      expect(enabled.onPressed, isNotNull);
    });

    testWidgets('an archived place offers no action and no restore',
        (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1.0;

      final c = clientFor((_) => routes(status: 'ARCHIVED'));
      final s = AdminPlaceDetailState(api: c.api, placeId: 1);
      await s.load();
      await tester
          .pumpWidget(harness(AdminPlaceDetailScreen(state: s, onBack: () {})));
      await tester.pumpAndSettle();

      expect(find.textContaining('no way to restore'), findsOneWidget);
      for (final label in ['Restore', 'Unarchive', 'Reactivate', 'Archive']) {
        expect(find.text(label), findsNothing, reason: label);
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 13–14 · Verification and featured guards
  // ═══════════════════════════════════════════════════════════════════════════

  group('verified and featured', () {
    test('may only be turned on from APPROVED or PUBLISHED', () {
      expect(AdminPlaceStatus.approved.canSetFlagsTrue, isTrue);
      expect(AdminPlaceStatus.published.canSetFlagsTrue, isTrue);
      for (final s in [
        AdminPlaceStatus.draft,
        AdminPlaceStatus.pendingReview,
        AdminPlaceStatus.rejected,
        AdminPlaceStatus.hidden,
        AdminPlaceStatus.archived,
      ]) {
        expect(s.canSetFlagsTrue, isFalse, reason: s.name);
      }
    });

    test('clearing a flag is allowed from any state', () async {
      final c = clientFor((_) => routes(status: 'HIDDEN', verified: true));
      final s = AdminPlaceDetailState(api: c.api, placeId: 1);
      await s.load();
      expect(s.canSetVerified(false), isTrue, reason: 'clearing is unguarded');
      expect(s.canSetVerified(true), isFalse, reason: 'HIDDEN cannot set true');
    });

    test('posts the backend body shape', () async {
      final c = clientFor((_) => routes(status: 'PUBLISHED'));
      final s = AdminPlaceDetailState(api: c.api, placeId: 1);
      await s.load();
      await s.setVerified(true);
      final body = jsonDecode(
          c.sent.firstWhere((r) => r.url.path.endsWith('/verified')).body);
      expect(body, {'value': true});
    });

    testWidgets('the switches are disabled outside APPROVED/PUBLISHED',
        (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1.0;

      final c = clientFor((_) => routes(status: 'DRAFT'));
      final s = AdminPlaceDetailState(api: c.api, placeId: 1);
      await s.load();
      await tester
          .pumpWidget(harness(AdminPlaceDetailScreen(state: s, onBack: () {})));
      await tester.pumpAndSettle();

      final switches =
          tester.widgetList<SwitchListTile>(find.byType(SwitchListTile));
      expect(switches, hasLength(2));
      for (final sw in switches) {
        expect(sw.onChanged, isNull);
      }
      expect(find.textContaining('only be turned on'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Mutation honesty — a catalog write must never look like it worked
  // ═══════════════════════════════════════════════════════════════════════════

  group('mutation outcomes', () {
    test('an unreadable success body is uncertain, not a success', () async {
      // The place may well have moved; the response just cannot be read. For
      // ARCHIVED in particular there is no way back, so this must never be
      // reported as a clean failure the operator would simply retry.
      final r = routes(status: 'PUBLISHED');
      r['/api/admin/places/1/status'] = http.Response('not json', 200);
      final c = clientFor((_) => r);
      final s = AdminPlaceDetailState(api: c.api, placeId: 1);
      await s.load();

      final ok = await s.changeStatus(AdminPlaceStatus.hidden);
      expect(ok, isFalse);
      expect(s.mutationUncertain, isTrue,
          reason: 'the warning outlives the reload that follows it');
      expect(s.isReady, isTrue, reason: 'the page still shows real state');
    });

    test('a rejected mutation surfaces the error, never a silent success',
        () async {
      final r = routes(status: 'PUBLISHED');
      r['/api/admin/places/1/verified'] = http.Response(
          '{"message":"Only APPROVED or PUBLISHED places can be verified"}',
          400);
      final c = clientFor((_) => r);
      final s = AdminPlaceDetailState(api: c.api, placeId: 1);
      await s.load();

      final ok = await s.setVerified(true);
      expect(ok, isFalse);
      expect(s.mutationUncertain, isFalse, reason: 'a 400 is a clean refusal');
      expect(s.mutationError, isNotNull);
      expect(s.place!.verified, isFalse, reason: 'nothing was patched locally');
    });

    test('a second write is refused while one is in flight', () async {
      final c = clientFor((_) => routes(status: 'PUBLISHED'));
      final s = AdminPlaceDetailState(api: c.api, placeId: 1);
      await s.load();

      final first = s.changeStatus(AdminPlaceStatus.hidden);
      final second = s.changeStatus(AdminPlaceStatus.hidden);
      expect(await second, isFalse, reason: 'double-submit is dropped');
      await first;
      expect(c.sent.where((r) => r.url.path.endsWith('/status')), hasLength(1));
    });

    testWidgets('the uncertain warning is shown, not just recorded',
        (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1.0;

      final r = routes(status: 'PUBLISHED');
      r['/api/admin/places/1/status'] = http.Response('not json', 200);
      final c = clientFor((_) => r);
      final s = AdminPlaceDetailState(api: c.api, placeId: 1);
      await s.load();
      await tester
          .pumpWidget(harness(AdminPlaceDetailScreen(state: s, onBack: () {})));
      await settle(tester);

      await s.changeStatus(AdminPlaceStatus.hidden);
      await settle(tester);
      expect(find.textContaining('result of the last action is unknown'),
          findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 15–17 · Read-only, rooms and assignment boundaries
  // ═══════════════════════════════════════════════════════════════════════════

  group('boundaries', () {
    testWidgets('identity is read-only — no editor, no delete', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1.0;

      final c = clientFor((_) => routes());
      final s = AdminPlaceDetailState(api: c.api, placeId: 1);
      await s.load();
      await tester
          .pumpWidget(harness(AdminPlaceDetailScreen(state: s, onBack: () {})));
      await tester.pumpAndSettle();

      // PUT /api/admin/places/{id} exists but is a destructive full replace of
      // tags, opening hours and amenities, so no partial editor is offered.
      expect(find.byType(TextField), findsNothing);
      for (final label in ['Save', 'Edit', 'Delete']) {
        expect(find.text(label), findsNothing, reason: label);
      }
      expect(find.textContaining('Read-only'), findsWidgets);
    });

    testWidgets('rooms are a relationship, not an operations console',
        (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1.0;

      final c = clientFor((_) => routes());
      final s = AdminPlaceDetailState(api: c.api, placeId: 1);
      await s.load();
      await tester
          .pumpWidget(harness(AdminPlaceDetailScreen(state: s, onBack: () {})));
      await tester.pumpAndSettle();

      expect(find.text('Suite King'), findsOneWidget);
      expect(
          find.textContaining('managed outside the catalog'), findsOneWidget);
      for (final absent in [
        'Inventory',
        'Rate plans',
        'Bookings',
        'Availability'
      ]) {
        expect(find.text(absent), findsNothing, reason: absent);
      }
    });

    test('no assign-owner method exists on the catalog client surface', () {
      // The D3B catalog freeze placed assign-owner out of scope, so nothing in
      // this feature calls POST /api/admin/hotels/{id}/assign-owner.
      final c = clientFor((_) => routes());
      expect(c.requests, isEmpty);
    });

    testWidgets('the gallery is read-only with no media controls',
        (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1.0;

      final c = clientFor((_) => routes());
      final s = AdminPlaceDetailState(api: c.api, placeId: 1);
      await s.load();
      await tester
          .pumpWidget(harness(AdminPlaceDetailScreen(state: s, onBack: () {})));
      await tester.pumpAndSettle();

      expect(find.text('Gallery'), findsOneWidget);
      for (final absent in [
        'Upload',
        'Add image',
        'Set cover',
        'Reorder',
        'Remove'
      ]) {
        expect(find.text(absent), findsNothing, reason: absent);
      }
      expect(c.requests.map((u) => u.path),
          everyElement(isNot(contains('/admin/media'))));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 18–20 · Localization, responsive, accessibility
  // ═══════════════════════════════════════════════════════════════════════════

  group('localization and layout', () {
    testWidgets('renders in Vietnamese', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1.0;

      final c = clientFor((_) => routes());
      final s = AdminPlaceDetailState(api: c.api, placeId: 1);
      await s.load();
      await tester.pumpWidget(harness(
          AdminPlaceDetailScreen(state: s, onBack: () {}),
          locale: const Locale('vi')));
      await tester.pumpAndSettle();
      expect(find.text('Vòng đời'), findsOneWidget);
      expect(find.text('Lifecycle'), findsNothing);
    });

    // Overflow is reported through FlutterError.onError, which the test binding
    // already records; asking the tester for it is enough. Overriding that
    // handler here would swallow every *other* framework error at the same
    // time, which is how a broken layout can look like a passing test.
    testWidgets('list and detail survive 320, 390, 820 and 1600',
        (tester) async {
      addTearDown(tester.view.reset);

      for (final width in [320.0, 390.0, 820.0, 1600.0]) {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1.0;

        final c = clientFor((_) => routes(status: 'PUBLISHED'));
        final list = AdminCatalogPlacesState(api: c.api);
        await list.load();
        await tester.pumpWidget(
            harness(AdminCatalogScreen(state: list, onOpenPlace: (_) {})));
        await settle(tester);
        expect(tester.takeException(), isNull, reason: 'list at ${width}px');

        final detail = AdminPlaceDetailState(api: c.api, placeId: 1);
        await detail.load();
        await tester.pumpWidget(
            harness(AdminPlaceDetailScreen(state: detail, onBack: () {})));
        await settle(tester);
        expect(tester.takeException(), isNull, reason: 'detail at ${width}px');

        // The cards below the fold are never laid out until they scroll into
        // view, so a narrow-width defect in Rooms or Gallery would otherwise go
        // unseen at exactly the widths this test exists to cover.
        for (var i = 0; i < 6; i++) {
          await tester.drag(find.byType(ListView), const Offset(0, -400));
          await settle(tester);
          expect(tester.takeException(), isNull,
              reason: 'detail scrolled at ${width}px');
        }
      }
    });

    testWidgets('the archive dialog fits 320px', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;

      final c = clientFor((_) => routes(status: 'PUBLISHED'));
      final s = AdminPlaceDetailState(api: c.api, placeId: 1);
      await s.load();
      await tester
          .pumpWidget(harness(AdminPlaceDetailScreen(state: s, onBack: () {})));
      await settle(tester);
      await tester.tap(find.text('Archive'));
      await settle(tester);

      expect(find.byType(Checkbox), findsOneWidget);
      expect(find.text('Archive place'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('critical controls carry an accessible name', (tester) async {
      final handle = tester.ensureSemantics();
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      final c = clientFor((_) => routes());
      final list = AdminCatalogPlacesState(api: c.api);
      await list.load();
      await tester.pumpWidget(
          harness(AdminCatalogScreen(state: list, onOpenPlace: (_) {})));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(l10n.adminCatalogSearchLabel), findsWidgets);
      expect(find.bySemanticsLabel(l10n.adminCatalogSortLabel), findsWidgets);

      final detail = AdminPlaceDetailState(api: c.api, placeId: 1);
      await detail.load();
      await tester.pumpWidget(
          harness(AdminPlaceDetailScreen(state: detail, onBack: () {})));
      await tester.pumpAndSettle();
      expect(find.byTooltip(l10n.adminCatalogBackToList), findsOneWidget);

      handle.dispose();
    });
  });
}

class _RecordingClient extends http.BaseClient {
  final http.Response Function(http.BaseRequest request) onRequest;

  _RecordingClient({required this.onRequest});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final materialised = request is http.Request
        ? (http.Request(request.method, request.url)
          ..headers.addAll(request.headers)
          ..body = request.body)
        : request;
    final res = onRequest(materialised);
    return http.StreamedResponse(
      Stream.value(utf8.encode(res.body)),
      res.statusCode,
      headers: res.headers,
      request: request,
    );
  }
}
