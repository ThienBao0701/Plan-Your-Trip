import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/mock/app_models.dart';
import 'package:planyourtrip_frontend/core/mock/mock_data.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/home/app_shell.dart';
import 'package:planyourtrip_frontend/features/trips/trip_companion_screen.dart';
import 'package:planyourtrip_frontend/features/trips/trip_detail_screen.dart';
import 'package:planyourtrip_frontend/features/trips/trips_screen.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final fixedNow = DateTime(2026, 7, 16, 10);

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

  AppState demoState({String? email}) => AppState(now: () => fixedNow)
    ..demoMode = true
    ..email = email ?? MockData.demoEmail;

  AppState realState() => AppState(now: () => fixedNow)
    ..demoMode = false
    ..email = 'real@example.com'
    ..trips = []
    ..timeline = []
    ..expenses = []
    ..demoBookings = []
    ..travelWalletItems = []
    ..tripDocuments = []
    ..tripCollaborators = []
    ..sharedTrips = []
    ..tripNotes = []
    ..packingItems = []
    ..tripReminders = []
    ..publicTripIds = {};

  Widget harness({
    required Widget child,
    AppState? app,
    Locale? locale,
    double textScaleFactor = 1,
  }) {
    return AppScope(
      notifier: app ?? demoState(),
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
    Widget child,
    Size size, {
    AppState? app,
    Locale? locale,
    double textScaleFactor = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(harness(
      child: child,
      app: app,
      locale: locale,
      textScaleFactor: textScaleFactor,
    ));
    await tester.pumpAndSettle();
  }

  test('UI-9 stable wire values and permissions are backend-aligned', () {
    expect(TripCollaboratorRole.values.map((role) => role.code), [
      'VIEWER',
      'EDITOR',
    ]);
    expect(TripNoteType.values.map((type) => type.code), [
      'NOTE',
      'JOURNAL',
      'REMINDER',
      'IDEA',
      'MEMORY',
    ]);
    expect(TripMood.values.map((mood) => mood.code), [
      'HAPPY',
      'EXCITED',
      'CALM',
      'TIRED',
      'STRESSED',
      'NEUTRAL',
    ]);
    expect(PackingCategory.values.map((category) => category.code), [
      'DOCUMENTS',
      'CLOTHES',
      'TOILETRIES',
      'ELECTRONICS',
      'MEDICINE',
      'MONEY',
      'FOOD',
      'BABY',
      'PET',
      'OTHER',
    ]);
    expect(TripReminderType.values.map((type) => type.code), [
      'CUSTOM',
      'DOCUMENT',
      'CHECK_IN',
      'FLIGHT',
      'ACTIVITY',
      'PAYMENT',
      'PACKING',
      'OTHER',
    ]);
    expect(TripReminderStatus.values.map((status) => status.code), [
      'PENDING',
      'COMPLETED',
      'CANCELLED',
    ]);

    final owner = demoState();
    final editor = demoState(email: 'editor@planyourtrip.com');
    final viewer = demoState(email: 'viewer@planyourtrip.com');
    final stranger = demoState(email: 'stranger@example.com');

    expect(owner.tripAccessLevel(1), TripPermission.owner);
    expect(editor.tripAccessLevel(1), TripPermission.editor);
    expect(viewer.tripAccessLevel(1), TripPermission.viewer);
    expect(stranger.tripAccessLevel(1), TripPermission.noAccess);
    expect(viewer.addTripNote(_noteFixture('viewer-blocked')),
        TripToolActionResult.forbidden);
  });

  test('collaboration validates demo invitations and owner-only management',
      () {
    final app = demoState();

    expect(app.inviteTripCollaborator(1, ''), TripToolActionResult.blank);
    expect(app.inviteTripCollaborator(1, 'bad-email'),
        TripToolActionResult.invalidEmail);
    expect(app.inviteTripCollaborator(1, MockData.demoEmail),
        TripToolActionResult.rejected);
    expect(app.inviteTripCollaborator(1, 'unknown@example.com'),
        TripToolActionResult.rejected);
    expect(app.inviteTripCollaborator(1, 'EDITOR@PLANYOURTRIP.COM'),
        TripToolActionResult.duplicate);
    expect(
      app.inviteTripCollaborator(
        1,
        'friend@planyourtrip.com',
        role: TripCollaboratorRole.editor,
      ),
      TripToolActionResult.duplicate,
    );

    final inactive = app.tripCollaborators
        .firstWhere((item) => item.id == 'collab-inactive-da-lat');
    expect(
        app.removeCollaborator(1, inactive.id), TripToolActionResult.success);
    expect(
      app.inviteTripCollaborator(
        1,
        'friend@planyourtrip.com',
        role: TripCollaboratorRole.editor,
      ),
      TripToolActionResult.success,
    );
    final collaborator = app.tripCollaborators
        .firstWhere((item) => item.userEmail == 'friend@planyourtrip.com');
    expect(collaborator.role, TripCollaboratorRole.editor);
    expect(
      app.updateCollaboratorRole(
        1,
        collaborator.id,
        TripCollaboratorRole.viewer,
      ),
      TripToolActionResult.success,
    );
    expect(app.setTripPublic(1, false), TripToolActionResult.success);
    expect(app.isTripPublic(1), isFalse);

    final editor = demoState(email: 'editor@planyourtrip.com');
    expect(editor.setTripPublic(1, false), TripToolActionResult.forbidden);
    expect(editor.removeCollaborator(1, 'collab-viewer-da-lat'),
        TripToolActionResult.forbidden);
  });

  test('notes and journal enforce content, URL, author, and ordering rules',
      () {
    final app = demoState();
    final beforeReminders = app.tripReminders.length;

    expect(app.addTripNote(_noteFixture('blank', content: '   ')),
        TripToolActionResult.blank);
    expect(
      app.addTripNote(_noteFixture(
        'unsafe-photo',
        photoUrl: 'file:///private/image.jpg',
      )),
      TripToolActionResult.unsafeUrl,
    );
    expect(
      app.addTripNote(_noteFixture(
        'reminder-note',
        type: TripNoteType.reminder,
      )),
      TripToolActionResult.success,
    );
    expect(app.tripReminders.length, beforeReminders);
    final added =
        app.tripNotes.firstWhere((note) => note.id == 'reminder-note');
    expect(added.authorUserName, 'Demo Traveler');

    final editor = demoState(email: 'editor@planyourtrip.com');
    final original =
        editor.tripNotes.firstWhere((note) => note.id == 'note-pinned-da-lat');
    expect(
      editor.updateTripNote(original.copyWith(content: 'Editor update')),
      TripToolActionResult.success,
    );
    final updated =
        editor.tripNotes.firstWhere((note) => note.id == original.id);
    expect(updated.authorUserName, original.authorUserName);
    final foreign = editor.tripNotes.firstWhere(
      (note) => note.id == 'note-memory-vung-tau',
    );
    expect(
      editor.updateTripNote(foreign.copyWith(
        tripPlanId: 1,
        content: 'Cross-trip edit attempt',
      )),
      TripToolActionResult.forbidden,
    );
    expect(
      editor.tripNotes
          .firstWhere((note) => note.id == 'note-memory-vung-tau')
          .content,
      foreign.content,
    );
    expect(editor.notesForTrip(1).first.pinned, isTrue);
    expect(editor.setTripNotePinned(original.id, false),
        TripToolActionResult.success);
    expect(editor.deleteTripNote(original.id), TripToolActionResult.success);
  });

  test(
      'packing validates progress, assignment, reorder, and collaborator removal',
      () {
    final app = demoState();
    final progress = app.packingProgressForTrip(1);
    expect(progress.total, 3);
    expect(progress.checked, 1);
    expect(progress.unchecked, 2);
    expect(progress.percent, 33);
    expect(app.packingForTrip(1).last.checked, isTrue);

    expect(
      app.addPackingItem(_packingFixture('bad-quantity', quantity: 0)),
      TripToolActionResult.invalidQuantity,
    );
    expect(
      app.addPackingItem(
        _packingFixture('foreign-assignee', assignedToUserId: 'missing-user'),
      ),
      TripToolActionResult.rejected,
    );
    expect(
      app.addPackingItem(
        _packingFixture(
          'valid-assignee',
          assignedToUserId: 'demo-editor',
        ),
      ),
      TripToolActionResult.success,
    );
    expect(app.setPackingChecked('valid-assignee', true),
        TripToolActionResult.success);
    expect(
        app.packingItems.firstWhere((i) => i.id == 'valid-assignee').checkedAt,
        isNotNull);
    expect(app.setPackingChecked('valid-assignee', false),
        TripToolActionResult.success);
    expect(
        app.packingItems.firstWhere((i) => i.id == 'valid-assignee').checkedAt,
        isNull);

    final ids = app.packingForTrip(1).map((item) => item.id).toList();
    expect(app.reorderPackingItems(1, [...ids, ids.first]),
        TripToolActionResult.invalidReorder);
    expect(app.reorderPackingItems(1, ids.reversed.toList()),
        TripToolActionResult.success);
    expect(
      app.packingItems.firstWhere((i) => i.id == 'packing-jacket').checked,
      isTrue,
    );

    expect(app.removeCollaborator(1, 'collab-editor-da-lat'),
        TripToolActionResult.success);
    expect(
      app.packingItems.where((item) => item.assignedToUserId == 'demo-editor'),
      isEmpty,
    );
  });

  test('reminders sort, hide cancelled, compute overdue, and keep UTC state',
      () {
    final app = demoState();
    final visible = app.remindersForTrip(1);

    expect(visible.any((item) => item.status == TripReminderStatus.cancelled),
        isFalse);
    expect(app.remindersForTrip(1, includeCancelled: true), hasLength(4));
    expect(visible.first.id, 'reminder-overdue-pack');
    expect(visible.first.isOverdue(fixedNow), isTrue);
    expect(visible.first.status, TripReminderStatus.pending);

    expect(
      app.addTripReminder(_reminderFixture(
        'invalid-doc',
        documentId: 'doc-bus-vung-tau',
      )),
      TripToolActionResult.rejected,
    );
    expect(
      app.addTripReminder(_reminderFixture('valid-reminder')),
      TripToolActionResult.success,
    );
    final added =
        app.tripReminders.firstWhere((item) => item.id == 'valid-reminder');
    expect(added.reminderAt.isUtc, isTrue);
    expect(app.completeTripReminder('valid-reminder'),
        TripToolActionResult.success);
    expect(
      app.tripReminders
          .firstWhere((item) => item.id == 'valid-reminder')
          .status,
      TripReminderStatus.completed,
    );
    expect(app.completeTripReminder('valid-reminder'),
        TripToolActionResult.success);
    expect(app.cancelTripReminder('valid-reminder'),
        TripToolActionResult.rejected);
    expect(
      app.tripReminders
          .firstWhere((item) => item.id == 'valid-reminder')
          .status,
      TripReminderStatus.completed,
    );
    expect(app.cancelTripReminder('reminder-flight-check'),
        TripToolActionResult.success);
    expect(
      app.tripReminders
          .firstWhere((item) => item.id == 'reminder-flight-check')
          .status,
      TripReminderStatus.cancelled,
    );
    expect(
        app.deleteTripReminder('valid-reminder'), TripToolActionResult.success);
  });

  test('cascades unlink optional companion references safely', () {
    final app = demoState();

    expect(
      app.tripNotes.any((note) => note.tripItemId == 1),
      isTrue,
    );
    app.deleteTimeline(1);
    expect(app.tripNotes.any((note) => note.tripItemId == 1), isFalse);
    expect(
        app.tripReminders.any((reminder) => reminder.tripItemId == 1), isFalse);

    expect(
      app.tripReminders
          .any((reminder) => reminder.documentId == 'doc-flight-da-lat'),
      isTrue,
    );
    expect(app.deleteTripDocument('doc-flight-da-lat'),
        WalletActionResult.success);
    expect(
      app.tripReminders
          .any((reminder) => reminder.documentId == 'doc-flight-da-lat'),
      isFalse,
    );

    final shortened = app.trips.first.copyWith(
      endDate: app.trips.first.startDate,
    );
    app.updateTrip(shortened);
    expect(
        app.tripNotes.where((note) => note.tripPlanId == 1).every(
              (note) =>
                  note.tripDayId == null || note.tripDayId! <= shortened.days,
            ),
        isTrue);

    app.deleteTrip(1);
    expect(app.tripCollaborators.any((item) => item.tripPlanId == 1), isFalse);
    expect(app.tripNotes.any((item) => item.tripPlanId == 1), isFalse);
    expect(app.packingItems.any((item) => item.tripPlanId == 1), isFalse);
    expect(app.tripReminders.any((item) => item.tripPlanId == 1), isFalse);
    expect(app.tripDocuments.any((item) => item.tripId == 1), isFalse);
  });

  test('real mode remains empty and cannot mutate companion data', () {
    final app = realState();

    expect(app.visibleSharedTrips(), isEmpty);
    expect(app.companionCountsForTrip(1).notes, 0);
    expect(app.inviteTripCollaborator(1, 'friend@planyourtrip.com'),
        TripToolActionResult.unavailable);
    expect(app.addTripNote(_noteFixture('real-note')),
        TripToolActionResult.unavailable);
    expect(app.addPackingItem(_packingFixture('real-pack')),
        TripToolActionResult.unavailable);
    expect(app.addTripReminder(_reminderFixture('real-reminder')),
        TripToolActionResult.unavailable);
    expect(app.tripNotes, isEmpty);
    expect(app.packingItems, isEmpty);
    expect(app.tripReminders, isEmpty);
  });

  testWidgets('Trip Detail opens companion modules and shared trips entry',
      (tester) async {
    ignoreNetworkImageErrors();
    final app = demoState();
    final trip = app.trips.first;

    await pumpSize(
      tester,
      TripDetailScreen(trip: trip),
      const Size(900, 1400),
      app: app,
    );

    await tester.ensureVisible(find.byKey(const Key('trip-companion-action')));
    await tester.tap(find.byKey(const Key('trip-companion-action')));
    await tester.pumpAndSettle();

    final root = find.byKey(const Key('trip-companion-screen'));
    expect(root, findsOneWidget);
    expect(tester.getSize(root).height, greaterThan(0));
    expect(find.text('Trip Companion'), findsWidgets);
    expect(find.byKey(const Key('companion-collaboration')), findsOneWidget);
    expect(find.byKey(const Key('companion-notes')), findsOneWidget);
    expect(find.byKey(const Key('companion-packing')), findsOneWidget);
    expect(find.byKey(const Key('companion-reminders')), findsOneWidget);
    expect(find.byKey(const Key('companion-documents')), findsOneWidget);

    await tester.tap(find.byKey(const Key('companion-collaboration')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('trip-collaboration-screen')), findsOneWidget);
    expect(find.text('Minh Editor'), findsWidgets);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('companion-notes')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('trip-notes-screen')), findsOneWidget);
    expect(find.text('First morning plan'), findsWidgets);
    expect(find.text('Photo URL metadata'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await pumpSize(tester, const TripsScreen(), const Size(900, 1400),
        app: app);
    expect(find.byKey(const Key('shared-with-me-action')), findsOneWidget);
    await tester.tap(find.byKey(const Key('shared-with-me-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('shared-with-me-screen')), findsOneWidget);
    expect(find.text('Hoi An shared weekend'), findsWidgets);
    await tester.tap(find.byKey(const Key('shared-trip-9001')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('shared-trip-summary-screen')), findsOneWidget);
    expect(
      find.text(
        'This summary is local demo presentation only. Full shared-trip tools will open when the backend provides the complete trip record.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shared collaborator trips open read-only companion tools',
      (tester) async {
    final app = demoState(email: 'viewer@planyourtrip.com');

    await pumpSize(
      tester,
      const SharedWithMeScreen(),
      const Size(900, 1400),
      app: app,
    );

    expect(find.byKey(const Key('shared-with-me-screen')), findsOneWidget);
    expect(find.byKey(const Key('shared-trip-1')), findsOneWidget);
    expect(find.text('Hoi An shared weekend'), findsNothing);

    await tester.tap(find.byKey(const Key('shared-trip-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('trip-companion-screen')), findsOneWidget);
    expect(find.text('Access: Viewer'), findsOneWidget);

    await tester.tap(find.byKey(const Key('companion-notes')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('trip-notes-screen')), findsOneWidget);
    expect(find.text('This trip is read-only for your current local role.'),
        findsOneWidget);
  });

  testWidgets('packing and reminders render on wide and large-text layouts',
      (tester) async {
    final app = demoState();
    final trip = app.trips.first;

    await pumpSize(
      tester,
      TripPackingScreen(trip: trip),
      const Size(1920, 1080),
      app: app,
      textScaleFactor: 1.4,
    );
    expect(find.byKey(const Key('trip-packing-screen')), findsOneWidget);
    expect(find.text('1 of 3 packed (33%)'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await pumpSize(
      tester,
      TripRemindersScreen(trip: trip),
      const Size(1440, 900),
      app: app,
      textScaleFactor: 1.3,
    );
    expect(find.byKey(const Key('trip-reminders-screen')), findsOneWidget);
    expect(find.text('Overdue'), findsWidgets);
    expect(find.text('Old transfer reminder'), findsNothing);
    await tester.tap(find.byKey(const Key('reminders-include-cancelled')));
    await tester.pumpAndSettle();
    expect(find.text('Old transfer reminder'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'real and Vietnamese companion states render without blank content',
      (tester) async {
    final real = realState();
    final placeholderTrip = Trip(
      id: 99,
      title: 'Real placeholder',
      destination: 'Da Nang',
      imageUrl: '',
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 8, 3),
      travelers: 1,
      budget: 0,
    );

    await pumpSize(
      tester,
      TripCompanionScreen(trip: placeholderTrip),
      const Size(430, 932),
      app: real..trips = [placeholderTrip],
    );
    expect(find.text('Trip companion is not connected yet'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await pumpSize(
      tester,
      TripCompanionScreen(trip: MockData.trips.first),
      const Size(430, 932),
      locale: const Locale('vi'),
      textScaleFactor: 1.35,
    );
    expect(find.text('Đồng hành chuyến đi'), findsWidgets);
    expect(find.text('Cộng tác'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AppShell keeps four tabs and repeated switching shows content',
      (tester) async {
    ignoreNetworkImageErrors();
    final semantics = tester.ensureSemantics();
    await pumpSize(
      tester,
      const AppShell(),
      const Size(1920, 1080),
      app: demoState(),
    );
    try {
      expect(find.bySemanticsLabel('Explore tab'), findsOneWidget);
      expect(find.bySemanticsLabel('Trips tab'), findsOneWidget);
      expect(find.bySemanticsLabel('Planner tab'), findsOneWidget);
      expect(find.bySemanticsLabel('Profile tab'), findsOneWidget);
      expect(find.bySemanticsLabel('Trip Companion tab'), findsNothing);
    } finally {
      semantics.dispose();
    }

    for (final label in ['Trips', 'Planner', 'Profile', 'Explore', 'Trips']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    final tripsRoot = find.byKey(const ValueKey('shell-tab-1'));
    expect(tripsRoot, findsOneWidget);
    expect(tester.getSize(tripsRoot).height, greaterThan(0));
    expect(find.text('My trips'), findsWidgets);
  });

  test('English and Vietnamese ARB files keep UI-9 key parity', () {
    final en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
        as Map<String, dynamic>;
    final vi = jsonDecode(File('lib/l10n/app_vi.arb').readAsStringSync())
        as Map<String, dynamic>;
    final enKeys = en.keys.where((key) => !key.startsWith('@')).toSet();
    final viKeys = vi.keys.where((key) => !key.startsWith('@')).toSet();

    expect(enKeys.difference(viKeys), isEmpty);
    expect(viKeys.difference(enKeys), isEmpty);
    expect(enKeys, contains('tripCompanionTitle'));
    expect(enKeys, contains('tripCompanionRemindersTitle'));
  });
}

TripNote _noteFixture(
  String id, {
  String content = 'Local note content',
  TripNoteType type = TripNoteType.note,
  String photoUrl = '',
}) {
  return TripNote(
    id: id,
    tripPlanId: 1,
    authorUserId: 'demo-owner',
    authorUserName: 'Demo Traveler',
    noteType: type,
    title: 'Local note',
    content: content,
    photoUrl: photoUrl,
    createdAt: DateTime(2026, 7, 16),
    updatedAt: DateTime(2026, 7, 16),
  );
}

PackingItem _packingFixture(
  String id, {
  int quantity = 1,
  String? assignedToUserId,
}) {
  return PackingItem(
    id: id,
    tripPlanId: 1,
    label: 'Local packing item',
    category: PackingCategory.documents,
    quantity: quantity,
    assignedToUserId: assignedToUserId,
    sortOrder: 10,
    createdAt: DateTime(2026, 7, 16),
    updatedAt: DateTime(2026, 7, 16),
  );
}

TripReminder _reminderFixture(String id, {String? documentId}) {
  return TripReminder(
    id: id,
    tripPlanId: 1,
    documentId: documentId,
    userId: 'demo-owner',
    userName: 'Demo Traveler',
    reminderType: TripReminderType.custom,
    title: 'Local reminder',
    reminderAt: DateTime(2026, 8, 1, 9),
    createdAt: DateTime(2026, 7, 16),
    updatedAt: DateTime(2026, 7, 16),
  );
}
