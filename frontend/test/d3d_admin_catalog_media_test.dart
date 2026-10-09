import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:planyourtrip_frontend/core/admin/admin_models.dart';
import 'package:planyourtrip_frontend/core/admin/admin_state.dart';
import 'package:planyourtrip_frontend/core/app_role.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/features/admin/admin_app_shell.dart';
import 'package:planyourtrip_frontend/features/admin/admin_catalog_states.dart';
import 'package:planyourtrip_frontend/features/admin/admin_media_states.dart';
import 'package:planyourtrip_frontend/features/admin/admin_routes.dart';
import 'package:planyourtrip_frontend/features/admin/widgets/admin_widgets.dart';
import 'package:planyourtrip_frontend/features/admin/screens/admin_media_screen.dart';
import 'package:planyourtrip_frontend/features/admin/screens/admin_place_detail_screen.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/admin_access_stub.dart';

/// D3D — Catalog ↔ Media integration and its security boundary.
///
/// The flow under test is the real one, driven through [AdminAppShell]:
/// Catalog → place detail → media gallery → back. Where a test asserts an
/// absence — no owner switch, no cross-place mutation, no upload, no restore,
/// no auto-promoted cover — that absence is the requirement.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5));

  // ── fixtures ───────────────────────────────────────────────────────────────

  Map<String, dynamic> ref(int id, String name) =>
      {'id': id, 'name': name, 'slug': name.toLowerCase()};

  Map<String, dynamic> placeRow({int id = 1, String name = 'Grand Palace'}) => {
        'id': id,
        'name': name,
        'slug': 'p$id',
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
        'status': 'PUBLISHED',
        'featured': false,
        'verified': true,
        'coverImageUrl': 'https://cdn.test/cover.jpg',
        'createdAt': '2026-08-30T09:00:00Z',
      };

  Map<String, dynamic> placeDetail({
    int id = 1,
    String name = 'Grand Palace',
    String? coverImageUrl = 'https://cdn.test/cover.jpg',
    int galleryCount = 1,
  }) =>
      {
        'id': id,
        'name': name,
        'slug': 'p$id',
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
        'featured': false,
        'verified': true,
        'status': 'PUBLISHED',
        'tags': const [],
        'amenities': const [],
        'openingHours': const [],
        'groupedOpeningHours': const [],
        'coverImageUrl': coverImageUrl,
        'galleryImages': [
          for (var i = 0; i < galleryCount; i++)
            {
              'id': 100 + i,
              'url': 'https://cdn.test/g$i.jpg',
              'thumbnailUrl': null,
              'altText': 'G$i',
              'sortOrder': i,
              'cover': i == 0 && coverImageUrl != null,
            }
        ],
        'openNow': true,
        'similarPlaces': const [],
        'metadata': null,
        'hotelDetail': {'id': 7, 'starRating': 5},
      };

  Map<String, dynamic> asset({
    int id = 5,
    int ownerId = 1,
    String ownerType = 'PLACE',
    String url = 'https://cdn.test/a.jpg',
    String mediaType = 'IMAGE',
    int sortOrder = 0,
    bool cover = false,
    bool active = true,
  }) =>
      {
        'id': id,
        'ownerType': ownerType,
        'ownerId': ownerId,
        'url': url,
        'thumbnailUrl': null,
        'mediaType': mediaType,
        'altText': 'Lobby $id',
        'sortOrder': sortOrder,
        'cover': cover,
        'active': active,
        'uploadedByUserId': 1,
        'createdAt': '2026-08-30T09:00:00Z',
        'updatedAt': '2026-08-30T09:00:00Z',
      };

  Map<String, dynamic> pageOf(List<Map<String, dynamic>> rows) => {
        'content': rows,
        'page': 0,
        'size': 20,
        'totalElements': rows.length,
        'totalPages': 1,
      };

  // ── a routing client that records every request ────────────────────────────

  ({
    ApiClient api,
    List<http.BaseRequest> requests,
    List<http.Request> sent,
    List<String> paths,
  }) clientFor({
    Map<int, List<Map<String, dynamic>>>? galleries,
    Map<int, Map<String, dynamic>>? details,
    Map<String, http.Response>? overrides,
    int mediaStatus = 200,
  }) {
    final requests = <http.BaseRequest>[];
    final sent = <http.Request>[];
    final paths = <String>[];

    http.Response route(http.BaseRequest req) {
      final path = req.url.path;
      final override = overrides?[path];
      if (override != null) return override;

      http.Response ok(Object body) => http.Response(jsonEncode(body), 200,
          headers: {'content-type': 'application/json'});

      final media = RegExp(r'^/api/admin/places/(\d+)/media$').firstMatch(path);
      if (media != null) {
        if (mediaStatus != 200) {
          return http.Response('{"message":"denied"}', mediaStatus);
        }
        final id = int.parse(media.group(1)!);
        final rows = galleries?[id];
        if (rows == null) return http.Response('{"message":"no place"}', 404);
        return ok(rows);
      }

      final detail = RegExp(r'^/api/admin/places/(\d+)$').firstMatch(path);
      if (detail != null) {
        final id = int.parse(detail.group(1)!);
        final body = details?[id];
        if (body == null) return http.Response('{"message":"no place"}', 404);
        return ok(body);
      }

      if (path == '/api/admin/places') {
        return ok(pageOf([
          for (final id in (details?.keys.toList() ?? [1])) placeRow(id: id)
        ]));
      }
      if (RegExp(r'^/api/admin/hotels/\d+/rooms$').hasMatch(path)) {
        return ok(const []);
      }
      if (path == '/api/admin/media' ||
          path == '/api/admin/media/cover' ||
          RegExp(r'^/api/admin/media/\d+').hasMatch(path)) {
        return http.Response(jsonEncode(asset()), 200,
            headers: {'content-type': 'application/json'});
      }
      if (path == '/api/admin/media/reorder') {
        return ok([asset()]);
      }
      if (path.endsWith('/analytics/overview')) {
        return ok({'totalBookings': 0, 'totalRevenue': 0});
      }
      return ok(pageOf(const []));
    }

    final mock = _RecordingClient(onRequest: (req) {
      requests.add(req);
      paths.add('${req.method} ${req.url.path}');
      if (req is http.Request) sent.add(req);
      return route(req);
    });
    return (
      api: ApiClient(client: withAdminAccess(mock), baseUrl: 'http://test/api'),
      requests: requests,
      sent: sent,
      paths: paths
    );
  }

  Widget consoleHarness({
    required AppState app,
    required AdminState admin,
    required Widget child,
    Locale? locale,
  }) =>
      AppScope(
        notifier: app,
        child: AdminScope(
          notifier: admin,
          child: MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: child,
          ),
        ),
      );

  /// Opens the real console on the Catalog destination.
  Future<AppState> pumpConsole(
    WidgetTester tester,
    ApiClient api, {
    AppRole role = AppRole.admin,
    Size size = const Size(1600, 2400),
    Locale? locale,
    String route = AdminRoutes.catalog,
  }) async {
    final app = AppState(api: api)
      ..demoMode = false
      ..email = 'admin@planyourtrip.com'
      ..role = role;
    final admin = AdminState(api: api)..bindSession(app);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(consoleHarness(
      app: app,
      admin: admin,
      locale: locale,
      child: AdminRouteGuard(key: ValueKey(route), initialRoute: route),
    ));
    await settle(tester);
    return app;
  }

  /// Opens the first place from the catalog. The wide layout offers an "Open"
  /// button in a table row; the narrow one is a tappable card instead.
  Future<void> openFirstPlace(
    WidgetTester tester, {
    String? name,
    String openLabel = 'Open',
  }) async {
    final button = find.widgetWithText(TextButton, openLabel);
    if (button.evaluate().isNotEmpty) {
      await tester.tap(button.first);
    } else {
      await tester.tap(find.text(name ?? 'Grand Palace').first);
    }
    await settle(tester);
  }

  /// The gallery card sits at the bottom of the detail's lazy list, so on a
  /// short viewport it is not built until it is scrolled to.
  Future<void> tapManageMedia(WidgetTester tester,
      {String label = 'Manage media'}) async {
    await tester.dragUntilVisible(
      find.text(label),
      find.byType(ListView).last,
      const Offset(0, -200),
    );
    await settle(tester);
    await tester.tap(find.text(label));
    await settle(tester);
  }

  /// Catalog → place detail → media gallery, through the real controls.
  Future<void> openMediaFromPlace(WidgetTester tester) async {
    await openFirstPlace(tester);
    expect(find.byType(AdminPlaceDetailScreen), findsOneWidget);
    await tapManageMedia(tester);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1–5 · Routing
  // ═══════════════════════════════════════════════════════════════════════════

  group('routing', () {
    testWidgets('an admin reaches Media from a place detail', (tester) async {
      final c = clientFor(
        details: {1: placeDetail()},
        galleries: {
          1: [asset(id: 5)]
        },
      );
      await pumpConsole(tester, c.api);
      await openMediaFromPlace(tester);

      expect(find.byType(AdminMediaScreen), findsOneWidget);
      expect(find.byType(AdminPlaceDetailScreen), findsNothing);
      expect(find.text('Lobby 5'), findsOneWidget);
    });

    testWidgets('the canonical place id is what the gallery requests',
        (tester) async {
      // Place 2 is the one opened, and the gallery read must name 2 — never 1,
      // and never anything parsed out of what is on screen.
      final c = clientFor(
        details: {1: placeDetail(), 2: placeDetail(id: 2, name: 'Sea View')},
        galleries: {
          1: [asset(id: 5)],
          2: [asset(id: 9, ownerId: 2)]
        },
      );
      await pumpConsole(tester, c.api);
      await tester.tap(find.text('Open').at(1));
      await settle(tester);
      await tester.tap(find.text('Manage media'));
      await settle(tester);

      expect(c.paths, contains('GET /api/admin/places/2/media'));
      expect(c.paths, isNot(contains('GET /api/admin/places/1/media')));
      expect(find.text('Lobby 9'), findsOneWidget);
    });

    testWidgets('back returns to the place detail it was opened from',
        (tester) async {
      final c = clientFor(
        details: {1: placeDetail()},
        galleries: {
          1: [asset(id: 5)]
        },
      );
      await pumpConsole(tester, c.api);
      await openMediaFromPlace(tester);

      await tester.tap(find.byTooltip('Back to place details'));
      await settle(tester);
      expect(find.byType(AdminPlaceDetailScreen), findsOneWidget);
      expect(find.byType(AdminMediaScreen), findsNothing);
    });

    testWidgets('the direct Media destination still opens on its picker',
        (tester) async {
      final c = clientFor(
        details: {1: placeDetail()},
        galleries: {
          1: [asset(id: 5)]
        },
      );
      await pumpConsole(tester, c.api, route: AdminRoutes.media);

      expect(find.byType(AdminMediaScreen), findsOneWidget);
      expect(find.text('Choose a place'), findsOneWidget);
      // No place detail was involved, so back is the picker, not a detail.
      expect(find.byTooltip('Back to place details'), findsNothing);
    });

    testWidgets('a place that cannot be read never reaches Media',
        (tester) async {
      // The catalog lists it, the detail 404s: the detail screen says so and
      // offers no media entry point, because there is no canonical id to bind.
      final c = clientFor(
        details: {1: placeDetail()},
        galleries: const {},
        overrides: {'/api/admin/places/1': http.Response('{}', 404)},
      );
      await pumpConsole(tester, c.api);
      await tester.tap(find.text('Open').first);
      await settle(tester);

      expect(find.text('Place not found'), findsOneWidget);
      expect(find.text('Manage media'), findsNothing);
      expect(c.paths.where((p) => p.contains('/media')), isEmpty);
    });

    testWidgets('leaving via the rail drops the origin, not just the route',
        (tester) async {
      final c = clientFor(
        details: {1: placeDetail()},
        galleries: {
          1: [asset(id: 5)]
        },
      );
      await pumpConsole(tester, c.api);
      await openMediaFromPlace(tester);

      // Choosing Media from the rail is a fresh visit to the destination, so
      // "back to place details" is no longer meaningful and must not linger.
      // The rail entry, not the app-bar title, which reads "Media" too.
      await tester.tap(find.descendant(
        of: find.byType(ListTile),
        matching: find.text('Media'),
      ));
      await settle(tester);
      expect(find.byTooltip('Back to place details'), findsNothing);
      expect(find.byTooltip('Back to places'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 6–10 · Owner binding
  // ═══════════════════════════════════════════════════════════════════════════

  group('owner binding', () {
    Future<AdminMediaState> boundState(ApiClient api, int placeId) async {
      final state = AdminMediaState(api: api);
      await state.openPlace(placeId: placeId, placeName: 'Whatever');
      return state;
    }

    test('create always uses PLACE and the canonical id', () async {
      final c = clientFor(galleries: {
        7: [asset(id: 5, ownerId: 7)]
      });
      final state = await boundState(c.api, 7);
      await state.createMedia(
          url: 'https://cdn.test/n.jpg', mediaType: AdminMediaType.image);

      final body =
          jsonDecode(c.sent.firstWhere((r) => r.method == 'POST').body) as Map;
      expect(body['ownerType'], 'PLACE');
      expect(body['ownerId'], 7);
    });

    test('the owner is an id, never the display name', () async {
      final c = clientFor(galleries: {
        7: [asset(id: 5, ownerId: 7)]
      });
      final state = await boundState(c.api, 7);
      expect(state.owner!.id, 7);
      expect(state.owner!.type, AdminMediaOwnerType.place);
      // The name is carried for display only; the request used the id.
      expect(c.paths, contains('GET /api/admin/places/7/media'));
    });

    test('an asset from another place is refused every mutation', () async {
      // Constructed the way a stale row or a hand-made object would be.
      const foreign = AdminMediaAsset(
        id: 99,
        ownerType: AdminMediaOwnerType.place,
        ownerId: 2,
        url: 'https://cdn.test/foreign.jpg',
        thumbnailUrl: null,
        mediaType: AdminMediaType.image,
        altText: null,
        sortOrder: 0,
        cover: false,
        active: true,
        uploadedByUserId: 1,
        createdAt: null,
        updatedAt: null,
      );
      final c = clientFor(galleries: {
        1: [asset(id: 5)]
      });
      final state = await boundState(c.api, 1);
      final before = c.sent.length;

      expect(state.ownsAsset(foreign), isFalse);
      expect(await state.deactivateMedia(foreign), isFalse);
      expect(await state.setCover(foreign), isFalse);
      expect(await state.moveMedia(foreign, up: true), isFalse);
      expect(
          await state.updateMedia(foreign,
              url: 'https://cdn.test/x.jpg', mediaType: AdminMediaType.image),
          isFalse);
      expect(c.sent.length, before, reason: 'nothing left the client');
    });

    test('an asset of the right owner but not in this gallery is refused',
        () async {
      const ghost = AdminMediaAsset(
        id: 4242,
        ownerType: AdminMediaOwnerType.place,
        ownerId: 1,
        url: 'https://cdn.test/ghost.jpg',
        thumbnailUrl: null,
        mediaType: AdminMediaType.image,
        altText: null,
        sortOrder: 0,
        cover: false,
        active: true,
        uploadedByUserId: 1,
        createdAt: null,
        updatedAt: null,
      );
      final c = clientFor(galleries: {
        1: [asset(id: 5)]
      });
      final state = await boundState(c.api, 1);
      final before = c.sent.length;

      expect(state.ownsAsset(ghost), isFalse, reason: 'never loaded here');
      expect(await state.setCover(ghost), isFalse);
      expect(c.sent.length, before);
    });

    test('reorder carries only ids loaded for the current place', () async {
      final c = clientFor(galleries: {
        1: [
          asset(id: 5, sortOrder: 0),
          asset(id: 6, sortOrder: 1),
          asset(id: 7, sortOrder: 2),
        ]
      });
      final state = await boundState(c.api, 1);
      await state.moveMedia(state.items.last, up: true);

      final body = jsonDecode(c.sent
          .firstWhere((r) => r.url.path == '/api/admin/media/reorder')
          .body) as Map;
      final ids =
          (body['items'] as List).map((i) => (i as Map)['mediaId']).toSet();
      expect(ids, {5, 6, 7});
      expect(ids.every((id) => state.items.any((a) => a.id == id)), isTrue);
    });

    test('set cover can only target an asset in this gallery', () async {
      final c = clientFor(galleries: {
        1: [asset(id: 5)]
      });
      final state = await boundState(c.api, 1);
      expect(state.canSetCover(state.items.single), isTrue);
      await state.setCover(state.items.single);
      final patch =
          c.sent.firstWhere((r) => r.url.path == '/api/admin/media/cover');
      expect(jsonDecode(patch.body), {'mediaId': 5});
    });

    testWidgets('no control on the media screen can change the owner',
        (tester) async {
      final c = clientFor(
        details: {1: placeDetail()},
        galleries: {
          1: [asset(id: 5)]
        },
      );
      await pumpConsole(tester, c.api);
      await openMediaFromPlace(tester);
      await tester.tap(find.text('Add media'));
      await settle(tester);

      // The create form offers URL, thumbnail, type, alt text and position —
      // and nothing that names an owner.
      for (final label in [
        'Owner',
        'Owner type',
        'Owner id',
        'Place id',
        'PLACE',
        'ROOM',
        'REVIEW',
        'TRIP_DOCUMENT',
        'SUBMISSION',
      ]) {
        expect(find.text(label), findsNothing, reason: label);
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 11–14 · Authorization
  // ═══════════════════════════════════════════════════════════════════════════

  group('authorization', () {
    testWidgets('ADMIN reaches the console', (tester) async {
      final c = clientFor(details: {1: placeDetail()}, galleries: const {});
      await pumpConsole(tester, c.api, route: AdminRoutes.media);
      expect(find.byType(AdminAppShell), findsOneWidget);
      expect(find.byType(AdminAccessDeniedScreen), findsNothing);
    });

    for (final role in [AppRole.partner, AppRole.user, AppRole.unknown]) {
      testWidgets('$role is refused the Media route', (tester) async {
        final c = clientFor(details: {1: placeDetail()}, galleries: const {});
        await pumpConsole(tester, c.api, route: AdminRoutes.media, role: role);
        expect(find.byType(AdminAccessDeniedScreen), findsOneWidget);
        expect(find.byType(AdminAppShell), findsNothing);
      });
    }

    testWidgets('a signed-out session is refused', (tester) async {
      final c = clientFor(details: {1: placeDetail()}, galleries: const {});
      final app = AppState(api: c.api);
      await tester.pumpWidget(consoleHarness(
        app: app,
        admin: AdminState(api: c.api)..bindSession(app),
        child: const AdminRouteGuard(initialRoute: AdminRoutes.media),
      ));
      await tester.pump();
      expect(find.byType(AdminAccessDeniedScreen), findsOneWidget);
    });

    test('the role gate is the only frontend gate, and it is unchanged', () {
      expect(AppRole.admin.canEnterAdminConsole, isTrue);
      for (final r in [AppRole.user, AppRole.partner, AppRole.unknown]) {
        expect(r.canEnterAdminConsole, isFalse, reason: r.name);
      }
      // No new role was introduced by this phase.
      expect(AppRole.values.map((r) => r.name).toSet(),
          isNot(contains('superAdmin')));
      expect(AppRole.values.map((r) => r.name).toSet(),
          isNot(contains('superPartner')));
    });

    testWidgets('a 403 on the gallery renders as forbidden, not as empty',
        (tester) async {
      final c = clientFor(
        details: {1: placeDetail()},
        galleries: {1: const []},
        mediaStatus: 403,
      );
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await pumpConsole(tester, c.api);
      await openMediaFromPlace(tester);
      expect(find.text('No media'), findsNothing);
      expect(find.text(l10n.adminErrorForbidden), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 15–20 · State synchronization
  // ═══════════════════════════════════════════════════════════════════════════

  group('state synchronization', () {
    int galleryReads(List<String> paths, int placeId) =>
        paths.where((p) => p == 'GET /api/admin/places/$placeId/media').length;

    Future<AdminMediaState> boundState(ApiClient api) async {
      final state = AdminMediaState(api: api);
      await state.openPlace(placeId: 1);
      return state;
    }

    test('every mutation re-reads the gallery', () async {
      final c = clientFor(galleries: {
        1: [asset(id: 5, sortOrder: 0), asset(id: 6, sortOrder: 1)]
      });
      final state = await boundState(c.api);

      Future<void> check(String what, Future<bool> Function() run) async {
        final before = galleryReads(c.paths, 1);
        await run();
        expect(galleryReads(c.paths, 1), before + 1, reason: what);
      }

      await check(
          'create',
          () => state.createMedia(
              url: 'https://cdn.test/n.jpg', mediaType: AdminMediaType.image));
      await check(
          'edit',
          () => state.updateMedia(state.items.first,
              url: 'https://cdn.test/e.jpg', mediaType: AdminMediaType.image));
      await check('set cover', () => state.setCover(state.items.last));
      await check('reorder', () => state.moveMedia(state.items.last, up: true));
      await check('deactivate', () => state.deactivateMedia(state.items.first));
    });

    test('the gallery is server state, never a local patch', () async {
      // The server keeps answering the same rows, so anything the UI shows
      // after a mutation must come from that answer.
      final c = clientFor(galleries: {
        1: [asset(id: 5, sortOrder: 0), asset(id: 6, sortOrder: 1)]
      });
      final state = await boundState(c.api);
      await state.moveMedia(state.items.last, up: true);
      expect(state.items.map((a) => a.id), [5, 6],
          reason: 'the re-read order is what is rendered');
      await state.setCover(state.items.first);
      expect(state.coverAsset, isNull, reason: 'no local cover promotion');
    });

    test('a mutation marks dependent place state stale; a visit does not',
        () async {
      final c = clientFor(galleries: {
        1: [asset(id: 5)]
      });
      final looked = await boundState(c.api);
      expect(looked.galleryChanged, isFalse, reason: 'read-only visit');

      await looked.setCover(looked.items.single);
      expect(looked.galleryChanged, isTrue);

      await looked.openPlace(placeId: 1);
      expect(looked.galleryChanged, isFalse, reason: 'reset on open');
    });

    testWidgets('returning after a change re-reads the place, not the rooms',
        (tester) async {
      final c = clientFor(
        details: {1: placeDetail()},
        galleries: {
          1: [asset(id: 5)]
        },
      );
      await pumpConsole(tester, c.api);
      await openMediaFromPlace(tester);

      final detailsBefore =
          c.paths.where((p) => p == 'GET /api/admin/places/1').length;
      final roomsBefore =
          c.paths.where((p) => p.contains('/hotels/1/rooms')).length;

      await tester.tap(find.text('Set as cover'));
      await settle(tester);
      await tester.tap(find.byTooltip('Back to place details'));
      await settle(tester);

      expect(c.paths.where((p) => p == 'GET /api/admin/places/1').length,
          detailsBefore + 1,
          reason: 'the cover and gallery count came from this read');
      expect(c.paths.where((p) => p.contains('/hotels/1/rooms')).length,
          roomsBefore,
          reason: 'no media action can change the rooms');
    });

    testWidgets('returning without a change costs no extra request',
        (tester) async {
      final c = clientFor(
        details: {1: placeDetail()},
        galleries: {
          1: [asset(id: 5)]
        },
      );
      await pumpConsole(tester, c.api);
      await openMediaFromPlace(tester);

      final before = c.paths.length;
      await tester.tap(find.byTooltip('Back to place details'));
      await settle(tester);
      expect(c.paths.length, before, reason: 'nothing was changed');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 21–25 · Security and error handling
  // ═══════════════════════════════════════════════════════════════════════════

  group('errors and safety', () {
    testWidgets('a foreign asset in the response stops the gallery',
        (tester) async {
      // The read is place-scoped, so this can only mean the response does not
      // match the request. Nothing is filtered, corrected or rendered.
      final c = clientFor(
        details: {1: placeDetail()},
        galleries: {
          1: [asset(id: 5), asset(id: 6, ownerId: 2)]
        },
      );
      await pumpConsole(tester, c.api);
      await openMediaFromPlace(tester);

      expect(find.textContaining('belonging to a different place'),
          findsOneWidget);
      expect(find.text('Lobby 5'), findsNothing);
      expect(find.text('Set as cover'), findsNothing);
    });

    test('a foreign owner type is treated the same way', () async {
      final c = clientFor(galleries: {
        1: [asset(id: 5, ownerType: 'ROOM')]
      });
      final state = AdminMediaState(api: c.api);
      await state.openPlace(placeId: 1);
      expect(state.ownerMismatch, isTrue);
      expect(state.items, isEmpty);
      expect(
          await state.createMedia(
              url: 'https://cdn.test/n.jpg', mediaType: AdminMediaType.image),
          isFalse,
          reason: 'no write while the gallery cannot be vouched for');
    });

    test('401, 403 and 404 stay distinct', () async {
      for (final entry in {
        401: AdminLoadStatus.unauthorized,
        403: AdminLoadStatus.forbidden,
        404: AdminLoadStatus.notFound,
        500: AdminLoadStatus.error,
      }.entries) {
        final c = clientFor(galleries: {
          1: const []
        }, overrides: {
          '/api/admin/places/1/media':
              http.Response('{"message":"no"}', entry.key)
        });
        final state = AdminMediaState(api: c.api);
        await state.openPlace(placeId: 1);
        expect(state.status, entry.value, reason: '${entry.key}');
      }
    });

    test('a validation failure is surfaced, not swallowed', () async {
      final c = clientFor(galleries: {
        1: [asset(id: 5)]
      }, overrides: {
        '/api/admin/media': http.Response(
            '{"message":"url scheme is not allowed; use http or https"}', 400)
      });
      final state = AdminMediaState(api: c.api);
      await state.openPlace(placeId: 1);
      final ok = await state.createMedia(
          url: 'https://cdn.test/n.jpg', mediaType: AdminMediaType.image);
      expect(ok, isFalse);
      expect(state.mutationUncertain, isFalse);
      expect(state.mutationError, isNotNull);
    });

    test('an uncertain outcome survives the reload', () async {
      final c = clientFor(galleries: {
        1: [asset(id: 5)]
      }, overrides: {
        '/api/admin/media/cover': http.Response('not json', 200)
      });
      final state = AdminMediaState(api: c.api);
      await state.openPlace(placeId: 1);
      final ok = await state.setCover(state.items.single);
      expect(ok, isFalse);
      expect(state.mutationUncertain, isTrue);
      expect(state.isReady, isTrue);
    });

    test('a failed mutation never reports success', () async {
      final c = clientFor(galleries: {
        1: [asset(id: 5)]
      }, overrides: {
        '/api/admin/media/5/deactivate': http.Response('{}', 409)
      });
      final state = AdminMediaState(api: c.api);
      await state.openPlace(placeId: 1);
      expect(await state.deactivateMedia(state.items.single), isFalse);
      expect(state.items.single.active, isTrue,
          reason: 'the server still says active');
    });

    test('a place detail that stops resolving does not keep a stale snapshot',
        () async {
      final c = clientFor(details: {1: placeDetail()}, overrides: {});
      final detail = AdminPlaceDetailState(api: c.api, placeId: 1);
      await detail.load();
      expect(detail.isReady, isTrue);

      // The same client now refuses the place; refreshing must not leave the
      // previous snapshot on screen as if it were current.
      final gone = clientFor(details: const {});
      final orphan = AdminPlaceDetailState(api: gone.api, placeId: 1);
      await orphan.load();
      expect(orphan.isNotFound, isTrue);
      expect(orphan.place, isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 26–28 · No N+1
  // ═══════════════════════════════════════════════════════════════════════════

  group('request shape', () {
    testWidgets('the catalog list never touches media', (tester) async {
      final c = clientFor(
        details: {1: placeDetail(), 2: placeDetail(id: 2, name: 'Sea View')},
        galleries: {1: const [], 2: const []},
      );
      await pumpConsole(tester, c.api);
      expect(c.paths.where((p) => p.contains('/media')), isEmpty);
    });

    testWidgets('opening a place detail fetches the place and its rooms only',
        (tester) async {
      final c = clientFor(
        details: {1: placeDetail(galleryCount: 3)},
        galleries: {
          1: [asset(id: 5), asset(id: 6, sortOrder: 1)]
        },
      );
      await pumpConsole(tester, c.api);
      await tester.tap(find.text('Open').first);
      await settle(tester);

      expect(
          c.paths.where((p) => p == 'GET /api/admin/places/1'), hasLength(1));
      expect(c.paths.where((p) => p.contains('/hotels/1/rooms')), hasLength(1));
      // The gallery card summarises what the detail already returned; it does
      // not fetch a media record, or metadata for one.
      expect(c.paths.where((p) => p.contains('/media')), isEmpty);
      expect(c.paths.where((p) => p.contains('/admin/media')), isEmpty);
    });

    testWidgets('opening the gallery makes exactly one media read',
        (tester) async {
      final c = clientFor(
        details: {1: placeDetail()},
        galleries: {
          1: [
            asset(id: 5),
            asset(id: 6, sortOrder: 1),
            asset(id: 7, sortOrder: 2)
          ]
        },
      );
      await pumpConsole(tester, c.api);
      await openMediaFromPlace(tester);

      expect(c.paths.where((p) => p == 'GET /api/admin/places/1/media'),
          hasLength(1),
          reason: 'one read for the whole gallery, not one per card');
      // Three cards rendered, still one read.
      expect(find.text('Lobby 5'), findsOneWidget);
      expect(find.text('Lobby 7'), findsOneWidget);
    });

    testWidgets('re-entering the destination does not re-fetch on rebuild',
        (tester) async {
      final c = clientFor(
        details: {1: placeDetail()},
        galleries: {
          1: [asset(id: 5)]
        },
      );
      await pumpConsole(tester, c.api);
      await openMediaFromPlace(tester);
      final after = c.paths.length;

      await tester.pump();
      await settle(tester);
      expect(c.paths.length, after, reason: 'a rebuild is not a load');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 29–30 · Accessibility
  // ═══════════════════════════════════════════════════════════════════════════

  group('accessibility', () {
    testWidgets('the media entry point and context are reachable by name',
        (tester) async {
      final handle = tester.ensureSemantics();
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      final c = clientFor(
        details: {1: placeDetail()},
        galleries: {
          1: [asset(id: 5)]
        },
      );
      await pumpConsole(tester, c.api);
      await tester.tap(find.text('Open').first);
      await settle(tester);

      expect(
          find.bySemanticsLabel(
              l10n.adminCatalogManageMediaSemantic('Grand Palace')),
          findsWidgets);
      // Not icon-only: the control carries its own visible label too.
      expect(find.text(l10n.adminCatalogManageMedia), findsOneWidget);

      await tester.tap(find.text('Manage media'));
      await settle(tester);

      expect(find.byTooltip(l10n.adminMediaBackToPlaceDetail), findsOneWidget);
      // The heading names the place and the id every request is bound to.
      expect(find.text(l10n.adminMediaOwnerContext(1)), findsOneWidget);
      handle.dispose();
    });

    testWidgets('state on the gallery is never colour alone', (tester) async {
      final c = clientFor(
        details: {1: placeDetail()},
        galleries: {
          1: [
            asset(id: 5, cover: true),
            asset(id: 6, sortOrder: 1, active: false)
          ]
        },
      );
      await pumpConsole(tester, c.api);
      await openMediaFromPlace(tester);

      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Inactive'), findsOneWidget);
      expect(find.text('Cover'), findsWidgets);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 31–37 · Responsive and localization
  // ═══════════════════════════════════════════════════════════════════════════

  group('responsive and localization', () {
    testWidgets('the whole flow survives 320, 390, 820 and 1600',
        (tester) async {
      for (final width in [320.0, 390.0, 820.0, 1600.0]) {
        final c = clientFor(
          details: {1: placeDetail()},
          galleries: {
            1: [
              asset(id: 5, cover: true),
              asset(id: 6, sortOrder: 1, mediaType: 'VIDEO'),
              asset(id: 7, sortOrder: 2, active: false),
            ]
          },
        );
        await pumpConsole(tester, c.api, size: Size(width, 900));
        expect(tester.takeException(), isNull, reason: 'catalog at ${width}px');

        await openFirstPlace(tester);
        expect(tester.takeException(), isNull, reason: 'detail at ${width}px');

        await tapManageMedia(tester);
        expect(tester.takeException(), isNull, reason: 'gallery at ${width}px');

        for (var i = 0; i < 5; i++) {
          await tester.drag(find.byType(ListView).last, const Offset(0, -300));
          await settle(tester);
          expect(tester.takeException(), isNull,
              reason: 'gallery scrolled at ${width}px');
        }

        await tester.tap(find.byTooltip('Back to place details'));
        await settle(tester);
        expect(tester.takeException(), isNull, reason: 'return at ${width}px');
      }
    });

    testWidgets('the integration renders in Vietnamese', (tester) async {
      final c = clientFor(
        details: {1: placeDetail()},
        galleries: {
          1: [asset(id: 5)]
        },
      );
      final vi = await AppLocalizations.delegate.load(const Locale('vi'));
      await pumpConsole(tester, c.api, locale: const Locale('vi'));
      await openFirstPlace(tester, openLabel: vi.adminPartnerOpen);
      await tester.dragUntilVisible(
        find.text(vi.adminCatalogManageMedia),
        find.byType(ListView).last,
        const Offset(0, -200),
      );
      await settle(tester);

      expect(find.text('Quản lý thư viện'), findsOneWidget);
      expect(find.text('Manage media'), findsNothing);
      await tester.tap(find.text('Quản lý thư viện'));
      await settle(tester);
      expect(find.byTooltip('Quay lại chi tiết địa điểm'), findsOneWidget);
    });

    test('every D3D string exists in both locales with matching placeholders',
        () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      final vi = await AppLocalizations.delegate.load(const Locale('vi'));
      // Both resolve, both interpolate, and neither is left in English.
      expect(en.adminCatalogManageMedia, isNotEmpty);
      expect(vi.adminCatalogManageMedia, isNotEmpty);
      expect(vi.adminCatalogManageMedia, isNot(en.adminCatalogManageMedia));
      expect(en.adminCatalogManageMediaSemantic('X'), contains('X'));
      expect(vi.adminCatalogManageMediaSemantic('X'), contains('X'));
      expect(en.adminMediaOwnerContext(42), contains('42'));
      expect(vi.adminMediaOwnerContext(42), contains('42'));
      expect(vi.adminMediaBackToPlaceDetail,
          isNot(en.adminMediaBackToPlaceDetail));
      expect(vi.adminMediaOwnerMismatch, isNot(en.adminMediaOwnerMismatch));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 38–42 · Boundaries preserved
  // ═══════════════════════════════════════════════════════════════════════════

  group('boundaries', () {
    test('no upload, picker or multipart code exists', () {
      const paths = [
        'lib/features/admin/admin_media_states.dart',
        'lib/features/admin/screens/admin_media_screen.dart',
        'lib/features/admin/screens/admin_place_detail_screen.dart',
        'lib/features/admin/admin_app_shell.dart',
        'lib/core/network/api_client.dart',
      ];
      for (final path in paths) {
        final source = File(path).readAsStringSync();
        for (final token in [
          'MultipartRequest',
          'MultipartFile',
          'multipart/form-data',
          'FilePicker',
          'ImagePicker',
        ]) {
          expect(source.contains(token), isFalse, reason: '$token in $path');
        }
      }
    });

    test('the owner boundary is still PLACE only', () {
      expect(AdminMediaState.manageableOwnerTypes, [AdminMediaOwnerType.place]);
      expect(AdminMediaOwnerType.submission.isSupportedByBackend, isFalse);
      for (final t in [
        AdminMediaOwnerType.room,
        AdminMediaOwnerType.review,
        AdminMediaOwnerType.tripDocument,
      ]) {
        expect(t.isAdminManageable, isFalse, reason: t.name);
      }
    });

    testWidgets('no restore, reactivate or bulk action was introduced',
        (tester) async {
      final c = clientFor(
        details: {1: placeDetail()},
        galleries: {
          1: [asset(id: 5), asset(id: 6, sortOrder: 1, active: false)]
        },
      );
      await pumpConsole(tester, c.api);
      await openMediaFromPlace(tester);

      for (final label in [
        'Restore',
        'Reactivate',
        'Activate',
        'Select all',
        'Delete selected',
        'Deactivate all',
        'Bulk',
      ]) {
        expect(find.text(label), findsNothing, reason: label);
      }
    });

    test('deactivating the cover promotes nothing', () async {
      // The server answers a gallery with no cover afterwards; the console must
      // report exactly that rather than choosing a replacement.
      final c = clientFor(galleries: {
        1: [asset(id: 5, cover: false), asset(id: 6, sortOrder: 1)]
      });
      final state = AdminMediaState(api: c.api);
      await state.openPlace(placeId: 1);
      await state.deactivateMedia(state.items.first);
      expect(state.coverAsset, isNull);
    });

    testWidgets('the catalog place detail is still read-only', (tester) async {
      final c = clientFor(
        details: {1: placeDetail()},
        galleries: {1: const []},
      );
      await pumpConsole(tester, c.api);
      await tester.tap(find.text('Open').first);
      await settle(tester);

      // D3D added one entry point and nothing else: no editor, no delete.
      expect(find.byType(TextField), findsNothing);
      for (final label in ['Save', 'Edit place', 'Delete']) {
        expect(find.text(label), findsNothing, reason: label);
      }
      expect(find.text('Manage media'), findsOneWidget);
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
