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
import 'package:planyourtrip_frontend/features/admin/admin_media_states.dart';
import 'package:planyourtrip_frontend/features/admin/admin_navigation.dart';
import 'package:planyourtrip_frontend/features/admin/admin_routes.dart';
import 'package:planyourtrip_frontend/features/admin/screens/admin_media_screen.dart';
import 'package:planyourtrip_frontend/features/admin/widgets/admin_widgets.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// D3C-B — Admin Media.
///
/// Fixtures mirror `MediaAssetResponse` on `develop@5afaa45`. Where a test
/// asserts an absence — no upload, no multipart, no reactivate, no owner
/// selector beyond PLACE — that absence is the requirement, because the backend
/// exposes nothing behind it.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // A short settle budget, so a tree that never stops scheduling frames fails
  // in seconds instead of burning the framework's ten-minute default.
  Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5));

  Map<String, dynamic> placeRow({int id = 1, String name = 'Grand Palace'}) => {
        'id': id,
        'name': name,
        'slug': 'grand-palace',
        'category': {'id': 9, 'name': 'Accommodation', 'slug': 'acc'},
        'subcategory': null,
        'administrativeUnit': {'id': 3, 'name': 'Vung Tau', 'slug': 'vt'},
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

  Map<String, dynamic> asset({
    int id = 5,
    String url = 'https://cdn.test/a.jpg',
    String? thumbnailUrl,
    String mediaType = 'IMAGE',
    String? altText = 'Lobby',
    int sortOrder = 0,
    bool cover = false,
    bool active = true,
  }) =>
      {
        'id': id,
        'ownerType': 'PLACE',
        'ownerId': 1,
        'url': url,
        'thumbnailUrl': thumbnailUrl,
        'mediaType': mediaType,
        'altText': altText,
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

  http.Response ok(Object json) => http.Response(jsonEncode(json), 200,
      headers: {'content-type': 'application/json'});

  http.Response created(Object json) => http.Response(jsonEncode(json), 201,
      headers: {'content-type': 'application/json'});

  ({ApiClient api, List<http.BaseRequest> requests, List<http.Request> sent})
      clientFor(Map<String, http.Response> Function(Uri uri) route,
          {Duration? delay}) {
    final requests = <http.BaseRequest>[];
    final sent = <http.Request>[];
    final mock = _RecordingClient(
        delay: delay,
        onRequest: (req) {
          requests.add(req);
          if (req is http.Request) sent.add(req);
          return route(req.url)[req.url.path] ??
              http.Response('{"message":"unmapped ${req.url.path}"}', 500);
        });
    return (
      api: ApiClient(client: mock, baseUrl: 'http://test/api'),
      requests: requests,
      sent: sent
    );
  }

  Map<String, http.Response> routes({
    List<Map<String, dynamic>>? gallery,
    http.Response? galleryOverride,
  }) =>
      {
        '/api/admin/places': ok(pageOf([placeRow()])),
        '/api/admin/places/1/media':
            galleryOverride ?? ok(gallery ?? [asset()]),
        '/api/admin/media': created(asset(id: 9)),
        '/api/admin/media/5': ok(asset(id: 5, altText: 'Updated')),
        '/api/admin/media/5/deactivate': ok(asset(id: 5, active: false)),
        '/api/admin/media/cover': ok(asset(id: 5, cover: true)),
        '/api/admin/media/reorder': ok([asset(id: 5)]),
      };

  Widget harness(Widget child, {Locale? locale}) => MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  /// Selects the fixture place so a test can start on the gallery.
  Future<AdminMediaState> galleryState(ApiClient api) async {
    final state = AdminMediaState(api: api);
    await state.searchPlaces('');
    await state.selectPlace(state.placeOptions.single);
    return state;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1 · Route and admission
  // ═══════════════════════════════════════════════════════════════════════════

  group('route', () {
    test('Media is a registered admin destination', () {
      final d = AdminNavigation.byRoute(AdminRoutes.media);
      expect(d, isNotNull);
      expect(d!.section, AdminSection.catalog);
      expect(AdminRoutes.isAdminRoute(AdminRoutes.media), isTrue);
    });

    testWidgets('a signed-out session is refused the Media route',
        (tester) async {
      final app = AppState();
      await tester.pumpWidget(AppScope(
        notifier: app,
        child: AdminScope(
          notifier: AdminState(api: app.api),
          child:
              harness(const AdminRouteGuard(initialRoute: AdminRoutes.media)),
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
  // 2 · Owner scope — only what the admin API can actually manage
  // ═══════════════════════════════════════════════════════════════════════════

  group('owner scope', () {
    test('PLACE is the only manageable owner', () {
      // `AdminMediaController` has exactly one admin read and it is
      // place-scoped, so an asset created against any other owner could never
      // be found again from this console.
      expect(AdminMediaState.manageableOwnerTypes, [AdminMediaOwnerType.place]);
      expect(AdminMediaOwnerType.place.isAdminManageable, isTrue);
      for (final t in [
        AdminMediaOwnerType.room,
        AdminMediaOwnerType.review,
        AdminMediaOwnerType.tripDocument,
        AdminMediaOwnerType.submission,
      ]) {
        expect(t.isAdminManageable, isFalse, reason: t.name);
      }
    });

    test('SUBMISSION is not supported by the backend at all', () {
      // `validateOwnerExists` answers 400 for it: there is no such entity.
      expect(AdminMediaOwnerType.submission.isSupportedByBackend, isFalse);
      expect(AdminMediaOwnerType.place.isSupportedByBackend, isTrue);
    });

    test('an unrecognised owner or type parses to unknown, never a guess', () {
      expect(
          AdminMediaOwnerType.parse('SOMETHING'), AdminMediaOwnerType.unknown);
      expect(AdminMediaType.parse('AUDIO'), AdminMediaType.unknown);
      expect(AdminMediaType.unknown.canBeCover, isFalse);
      expect(AdminMediaType.unknown.isRenderableAsImage, isFalse);
    });

    testWidgets('no owner-type selector is rendered anywhere', (tester) async {
      final c = clientFor((_) => routes());
      final state = await galleryState(c.api);
      await tester.pumpWidget(harness(AdminMediaScreen(state: state)));
      await settle(tester);

      for (final wire in ['ROOM', 'REVIEW', 'TRIP_DOCUMENT', 'SUBMISSION']) {
        expect(find.text(wire), findsNothing, reason: wire);
      }
    });

    test('the create request always targets the selected place', () async {
      final c = clientFor((_) => routes());
      final state = await galleryState(c.api);
      await state.createMedia(
          url: 'https://cdn.test/new.jpg', mediaType: AdminMediaType.image);
      final body =
          jsonDecode(c.sent.firstWhere((r) => r.method == 'POST').body) as Map;
      expect(body['ownerType'], 'PLACE');
      expect(body['ownerId'], 1);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 3 · Gallery states
  // ═══════════════════════════════════════════════════════════════════════════

  group('gallery', () {
    test('loads the place gallery, including inactive assets', () async {
      final c = clientFor((_) => routes(gallery: [
            asset(id: 5, sortOrder: 0, cover: true),
            asset(id: 6, sortOrder: 1, active: false),
          ]));
      final state = await galleryState(c.api);
      expect(state.status, AdminLoadStatus.ready);
      expect(state.items.map((a) => a.id), [5, 6]);
      expect(state.items.last.active, isFalse);
      expect(state.coverAsset?.id, 5);
    });

    test('an empty gallery is empty, not an error', () async {
      final c = clientFor((_) => routes(gallery: const []));
      final state = await galleryState(c.api);
      expect(state.status, AdminLoadStatus.ready);
      expect(state.isEmpty, isTrue);
    });

    test('a 403 becomes forbidden, a 404 becomes notFound', () async {
      final forbidden =
          clientFor((_) => routes(galleryOverride: http.Response('{}', 403)));
      expect((await galleryState(forbidden.api)).status,
          AdminLoadStatus.forbidden);

      // The controller resolves the place before delegating, so 404 means the
      // place is gone — not that it has no media.
      final missing =
          clientFor((_) => routes(galleryOverride: http.Response('{}', 404)));
      expect(
          (await galleryState(missing.api)).status, AdminLoadStatus.notFound);
    });

    test('a gallery with no cover reports none rather than guessing', () async {
      final c = clientFor((_) => routes(gallery: [asset(id: 5, cover: false)]));
      final state = await galleryState(c.api);
      expect(state.coverAsset, isNull);
    });

    test('a deactivated cover is not treated as the cover', () async {
      final c = clientFor(
          (_) => routes(gallery: [asset(id: 5, cover: true, active: false)]));
      final state = await galleryState(c.api);
      expect(state.coverAsset, isNull);
    });

    test('duplicate positions are reported, not silently reordered', () async {
      // The admin read sorts by sortOrder alone, with no id tiebreaker.
      final c = clientFor((_) => routes(gallery: [
            asset(id: 5, sortOrder: 1),
            asset(id: 6, sortOrder: 1),
          ]));
      final state = await galleryState(c.api);
      expect(state.hasAmbiguousOrder, isTrue);
      expect(state.items.map((a) => a.id), [5, 6],
          reason: 'server order is preserved, not re-sorted locally');
    });

    testWidgets('renders loading, then the loaded rows', (tester) async {
      // Driven entirely through the UI on a delayed client, so the loading
      // frame is actually rendered instead of being skipped by a mock that
      // resolves before the first frame.
      final c =
          clientFor((_) => routes(), delay: const Duration(milliseconds: 30));
      final state = AdminMediaState(api: c.api);
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      await tester.pumpWidget(harness(AdminMediaScreen(state: state)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tap(find.text('Grand Palace'));
      await tester.pump();

      expect(find.text(l10n.adminLoading), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      await tester.pump(const Duration(milliseconds: 60));
      await settle(tester);
      expect(find.textContaining('cdn.test/a.jpg'), findsOneWidget);
      expect(find.text('Lobby'), findsOneWidget);
    });

    testWidgets('an empty gallery shows the empty state', (tester) async {
      final c = clientFor((_) => routes(gallery: const []));
      final state = await galleryState(c.api);
      await tester.pumpWidget(harness(AdminMediaScreen(state: state)));
      await settle(tester);
      expect(find.text('No media'), findsOneWidget);
    });

    testWidgets('an API error shows a retryable error state', (tester) async {
      final c =
          clientFor((_) => routes(galleryOverride: http.Response('{}', 500)));
      final state = await galleryState(c.api);
      await tester.pumpWidget(harness(AdminMediaScreen(state: state)));
      await settle(tester);
      expect(state.status, AdminLoadStatus.error);
      expect(find.byType(AdminStateView), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 4 · Place picker
  // ═══════════════════════════════════════════════════════════════════════════

  group('place picker', () {
    testWidgets('opens on a picker and selects a place', (tester) async {
      final c = clientFor((_) => routes());
      final state = AdminMediaState(api: c.api);
      await tester.pumpWidget(harness(AdminMediaScreen(state: state)));
      await settle(tester);

      expect(find.text('Choose a place'), findsOneWidget);
      await tester.tap(find.text('Grand Palace'));
      await settle(tester);
      expect(state.owner?.id, 1);
      expect(find.text('Add media'), findsOneWidget);
    });

    testWidgets('returning to the picker drops the previous gallery',
        (tester) async {
      final c = clientFor((_) => routes());
      final state = await galleryState(c.api);
      await tester.pumpWidget(harness(AdminMediaScreen(state: state)));
      await settle(tester);

      await tester.tap(find.byTooltip('Back to places'));
      await settle(tester);
      expect(state.owner, isNull);
      expect(state.items, isEmpty);
      expect(find.text('Choose a place'), findsOneWidget);
    });

    test('the picker asks for one bounded page, not every place', () async {
      final c = clientFor((_) => routes());
      final state = AdminMediaState(api: c.api);
      await state.searchPlaces('palace');
      final uri = c.requests
          .map((r) => r.url)
          .lastWhere((u) => u.path == '/api/admin/places');
      expect(uri.queryParameters['q'], 'palace');
      expect(
          uri.queryParameters['size'], '${AdminMediaState.placeOptionLimit}');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 5 · Create
  // ═══════════════════════════════════════════════════════════════════════════

  group('create', () {
    test('sends the MediaAssetRequest shape and omits blank optionals',
        () async {
      final c = clientFor((_) => routes());
      final state = await galleryState(c.api);
      await state.createMedia(
        url: '  https://cdn.test/new.jpg  ',
        mediaType: AdminMediaType.image,
        altText: '  Pool  ',
        sortOrder: 3,
      );

      final post = c.sent.firstWhere((r) => r.method == 'POST');
      expect(post.url.path, '/api/admin/media');
      expect(jsonDecode(post.body), {
        'ownerType': 'PLACE',
        'ownerId': 1,
        'url': 'https://cdn.test/new.jpg',
        'mediaType': 'IMAGE',
        'altText': 'Pool',
        'sortOrder': 3,
      });
    });

    test('cover is sent only when it was asked for', () async {
      final c = clientFor((_) => routes());
      final state = await galleryState(c.api);
      await state.createMedia(
          url: 'https://cdn.test/n.jpg', mediaType: AdminMediaType.image);
      expect(jsonDecode(c.sent.firstWhere((r) => r.method == 'POST').body),
          isNot(contains('cover')));

      await state.createMedia(
          url: 'https://cdn.test/n2.jpg',
          mediaType: AdminMediaType.image,
          cover: true);
      final second = c.sent.where((r) => r.method == 'POST').toList()[1];
      expect((jsonDecode(second.body) as Map)['cover'], true);
    });

    test('a 201 is a success, not an unexpected status', () async {
      final c = clientFor((_) => routes());
      final state = await galleryState(c.api);
      final ok = await state.createMedia(
          url: 'https://cdn.test/n.jpg', mediaType: AdminMediaType.image);
      expect(ok, isTrue);
      expect(state.mutationError, isNull);
    });

    testWidgets('an obviously invalid URL is refused before any request',
        (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;

      final c = clientFor((_) => routes());
      final state = await galleryState(c.api);
      await tester.pumpWidget(harness(AdminMediaScreen(state: state)));
      await settle(tester);

      await tester.tap(find.text('Add media'));
      await settle(tester);

      // Mirrors MediaAssetService.validateUrl: absolute, http/https, with a
      // host. Nothing stricter — no host allowlist, no extension check.
      for (final bad in [
        'javascript:alert(1)',
        'data:image/png;base64,AAAA',
        'file:///etc/passwd',
        '//cdn.test/a.jpg',
        '/relative/a.jpg',
        'https://',
      ]) {
        await tester.enterText(find.byType(TextFormField).first, bad);
        await tester.tap(find.text('Register'));
        await settle(tester);
        expect(find.text('Enter an absolute http or https URL with a host.'),
            findsOneWidget,
            reason: bad);
        expect(c.sent.where((r) => r.method == 'POST'), isEmpty,
            reason: 'nothing was sent for $bad');
      }
    });

    testWidgets('a blank URL is refused with its own message', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;

      final c = clientFor((_) => routes());
      final state = await galleryState(c.api);
      await tester.pumpWidget(harness(AdminMediaScreen(state: state)));
      await settle(tester);
      await tester.tap(find.text('Add media'));
      await settle(tester);
      await tester.tap(find.text('Register'));
      await settle(tester);

      expect(find.text('A URL is required.'), findsOneWidget);
      expect(c.sent.where((r) => r.method == 'POST'), isEmpty);
    });

    testWidgets('a valid URL is accepted and posted', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;

      final c = clientFor((_) => routes());
      final state = await galleryState(c.api);
      await tester.pumpWidget(harness(AdminMediaScreen(state: state)));
      await settle(tester);
      await tester.tap(find.text('Add media'));
      await settle(tester);
      await tester.enterText(
          find.byType(TextFormField).first, 'http://cdn.test/ok.png');
      await tester.tap(find.text('Register'));
      await settle(tester);

      final post = c.sent.firstWhere((r) => r.method == 'POST');
      expect((jsonDecode(post.body) as Map)['url'], 'http://cdn.test/ok.png');
    });

    test('a backend validation error is surfaced, never a silent success',
        () async {
      final r = routes();
      r['/api/admin/media'] = http.Response(
          '{"message":"url scheme \'ftp\' is not allowed; use http or https"}',
          400);
      final c = clientFor((_) => r);
      final state = await galleryState(c.api);
      final ok = await state.createMedia(
          url: 'https://cdn.test/n.jpg', mediaType: AdminMediaType.image);
      expect(ok, isFalse);
      expect(state.mutationUncertain, isFalse);
      expect(state.mutationError, isNotNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 6 · Edit
  // ═══════════════════════════════════════════════════════════════════════════

  group('edit', () {
    test('PUTs to the asset and returns its own owner unchanged', () async {
      final c = clientFor((_) => routes());
      final state = await galleryState(c.api);
      await state.updateMedia(
        state.items.single,
        url: 'https://cdn.test/edited.jpg',
        mediaType: AdminMediaType.image,
        altText: 'Edited',
        sortOrder: 2,
      );

      final put = c.sent.firstWhere((r) => r.method == 'PUT');
      expect(put.url.path, '/api/admin/media/5');
      expect(jsonDecode(put.body), {
        'ownerType': 'PLACE',
        'ownerId': 1,
        'url': 'https://cdn.test/edited.jpg',
        'mediaType': 'IMAGE',
        'altText': 'Edited',
        'sortOrder': 2,
      });
    });

    testWidgets('the form prefills from the asset, URL in full',
        (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;

      final c = clientFor((_) =>
          routes(gallery: [asset(url: 'https://cdn.test/a.jpg?sig=abc123')]));
      final state = await galleryState(c.api);
      await tester.pumpWidget(harness(AdminMediaScreen(state: state)));
      await settle(tester);
      await tester.tap(find.text('Edit'));
      await settle(tester);

      // The list redacts the query; the editor must not, or saving would
      // silently rewrite what the operator registered.
      final field =
          tester.widget<TextFormField>(find.byType(TextFormField).first);
      expect(field.controller?.text, 'https://cdn.test/a.jpg?sig=abc123');
      expect(find.text('Lobby'), findsWidgets);
    });

    testWidgets('editing warns that the save replaces every field',
        (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;

      final c = clientFor((_) => routes());
      final state = await galleryState(c.api);
      await tester.pumpWidget(harness(AdminMediaScreen(state: state)));
      await settle(tester);
      await tester.tap(find.text('Edit'));
      await settle(tester);
      expect(find.textContaining('replaces every field'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 7 · Deactivate
  // ═══════════════════════════════════════════════════════════════════════════

  group('deactivate', () {
    test('PATCHes the deactivate path with no body', () async {
      final c = clientFor((_) => routes());
      final state = await galleryState(c.api);
      await state.deactivateMedia(state.items.single);
      final patch = c.sent
          .firstWhere((r) => r.url.path == '/api/admin/media/5/deactivate');
      expect(patch.method, 'PATCH');
      expect(patch.body, isEmpty);
    });

    testWidgets('requires an explicit acknowledgement', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;

      final c = clientFor((_) => routes());
      final state = await galleryState(c.api);
      await tester.pumpWidget(harness(AdminMediaScreen(state: state)));
      await settle(tester);

      await tester.tap(find.text('Deactivate'));
      await settle(tester);
      expect(find.textContaining('disappears from the place'), findsOneWidget);
      expect(find.textContaining('no way to reactivate'), findsOneWidget);

      final disabled = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Deactivate media'));
      expect(disabled.onPressed, isNull);
      await tester.tap(find.byType(Checkbox));
      await settle(tester);
      final enabled = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Deactivate media'));
      expect(enabled.onPressed, isNotNull);
    });

    testWidgets('deactivating the cover says the place will have none',
        (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;

      final c = clientFor((_) => routes(gallery: [asset(cover: true)]));
      final state = await galleryState(c.api);
      await tester.pumpWidget(harness(AdminMediaScreen(state: state)));
      await settle(tester);
      await tester.tap(find.text('Deactivate'));
      await settle(tester);
      expect(find.textContaining('nothing is promoted'), findsOneWidget);
    });

    testWidgets('an inactive asset offers no deactivate and no restore',
        (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;

      final c = clientFor((_) => routes(gallery: [asset(active: false)]));
      final state = await galleryState(c.api);
      await tester.pumpWidget(harness(AdminMediaScreen(state: state)));
      await settle(tester);

      expect(find.text('Deactivate'), findsNothing);
      for (final label in ['Restore', 'Reactivate', 'Activate', 'Undelete']) {
        expect(find.text(label), findsNothing, reason: label);
      }
      expect(find.text('Inactive'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 8 · Cover
  // ═══════════════════════════════════════════════════════════════════════════

  group('set cover', () {
    test('PATCHes /media/cover with the backend body shape', () async {
      final c = clientFor((_) => routes());
      final state = await galleryState(c.api);
      await state.setCover(state.items.single);
      final patch =
          c.sent.firstWhere((r) => r.url.path == '/api/admin/media/cover');
      expect(patch.method, 'PATCH');
      expect(jsonDecode(patch.body), {'mediaId': 5});
    });

    test('is refused for anything the backend would reject', () async {
      final c = clientFor((_) => routes(gallery: [
            asset(id: 5, mediaType: 'VIDEO'),
            asset(id: 6, active: false),
            asset(id: 7, cover: true),
            asset(id: 8),
          ]));
      final state = await galleryState(c.api);
      final byId = {for (final a in state.items) a.id: a};

      expect(state.canSetCover(byId[5]!), isFalse, reason: 'not an image');
      expect(state.canSetCover(byId[6]!), isFalse, reason: 'inactive');
      expect(state.canSetCover(byId[7]!), isFalse, reason: 'already the cover');
      expect(state.canSetCover(byId[8]!), isTrue);

      final before = c.sent.length;
      expect(await state.setCover(byId[5]!), isFalse);
      expect(c.sent.length, before, reason: 'nothing was sent');
    });

    testWidgets('the action appears only where it is legal', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1600, 2400);
      tester.view.devicePixelRatio = 1.0;

      final c = clientFor((_) => routes(gallery: [
            asset(id: 5, cover: true),
            asset(id: 6, mediaType: 'VIDEO', sortOrder: 1),
            asset(id: 7, sortOrder: 2),
          ]));
      final state = await galleryState(c.api);
      await tester.pumpWidget(harness(AdminMediaScreen(state: state)));
      await settle(tester);

      // Only asset 7 qualifies: 5 already is the cover, 6 is a video.
      expect(find.text('Set as cover'), findsOneWidget);
      expect(find.text('Cover'), findsWidgets);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 9 · Reorder
  // ═══════════════════════════════════════════════════════════════════════════

  group('reorder', () {
    test('submits the whole gallery renumbered 0..n-1', () async {
      // The backend rejects a repeated sortOrder, so a single-row patch is not
      // expressible: the request states every position.
      final c = clientFor((_) => routes(gallery: [
            asset(id: 5, sortOrder: 0),
            asset(id: 6, sortOrder: 1),
            asset(id: 7, sortOrder: 2),
          ]));
      final state = await galleryState(c.api);
      await state.moveMedia(state.items[2], up: true);

      final patch =
          c.sent.firstWhere((r) => r.url.path == '/api/admin/media/reorder');
      expect(patch.method, 'PATCH');
      expect(jsonDecode(patch.body), {
        'items': [
          {'mediaId': 5, 'sortOrder': 0},
          {'mediaId': 7, 'sortOrder': 1},
          {'mediaId': 6, 'sortOrder': 2},
        ]
      });
    });

    test('never sends a duplicate id or a duplicate position', () async {
      final c = clientFor((_) => routes(gallery: [
            asset(id: 5, sortOrder: 4),
            asset(id: 6, sortOrder: 4),
            asset(id: 7, sortOrder: 9),
          ]));
      final state = await galleryState(c.api);
      await state.moveMedia(state.items.first, up: false);

      final body = jsonDecode(c.sent
          .firstWhere((r) => r.url.path == '/api/admin/media/reorder')
          .body) as Map;
      final items = (body['items'] as List).cast<Map>();
      expect(items.map((i) => i['mediaId']).toSet(), hasLength(items.length));
      expect(items.map((i) => i['sortOrder']).toSet(), hasLength(items.length));
    });

    test('the ends of the list cannot be moved past', () async {
      final c = clientFor((_) => routes(gallery: [
            asset(id: 5, sortOrder: 0),
            asset(id: 6, sortOrder: 1),
          ]));
      final state = await galleryState(c.api);
      expect(state.canMoveUp(state.items.first), isFalse);
      expect(state.canMoveDown(state.items.last), isFalse);

      final before = c.sent.length;
      expect(await state.moveMedia(state.items.first, up: true), isFalse);
      expect(c.sent.length, before);
    });

    test('a single-item gallery offers no move at all', () async {
      final c = clientFor((_) => routes());
      final state = await galleryState(c.api);
      expect(state.canMoveUp(state.items.single), isFalse);
      expect(state.canMoveDown(state.items.single), isFalse);
    });

    testWidgets('the move controls are reachable by name', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1600, 2400);
      tester.view.devicePixelRatio = 1.0;

      final c = clientFor((_) => routes(gallery: [
            asset(id: 5, sortOrder: 0),
            asset(id: 6, sortOrder: 1),
          ]));
      final state = await galleryState(c.api);
      await tester.pumpWidget(harness(AdminMediaScreen(state: state)));
      await settle(tester);

      expect(find.byTooltip('Move up'), findsNWidgets(2));
      expect(find.byTooltip('Move down'), findsNWidgets(2));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 10 · Mutation honesty
  // ═══════════════════════════════════════════════════════════════════════════

  group('mutation outcomes', () {
    test('every mutation re-reads the gallery afterwards', () async {
      final c = clientFor((_) => routes());
      final state = await galleryState(c.api);
      int reads() => c.requests
          .where((r) =>
              r.method == 'GET' && r.url.path == '/api/admin/places/1/media')
          .length;

      final before = reads();
      await state.setCover(state.items.single);
      expect(reads(), before + 1, reason: 'set cover reloads');

      final afterCover = reads();
      await state.deactivateMedia(state.items.single);
      expect(reads(), afterCover + 1, reason: 'deactivate reloads');
    });

    test('nothing is patched locally on success', () async {
      // The gallery keeps answering the original row, so a UI that patched
      // locally would disagree with the server.
      final c = clientFor((_) => routes(gallery: [asset(cover: false)]));
      final state = await galleryState(c.api);
      await state.setCover(state.items.single);
      expect(state.items.single.cover, isFalse,
          reason: 'the reloaded server state is what is shown');
    });

    test('an unreadable success body is uncertain, not a success', () async {
      final r = routes();
      r['/api/admin/media/5/deactivate'] = http.Response('not json', 200);
      final c = clientFor((_) => r);
      final state = await galleryState(c.api);

      final ok = await state.deactivateMedia(state.items.single);
      expect(ok, isFalse);
      expect(state.mutationUncertain, isTrue,
          reason: 'the warning outlives the reload that follows it');
      expect(state.isReady, isTrue);
    });

    test('a second mutation is refused while one is in flight', () async {
      final c = clientFor((_) => routes());
      final state = await galleryState(c.api);
      final asset5 = state.items.single;
      final first = state.deactivateMedia(asset5);
      final second = state.deactivateMedia(asset5);
      expect(await second, isFalse);
      await first;
      expect(c.sent.where((r) => r.url.path == '/api/admin/media/5/deactivate'),
          hasLength(1));
    });

    testWidgets('the uncertain warning is shown and can be dismissed',
        (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;

      final r = routes();
      r['/api/admin/media/cover'] = http.Response('not json', 200);
      final c = clientFor((_) => r);
      final state = await galleryState(c.api);
      await tester.pumpWidget(harness(AdminMediaScreen(state: state)));
      await settle(tester);

      await state.setCover(state.items.single);
      await settle(tester);
      expect(find.textContaining('result of the last action is unknown'),
          findsOneWidget);

      await tester.tap(find.byTooltip('Dismiss'));
      await settle(tester);
      expect(find.textContaining('result of the last action is unknown'),
          findsNothing);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 11 · Preview safety and URL display
  // ═══════════════════════════════════════════════════════════════════════════

  group('preview and URL display', () {
    testWidgets('a broken image URL renders a fallback, not an exception',
        (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;

      // Every network image fails under the test HttpClient, which is exactly
      // the case a registry of arbitrary URLs must survive.
      final handle = tester.ensureSemantics();
      final c = clientFor(
          (_) => routes(gallery: [asset(url: 'https://cdn.test/gone.jpg')]));
      final state = await galleryState(c.api);
      await tester.pumpWidget(harness(AdminMediaScreen(state: state)));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel('Preview unavailable'), findsWidgets);
      handle.dispose();
    });

    testWidgets('a non-image type is never fetched as an image',
        (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;

      final handle = tester.ensureSemantics();
      final c = clientFor((_) => routes(gallery: [
            asset(mediaType: 'DOCUMENT', url: 'https://cdn.test/a.pdf'),
          ]));
      final state = await galleryState(c.api);
      await tester.pumpWidget(harness(AdminMediaScreen(state: state)));
      await settle(tester);

      expect(find.byType(Image), findsNothing);
      expect(find.bySemanticsLabel('Not an image'), findsWidgets);
      expect(tester.takeException(), isNull);
      handle.dispose();
    });

    testWidgets('a signed query string is not printed in the listing',
        (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;

      final c = clientFor((_) => routes(gallery: [
            asset(url: 'https://cdn.test/a.jpg?X-Amz-Signature=deadbeef'),
          ]));
      final state = await galleryState(c.api);
      await tester.pumpWidget(harness(AdminMediaScreen(state: state)));
      await settle(tester);

      expect(find.textContaining('X-Amz-Signature'), findsNothing);
      expect(find.text('https://cdn.test/a.jpg'), findsOneWidget);
      expect(find.textContaining('query string is present'), findsOneWidget);
    });

    test('the stored URL is never rewritten by the display helper', () async {
      const signed = 'https://cdn.test/a.jpg?sig=1';
      final c = clientFor((_) => routes(gallery: [asset(url: signed)]));
      final state = await galleryState(c.api);
      expect(state.items.single.url, signed, reason: 'untouched');
      expect(state.items.single.displayUrl, 'https://cdn.test/a.jpg');
      expect(state.items.single.urlHasQuery, isTrue);
    });

    test('the URL rule matches the backend and adds nothing of its own', () {
      for (final good in [
        'https://cdn.test/a.jpg',
        'http://cdn.test/a.jpg',
        'HTTPS://CDN.TEST/a.jpg',
        'https://cdn.test/a.jpg?sig=1',
        'https://example.org/no-extension',
      ]) {
        expect(AdminMediaUrl.isAcceptable(good), isTrue, reason: good);
      }
      for (final bad in [
        '',
        '   ',
        'javascript:alert(1)',
        'vbscript:msgbox(1)',
        'data:image/png;base64,AAA',
        'file:///etc/passwd',
        'ftp://cdn.test/a.jpg',
        '//cdn.test/a.jpg',
        '/relative.jpg',
        'https://',
      ]) {
        expect(AdminMediaUrl.isAcceptable(bad), isFalse, reason: '"$bad"');
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 12 · No upload surface exists
  // ═══════════════════════════════════════════════════════════════════════════

  group('registry, not an uploader', () {
    test('no multipart, file-picker or upload code exists in the media surface',
        () {
      // A source-level assertion because the requirement is an absence: this is
      // a URL registry, and the backend has no endpoint that accepts a file.
      const paths = [
        'lib/features/admin/admin_media_states.dart',
        'lib/features/admin/screens/admin_media_screen.dart',
        'lib/core/network/api_client.dart',
      ];
      const forbidden = [
        'MultipartRequest',
        'MultipartFile',
        'multipart/form-data',
        'FilePicker',
        'file_picker',
        'image_picker',
        'ImagePicker',
      ];
      for (final path in paths) {
        final source = File(path).readAsStringSync();
        for (final token in forbidden) {
          expect(source.contains(token), isFalse,
              reason: '$token must not appear in $path');
        }
      }
    });

    test('pubspec declares no upload or file-picking dependency', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final token in ['file_picker:', 'image_picker:', 'dio:']) {
        expect(pubspec.contains(token), isFalse, reason: token);
      }
    });

    testWidgets('the UI offers no upload affordance', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;

      final c = clientFor((_) => routes());
      final state = await galleryState(c.api);
      await tester.pumpWidget(harness(AdminMediaScreen(state: state)));
      await settle(tester);

      for (final label in [
        'Upload',
        'Choose file',
        'Browse',
        'Drop files',
        'Select image'
      ]) {
        expect(find.text(label), findsNothing, reason: label);
      }
      expect(find.textContaining('no file upload'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 13 · Localization, responsive, accessibility
  // ═══════════════════════════════════════════════════════════════════════════

  group('localization and layout', () {
    testWidgets('renders in Vietnamese', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;

      final c = clientFor((_) => routes());
      final state = await galleryState(c.api);
      await tester.pumpWidget(
          harness(AdminMediaScreen(state: state), locale: const Locale('vi')));
      await settle(tester);

      expect(find.text('Thêm ảnh hoặc video'), findsOneWidget);
      expect(find.text('Add media'), findsNothing);
    });

    testWidgets('gallery and picker survive 320, 390, 820 and 1600',
        (tester) async {
      addTearDown(tester.view.reset);

      for (final width in [320.0, 390.0, 820.0, 1600.0]) {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1.0;

        final c = clientFor((_) => routes(gallery: [
              asset(id: 5, sortOrder: 0, cover: true),
              asset(id: 6, sortOrder: 1, mediaType: 'VIDEO'),
              asset(id: 7, sortOrder: 2, active: false),
            ]));

        final picker = AdminMediaState(api: c.api);
        await tester.pumpWidget(harness(AdminMediaScreen(state: picker)));
        await settle(tester);
        expect(tester.takeException(), isNull, reason: 'picker at ${width}px');

        final state = await galleryState(c.api);
        await tester.pumpWidget(harness(AdminMediaScreen(state: state)));
        await settle(tester);
        expect(tester.takeException(), isNull, reason: 'gallery at ${width}px');

        for (var i = 0; i < 5; i++) {
          await tester.drag(find.byType(ListView).last, const Offset(0, -300));
          await settle(tester);
          expect(tester.takeException(), isNull,
              reason: 'gallery scrolled at ${width}px');
        }
      }
    });

    testWidgets('the empty and error states fit 320px', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;

      final empty = clientFor((_) => routes(gallery: const []));
      final emptyState = await galleryState(empty.api);
      await tester.pumpWidget(harness(AdminMediaScreen(state: emptyState)));
      await settle(tester);
      expect(tester.takeException(), isNull);

      final broken =
          clientFor((_) => routes(galleryOverride: http.Response('{}', 500)));
      final brokenState = await galleryState(broken.api);
      await tester.pumpWidget(harness(AdminMediaScreen(state: brokenState)));
      await settle(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the create and deactivate dialogs fit 320px', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;

      final c = clientFor((_) => routes());
      final state = await galleryState(c.api);
      await tester.pumpWidget(harness(AdminMediaScreen(state: state)));
      await settle(tester);

      await tester.tap(find.text('Add media'));
      await settle(tester);
      expect(find.text('Register'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Cancel'));
      await settle(tester);

      await tester.ensureVisible(find.text('Deactivate'));
      await settle(tester);
      await tester.tap(find.text('Deactivate'));
      await settle(tester);
      expect(find.text('Deactivate media'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('critical controls carry an accessible name', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1600, 2400);
      tester.view.devicePixelRatio = 1.0;

      final handle = tester.ensureSemantics();
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      final c = clientFor((_) => routes());

      final picker = AdminMediaState(api: c.api);
      await tester.pumpWidget(harness(AdminMediaScreen(state: picker)));
      await settle(tester);
      expect(
          find.bySemanticsLabel(l10n.adminMediaPlaceSearchLabel), findsWidgets);
      expect(
          find.bySemanticsLabel(
              l10n.adminMediaOpenGallerySemantic('Grand Palace')),
          findsWidgets);

      final state = await galleryState(c.api);
      await tester.pumpWidget(harness(AdminMediaScreen(state: state)));
      await settle(tester);

      expect(find.byTooltip(l10n.adminMediaBackToPlaces), findsOneWidget);
      expect(find.byTooltip(l10n.adminMediaMoveUp), findsWidgets);
      expect(find.byTooltip(l10n.adminMediaMoveDown), findsWidgets);
      expect(
          find.bySemanticsLabel(l10n.adminMediaAssetSemantic(5)), findsWidgets);
      // State is never colour alone: each badge carries its own word.
      expect(find.text(l10n.adminMediaActive), findsOneWidget);

      await tester.tap(find.text('Add media'));
      await settle(tester);
      expect(find.bySemanticsLabel(l10n.adminMediaUrl), findsWidgets);
      expect(find.bySemanticsLabel(l10n.adminMediaType), findsWidgets);
      expect(find.bySemanticsLabel(l10n.adminMediaAltText), findsWidgets);
      expect(find.bySemanticsLabel(l10n.adminMediaSortOrder), findsWidgets);

      handle.dispose();
    });
  });
}

class _RecordingClient extends http.BaseClient {
  final http.Response Function(http.BaseRequest request) onRequest;

  /// Holds the response back so a test can observe the loading frame. Without
  /// it the mock resolves on a microtask and the frame is never rendered.
  final Duration? delay;

  _RecordingClient({required this.onRequest, this.delay});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (delay != null) await Future<void>.delayed(delay!);
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
