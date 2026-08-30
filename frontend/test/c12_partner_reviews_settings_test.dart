import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/core/app_role.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/core/partner/partner_account_models.dart';
import 'package:planyourtrip_frontend/core/partner/partner_models.dart';
import 'package:planyourtrip_frontend/core/partner/partner_state.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/partner/partner_navigation.dart';
import 'package:planyourtrip_frontend/features/partner/reviews/partner_reviews_screen.dart';
import 'package:planyourtrip_frontend/features/partner/reviews/partner_reviews_state.dart';
import 'package:planyourtrip_frontend/features/partner/settings/partner_account_state.dart';
import 'package:planyourtrip_frontend/features/partner/settings/partner_settings_screen.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_en.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_vi.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// C12 — Partner Reviews / Settings.
///
/// Encodes what the audit established:
///
///  * `PartnerReviewController` has **one** endpoint — the reply. There is no
///    partner review list, no detail and no moderation, so the list reuses the
///    public `GET /api/places/{placeId}/reviews`.
///  * **A partner cannot read a review's text**: `ReviewService.getReview` gates
///    on the review's *author*, so `GET /api/reviews/{id}` is a 403.
///  * A review has **one** reply, replaced in place, with **no delete endpoint**.
///    Only an `APPROVED` review may be replied to — anything else is 422.
///  * Team writes are **OWNER only**; payout writes are **OWNER or FINANCE**;
///    C6's settings writes remain OWNER/MANAGER and are untouched.
///  * The payout API never returns a full account number — only `last4`.
///  * An approved business profile **cannot be edited**, so no editor is shown.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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

  Map<String, dynamic> profileJson({String verificationStatus = 'APPROVED'}) =>
      {
        'id': 7,
        'userId': 42,
        'businessName': 'Bay View Resorts',
        'representativeName': 'Le Minh',
        'email': 'ops@bayview.example',
        'verificationStatus': verificationStatus,
      };

  Map<String, dynamic> extranetHomeJson() => {
        'profile': {
          'id': 7,
          'businessName': 'Bay View Resorts',
          'representativeName': 'Le Minh',
          'email': 'ops@bayview.example',
        },
        'verificationStatus': 'APPROVED',
        'ownedHotelCount': 1,
        'activeRoomCount': 2,
        'todaysArrivals': 0,
        'todaysDepartures': 0,
        'unreadMessages': 0,
        'unreadNotifications': 0,
        'pendingReviews': 1,
        'activePromotions': 0,
        'quickActions': <Object>[],
      };

  Map<String, dynamic> hotelJson({int id = 11}) => {
        'id': id,
        'name': 'Bay View Danang',
        'slug': 'bay-view-danang',
        'shortDescription': null,
        'address': '12 Vo Nguyen Giap',
        'active': true,
        'featured': false,
        'verified': true,
        'ratingAvg': 4.6,
        'reviewCount': 12,
        'status': 'PUBLISHED',
        'createdAt': '2026-07-30T02:00:00Z',
        'updatedAt': '2026-08-20T02:00:00Z',
      };

  /// `ReviewDto.ReviewSummaryResponse` — note there is **no `content`**: the
  /// public list never carries the review body.
  Map<String, dynamic> reviewJson({
    int id = 1,
    int rating = 5,
    String? title = 'Wonderful stay',
    String status = 'APPROVED',
    Map<String, dynamic>? partnerReply,
  }) =>
      {
        'id': id,
        'placeId': 11,
        'placeName': 'Bay View Danang',
        'userId': 1,
        'userName': 'Demo User',
        'ratingOverall': rating,
        'title': title,
        'status': status,
        'createdAt': '2026-08-30T01:12:27Z',
        'partnerReply': partnerReply,
        'media': <Object>[],
      };

  Map<String, dynamic> replyJson() => {
        'content': 'Thank you for staying with us.',
        'repliedAt': '2026-08-30T02:00:00Z',
        'updatedAt': '2026-08-30T02:00:00Z',
        'partnerDisplayName': 'Bay View Resorts',
      };

  Map<String, dynamic> memberJson({
    int id = 1,
    String role = 'OWNER',
    bool active = true,
    String email = 'partner@planyourtrip.com',
  }) =>
      {
        'id': id,
        'partnerProfileId': 7,
        'userId': 2,
        'userName': 'Partner User',
        'userEmail': email,
        'role': role,
        'active': active,
        'invitedAt': '2026-08-30T01:12:27Z',
        'joinedAt': '2026-08-30T01:12:27Z',
        'createdAt': '2026-08-30T01:12:27Z',
        'updatedAt': '2026-08-30T01:12:27Z',
      };

  /// `PartnerSettingsDto.PartnerPayoutAccountResponse` — only `last4` exists.
  Map<String, dynamic> payoutJson() => {
        'id': 1,
        'partnerProfileId': 7,
        'accountHolderName': 'Partner User',
        'bankName': 'Vietcombank',
        'bankAccountLast4': '6789',
        'payoutMethod': 'BANK_TRANSFER',
        'status': 'VERIFIED',
        'createdAt': '2026-08-30T01:12:27Z',
        'updatedAt': '2026-08-30T01:12:27Z',
      };

  late List<String> requestLog;
  late List<Map<String, dynamic>> writeBodies;
  setUp(() {
    requestLog = <String>[];
    writeBodies = <Map<String, dynamic>>[];
  });

  MockClient c12Client({
    Map<String, http.Response>? overrides,
    List<Map<String, dynamic>>? reviews,
    List<Map<String, dynamic>>? team,
    Map<String, dynamic>? payout,
    int? payoutStatus,
    int? replyStatus,
    int? teamWriteStatus,
    String teamRole = 'OWNER',
    bool throwNetwork = false,
  }) =>
      MockClient((request) async {
        final path = request.url.path;
        requestLog.add('${request.method} $path');
        if (throwNetwork) throw http.ClientException('offline');
        if (request.body.isNotEmpty) {
          final decoded = jsonDecode(request.body);
          if (decoded is Map<String, dynamic>) writeBodies.add(decoded);
        }

        if (overrides != null) {
          for (final entry in overrides.entries) {
            if (path.endsWith(entry.key)) return entry.value;
          }
        }

        if (path.endsWith('/partner/profile')) {
          return jsonResponse(profileJson(), 200);
        }
        if (path.endsWith('/partner/extranet/home')) {
          return jsonResponse(extranetHomeJson(), 200);
        }
        if (path.endsWith('/partner/hotels')) {
          return jsonResponse([hotelJson()], 200);
        }

        if (path.endsWith('/partner/payout-account')) {
          final code = payoutStatus ?? 200;
          if (code != 200) {
            return jsonResponse(errorBody(code, 'x', path), code);
          }
          return jsonResponse(payout ?? payoutJson(), 200);
        }

        final member = RegExp(r'/partner/team/(\d+)$').firstMatch(path);
        if (member != null) {
          final code = teamWriteStatus ?? 200;
          if (code != 200) {
            return jsonResponse(errorBody(code, 'refused', path), code);
          }
          if (request.method == 'DELETE') return http.Response('', 204);
          return jsonResponse(memberJson(id: int.parse(member.group(1)!)), 200);
        }
        if (path.endsWith('/partner/team')) {
          if (request.method == 'POST') {
            final code = teamWriteStatus ?? 201;
            if (code != 200 && code != 201) {
              return jsonResponse(errorBody(code, 'refused', path), code);
            }
            return jsonResponse(memberJson(id: 2, role: 'VIEWER'), 201);
          }
          return jsonResponse(team ?? [memberJson(role: teamRole)], 200);
        }

        if (path.contains('/partner/reviews/') && path.endsWith('/reply')) {
          final code = replyStatus ?? 200;
          if (code != 200) {
            return jsonResponse(errorBody(code, 'refused', path), code);
          }
          return jsonResponse(reviewJson(partnerReply: replyJson()), 200);
        }

        if (path.endsWith('/reviews') && path.contains('/places/')) {
          return jsonResponse(reviews ?? [reviewJson()], 200);
        }
        return jsonResponse(errorBody(404, 'Not found', path), 404);
      });

  AppState partnerApp(http.Client client) =>
      AppState(api: ApiClient(client: client)..demoMode = false)
        ..demoMode = false
        ..email = 'partner@planyourtrip.com'
        ..role = AppRole.partner;

  Widget testApp({
    required AppState app,
    required PartnerState partner,
    required Widget child,
    Locale? locale,
  }) =>
      AppScope(
        notifier: app,
        child: PartnerScope(
          notifier: partner,
          child: MaterialApp(
            theme: AppTheme.light(),
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: SingleChildScrollView(child: child)),
          ),
        ),
      );

  Future<({AppState app, PartnerState partner})> pumpScreen(
    WidgetTester tester,
    Widget child, {
    http.Client? client,
    Size size = const Size(1600, 3600),
    Locale? locale,
  }) async {
    final app = partnerApp(client ?? c12Client());
    final partner = PartnerState(api: app.api)..bindSession(app);
    await partner.loadWorkspace(app);

    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
        testApp(app: app, partner: partner, child: child, locale: locale));
    await tester.pumpAndSettle();
    return (app: app, partner: partner);
  }

  Future<({PartnerReviewsState state, PartnerState partner})> loadedReviews(
    http.Client client,
  ) async {
    final app = partnerApp(client);
    final partner = PartnerState(api: app.api)..bindSession(app);
    await partner.loadWorkspace(app);
    final state = PartnerReviewsState(api: app.api);
    await state.load(partner, partner.selectedPropertyId);
    return (state: state, partner: partner);
  }

  Future<({PartnerAccountState state, PartnerState partner})> loadedAccount(
    http.Client client,
  ) async {
    final app = partnerApp(client);
    final partner = PartnerState(api: app.api)..bindSession(app);
    await partner.loadWorkspace(app);
    final state = PartnerAccountState(api: app.api);
    await state.load(partner);
    return (state: state, partner: partner);
  }

  List<String> captureLayoutErrors(WidgetTester tester) {
    final errors = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details.toString());
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);
    return errors;
  }

  // ── Boundary ──────────────────────────────────────────────────────────

  group('C12 duplicates nothing', () {
    test('reviews becomes the last implemented destination', () {
      expect(PartnerNavigation.destinations, hasLength(13));
      final planned = PartnerNavigation.destinations
          .where((d) => !d.implemented)
          .map((d) => d.key)
          .toSet();
      // Messages and Notifications remain, and C12 did not invent a
      // destination for team, payout or profile.
      expect(planned, {'messages', 'notifications'});
    });

    test('the review list uses the endpoint UI-29 already implemented',
        () async {
      await loadedReviews(c12Client());
      expect(requestLog, contains('GET /api/places/11/reviews'));
      // There is no partner review list endpoint to call.
      expect(requestLog.any((r) => r.contains('/partner/reviews')), isFalse);
    });

    test('the account state never touches C6 settings or policies', () async {
      await loadedAccount(c12Client());
      final touched = requestLog.where((r) => r.contains('/partner/')).toSet();
      expect(touched.any((r) => r.contains('/partner/settings')), isFalse);
      expect(touched.any((r) => r.contains('/policies')), isFalse);
      expect(
          touched,
          containsAll(<String>[
            'GET /api/partner/team',
            'GET /api/partner/payout-account',
          ]));
    });
  });

  // ── Reviews ───────────────────────────────────────────────────────────

  group('reviews', () {
    test('the list is the property\'s published reviews', () async {
      final loaded = await loadedReviews(c12Client());
      expect(loaded.state.status, PartnerReviewsStatus.ready);
      expect(loaded.state.reviews, hasLength(1));
      expect(loaded.state.reviews.single.status, 'APPROVED');
    });

    test('no property selected is its own state, not an error', () async {
      final loaded = await loadedReviews(c12Client());
      await loaded.state.load(loaded.partner, null);
      expect(loaded.state.status, PartnerReviewsStatus.noProperty);
      expect(loaded.state.reviews, isEmpty);
    });

    test('an unowned property id is never requested', () async {
      final loaded = await loadedReviews(c12Client());
      final before = requestLog.length;
      await loaded.state.load(loaded.partner, 4242);
      expect(requestLog.length, before);
      expect(loaded.state.status, PartnerReviewsStatus.noProperty);
    });

    test('needs-reply and replied are counted from the same complete list',
        () async {
      final loaded = await loadedReviews(c12Client(reviews: [
        reviewJson(id: 1),
        reviewJson(id: 2, partnerReply: replyJson()),
        reviewJson(id: 3),
      ]));
      expect(loaded.state.needsReplyCount, 2);
      expect(loaded.state.repliedCount, 1);

      loaded.state.setFilter(PartnerReviewFilter.needsReply);
      expect(loaded.state.visibleReviews.map((r) => r.id), [1, 3]);

      loaded.state.setFilter(PartnerReviewFilter.replied);
      expect(loaded.state.visibleReviews.map((r) => r.id), [2]);
    });

    test('a filter that hides the open review closes it', () async {
      final loaded = await loadedReviews(c12Client(reviews: [
        reviewJson(id: 1),
        reviewJson(id: 2, partnerReply: replyJson()),
      ]));
      loaded.state.openReviewDetail(1);
      loaded.state.setFilter(PartnerReviewFilter.replied);
      expect(loaded.state.openReviewId, isNull);
    });

    test('opening a review outside the list is refused', () async {
      final loaded = await loadedReviews(c12Client());
      loaded.state.openReviewDetail(999);
      expect(loaded.state.openReviewId, isNull);
    });

    test('only an approved review may be replied to', () async {
      final loaded = await loadedReviews(
          c12Client(reviews: [reviewJson(status: 'PENDING')]));
      expect(loaded.state.canReplyTo(loaded.state.reviews.single), isFalse);

      final result = await loaded.state.submitReply(
        partner: loaded.partner,
        reviewId: 1,
        content: 'hello',
      );
      expect(result, PartnerReplyResult.notReplyable);
      // Refused before the request, so the server is never asked.
      expect(requestLog.any((r) => r.startsWith('PUT')), isFalse);
    });

    test('a reply PUTs the trimmed content and re-reads the list', () async {
      final loaded = await loadedReviews(c12Client());
      final result = await loaded.state.submitReply(
        partner: loaded.partner,
        reviewId: 1,
        content: '  Thank you.  ',
      );
      expect(result, PartnerReplyResult.success);
      expect(requestLog, contains('PUT /api/partner/reviews/1/reply'));
      expect(writeBodies.single, {'content': 'Thank you.'});
      // The stored reply and its timestamps come from the server.
      expect(requestLog.where((r) => r == 'GET /api/places/11/reviews').length,
          greaterThan(1));
    });

    test('an empty reply never reaches the network', () async {
      final loaded = await loadedReviews(c12Client());
      final result = await loaded.state.submitReply(
        partner: loaded.partner,
        reviewId: 1,
        content: '   ',
      );
      expect(result, PartnerReplyResult.validation);
      expect(requestLog.any((r) => r.startsWith('PUT')), isFalse);
    });

    test('the reply error codes map distinctly', () async {
      for (final entry in {
        401: PartnerReplyResult.unauthorized,
        403: PartnerReplyResult.forbidden,
        404: PartnerReplyResult.notFound,
        422: PartnerReplyResult.notReplyable,
        400: PartnerReplyResult.validation,
        500: PartnerReplyResult.failed,
      }.entries) {
        final loaded = await loadedReviews(c12Client(replyStatus: entry.key));
        final result = await loaded.state.submitReply(
          partner: loaded.partner,
          reviewId: 1,
          content: 'hello',
        );
        expect(result, entry.value, reason: 'HTTP ${entry.key}');
      }
    });

    test('a timeout is uncertain, because a reply cannot be withdrawn',
        () async {
      final app = partnerApp(c12Client());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);

      final slow = partnerApp(MockClient((request) async {
        if (request.method == 'PUT') {
          await Future<void>.delayed(const Duration(seconds: 30));
        }
        if (request.url.path.endsWith('/reviews')) {
          return jsonResponse([reviewJson()], 200);
        }
        return jsonResponse(errorBody(404, 'x', request.url.path), 404);
      }));
      final state = PartnerReviewsState(api: slow.api);
      await state.load(partner, partner.selectedPropertyId);
      final result = await state.submitReply(
          partner: partner, reviewId: 1, content: 'hello');
      expect(result, PartnerReplyResult.uncertain);
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('a network drop is retryable', () async {
      final app = partnerApp(c12Client());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final offline = partnerApp(c12Client(throwNetwork: true));
      final state = PartnerReviewsState(api: offline.api);
      await state.load(partner, partner.selectedPropertyId);
      expect(state.status, PartnerReviewsStatus.error);
      expect(state.isRetryable, isTrue);
    });
  });

  // ── Team ──────────────────────────────────────────────────────────────

  group('team', () {
    test('the role gate mirrors requireOwner exactly', () async {
      final loaded = await loadedAccount(c12Client());
      expect(loaded.state.canManageTeam(PartnerTeamRole.owner), isTrue);
      for (final role in [
        PartnerTeamRole.manager,
        PartnerTeamRole.frontDesk,
        PartnerTeamRole.finance,
        PartnerTeamRole.viewer,
        PartnerTeamRole.unknown,
      ]) {
        expect(loaded.state.canManageTeam(role), isFalse, reason: '$role');
      }
    });

    test('adding a member posts the email and the wire role', () async {
      final loaded = await loadedAccount(c12Client());
      final result = await loaded.state.addMember(
        partner: loaded.partner,
        email: '  desk@bayview.example ',
        role: PartnerTeamRole.frontDesk,
      );
      expect(result, PartnerAccountActionResult.success);
      expect(requestLog, contains('POST /api/partner/team'));
      expect(writeBodies.first,
          {'email': 'desk@bayview.example', 'role': 'FRONT_DESK'});
    });

    test('an unknown role can never be sent', () async {
      final loaded = await loadedAccount(c12Client());
      final before = requestLog.length;
      final result = await loaded.state.addMember(
        partner: loaded.partner,
        email: 'x@y.z',
        role: PartnerTeamRole.unknown,
      );
      expect(result, PartnerAccountActionResult.validation);
      expect(requestLog.length, before);
    });

    test('a role change sends only the role, never active', () async {
      final loaded = await loadedAccount(c12Client());
      await loaded.state.updateMember(
        partner: loaded.partner,
        memberId: 1,
        role: PartnerTeamRole.manager,
      );
      expect(requestLog, contains('PATCH /api/partner/team/1'));
      expect(writeBodies.first, {'role': 'MANAGER'});
    });

    test('a deactivate sends only active, never a role', () async {
      final loaded = await loadedAccount(c12Client());
      await loaded.state.updateMember(
        partner: loaded.partner,
        memberId: 1,
        active: false,
      );
      expect(writeBodies.first, {'active': false});
    });

    test('an update with nothing to change is refused locally', () async {
      final loaded = await loadedAccount(c12Client());
      final before = requestLog.length;
      final result =
          await loaded.state.updateMember(partner: loaded.partner, memberId: 1);
      expect(result, PartnerAccountActionResult.validation);
      expect(requestLog.length, before);
    });

    test('removal issues a DELETE and re-reads', () async {
      final loaded = await loadedAccount(c12Client());
      final result =
          await loaded.state.removeMember(partner: loaded.partner, memberId: 1);
      expect(result, PartnerAccountActionResult.success);
      expect(requestLog, contains('DELETE /api/partner/team/1'));
    });

    test('a 403 on a team write is surfaced, not pre-empted', () async {
      final loaded = await loadedAccount(c12Client(teamWriteStatus: 403));
      final result =
          await loaded.state.removeMember(partner: loaded.partner, memberId: 1);
      expect(result, PartnerAccountActionResult.forbidden);
    });

    test('a 409 on add is a conflict', () async {
      final loaded = await loadedAccount(c12Client(teamWriteStatus: 409));
      final result = await loaded.state.addMember(
        partner: loaded.partner,
        email: 'x@y.z',
        role: PartnerTeamRole.viewer,
      );
      expect(result, PartnerAccountActionResult.conflict);
    });

    test('only the five real roles are assignable', () {
      expect(partnerAssignableRoles, hasLength(5));
      expect(partnerAssignableRoles.contains(PartnerTeamRole.unknown), isFalse);
      for (final role in partnerAssignableRoles) {
        expect(partnerTeamRoleWire(role), isNotNull);
      }
      expect(partnerTeamRoleWire(PartnerTeamRole.unknown), isNull);
      // SUPER_PARTNER does not exist and is never created.
      expect(
        partnerAssignableRoles
            .map(partnerTeamRoleWire)
            .contains('SUPER_PARTNER'),
        isFalse,
      );
    });
  });

  // ── Payout ────────────────────────────────────────────────────────────

  group('payout account', () {
    test('the role gate mirrors PAYOUT_WRITE_ROLES', () async {
      final loaded = await loadedAccount(c12Client());
      expect(loaded.state.canEditPayout(PartnerTeamRole.owner), isTrue);
      expect(loaded.state.canEditPayout(PartnerTeamRole.finance), isTrue);
      for (final role in [
        PartnerTeamRole.manager,
        PartnerTeamRole.frontDesk,
        PartnerTeamRole.viewer,
        PartnerTeamRole.unknown,
      ]) {
        expect(loaded.state.canEditPayout(role), isFalse, reason: '$role');
      }
    });

    test('only the last four digits are ever received', () {
      final account = PartnerPayoutAccount.fromJson(payoutJson())!;
      expect(account.bankAccountLast4, '6789');
      // No full-number field exists on the DTO or the model.
      expect(payoutJson().containsKey('bankAccountNumber'), isFalse);
      expect(account.toString().contains('bankAccountNumber'), isFalse);
    });

    test('no payout account yet is a real state, not a failure', () async {
      final loaded = await loadedAccount(c12Client(payoutStatus: 404));
      expect(loaded.state.status, PartnerAccountStatus.ready);
      expect(loaded.state.hasPayoutAccount, isFalse);
      expect(loaded.state.payoutErrorKind, isNull);
    });

    test('a payout read failure is told apart from having none', () async {
      final loaded = await loadedAccount(c12Client(payoutStatus: 500));
      expect(loaded.state.hasPayoutAccount, isFalse);
      expect(loaded.state.payoutErrorKind, ApiErrorKind.server);
      // The team still loaded.
      expect(loaded.state.team, isNotEmpty);
    });

    test('a too-short account number never reaches the network', () async {
      final loaded = await loadedAccount(c12Client());
      final before = requestLog.length;
      final result = await loaded.state.savePayoutAccount(
        partner: loaded.partner,
        accountHolderName: 'A',
        bankName: 'B',
        bankAccountNumber: '123',
        payoutMethod: PartnerPayoutMethod.bankTransfer,
      );
      expect(result, PartnerAccountActionResult.validation);
      expect(requestLog.length, before);
    });

    test('a valid save sends the four request fields', () async {
      final loaded = await loadedAccount(c12Client());
      final result = await loaded.state.savePayoutAccount(
        partner: loaded.partner,
        accountHolderName: ' Partner User ',
        bankName: ' Vietcombank ',
        bankAccountNumber: ' 123456789 ',
        payoutMethod: PartnerPayoutMethod.bankTransfer,
      );
      expect(result, PartnerAccountActionResult.success);
      expect(writeBodies.first, {
        'accountHolderName': 'Partner User',
        'bankName': 'Vietcombank',
        'bankAccountNumber': '123456789',
        'payoutMethod': 'BANK_TRANSFER',
      });
    });

    test('only the two real payout methods are selectable', () {
      expect(PartnerPayoutMethod.selectable, [
        PartnerPayoutMethod.bankTransfer,
        PartnerPayoutMethod.manual,
      ]);
      expect(PartnerPayoutMethod.unknown.wireValue, isNull);
      expect(
          PartnerPayoutMethod.parse('E_WALLET'), PartnerPayoutMethod.unknown);
    });
  });

  // ── UI ────────────────────────────────────────────────────────────────

  group('reviews UI', () {
    testWidgets('renders the property\'s reviews', (tester) async {
      await pumpScreen(tester, const PartnerReviewsScreen());
      expect(find.text('Wonderful stay'), findsWidgets);
      expect(find.text(en.partnerReviewsNeedsReply), findsWidgets);
    });

    testWidgets('says the review body is unavailable', (tester) async {
      await pumpScreen(tester, const PartnerReviewsScreen());
      expect(find.text(en.partnerReviewsNoBodyNotice), findsOneWidget);
    });

    testWidgets('warns that a published reply cannot be deleted',
        (tester) async {
      await pumpScreen(tester, const PartnerReviewsScreen());
      await tester.tap(find.text('Wonderful stay').first);
      await tester.pumpAndSettle();
      expect(find.text(en.partnerReviewsPublicNotice), findsOneWidget);
    });

    testWidgets('publishing asks for confirmation first', (tester) async {
      await pumpScreen(tester, const PartnerReviewsScreen());
      await tester.tap(find.text('Wonderful stay').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Thank you.');
      await tester.pump();
      await tester.tap(find.text(en.partnerReviewsPublishReply));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text(en.partnerBookingActionCancel));
      await tester.pumpAndSettle();
      expect(requestLog.any((r) => r.startsWith('PUT')), isFalse);
    });

    testWidgets('a non-approved review offers no reply box', (tester) async {
      await pumpScreen(tester, const PartnerReviewsScreen(),
          client: c12Client(reviews: [reviewJson(status: 'PENDING')]));
      await tester.tap(find.text('Wonderful stay').first);
      await tester.pumpAndSettle();
      expect(find.text(en.partnerReviewsNotApprovedNotice), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('an empty property says so', (tester) async {
      await pumpScreen(tester, const PartnerReviewsScreen(),
          client: c12Client(reviews: []));
      expect(find.text(en.partnerReviewsEmptyTitle), findsOneWidget);
    });
  });

  group('settings UI', () {
    testWidgets('keeps C6 as the first tab and adds three', (tester) async {
      await pumpScreen(tester, const PartnerSettingsScreen());
      expect(find.text(en.partnerSettingsTabWorkspace), findsOneWidget);
      expect(find.text(en.partnerSettingsTabTeam), findsOneWidget);
      expect(find.text(en.partnerSettingsTabPayout), findsOneWidget);
      expect(find.text(en.partnerSettingsTabProfile), findsOneWidget);
    });

    testWidgets('the team tab lists members', (tester) async {
      await pumpScreen(tester, const PartnerSettingsScreen());
      await tester.tap(find.text(en.partnerSettingsTabTeam));
      await tester.pumpAndSettle();
      expect(find.text('partner@planyourtrip.com'), findsWidgets);
      expect(find.text(en.partnerTeamRoleOwner), findsWidgets);
    });

    testWidgets('the payout tab shows only the masked number', (tester) async {
      await pumpScreen(tester, const PartnerSettingsScreen());
      await tester.tap(find.text(en.partnerSettingsTabPayout));
      await tester.pumpAndSettle();
      expect(find.text(en.partnerPayoutMasked('6789')), findsOneWidget);
      expect(find.text(en.partnerPayoutNoExecutionNotice), findsOneWidget);
      // No full account number exists to show.
      expect(find.textContaining('123456789'), findsNothing);
    });

    testWidgets('the profile tab is read-only and explains why',
        (tester) async {
      await pumpScreen(tester, const PartnerSettingsScreen());
      await tester.tap(find.text(en.partnerSettingsTabProfile));
      await tester.pumpAndSettle();
      expect(find.text(en.partnerProfileReadOnlyNotice), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Save'), findsNothing);
    });
  });

  // ── Gating, layout, localization ──────────────────────────────────────

  group('gating', () {
    testWidgets('a non-approved partner reaches neither module',
        (tester) async {
      final app = partnerApp(MockClient((request) async {
        if (request.url.path.endsWith('/partner/profile')) {
          return jsonResponse(
              profileJson(verificationStatus: 'SUBMITTED'), 200);
        }
        return jsonResponse(errorBody(404, 'no', request.url.path), 404);
      }));
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);

      await tester.pumpWidget(testApp(
          app: app, partner: partner, child: const PartnerReviewsScreen()));
      await tester.pumpAndSettle();
      expect(find.text(en.partnerReviewsNoBodyNotice), findsNothing);
    });
  });

  group('layout', () {
    for (final size in const [
      Size(1600, 3600),
      Size(820, 4200),
      Size(390, 5200),
      Size(320, 5200),
    ]) {
      testWidgets('reviews fit $size', (tester) async {
        final errors = captureLayoutErrors(tester);
        await pumpScreen(tester, const PartnerReviewsScreen(), size: size);
        expect(errors, isEmpty);
      });

      testWidgets('settings fit $size', (tester) async {
        final errors = captureLayoutErrors(tester);
        await pumpScreen(tester, const PartnerSettingsScreen(), size: size);
        expect(errors, isEmpty);
      });
    }

    testWidgets('the team tab fits a narrow phone', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpScreen(tester, const PartnerSettingsScreen(),
          size: const Size(320, 5200));
      await tester.tap(find.text(en.partnerSettingsTabTeam));
      await tester.pumpAndSettle();
      expect(errors, isEmpty);
    });
  });

  group('localization', () {
    testWidgets('English renders English strings', (tester) async {
      await pumpScreen(tester, const PartnerReviewsScreen(),
          locale: const Locale('en'));
      expect(find.text(en.partnerReviewsTitle), findsOneWidget);
    });

    testWidgets('Vietnamese renders Vietnamese strings', (tester) async {
      await pumpScreen(tester, const PartnerReviewsScreen(),
          locale: const Locale('vi'));
      expect(find.text(vi.partnerReviewsTitle), findsOneWidget);
    });

    testWidgets('Vietnamese settings do not overflow', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpScreen(tester, const PartnerSettingsScreen(),
          size: const Size(390, 5200), locale: const Locale('vi'));
      expect(errors, isEmpty);
    });

    test('labels do not collide with the sidebar destinations', () {
      expect(en.partnerReviewsTitle, isNot(en.partnerNavReviews));
      expect(vi.partnerReviewsTitle, isNot(vi.partnerNavReviews));
      expect(en.partnerSettingsTitle, isNot(en.partnerNavSettings));
      expect(vi.partnerSettingsTitle, isNot(vi.partnerNavSettings));
    });
  });
}
