import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:planyourtrip_frontend/core/admin/admin_models.dart';
import 'package:planyourtrip_frontend/core/admin/admin_state.dart';
import 'package:planyourtrip_frontend/core/app_role.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/features/admin/admin_navigation.dart';
import 'package:planyourtrip_frontend/features/admin/admin_paged_state.dart';
import 'package:planyourtrip_frontend/features/admin/admin_reference_states.dart';
import 'package:planyourtrip_frontend/features/admin/admin_routes.dart';
import 'package:planyourtrip_frontend/features/admin/screens/admin_reference_data_screen.dart';
import 'package:planyourtrip_frontend/features/admin/widgets/admin_widgets.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_en.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_vi.dart';

/// D10 — Admin Reference Data (amenities and categories).
///
/// Fixtures mirror `AmenityResponse` and `CategoryResponse` on
/// `develop@f26bb97`. Where a test asserts an **absence** — no delete control,
/// no DELETE request, no editable slug on update, no free-text type — that
/// absence is the requirement:
///
///  * the admin API exposes list / create / update / set-active and nothing
///    else, for either domain;
///  * `HotelRoomService` resolves room amenities by slug and silently skips an
///    unmatched one, so a slug is fixed after creation;
///  * `Category.type` is an unvalidated String that `CustomerCouponService`
///    matches against `CouponDefinition.placeType`, so it is picked, not typed;
///  * `StatusRequest` is a record with a primitive `boolean` and no `@Valid`,
///    so an empty body would deserialize to `active = false`.
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

  /// `AmenityDto.AmenityResponse`, in full.
  Map<String, dynamic> amenityRow(
    int id, {
    String name = 'Swimming Pool',
    String slug = 'swimming-pool',
    String? icon = 'pool',
    String? groupName = 'HOTEL',
    String? description = 'Outdoor or indoor swimming pool',
    int? sortOrder = 1,
    bool active = true,
  }) =>
      {
        'id': id,
        'name': name,
        'slug': slug,
        'icon': icon,
        'groupName': groupName,
        'description': description,
        'sortOrder': sortOrder,
        'active': active,
        'createdAt': '2026-08-24T00:00:00Z',
        'updatedAt': '2026-08-25T00:00:00Z',
      };

  /// `CategoryDto.CategoryResponse`, in full. Note there is **no**
  /// `description` field on this record, and there **is** a `color`.
  Map<String, dynamic> categoryRow(
    int id, {
    int? parentId,
    String name = 'Accommodation',
    String slug = 'accommodation',
    String? type = 'ACCOMMODATION',
    String? icon = 'hotel',
    String? color = '#2196F3',
    String? coverImageUrl = 'https://cdn.test/cover.jpg',
    int? sortOrder = 1,
    bool active = true,
  }) =>
      {
        'id': id,
        'parentId': parentId,
        'name': name,
        'slug': slug,
        'type': type,
        'icon': icon,
        'color': color,
        'coverImageUrl': coverImageUrl,
        'sortOrder': sortOrder,
        'active': active,
        'createdAt': '2026-08-24T00:00:00Z',
        'updatedAt': '2026-08-25T00:00:00Z',
      };

  late List<String> requestLog;
  late List<String> rawBodies;
  late List<Map<String, dynamic>> writeBodies;
  setUp(() {
    requestLog = <String>[];
    rawBodies = <String>[];
    writeBodies = <Map<String, dynamic>>[];
  });

  int countOf(String needle) =>
      requestLog.where((e) => e.contains(needle)).length;

  /// The mock holds list state, so a confirmed write genuinely changes what the
  /// next read returns — which is how "the grid re-reads rather than patching"
  /// can be asserted honestly. [freezeList] breaks that link deliberately: the
  /// write succeeds, the list does not change, and a UI that patched locally
  /// would visibly disagree with the server.
  MockClient d10Client({
    List<Map<String, dynamic>>? amenities,
    List<Map<String, dynamic>>? categories,
    int? writeStatus,
    String writeMessage = 'Slug already exists: swimming-pool',
    bool writeTimesOut = false,
    bool throwNetwork = false,
    bool freezeList = false,
    bool listMalformed = false,
  }) {
    var currentAmenities = amenities ?? [amenityRow(1)];
    var currentCategories = categories ?? [categoryRow(9)];

    return MockClient((request) async {
      final path = request.url.path;
      requestLog.add('${request.method} $path');
      if (throwNetwork) throw http.ClientException('offline');
      if (request.body.isNotEmpty) {
        rawBodies.add(request.body);
        final decoded = jsonDecode(request.body);
        if (decoded is Map<String, dynamic>) writeBodies.add(decoded);
      }

      final isWrite = request.method != 'GET';
      if (isWrite) {
        if (writeTimesOut) {
          await Future<void>.delayed(const Duration(seconds: 30));
          return jsonResponse(amenityRow(1), 200);
        }
        if (writeStatus != null && writeStatus != 200 && writeStatus != 201) {
          return jsonResponse(
              errorBody(writeStatus, writeMessage, path), writeStatus);
        }
      }

      // ── amenities ──────────────────────────────────────────────────────
      final amenityStatus =
          RegExp(r'/admin/amenities/(\d+)/status$').firstMatch(path);
      if (amenityStatus != null) {
        final id = int.parse(amenityStatus.group(1)!);
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final active = body['active'] == true;
        final updated = amenityRow(id, active: active);
        if (!freezeList) {
          currentAmenities = [
            for (final r in currentAmenities)
              if (r['id'] == id) updated else r
          ];
        }
        return jsonResponse(updated, 200);
      }

      final amenityUpdate = RegExp(r'/admin/amenities/(\d+)$').firstMatch(path);
      if (amenityUpdate != null) {
        final id = int.parse(amenityUpdate.group(1)!);
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final updated = amenityRow(
          id,
          name: body['name'] as String,
          slug: (body['slug'] as String?) ?? 'derived-slug',
          icon: body['icon'] as String?,
          groupName: body['groupName'] as String?,
          description: body['description'] as String?,
          sortOrder: body['sortOrder'] as int?,
        );
        if (!freezeList) {
          currentAmenities = [
            for (final r in currentAmenities)
              if (r['id'] == id) updated else r
          ];
        }
        return jsonResponse(updated, 200);
      }

      if (path.endsWith('/admin/amenities')) {
        if (request.method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final created = amenityRow(
            99,
            name: body['name'] as String,
            slug: (body['slug'] as String?) ?? 'derived-slug',
            icon: body['icon'] as String?,
            groupName: body['groupName'] as String?,
            description: body['description'] as String?,
            sortOrder: body['sortOrder'] as int?,
          );
          if (!freezeList) currentAmenities = [...currentAmenities, created];
          return jsonResponse(created, 201);
        }
        if (listMalformed) {
          return jsonResponse({'content': const []}, 200);
        }
        return jsonResponse(currentAmenities, 200);
      }

      // ── categories ─────────────────────────────────────────────────────
      final categoryStatus =
          RegExp(r'/admin/categories/(\d+)/status$').firstMatch(path);
      if (categoryStatus != null) {
        final id = int.parse(categoryStatus.group(1)!);
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final active = body['active'] == true;
        final existing = currentCategories.firstWhere((r) => r['id'] == id,
            orElse: () => categoryRow(id));
        final updated = categoryRow(
          id,
          parentId: existing['parentId'] as int?,
          name: existing['name'] as String,
          slug: existing['slug'] as String,
          type: existing['type'] as String?,
          active: active,
        );
        if (!freezeList) {
          currentCategories = [
            for (final r in currentCategories)
              if (r['id'] == id) updated else r
          ];
        }
        return jsonResponse(updated, 200);
      }

      final categoryUpdate =
          RegExp(r'/admin/categories/(\d+)$').firstMatch(path);
      if (categoryUpdate != null) {
        final id = int.parse(categoryUpdate.group(1)!);
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final updated = categoryRow(
          id,
          parentId: body['parentId'] as int?,
          name: body['name'] as String,
          slug: (body['slug'] as String?) ?? 'derived-slug',
          type: body['type'] as String?,
          icon: body['icon'] as String?,
          color: body['color'] as String?,
          coverImageUrl: body['coverImageUrl'] as String?,
          sortOrder: body['sortOrder'] as int?,
        );
        if (!freezeList) {
          currentCategories = [
            for (final r in currentCategories)
              if (r['id'] == id) updated else r
          ];
        }
        return jsonResponse(updated, 200);
      }

      if (path.endsWith('/admin/categories')) {
        if (request.method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final created = categoryRow(
            77,
            parentId: body['parentId'] as int?,
            name: body['name'] as String,
            slug: (body['slug'] as String?) ?? 'derived-slug',
            type: body['type'] as String?,
            icon: body['icon'] as String?,
            color: body['color'] as String?,
            coverImageUrl: body['coverImageUrl'] as String?,
            sortOrder: body['sortOrder'] as int?,
          );
          if (!freezeList) currentCategories = [...currentCategories, created];
          return jsonResponse(created, 201);
        }
        return jsonResponse(currentCategories, 200);
      }

      // Everything else the console might touch while mounted.
      if (path.contains('/admin/')) {
        return jsonResponse(const <Object>[], 200);
      }
      return jsonResponse(errorBody(404, 'Not found', path), 404);
    });
  }

  AppState adminApp(http.Client client, {AppRole role = AppRole.admin}) =>
      AppState(api: ApiClient(client: client)..demoMode = false)
        ..demoMode = false
        ..email = 'admin@planyourtrip.com'
        ..role = role;

  /// Renders the screen directly with its two notifiers.
  Future<({AdminAmenitiesState amenities, AdminCategoriesState categories})>
      pumpReference(
    WidgetTester tester, {
    http.Client? client,
    Locale? locale,
    int initialTab = 0,
    Size size = const Size(2000, 2400),
    bool settle = true,
  }) async {
    final api = ApiClient(client: client ?? d10Client())..demoMode = false;
    final amenities = AdminAmenitiesState(api: api);
    final categories = AdminCategoriesState(api: api);
    addTearDown(amenities.dispose);
    addTearDown(categories.dispose);

    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: AdminReferenceDataScreen(
          amenities: amenities,
          categories: categories,
          initialTab: initialTab,
        ),
      ),
    ));
    if (settle) await tester.pumpAndSettle();
    return (amenities: amenities, categories: categories);
  }

  /// Renders the whole console, for routing and role tests.
  Future<void> pumpConsole(
    WidgetTester tester, {
    http.Client? client,
    AppRole role = AppRole.admin,
    String route = AdminRoutes.referenceData,
    Size size = const Size(2000, 2400),
  }) async {
    final app = adminApp(client ?? d10Client(), role: role);
    final admin = AdminState(api: app.api)..bindSession(app);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(AppScope(
      notifier: app,
      child: AdminScope(
        notifier: admin,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AdminRouteGuard(key: ValueKey(route), initialRoute: route),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  /// Scrolls [finder] into view before tapping it. The grids are tables inside
  /// a horizontal scroll view, so an action column can sit outside the painted
  /// area even on a wide viewport.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key) =>
      tapVisible(tester, find.byKey(Key(key)));

  Future<void> confirmStatus(WidgetTester tester) =>
      tapKey(tester, 'admin-reference-status-confirm');

  Future<void> submitForm(WidgetTester tester) =>
      tapKey(tester, 'admin-reference-form-submit');

  /// Every affordance that would suggest a row can be removed. None of these
  /// may ever exist: the backend has no delete endpoint for either domain.
  void expectNoDeleteAffordance(WidgetTester tester) {
    for (final icon in [
      Icons.delete,
      Icons.delete_outline,
      Icons.delete_forever,
      Icons.delete_sweep,
      Icons.archive,
      Icons.archive_outlined,
    ]) {
      expect(find.byIcon(icon), findsNothing,
          reason: '$icon implies a removal this API cannot perform');
    }
    for (final label in ['Delete', 'Remove', 'Archive', 'Destroy']) {
      expect(find.text(label), findsNothing,
          reason: '"$label" implies a removal this API cannot perform');
    }
    expect(requestLog.where((e) => e.startsWith('DELETE')), isEmpty,
        reason: 'no DELETE may ever be issued from this screen');
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 1. General — reachability, roles, states
  // ═════════════════════════════════════════════════════════════════════════

  group('reachability and roles', () {
    test('the route is registered and resolves to a real destination', () {
      expect(AdminRoutes.referenceData, '/admin/reference-data');
      expect(AdminRoutes.isAdminRoute(AdminRoutes.referenceData), isTrue);
      final destination = AdminNavigation.byRoute(AdminRoutes.referenceData);
      expect(destination, isNotNull);
      expect(destination!.section, AdminSection.catalog);
      expect(destination.label(en), en.adminNavReferenceData);
    });

    testWidgets('an ADMIN reaches the destination through the console',
        (tester) async {
      await pumpConsole(tester);
      expect(find.byType(AdminReferenceDataScreen), findsOneWidget);
      expect(find.byType(AdminAccessDeniedScreen), findsNothing);
      expect(countOf('GET /api/admin/amenities'), 1,
          reason: 'the shown tab loads once, the other not at all');
      expect(countOf('GET /api/admin/categories'), 0);
    });

    for (final role in [AppRole.user, AppRole.partner, AppRole.unknown]) {
      testWidgets('$role is refused the destination', (tester) async {
        await pumpConsole(tester, role: role);
        expect(find.byType(AdminAccessDeniedScreen), findsOneWidget);
        expect(find.byType(AdminReferenceDataScreen), findsNothing);
        expect(requestLog, isEmpty,
            reason: 'a refused role must not reach the reference endpoints');
      });
    }

    testWidgets('the menu lists Reference Data exactly once', (tester) async {
      await pumpConsole(tester);
      expect(AdminNavigation.destinations, hasLength(10));
      expect(
          AdminNavigation.destinations
              .where((d) => d.route == AdminRoutes.referenceData),
          hasLength(1));
      expect(find.text(en.adminNavReferenceData), findsWidgets);
    });

    testWidgets('both tabs are reachable and each loads once', (tester) async {
      await pumpReference(tester);
      expect(find.text(en.adminReferenceTabAmenities), findsOneWidget);
      expect(find.text(en.adminReferenceTabCategories), findsOneWidget);
      expect(countOf('GET /api/admin/amenities'), 1);
      expect(countOf('GET /api/admin/categories'), 0);

      await tester.tap(find.text(en.adminReferenceTabCategories));
      await tester.pumpAndSettle();
      expect(countOf('GET /api/admin/categories'), 1);
      expect(find.text('Accommodation'), findsWidgets);

      // Back and forth does not refetch: each tab keeps its rows.
      await tester.tap(find.text(en.adminReferenceTabAmenities));
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.adminReferenceTabCategories));
      await tester.pumpAndSettle();
      expect(countOf('GET /api/admin/amenities'), 1);
      expect(countOf('GET /api/admin/categories'), 1);
    });
  });

  group('load states', () {
    testWidgets('a slow read shows the loading state, not an empty grid',
        (tester) async {
      final slow = MockClient((request) async {
        requestLog.add('${request.method} ${request.url.path}');
        await Future<void>.delayed(const Duration(seconds: 2));
        return jsonResponse([amenityRow(1)], 200);
      });
      await pumpReference(tester, client: slow, settle: false);
      await tester.pump();
      await tester.pump();
      expect(find.byType(AdminStateView), findsWidgets);
      expect(find.text(en.adminReferenceEmptyAmenities), findsNothing);

      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(find.text('Swimming Pool'), findsWidgets);
    });

    testWidgets('an empty list is an empty state, never an error',
        (tester) async {
      final r =
          await pumpReference(tester, client: d10Client(amenities: const []));
      expect(r.amenities.isEmpty, isTrue);
      expect(r.amenities.status, AdminLoadStatus.ready);
      expect(find.text(en.adminReferenceEmptyAmenities), findsOneWidget);
    });

    testWidgets('a network failure is an error state with a retry',
        (tester) async {
      final r =
          await pumpReference(tester, client: d10Client(throwNetwork: true));
      expect(r.amenities.status, AdminLoadStatus.error);
      expect(find.text(en.adminReferenceEmptyAmenities), findsNothing);

      final before = countOf('GET /api/admin/amenities');
      await tapVisible(tester, find.text(en.errorAction));
      expect(countOf('GET /api/admin/amenities'), greaterThan(before),
          reason: 'retry must re-issue the read');
    });

    testWidgets('a 403 is reported as forbidden, not as a generic error',
        (tester) async {
      final forbidden = MockClient((request) async {
        requestLog.add('${request.method} ${request.url.path}');
        return jsonResponse(
            errorBody(403, 'Access denied', request.url.path), 403);
      });
      final r = await pumpReference(tester, client: forbidden);
      expect(r.amenities.status, AdminLoadStatus.forbidden);
    });

    testWidgets('a list that is not an array is malformed, not empty',
        (tester) async {
      final r =
          await pumpReference(tester, client: d10Client(listMalformed: true));
      expect(r.amenities.status, AdminLoadStatus.error);
      expect(r.amenities.isEmpty, isFalse,
          reason: 'a malformed payload must never read as "no rows"');
    });

    testWidgets('a stale read never overwrites a newer one', (tester) async {
      var call = 0;
      final racing = MockClient((request) async {
        requestLog.add('${request.method} ${request.url.path}');
        call++;
        if (call == 1) {
          await Future<void>.delayed(const Duration(seconds: 4));
          return jsonResponse([amenityRow(1, name: 'STALE')], 200);
        }
        return jsonResponse([amenityRow(2, name: 'FRESH')], 200);
      });
      final r = await pumpReference(tester, client: racing, settle: false);
      await tester.pump();
      await r.amenities.load();
      await tester.pumpAndSettle(const Duration(seconds: 10));
      expect(r.amenities.items.single.name, 'FRESH');
    });
  });

  group('CMS scope messaging', () {
    testWidgets(
        'the screen states the CMS-only scope and the absence of delete',
        (tester) async {
      await pumpReference(tester);
      expect(
          find.byKey(const Key('admin-reference-cms-notice')), findsOneWidget);
      expect(find.text(en.adminReferenceCmsStatusNotice), findsOneWidget);
      expect(find.text(en.adminReferenceNoDeleteNotice), findsOneWidget);
    });

    testWidgets('no status wording claims a customer-facing effect', (_) async {
      for (final l in [en, vi]) {
        for (final copy in [
          l.adminReferenceStatusActive,
          l.adminReferenceStatusInactive,
          l.adminReferenceActivate,
          l.adminReferenceDeactivate,
          l.adminReferenceActivateTitle,
          l.adminReferenceDeactivateTitle,
          l.adminReferenceColCmsStatus,
        ]) {
          final lower = copy.toLowerCase();
          for (final forbidden in [
            'hide from customer',
            'hidden from public',
            'no longer visible',
            'ẩn khỏi khách',
            'không còn hiển thị',
          ]) {
            expect(lower.contains(forbidden), isFalse,
                reason: '"$copy" implies public filtering the server does '
                    'not perform');
          }
        }
        expect(l.adminReferenceStatusPublicNotice, isNotEmpty);
      }
    });

    for (final entry in {'en': en, 'vi': vi}.entries) {
      testWidgets('${entry.key} renders the tabs and the CMS notice',
          (tester) async {
        await pumpReference(tester, locale: Locale(entry.key));
        expect(
            find.text(entry.value.adminReferenceTabAmenities), findsOneWidget);
        expect(
            find.text(entry.value.adminReferenceTabCategories), findsOneWidget);
        expect(find.text(entry.value.adminReferenceCmsStatusNotice),
            findsOneWidget);
        expect(find.text(entry.value.adminReferenceNoDeleteNotice),
            findsOneWidget);
      });
    }

    test('the two locales differ, so neither is a copy of the other', () {
      expect(vi.adminNavReferenceData, isNot(en.adminNavReferenceData));
      expect(
          vi.adminReferenceStatusActive, isNot(en.adminReferenceStatusActive));
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // 2. Models and vocabularies
  // ═════════════════════════════════════════════════════════════════════════

  group('models', () {
    test('a full amenity row parses every field', () {
      final a = AdminAmenity.fromJson(amenityRow(4))!;
      expect(a.id, 4);
      expect(a.name, 'Swimming Pool');
      expect(a.slug, 'swimming-pool');
      expect(a.icon, 'pool');
      expect(a.groupName, 'HOTEL');
      expect(a.description, 'Outdoor or indoor swimming pool');
      expect(a.sortOrder, 1);
      expect(a.active, isTrue);
      expect(a.createdAt, isNotNull);
      expect(a.updatedAt, isNotNull);
    });

    test('a full category row parses every field, including colour', () {
      final c = AdminCategory.fromJson(categoryRow(9, parentId: 3))!;
      expect(c.id, 9);
      expect(c.parentId, 3);
      expect(c.isRoot, isFalse);
      expect(c.type, 'ACCOMMODATION');
      expect(c.color, '#2196F3');
      expect(c.coverImageUrl, 'https://cdn.test/cover.jpg');
      expect(AdminCategory.fromJson(categoryRow(1))!.isRoot, isTrue);
    });

    test('a row without a usable id is dropped, not rendered', () {
      expect(AdminAmenity.fromJson({'name': 'No id'}), isNull);
      expect(AdminCategory.fromJson({'name': 'No id'}), isNull);
      expect(AdminAmenity.fromJson({'id': null, 'name': 'x'}), isNull);
    });

    test('null and blank optional fields survive as null', () {
      final a = AdminAmenity.fromJson({
        'id': 5,
        'name': null,
        'slug': '   ',
        'icon': null,
        'groupName': null,
        'description': null,
        'sortOrder': null,
        'active': null,
      })!;
      expect(a.name, isNull);
      expect(a.slug, isNull);
      expect(a.sortOrder, isNull);
      expect(a.active, isFalse, reason: 'a non-boolean must not throw');
    });

    testWidgets('a malformed row is skipped and the good rows still render',
        (tester) async {
      final mixed = MockClient((request) async {
        requestLog.add('${request.method} ${request.url.path}');
        return jsonResponse([
          amenityRow(1, name: 'Good One'),
          {'name': 'No id at all'},
          'not even an object',
          amenityRow(2, name: 'Good Two', slug: 'good-two'),
        ], 200);
      });
      final r = await pumpReference(tester, client: mixed);
      expect(r.amenities.items, hasLength(2));
      expect(find.text('Good One'), findsWidgets);
      expect(find.text('Good Two'), findsWidgets);
      expect(find.text('No id at all'), findsNothing);
    });
  });

  group('vocabularies', () {
    test('options come from the data, sorted and de-duplicated', () {
      expect(
        AdminReferenceVocabulary.optionsFrom(
            ['HOTEL', 'general', 'HOTEL', null, '  '],
            fallback: const ['X']),
        ['HOTEL', 'general'],
      );
    });

    test('the fallback is used only when nothing was observed', () {
      expect(
        AdminReferenceVocabulary.optionsFrom(const <String?>[],
            fallback: const ['GENERAL', 'HOTEL']),
        ['GENERAL', 'HOTEL'],
      );
      expect(
        AdminReferenceVocabulary.optionsFrom(const ['ROOM'],
            fallback: const ['GENERAL']),
        ['ROOM'],
      );
    });

    test('the current value is always offered, even if no row shares it', () {
      expect(
        AdminReferenceVocabulary.optionsFrom(const ['HOTEL'],
            fallback: const ['GENERAL'], current: 'LEGACY'),
        ['HOTEL', 'LEGACY'],
      );
    });

    test('the seeded fallbacks match the backend data, not the Swagger text',
        () {
      // `AmenityController`'s summary documents five groups and omits
      // ATTRACTION, which `DataInitializer` actually seeds (8 rows).
      expect(AdminReferenceVocabulary.seededGroupNames, contains('ATTRACTION'));
      expect(AdminReferenceVocabulary.seededGroupNames, hasLength(6));
      expect(AdminReferenceVocabulary.seededCategoryTypes, hasLength(10));
      expect(
          AdminReferenceVocabulary.seededCategoryTypes, contains('PHOTO_SPOT'));
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // 3. Amenities
  // ═════════════════════════════════════════════════════════════════════════

  group('amenities', () {
    testWidgets('the grid renders the row as the server sent it',
        (tester) async {
      await pumpReference(tester);
      expect(find.text('Swimming Pool'), findsWidgets);
      expect(find.text('swimming-pool'), findsWidgets);
      expect(find.text('HOTEL'), findsWidgets);
      expect(find.text(en.adminReferenceStatusActive), findsWidgets);
    });

    testWidgets('no delete affordance exists anywhere', (tester) async {
      await pumpReference(tester);
      expectNoDeleteAffordance(tester);
      await tapKey(tester, 'admin-reference-new-amenity');
      expectNoDeleteAffordance(tester);
    });

    testWidgets('create sends exactly the AmenityRequest fields',
        (tester) async {
      await pumpReference(tester);
      await tapKey(tester, 'admin-reference-new-amenity');

      await tester.enterText(
          find.byKey(const Key('admin-reference-name-field')), 'Rooftop Bar');
      await tester.enterText(
          find.byKey(const Key('admin-reference-slug-field')), 'rooftop-bar');
      await tester.enterText(
          find.byKey(const Key('admin-reference-sort-order-field')), '7');
      await submitForm(tester);

      expect(countOf('POST /api/admin/amenities'), 1);
      final body = writeBodies.last;
      expect(body['name'], 'Rooftop Bar');
      expect(body['slug'], 'rooftop-bar');
      expect(body['sortOrder'], 7);
      expect(
          body.keys.toSet(),
          {
            'name',
            'slug',
            'icon',
            'groupName',
            'description',
            'sortOrder',
          },
          reason: 'the body is AmenityRequest exactly — no invented fields');
      // The created row is visible only because the list was re-read.
      expect(countOf('GET /api/admin/amenities'), 2);
      expect(find.text('Rooftop Bar'), findsWidgets);
    });

    testWidgets('a blank slug is sent as null so the server derives it',
        (tester) async {
      await pumpReference(tester);
      await tapKey(tester, 'admin-reference-new-amenity');
      await tester.enterText(
          find.byKey(const Key('admin-reference-name-field')), 'Sauna');
      await submitForm(tester);
      expect(writeBodies.last['slug'], isNull);
    });

    testWidgets('a blank name is refused before any request', (tester) async {
      await pumpReference(tester);
      final before = requestLog.length;
      await tapKey(tester, 'admin-reference-new-amenity');
      await submitForm(tester);
      expect(find.text(en.adminReferenceNameRequired), findsOneWidget);
      expect(requestLog.length, before, reason: 'nothing may be sent');
      expect(find.byType(AlertDialog), findsOneWidget,
          reason: 'the dialog stays open so the operator can fix it');
    });

    testWidgets('a non-numeric sort order is refused before any request',
        (tester) async {
      await pumpReference(tester);
      final before = requestLog.length;
      await tapKey(tester, 'admin-reference-new-amenity');
      await tester.enterText(
          find.byKey(const Key('admin-reference-name-field')), 'Sauna');
      await tester.enterText(
          find.byKey(const Key('admin-reference-sort-order-field')), 'abc');
      await submitForm(tester);
      expect(find.text(en.adminReferenceSortOrderInvalid), findsOneWidget);
      expect(requestLog.length, before);
    });

    testWidgets('a 409 keeps the backend message and changes nothing',
        (tester) async {
      final r =
          await pumpReference(tester, client: d10Client(writeStatus: 409));
      await tapKey(tester, 'admin-reference-new-amenity');
      await tester.enterText(
          find.byKey(const Key('admin-reference-name-field')), 'Swimming Pool');
      await submitForm(tester);

      expect(r.amenities.mutationConflict, isTrue);
      expect(r.amenities.mutationError, 'Slug already exists: swimming-pool');
      expect(find.byKey(const Key('admin-reference-mutation-banner')),
          findsOneWidget);
      expect(find.text('Slug already exists: swimming-pool'), findsOneWidget);
      expect(r.amenities.items, hasLength(1),
          reason: 'a refused create adds nothing locally');
    });

    testWidgets('a 409 with no readable message names the duplicate slug',
        (tester) async {
      await pumpReference(tester,
          client: d10Client(writeStatus: 409, writeMessage: ''));
      await tapKey(tester, 'admin-reference-new-amenity');
      await tester.enterText(
          find.byKey(const Key('admin-reference-name-field')), 'Pool');
      await submitForm(tester);
      expect(find.text(en.adminReferenceDuplicateSlug), findsOneWidget);
    });

    testWidgets('the banner can be dismissed', (tester) async {
      final r =
          await pumpReference(tester, client: d10Client(writeStatus: 409));
      await tapKey(tester, 'admin-reference-new-amenity');
      await tester.enterText(
          find.byKey(const Key('admin-reference-name-field')), 'Pool');
      await submitForm(tester);
      await tester.tap(find.text(en.adminReferenceDismiss));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('admin-reference-mutation-banner')),
          findsNothing);
      expect(r.amenities.mutationConflict, isFalse);
    });

    testWidgets('update sends the row slug back unchanged', (tester) async {
      await pumpReference(tester);
      await tapKey(tester, 'admin-reference-amenity-edit-1');
      await tester.enterText(
          find.byKey(const Key('admin-reference-name-field')), 'Indoor Pool');
      await submitForm(tester);

      expect(countOf('PUT /api/admin/amenities/1'), 1);
      expect(writeBodies.last['name'], 'Indoor Pool');
      expect(writeBodies.last['slug'], 'swimming-pool',
          reason: 'the stored slug is passed through, never rewritten');
      expect(find.text('Indoor Pool'), findsWidgets);
    });

    testWidgets('slug is editable on create and read-only on update',
        (tester) async {
      await pumpReference(tester);

      await tapKey(tester, 'admin-reference-new-amenity');
      var slug = tester.widget<TextFormField>(
          find.byKey(const Key('admin-reference-slug-field')));
      expect(slug.enabled, isNot(false),
          reason: 'slug may be supplied on create');
      expect(find.text(en.adminReferenceSlugHelper), findsOneWidget);
      await tester.tap(find.text(en.adminPartnerCancel));
      await tester.pumpAndSettle();

      await tapKey(tester, 'admin-reference-amenity-edit-1');
      slug = tester.widget<TextFormField>(
          find.byKey(const Key('admin-reference-slug-field')));
      expect(slug.enabled, isFalse, reason: 'slug is fixed after creation');
      expect(find.text(en.adminReferenceSlugFixedNotice), findsOneWidget);
    });

    testWidgets('the group picker offers observed values, not free text',
        (tester) async {
      await pumpReference(
        tester,
        client: d10Client(amenities: [
          amenityRow(1, groupName: 'HOTEL'),
          amenityRow(2, name: 'WiFi', slug: 'wifi', groupName: 'GENERAL'),
          amenityRow(3, name: 'Balcony', slug: 'balcony', groupName: 'ROOM'),
        ]),
      );
      await tapKey(tester, 'admin-reference-new-amenity');

      final picker = find.byKey(const Key('admin-reference-group-picker'));
      expect(picker, findsOneWidget);
      expect(find.descendant(of: picker, matching: find.byType(TextField)),
          findsNothing,
          reason: 'a group must be chosen, never typed');

      await tester.tap(picker);
      await tester.pumpAndSettle();
      for (final group in ['GENERAL', 'HOTEL', 'ROOM']) {
        expect(find.text(group), findsWidgets,
            reason: '$group is present in the data and must be offered');
      }
      expect(find.text('RESTAURANT'), findsNothing,
          reason: 'the seeded fallback must not appear once data was observed');
    });

    testWidgets('the group picker keeps a stored value no other row uses',
        (tester) async {
      final r = await pumpReference(
        tester,
        client: d10Client(amenities: [
          amenityRow(1, groupName: 'LEGACY_GROUP'),
          amenityRow(2, name: 'WiFi', slug: 'wifi', groupName: 'GENERAL'),
        ]),
      );
      expect(r.amenities.groupOptions(current: 'LEGACY_GROUP'),
          containsAll(['GENERAL', 'LEGACY_GROUP']));
    });

    testWidgets('deactivate confirms first, then sends an explicit false',
        (tester) async {
      await pumpReference(tester);
      await tapKey(tester, 'admin-reference-amenity-status-1');

      expect(find.text(en.adminReferenceDeactivateTitle), findsOneWidget);
      expect(find.text(en.adminReferenceStatusPublicNotice), findsOneWidget);
      expect(countOf('PATCH'), 0, reason: 'nothing is sent before confirming');

      await confirmStatus(tester);
      expect(countOf('PATCH /api/admin/amenities/1/status'), 1);
      expect(rawBodies.last, '{"active":false}');
      expect(find.text(en.adminReferenceStatusInactive), findsWidgets);
    });

    testWidgets('activate sends an explicit true', (tester) async {
      await pumpReference(tester,
          client: d10Client(amenities: [amenityRow(1, active: false)]));
      expect(find.text(en.adminReferenceStatusInactive), findsWidgets);
      await tapKey(tester, 'admin-reference-amenity-status-1');
      expect(find.text(en.adminReferenceActivateTitle), findsOneWidget);
      await confirmStatus(tester);
      expect(rawBodies.last, '{"active":true}');
      expect(find.text(en.adminReferenceStatusActive), findsWidgets);
    });

    testWidgets('cancelling the confirmation sends nothing', (tester) async {
      await pumpReference(tester);
      final before = requestLog.length;
      await tapKey(tester, 'admin-reference-amenity-status-1');
      await tester.tap(find.text(en.adminPartnerCancel));
      await tester.pumpAndSettle();
      expect(requestLog.length, before);
      expect(find.text(en.adminReferenceStatusActive), findsWidgets);
    });

    testWidgets('the grid shows the server list, never a locally patched row',
        (tester) async {
      // The write succeeds but the list read is frozen. A UI that patched
      // optimistically would show the new name; this one shows the server's.
      await pumpReference(tester, client: d10Client(freezeList: true));
      await tapKey(tester, 'admin-reference-amenity-edit-1');
      await tester.enterText(
          find.byKey(const Key('admin-reference-name-field')), 'Renamed Pool');
      await submitForm(tester);

      expect(countOf('PUT /api/admin/amenities/1'), 1);
      expect(countOf('GET /api/admin/amenities'), 2,
          reason: 'a confirmed mutation is followed by a re-read');
      expect(find.text('Renamed Pool'), findsNothing);
      expect(find.text('Swimming Pool'), findsWidgets);
    });

    testWidgets('an unanswered write is uncertain, and the list is reloaded',
        (tester) async {
      final r =
          await pumpReference(tester, client: d10Client(writeTimesOut: true));
      await tapKey(tester, 'admin-reference-amenity-status-1');
      await tester.tap(find.byKey(const Key('admin-reference-status-confirm')));
      await tester.pumpAndSettle(const Duration(seconds: 40));

      expect(r.amenities.mutationUncertain, isTrue);
      expect(r.amenities.mutationError, isNull,
          reason: 'uncertainty is not a failure message');
      expect(find.text(en.adminReferenceMutationUncertain), findsOneWidget);
      expect(countOf('GET /api/admin/amenities'), 2,
          reason: 'the operator is shown the current server state');
    });

    testWidgets('a second write is refused while one is in flight',
        (tester) async {
      final r =
          await pumpReference(tester, client: d10Client(writeTimesOut: true));
      final first = r.amenities
          .setActive(AdminAmenity.fromJson(amenityRow(1))!, active: false);
      await tester.pump();
      expect(r.amenities.isMutating, isTrue);
      expect(
          await r.amenities
              .setActive(AdminAmenity.fromJson(amenityRow(1))!, active: true),
          isFalse,
          reason: 'single-flight: the second call is refused outright');
      expect(countOf('PATCH'), 1);
      await tester.pumpAndSettle(const Duration(seconds: 40));
      await first;
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // 4. Categories
  // ═════════════════════════════════════════════════════════════════════════

  group('categories', () {
    List<Map<String, dynamic>> tree() => [
          categoryRow(1, name: 'Accommodation', slug: 'accommodation'),
          categoryRow(2,
              parentId: 1, name: 'Hotel', slug: 'hotel', type: 'ACCOMMODATION'),
          categoryRow(3,
              parentId: 2,
              name: 'Boutique Hotel',
              slug: 'boutique-hotel',
              type: 'ACCOMMODATION'),
          categoryRow(4, name: 'Food', slug: 'food', type: 'FOOD'),
        ];

    Future<({AdminAmenitiesState amenities, AdminCategoriesState categories})>
        pumpCategories(WidgetTester tester,
                {List<Map<String, dynamic>>? rows,
                int? writeStatus,
                bool freezeList = false,
                bool writeTimesOut = false}) =>
            pumpReference(
              tester,
              initialTab: 1,
              client: d10Client(
                categories: rows ?? tree(),
                writeStatus: writeStatus,
                writeMessage: 'Slug already exists: hotel',
                freezeList: freezeList,
                writeTimesOut: writeTimesOut,
              ),
            );

    testWidgets('the grid renders rows and resolves the parent name',
        (tester) async {
      await pumpCategories(tester);
      expect(find.text('Accommodation'), findsWidgets);
      expect(find.text('Hotel'), findsWidgets);
      expect(find.text('ACCOMMODATION'), findsWidgets);
      // Row 2's parent is row 1, resolved from the rows already loaded.
      expect(find.text(en.adminReferenceParentNone), findsWidgets,
          reason: 'roots say so explicitly');
    });

    testWidgets('no delete affordance exists anywhere', (tester) async {
      await pumpCategories(tester);
      expectNoDeleteAffordance(tester);
      await tapKey(tester, 'admin-reference-new-category');
      expectNoDeleteAffordance(tester);
    });

    testWidgets('create sends exactly the CategoryRequest fields',
        (tester) async {
      await pumpCategories(tester);
      await tapKey(tester, 'admin-reference-new-category');
      await tester.enterText(
          find.byKey(const Key('admin-reference-name-field')), 'Glamping');
      await submitForm(tester);

      expect(countOf('POST /api/admin/categories'), 1);
      expect(
          writeBodies.last.keys.toSet(),
          {
            'parentId',
            'name',
            'slug',
            'type',
            'icon',
            'color',
            'coverImageUrl',
            'sortOrder',
          },
          reason: 'the body is CategoryRequest exactly — colour included, and '
              'no "description", which the record does not declare');
      expect(writeBodies.last['name'], 'Glamping');
      expect(writeBodies.last['parentId'], isNull,
          reason: 'no parent chosen means a root category');
      expect(countOf('GET /api/admin/categories'), 2);
    });

    testWidgets('update preserves colour and cover rather than clearing them',
        (tester) async {
      await pumpCategories(tester);
      await tapKey(tester, 'admin-reference-category-edit-2');
      await tester.enterText(
          find.byKey(const Key('admin-reference-name-field')), 'Hotels');
      await submitForm(tester);

      expect(countOf('PUT /api/admin/categories/2'), 1);
      final body = writeBodies.last;
      expect(body['name'], 'Hotels');
      expect(body['slug'], 'hotel', reason: 'the slug is passed through');
      expect(body['color'], '#2196F3',
          reason: 'the update is a full replace, so colour must be resent');
      expect(body['coverImageUrl'], 'https://cdn.test/cover.jpg');
      expect(body['parentId'], 1, reason: 'the stored parent is preserved');
    });

    testWidgets('a duplicate slug surfaces the backend message',
        (tester) async {
      final r = await pumpCategories(tester, writeStatus: 409);
      await tapKey(tester, 'admin-reference-new-category');
      await tester.enterText(
          find.byKey(const Key('admin-reference-name-field')), 'Hotel');
      await submitForm(tester);
      expect(r.categories.mutationConflict, isTrue);
      expect(find.text('Slug already exists: hotel'), findsOneWidget);
    });

    testWidgets('the type picker offers observed values, not free text',
        (tester) async {
      await pumpCategories(tester);
      await tapKey(tester, 'admin-reference-new-category');

      final picker = find.byKey(const Key('admin-reference-type-picker'));
      expect(find.descendant(of: picker, matching: find.byType(TextField)),
          findsNothing,
          reason: 'a type must be chosen, never typed');
      expect(find.text(en.adminReferenceTypeNotice), findsOneWidget);

      await tester.tap(picker);
      await tester.pumpAndSettle();
      expect(find.text('ACCOMMODATION'), findsWidgets);
      expect(find.text('FOOD'), findsWidgets);
      expect(find.text('WELLNESS'), findsNothing,
          reason:
              'unseen seeded values must not appear once data was observed');
    });

    testWidgets('the parent picker offers a root option and the other rows',
        (tester) async {
      await pumpCategories(tester);
      await tapKey(tester, 'admin-reference-new-category');
      // The grid behind the dialog renders these names too, so what the
      // picker adds is measured as a delta rather than by bare presence.
      final before = {
        for (final n in ['Accommodation', 'Hotel', 'Boutique Hotel', 'Food'])
          n: find.text(n).evaluate().length
      };
      await tapKey(tester, 'admin-reference-parent-picker');
      expect(find.text(en.adminReferenceParentNone), findsWidgets);
      for (final entry in before.entries) {
        expect(find.text(entry.key).evaluate().length, greaterThan(entry.value),
            reason: '${entry.key} must be offered as a parent on create');
      }
    });

    testWidgets('editing a category excludes itself and its descendants',
        (tester) async {
      final r = await pumpCategories(tester);
      final accommodation = r.categories.byId(1)!;

      expect(r.categories.descendantIdsOf(1), {2, 3});
      final options = r.categories.parentOptions(editing: accommodation);
      expect(options.map((c) => c.id), [4],
          reason: 'self (1) and descendants (2, 3) are all excluded');

      await tapKey(tester, 'admin-reference-category-edit-1');
      expect(find.text(en.adminReferenceParentGuardNotice), findsOneWidget);

      final foodBefore = find.text('Food').evaluate().length;
      final grandchildBefore = find.text('Boutique Hotel').evaluate().length;
      await tapKey(tester, 'admin-reference-parent-picker');
      expect(find.text('Food').evaluate().length, greaterThan(foodBefore),
          reason: 'an unrelated category is still a valid parent');
      expect(find.text('Boutique Hotel').evaluate().length, grandchildBefore,
          reason: 'a grandchild must not be offered as a parent — the count '
              'is unchanged, so the only match is the row behind the dialog');
    });

    testWidgets('a mid-tree category excludes only what is below it',
        (tester) async {
      final r = await pumpCategories(tester);
      expect(r.categories.descendantIdsOf(2), {3});
      expect(
          r.categories
              .parentOptions(editing: r.categories.byId(2)!)
              .map((c) => c.id)
              .toSet(),
          {1, 4});
      expect(r.categories.descendantIdsOf(3), isEmpty);
      expect(
          r.categories
              .parentOptions(editing: r.categories.byId(3)!)
              .map((c) => c.id)
              .toSet(),
          {1, 2, 4});
    });

    testWidgets('an existing cycle in the data cannot hang the picker',
        (tester) async {
      // The backend has no cycle guard, so the console must survive one.
      final r = await pumpCategories(tester, rows: [
        categoryRow(1, parentId: 2, name: 'A', slug: 'a'),
        categoryRow(2, parentId: 1, name: 'B', slug: 'b'),
      ]);
      expect(r.categories.descendantIdsOf(1), {1, 2});
      expect(
          r.categories.parentOptions(editing: r.categories.byId(1)!), isEmpty);
    });

    testWidgets('status on and off both confirm and send an explicit flag',
        (tester) async {
      await pumpCategories(tester);
      await tapKey(tester, 'admin-reference-category-status-1');
      expect(countOf('PATCH'), 0);
      await confirmStatus(tester);
      expect(countOf('PATCH /api/admin/categories/1/status'), 1);
      expect(rawBodies.last, '{"active":false}');

      await tapKey(tester, 'admin-reference-category-status-1');
      await confirmStatus(tester);
      expect(rawBodies.last, '{"active":true}');
      expect(countOf('PATCH /api/admin/categories/1/status'), 2);
    });

    testWidgets('every status body carries the key, always', (tester) async {
      await pumpCategories(tester);
      await tapKey(tester, 'admin-reference-category-status-4');
      await confirmStatus(tester);
      for (final body in writeBodies) {
        expect(body.containsKey('active'), isTrue,
            reason: 'an omitted key deserializes to false on the server');
        expect(body['active'], isA<bool>());
      }
      expect(rawBodies.every((b) => b != '{}'), isTrue);
    });

    testWidgets('the grid shows the server list, never a locally patched row',
        (tester) async {
      await pumpCategories(tester, freezeList: true);
      await tapKey(tester, 'admin-reference-category-edit-4');
      await tester.enterText(
          find.byKey(const Key('admin-reference-name-field')), 'Dining');
      await submitForm(tester);
      expect(countOf('GET /api/admin/categories'), 2);
      expect(find.text('Dining'), findsNothing);
      expect(find.text('Food'), findsWidgets);
    });

    testWidgets('an unanswered write is uncertain, and the list is reloaded',
        (tester) async {
      final r = await pumpCategories(tester, writeTimesOut: true);
      await tapKey(tester, 'admin-reference-category-status-4');
      await tester.tap(find.byKey(const Key('admin-reference-status-confirm')));
      await tester.pumpAndSettle(const Duration(seconds: 40));
      expect(r.categories.mutationUncertain, isTrue);
      expect(find.text(en.adminReferenceMutationUncertain), findsOneWidget);
      expect(countOf('GET /api/admin/categories'), 2);
    });

    testWidgets('an empty category list is an empty state', (tester) async {
      final r = await pumpCategories(tester, rows: const []);
      expect(r.categories.isEmpty, isTrue);
      expect(find.text(en.adminReferenceEmptyCategories), findsOneWidget);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // 5. Contract guards
  // ═════════════════════════════════════════════════════════════════════════

  group('contract guards', () {
    testWidgets('only the four documented operations are ever issued',
        (tester) async {
      await pumpReference(tester);
      await tapKey(tester, 'admin-reference-amenity-status-1');
      await confirmStatus(tester);
      await tester.tap(find.text(en.adminReferenceTabCategories));
      await tester.pumpAndSettle();

      for (final entry in requestLog) {
        final method = entry.split(' ').first;
        expect(['GET', 'POST', 'PUT', 'PATCH'], contains(method),
            reason: '$entry uses a method the reference API does not expose');
        expect(entry, contains('/api/admin/'),
            reason: '$entry left the admin namespace');
        expect(
            entry.contains('/admin/amenities') ||
                entry.contains('/admin/categories'),
            isTrue,
            reason: '$entry touches a domain outside D10');
      }
    });

    testWidgets('no locations endpoint is touched — D11 is out of scope',
        (tester) async {
      await pumpReference(tester);
      await tester.tap(find.text(en.adminReferenceTabCategories));
      await tester.pumpAndSettle();
      expect(requestLog.where((e) => e.contains('locations')), isEmpty);
    });

    test('no reference state reuses the paged envelope', () {
      // These endpoints return a bare array; the paged base would manufacture
      // a `PageResponse` the server never sent.
      expect(AdminAmenitiesState(api: ApiClient(client: d10Client())),
          isNot(isA<AdminPagedState<Object?>>()));
      expect(AdminCategoriesState(api: ApiClient(client: d10Client())),
          isNot(isA<AdminPagedState<Object?>>()));
    });

    testWidgets('reset drops rows and clears every banner', (tester) async {
      final r =
          await pumpReference(tester, client: d10Client(writeStatus: 409));
      await tapKey(tester, 'admin-reference-new-amenity');
      await tester.enterText(
          find.byKey(const Key('admin-reference-name-field')), 'Pool');
      await submitForm(tester);
      expect(r.amenities.mutationConflict, isTrue);

      r.amenities.reset();
      await tester.pump();
      expect(r.amenities.items, isEmpty);
      expect(r.amenities.status, AdminLoadStatus.idle);
      expect(r.amenities.mutationConflict, isFalse);
      expect(r.amenities.mutationError, isNull);
    });
  });
}
