import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/mock/app_models.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/trips/real_trip_documents_screen.dart';
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

  Map<String, dynamic> documentJson({
    int id = 1,
    String documentType = 'FLIGHT_TICKET',
    String? title = 'Outbound ticket',
    bool pinned = true,
    String url = 'https://example.com/ticket.pdf',
  }) =>
      {
        'id': id,
        'tripPlanId': 7,
        'tripDayId': null,
        'tripItemId': null,
        'mediaAsset': {
          'id': 20,
          'ownerType': 'TRIP_DOCUMENT',
          'ownerId': 7,
          'url': url,
          'thumbnailUrl': null,
          'mediaType': 'DOCUMENT',
          'altText': null,
          'sortOrder': 0,
          'cover': false,
          'active': true,
          'uploadedByUserId': 9,
          'createdAt': '2030-05-01T10:00:00Z',
          'updatedAt': '2030-05-01T10:00:00Z',
        },
        'uploadedByUserId': 9,
        'uploadedByUserName': 'Bao',
        'documentType': documentType,
        'title': title,
        'notes': 'Seat 12A',
        'pinned': pinned,
        'createdAt': '2030-05-01T10:00:00Z',
        'updatedAt': '2030-05-01T10:00:00Z',
      };

  bool listPath(http.Request r) =>
      r.method == 'GET' && r.url.path.endsWith('/me/trips/7/documents');
  bool createPath(http.Request r) =>
      r.method == 'POST' && r.url.path.endsWith('/me/trips/7/documents');
  bool updatePath(http.Request r) =>
      r.method == 'PUT' &&
      RegExp(r'/me/trips/documents/\d+$').hasMatch(r.url.path);
  bool deletePath(http.Request r) =>
      r.method == 'DELETE' &&
      RegExp(r'/me/trips/documents/\d+$').hasMatch(r.url.path);
  bool pinPath(http.Request r) =>
      r.method == 'PATCH' && r.url.path.endsWith('/pin');
  bool unpinPath(http.Request r) =>
      r.method == 'PATCH' && r.url.path.endsWith('/unpin');

  AppState routedApp({
    Future<http.Response> Function(http.Request)? onList,
    Future<http.Response> Function(http.Request)? onCreate,
    Future<http.Response> Function(http.Request)? onUpdate,
    Future<http.Response> Function(http.Request)? onDelete,
    Future<http.Response> Function(http.Request)? onPin,
    Future<http.Response> Function(http.Request)? onUnpin,
    void Function(http.Request)? onRequest,
  }) =>
      realApp(MockClient((request) async {
        onRequest?.call(request);
        if (createPath(request)) {
          return (onCreate ??
              (_) async => jsonResponse(documentJson(id: 99), 201))(request);
        }
        if (updatePath(request)) {
          return (onUpdate ??
              (_) async => jsonResponse(documentJson(), 200))(request);
        }
        if (deletePath(request)) {
          return (onDelete ?? (_) async => http.Response('', 204))(request);
        }
        if (pinPath(request)) {
          return (onPin ??
              (_) async =>
                  jsonResponse(documentJson(pinned: true), 200))(request);
        }
        if (unpinPath(request)) {
          return (onUnpin ??
              (_) async =>
                  jsonResponse(documentJson(pinned: false), 200))(request);
        }
        if (listPath(request)) {
          return (onList ??
              (_) async => jsonResponse([documentJson()], 200))(request);
        }
        return jsonResponse(const <String, dynamic>{}, 200);
      }));

  RealTripDocumentPayload payload() => const RealTripDocumentPayload(
        documentType: TripDocumentType.flightTicket,
        title: 'Ticket',
        url: 'https://example.com/x.pdf',
      );

  // ── Contract parsing ───────────────────────────────────────────────────────

  group('Contract parsing', () {
    test('list parses nested media; correct path', () async {
      http.Request? seen;
      final app = routedApp(onRequest: (r) {
        if (listPath(r)) seen = r;
      });
      expect(await app.loadRealDocuments(7), DocumentOutcome.success);
      expect(seen!.url.path.endsWith('/me/trips/7/documents'), isTrue);
      final d = app.realDocumentsFor(7).single;
      expect(d.id, 1);
      expect(d.typeView, TripDocumentType.flightTicket);
      expect(d.title, 'Outbound ticket');
      expect(d.pinned, isTrue);
      expect(d.mediaUrl, 'https://example.com/ticket.pdf');
      expect(d.mediaType, 'DOCUMENT');
      expect(d.uploadedByUserName, 'Bao');
    });

    test('type mapper + wire code; unknown → null', () {
      expect(tripDocumentTypeFromCode('PASSPORT'), TripDocumentType.passport);
      expect(tripDocumentTypeFromCode('NOPE'), isNull);
      expect(TripDocumentType.flightTicket.code, 'FLIGHT_TICKET');
    });

    test('payload toJson emits type wire code + url', () {
      final json = payload().toJson();
      expect(json['documentType'], 'FLIGHT_TICKET');
      expect(json['title'], 'Ticket');
      expect(json['url'], 'https://example.com/x.pdf');
      expect(json.containsKey('tripDayId'), isTrue);
    });

    test('non-list body → serverError (malformed)', () async {
      final app = realApp(MockClient((_) async => http.Response('{}', 200)));
      expect(await app.loadRealDocuments(7), DocumentOutcome.serverError);
    });
  });

  // ── Demo Mode (zero HTTP) ────────────────────────────────────────────────────

  group('Demo Mode', () {
    test('all methods return demoUnavailable with zero HTTP', () async {
      var calls = 0;
      final app = demoApp(MockClient((_) async {
        calls++;
        return jsonResponse([documentJson()], 200);
      }));
      expect(await app.loadRealDocuments(7), DocumentOutcome.demoUnavailable);
      expect(await app.createRealDocument(7, payload()),
          DocumentOutcome.demoUnavailable);
      expect(await app.updateRealDocument(7, 1, payload()),
          DocumentOutcome.demoUnavailable);
      expect(
          await app.deleteRealDocument(7, 1), DocumentOutcome.demoUnavailable);
      expect(await app.setRealDocumentPinned(7, 1, true),
          DocumentOutcome.demoUnavailable);
      expect(calls, 0);
      expect(app.realDocumentsFor(7), isEmpty);
    });
  });

  // ── CRUD + pin ────────────────────────────────────────────────────────────────

  group('CRUD', () {
    test('cached list not re-fetched unless refreshed', () async {
      var gets = 0;
      final app = routedApp(onRequest: (r) {
        if (listPath(r)) gets++;
      });
      await app.loadRealDocuments(7);
      await app.loadRealDocuments(7);
      expect(gets, 1);
      await app.loadRealDocuments(7, refresh: true);
      expect(gets, 2);
    });

    test('create POSTs the payload and reloads', () async {
      Map<String, dynamic>? body;
      var listGets = 0;
      final app = routedApp(
        onRequest: (r) {
          if (listPath(r)) listGets++;
        },
        onCreate: (r) async {
          body = jsonDecode(r.body) as Map<String, dynamic>;
          return jsonResponse(documentJson(id: 99), 201);
        },
      );
      await app.loadRealDocuments(7);
      expect(listGets, 1);
      expect(
          await app.createRealDocument(7, payload()), DocumentOutcome.success);
      expect(body!['documentType'], 'FLIGHT_TICKET');
      expect(body!['url'], 'https://example.com/x.pdf');
      expect(listGets, 2);
    });

    test('update PUTs to the document id and reloads', () async {
      http.Request? seen;
      final app = routedApp(onRequest: (r) {
        if (updatePath(r)) seen = r;
      });
      await app.loadRealDocuments(7);
      expect(await app.updateRealDocument(7, 1, payload()),
          DocumentOutcome.success);
      expect(seen!.url.path.endsWith('/me/trips/documents/1'), isTrue);
    });

    test('delete DELETEs and reloads', () async {
      http.Request? seen;
      var listGets = 0;
      final app = routedApp(onRequest: (r) {
        if (deletePath(r)) seen = r;
        if (listPath(r)) listGets++;
      });
      await app.loadRealDocuments(7);
      expect(await app.deleteRealDocument(7, 1), DocumentOutcome.success);
      expect(seen!.url.path.endsWith('/me/trips/documents/1'), isTrue);
      expect(listGets, 2);
    });

    test('pin/unpin PATCH the right paths', () async {
      final seen = <String>[];
      final app = routedApp(onRequest: (r) {
        if (pinPath(r) || unpinPath(r)) seen.add(r.url.path);
      });
      await app.loadRealDocuments(7);
      expect(
          await app.setRealDocumentPinned(7, 1, true), DocumentOutcome.success);
      expect(await app.setRealDocumentPinned(7, 1, false),
          DocumentOutcome.success);
      expect(seen[0].endsWith('/me/trips/documents/1/pin'), isTrue);
      expect(seen[1].endsWith('/me/trips/documents/1/unpin'), isTrue);
    });
  });

  // ── Errors ───────────────────────────────────────────────────────────────────

  group('Errors', () {
    test('401 → sessionExpired, no auto-logout / no demo switch', () async {
      final app = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(401, 'x', '/me/trips/7/documents'), 401),
      );
      app.email = 'bao@example.com';
      app.api.token = 'jwt-token';
      expect(await app.loadRealDocuments(7), DocumentOutcome.sessionExpired);
      expect(app.email, 'bao@example.com');
      expect(app.api.token, 'jwt-token');
      expect(app.demoMode, isFalse);
    });

    test('403 forbidden on create; 404 on update; 400 validation', () async {
      final f = routedApp(
        onCreate: (_) async =>
            jsonResponse(errorBody(403, 'x', '/me/trips/7/documents'), 403),
      );
      expect(
          await f.createRealDocument(7, payload()), DocumentOutcome.forbidden);

      final nf = routedApp(
        onUpdate: (_) async =>
            jsonResponse(errorBody(404, 'x', '/me/trips/documents/1'), 404),
      );
      expect(await nf.updateRealDocument(7, 1, payload()),
          DocumentOutcome.notFound);

      final inv = routedApp(
        onCreate: (_) async =>
            jsonResponse(errorBody(400, 'x', '/me/trips/7/documents'), 400),
      );
      expect(await inv.createRealDocument(7, payload()),
          DocumentOutcome.validation);
    });

    test('list 500 → serverError; network', () async {
      final se = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(500, 'x', '/me/trips/7/documents'), 500),
      );
      expect(await se.loadRealDocuments(7), DocumentOutcome.serverError);

      final net = realApp(MockClient((_) async {
        throw http.ClientException('offline');
      }));
      expect(await net.loadRealDocuments(7), DocumentOutcome.network);
    });

    test('a failed refresh preserves the previously loaded list', () async {
      var fail = false;
      final app = routedApp(
        onList: (_) async => fail
            ? jsonResponse(errorBody(500, 'x', '/me/trips/7/documents'), 500)
            : jsonResponse([documentJson()], 200),
      );
      await app.loadRealDocuments(7);
      expect(app.realDocumentsFor(7), isNotEmpty);
      fail = true;
      expect(await app.loadRealDocuments(7, refresh: true),
          DocumentOutcome.serverError);
      expect(app.realDocumentsFor(7), isNotEmpty);
    });
  });

  // ── Session isolation ────────────────────────────────────────────────────────

  group('Session isolation', () {
    test('logout clears all document state', () async {
      final app = routedApp();
      await app.loadRealDocuments(7);
      expect(app.realDocumentsFor(7), isNotEmpty);
      await app.logout();
      expect(app.realDocumentsFor(7), isEmpty);
      expect(app.realDocumentsTripId, isNull);
      expect(app.realDocumentsLoaded, isFalse);
    });
  });

  // ── Widgets ──────────────────────────────────────────────────────────────────

  group('Widgets', () {
    testWidgets('renders content + document cards', (t) async {
      final app = routedApp();
      await pumpSize(
        t,
        testApp(child: const RealTripDocumentsScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('documents-content')), findsOneWidget);
      expect(find.byKey(const Key('document-card-1')), findsOneWidget);
    });

    testWidgets('add opens the form; saving POSTs and closes', (t) async {
      var created = 0;
      final app = routedApp(onRequest: (r) {
        if (createPath(r)) created++;
      });
      await pumpSize(
        t,
        testApp(child: const RealTripDocumentsScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('documents-add')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('document-form-content')), findsOneWidget);
      await t.enterText(
          find.byKey(const Key('document-field-url')), 'https://x.com/a.pdf');
      await t.tap(find.byKey(const Key('document-form-save')));
      await t.pumpAndSettle();
      expect(created, 1);
      expect(find.byKey(const Key('document-form-content')), findsNothing);
    });

    testWidgets('create form blocks submit without a url (no HTTP)', (t) async {
      var created = 0;
      final app = routedApp(onRequest: (r) {
        if (createPath(r)) created++;
      });
      await pumpSize(
        t,
        testApp(child: const RealTripDocumentsScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('documents-add')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('document-form-save')));
      await t.pumpAndSettle();
      expect(created, 0);
      expect(find.byKey(const Key('document-form-content')), findsOneWidget);
    });

    testWidgets('delete confirms then DELETEs', (t) async {
      var deleted = 0;
      final app = routedApp(onRequest: (r) {
        if (deletePath(r)) deleted++;
      });
      await pumpSize(
        t,
        testApp(child: const RealTripDocumentsScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('document-delete-1')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('document-delete-confirm')));
      await t.pumpAndSettle();
      expect(deleted, 1);
    });

    testWidgets('empty feed shows the empty state', (t) async {
      final app = routedApp(onList: (_) async => jsonResponse(const [], 200));
      await pumpSize(
        t,
        testApp(child: const RealTripDocumentsScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('documents-empty')), findsOneWidget);
    });

    testWidgets('a 401 shows the inline session-expired state', (t) async {
      final app = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(401, 'x', '/me/trips/7/documents'), 401),
      );
      await pumpSize(
        t,
        testApp(child: const RealTripDocumentsScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      expect(
          find.byKey(const Key('documents-session-expired')), findsOneWidget);
    });
  });

  // ── Localization parity ──────────────────────────────────────────────────────

  group('Localization parity', () {
    test('every new UI43 key is present in both EN and VI', () {
      final en = AppLocalizationsEn();
      final vi = AppLocalizationsVi();
      final enValues = <String>[
        en.documentsRealLoadingMessage,
        en.documentsRealErrorMessage,
        en.documentsRealForbiddenMessage,
        en.documentsRealGoneMessage,
        en.documentsRealNetworkMessage,
        en.documentsRealActionErrorMessage,
        en.documentsRealCreatedMessage,
        en.documentsRealUpdatedMessage,
        en.documentsRealPinnedMessage,
        en.documentsRealUnpinnedMessage,
        en.documentsRealUrlRequiredMessage,
        en.documentsRealAddSemantic,
        en.documentsRealTypeUnknown,
      ];
      final viValues = <String>[
        vi.documentsRealLoadingMessage,
        vi.documentsRealErrorMessage,
        vi.documentsRealForbiddenMessage,
        vi.documentsRealGoneMessage,
        vi.documentsRealNetworkMessage,
        vi.documentsRealActionErrorMessage,
        vi.documentsRealCreatedMessage,
        vi.documentsRealUpdatedMessage,
        vi.documentsRealPinnedMessage,
        vi.documentsRealUnpinnedMessage,
        vi.documentsRealUrlRequiredMessage,
        vi.documentsRealAddSemantic,
        vi.documentsRealTypeUnknown,
      ];
      for (final v in enValues) {
        expect(v.trim(), isNotEmpty);
      }
      for (final v in viValues) {
        expect(v.trim(), isNotEmpty);
      }
      expect(en.documentsRealCreatedMessage,
          isNot(vi.documentsRealCreatedMessage));
    });

    test('reused demo document keys still resolve', () {
      final en = AppLocalizationsEn();
      expect(en.tripDocumentsTitle.trim(), isNotEmpty);
      expect(en.tripDocumentDeleteConfirmMessage('Ticket'), contains('Ticket'));
      expect(en.tripDocumentCardSemantic('Ticket'), contains('Ticket'));
    });
  });
}
