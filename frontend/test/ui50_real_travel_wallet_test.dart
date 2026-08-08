import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/mock/app_models.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/wallet/real_travel_wallet_screen.dart';
import 'package:planyourtrip_frontend/features/wallet/travel_wallet_screen.dart';
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

  Map<String, dynamic> walletJson({
    int id = 5,
    String walletItemType = 'PASSPORT',
    String displayTitle = 'My passport',
    String? issuer = 'Vietnam',
    String? referenceNumberMasked = '****4321',
    String status = 'ACTIVE',
    String effectiveStatus = 'ACTIVE',
    bool favorite = false,
    bool archived = false,
    String? validFrom = '2028-01-01',
    String? validUntil = '2032-01-01',
    int? tripPlanId = 7,
    String? tripPlanTitle = 'Japan 2030',
  }) =>
      {
        'id': id,
        'tripPlanId': tripPlanId,
        'tripPlanTitle': tripPlanTitle,
        'walletItemType': walletItemType,
        'displayTitle': displayTitle,
        'issuer': issuer,
        'referenceNumberMasked': referenceNumberMasked,
        'validFrom': validFrom,
        'validUntil': validUntil,
        'status': status,
        'effectiveStatus': effectiveStatus,
        'expired': false,
        'favorite': favorite,
        'archived': archived,
        'expiryReminderEnabled': true,
        'organizerCategory': 'IDENTITY',
        'createdAt': '2027-01-01T08:00:00Z',
        'updatedAt': '2027-01-02T08:00:00Z',
      };

  bool listPath(http.Request r) =>
      r.method == 'GET' && r.url.path.endsWith('/me/travel-wallet');
  bool createPath(http.Request r) =>
      r.method == 'POST' && r.url.path.endsWith('/me/travel-wallet');
  bool updatePath(http.Request r) =>
      r.method == 'PUT' &&
      RegExp(r'/me/travel-wallet/\d+$').hasMatch(r.url.path);
  bool deletePath(http.Request r) =>
      r.method == 'DELETE' &&
      RegExp(r'/me/travel-wallet/\d+$').hasMatch(r.url.path);
  bool favoritePath(http.Request r) =>
      r.method == 'PATCH' && r.url.path.endsWith('/favorite');
  bool unfavoritePath(http.Request r) =>
      r.method == 'PATCH' && r.url.path.endsWith('/unfavorite');
  bool archivePath(http.Request r) =>
      r.method == 'PATCH' && r.url.path.endsWith('/archive');
  bool restorePath(http.Request r) =>
      r.method == 'PATCH' && r.url.path.endsWith('/restore');

  AppState routedApp({
    Future<http.Response> Function(http.Request)? onList,
    Future<http.Response> Function(http.Request)? onCreate,
    Future<http.Response> Function(http.Request)? onUpdate,
    Future<http.Response> Function(http.Request)? onDelete,
    void Function(http.Request)? onRequest,
  }) =>
      realApp(MockClient((request) async {
        onRequest?.call(request);
        if (createPath(request)) {
          return (onCreate ??
              (_) async => jsonResponse(walletJson(id: 99), 201))(request);
        }
        if (updatePath(request)) {
          return (onUpdate ??
              (_) async => jsonResponse(walletJson(), 200))(request);
        }
        if (deletePath(request)) {
          return (onDelete ?? (_) async => http.Response('', 204))(request);
        }
        if (favoritePath(request) ||
            unfavoritePath(request) ||
            archivePath(request) ||
            restorePath(request)) {
          return jsonResponse(walletJson(), 200);
        }
        if (listPath(request)) {
          return (onList ??
              (_) async => jsonResponse([walletJson()], 200))(request);
        }
        return jsonResponse(const <String, dynamic>{}, 200);
      }));

  RealWalletItemPayload payload() => RealWalletItemPayload(
        walletItemType: WalletItemType.visa,
        displayTitle: 'Schengen visa',
        issuer: 'France',
        referenceNumber: 'AB123456',
        validFrom: DateTime.utc(2030, 6, 1),
        validUntil: DateTime.utc(2030, 12, 31),
      );

  // ── Contract parsing ───────────────────────────────────────────────────────

  group('Contract parsing', () {
    test('bare list parses; correct path + fields', () async {
      http.Request? seen;
      final app = routedApp(onRequest: (r) {
        if (listPath(r)) seen = r;
      });
      expect(await app.loadRealWallet(), WalletOutcome.success);
      expect(seen!.url.path.endsWith('/me/travel-wallet'), isTrue);
      final w = app.realWalletItems.single;
      expect(w.id, 5);
      expect(w.displayTitle, 'My passport');
      expect(w.typeView, WalletItemType.passport);
      expect(w.effectiveStatusView, WalletItemStatus.active);
      expect(w.referenceNumberMasked, '****4321');
      expect(w.tripPlanTitle, 'Japan 2030');
      expect(w.validUntil, DateTime(2032, 1, 1));
    });

    test('nullable fields degrade to null', () {
      final w = RealWalletItem.fromJson(walletJson(
        issuer: null,
        referenceNumberMasked: null,
        validFrom: null,
        validUntil: null,
        tripPlanId: null,
        tripPlanTitle: null,
      ));
      expect(w.issuer, isNull);
      expect(w.referenceNumberMasked, isNull);
      expect(w.validFrom, isNull);
      expect(w.tripPlanId, isNull);
    });

    test('type/status mappers + wire codes; unknown → null', () {
      expect(
          walletItemTypeFromCode('HOTEL_VOUCHER'), WalletItemType.hotelVoucher);
      expect(walletItemTypeFromCode('NOPE'), isNull);
      expect(walletItemStatusFromCode('EXPIRED'), WalletItemStatus.expired);
      expect(walletItemStatusFromCode('NOPE'), isNull);
      expect(WalletItemType.passport.code, 'PASSPORT');
      expect(WalletItemStatus.upcoming.code, 'UPCOMING');
    });

    test('unknown enum on an item never crashes', () {
      final w = RealWalletItem.fromJson(
          walletJson(walletItemType: 'MYSTERY', effectiveStatus: 'WAT'));
      expect(w.typeView, isNull);
      expect(w.effectiveStatusView, isNull);
    });

    test('payload toJson emits code + LocalDate strings', () {
      final json = payload().toJson();
      expect(json['walletItemType'], 'VISA');
      expect(json['displayTitle'], 'Schengen visa');
      expect(json['issuer'], 'France');
      expect(json['referenceNumber'], 'AB123456');
      expect(json['validFrom'], '2030-06-01');
      expect(json['validUntil'], '2030-12-31');
    });

    test('non-list body → serverError (malformed)', () async {
      final app = realApp(MockClient((_) async => http.Response('{}', 200)));
      expect(await app.loadRealWallet(), WalletOutcome.serverError);
    });
  });

  // ── Demo Mode (zero HTTP) ────────────────────────────────────────────────────

  group('Demo Mode', () {
    test('all methods return demoUnavailable with zero HTTP', () async {
      var calls = 0;
      final app = demoApp(MockClient((_) async {
        calls++;
        return jsonResponse([walletJson()], 200);
      }));
      expect(await app.loadRealWallet(), WalletOutcome.demoUnavailable);
      expect(await app.createRealWalletItem(payload()),
          WalletOutcome.demoUnavailable);
      expect(await app.updateRealWalletItem(5, payload()),
          WalletOutcome.demoUnavailable);
      expect(await app.deleteRealWalletItem(5), WalletOutcome.demoUnavailable);
      expect(await app.setRealWalletItemFavorite(5, true),
          WalletOutcome.demoUnavailable);
      expect(await app.setRealWalletItemArchived(5, true),
          WalletOutcome.demoUnavailable);
      expect(calls, 0);
      expect(app.realWalletItems, isEmpty);
    });
  });

  // ── CRUD + toggles ────────────────────────────────────────────────────────────

  group('CRUD', () {
    test('cached list not re-fetched unless refreshed', () async {
      var gets = 0;
      final app = routedApp(onRequest: (r) {
        if (listPath(r)) gets++;
      });
      await app.loadRealWallet();
      await app.loadRealWallet();
      expect(gets, 1);
      await app.loadRealWallet(refresh: true);
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
          return jsonResponse(walletJson(id: 99), 201);
        },
      );
      await app.loadRealWallet();
      expect(listGets, 1);
      expect(await app.createRealWalletItem(payload()), WalletOutcome.success);
      expect(body!['walletItemType'], 'VISA');
      expect(body!['displayTitle'], 'Schengen visa');
      expect(listGets, 2);
    });

    test('blank title → validation, no HTTP', () async {
      var calls = 0;
      final app = routedApp(onRequest: (_) => calls++);
      const blank = RealWalletItemPayload(
        walletItemType: WalletItemType.other,
        displayTitle: '   ',
      );
      expect(await app.createRealWalletItem(blank), WalletOutcome.validation);
      expect(
          await app.updateRealWalletItem(5, blank), WalletOutcome.validation);
      expect(calls, 0);
    });

    test('update PUTs to the item id and reloads', () async {
      http.Request? seen;
      final app = routedApp(onRequest: (r) {
        if (updatePath(r)) seen = r;
      });
      await app.loadRealWallet();
      expect(
          await app.updateRealWalletItem(5, payload()), WalletOutcome.success);
      expect(seen!.url.path.endsWith('/me/travel-wallet/5'), isTrue);
    });

    test('delete DELETEs and reloads', () async {
      http.Request? seen;
      var listGets = 0;
      final app = routedApp(onRequest: (r) {
        if (deletePath(r)) seen = r;
        if (listPath(r)) listGets++;
      });
      await app.loadRealWallet();
      expect(await app.deleteRealWalletItem(5), WalletOutcome.success);
      expect(seen!.url.path.endsWith('/me/travel-wallet/5'), isTrue);
      expect(listGets, 2);
    });

    test('favorite/unfavorite PATCH the right paths', () async {
      final seen = <String>[];
      final app = routedApp(onRequest: (r) {
        if (favoritePath(r) || unfavoritePath(r)) seen.add(r.url.path);
      });
      await app.loadRealWallet();
      expect(
          await app.setRealWalletItemFavorite(5, true), WalletOutcome.success);
      expect(
          await app.setRealWalletItemFavorite(5, false), WalletOutcome.success);
      expect(seen[0].endsWith('/me/travel-wallet/5/favorite'), isTrue);
      expect(seen[1].endsWith('/me/travel-wallet/5/unfavorite'), isTrue);
    });

    test('archive/restore PATCH the right paths', () async {
      final seen = <String>[];
      final app = routedApp(onRequest: (r) {
        if (archivePath(r) || restorePath(r)) seen.add(r.url.path);
      });
      await app.loadRealWallet();
      expect(
          await app.setRealWalletItemArchived(5, true), WalletOutcome.success);
      expect(
          await app.setRealWalletItemArchived(5, false), WalletOutcome.success);
      expect(seen[0].endsWith('/me/travel-wallet/5/archive'), isTrue);
      expect(seen[1].endsWith('/me/travel-wallet/5/restore'), isTrue);
    });
  });

  // ── Errors ───────────────────────────────────────────────────────────────────

  group('Errors', () {
    test('401 → sessionExpired, no auto-logout / no demo switch', () async {
      final app = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(401, 'x', '/me/travel-wallet'), 401),
      );
      app.email = 'bao@example.com';
      app.api.token = 'jwt-token';
      expect(await app.loadRealWallet(), WalletOutcome.sessionExpired);
      expect(app.email, 'bao@example.com');
      expect(app.api.token, 'jwt-token');
      expect(app.demoMode, isFalse);
    });

    test('404 notFound on update; 400 validation on create', () async {
      final nf = routedApp(
        onUpdate: (_) async =>
            jsonResponse(errorBody(404, 'x', '/me/travel-wallet/5'), 404),
      );
      expect(
          await nf.updateRealWalletItem(5, payload()), WalletOutcome.notFound);

      final inv = routedApp(
        onCreate: (_) async =>
            jsonResponse(errorBody(400, 'x', '/me/travel-wallet'), 400),
      );
      expect(
          await inv.createRealWalletItem(payload()), WalletOutcome.validation);
    });

    test('list 500 → serverError; network', () async {
      final se = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(500, 'x', '/me/travel-wallet'), 500),
      );
      expect(await se.loadRealWallet(), WalletOutcome.serverError);

      final net = realApp(MockClient((_) async {
        throw http.ClientException('offline');
      }));
      expect(await net.loadRealWallet(), WalletOutcome.network);
    });

    test('a failed refresh preserves the previously loaded list', () async {
      var fail = false;
      final app = routedApp(
        onList: (_) async => fail
            ? jsonResponse(errorBody(500, 'x', '/me/travel-wallet'), 500)
            : jsonResponse([walletJson()], 200),
      );
      await app.loadRealWallet();
      expect(app.realWalletItems, isNotEmpty);
      fail = true;
      expect(
          await app.loadRealWallet(refresh: true), WalletOutcome.serverError);
      expect(app.realWalletItems, isNotEmpty);
    });
  });

  // ── Session isolation ────────────────────────────────────────────────────────

  group('Session isolation', () {
    test('logout clears all wallet state', () async {
      final app = routedApp();
      await app.loadRealWallet();
      expect(app.realWalletItems, isNotEmpty);
      await app.logout();
      expect(app.realWalletItems, isEmpty);
      expect(app.realWalletLoaded, isFalse);
    });
  });

  // ── Widgets ──────────────────────────────────────────────────────────────────

  group('Widgets', () {
    testWidgets('demo TravelWalletScreen delegates to real in real mode',
        (t) async {
      final app = routedApp();
      await pumpSize(
        t,
        testApp(child: const TravelWalletScreen(), app: app),
        const Size(1200, 2400),
      );
      expect(find.byType(RealTravelWalletScreen), findsOneWidget);
    });

    testWidgets('renders content + wallet card', (t) async {
      final app = routedApp();
      await pumpSize(
        t,
        testApp(child: const RealTravelWalletScreen(), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('wallet-content')), findsOneWidget);
      expect(find.byKey(const Key('wallet-card-5')), findsOneWidget);
    });

    testWidgets('favorite button PATCHes favorite', (t) async {
      var fav = 0;
      final app = routedApp(onRequest: (r) {
        if (favoritePath(r)) fav++;
      });
      await pumpSize(
        t,
        testApp(child: const RealTravelWalletScreen(), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('wallet-favorite-5')));
      await t.pumpAndSettle();
      expect(fav, 1);
    });

    testWidgets('archive button PATCHes archive', (t) async {
      var arch = 0;
      final app = routedApp(onRequest: (r) {
        if (archivePath(r)) arch++;
      });
      await pumpSize(
        t,
        testApp(child: const RealTravelWalletScreen(), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('wallet-archive-5')));
      await t.pumpAndSettle();
      expect(arch, 1);
    });

    testWidgets('add opens the form; saving POSTs and closes', (t) async {
      var created = 0;
      final app = routedApp(onRequest: (r) {
        if (createPath(r)) created++;
      });
      await pumpSize(
        t,
        testApp(child: const RealTravelWalletScreen(), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('wallet-add')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('wallet-form-content')), findsOneWidget);
      await t.enterText(
          find.byKey(const Key('wallet-field-title')), 'Travel insurance');
      await t.tap(find.byKey(const Key('wallet-form-save')));
      await t.pumpAndSettle();
      expect(created, 1);
      expect(find.byKey(const Key('wallet-form-content')), findsNothing);
    });

    testWidgets('form blocks submit without a title (no HTTP)', (t) async {
      var created = 0;
      final app = routedApp(onRequest: (r) {
        if (createPath(r)) created++;
      });
      await pumpSize(
        t,
        testApp(child: const RealTravelWalletScreen(), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('wallet-add')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('wallet-form-save')));
      await t.pumpAndSettle();
      expect(created, 0);
      expect(find.byKey(const Key('wallet-form-content')), findsOneWidget);
    });

    testWidgets('delete confirms then DELETEs', (t) async {
      var deleted = 0;
      final app = routedApp(onRequest: (r) {
        if (deletePath(r)) deleted++;
      });
      await pumpSize(
        t,
        testApp(child: const RealTravelWalletScreen(), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('wallet-delete-5')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('wallet-delete-confirm')));
      await t.pumpAndSettle();
      expect(deleted, 1);
    });

    testWidgets('empty feed shows the empty state', (t) async {
      final app = routedApp(onList: (_) async => jsonResponse(const [], 200));
      await pumpSize(
        t,
        testApp(child: const RealTravelWalletScreen(), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('wallet-empty')), findsOneWidget);
    });

    testWidgets('a 401 shows the inline session-expired state', (t) async {
      final app = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(401, 'x', '/me/travel-wallet'), 401),
      );
      await pumpSize(
        t,
        testApp(child: const RealTravelWalletScreen(), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('wallet-session-expired')), findsOneWidget);
    });
  });

  // ── Localization parity ──────────────────────────────────────────────────────

  group('Localization parity', () {
    test('every new UI50 key is present in both EN and VI', () {
      final en = AppLocalizationsEn();
      final vi = AppLocalizationsVi();
      final enValues = <String>[
        en.walletRealLoadingMessage,
        en.walletRealErrorMessage,
        en.walletRealForbiddenMessage,
        en.walletRealGoneMessage,
        en.walletRealNetworkMessage,
        en.walletRealActionErrorMessage,
        en.walletRealCreatedMessage,
        en.walletRealUpdatedMessage,
        en.walletRealDeletedMessage,
        en.walletRealFavoritedMessage,
        en.walletRealUnfavoritedMessage,
        en.walletRealArchivedMessage,
        en.walletRealRestoredMessage,
        en.walletRealTitleRequiredMessage,
        en.walletRealAddSemantic,
        en.walletRealCreateTitle,
        en.walletRealEditTitle,
        en.walletRealUntitled,
        en.walletRealListEmptyTitle,
        en.walletRealListEmptyMessage,
        en.walletRealTitleField,
        en.walletRealReferenceField,
        en.walletRealReferenceNote,
        en.walletRealValidFromField,
        en.walletRealValidUntilField,
        en.walletRealDateNone,
        en.walletRealSaveAction,
        en.walletRealArchiveAction,
        en.walletRealRestoreAction,
        en.walletRealDeleteAction,
      ];
      final viValues = <String>[
        vi.walletRealLoadingMessage,
        vi.walletRealErrorMessage,
        vi.walletRealForbiddenMessage,
        vi.walletRealGoneMessage,
        vi.walletRealNetworkMessage,
        vi.walletRealActionErrorMessage,
        vi.walletRealCreatedMessage,
        vi.walletRealUpdatedMessage,
        vi.walletRealDeletedMessage,
        vi.walletRealFavoritedMessage,
        vi.walletRealUnfavoritedMessage,
        vi.walletRealArchivedMessage,
        vi.walletRealRestoredMessage,
        vi.walletRealTitleRequiredMessage,
        vi.walletRealAddSemantic,
        vi.walletRealCreateTitle,
        vi.walletRealEditTitle,
        vi.walletRealUntitled,
        vi.walletRealListEmptyTitle,
        vi.walletRealListEmptyMessage,
        vi.walletRealTitleField,
        vi.walletRealReferenceField,
        vi.walletRealReferenceNote,
        vi.walletRealValidFromField,
        vi.walletRealValidUntilField,
        vi.walletRealDateNone,
        vi.walletRealSaveAction,
        vi.walletRealArchiveAction,
        vi.walletRealRestoreAction,
        vi.walletRealDeleteAction,
      ];
      for (final v in enValues) {
        expect(v.trim(), isNotEmpty);
      }
      for (final v in viValues) {
        expect(v.trim(), isNotEmpty);
      }
      expect(en.walletRealListEmptyTitle, isNot(vi.walletRealListEmptyTitle));
    });

    test('parameterized + reused demo keys resolve', () {
      final en = AppLocalizationsEn();
      expect(
          en.walletRealDeleteConfirmMessage('Passport'), contains('Passport'));
      expect(en.walletRealFavoriteSemantic('Visa'), contains('Visa'));
      expect(en.walletRealReferenceHint('****1'), contains('****1'));
      expect(en.travelWalletTitle.trim(), isNotEmpty);
      expect(en.walletTypePassport.trim(), isNotEmpty);
      expect(en.walletStatusActive.trim(), isNotEmpty);
    });
  });
}
