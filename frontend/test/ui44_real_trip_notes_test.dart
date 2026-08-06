import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/mock/app_models.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/trips/real_trip_notes_screen.dart';
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

  Map<String, dynamic> noteJson({
    int id = 1,
    String noteType = 'JOURNAL',
    String? title = 'Day one',
    String content = 'Landed safely, great weather.',
    String? mood = 'HAPPY',
    bool pinned = true,
  }) =>
      {
        'id': id,
        'tripPlanId': 7,
        'tripDayId': null,
        'tripItemId': null,
        'authorUserId': 9,
        'authorUserName': 'Bao',
        'noteType': noteType,
        'title': title,
        'content': content,
        'mood': mood,
        'photoUrl': null,
        'pinned': pinned,
        'createdAt': '2030-05-01T10:00:00Z',
        'updatedAt': '2030-05-01T10:00:00Z',
      };

  bool listPath(http.Request r) =>
      r.method == 'GET' && r.url.path.endsWith('/me/trips/7/notes');
  bool createPath(http.Request r) =>
      r.method == 'POST' && r.url.path.endsWith('/me/trips/7/notes');
  bool updatePath(http.Request r) =>
      r.method == 'PUT' && RegExp(r'/me/trips/notes/\d+$').hasMatch(r.url.path);
  bool deletePath(http.Request r) =>
      r.method == 'DELETE' &&
      RegExp(r'/me/trips/notes/\d+$').hasMatch(r.url.path);
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
              (_) async => jsonResponse(noteJson(id: 99), 201))(request);
        }
        if (updatePath(request)) {
          return (onUpdate ??
              (_) async => jsonResponse(noteJson(), 200))(request);
        }
        if (deletePath(request)) {
          return (onDelete ?? (_) async => http.Response('', 204))(request);
        }
        if (pinPath(request)) {
          return (onPin ??
              (_) async => jsonResponse(noteJson(pinned: true), 200))(request);
        }
        if (unpinPath(request)) {
          return (onUnpin ??
              (_) async => jsonResponse(noteJson(pinned: false), 200))(request);
        }
        if (listPath(request)) {
          return (onList ??
              (_) async => jsonResponse([noteJson()], 200))(request);
        }
        return jsonResponse(const <String, dynamic>{}, 200);
      }));

  RealTripNotePayload payload() => const RealTripNotePayload(
        noteType: TripNoteType.journal,
        content: 'A journal entry',
        title: 'Title',
        mood: TripMood.happy,
      );

  // ── Contract parsing ───────────────────────────────────────────────────────

  group('Contract parsing', () {
    test('list parses; correct path', () async {
      http.Request? seen;
      final app = routedApp(onRequest: (r) {
        if (listPath(r)) seen = r;
      });
      expect(await app.loadRealNotes(7), NoteOutcome.success);
      expect(seen!.url.path.endsWith('/me/trips/7/notes'), isTrue);
      final n = app.realNotesFor(7).single;
      expect(n.id, 1);
      expect(n.typeView, TripNoteType.journal);
      expect(n.moodView, TripMood.happy);
      expect(n.title, 'Day one');
      expect(n.content, 'Landed safely, great weather.');
      expect(n.pinned, isTrue);
      expect(n.authorUserName, 'Bao');
    });

    test('type + mood mappers, unknown → null', () {
      expect(tripNoteTypeFromCode('REMINDER'), TripNoteType.reminder);
      expect(tripNoteTypeFromCode('NOPE'), isNull);
      expect(tripMoodFromCode('STRESSED'), TripMood.stressed);
      expect(tripMoodFromCode(null), isNull);
      expect(TripNoteType.journal.code, 'JOURNAL');
      expect(TripMood.happy.code, 'HAPPY');
    });

    test('payload toJson emits wire codes + content', () {
      final json = payload().toJson();
      expect(json['noteType'], 'JOURNAL');
      expect(json['mood'], 'HAPPY');
      expect(json['content'], 'A journal entry');
      expect(json['title'], 'Title');
      expect(json.containsKey('tripDayId'), isTrue);
    });

    test('null mood tolerated in payload + response', () async {
      const payloadNoMood = RealTripNotePayload(
        noteType: TripNoteType.note,
        content: 'x',
      );
      expect(payloadNoMood.toJson()['mood'], isNull);
      final app = routedApp(
        onList: (_) async => jsonResponse([noteJson(mood: null)], 200),
      );
      await app.loadRealNotes(7);
      expect(app.realNotesFor(7).single.moodView, isNull);
    });

    test('non-list body → serverError (malformed)', () async {
      final app = realApp(MockClient((_) async => http.Response('{}', 200)));
      expect(await app.loadRealNotes(7), NoteOutcome.serverError);
    });
  });

  // ── Demo Mode (zero HTTP) ────────────────────────────────────────────────────

  group('Demo Mode', () {
    test('all methods return demoUnavailable with zero HTTP', () async {
      var calls = 0;
      final app = demoApp(MockClient((_) async {
        calls++;
        return jsonResponse([noteJson()], 200);
      }));
      expect(await app.loadRealNotes(7), NoteOutcome.demoUnavailable);
      expect(
          await app.createRealNote(7, payload()), NoteOutcome.demoUnavailable);
      expect(await app.updateRealNote(7, 1, payload()),
          NoteOutcome.demoUnavailable);
      expect(await app.deleteRealNote(7, 1), NoteOutcome.demoUnavailable);
      expect(
          await app.setRealNotePinned(7, 1, true), NoteOutcome.demoUnavailable);
      expect(calls, 0);
      expect(app.realNotesFor(7), isEmpty);
    });
  });

  // ── CRUD + pin ────────────────────────────────────────────────────────────────

  group('CRUD', () {
    test('cached list not re-fetched unless refreshed', () async {
      var gets = 0;
      final app = routedApp(onRequest: (r) {
        if (listPath(r)) gets++;
      });
      await app.loadRealNotes(7);
      await app.loadRealNotes(7);
      expect(gets, 1);
      await app.loadRealNotes(7, refresh: true);
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
          return jsonResponse(noteJson(id: 99), 201);
        },
      );
      await app.loadRealNotes(7);
      expect(listGets, 1);
      expect(await app.createRealNote(7, payload()), NoteOutcome.success);
      expect(body!['noteType'], 'JOURNAL');
      expect(body!['content'], 'A journal entry');
      expect(listGets, 2);
    });

    test('blank content → validation, no HTTP', () async {
      var calls = 0;
      final app = routedApp(onRequest: (_) => calls++);
      const blank = RealTripNotePayload(
        noteType: TripNoteType.note,
        content: '   ',
      );
      expect(await app.createRealNote(7, blank), NoteOutcome.validation);
      expect(await app.updateRealNote(7, 1, blank), NoteOutcome.validation);
      expect(calls, 0);
    });

    test('update PUTs to the note id and reloads', () async {
      http.Request? seen;
      final app = routedApp(onRequest: (r) {
        if (updatePath(r)) seen = r;
      });
      await app.loadRealNotes(7);
      expect(await app.updateRealNote(7, 1, payload()), NoteOutcome.success);
      expect(seen!.url.path.endsWith('/me/trips/notes/1'), isTrue);
    });

    test('delete DELETEs and reloads', () async {
      http.Request? seen;
      var listGets = 0;
      final app = routedApp(onRequest: (r) {
        if (deletePath(r)) seen = r;
        if (listPath(r)) listGets++;
      });
      await app.loadRealNotes(7);
      expect(await app.deleteRealNote(7, 1), NoteOutcome.success);
      expect(seen!.url.path.endsWith('/me/trips/notes/1'), isTrue);
      expect(listGets, 2);
    });

    test('pin/unpin PATCH the right paths', () async {
      final seen = <String>[];
      final app = routedApp(onRequest: (r) {
        if (pinPath(r) || unpinPath(r)) seen.add(r.url.path);
      });
      await app.loadRealNotes(7);
      expect(await app.setRealNotePinned(7, 1, true), NoteOutcome.success);
      expect(await app.setRealNotePinned(7, 1, false), NoteOutcome.success);
      expect(seen[0].endsWith('/me/trips/notes/1/pin'), isTrue);
      expect(seen[1].endsWith('/me/trips/notes/1/unpin'), isTrue);
    });
  });

  // ── Errors ───────────────────────────────────────────────────────────────────

  group('Errors', () {
    test('401 → sessionExpired, no auto-logout / no demo switch', () async {
      final app = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(401, 'x', '/me/trips/7/notes'), 401),
      );
      app.email = 'bao@example.com';
      app.api.token = 'jwt-token';
      expect(await app.loadRealNotes(7), NoteOutcome.sessionExpired);
      expect(app.email, 'bao@example.com');
      expect(app.api.token, 'jwt-token');
      expect(app.demoMode, isFalse);
    });

    test('403 forbidden on create; 404 on update; 400 validation', () async {
      final f = routedApp(
        onCreate: (_) async =>
            jsonResponse(errorBody(403, 'x', '/me/trips/7/notes'), 403),
      );
      expect(await f.createRealNote(7, payload()), NoteOutcome.forbidden);

      final nf = routedApp(
        onUpdate: (_) async =>
            jsonResponse(errorBody(404, 'x', '/me/trips/notes/1'), 404),
      );
      expect(await nf.updateRealNote(7, 1, payload()), NoteOutcome.notFound);

      final inv = routedApp(
        onCreate: (_) async =>
            jsonResponse(errorBody(400, 'x', '/me/trips/7/notes'), 400),
      );
      expect(await inv.createRealNote(7, payload()), NoteOutcome.validation);
    });

    test('list 500 → serverError; network', () async {
      final se = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(500, 'x', '/me/trips/7/notes'), 500),
      );
      expect(await se.loadRealNotes(7), NoteOutcome.serverError);

      final net = realApp(MockClient((_) async {
        throw http.ClientException('offline');
      }));
      expect(await net.loadRealNotes(7), NoteOutcome.network);
    });

    test('a failed refresh preserves the previously loaded list', () async {
      var fail = false;
      final app = routedApp(
        onList: (_) async => fail
            ? jsonResponse(errorBody(500, 'x', '/me/trips/7/notes'), 500)
            : jsonResponse([noteJson()], 200),
      );
      await app.loadRealNotes(7);
      expect(app.realNotesFor(7), isNotEmpty);
      fail = true;
      expect(
          await app.loadRealNotes(7, refresh: true), NoteOutcome.serverError);
      expect(app.realNotesFor(7), isNotEmpty);
    });
  });

  // ── Session isolation ────────────────────────────────────────────────────────

  group('Session isolation', () {
    test('logout clears all note state', () async {
      final app = routedApp();
      await app.loadRealNotes(7);
      expect(app.realNotesFor(7), isNotEmpty);
      await app.logout();
      expect(app.realNotesFor(7), isEmpty);
      expect(app.realNotesTripId, isNull);
      expect(app.realNotesLoaded, isFalse);
    });
  });

  // ── Widgets ──────────────────────────────────────────────────────────────────

  group('Widgets', () {
    testWidgets('renders content + note cards', (t) async {
      final app = routedApp();
      await pumpSize(
        t,
        testApp(child: const RealTripNotesScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('notes-content')), findsOneWidget);
      expect(find.byKey(const Key('note-card-1')), findsOneWidget);
    });

    testWidgets('add opens the form; saving POSTs and closes', (t) async {
      var created = 0;
      final app = routedApp(onRequest: (r) {
        if (createPath(r)) created++;
      });
      await pumpSize(
        t,
        testApp(child: const RealTripNotesScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('notes-add')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('note-form-content')), findsOneWidget);
      await t.enterText(
          find.byKey(const Key('note-field-content')), 'My entry');
      await t.tap(find.byKey(const Key('note-form-save')));
      await t.pumpAndSettle();
      expect(created, 1);
      expect(find.byKey(const Key('note-form-content')), findsNothing);
    });

    testWidgets('create form blocks submit without content (no HTTP)',
        (t) async {
      var created = 0;
      final app = routedApp(onRequest: (r) {
        if (createPath(r)) created++;
      });
      await pumpSize(
        t,
        testApp(child: const RealTripNotesScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('notes-add')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('note-form-save')));
      await t.pumpAndSettle();
      expect(created, 0);
      expect(find.byKey(const Key('note-form-content')), findsOneWidget);
    });

    testWidgets('delete confirms then DELETEs', (t) async {
      var deleted = 0;
      final app = routedApp(onRequest: (r) {
        if (deletePath(r)) deleted++;
      });
      await pumpSize(
        t,
        testApp(child: const RealTripNotesScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('note-delete-1')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('note-delete-confirm')));
      await t.pumpAndSettle();
      expect(deleted, 1);
    });

    testWidgets('empty feed shows the empty state', (t) async {
      final app = routedApp(onList: (_) async => jsonResponse(const [], 200));
      await pumpSize(
        t,
        testApp(child: const RealTripNotesScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('notes-empty')), findsOneWidget);
    });

    testWidgets('a 401 shows the inline session-expired state', (t) async {
      final app = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(401, 'x', '/me/trips/7/notes'), 401),
      );
      await pumpSize(
        t,
        testApp(child: const RealTripNotesScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('notes-session-expired')), findsOneWidget);
    });
  });

  // ── Localization parity ──────────────────────────────────────────────────────

  group('Localization parity', () {
    test('every new UI44 key is present in both EN and VI', () {
      final en = AppLocalizationsEn();
      final vi = AppLocalizationsVi();
      final enValues = <String>[
        en.notesRealTitle,
        en.notesRealLoadingMessage,
        en.notesRealErrorMessage,
        en.notesRealForbiddenMessage,
        en.notesRealGoneMessage,
        en.notesRealNetworkMessage,
        en.notesRealActionErrorMessage,
        en.notesRealCreatedMessage,
        en.notesRealUpdatedMessage,
        en.notesRealDeletedMessage,
        en.notesRealPinnedMessage,
        en.notesRealUnpinnedMessage,
        en.notesRealContentRequiredMessage,
        en.notesRealAddSemantic,
        en.notesRealMoodNone,
        en.notesRealCreateTitle,
        en.notesRealEditTitle,
      ];
      final viValues = <String>[
        vi.notesRealTitle,
        vi.notesRealLoadingMessage,
        vi.notesRealErrorMessage,
        vi.notesRealForbiddenMessage,
        vi.notesRealGoneMessage,
        vi.notesRealNetworkMessage,
        vi.notesRealActionErrorMessage,
        vi.notesRealCreatedMessage,
        vi.notesRealUpdatedMessage,
        vi.notesRealDeletedMessage,
        vi.notesRealPinnedMessage,
        vi.notesRealUnpinnedMessage,
        vi.notesRealContentRequiredMessage,
        vi.notesRealAddSemantic,
        vi.notesRealMoodNone,
        vi.notesRealCreateTitle,
        vi.notesRealEditTitle,
      ];
      for (final v in enValues) {
        expect(v.trim(), isNotEmpty);
      }
      for (final v in viValues) {
        expect(v.trim(), isNotEmpty);
      }
      expect(en.notesRealCreatedMessage, isNot(vi.notesRealCreatedMessage));
    });

    test('reused demo note keys still resolve', () {
      final en = AppLocalizationsEn();
      expect(en.notesTitleLabel.trim(), isNotEmpty);
      expect(en.notesDeleteConfirmMessage('Day one'), contains('Day one'));
      expect(en.noteTypeJournal.trim(), isNotEmpty);
      expect(en.moodHappy.trim(), isNotEmpty);
    });
  });
}
