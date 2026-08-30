import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/partner/partner_models.dart';
import '../../../core/partner/partner_promotion_models.dart';
import '../../../core/partner/partner_state.dart';
import '../../../design/app_breakpoints.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_radii.dart';
import '../../../design/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/glass_widgets.dart';
import '../properties/widgets/partner_property_widgets.dart';
import '../widgets/partner_state_views.dart';
import 'partner_promotions_state.dart';
import 'partner_vouchers_state.dart';
import 'widgets/partner_promotion_widgets.dart';

/// The Partner Promotions module, plus the booking-voucher check.
///
/// ## Two unrelated domains, deliberately not merged
///
/// The two tabs are separate because the concepts are: a **promotion** is an
/// automatic discount rule the pricing engine applies; a **voucher** here is a
/// signed *booking* QR payload used to admit a guest, carrying no discount. They
/// share a screen only because the backend's own menu has one `promotions` key
/// and voucher verification lives under `/api/partner/bookings/**`, whose
/// destination is out of scope this phase. C8 should move the voucher check to
/// Bookings, where the backend already puts it.
///
/// ## Backend contract (verified in `backend-v1`/`develop` and live on :8081)
///
/// | Action | Endpoint | C7 |
/// |---|---|---|
/// | List promotions | `GET /api/partner/promotions` | ✅ |
/// | Promotion detail | `GET /api/partner/promotions/{id}` | ✅ |
/// | Activate / deactivate | `PUT /api/partner/promotions/{id}` (lossless full body) | ✅ |
/// | Pricing preview | `GET /api/partner/rooms/{roomId}/pricing-preview` | ✅ |
/// | Voucher check | `POST /api/partner/bookings/voucher/verify` (read-only) | ✅ |
/// | Create / free-form edit / delete | `POST` / `PUT` / `DELETE` | ⛔ |
///
/// Create and free-form edit are absent for two concrete reasons: the request is
/// a **sixteen-field full replace**, and a `HOTEL` target needs a `HotelDetail`
/// id that **no partner endpoint exposes**. Delete is irreversible. The
/// activate toggle is safe because every request field is present on the
/// response, so the whole record can be echoed back with one flag changed.
class PartnerPromotionsScreen extends StatefulWidget {
  const PartnerPromotionsScreen({super.key});

  @override
  State<PartnerPromotionsScreen> createState() =>
      _PartnerPromotionsScreenState();
}

