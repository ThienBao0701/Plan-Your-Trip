import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/mock/app_models.dart';
import 'package:planyourtrip_frontend/core/mock/mock_data.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/home/app_shell.dart';
import 'package:planyourtrip_frontend/features/hotels/hotel_utils.dart';
import 'package:planyourtrip_frontend/features/profile/profile_screen.dart';
import 'package:planyourtrip_frontend/features/rewards/rewards_screen.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final today = DateTime(2026, 7, 16, 10);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  AppState testState({bool demoMode = true}) {
    final app = AppState(now: () => today)
      ..demoMode = demoMode
      ..email = demoMode ? MockData.demoEmail : 'real@example.com';
    if (!demoMode) {
      app.trips = [];
      app.timeline = [];
      app.expenses = [];
      app.demoBookings = [];
      app.travelCreditAccount = null;
      app.travelCreditTransactions = [];
      app.loyaltyAccount = null;
      app.loyaltyTransactions = [];
      app.membershipAccount = null;
      app.membershipProgress = null;
      app.membershipBenefits = [];
      app.membershipHistory = [];
      app.coupons = [];
      app.referralSummary = null;
      app.referralHistory = [];
      app.giftCards = [];
    }
    return app;
  }

  Widget harness({
    required Widget child,
    AppState? app,
    Locale? locale,
    double textScaleFactor = 1,
  }) {
    return AppScope(
      notifier: app ?? testState(),
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
    await tester.pumpWidget(harness(
      child: child,
      app: app,
      locale: locale,
      textScaleFactor: textScaleFactor,
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('Profile opens Rewards Hub without adding an AppShell tab',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpSize(
      tester,
      const AppShell(),
      const Size(900, 1400),
    );

    try {
      expect(find.bySemanticsLabel('Explore tab'), findsOneWidget);
      expect(find.bySemanticsLabel('Trips tab'), findsOneWidget);
      expect(find.bySemanticsLabel('Planner tab'), findsOneWidget);
      expect(find.bySemanticsLabel('Profile tab'), findsOneWidget);
      expect(find.bySemanticsLabel('Rewards tab'), findsNothing);
    } finally {
      semantics.dispose();
    }

    await pumpSize(
      tester,
      const ProfileScreen(),
      const Size(900, 1800),
    );

    await tester.tap(find.byKey(const Key('profile-rewards')));
    await tester.pumpAndSettle();

    expect(find.text('Rewards & Benefits'), findsWidgets);
    expect(find.text('Travel Credits'), findsOneWidget);
  });

  testWidgets('real mode shows no seeded rewards while demo shows summaries',
      (tester) async {
    await pumpSize(
      tester,
      const RewardsHubScreen(),
      const Size(900, 1400),
      app: testState(demoMode: false),
    );

    expect(find.text('Rewards not connected'), findsOneWidget);
    expect(find.textContaining('750'), findsNothing);

    await pumpSize(
      tester,
      const RewardsHubScreen(),
      const Size(900, 1400),
      app: testState(),
    );

    expect(find.text('PYTDEMO'), findsOneWidget);
    expect(find.textContaining('750'), findsWidgets);
  });

  testWidgets('Travel credits show currency, direction, and no cash controls',
      (tester) async {
    await pumpSize(
      tester,
      const TravelCreditsScreen(),
      const Size(900, 1400),
    );

    expect(find.text('Available travel credit'), findsOneWidget);
    expect(find.textContaining('+'), findsWidgets);
    expect(find.textContaining('-'), findsWidgets);
    expect(find.textContaining('₫'), findsWidgets);
    expect(find.widgetWithText(ElevatedButton, 'Cash out'), findsNothing);
    expect(find.widgetWithText(TextButton, 'Transfer'), findsNothing);
  });

  test('reward direction, redeemable status, and progress helpers are bounded',
      () {
    expect(TravelCreditTransactionType.grant.increasesBalance, isTrue);
    expect(TravelCreditTransactionType.promotion.increasesBalance, isTrue);
    expect(TravelCreditTransactionType.refundCredit.increasesBalance, isTrue);
    expect(TravelCreditTransactionType.reversal.increasesBalance, isTrue);
    expect(TravelCreditTransactionType.redemption.increasesBalance, isFalse);
    expect(TravelCreditTransactionType.expiration.increasesBalance, isFalse);
    expect(TravelCreditTransactionType.adjustment.increasesBalance, isFalse);

    final adjustmentUp = LoyaltyTransaction(
      transactionType: LoyaltyTransactionType.adjustment,
      points: 100,
      balanceBefore: 1000,
      balanceAfter: 1100,
      description: 'Manual correction metadata',
      createdAt: today,
    );
    final reversalDown = LoyaltyTransaction(
      transactionType: LoyaltyTransactionType.reversal,
      points: 200,
      balanceBefore: 1100,
      balanceAfter: 900,
      description: 'Reversal metadata',
      createdAt: today,
    );

    expect(adjustmentUp.increasesBalance, isTrue);
    expect(reversalDown.increasesBalance, isFalse);
    expect(LoyaltyTransactionType.redemptionRelease.knownIncrease, isTrue);
    expect(LoyaltyTransactionType.redemptionRefund.knownIncrease, isTrue);
    expect(LoyaltyTransactionType.redemptionDebit.knownIncrease, isFalse);

    expect(GiftCardStatus.active.canRedeem, isTrue);
    expect(GiftCardStatus.partiallyRedeemed.canRedeem, isTrue);
    expect(GiftCardStatus.issued.canRedeem, isFalse);
    expect(GiftCardStatus.fullyRedeemed.canRedeem, isFalse);
    expect(GiftCardStatus.expired.canRedeem, isFalse);
    expect(GiftCardStatus.cancelled.canRedeem, isFalse);

    const negativeProgress = MembershipProgress(
      currentTier: MembershipTier.bronze,
      effectiveTier: MembershipTier.bronze,
      lifetimePointsEarned: 0,
      completedBookings: 0,
      progressPercentage: -20,
    );
    const excessiveProgress = MembershipProgress(
      currentTier: MembershipTier.diamond,
      effectiveTier: MembershipTier.diamond,
      lifetimePointsEarned: 100000,
      completedBookings: 40,
      progressPercentage: 180,
    );

    expect(negativeProgress.clampedProgress, 0);
    expect(excessiveProgress.clampedProgress, 100);
  });

  testWidgets('Loyalty separates current and lifetime points without currency',
      (tester) async {
    await pumpSize(
      tester,
      const LoyaltyScreen(),
      const Size(900, 1400),
    );

    expect(find.text('Current balance'), findsOneWidget);
    expect(find.text('Lifetime earned'), findsOneWidget);
    expect(find.textContaining('points'), findsWidgets);
    expect(find.textContaining('₫'), findsNothing);
  });

  testWidgets(
      'Membership preview, clamped progress, highest tier and enrollment',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final app = testState()
      ..membershipProgress = const MembershipProgress(
        currentTier: MembershipTier.diamond,
        effectiveTier: MembershipTier.diamond,
        lifetimePointsEarned: 90000,
        completedBookings: 30,
        progressPercentage: 140,
      );

    await pumpSize(
      tester,
      const MembershipScreen(),
      const Size(900, 1400),
      app: app,
    );

    try {
      expect(find.text('Preview'), findsOneWidget);
      expect(find.text('Diamond'), findsOneWidget);
      expect(find.textContaining('Highest tier'), findsOneWidget);
      expect(find.bySemanticsLabel('Membership progress 100 percent'),
          findsOneWidget);

      await tester.tap(find.byKey(const Key('membership-enroll')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('membership-enroll')));
      await tester.pumpAndSettle();

      expect(app.membershipAccount?.active, isTrue);
      expect(
        app.membershipHistory
            .where((item) => item.description == 'Local demo enrollment')
            .length,
        1,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
      'Expired membership uses effective preview tier instead of stored tier',
      (tester) async {
    final app = testState()
      ..membershipAccount = MembershipAccount(
        currentTier: MembershipTier.diamond,
        effectiveTier: MembershipTier.diamond,
        active: true,
        expired: true,
        validUntil: today.subtract(const Duration(days: 1)),
      )
      ..membershipProgress = MembershipProgress(
        currentTier: MembershipTier.diamond,
        effectiveTier: MembershipTier.silver,
        lifetimePointsEarned: 9800,
        completedBookings: 4,
        nextTier: MembershipTier.gold,
        pointsRequiredForNextTier: 12000,
        bookingsRequiredForNextTier: 6,
        progressPercentage: 68,
        validUntil: today.subtract(const Duration(days: 1)),
        expired: true,
      );

    await pumpSize(
      tester,
      const MembershipScreen(),
      const Size(900, 1400),
      app: app,
    );

    expect(find.text('Expired'), findsOneWidget);
    expect(find.text('Silver'), findsWidgets);
    expect(find.text('Diamond'), findsNothing);
  });

  test('real membership enrollment is unavailable', () {
    final app = testState(demoMode: false);

    expect(app.enrollDemoMembership(), RewardActionResult.unavailable);
    expect(app.membershipAccount, isNull);
  });

  testWidgets('Benefits are metadata rather than fulfilled actions',
      (tester) async {
    await pumpSize(
      tester,
      const MembershipScreen(),
      const Size(900, 1400),
    );

    expect(find.text('Benefits metadata'), findsOneWidget);
    expect(find.textContaining('not applied to UI-6 quotes'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Upgrade room'), findsNothing);
  });

  testWidgets('Coupons show effective status and percentage/fixed formatting',
      (tester) async {
    await pumpSize(
      tester,
      const CouponsScreen(),
      const Size(900, 1400),
    );

    expect(find.text('ACTIVE'), findsOneWidget);
    expect(find.text('USED'), findsOneWidget);
    expect(find.text('15% off'), findsOneWidget);
    expect(find.textContaining('₫300,000'), findsOneWidget);
    expect(find.textContaining('read-only'), findsWidgets);
  });

  testWidgets('Fixed coupon without currency does not invent an amount',
      (tester) async {
    final app = testState()
      ..coupons = [
        CustomerCoupon(
          id: 'coupon-no-currency',
          code: 'NOCURRENCY',
          name: 'No currency coupon',
          description: 'Fixed discount without currency context.',
          discountType: CouponDiscountType.fixedAmount,
          discountValue: 250000,
          validFrom: today.subtract(const Duration(days: 1)),
          validUntil: today.add(const Duration(days: 30)),
          effectiveStatus: 'ACTIVE',
          claimedAt: today,
        ),
        CustomerCoupon(
          id: 'coupon-high-percent',
          code: 'HIGH150',
          name: 'High percent coupon',
          description: 'Percentage discount outside display bounds.',
          discountType: CouponDiscountType.percentage,
          discountValue: 150,
          validFrom: today.subtract(const Duration(days: 1)),
          validUntil: today.add(const Duration(days: 30)),
          effectiveStatus: 'ACTIVE',
          claimedAt: today,
        ),
      ];

    await pumpSize(
      tester,
      const CouponsScreen(),
      const Size(900, 1400),
      app: app,
    );

    expect(find.text('Amount unavailable'), findsOneWidget);
    expect(find.textContaining('₫250,000'), findsNothing);
    expect(find.text('100% off'), findsOneWidget);
    expect(find.text('150% off'), findsNothing);
  });

  testWidgets(
      'Coupon claim rejects blank and duplicate and does not touch quote',
      (tester) async {
    final app = testState();
    final hotel = MockData.places.first;
    final criteria =
        defaultHotelCriteria(today: today, trip: MockData.trips.first);
    final room = hotel.hotelDetail!.rooms.first;
    final rate = room.ratePlans.first;
    final quote = buildLocalHotelQuote(
      hotel: hotel,
      room: room,
      ratePlan: rate,
      criteria: criteria,
      generatedAt: today,
    );
    final originalTotal = quote.finalQuotedPrice;

    await pumpSize(
      tester,
      const CouponsScreen(),
      const Size(900, 1400),
      app: app,
    );

    await tester.tap(find.bySemanticsLabel('Claim local demo coupon'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Enter a code first.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'local300');
    await tester.tap(find.bySemanticsLabel('Claim local demo coupon'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(
        app.coupons.firstWhere((c) => c.code == 'LOCAL300').isClaimed, isTrue);

    await tester.enterText(find.byType(TextField), 'LOCAL300');
    await tester.tap(find.bySemanticsLabel('Claim local demo coupon'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('This code is already used or claimed.'), findsOneWidget);
    expect(quote.finalQuotedPrice, originalTotal);
  });

  testWidgets(
      'Referral copy state, own-code rejection, repeated-use prevention',
      (tester) async {
    final app = testState();
    final originalPoints = app.loyaltyAccount!.currentBalance;

    await pumpSize(
      tester,
      const ReferralScreen(),
      const Size(900, 1400),
      app: app,
    );

    await tester.tap(find.byKey(const Key('referral-copy')));
    await tester.pump();
    expect(find.text('Copied'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'PYTDEMO');
    await tester.tap(find.bySemanticsLabel('Use local demo referral code'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('You cannot use your own referral code.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'FRIEND26');
    await tester.tap(find.bySemanticsLabel('Use local demo referral code'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(app.referralSummary?.usedCode, 'FRIEND26');
    expect(app.loyaltyAccount!.currentBalance, originalPoints);

    await tester.enterText(find.byType(TextField), 'FRIEND26');
    await tester.tap(find.bySemanticsLabel('Use local demo referral code'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('This code is already used or claimed.'), findsOneWidget);
  });

  testWidgets(
      'Gift cards are masked, preview is read-only, and claim validates',
      (tester) async {
    final app = testState();
    final initialCardId = app.giftCards.first.id;
    final initialBalance = app.giftCards.first.currentBalanceMinor;

    await pumpSize(
      tester,
      const GiftCardsScreen(),
      const Size(900, 1400),
      app: app,
    );

    expect(find.text('PYT-****-2048'), findsOneWidget);
    expect(find.textContaining('2048'), findsOneWidget);
    expect(find.textContaining('GIFTDEMO'), findsOneWidget);
    expect(find.textContaining('Purchase'), findsNothing);
    expect(find.textContaining('Payment'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Claim local demo gift card'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Enter a code first.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'GIFTDEMO');
    await tester.tap(find.bySemanticsLabel('Claim local demo gift card'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(
        app.giftCards.any((card) => card.id == 'gift-claimed-local'), isTrue);

    await tester.tap(find.byKey(const Key('gift-card-gift-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preview only'));
    await tester.pumpAndSettle();
    expect(
      app.giftCards
          .firstWhere((card) => card.id == initialCardId)
          .currentBalanceMinor,
      initialBalance,
    );
  });

  test('gift cards with different currencies are not combined', () {
    final app = testState()
      ..giftCards = [
        ...MockData.giftCards,
        GiftCard(
          id: 'gift-usd',
          maskedCode: 'PYT-****-USD1',
          productName: 'USD card',
          originalAmountMinor: 2500,
          currentBalanceMinor: 2500,
          currency: 'USD',
          status: GiftCardStatus.active,
          effectiveStatus: GiftCardStatus.active,
          issuedAt: today,
        ),
      ];

    final currencies = app.giftCards.map((card) => card.currency).toSet();

    expect(currencies, containsAll(['VND', 'USD']));
    expect(app.giftCards.length, 3);
  });

  test('demo reward actions never work in real mode', () {
    final app = testState(demoMode: false);

    expect(app.claimDemoCoupon('LOCAL300'), RewardActionResult.unavailable);
    expect(app.useDemoReferralCode('FRIEND26'), RewardActionResult.unavailable);
    expect(app.claimDemoGiftCard('GIFTDEMO'), RewardActionResult.unavailable);
    expect(app.api.token, isNull);
    expect(app.api.demoMode, isTrue);
  });

  testWidgets('Vietnamese rewards labels render', (tester) async {
    await pumpSize(
      tester,
      const RewardsHubScreen(),
      const Size(900, 1400),
      locale: const Locale('vi'),
    );

    expect(find.text('Ưu đãi & quyền lợi'), findsWidgets);
    expect(find.text('Tín dụng du lịch'), findsOneWidget);
    expect(find.text('Thẻ quà tặng'), findsOneWidget);
  });

  testWidgets('Rewards screens support narrow layout', (tester) async {
    await pumpSize(
      tester,
      const RewardsHubScreen(),
      const Size(330, 720),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('Rewards screens support wide layout', (tester) async {
    await pumpSize(
      tester,
      const RewardsHubScreen(),
      const Size(1280, 820),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('Rewards screens support enlarged text and semantics',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpSize(
        tester,
        const RewardsHubScreen(),
        const Size(390, 820),
        textScaleFactor: 1.6,
      );

      expect(find.bySemanticsLabel('Open Travel Credits'), findsOneWidget);
      expect(find.bySemanticsLabel('Open Gift Cards'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  test('logout and real-login failure regressions remain intact for rewards',
      () async {
    final app = testState();

    await app.logout();

    expect(app.api.token, isNull);
    expect(app.demoMode, isTrue);
    expect(app.travelCreditAccount, isNotNull);
    expect(app.giftCards, isNotEmpty);
  });
}
