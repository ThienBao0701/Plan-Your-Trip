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
import 'package:planyourtrip_frontend/features/admin/admin_reference_states.dart';
import 'package:planyourtrip_frontend/features/admin/admin_routes.dart';
import 'package:planyourtrip_frontend/features/admin/screens/admin_reference_data_screen.dart';
import 'package:planyourtrip_frontend/features/admin/widgets/admin_widgets.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_en.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_vi.dart';

/// D11 — Admin locations, the third tab of the Reference Data destination.
///
/// Fixtures mirror `LocationDto.LocationResponse` on `develop@f26bb97`. Where a
/// test asserts an **absence** — no parent picker, no `fullPath` box, no level
/// or coordinate editor, no delete — that absence is the requirement, and each
/// one has a reason in the backend:
///
///  * `parentId` — `CategoryService`-style reparenting with no cycle guard, and
///    no recomputation of a moved subtree, so a parent control could orphan a
///    branch from `/api/locations/roots`;
///  * `fullPath` — caller-supplied, never derived, and **customer-visible**: it
///    rides in `PlaceDto.LocationRef` and the traveller app parses it to show a
///    place's province;
///  * `level` — derived from nothing and validated against nothing;
///  * `latitude`/`longitude` — no range and no pairing validation;
///  * delete — no endpoint exists, for any role.
///
/// And because `PUT` is a full replace, every one of those must be **sent back
/// unchanged** rather than merely left out of the form.
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

  /// `LocationDto.LocationResponse`, in full — 15 fields.
  Map<String, dynamic> locationRow(
    int id, {
    int? parentId,
    String? code = 'DNG',
    String name = 'Đà Nẵng',
    String slug = 'da-nang',
    String? type = 'CITY',
    int? level = 2,
    String? oldName = 'Da Nang',
    String? fullPath = 'Vietnam > Đà Nẵng',
    double? latitude = 16.0544,
    double? longitude = 108.2022,
    int? sortOrder = 4,
    bool active = true,
  }) =>
      {
        'id': id,
        'parentId': parentId,
        'code': code,
        'name': name,
        'slug': slug,
        'type': type,
        'level': level,
        'oldName': oldName,
        'fullPath': fullPath,
        'latitude': latitude,
        'longitude': longitude,
        'sortOrder': sortOrder,
        'active': active,
        'createdAt': '2026-08-24T00:00:00Z',
        'updatedAt': '2026-08-25T00:00:00Z',
      };

  /// The country row the seeded tree hangs off, used as a parent.
  Map<String, dynamic> countryRow() => locationRow(
        1,
        code: 'VN',
        name: 'Vietnam',
        slug: 'vietnam',
        type: 'COUNTRY',
        level: 0,
        oldName: null,
        fullPath: 'Vietnam',
        latitude: 14.06,
        longitude: 108.28,
        sortOrder: 0,
      );

  List<Map<String, dynamic>> tree() => [
        countryRow(),
        locationRow(2, parentId: 1),
        locationRow(
          3,
          parentId: 1,
          code: 'HCM',
          name: 'TP Hồ Chí Minh',
          slug: 'tp-ho-chi-minh',
          oldName: 'Sai Gon',
          fullPath: 'Vietnam > TP Hồ Chí Minh',
          latitude: 10.8231,
          longitude: 106.6297,
          sortOrder: 2,
        ),
      ];

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

  Map<String, dynamic> lastWrite() => writeBodies.last;

  /// Holds list state so a confirmed write genuinely changes the next read.
  /// [freezeList] breaks that link deliberately: the write succeeds, the list
  /// does not move, and a UI that patched locally would visibly disagree.
  MockClient d11Client({
    List<Map<String, dynamic>>? locations,
    int? writeStatus,
    String writeMessage = 'Slug already exists: da-nang',
    bool writeTimesOut = false,
    bool throwNetwork = false,
    bool freezeList = false,
    bool listMalformed = false,
  }) {
    var current = locations ?? tree();

    return MockClient((request) async {
      final path = request.url.path;
      requestLog.add('${request.method} $path');
      if (throwNetwork) throw http.ClientException('offline');
      if (request.body.isNotEmpty) {
        rawBodies.add(request.body);
        final decoded = jsonDecode(request.body);
        if (decoded is Map<String, dynamic>) writeBodies.add(decoded);
      }

      if (request.method != 'GET') {
        if (writeTimesOut) {
          await Future<void>.delayed(const Duration(seconds: 30));
          return jsonResponse(locationRow(2, parentId: 1), 200);
        }
        if (writeStatus != null && writeStatus != 200 && writeStatus != 201) {
          return jsonResponse(
              errorBody(writeStatus, writeMessage, path), writeStatus);
        }
      }

      /// Builds the stored row from a request body, so a read-back reflects
      /// exactly what the client sent — including anything it nulled.
      Map<String, dynamic> rowFromBody(int id, Map<String, dynamic> b) =>
          locationRow(
            id,
            parentId: b['parentId'] as int?,
            code: b['code'] as String?,
            name: b['name'] as String,
            slug: (b['slug'] as String?) ?? 'derived-slug',
            type: b['type'] as String?,
            level: b['level'] as int?,
            oldName: b['oldName'] as String?,
            fullPath: b['fullPath'] as String?,
            latitude: (b['latitude'] as num?)?.toDouble(),
            longitude: (b['longitude'] as num?)?.toDouble(),
            sortOrder: b['sortOrder'] as int?,
          );

      final status = RegExp(r'/admin/locations/(\d+)/status$').firstMatch(path);
      if (status != null) {
        final id = int.parse(status.group(1)!);
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final existing = current.firstWhere((r) => r['id'] == id,
            orElse: () => locationRow(id));
        final updated = {...existing, 'active': body['active'] == true};
        if (!freezeList) {
          current = [
            for (final r in current)
              if (r['id'] == id) updated else r
          ];
        }
        return jsonResponse(updated, 200);
      }

      final update = RegExp(r'/admin/locations/(\d+)$').firstMatch(path);
      if (update != null) {
        final id = int.parse(update.group(1)!);
        final updated =
            rowFromBody(id, jsonDecode(request.body) as Map<String, dynamic>);
        if (!freezeList) {
          current = [
            for (final r in current)
              if (r['id'] == id) updated else r
          ];
        }
        return jsonResponse(updated, 200);
      }

      if (path.endsWith('/admin/locations')) {
        if (request.method == 'POST') {
          final created =
              rowFromBody(99, jsonDecode(request.body) as Map<String, dynamic>);
          if (!freezeList) current = [...current, created];
          return jsonResponse(created, 201);
        }
        if (listMalformed) return jsonResponse({'content': const []}, 200);
        return jsonResponse(current, 200);
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

  /// Renders the screen with the Locations tab already selected.
  Future<AdminLocationsState> pumpLocations(
    WidgetTester tester, {
    http.Client? client,
    Locale? locale,
    Size size = const Size(2200, 2400),
    bool settle = true,
  }) async {
    final api = ApiClient(client: client ?? d11Client())..demoMode = false;
    final amenities = AdminAmenitiesState(api: api);
    final categories = AdminCategoriesState(api: api);
    final locations = AdminLocationsState(api: api);
    addTearDown(amenities.dispose);
    addTearDown(categories.dispose);
    addTearDown(locations.dispose);

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
          locations: locations,
          initialTab: 2,
        ),
      ),
    ));
    if (settle) await tester.pumpAndSettle();
    return locations;
  }

  /// Renders the whole console, for routing and role tests.
  Future<void> pumpConsole(
    WidgetTester tester, {
    http.Client? client,
    AppRole role = AppRole.admin,
    Size size = const Size(2200, 2400),
  }) async {
    final app = adminApp(client ?? d11Client(), role: role);
    final admin = AdminState(api: app.api)..bindSession(app);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(AppScope(
      notifier: app,
      child: AdminScope(
        notifier: admin,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AdminRouteGuard(
              key: ValueKey(AdminRoutes.referenceData),
              initialRoute: AdminRoutes.referenceData),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  /// Scrolls [finder] into view before tapping. The locations grid is a
  /// nine-column table inside a horizontal scroll view, so an action column can
  /// sit outside the painted area even on a wide viewport.
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

  Future<void> openCreate(WidgetTester tester) =>
      tapKey(tester, 'admin-reference-new-location');

  Future<void> openEdit(WidgetTester tester, int id) =>
      tapKey(tester, 'admin-reference-location-edit-$id');

  Future<void> type(WidgetTester tester, String key, String value) async {
    await tester.enterText(find.byKey(Key(key)), value);
    await tester.pumpAndSettle();
  }

  /// Every affordance that would suggest a row can be removed.
  void expectNoDeleteAffordance() {
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
      expect(find.text(label), findsNothing);
    }
    expect(requestLog.where((e) => e.startsWith('DELETE')), isEmpty,
        reason: 'no DELETE may ever be issued from this screen');
  }

  /// The dialog's editable inputs, by key — the exact set, so a control for a
  /// read-only field could not be added without failing here.
  Set<String?> dialogInputKeys(WidgetTester tester) {
    String? keyOf(Widget w) {
      final k = w.key;
      return k is ValueKey<String> ? k.value : null;
    }

    final fields = tester
        .widgetList<TextFormField>(find.descendant(
            of: find.byType(AlertDialog), matching: find.byType(TextFormField)))
        .map(keyOf);
    final drops = tester
        .widgetList<DropdownButtonFormField<String>>(find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(DropdownButtonFormField<String>)))
        .map(keyOf);
    return {...fields, ...drops};
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 1. General — tab, roles, states
  // ═════════════════════════════════════════════════════════════════════════

  group('reachability and roles', () {
    testWidgets('the Locations tab is registered as the third tab',
        (tester) async {
      await pumpLocations(tester);
      expect(find.text(en.adminReferenceTabAmenities), findsOneWidget);
      expect(find.text(en.adminReferenceTabCategories), findsOneWidget);
      expect(find.text(en.adminReferenceTabLocations), findsOneWidget);
      expect(find.byType(Tab), findsNWidgets(3));
    });

    testWidgets('the navigation destination count is unchanged at 10',
        (tester) async {
      await pumpConsole(tester);
      expect(AdminNavigation.destinations, hasLength(10),
          reason: 'D11 adds a tab, not a destination');
      expect(
          AdminNavigation.destinations
              .where((d) => d.route == AdminRoutes.referenceData),
          hasLength(1));
      expect(find.text(en.adminNavReferenceData), findsWidgets);
    });

    testWidgets('an ADMIN reaches the destination and opens Locations',
        (tester) async {
      await pumpConsole(tester);
      expect(find.byType(AdminReferenceDataScreen), findsOneWidget);
      expect(find.byType(AdminAccessDeniedScreen), findsNothing);
      expect(countOf('GET /api/admin/locations'), 0,
          reason: 'only the shown tab loads');

      await tester.tap(find.text(en.adminReferenceTabLocations));
      await tester.pumpAndSettle();
      expect(countOf('GET /api/admin/locations'), 1);
      expect(find.text('Đà Nẵng'), findsWidgets);
    });

    for (final role in [AppRole.user, AppRole.partner, AppRole.unknown]) {
      testWidgets('$role is refused the destination', (tester) async {
        await pumpConsole(tester, role: role);
        expect(find.byType(AdminAccessDeniedScreen), findsOneWidget);
        expect(find.byType(AdminReferenceDataScreen), findsNothing);
        expect(requestLog, isEmpty,
            reason: 'a refused role must not reach the location endpoints');
      });
    }

    testWidgets('returning to the tab does not refetch', (tester) async {
      await pumpLocations(tester);
      expect(countOf('GET /api/admin/locations'), 1);
      await tester.tap(find.text(en.adminReferenceTabAmenities));
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.adminReferenceTabLocations));
      await tester.pumpAndSettle();
      expect(countOf('GET /api/admin/locations'), 1);
    });
  });

  group('load states', () {
    testWidgets('a slow read shows the loading state, not an empty grid',
        (tester) async {
      final slow = MockClient((request) async {
        requestLog.add('${request.method} ${request.url.path}');
        await Future<void>.delayed(const Duration(seconds: 2));
        return jsonResponse(tree(), 200);
      });
      await pumpLocations(tester, client: slow, settle: false);
      await tester.pump();
      await tester.pump();
      expect(find.byType(AdminStateView), findsWidgets);
      expect(find.text(en.adminLocationEmpty), findsNothing);

      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(find.text('Đà Nẵng'), findsWidgets);
    });

    testWidgets('an empty list is an empty state, never an error',
        (tester) async {
      final state =
          await pumpLocations(tester, client: d11Client(locations: const []));
      expect(state.isEmpty, isTrue);
      expect(state.status, AdminLoadStatus.ready);
      expect(find.text(en.adminLocationEmpty), findsOneWidget);
    });

    testWidgets('a network failure is an error state with a retry',
        (tester) async {
      final state =
          await pumpLocations(tester, client: d11Client(throwNetwork: true));
      expect(state.status, AdminLoadStatus.error);
      expect(find.text(en.adminLocationEmpty), findsNothing);

      final before = countOf('GET /api/admin/locations');
      await tapVisible(tester, find.text(en.errorAction));
      expect(countOf('GET /api/admin/locations'), greaterThan(before));
    });

    testWidgets('a 403 is reported as forbidden, not as a generic error',
        (tester) async {
      final forbidden = MockClient((request) async {
        requestLog.add('${request.method} ${request.url.path}');
        return jsonResponse(
            errorBody(403, 'Access denied', request.url.path), 403);
      });
      final state = await pumpLocations(tester, client: forbidden);
      expect(state.status, AdminLoadStatus.forbidden);
    });

    testWidgets('a list that is not an array is malformed, not empty',
        (tester) async {
      final state =
          await pumpLocations(tester, client: d11Client(listMalformed: true));
      expect(state.status, AdminLoadStatus.error);
      expect(state.isEmpty, isFalse);
    });

    testWidgets('a stale read never overwrites a newer one', (tester) async {
      var call = 0;
      final racing = MockClient((request) async {
        requestLog.add('${request.method} ${request.url.path}');
        call++;
        if (call == 1) {
          await Future<void>.delayed(const Duration(seconds: 4));
          return jsonResponse([locationRow(1, name: 'STALE')], 200);
        }
        return jsonResponse([locationRow(2, name: 'FRESH')], 200);
      });
      final state = await pumpLocations(tester, client: racing, settle: false);
      await tester.pump();
      await state.load();
      await tester.pumpAndSettle(const Duration(seconds: 10));
      expect(state.items.single.name, 'FRESH');
    });
  });

  for (final entry in {'en': en, 'vi': vi}.entries) {
    testWidgets('${entry.key} renders the Locations tab and the CMS notice',
        (tester) async {
      await pumpLocations(tester, locale: Locale(entry.key));
      expect(find.text(entry.value.adminReferenceTabLocations), findsOneWidget);
      expect(
          find.text(entry.value.adminReferenceCmsStatusNotice), findsOneWidget);
      expect(
          find.text(entry.value.adminReferenceNoDeleteNotice), findsOneWidget);
      expect(find.text(entry.value.adminLocationNew), findsWidgets);
    });
  }

  test('the two locales differ, so neither is a copy of the other', () {
    expect(vi.adminReferenceTabLocations, isNot(en.adminReferenceTabLocations));
    expect(vi.adminLocationCodeCannotBeCleared,
        isNot(en.adminLocationCodeCannotBeCleared));
  });

  // ═════════════════════════════════════════════════════════════════════════
  // 2. Model and vocabulary
  // ═════════════════════════════════════════════════════════════════════════

  group('model', () {
    test('a full row parses every one of the fifteen fields', () {
      final l = AdminLocation.fromJson(locationRow(7, parentId: 1))!;
      expect(l.id, 7);
      expect(l.parentId, 1);
      expect(l.code, 'DNG');
      expect(l.name, 'Đà Nẵng');
      expect(l.slug, 'da-nang');
      expect(l.type, 'CITY');
      expect(l.level, 2);
      expect(l.oldName, 'Da Nang');
      expect(l.fullPath, 'Vietnam > Đà Nẵng');
      expect(l.latitude, 16.0544);
      expect(l.longitude, 108.2022);
      expect(l.sortOrder, 4);
      expect(l.active, isTrue);
      expect(l.createdAt, isNotNull);
      expect(l.updatedAt, isNotNull);
      expect(l.isRoot, isFalse);
      expect(l.hasCoordinates, isTrue);
    });

    test('a minimal row parses, with every optional field null', () {
      final l = AdminLocation.fromJson({'id': 5, 'name': 'Somewhere'})!;
      expect(l.id, 5);
      expect(l.name, 'Somewhere');
      expect(l.parentId, isNull);
      expect(l.code, isNull);
      expect(l.slug, isNull);
      expect(l.type, isNull);
      expect(l.level, isNull);
      expect(l.oldName, isNull);
      expect(l.fullPath, isNull);
      expect(l.latitude, isNull);
      expect(l.longitude, isNull);
      expect(l.sortOrder, isNull);
      expect(l.active, isFalse, reason: 'a missing boolean must not throw');
      expect(l.isRoot, isTrue);
      expect(l.hasCoordinates, isFalse);
    });

    test('a null parent is a root', () {
      expect(AdminLocation.fromJson(countryRow())!.isRoot, isTrue);
      expect(
          AdminLocation.fromJson(locationRow(2, parentId: 1))!.isRoot, isFalse);
    });

    test('half a coordinate pair is not a position', () {
      final half = AdminLocation.fromJson(locationRow(4, longitude: null))!;
      expect(half.latitude, isNotNull);
      expect(half.hasCoordinates, isFalse,
          reason: 'the backend enforces no pairing rule, so the console does');
    });

    test('a row without a usable id is dropped, not rendered', () {
      expect(AdminLocation.fromJson({'name': 'No id'}), isNull);
      expect(AdminLocation.fromJson({'id': null, 'name': 'x'}), isNull);
    });

    testWidgets('a malformed row is skipped and the good rows still render',
        (tester) async {
      final mixed = MockClient((request) async {
        requestLog.add('${request.method} ${request.url.path}');
        return jsonResponse([
          locationRow(1, name: 'Good One', slug: 'good-one'),
          {'name': 'No id at all'},
          'not even an object',
          locationRow(2, name: 'Good Two', slug: 'good-two', code: 'GT'),
        ], 200);
      });
      final state = await pumpLocations(tester, client: mixed);
      expect(state.items, hasLength(2));
      expect(find.text('Good One'), findsWidgets);
      expect(find.text('No id at all'), findsNothing);
    });

    test('the type vocabulary is the backend enum, closed', () {
      expect(AdminLocationType.values,
          ['COUNTRY', 'PROVINCE', 'CITY', 'WARD', 'COMMUNE', 'AREA']);
      expect(AdminLocationType.optionsWith('CITY'), AdminLocationType.values);
      expect(AdminLocationType.optionsWith(null), AdminLocationType.values);
    });

    test('an unrecognised stored type is preserved, never rewritten', () {
      expect(AdminLocationType.optionsWith('DISTRICT'), contains('DISTRICT'));
      expect(AdminLocationType.optionsWith('DISTRICT'), hasLength(7));
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // 3. Client-side filter
  // ═════════════════════════════════════════════════════════════════════════

  group('client-side filter', () {
    testWidgets('filters by name and issues no request', (tester) async {
      final state = await pumpLocations(tester);
      final before = requestLog.length;
      await type(tester, 'admin-reference-location-filter', 'Đà');
      expect(state.visibleItems.map((l) => l.id), [2]);
      expect(requestLog.length, before,
          reason: 'the admin list endpoint takes no search parameter');
      // "Vietnam" is still on screen — it is row 2's parent, rendered in the
      // Parent column of the row that matched. The row that did not match is
      // what must be gone.
      expect(find.text('TP Hồ Chí Minh'), findsNothing);
    });

    testWidgets('filters by slug', (tester) async {
      final state = await pumpLocations(tester);
      await type(tester, 'admin-reference-location-filter', 'tp-ho-chi');
      expect(state.visibleItems.map((l) => l.id), [3]);
    });

    testWidgets('filters by code', (tester) async {
      final state = await pumpLocations(tester);
      await type(tester, 'admin-reference-location-filter', 'hcm');
      expect(state.visibleItems.map((l) => l.id), [3],
          reason: 'the filter is case-insensitive');
    });

    testWidgets('filters by former name', (tester) async {
      final state = await pumpLocations(tester);
      await type(tester, 'admin-reference-location-filter', 'Sai Gon');
      expect(state.visibleItems.map((l) => l.id), [3],
          reason: 'oldName is a legacy alias customers still search by');
    });

    testWidgets('no match is a distinct state from no rows', (tester) async {
      final state = await pumpLocations(tester);
      await type(tester, 'admin-reference-location-filter', 'zzzz');
      expect(state.visibleItems, isEmpty);
      expect(state.isFilteredEmpty, isTrue);
      expect(state.isEmpty, isFalse);
      expect(find.text(en.adminLocationFilterEmpty), findsOneWidget);
      expect(find.text(en.adminLocationEmpty), findsNothing);
    });

    testWidgets('clearing the filter restores every row', (tester) async {
      final state = await pumpLocations(tester);
      await type(tester, 'admin-reference-location-filter', 'zzzz');
      expect(state.visibleItems, isEmpty);
      await tapVisible(tester, find.byTooltip(en.adminLocationFilterClear));
      expect(state.filter, '');
      expect(state.visibleItems, hasLength(3));
    });

    test('reset clears the filter as well as the rows', () {
      final state = AdminLocationsState(api: ApiClient(client: d11Client()));
      state.setFilter('hue');
      expect(state.hasFilter, isTrue);
      state.reset();
      expect(state.filter, '');
      expect(state.items, isEmpty);
      expect(state.status, AdminLoadStatus.idle);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // 4. Create
  // ═════════════════════════════════════════════════════════════════════════

  group('create', () {
    testWidgets('sends exactly the LocationRequest fields', (tester) async {
      await pumpLocations(tester);
      await openCreate(tester);
      await type(tester, 'admin-reference-name-field', 'Phú Quốc');
      await type(tester, 'admin-reference-location-code-field', 'PQC');
      await type(tester, 'admin-reference-slug-field', 'phu-quoc');
      await type(tester, 'admin-reference-location-oldname-field', 'Phu Quoc');
      await type(tester, 'admin-reference-sort-order-field', '12');
      await submitForm(tester);

      expect(countOf('POST /api/admin/locations'), 1);
      expect(
          lastWrite().keys.toSet(),
          {
            'parentId',
            'code',
            'name',
            'slug',
            'type',
            'level',
            'oldName',
            'fullPath',
            'latitude',
            'longitude',
            'sortOrder',
          },
          reason: 'the body is LocationRequest exactly — and carries no '
              'nameNormalized, which the record does not declare');
      expect(lastWrite()['name'], 'Phú Quốc');
      expect(lastWrite()['code'], 'PQC');
      expect(lastWrite()['slug'], 'phu-quoc');
      expect(lastWrite()['oldName'], 'Phu Quoc');
      expect(lastWrite()['sortOrder'], 12);
      expect(countOf('GET /api/admin/locations'), 2,
          reason: 'a confirmed create is followed by a re-read');
    });

    testWidgets('creates a top level location and says so', (tester) async {
      await pumpLocations(tester);
      await openCreate(tester);
      expect(find.text(en.adminLocationCreateRootNotice), findsOneWidget);
      await type(tester, 'admin-reference-name-field', 'Côn Đảo');
      await submitForm(tester);
      expect(lastWrite()['parentId'], isNull);
      expect(lastWrite()['level'], isNull);
      expect(lastWrite()['latitude'], isNull);
      expect(lastWrite()['longitude'], isNull);
    });

    testWidgets('previews the exact path it will store', (tester) async {
      await pumpLocations(tester);
      await openCreate(tester);
      expect(find.text(en.adminLocationFullPathPreviewNotice), findsOneWidget);
      await type(tester, 'admin-reference-name-field', 'Côn Đảo');
      expect(find.text('Côn Đảo'), findsWidgets,
          reason: 'the preview follows the name as it is typed');
      await submitForm(tester);
      expect(lastWrite()['fullPath'], 'Côn Đảo',
          reason: "a root's path is its name — DataInitializer's own rule");
    });

    testWidgets('a blank slug is sent as null so the server derives it',
        (tester) async {
      await pumpLocations(tester);
      await openCreate(tester);
      await type(tester, 'admin-reference-name-field', 'Sa Pa');
      await submitForm(tester);
      expect(lastWrite()['slug'], isNull);
    });

    testWidgets('a blank name is refused before any request', (tester) async {
      await pumpLocations(tester);
      final before = requestLog.length;
      await openCreate(tester);
      await submitForm(tester);
      expect(find.text(en.adminReferenceNameRequired), findsOneWidget);
      expect(requestLog.length, before);
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('a duplicate slug keeps the backend message', (tester) async {
      final state = await pumpLocations(tester,
          client: d11Client(
              writeStatus: 409, writeMessage: 'Slug already exists: da-nang'));
      await openCreate(tester);
      await type(tester, 'admin-reference-name-field', 'Da Nang');
      await submitForm(tester);
      expect(state.mutationConflict, isTrue);
      expect(find.text('Slug already exists: da-nang'), findsOneWidget);
      expect(state.items, hasLength(3), reason: 'nothing was added locally');
    });

    testWidgets('a duplicate code keeps the backend message', (tester) async {
      final state = await pumpLocations(tester,
          client: d11Client(
              writeStatus: 409, writeMessage: 'Code already exists: DNG'));
      await openCreate(tester);
      await type(tester, 'admin-reference-name-field', 'Somewhere');
      await type(tester, 'admin-reference-location-code-field', 'DNG');
      await submitForm(tester);
      expect(state.mutationConflict, isTrue);
      expect(find.text('Code already exists: DNG'), findsOneWidget,
          reason: 'code is a second 409 axis and the message says which');
    });

    testWidgets('an unanswered create is uncertain, and the list is reloaded',
        (tester) async {
      final state =
          await pumpLocations(tester, client: d11Client(writeTimesOut: true));
      await openCreate(tester);
      await type(tester, 'admin-reference-name-field', 'Somewhere');
      await tester.tap(find.byKey(const Key('admin-reference-form-submit')));
      await tester.pumpAndSettle(const Duration(seconds: 40));

      expect(state.mutationUncertain, isTrue);
      expect(state.mutationError, isNull);
      expect(find.text(en.adminReferenceMutationUncertain), findsOneWidget);
      expect(countOf('GET /api/admin/locations'), 2);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // 5. Edit — preservation is the whole point
  // ═════════════════════════════════════════════════════════════════════════

  group('edit', () {
    testWidgets('every field the console does not edit is sent back unchanged',
        (tester) async {
      await pumpLocations(tester);
      await openEdit(tester, 2);
      await type(tester, 'admin-reference-name-field', 'Da Nang City');
      await submitForm(tester);

      expect(countOf('PUT /api/admin/locations/2'), 1);
      expect(lastWrite()['name'], 'Da Nang City');
      // The six preserved values, each for its own reason.
      expect(lastWrite()['parentId'], 1, reason: 'no reparenting from here');
      expect(lastWrite()['fullPath'], 'Vietnam > Đà Nẵng',
          reason: 'customer-visible through PlaceDto.LocationRef');
      expect(lastWrite()['level'], 2, reason: 'derived from nothing');
      expect(lastWrite()['latitude'], 16.0544);
      expect(lastWrite()['longitude'], 108.2022);
      expect(lastWrite()['slug'], 'da-nang', reason: 'fixed after creation');
    });

    testWidgets('no preserved field is ever null merely because it is hidden',
        (tester) async {
      await pumpLocations(tester);
      await openEdit(tester, 2);
      await submitForm(tester);
      for (final key in [
        'parentId',
        'fullPath',
        'level',
        'latitude',
        'longitude',
        'slug',
        'code',
      ]) {
        expect(lastWrite()[key], isNotNull,
            reason: 'PUT is a full replace: a null $key would clear it');
      }
    });

    testWidgets('a root stays a root', (tester) async {
      await pumpLocations(tester);
      await openEdit(tester, 1);
      await type(tester, 'admin-reference-name-field', 'Viet Nam');
      await submitForm(tester);
      expect(lastWrite()['parentId'], isNull);
      expect(lastWrite()['fullPath'], 'Vietnam');
    });

    testWidgets('slug is read-only when editing', (tester) async {
      await pumpLocations(tester);
      await openEdit(tester, 2);
      final slug = tester.widget<TextFormField>(
          find.byKey(const Key('admin-reference-slug-field')));
      expect(slug.enabled, isFalse);
      expect(find.text(en.adminReferenceSlugFixedNotice), findsOneWidget);
    });

    testWidgets('slug is editable when creating', (tester) async {
      await pumpLocations(tester);
      await openCreate(tester);
      final slug = tester.widget<TextFormField>(
          find.byKey(const Key('admin-reference-slug-field')));
      expect(slug.enabled, isNot(false));
      expect(find.text(en.adminReferenceSlugHelper), findsOneWidget);
    });

    testWidgets('a code can be replaced', (tester) async {
      await pumpLocations(tester);
      await openEdit(tester, 2);
      await type(tester, 'admin-reference-location-code-field', 'DAD');
      await submitForm(tester);
      expect(lastWrite()['code'], 'DAD');
    });

    testWidgets('a stored code cannot be cleared', (tester) async {
      await pumpLocations(tester);
      final before = requestLog.length;
      await openEdit(tester, 2);
      await type(tester, 'admin-reference-location-code-field', '');
      await submitForm(tester);
      expect(find.text(en.adminLocationCodeCannotBeCleared), findsOneWidget);
      expect(requestLog.length, before, reason: 'nothing may be sent');
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    test('the state refuses to clear a code even if a caller tries', () async {
      // Belt and braces: the form validator blocks this, and so does the state.
      final api = ApiClient(client: d11Client());
      final state = AdminLocationsState(api: api);
      addTearDown(state.dispose);
      await state.load();
      final row = state.byId(2)!;
      await state.update(row, name: row.name!, type: row.type!, code: '  ');
      expect(lastWrite()['code'], 'DNG');
    });

    test('a location that never had a code may still be saved without one',
        () async {
      final api = ApiClient(
          client: d11Client(locations: [
        locationRow(4, code: null, name: 'Nowhere', slug: 'nowhere')
      ]));
      final state = AdminLocationsState(api: api);
      addTearDown(state.dispose);
      await state.load();
      final row = state.byId(4)!;
      await state.update(row, name: 'Nowhere', type: 'AREA');
      expect(lastWrite()['code'], isNull,
          reason: 'there is no code to preserve, so none is invented');
    });

    testWidgets('the type picker offers the closed backend enum',
        (tester) async {
      await pumpLocations(tester);
      await openEdit(tester, 2);
      final picker =
          find.byKey(const Key('admin-reference-location-type-picker'));
      expect(find.descendant(of: picker, matching: find.byType(TextField)),
          findsNothing,
          reason: 'a type must be chosen, never typed');

      final before = {
        for (final t in AdminLocationType.values)
          t: find.text(t).evaluate().length
      };
      await tapVisible(tester, picker);
      for (final entry in before.entries) {
        expect(find.text(entry.key).evaluate().length, greaterThan(entry.value),
            reason: '${entry.key} is declared by UnitType and must be offered');
      }
    });

    testWidgets('the former name and sort order are editable', (tester) async {
      await pumpLocations(tester);
      await openEdit(tester, 2);
      await type(tester, 'admin-reference-location-oldname-field', 'Tourane');
      await type(tester, 'admin-reference-sort-order-field', '9');
      await submitForm(tester);
      expect(lastWrite()['oldName'], 'Tourane');
      expect(lastWrite()['sortOrder'], 9);
    });

    testWidgets('a non-numeric sort order is refused before any request',
        (tester) async {
      await pumpLocations(tester);
      final before = requestLog.length;
      await openEdit(tester, 2);
      await type(tester, 'admin-reference-sort-order-field', 'abc');
      await submitForm(tester);
      expect(find.text(en.adminReferenceSortOrderInvalid), findsOneWidget);
      expect(requestLog.length, before);
    });

    testWidgets('the grid shows the server list, never a locally patched row',
        (tester) async {
      await pumpLocations(tester, client: d11Client(freezeList: true));
      await openEdit(tester, 2);
      await type(tester, 'admin-reference-name-field', 'Renamed City');
      await submitForm(tester);
      expect(countOf('PUT /api/admin/locations/2'), 1);
      expect(countOf('GET /api/admin/locations'), 2);
      expect(find.text('Renamed City'), findsNothing);
      expect(find.text('Đà Nẵng'), findsWidgets);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // 6. CMS status
  // ═════════════════════════════════════════════════════════════════════════

  group('CMS status', () {
    testWidgets('deactivate confirms first, then sends an explicit false',
        (tester) async {
      await pumpLocations(tester);
      await tapKey(tester, 'admin-reference-location-status-2');
      expect(find.text(en.adminReferenceDeactivateTitle), findsOneWidget);
      expect(find.text(en.adminReferenceStatusPublicNotice), findsOneWidget);
      expect(countOf('PATCH'), 0, reason: 'nothing is sent before confirming');

      await confirmStatus(tester);
      expect(countOf('PATCH /api/admin/locations/2/status'), 1);
      expect(rawBodies.last, '{"active":false}');
      expect(find.text(en.adminReferenceStatusInactive), findsWidgets);
    });

    testWidgets('activate confirms first, then sends an explicit true',
        (tester) async {
      await pumpLocations(tester,
          client: d11Client(
              locations: [locationRow(2, parentId: 1, active: false)]));
      expect(find.text(en.adminReferenceStatusInactive), findsWidgets);
      await tapKey(tester, 'admin-reference-location-status-2');
      expect(find.text(en.adminReferenceActivateTitle), findsOneWidget);
      await confirmStatus(tester);
      expect(rawBodies.last, '{"active":true}');
      expect(find.text(en.adminReferenceStatusActive), findsWidgets);
    });

    testWidgets('cancelling the confirmation sends nothing', (tester) async {
      await pumpLocations(tester);
      final before = requestLog.length;
      await tapKey(tester, 'admin-reference-location-status-2');
      await tapVisible(tester, find.text(en.adminPartnerCancel));
      expect(requestLog.length, before);
    });

    testWidgets('every status body carries the key, always', (tester) async {
      await pumpLocations(tester);
      await tapKey(tester, 'admin-reference-location-status-3');
      await confirmStatus(tester);
      for (final body in writeBodies) {
        expect(body.containsKey('active'), isTrue,
            reason: 'an omitted key deserializes to false on the server');
        expect(body['active'], isA<bool>());
      }
      expect(rawBodies.every((b) => b != '{}'), isTrue);
    });

    testWidgets('no status wording claims a customer-facing effect', (_) async {
      for (final l in [en, vi]) {
        for (final copy in [
          l.adminReferenceStatusActive,
          l.adminReferenceStatusInactive,
          l.adminReferenceActivate,
          l.adminReferenceDeactivate,
          l.adminReferenceColCmsStatus,
        ]) {
          final lower = copy.toLowerCase();
          for (final forbidden in [
            'hide from customer',
            'hidden from public',
            'no longer visible',
            'removed from search',
            'ẩn khỏi khách',
            'không còn hiển thị',
          ]) {
            expect(lower.contains(forbidden), isFalse,
                reason: '"$copy" implies filtering the server does not do');
          }
        }
      }
    });

    testWidgets('an unanswered status write is uncertain', (tester) async {
      final state =
          await pumpLocations(tester, client: d11Client(writeTimesOut: true));
      await tapKey(tester, 'admin-reference-location-status-2');
      await tester.tap(find.byKey(const Key('admin-reference-status-confirm')));
      await tester.pumpAndSettle(const Duration(seconds: 40));
      expect(state.mutationUncertain, isTrue);
      expect(find.text(en.adminReferenceMutationUncertain), findsOneWidget);
      expect(countOf('GET /api/admin/locations'), 2);
    });

    testWidgets('a second write is refused while one is in flight',
        (tester) async {
      final state =
          await pumpLocations(tester, client: d11Client(writeTimesOut: true));
      final row = state.byId(2)!;
      final first = state.setActive(row, active: false);
      await tester.pump();
      expect(state.isMutating, isTrue);
      expect(await state.setActive(row, active: true), isFalse,
          reason: 'single-flight: the second call is refused outright');
      expect(countOf('PATCH'), 1);
      await tester.pumpAndSettle(const Duration(seconds: 40));
      await first;
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // 7. Safety — the controls that must not exist
  // ═════════════════════════════════════════════════════════════════════════

  group('safety', () {
    testWidgets('no delete affordance exists anywhere', (tester) async {
      await pumpLocations(tester);
      expectNoDeleteAffordance();
      await openCreate(tester);
      expectNoDeleteAffordance();
    });

    testWidgets('the edit dialog exposes exactly five inputs and one picker',
        (tester) async {
      await pumpLocations(tester);
      await openEdit(tester, 2);
      expect(
          dialogInputKeys(tester),
          {
            'admin-reference-name-field',
            'admin-reference-location-code-field',
            'admin-reference-slug-field',
            'admin-reference-location-oldname-field',
            'admin-reference-sort-order-field',
            'admin-reference-location-type-picker',
          },
          reason: 'a control for any read-only field would show up here');
    });

    testWidgets('there is no parent picker, on create or on edit',
        (tester) async {
      await pumpLocations(tester);
      for (final open in [
        () => openCreate(tester),
        () => openEdit(tester, 2),
      ]) {
        await open();
        expect(find.byKey(const Key('admin-reference-parent-picker')),
            findsNothing);
        expect(find.byType(DropdownButtonFormField<int?>), findsNothing,
            reason: 'reparenting has no cycle guard and no path recomputation');
        expect(find.text(en.adminLocationReadOnlyNotice), findsOneWidget);
        await tapVisible(tester, find.text(en.adminPartnerCancel));
      }
    });

    testWidgets('fullPath, level and coordinates have no editor',
        (tester) async {
      await pumpLocations(tester);
      await openEdit(tester, 2);
      final keys = dialogInputKeys(tester);
      for (final forbidden in [
        'admin-reference-location-fullpath-field',
        'admin-reference-location-level-field',
        'admin-reference-location-latitude-field',
        'admin-reference-location-longitude-field',
      ]) {
        expect(keys.contains(forbidden), isFalse);
      }
      // They are shown, read-only, so the operator can see what is preserved.
      expect(find.text('Vietnam > Đà Nẵng'), findsWidgets);
      expect(
          find.text(en.adminLocationFullPathPreservedNotice), findsOneWidget);
    });

    testWidgets('there is no tree editor and no drag reordering',
        (tester) async {
      await pumpLocations(tester);
      expect(find.byType(ExpansionTile), findsNothing);
      expect(find.byType(ReorderableListView), findsNothing);
      for (final icon in [
        Icons.drag_handle,
        Icons.drag_indicator,
        Icons.account_tree,
        Icons.account_tree_outlined,
        Icons.map,
        Icons.map_outlined,
      ]) {
        expect(find.byIcon(icon), findsNothing);
      }
    });

    testWidgets('only the four documented operations are ever issued',
        (tester) async {
      await pumpLocations(tester);
      await tapKey(tester, 'admin-reference-location-status-2');
      await confirmStatus(tester);
      await openCreate(tester);
      await type(tester, 'admin-reference-name-field', 'Somewhere');
      await submitForm(tester);
      await openEdit(tester, 2);
      await type(tester, 'admin-reference-name-field', 'Renamed');
      await submitForm(tester);

      for (final entry in requestLog) {
        final method = entry.split(' ').first;
        expect(['GET', 'POST', 'PUT', 'PATCH'], contains(method),
            reason: entry);
        expect(entry, contains('/api/admin/locations'),
            reason: '$entry left the D11 surface');
      }
    });

    testWidgets('no public location endpoint is touched', (tester) async {
      await pumpLocations(tester);
      await type(tester, 'admin-reference-location-filter', 'hue');
      expect(
          requestLog.where((e) =>
              e.contains('/api/locations/roots') ||
              e.contains('/children') ||
              e.contains('/api/locations/search')),
          isEmpty,
          reason: 'the public reads are out of D11 scope');
    });

    testWidgets('a 409 with no readable message names both conflict axes',
        (tester) async {
      // Locations have two uniqueness axes. Blaming the slug when the code may
      // be at fault would point the operator at the wrong field.
      await pumpLocations(tester,
          client: d11Client(writeStatus: 409, writeMessage: ''));
      await openCreate(tester);
      await type(tester, 'admin-reference-name-field', 'Dup');
      await submitForm(tester);
      expect(find.text(en.adminLocationDuplicateCodeOrSlug), findsOneWidget);
      expect(find.text(en.adminReferenceDuplicateSlug), findsNothing);
    });

    testWidgets('the banner can be dismissed', (tester) async {
      final state =
          await pumpLocations(tester, client: d11Client(writeStatus: 409));
      await openCreate(tester);
      await type(tester, 'admin-reference-name-field', 'Dup');
      await submitForm(tester);
      expect(find.byKey(const Key('admin-reference-mutation-banner')),
          findsOneWidget);
      await tapVisible(tester, find.text(en.adminReferenceDismiss));
      expect(find.byKey(const Key('admin-reference-mutation-banner')),
          findsNothing);
      expect(state.mutationConflict, isFalse);
    });
  });
}