class _PartnerPromotionsScreenState extends State<PartnerPromotionsScreen>
    with SingleTickerProviderStateMixin {
  PartnerPromotionsState? _promotions;
  PartnerVouchersState? _vouchers;
  PartnerState? _partner;
  int? _syncedPropertyId;

  // Built eagerly, not lazily: on a gated workspace `build` returns before it is
  // ever read, and a lazy `late final` would then be constructed for the first
  // time inside `dispose()` — against an already-deactivated element.
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final partner = PartnerScope.of(context);
    final rebind = !identical(partner, _partner);
    if (rebind) {
      _partner = partner;
      _promotions?.dispose();
      _vouchers?.dispose();
      _promotions = PartnerPromotionsState(api: partner.api);
      _vouchers = PartnerVouchersState(api: partner.api);
      _syncedPropertyId = null;
    }

    final selected = partner.selectedPropertyId;
    if (partner.isReady && (rebind || selected != _syncedPropertyId)) {
      _syncedPropertyId = selected;
      final promotions = _promotions!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) promotions.load(partner, selected);
      });
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _promotions?.dispose();
    _vouchers?.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final partner = _partner;
    final promotions = _promotions;
    if (partner == null || promotions == null) return;
    await promotions.load(partner, partner.selectedPropertyId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final partner = PartnerScope.of(context);
    final promotions = _promotions;
    final vouchers = _vouchers;

    if (!partner.isReady || promotions == null || vouchers == null) {
      return PartnerWorkspaceStatusView(
        status: partner.status,
        detail: partner.errorMessage,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OceanGlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.partnerPromotionsTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              TabBar(
                controller: _tabs,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppColors.ocean700,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.ocean700,
                tabs: [
                  Tab(text: l10n.partnerPromotionsTabPromotions),
                  Tab(text: l10n.partnerPromotionsTabVoucherCheck),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // A fixed-height TabBarView would fight the shell's scroll view, so the
        // selected tab is rendered directly instead.
        AnimatedBuilder(
          animation: _tabs,
          builder: (context, _) => _tabs.index == 0
              ? AnimatedBuilder(
                  animation: promotions,
                  builder: (context, _) => _PromotionsTab(
                    partner: partner,
                    promotions: promotions,
                    onReload: _reload,
                  ),
                )
              : AnimatedBuilder(
                  animation: vouchers,
                  builder: (context, _) => _VoucherCheckTab(vouchers: vouchers),
                ),
        ),
      ],
    );
  }
}

class _PromotionsTab extends StatelessWidget {
  final PartnerState partner;
  final PartnerPromotionsState promotions;
  final Future<void> Function() onReload;

  const _PromotionsTab({
    required this.partner,
    required this.promotions,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    switch (promotions.status) {
      case PartnerPromotionsStatus.unauthorized:
        return const PartnerWorkspaceStatusView(
            status: PartnerWorkspaceStatus.unauthorized);
      case PartnerPromotionsStatus.forbidden:
        return PartnerWorkspaceStatusView(
          status: PartnerWorkspaceStatus.forbidden,
          detail: promotions.errorMessage,
          onPrimaryAction: onReload,
        );
      case PartnerPromotionsStatus.notFound:
        return PartnerWorkspaceStatusView(
          status: PartnerWorkspaceStatus.onboardingRequired,
          onPrimaryAction: onReload,
        );
      case PartnerPromotionsStatus.error:
        return PartnerWorkspaceStatusView(
          status: PartnerWorkspaceStatus.error,
          detail: promotions.errorMessage,
          onPrimaryAction: onReload,
        );
      case PartnerPromotionsStatus.idle:
      case PartnerPromotionsStatus.loading:
        return const _PromotionsLoading();
      case PartnerPromotionsStatus.ready:
        break;
    }

    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= AppBreakpoints.desktop;
    final open = promotions.openPromotion;

    if (promotions.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PromotionsHeader(promotions: promotions, onReload: onReload),
          const SizedBox(height: AppSpacing.md),
          OceanStateView(
            icon: Icons.local_offer_outlined,
            title: l10n.partnerPromotionsEmptyTitle,
            message: l10n.partnerPromotionsEmptyMessage,
            semanticLabel: l10n.partnerPromotionsEmptyTitle,
          ),
          const SizedBox(height: AppSpacing.md),
          _PricingPreviewCard(promotions: promotions),
        ],
      );
    }

    final list = _PromotionList(
      partner: partner,
      promotions: promotions,
      compact: isWide && open != null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PromotionsHeader(promotions: promotions, onReload: onReload),
        const SizedBox(height: AppSpacing.md),
        if (isWide && open != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: list),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 3,
                child: _PromotionDetailPanel(
                    promotions: promotions, promotion: open),
              ),
            ],
          )
        else if (open != null)
          _PromotionDetailPanel(promotions: promotions, promotion: open)
        else
          list,
        const SizedBox(height: AppSpacing.md),
        _PricingPreviewCard(promotions: promotions),
      ],
    );
  }
}

class _PromotionsHeader extends StatelessWidget {
  final PartnerPromotionsState promotions;
  final Future<void> Function() onReload;

