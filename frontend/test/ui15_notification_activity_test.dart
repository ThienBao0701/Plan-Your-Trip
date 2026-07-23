import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/mock/app_models.dart';
import 'package:planyourtrip_frontend/core/mock/mock_data.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/home/app_shell.dart';
import 'package:planyourtrip_frontend/features/profile/notifications_screen.dart';
import 'package:planyourtrip_frontend/features/profile/profile_screen.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:planyourtrip_frontend/shared/widgets/glass_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final fixedNow = DateTime(2026, 7, 22, 10);

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

  AppState demoState() => AppState(now: () => fixedNow)
    ..demoMode = true
    ..email = MockData.demoEmail;

  AppState realState() => AppState(now: () => fixedNow)
    ..demoMode = false
    ..email = 'real@example.com'
    ..trips = []
    ..timeline = []
    ..expenses = []
    ..demoBookings = []
    ..demoPaymentAttempts = []
    ..travelWalletItems = []
    ..tripDocuments = []
    ..tripCollaborators = []
    ..sharedTrips = []
    ..tripNotes = []
    ..packingItems = []
    ..tripReminders = []
    ..reviews = []
    ..userNotifications = []
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
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      harness(
        child: child,
        app: app,
        locale: locale,
        textScaleFactor: textScaleFactor,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openNotification(
    WidgetTester tester,
    String notificationId,
  ) async {
    final card = find.byKey(Key('notification-card-$notificationId'));
    final visibleCard = card.hitTestable();
    for (var i = 0; i < 8 && visibleCard.evaluate().isEmpty; i++) {
      await tester.drag(
        find.byKey(const Key('notification-center-screen')),
        const Offset(0, -360),
      );
      await tester.pumpAndSettle();
    }
    expect(visibleCard, findsOneWidget);
    await tester.tap(visibleCard);
    await tester.pumpAndSettle();
  }

  test('backend notification wire values stay aligned', () {
    expect(
      UserNotificationType.values.map((value) => value.code),
      [
        'BOOKING',
        'PAYMENT',
        'RESERVATION',
        'SYSTEM',
        'PROMOTION',
        'REVIEW',
        'PARTNER',
        'ADMIN',
        'MESSAGE',
        'TRIP',
      ],
    );
    expect(
      UserNotificationPriority.values.map((value) => value.code),
      ['LOW', 'NORMAL', 'HIGH', 'URGENT'],
    );
    expect(
      UserNotificationRelatedEntityType.values.map((value) => value.code),
      [
        'BOOKING',
        'PAYMENT',
        'HOTEL',
        'ROOM',
        'PROMOTION',
        'SYSTEM',
        'PARTNER',
        'MESSAGE',
        'TRIP',
      ],
    );
    expect(userNotificationTypeFromWire('unknown'), isNull);
    expect(userNotificationPriorityFromWire('urgent'),
        UserNotificationPriority.urgent);
  });

  testWidgets('Profile opens Notification Center and shows demo unread badge',
      (tester) async {
    final app = demoState();

    await pumpSize(
      tester,
      const ProfileScreen(),
      const Size(430, 932),
      app: app,
    );

    expect(find.text('4'), findsWidgets);
    await tester.tap(find.text('Notifications').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('notification-center-screen')), findsOneWidget);
    expect(find.text('Booking changes saved'), findsOneWidget);
    expect(find.text('4 unread'), findsOneWidget);
  });

  testWidgets('AppShell keeps exactly four tabs and remains nonblank',
      (tester) async {
    ignoreNetworkImageErrors();

    await pumpSize(
      tester,
      const AppShell(),
      const Size(430, 932),
      app: demoState(),
    );

    final nav = tester.widget<OceanBottomNavigationBar>(
      find.byType(OceanBottomNavigationBar),
    );
    expect(nav.destinations, hasLength(4));
    final tabOrder = {
      'Trips': 1,
      'Planner': 2,
      'Profile': 3,
      'Explore': 0,
    };
    for (final entry in tabOrder.entries) {
      await tester.tap(find.text(entry.key).last);
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('shell-tab-${entry.value}')), findsOneWidget);
      expect(find.byType(Offstage), findsWidgets);
    }
  });

  test('demo notifications sort newest first and expose derived unread count',
      () {
    final app = demoState();
    final ids = app.visibleNotifications.map((item) => item.id).toList();

    expect(ids.first, 'notif-demo-booking-modified');
    expect(ids.last, 'notif-demo-system-account');
    expect(app.unreadNotificationCount, 4);
    expect(app.visibleNotifications.where((item) => !item.read), hasLength(4));
  });

  testWidgets('Notification Center groups Today and Earlier deterministically',
      (tester) async {
    await pumpSize(
      tester,
      const NotificationsScreen(),
      const Size(430, 932),
      app: demoState(),
    );

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Earlier'), findsOneWidget);
    expect(find.text('Booking changes saved'), findsOneWidget);
    expect(find.text('Itinerary reminder delivered'), findsOneWidget);
  });

  testWidgets('Notification Center handles midnight grouping boundaries',
      (tester) async {
    final app = demoState()
      ..userNotifications = [
        UserNotification(
          id: 'notif-midnight-today',
          type: UserNotificationType.system,
          template: DemoNotificationTemplate.systemAccount,
          createdAt: DateTime(2026, 7, 22, 0, 1),
        ),
        UserNotification(
          id: 'notif-midnight-earlier',
          type: UserNotificationType.trip,
          template: DemoNotificationTemplate.itineraryReminder,
          createdAt: DateTime(2026, 7, 21, 23, 59),
        ),
      ];

    await pumpSize(
      tester,
      const NotificationsScreen(),
      const Size(430, 932),
      app: app,
    );

    expect(tester.getTopLeft(find.text('Today')).dy,
        lessThan(tester.getTopLeft(find.text('Account notice')).dy));
    expect(
        tester.getTopLeft(find.text('Earlier')).dy,
        lessThan(
            tester.getTopLeft(find.text('Itinerary reminder delivered')).dy));
  });

  testWidgets('All, Unread, and type filters derive from AppState',
      (tester) async {
    await pumpSize(
      tester,
      const NotificationsScreen(),
      const Size(1440, 900),
      app: demoState(),
    );

    expect(find.text('Property replied to your review'), findsOneWidget);
    final filters = find.byKey(const Key('notification-filter-rail'));
    await tester.tap(
      find.descendant(of: filters, matching: find.text('Unread')).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Demo payment needs attention'), findsOneWidget);
    expect(find.text('Property replied to your review'), findsNothing);

    await tester.tap(
      find.descendant(of: filters, matching: find.text('Payments')).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Demo payment completed'), findsOneWidget);
    expect(find.text('Demo payment needs attention'), findsOneWidget);
    expect(find.text('Booking changes saved'), findsNothing);

    await tester.tap(
      find.descendant(of: filters, matching: find.text('Bookings')).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Booking changes saved'), findsOneWidget);
    expect(find.text('Demo payment completed'), findsNothing);
  });

  test('mark-read and mark-all-read are idempotent demo mutations', () {
    final app = demoState();
    final result = app.markNotificationRead('notif-demo-booking-modified');
    final firstReadAt =
        app.notificationById('notif-demo-booking-modified')?.readAt;

    expect(result, NotificationActionResult.success);
    expect(firstReadAt, fixedNow.toUtc());
    expect(app.markNotificationRead('notif-demo-booking-modified'),
        NotificationActionResult.success);
    expect(
      app.notificationById('notif-demo-booking-modified')?.readAt,
      firstReadAt,
    );
    expect(
        app.markNotificationRead('missing'), NotificationActionResult.notFound);

    expect(app.markAllNotificationsRead(), 3);
    expect(app.markAllNotificationsRead(), 0);
    expect(app.unreadNotificationCount, 0);
  });

  test('real mode cannot simulate notification mutations', () {
    final app = realState()
      ..userNotifications = List<UserNotification>.from(
        MockData.demoNotifications,
      );

    expect(app.visibleNotifications, isEmpty);
    expect(
      app.markNotificationRead('notif-demo-booking-modified'),
      NotificationActionResult.unavailable,
    );
    expect(app.markAllNotificationsRead(), 0);
    expect(
      app.deleteNotification('notif-demo-booking-modified'),
      NotificationActionResult.unavailable,
    );
  });

  test('delete removes only the notification and updates unread count', () {
    final app = demoState();
    final bookingCount = app.demoBookings.length;
    final paymentAttemptCount = app.demoPaymentAttempts.length;
    final tripCount = app.trips.length;
    final reviewCount = app.reviews.length;
    final walletCount = app.travelWalletItems.length;

    expect(app.unreadNotificationCount, 4);
    expect(
      app.deleteNotification('notif-demo-booking-modified'),
      NotificationActionResult.success,
    );
    expect(app.notificationById('notif-demo-booking-modified'), isNull);
    expect(app.unreadNotificationCount, 3);
    expect(
      app.deleteNotification('notif-demo-booking-modified'),
      NotificationActionResult.notFound,
    );
    expect(app.demoBookings.length, bookingCount);
    expect(app.demoPaymentAttempts.length, paymentAttemptCount);
    expect(app.trips.length, tripCount);
    expect(app.reviews.length, reviewCount);
    expect(app.travelWalletItems.length, walletCount);
  });

  testWidgets('delete action requires confirmation before local removal',
      (tester) async {
    final app = demoState();

    await pumpSize(
      tester,
      const NotificationsScreen(),
      const Size(430, 932),
      app: app,
    );
    await openNotification(tester, 'notif-demo-booking-modified');
    await tester.tap(find.text('Delete notification'));
    await tester.pumpAndSettle();

    expect(find.text('Delete notification?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(app.notificationById('notif-demo-booking-modified'), isNotNull);

    await openNotification(tester, 'notif-demo-booking-modified');
    await tester.tap(find.text('Delete notification'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete notification'));
    await tester.pumpAndSettle();

    expect(app.notificationById('notif-demo-booking-modified'), isNull);
    expect(find.text('Notification deleted from local demo data.'),
        findsOneWidget);
  });

  testWidgets('real mode shows unavailable boundary without seeded data',
      (tester) async {
    await pumpSize(
      tester,
      const NotificationsScreen(),
      const Size(430, 932),
      app: realState(),
    );

    expect(find.text('No notifications'), findsOneWidget);
    expect(
      find.textContaining('Push delivery, device tokens'),
      findsOneWidget,
    );
    expect(find.text('Booking changes saved'), findsNothing);
  });

  test('logout and repeated demo resets restore deterministic notifications',
      () async {
    final app = demoState();
    final originalTripReminderCount = app.tripReminders.length;
    app.markAllNotificationsRead();
    app.deleteNotification('notif-demo-wallet-document');

    await app.logout();
    final afterFirst = app.userNotifications.map((item) => item.id).toList();
    await app.logout();
    final afterSecond = app.userNotifications.map((item) => item.id).toList();

    expect(afterFirst, afterSecond);
    expect(afterFirst, MockData.demoNotifications.map((item) => item.id));
    expect(app.unreadNotificationCount, 4);
    expect(app.tripReminders.length, originalTripReminderCount);
  });

  testWidgets('booking notification target opens Booking Detail',
      (tester) async {
    ignoreNetworkImageErrors();

    await pumpSize(
      tester,
      const NotificationsScreen(),
      const Size(430, 932),
      app: demoState(),
    );
    await openNotification(tester, 'notif-demo-booking-modified');
    await tester.tap(find.text('View booking'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('booking-detail-screen')), findsOneWidget);
  });

  testWidgets('payment notification target opens Payment Status',
      (tester) async {
    ignoreNetworkImageErrors();

    await pumpSize(
      tester,
      const NotificationsScreen(),
      const Size(430, 932),
      app: demoState(),
    );
    await openNotification(tester, 'notif-demo-payment-success');
    await tester.tap(find.text('View payment status'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('payment-status-screen')), findsOneWidget);
  });

  testWidgets('trip, review, reward, and wallet targets use typed routes',
      (tester) async {
    ignoreNetworkImageErrors();
    final app = demoState();

    await pumpSize(
      tester,
      const NotificationsScreen(),
      const Size(1440, 900),
      app: app,
    );
    await openNotification(tester, 'notif-demo-trip-collaboration');
    await tester.tap(find.text('View companions'));
    await tester.pumpAndSettle();
    expect(find.text('Trip Companion'), findsWidgets);

    await Navigator.of(tester.element(find.text('Trip Companion').first))
        .maybePop();
    await tester.pumpAndSettle();
    await openNotification(tester, 'notif-demo-review-reply');
    await tester.tap(find.text('View review'));
    await tester.pumpAndSettle();
    expect(find.text('Review detail'), findsOneWidget);

    await Navigator.of(tester.element(find.text('Review detail'))).maybePop();
    await tester.pumpAndSettle();
    await openNotification(tester, 'notif-demo-reward');
    await tester.tap(find.text('View rewards'));
    await tester.pumpAndSettle();
    expect(find.text('Rewards & Benefits'), findsWidgets);

    await Navigator.of(tester.element(find.text('Rewards & Benefits').first))
        .maybePop();
    await tester.pumpAndSettle();
    await openNotification(tester, 'notif-demo-wallet-document');
    await tester.tap(find.text('View travel wallet'));
    await tester.pumpAndSettle();
    expect(find.text('Travel Wallet'), findsWidgets);
  });

  testWidgets('missing target falls back without arbitrary named routes',
      (tester) async {
    final app = demoState()
      ..userNotifications = [
        UserNotification(
          id: 'notif-missing-target',
          type: UserNotificationType.booking,
          template: DemoNotificationTemplate.bookingModified,
          target: const NotificationTarget.booking('PYT-DEMO-MISSING'),
          createdAt: fixedNow,
        ),
      ];

    await pumpSize(
      tester,
      const NotificationsScreen(),
      const Size(430, 932),
      app: app,
    );
    await openNotification(tester, 'notif-missing-target');
    await tester.tap(find.text('View booking'));
    await tester.pumpAndSettle();

    expect(
      find.text('The linked item is no longer available in local demo data.'),
      findsOneWidget,
    );
    expect(app.notificationById('notif-missing-target')?.target.kind,
        NotificationTargetKind.booking);
  });

  testWidgets('privacy masking omits raw booking and payment references',
      (tester) async {
    await pumpSize(
      tester,
      const NotificationsScreen(),
      const Size(430, 932),
      app: demoState(),
    );

    expect(find.textContaining('PYT-DEMO'), findsNothing);
    expect(find.textContaining('PAY-DEMO'), findsNothing);
    await openNotification(tester, 'notif-demo-payment-success');
    expect(find.textContaining('PAY-DEMO'), findsNothing);
    expect(find.textContaining('PS-DEMO'), findsNothing);
  });

  testWidgets('local notification preference boundary remains visible',
      (tester) async {
    await pumpSize(
      tester,
      const NotificationsScreen(),
      const Size(430, 932),
      app: demoState(),
    );

    expect(
      find.textContaining('local device preferences only'),
      findsOneWidget,
    );
  });

  testWidgets('narrow, wide, and large-text layouts remain usable',
      (tester) async {
    for (final size in const [
      Size(430, 932),
      Size(1440, 900),
      Size(1920, 1080),
    ]) {
      await pumpSize(
        tester,
        const NotificationsScreen(),
        size,
        app: demoState(),
      );
      expect(
          find.byKey(const Key('notification-center-screen')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    await pumpSize(
      tester,
      const NotificationsScreen(),
      const Size(430, 932),
      app: demoState(),
      textScaleFactor: 1.6,
    );
    expect(find.text('Booking changes saved'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('notification semantics expose read state and unread count',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpSize(
        tester,
        const NotificationsScreen(),
        const Size(430, 932),
        app: demoState(),
      );

      expect(
        find.bySemanticsLabel(RegExp('unread notification')),
        findsWidgets,
      );
      expect(
        find.bySemanticsLabel(RegExp('Unread notification')),
        findsWidgets,
      );
      expect(find.bySemanticsLabel('Notification filters'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  test('English and Vietnamese notification localization parity holds', () {
    final en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
        as Map<String, dynamic>;
    final vi = jsonDecode(File('lib/l10n/app_vi.arb').readAsStringSync())
        as Map<String, dynamic>;
    final enKeys = en.keys.where((key) => !key.startsWith('@')).toSet();
    final viKeys = vi.keys.where((key) => !key.startsWith('@')).toSet();

    expect(enKeys.difference(viKeys), isEmpty);
    expect(viKeys.difference(enKeys), isEmpty);
    for (final key in enKeys) {
      final enMeta = en['@$key'];
      final viMeta = vi['@$key'];
      final enPlaceholders = enMeta is Map<String, dynamic>
          ? (enMeta['placeholders'] as Map<String, dynamic>?)?.keys.toSet() ??
              const <String>{}
          : const <String>{};
      final viPlaceholders = viMeta is Map<String, dynamic>
          ? (viMeta['placeholders'] as Map<String, dynamic>?)?.keys.toSet() ??
              const <String>{}
          : const <String>{};
      expect(viPlaceholders, enPlaceholders, reason: key);
    }
  });

  test('Trip reminders remain separate from delivered notifications', () {
    final app = demoState();
    final reminderIds = app.tripReminders.map((item) => item.id).toList();

    expect(
        app.userNotifications
            .any((item) => item.type == UserNotificationType.trip),
        isTrue);
    expect(app.tripReminders.length, isPositive);
    app.markAllNotificationsRead();
    expect(app.tripReminders.map((item) => item.id), reminderIds);
    expect(app.userNotifications.length, isNot(app.tripReminders.length));
  });
}
