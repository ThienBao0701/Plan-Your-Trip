import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/mock/app_models.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/trips/real_shared_trips_screen.dart';
import 'package:planyourtrip_frontend/features/trips/real_trip_detail_screen.dart';
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

  Map<String, dynamic> sharedTripJson({
    int tripId = 7,
    String title = 'Da Nang getaway',
    String? destination = 'Da Nang',
    String status = 'ACTIVE',
    String ownerName = 'Owner Le',
    String role = 'VIEWER',
    String? startDate = '2030-05-01',
    String? endDate = '2030-05-05',
  }) =>
      {
        'tripId': tripId,
        'title': title,
        'destination': destination,
        'coverImage': null,
        'startDate': startDate,
        'endDate': endDate,
        'status': status,
        'ownerName': ownerName,
        'role': role,
      };

  Map<String, dynamic> tripDetailJson(int id) => {
        'id': id,
        'userId': 1,
        'title': 'Da Nang getaway',
        'status': 'ACTIVE',
        'isPublic': false,
        'days': const [],
      };

  bool sharedPath(http.Request r) =>
      r.method == 'GET' && r.url.path.endsWith('/me/trips/shared');
  bool detailPath(http.Request r) =>
      r.method == 'GET' &&
      RegExp(r'/me/trips/\d+$').hasMatch(r.url.path) &&
      !r.url.path.endsWith('/shared');

  AppState routedApp({
    Future<http.Response> Function(http.Request)? onShared,
    void Function(http.Request)? onRequest,
  }) =>
      realApp(MockClient((request) async {
        onRequest?.call(request);
        if (sharedPath(request)) {
          return (onShared ??
              (_) async => jsonResponse([sharedTripJson()], 200))(request);
        }
        if (detailPath(request)) {
          return jsonResponse(tripDetailJson(7), 200);
        }
        return jsonResponse(const <String, dynamic>{}, 200);
      }));

  // ── Contract parsing ───────────────────────────────────────────────────────

  group('Contract parsing', () {
    test('bare list parses; correct path + fields', () async {
      http.Request? seen;
      final app = routedApp(onRequest: (r) {
        if (sharedPath(r)) seen = r;
      });
      expect(await app.loadRealSharedTrips(), SharedTripsOutcome.success);
      expect(seen!.url.path.endsWith('/me/trips/shared'), isTrue);
      final t = app.realSharedTrips.single;
      expect(t.tripId, 7);
      expect(t.title, 'Da Nang getaway');
      expect(t.destination, 'Da Nang');
      expect(t.ownerName, 'Owner Le');
      expect(t.roleView, TripCollaboratorRole.viewer);
      expect(t.statusView, TripPlanStatusValue.active);
      expect(t.startDate, DateTime(2030, 5, 1));
      expect(t.endDate, DateTime(2030, 5, 5));
    });

    test('nullable destination/dates degrade to null', () {
      final t = RealSharedTrip.fromJson(sharedTripJson(
        destination: null,
        startDate: null,
        endDate: null,
      ));
      expect(t.destination, isNull);
      expect(t.startDate, isNull);
      expect(t.endDate, isNull);
    });

    test('unknown role/status never crash (safe fallbacks)', () {
      final t = RealSharedTrip.fromJson(
          sharedTripJson(role: 'SUPERADMIN', status: 'WAT'));
      expect(t.roleView, isNull);
      expect(t.statusView, TripPlanStatusValue.unknown);
    });

    test('editor role maps', () {
      final t = RealSharedTrip.fromJson(sharedTripJson(role: 'EDITOR'));
      expect(t.roleView, TripCollaboratorRole.editor);
    });

    test('non-list body → serverError (malformed)', () async {
      final app = realApp(MockClient((_) async => http.Response('{}', 200)));
      expect(await app.loadRealSharedTrips(), SharedTripsOutcome.serverError);
    });
  });

  // ── Demo Mode (zero HTTP) ────────────────────────────────────────────────────

  group('Demo Mode', () {
    test('loadRealSharedTrips → demoUnavailable, zero HTTP', () async {
      var calls = 0;
      final app = demoApp(MockClient((_) async {
        calls++;
        return jsonResponse([sharedTripJson()], 200);
      }));
      expect(
          await app.loadRealSharedTrips(), SharedTripsOutcome.demoUnavailable);
      expect(calls, 0);
      expect(app.realSharedTrips, isEmpty);
    });
  });

  // ── Load / cache / refresh ────────────────────────────────────────────────────

  group('Load / cache / refresh', () {
    test('cached list not re-fetched unless refreshed', () async {
      var gets = 0;
      final app = routedApp(onRequest: (r) {
        if (sharedPath(r)) gets++;
      });
      await app.loadRealSharedTrips();
      await app.loadRealSharedTrips();
      expect(gets, 1);
      await app.loadRealSharedTrips(refresh: true);
      expect(gets, 2);
    });

    test('a failed refresh preserves the previously loaded list', () async {
      var fail = false;
      final app = routedApp(
        onShared: (_) async => fail
            ? jsonResponse(errorBody(500, 'x', '/me/trips/shared'), 500)
            : jsonResponse([sharedTripJson()], 200),
      );
      await app.loadRealSharedTrips();
      expect(app.realSharedTrips, isNotEmpty);
      fail = true;
      expect(await app.loadRealSharedTrips(refresh: true),
          SharedTripsOutcome.serverError);
      expect(app.realSharedTrips, isNotEmpty);
    });
  });

  // ── Errors ───────────────────────────────────────────────────────────────────

  group('Errors', () {
    test('401 → sessionExpired, no auto-logout / no demo switch', () async {
      final app = routedApp(
        onShared: (_) async =>
            jsonResponse(errorBody(401, 'x', '/me/trips/shared'), 401),
      );
      app.email = 'bao@example.com';
      app.api.token = 'jwt-token';
      expect(
          await app.loadRealSharedTrips(), SharedTripsOutcome.sessionExpired);
      expect(app.email, 'bao@example.com');
      expect(app.api.token, 'jwt-token');
      expect(app.demoMode, isFalse);
    });

    test('403 → forbidden; 404 → notFound', () async {
      final f = routedApp(
        onShared: (_) async =>
            jsonResponse(errorBody(403, 'x', '/me/trips/shared'), 403),
      );
      expect(await f.loadRealSharedTrips(), SharedTripsOutcome.forbidden);

      final nf = routedApp(
        onShared: (_) async =>
            jsonResponse(errorBody(404, 'x', '/me/trips/shared'), 404),
      );
      expect(await nf.loadRealSharedTrips(), SharedTripsOutcome.notFound);
    });

    test('500 → serverError; network', () async {
      final se = routedApp(
        onShared: (_) async =>
            jsonResponse(errorBody(500, 'x', '/me/trips/shared'), 500),
      );
      expect(await se.loadRealSharedTrips(), SharedTripsOutcome.serverError);

      final net = realApp(MockClient((_) async {
        throw http.ClientException('offline');
      }));
      expect(await net.loadRealSharedTrips(), SharedTripsOutcome.network);
    });
  });

  // ── Session isolation ────────────────────────────────────────────────────────

  group('Session isolation', () {
    test('logout clears all shared-trip state', () async {
      final app = routedApp();
      await app.loadRealSharedTrips();
      expect(app.realSharedTrips, isNotEmpty);
      await app.logout();
      expect(app.realSharedTrips, isEmpty);
      expect(app.realSharedTripsLoaded, isFalse);
    });
  });

  // ── Widgets ──────────────────────────────────────────────────────────────────

  group('Widgets', () {
    testWidgets('renders content + shared trip card', (t) async {
      final app = routedApp();
      await pumpSize(
        t,
        testApp(child: const RealSharedTripsScreen(), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('shared-trips-content')), findsOneWidget);
      expect(find.byKey(const Key('shared-trip-card-7')), findsOneWidget);
      expect(find.text('Da Nang getaway'), findsWidgets);
    });

    testWidgets('tapping a card opens the real trip detail screen', (t) async {
      final app = routedApp();
      await pumpSize(
        t,
        testApp(child: const RealSharedTripsScreen(), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('shared-trip-card-7')));
      await t.pumpAndSettle();
      expect(find.byType(RealTripDetailScreen), findsOneWidget);
    });

    testWidgets('empty feed shows the empty state', (t) async {
      final app = routedApp(onShared: (_) async => jsonResponse(const [], 200));
      await pumpSize(
        t,
        testApp(child: const RealSharedTripsScreen(), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('shared-trips-empty')), findsOneWidget);
    });

    testWidgets('a 401 shows the inline session-expired state', (t) async {
      final app = routedApp(
        onShared: (_) async =>
            jsonResponse(errorBody(401, 'x', '/me/trips/shared'), 401),
      );
      await pumpSize(
        t,
        testApp(child: const RealSharedTripsScreen(), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('shared-trips-session-expired')),
          findsOneWidget);
    });

    testWidgets('an error shows the recoverable error state', (t) async {
      final app = routedApp(
        onShared: (_) async =>
            jsonResponse(errorBody(500, 'x', '/me/trips/shared'), 500),
      );
      await pumpSize(
        t,
        testApp(child: const RealSharedTripsScreen(), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('shared-trips-error')), findsOneWidget);
    });
  });

  // ── Localization parity ──────────────────────────────────────────────────────

  group('Localization parity', () {
    test('every new UI49 key is present in both EN and VI', () {
      final en = AppLocalizationsEn();
      final vi = AppLocalizationsVi();
      final enValues = <String>[
        en.sharedTripsRealLoadingMessage,
        en.sharedTripsRealErrorMessage,
        en.sharedTripsRealForbiddenMessage,
        en.sharedTripsRealGoneMessage,
        en.sharedTripsRealEmptyTitle,
        en.sharedTripsRealEmptyMessage,
        en.sharedTripsRealUntitled,
        en.sharedTripsRealEntryTitle,
        en.sharedTripsRealEntrySubtitle,
        en.sharedTripsRealEntrySemantic,
      ];
      final viValues = <String>[
        vi.sharedTripsRealLoadingMessage,
        vi.sharedTripsRealErrorMessage,
        vi.sharedTripsRealForbiddenMessage,
        vi.sharedTripsRealGoneMessage,
        vi.sharedTripsRealEmptyTitle,
        vi.sharedTripsRealEmptyMessage,
        vi.sharedTripsRealUntitled,
        vi.sharedTripsRealEntryTitle,
        vi.sharedTripsRealEntrySubtitle,
        vi.sharedTripsRealEntrySemantic,
      ];
      for (final v in enValues) {
        expect(v.trim(), isNotEmpty);
      }
      for (final v in viValues) {
        expect(v.trim(), isNotEmpty);
      }
      expect(en.sharedTripsRealEntryTitle, isNot(vi.sharedTripsRealEntryTitle));
    });

    test('reused generic keys resolve', () {
      final en = AppLocalizationsEn();
      expect(en.sharedWithMeTitle.trim(), isNotEmpty);
      expect(en.sharedWithMeOwnerLabel('Le'), contains('Le'));
      expect(en.tripCardSemantic('Da Nang'), contains('Da Nang'));
      expect(en.collaborationRoleViewer.trim(), isNotEmpty);
      expect(en.tripStatusActive.trim(), isNotEmpty);
    });
  });
}