  const _PromotionsHeader({required this.promotions, required this.onReload});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  // Stated because the list is partner-wide, not per property —
                  // the backend has no hotelId parameter here.
                  l10n.partnerPromotionsScopeNote,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ),
              IconButton(
                onPressed: promotions.isLoading ? null : onReload,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: l10n.partnerActionRefresh,
              ),
            ],
          ),
          if (promotions.isReady && promotions.promotions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xxs,
              children: [
                _Fact(
                  icon: Icons.local_offer_outlined,
                  text:
                      l10n.partnerPromotionsCount(promotions.promotions.length),
                ),
                _Fact(
                  icon: Icons.toggle_on_rounded,
                  text:
                      l10n.partnerPromotionsActiveCount(promotions.activeCount),
                ),
                if (promotions.expiredCount > 0)
                  _Fact(
                    icon: Icons.event_busy_outlined,
                    text: l10n
                        .partnerPromotionsExpiredCount(promotions.expiredCount),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.partnerPromotionsCurrencyNote,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Fact({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.textTertiary),
          const SizedBox(width: AppSpacing.xxs),
          Flexible(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      );
}

class _PromotionsLoading extends StatelessWidget {
  const _PromotionsLoading();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.partnerStatusLoadingTitle,
      liveRegion: true,
      child: OceanGlassCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PromotionList extends StatelessWidget {
  final PartnerState partner;
  final PartnerPromotionsState promotions;
  final bool compact;

  const _PromotionList({
    required this.partner,
    required this.promotions,
    required this.compact,
  });

  /// `PartnerPromotionService` applies **no** `PartnerTeamRole` check — it
  /// resolves the caller with `partnerProfileRepo.findByUserId`, so only the
  /// profile owner reaches these endpoints. Gating on OWNER mirrors that;
  /// unknown fails closed. UX only — the backend re-checks every request.
  bool get _canEdit => partner.teamRole == PartnerTeamRole.owner;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = promotions.promotions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_canEdit) ...[
          PartnerPromotionNotice(message: l10n.partnerPromotionsOwnerOnly),
          const SizedBox(height: AppSpacing.sm),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = AppSpacing.sm;
            final columns =
                compact ? 1 : (constraints.maxWidth / 340).floor().clamp(1, 3);
            final width =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final promotion in items)
                  SizedBox(
                    width: width,
                    child: PartnerPromotionCard(
                      promotion: promotion,
                      targetRoomName: promotions.roomNameFor(promotion),
                      open: promotions.openPromotionId == promotion.id,
                      actionPending: promotions.pendingActionId == promotion.id,
                      onOpen: () =>
                          promotions.openPromotionDetail(promotion.id),
                      onToggleActive:
                          _canEdit ? () => _toggle(context, promotion) : null,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _toggle(BuildContext context, PartnerPromotion promotion) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final result =
        await promotions.setActive(promotion.id, active: !promotion.active);
    if (!context.mounted) return;

    final message = switch (result) {
      PartnerPromotionActionResult.success => promotion.active
          ? l10n.partnerPromotionDeactivatedMessage(promotion.name)
          : l10n.partnerPromotionActivatedMessage(promotion.name),
      PartnerPromotionActionResult.unauthorized =>
        l10n.partnerDashboardErrorUnauthorized,
      PartnerPromotionActionResult.forbidden =>
        l10n.partnerDashboardErrorForbidden,
      PartnerPromotionActionResult.notFound =>
        l10n.partnerPromotionActionNotFound,
      PartnerPromotionActionResult.conflict =>
        l10n.partnerPromotionActionConflict,
      PartnerPromotionActionResult.validation =>
        l10n.partnerPromotionActionValidation,
      PartnerPromotionActionResult.notRoundTrippable =>
        l10n.partnerPromotionActionIncomplete,
      PartnerPromotionActionResult.uncertain =>
        l10n.partnerPropertyActionUncertain,
      PartnerPromotionActionResult.failed => l10n.partnerPropertyActionFailed,
    };
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PromotionDetailPanel extends StatelessWidget {
  final PartnerPromotionsState promotions;
  final PartnerPromotion promotion;

  const _PromotionDetailPanel({
    required this.promotions,
    required this.promotion,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final f = PartnerPromotionFormats.of(context);

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.partnerPromotionDetailHeading,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: promotions.closeDetail,
                icon: const Icon(Icons.close_rounded),
                tooltip: l10n.partnerPromotionCloseDetail,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            promotion.name,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          PartnerPropertySection(
            title: l10n.partnerPromotionSectionIdentity,
            children: [
              PartnerPropertyField(
                  label: l10n.partnerPromotionFieldCode, value: promotion.code),
              PartnerPropertyField(
                  label: l10n.partnerPromotionFieldDescription,
                  value: promotion.description),
              PartnerPropertyField(
                label: l10n.partnerPromotionFieldType,
                value: partnerPromotionTypeLabel(l10n, promotion.promotionType),
              ),
            ],
          ),
          PartnerPropertySection(
            title: l10n.partnerPromotionSectionDiscount,
            children: [
              PartnerPropertyField(
                label: l10n.partnerPromotionFieldDiscountType,
                value: partnerDiscountTypeLabel(l10n, promotion.discountType),
              ),
              PartnerPropertyField(
                label: l10n.partnerPromotionFieldDiscountValue,
                value: promotion.discountValue == null
                    ? null
                    : promotion.isPercentage
                        ? '${f.decimal.format(promotion.discountValue)}%'
                        : f.amount.format(promotion.discountValue),
              ),
              // A cap only means anything on a percentage discount.
              if (promotion.isPercentage)
                PartnerPropertyField(
                  label: l10n.partnerPromotionFieldMaxDiscount,
                  value: promotion.maxDiscountAmount == null
                      ? null
                      : f.amount.format(promotion.maxDiscountAmount),
                ),
            ],
          ),
          PartnerPropertySection(
            title: l10n.partnerPromotionSectionValidity,
            children: [
              PartnerPropertyField(
                label: l10n.partnerPromotionFieldStart,
                value: promotion.startDate == null
                    ? null
                    : f.date.format(promotion.startDate!),
              ),
              PartnerPropertyField(
                label: l10n.partnerPromotionFieldEnd,
                value: promotion.endDate == null
                    ? null
                    : f.date.format(promotion.endDate!),
              ),
            ],
          ),
          PartnerPropertySection(
            title: l10n.partnerPromotionSectionConditions,
            children: [
              PartnerPropertyField(
                label: l10n.partnerPromotionFieldMinimumStay,
                value: promotion.minimumStay == null
                    ? null
                    : l10n.partnerRateNightsValue(
                        f.integer.format(promotion.minimumStay)),
              ),
              PartnerPropertyField(
                label: l10n.partnerPromotionFieldMinimumSpend,
                value: promotion.minimumSpend == null
                    ? null
                    : f.amount.format(promotion.minimumSpend),
              ),
            ],
          ),
          PartnerPropertySection(
            title: l10n.partnerPromotionSectionApplication,
            children: [
              PartnerPropertyField(
                label: l10n.partnerPromotionFieldTarget,
                value: partnerPromotionTargetLabel(
                  l10n,
                  promotion.targetType,
                  promotions.roomNameFor(promotion),
                  promotion.targetId,
                ),
              ),
              PartnerPropertyField(
                label: l10n.partnerPromotionFieldPriority,
                value: f.integer.format(promotion.priority),
              ),
              PartnerPropertyField(
                label: l10n.partnerPromotionFieldStackable,
                value: promotion.stackable
                    ? l10n.partnerRoomYes
                    : l10n.partnerRoomNo,
              ),
              // Explains the engine's own rule rather than re-implementing it.
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xxs),
                child: Text(
                  promotion.stackable
                      ? l10n.partnerPromotionStackableNote
                      : l10n.partnerPromotionNonStackableNote,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: AppColors.textTertiary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The pricing engine's own breakdown — which promotions actually apply to a
/// stay, and what they take off. This is the one partner payload that carries a
/// currency, so amounts here are qualified.
class _PricingPreviewCard extends StatefulWidget {
  final PartnerPromotionsState promotions;

  const _PricingPreviewCard({required this.promotions});

  @override
  State<_PricingPreviewCard> createState() => _PricingPreviewCardState();
}

class _PricingPreviewCardState extends State<_PricingPreviewCard> {
  int? _roomId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final promotions = widget.promotions;
    final rooms = promotions.rooms;

    if (rooms.isEmpty) return const SizedBox.shrink();
    final selected = _roomId ?? rooms.first.id;

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.partnerPromotionPreviewHeading,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.partnerPromotionPreviewNote,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final room in rooms)
                ChoiceChip(
                  label: Text(room.roomName,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  selected: selected == room.id,
                  onSelected: promotions.isPreviewLoading
                      ? null
                      : (_) => setState(() => _roomId = room.id),
                  labelStyle: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: selected == room.id
                        ? AppColors.textInverse
                        : AppColors.textPrimary,
                  ),
                  selectedColor: AppColors.ocean700,
                  backgroundColor: AppColors.surfaceMuted,
                  showCheckmark: false,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OceanSecondaryButton(
              label: l10n.partnerPromotionPreviewAction,
              icon: Icons.calculate_outlined,
              fullWidth: false,
              onPressed: promotions.isPreviewLoading
                  ? null
                  : () {
                      final today = DateTime.now();
                      final from = DateTime(today.year, today.month, today.day)
                          .add(const Duration(days: 7));
                      promotions.runPreview(
                        roomId: selected,
                        checkIn: from,
                        checkOut: from.add(const Duration(days: 3)),
                      );
                    },
            ),
          ),
          if (promotions.isPreviewLoading) ...[
            const SizedBox(height: AppSpacing.md),
            const Center(child: CircularProgressIndicator()),
          ] else if (promotions.previewErrorKind != null) ...[
            const SizedBox(height: AppSpacing.sm),
            PartnerPromotionNotice(
              message: _previewError(l10n, promotions.previewErrorKind),
              warning: true,
            ),
          ] else if (promotions.preview != null) ...[
            const SizedBox(height: AppSpacing.md),
            PartnerPricingBreakdownView(preview: promotions.preview!),
          ],
        ],
      ),
    );
  }

  String _previewError(AppLocalizations l10n, ApiErrorKind? kind) =>
      switch (kind) {
        ApiErrorKind.unauthorized => l10n.partnerDashboardErrorUnauthorized,
        ApiErrorKind.forbidden => l10n.partnerDashboardErrorForbidden,
        ApiErrorKind.notFound => l10n.partnerPromotionActionNotFound,
        ApiErrorKind.validation => l10n.partnerPromotionPreviewInvalidRange,
        ApiErrorKind.timeout => l10n.partnerDashboardErrorTimeout,
        ApiErrorKind.network => l10n.partnerDashboardErrorNetwork,
        _ => l10n.partnerDashboardErrorGeneric,
      };
}

/// The booking-voucher check — read-only, no check-in.
class _VoucherCheckTab extends StatefulWidget {
  final PartnerVouchersState vouchers;

  const _VoucherCheckTab({required this.vouchers});

  @override
  State<_VoucherCheckTab> createState() => _VoucherCheckTabState();
}

class _VoucherCheckTabState extends State<_VoucherCheckTab> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.vouchers.payload);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final vouchers = widget.vouchers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OceanGlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.partnerVoucherCheckHeading,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              // Says plainly that this is not a discount voucher, so the two
              // domains are never confused.
              Text(
                l10n.partnerVoucherCheckNote,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: AppColors.textTertiary),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _controller,
                onChanged: vouchers.setPayload,
                minLines: 1,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.partnerVoucherCheckField,
                  hintText: 'PYT-V1.<bookingCode>.<signature>',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  isDense: true,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  OceanPrimaryButton(
                    label: l10n.partnerVoucherCheckAction,
                    fullWidth: false,
                    onPressed:
                        vouchers.canSubmit ? () => vouchers.verify() : null,
                  ),
                  OceanSecondaryButton(
                    label: l10n.partnerVoucherCheckClear,
                    fullWidth: false,
                    onPressed: vouchers.isChecking
                        ? null
                        : () {
                            _controller.clear();
                            vouchers.clear();
                          },
                  ),
                ],
              ),
              if (vouchers.isChecking) ...[
                const SizedBox(height: AppSpacing.md),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
        if (!vouchers.isChecking &&
            vouchers.status != PartnerVoucherCheckStatus.idle) ...[
          const SizedBox(height: AppSpacing.md),
          PartnerVoucherResultCard(
            status: vouchers.status,
            result: vouchers.result,
            errorMessage: vouchers.errorMessage,
          ),
        ],
      ],
    );
  }
}
