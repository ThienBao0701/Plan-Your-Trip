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
import 'support/admin_access_stub.dart';

/// D11 — Admin locations, the third tab of the Reference Data destination.
/// D13 — the parent picker, and the location hierarchy it mirrors.
///
/// Fixtures mirror `LocationDto.LocationResponse`. Where a test asserts an
/// **absence** — no `fullPath` box, no level or coordinate editor, no delete —
/// that absence is the requirement, and each one has a reason in the backend:
///
///  * `fullPath` — **customer-visible**: it rides in `PlaceDto.LocationRef` and
///    the traveller app parses it to show a place's province. Since D12 the
///    server derives it on every write, so the form previews it and never
///    edits it;
///  * `level` — derived from nothing and validated against nothing;
///  * `latitude`/`longitude` — no range and no pairing validation;
///  * delete — no endpoint exists, for any role.
///
/// `parentId` was on that list until D13. The backend now guards cycles,
/// recomputes a moved subtree's paths and enforces the hierarchy — COUNTRY top
/// level only; PROVINCE and CITY under a COUNTRY; AREA under a PROVINCE or
/// CITY; WARD and COMMUNE reserved — so the console offers a parent picker that
/// mirrors those rules. Section 8 pins it.
///
/// And because `PUT` is a full replace, every field the form does not edit must
/// be **sent back unchanged** rather than merely left out of the form.
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

  /// D13 — a tree shaped by the hierarchy, plus the legacy shapes the picker
  /// must never offer as a parent.
  List<Map<String, dynamic>> hierarchy() => [
        countryRow(), // 1 COUNTRY
        locationRow(2, parentId: 1), // CITY
        locationRow(3,
            parentId: 1,
            code: 'HCM',
            name: 'TP Hồ Chí Minh',
            slug: 'tp-ho-chi-minh',
            fullPath: 'Vietnam > TP Hồ Chí Minh'),
        locationRow(10,
            parentId: 1,
            code: 'KHO',
            name: 'Khánh Hòa',
            slug: 'khanh-hoa',
            type: 'PROVINCE',
            fullPath: 'Vietnam > Khánh Hòa'),
        locationRow(11,
            parentId: 10,
            code: 'NT',
            name: 'Nha Trang',
            slug: 'nha-trang',
            type: 'AREA',
            level: 3,
            fullPath: 'Vietnam > Khánh Hòa > Nha Trang'),
        locationRow(12,
            parentId: 2,
            code: 'ST',
            name: 'Sơn Trà',
            slug: 'son-tra',
            type: 'AREA',
            level: 3,
            fullPath: 'Vietnam > Đà Nẵng > Sơn Trà'),
        locationRow(13,
            parentId: 1,
            code: 'LDG',
            name: 'Lâm Đồng',
            slug: 'lam-dong',
            type: 'PROVINCE',
            fullPath: 'Vietnam > Lâm Đồng',
            active: false),
        locationRow(20,
            code: 'LA',
            name: 'Lào',
            slug: 'lao',
            type: 'COUNTRY',
            level: 0,
            fullPath: 'Lào'),
        locationRow(21,
            parentId: 20,
            code: 'VTE',
            name: 'Viêng Chăn',
            slug: 'vieng-chan',
            fullPath: 'Lào > Viêng Chăn'),
        // Legacy shapes: rendered in the grid, never offered as a parent.
        locationRow(30,
            parentId: 999,
            code: 'ORP',
            name: 'Orphan City',
            slug: 'orphan-city',
            fullPath: 'Gone > Orphan City'),
        locationRow(31,
            code: 'LRP',
            name: 'Legacy Root Province',
            slug: 'legacy-root-province',
            type: 'PROVINCE',
            fullPath: 'Legacy Root Province'),
        locationRow(32,
            parentId: 31,
            code: 'ULR',
            name: 'Under Legacy Root',
            slug: 'under-legacy-root',
            fullPath: 'Legacy Root Province > Under Legacy Root'),
        locationRow(33,
            parentId: 34,
            code: 'LPA',
            name: 'Loop A',
            slug: 'loop-a',
            fullPath: 'Loop A'),
        locationRow(34,
            parentId: 33,
            code: 'LPB',
            name: 'Loop B',
            slug: 'loop-b',
            fullPath: 'Loop B'),
        locationRow(35,
            parentId: 3,
            code: 'WRD',
            name: 'Legacy Ward',
            slug: 'legacy-ward',
            type: 'WARD',
            fullPath: 'Vietnam > TP Hồ Chí Minh > Legacy Ward'),
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
      AppState(
          api: ApiClient(client: withAdminAccess(client))..demoMode = false)
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
    final parents = tester
        .widgetList<DropdownButtonFormField<int?>>(find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(DropdownButtonFormField<int?>)))
        .map(keyOf);
    return {...fields, ...drops, ...parents};
  }

  const parentPickerKey = 'admin-reference-location-parent-picker';
  const typePickerKey = 'admin-reference-location-type-picker';

  /// Every item a dialog picker offers, enabled or not — read from the widget,
  /// so the answer does not depend on which menu happens to be painted.
  List<DropdownMenuItem<T>> pickerItems<T>(WidgetTester tester, String key) =>
      tester
          .widget<DropdownButton<T>>(find.descendant(
              of: find.byKey(Key(key)),
              matching: find.byType(DropdownButton<T>)))
          .items!;

  /// The parent ids the picker offers, with `null` standing for top level.
  List<int?> parentChoices(WidgetTester tester) => [
        for (final item in pickerItems<int?>(tester, parentPickerKey))
          item.value
      ];

  Future<void> chooseType(WidgetTester tester, String value) async {
    await tapKey(tester, typePickerKey);
    await tester.tap(
        find.byKey(Key('admin-reference-location-type-option-$value')).last);
    await tester.pumpAndSettle();
  }

  Future<void> chooseParent(WidgetTester tester, int? id) async {
    await tapKey(tester, parentPickerKey);
    await tester.tap(find
        .byKey(Key(id == null
            ? 'admin-reference-location-parent-root'
            : 'admin-reference-location-parent-option-$id'))
        .last);
    await tester.pumpAndSettle();
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

    testWidgets('the navigation destination count is unchanged at 11',
        (tester) async {
      await pumpConsole(tester);
      // 10 after D11; RBAC R6 added the Administrators destination.
      expect(AdminNavigation.destinations, hasLength(11),
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

    testWidgets('creates a top level COUNTRY by default', (tester) async {
      // D13: create is no longer root-only. The default type is COUNTRY, and a
      // COUNTRY has exactly one position — top level — so that is all it is
      // offered.
      await pumpLocations(tester);
      await openCreate(tester);
      expect(parentChoices(tester), [null]);
      await type(tester, 'admin-reference-name-field', 'Côn Đảo');
      await submitForm(tester);
      expect(lastWrite()['type'], 'COUNTRY');
      expect(lastWrite()['parentId'], isNull);
      expect(lastWrite()['level'], isNull);
      expect(lastWrite()['latitude'], isNull);
      expect(lastWrite()['longitude'], isNull);
    });

    testWidgets('previews the path the server will derive', (tester) async {
      // D13: the preview is a guide. Since D12 the server derives the stored
      // path itself, and the notice says so.
      await pumpLocations(tester);
      await openCreate(tester);
      expect(
          find.text(en.adminLocationFullPathGeneratedNotice), findsOneWidget);
      await type(tester, 'admin-reference-name-field', 'Côn Đảo');
      expect(find.text('Côn Đảo'), findsWidgets,
          reason: 'the preview follows the name as it is typed');
      await submitForm(tester);
      expect(lastWrite()['fullPath'], 'Côn Đảo',
          reason: "a top-level path is its name — the server's own rule");
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
      expect(lastWrite()['parentId'], 1,
          reason: 'an untouched parent is sent back as it is stored');
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

    testWidgets('a COUNTRY stays top level', (tester) async {
      // D13: a COUNTRY is offered no parent at all, so a rename cannot move it.
      await pumpLocations(tester);
      await openEdit(tester, 1);
      expect(parentChoices(tester), [null]);
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
      await state.update(row,
          name: row.name!, type: row.type!, parentId: row.parentId, code: '  ');
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
      await state.update(row,
          name: 'Nowhere', type: 'AREA', parentId: row.parentId);
      expect(lastWrite()['code'], isNull,
          reason: 'there is no code to preserve, so none is invented');
    });

    testWidgets('the type picker lists the closed backend enum',
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
            reason: '${entry.key} is declared by UnitType and must be listed');
      }
      // D13: listed is not selectable. WARD and COMMUNE have no place in the
      // hierarchy, so they are disabled and marked as reserved.
      for (final item in pickerItems<String>(tester, typePickerKey)) {
        expect(item.enabled, !AdminLocationType.isReserved(item.value),
            reason: '${item.value}');
      }
      expect(find.text(en.adminLocationTypeReservedMarker), findsWidgets);
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

    testWidgets('the edit dialog exposes exactly five inputs and two pickers',
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
            parentPickerKey,
          },
          reason: 'a control for any read-only field would show up here');
    });

    testWidgets('the parent is chosen from a picker, on create and on edit',
        (tester) async {
      // D13 reverses D11's absence: the backend now guards cycles, recomputes
      // a moved subtree's paths and enforces the hierarchy.
      await pumpLocations(tester);
      for (final open in [
        () => openCreate(tester),
        () => openEdit(tester, 2),
      ]) {
        await open();
        final picker = find.byKey(const Key(parentPickerKey));
        expect(picker, findsOneWidget);
        expect(find.byType(DropdownButtonFormField<int?>), findsOneWidget);
        expect(find.descendant(of: picker, matching: find.byType(TextField)),
            findsNothing,
            reason: 'a parent is chosen, never typed');
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
          find.text(en.adminLocationFullPathGeneratedNotice), findsOneWidget);
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

  // ═════════════════════════════════════════════════════════════════════════
  // 8. Hierarchy (D13) — the mirror, the candidates, the picker
  // ═════════════════════════════════════════════════════════════════════════

  group('hierarchy mirror', () {
    test('the placement rules are exactly the backend matrix', () {
      const allowed = {
        'COUNTRY>top',
        'PROVINCE>COUNTRY',
        'CITY>COUNTRY',
        'AREA>PROVINCE',
        'AREA>CITY',
      };
      for (final t in AdminLocationType.values) {
        expect(AdminLocationType.allowsRoot(t), allowed.contains('$t>top'),
            reason: '$t at top level');
        for (final parent in AdminLocationType.values) {
          expect(AdminLocationType.allowsParent(t, parent),
              allowed.contains('$t>$parent'),
              reason: '$t under $parent');
        }
      }
    });

    test('WARD and COMMUNE stay in the enum but are reserved', () {
      expect(AdminLocationType.values, containsAll(['WARD', 'COMMUNE']));
      for (final t in ['WARD', 'COMMUNE']) {
        expect(AdminLocationType.isReserved(t), isTrue);
        expect(AdminLocationType.isAssignable(t), isFalse);
      }
      for (final t in ['COUNTRY', 'PROVINCE', 'CITY', 'AREA']) {
        expect(AdminLocationType.isAssignable(t), isTrue);
        expect(AdminLocationType.isReserved(t), isFalse);
      }
      expect(AdminLocationType.isAssignable(null), isFalse);
      expect(AdminLocationType.isAssignable('DISTRICT'), isFalse);
    });
  });

  group('parent candidates', () {
    Future<AdminLocationsState> loaded() async {
      final state = AdminLocationsState(
          api: ApiClient(client: d11Client(locations: hierarchy())));
      addTearDown(state.dispose);
      await state.load();
      return state;
    }

    List<int> ids(List<AdminLocation> rows) => [for (final l in rows) l.id];

    test('a PROVINCE or a CITY is offered only well-formed countries',
        () async {
      final state = await loaded();
      expect(ids(state.parentOptions(type: 'PROVINCE')), [1, 20]);
      expect(ids(state.parentOptions(type: 'CITY')), [1, 20]);
    });

    test('an AREA is offered every well-formed province and city', () async {
      final state = await loaded();
      expect(ids(state.parentOptions(type: 'AREA')), [2, 3, 10, 13, 21]);
    });

    test('an inactive location remains a valid parent', () async {
      final state = await loaded();
      expect(state.byId(13)!.active, isFalse);
      expect(ids(state.parentOptions(type: 'AREA')), contains(13),
          reason: 'CMS status has no bearing on the hierarchy');
    });

    test('a COUNTRY, a reserved type and an unknown type are offered nothing',
        () async {
      final state = await loaded();
      for (final t in ['COUNTRY', 'WARD', 'COMMUNE', 'DISTRICT', null]) {
        expect(state.parentOptions(type: t), isEmpty, reason: '$t');
      }
    });

    test('types that cannot hold the location are never offered', () async {
      final state = await loaded();
      final forProvince = ids(state.parentOptions(type: 'PROVINCE'));
      for (final id in [2, 3, 10, 11, 12, 13, 21]) {
        expect(forProvince, isNot(contains(id)), reason: 'row $id');
      }
      final forArea = ids(state.parentOptions(type: 'AREA'));
      for (final id in [1, 20, 11, 12]) {
        expect(forArea, isNot(contains(id)), reason: 'row $id');
      }
    });

    test('orphans, cycles and legacy placements are never offered', () async {
      final state = await loaded();
      final wellFormed = state.wellFormedIds();
      expect(wellFormed, {1, 2, 3, 10, 11, 12, 13, 20, 21});
      for (final t in ['PROVINCE', 'CITY', 'AREA']) {
        final offered = ids(state.parentOptions(type: t));
        for (final id in [30, 31, 32, 33, 34, 35]) {
          expect(offered, isNot(contains(id)), reason: '$t: row $id');
        }
      }
    });

    test('the location itself is excluded on update', () async {
      final state = await loaded();
      // Khánh Hòa, reconsidered as an AREA: every other province and city is
      // offered, never itself.
      expect(ids(state.parentOptions(type: 'AREA', editing: state.byId(10))),
          [2, 3, 13, 21]);
    });

    test('every descendant is excluded on update', () async {
      final state = await loaded();
      expect(state.descendantIdsOf(1), {2, 3, 10, 11, 12, 13, 35});
      // Vietnam, reconsidered as an AREA: only Viêng Chăn is not beneath it.
      expect(
          ids(state.parentOptions(type: 'AREA', editing: state.byId(1))), [21]);
    });

    test('a cycle in the data is walked once and cannot hang', () async {
      final state = await loaded();
      expect(state.descendantIdsOf(33), {34});
      expect(state.descendantIdsOf(34), {33});
    });

    test('a type change that would strand a direct child is detected',
        () async {
      final state = await loaded();
      final daNang = state.byId(2)!;
      expect(state.typeChangeStrandsChildren(daNang, 'AREA'), isTrue,
          reason: 'Sơn Trà cannot sit under an AREA');
      expect(state.typeChangeStrandsChildren(daNang, 'PROVINCE'), isFalse,
          reason: 'an AREA sits under a PROVINCE as well');
      expect(state.typeChangeStrandsChildren(daNang, 'CITY'), isFalse,
          reason: 'an unchanged type has nothing to check');
    });

    test('candidates come from the loaded rows, with no request', () async {
      final state = await loaded();
      final before = requestLog.length;
      state.parentOptions(type: 'AREA');
      state.parentOptions(type: 'CITY', editing: state.byId(2));
      state.wellFormedIds();
      expect(requestLog.length, before);
    });
  });

  group('parent picker', () {
    Future<AdminLocationsState> pumpTree(WidgetTester tester) =>
        pumpLocations(tester, client: d11Client(locations: hierarchy()));

    for (final t in ['PROVINCE', 'CITY', 'AREA']) {
      testWidgets('top level is not offered to $t', (tester) async {
        await pumpTree(tester);
        await openCreate(tester);
        expect(parentChoices(tester), [null]);
        await chooseType(tester, t);
        expect(parentChoices(tester), isNot(contains(null)));
        expect(find.byKey(const Key('admin-reference-location-parent-root')),
            findsNothing);
      });
    }

    testWidgets('the picker offers exactly what the state computes',
        (tester) async {
      final state = await pumpTree(tester);
      await openCreate(tester);
      await chooseType(tester, 'AREA');
      expect(parentChoices(tester),
          [for (final l in state.parentOptions(type: 'AREA')) l.id]);
      expect(parentChoices(tester), [2, 3, 10, 13, 21]);
    });

    testWidgets('on edit, the location and its descendants are not offered',
        (tester) async {
      await pumpTree(tester);
      await openEdit(tester, 1);
      await chooseType(tester, 'AREA');
      expect(parentChoices(tester), [21],
          reason: 'everything else that could hold an AREA is under Vietnam');
      expect(find.text(en.adminLocationParentGuardNotice), findsOneWidget);
    });

    testWidgets('creates a PROVINCE under a COUNTRY', (tester) async {
      await pumpTree(tester);
      await openCreate(tester);
      await type(tester, 'admin-reference-name-field', 'Bình Định');
      await chooseType(tester, 'PROVINCE');
      await chooseParent(tester, 1);
      expect(find.text('Vietnam > Bình Định'), findsOneWidget,
          reason: 'the preview follows the chosen parent');
      await submitForm(tester);
      expect(countOf('POST /api/admin/locations'), 1);
      expect(lastWrite()['type'], 'PROVINCE');
      expect(lastWrite()['parentId'], 1);
      expect(lastWrite()['fullPath'], 'Vietnam > Bình Định',
          reason: 'sent as previewed; the server derives its own');
      expect(lastWrite()['level'], isNull,
          reason: 'the console never derives a level');
    });

    testWidgets('creates a CITY under a COUNTRY', (tester) async {
      await pumpTree(tester);
      await openCreate(tester);
      await type(tester, 'admin-reference-name-field', 'Pakse');
      await chooseType(tester, 'CITY');
      await chooseParent(tester, 20);
      expect(find.text('Lào > Pakse'), findsOneWidget);
      await submitForm(tester);
      expect(lastWrite()['type'], 'CITY');
      expect(lastWrite()['parentId'], 20);
    });

    for (final entry in {
      10: 'Vietnam > Khánh Hòa > Cam Ranh',
      2: 'Vietnam > Đà Nẵng > Cam Ranh',
    }.entries) {
      testWidgets('creates an AREA under ${entry.value.split(' > ')[1]}',
          (tester) async {
        await pumpTree(tester);
        await openCreate(tester);
        await type(tester, 'admin-reference-name-field', 'Cam Ranh');
        await chooseType(tester, 'AREA');
        await chooseParent(tester, entry.key);
        expect(find.text(entry.value), findsOneWidget);
        await submitForm(tester);
        expect(lastWrite()['type'], 'AREA');
        expect(lastWrite()['parentId'], entry.key);
      });
    }

    testWidgets('an inactive parent is offered, marked, and accepted',
        (tester) async {
      await pumpTree(tester);
      await openCreate(tester);
      await type(tester, 'admin-reference-name-field', 'Đà Lạt');
      await chooseType(tester, 'AREA');
      await chooseParent(tester, 13);
      expect(
          find.descendant(
              of: find.byKey(const Key(parentPickerKey)),
              matching: find.text(en.adminReferenceStatusInactive)),
          findsOneWidget);
      await submitForm(tester);
      expect(lastWrite()['type'], 'AREA');
      expect(lastWrite()['parentId'], 13);
    });

    testWidgets('reparents an AREA from a PROVINCE to a CITY', (tester) async {
      await pumpTree(tester);
      await openEdit(tester, 11);
      expect(parentChoices(tester), [2, 3, 10, 13, 21]);
      await chooseParent(tester, 2);
      expect(find.text('Vietnam > Đà Nẵng > Nha Trang'), findsOneWidget);
      await submitForm(tester);

      expect(countOf('PUT /api/admin/locations/11'), 1);
      expect(lastWrite()['type'], 'AREA');
      expect(lastWrite()['parentId'], 2);
      // Everything the form does not edit still goes back as stored.
      expect(lastWrite()['slug'], 'nha-trang');
      expect(lastWrite()['code'], 'NT');
      expect(lastWrite()['level'], 3);
      expect(lastWrite()['latitude'], 16.0544);
      expect(lastWrite()['longitude'], 108.2022);
      expect(lastWrite()['fullPath'], 'Vietnam > Khánh Hòa > Nha Trang',
          reason: 'echoed, never invented: the server derives the moved path');
      expect(countOf('GET /api/admin/locations'), 2,
          reason: 'a confirmed move is followed by a re-read');
      expectNoDeleteAffordance();
    });

    testWidgets('a type change the parent still allows keeps the parent',
        (tester) async {
      await pumpTree(tester);
      await openEdit(tester, 10);
      await chooseType(tester, 'CITY');
      expect(find.text(en.adminLocationParentCleared), findsNothing);
      await submitForm(tester);
      expect(lastWrite()['type'], 'CITY');
      expect(lastWrite()['parentId'], 1);
    });

    testWidgets('a PROVINCE with no parent is refused before any request',
        (tester) async {
      await pumpTree(tester);
      final before = requestLog.length;
      await openCreate(tester);
      await type(tester, 'admin-reference-name-field', 'Floating');
      await chooseType(tester, 'PROVINCE');
      await submitForm(tester);
      expect(find.text(en.adminLocationParentRequired), findsOneWidget);
      expect(requestLog.length, before,
          reason: 'a top-level PROVINCE is never sent');
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('a type the chosen parent cannot hold clears it, and says so',
        (tester) async {
      await pumpTree(tester);
      final before = requestLog.length;
      await openEdit(tester, 11);
      await chooseType(tester, 'CITY');
      expect(find.byKey(const Key('admin-reference-location-parent-cleared')),
          findsOneWidget);
      expect(find.text(en.adminLocationParentCleared), findsOneWidget);
      expect(parentChoices(tester), [1, 20]);
      await submitForm(tester);
      expect(find.text(en.adminLocationParentRequired), findsOneWidget,
          reason: 'the cleared parent is not silently replaced by top level');
      expect(requestLog.length, before);
    });

    testWidgets('a type change that would strand a child is refused',
        (tester) async {
      await pumpTree(tester);
      final before = requestLog.length;
      await openEdit(tester, 2);
      await chooseType(tester, 'AREA');
      await chooseParent(tester, 10);
      await submitForm(tester);
      expect(find.text(en.adminLocationTypeBlockedByChildren), findsOneWidget,
          reason: 'Sơn Trà cannot sit under an AREA');
      expect(requestLog.length, before);
    });

    testWidgets('a legacy WARD cannot be saved as it is', (tester) async {
      await pumpTree(tester);
      final before = requestLog.length;
      await openEdit(tester, 35);
      expect(parentChoices(tester), isEmpty,
          reason: 'a reserved type has no place to go');
      await submitForm(tester);
      expect(find.text(en.adminLocationTypeUnavailable), findsOneWidget);
      expect(requestLog.length, before);
    });

    testWidgets('the path is previewed from the parent, never edited',
        (tester) async {
      await pumpTree(tester);
      await openEdit(tester, 11);
      expect(find.text('Vietnam > Khánh Hòa > Nha Trang'), findsOneWidget);
      expect(
          find.text(en.adminLocationFullPathGeneratedNotice), findsOneWidget);
      expect(
          dialogInputKeys(tester)
              .contains('admin-reference-location-fullpath-field'),
          isFalse);
    });

    for (final entry in {'en': en, 'vi': vi}.entries) {
      testWidgets('${entry.key} labels the parent picker', (tester) async {
        await pumpLocations(tester, locale: Locale(entry.key));
        await openCreate(tester);
        expect(find.text(entry.value.adminLocationFieldParent), findsWidgets);
        expect(
            find.text(entry.value.adminLocationHierarchyRule), findsOneWidget);
      });
    }
  });
}
