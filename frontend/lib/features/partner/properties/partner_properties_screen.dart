import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import '../../../core/partner/partner_models.dart';
import '../../../core/partner/partner_property_models.dart';
import '../../../core/partner/partner_state.dart';
import '../../../design/app_breakpoints.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/glass_widgets.dart';
import '../widgets/partner_state_views.dart';
import 'partner_properties_state.dart';
import 'widgets/partner_property_widgets.dart';

/// The Partner Properties module — the workspace's inventory context.
///
/// ## Backend contract (verified in `backend-v1`/`develop`)
///
/// | Action | Endpoint |
/// |---|---|
/// | List | `GET /api/partner/hotels` → `PartnerHotelSummaryResponse[]` |
/// | Detail | `GET /api/partner/hotels/{id}` → `PartnerHotelResponse` |
/// | Publish listing | `PATCH /api/partner/hotels/{id}/activate` |
/// | Withdraw listing | `PATCH /api/partner/hotels/{id}/deactivate` |
///
/// There is **no create and no delete**: properties are assigned to a partner
/// by an admin (`PartnerPropertyService.assignOwner`). No "Add property"
/// affordance appears here, because the API behind it does not exist.
///
/// The four `PUT` edit endpoints (basic info, contact, policies, location) are
/// deliberately **not** wired in C2 — an editing surface needs its own form
/// validation, slug-conflict (409) handling and time pickers, and shipping a
/// half-built one would be worse than shipping none. Everything here is
/// read-only apart from the two atomic listing toggles.
///
/// ## Isolation
///
/// Every field displayed comes from a response the backend produced for *this*
/// caller. `PartnerPropertyService.ownedPlaceOrThrow` resolves through
/// `findByIdAndOwnerId`, returning a uniform 404 for an unknown id and for a
/// real property owned by someone else — so this screen can never be pointed at
/// another partner's data, and it never asks for an id the list did not return.
class PartnerPropertiesScreen extends StatefulWidget {
  const PartnerPropertiesScreen({super.key});

  @override
  State<PartnerPropertiesScreen> createState() =>
      _PartnerPropertiesScreenState();
}

class _PartnerPropertiesScreenState extends State<PartnerPropertiesScreen> {
  PartnerPropertiesState? _properties;
  PartnerState? _partner;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final partner = PartnerScope.of(context);
    if (identical(partner, _partner)) return;
    _partner = partner;
    _properties?.dispose();
    final properties = PartnerPropertiesState(api: partner.api);
    _properties = properties;
    if (partner.isReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) properties.load(partner);
      });
    }
  }

  @override
  void dispose() {
    _properties?.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final partner = _partner;
    final properties = _properties;
    if (partner == null || properties == null) return;
    await properties.load(partner);
  }

  @override
  Widget build(BuildContext context) {
    final partner = PartnerScope.of(context);
    final properties = _properties;

    if (!partner.isReady || properties == null) {
      return PartnerWorkspaceStatusView(
        status: partner.status,
        detail: partner.errorMessage,
      );
    }

    return AnimatedBuilder(
      animation: properties,
      builder: (context, _) => _PropertiesBody(
        partner: partner,
        properties: properties,
        onReload: _reload,
      ),
    );
  }
}

class _PropertiesBody extends StatelessWidget {
  final PartnerState partner;
  final PartnerPropertiesState properties;
  final Future<void> Function() onReload;

  const _PropertiesBody({
    required this.partner,
    required this.properties,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // A list-level failure is the whole module's condition — render it once,
    // mapped to the same workspace vocabulary the rest of the extranet uses.
    if (!properties.isLoading && !properties.isReady) {
      return PartnerWorkspaceStatusView(
        status: switch (properties.status) {
          PartnerPropertiesStatus.unauthorized =>
            PartnerWorkspaceStatus.unauthorized,
          PartnerPropertiesStatus.forbidden => PartnerWorkspaceStatus.forbidden,
          PartnerPropertiesStatus.noProfile =>
            PartnerWorkspaceStatus.onboardingRequired,
          _ => PartnerWorkspaceStatus.error,
        },
        detail: properties.errorMessage,
        onPrimaryAction: properties.isRetryable ? onReload : null,
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= AppBreakpoints.desktop;
    final detailOpen = properties.openPropertyId != null;

    final list = _PropertyList(
      partner: partner,
      properties: properties,
      // On a narrow screen the detail replaces the list rather than stacking
      // below it, so the two never compete for the same short viewport.
      compact: isWide && detailOpen,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PropertiesHeader(properties: properties, onReload: onReload),
        const SizedBox(height: AppSpacing.md),
        if (properties.isLoading)
          const _PropertiesLoading()
        else if (properties.isEmpty)
          _PropertiesEmpty(l10n: l10n)
        else if (isWide && detailOpen)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: list),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 3,
                child: _PropertyDetailPanel(
                  partner: partner,
                  properties: properties,
                  onReload: onReload,
                ),
              ),
            ],
          )
        else if (detailOpen)
          _PropertyDetailPanel(
            partner: partner,
            properties: properties,
            onReload: onReload,
          )
        else
          list,
      ],
    );
  }
}

class _PropertiesHeader extends StatelessWidget {
  final PartnerPropertiesState properties;
  final Future<void> Function() onReload;

  const _PropertiesHeader({required this.properties, required this.onReload});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.partnerNavHotels,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  properties.isLoading
                      ? l10n.partnerStatusLoadingTitle
                      : l10n
                          .partnerPropertiesCount(properties.properties.length),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: properties.isLoading ? null : onReload,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.partnerActionRefresh,
          ),
        ],
      ),
    );
  }
}

class _PropertiesLoading extends StatelessWidget {
  const _PropertiesLoading();

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
                  height: 56,
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

/// Zero properties is a legitimate answer, and is deliberately worded to be
/// unmistakable from "your partner profile is not approved" — which the
/// workspace-level view owns and which reaches the user through an entirely
/// different screen.
class _PropertiesEmpty extends StatelessWidget {
  final AppLocalizations l10n;

  const _PropertiesEmpty({required this.l10n});

  @override
  Widget build(BuildContext context) => OceanStateView(
        icon: Icons.apartment_outlined,
        title: l10n.partnerPropertiesEmptyTitle,
        message: l10n.partnerPropertiesEmptyMessage,
        semanticLabel: l10n.partnerPropertiesEmptyTitle,
      );
}

class _PropertyList extends StatelessWidget {
  final PartnerState partner;
  final PartnerPropertiesState properties;
  final bool compact;

  const _PropertyList({
    required this.partner,
    required this.properties,
    required this.compact,
  });

  /// Listing actions mirror the backend rule and nothing looser.
  ///
  /// `PartnerPropertyService` applies **no** `PartnerTeamRole` check at all —
  /// it resolves the caller with `partnerProfileRepo.findByUserId`, so only the
  /// profile owner can reach these endpoints; a team member gets 404 and never
  /// arrives here. Gating the affordance on OWNER therefore mirrors reality,
  /// and an unknown role fails closed. It is UX only: the backend re-checks.
  bool get _canAct => partner.teamRole == PartnerTeamRole.owner;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = properties.properties;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_canAct) ...[
          _RoleNotice(message: l10n.partnerPropertyActionsOwnerOnly),
          const SizedBox(height: AppSpacing.sm),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            // One column when the detail panel is sharing the row, otherwise as
            // many as fit. Wrap keeps large text scales from clipping.
            const spacing = AppSpacing.sm;
            final columns =
                compact ? 1 : (constraints.maxWidth / 320).floor().clamp(1, 3);
            final width =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final property in items)
                  SizedBox(
                    width: width,
                    child: PartnerPropertyCard(
                      property: property,
                      selected: partner.selectedPropertyId == property.id,
                      open: properties.openPropertyId == property.id,
                      actionPending:
                          properties.pendingActionPropertyId == property.id,
                      onOpen: () =>
                          properties.openProperty(partner, property.id),
                      onToggleActive:
                          _canAct ? () => _toggle(context, property) : null,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _toggle(BuildContext context, PartnerProperty property) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final result = await properties.setActive(
      property.id,
      activate: !property.active,
    );
    if (!context.mounted) return;

    // Never report a success the server did not confirm.
    final message = switch (result) {
      PartnerPropertyActionResult.success => property.active
          ? l10n.partnerPropertyDeactivatedMessage(property.name)
          : l10n.partnerPropertyActivatedMessage(property.name),
      PartnerPropertyActionResult.unauthorized =>
        l10n.partnerDashboardErrorUnauthorized,
      PartnerPropertyActionResult.forbidden =>
        l10n.partnerDashboardErrorForbidden,
      PartnerPropertyActionResult.notFound =>
        l10n.partnerPropertyActionNotFound,
      PartnerPropertyActionResult.uncertain =>
        l10n.partnerPropertyActionUncertain,
      PartnerPropertyActionResult.failed => l10n.partnerPropertyActionFailed,
    };
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}

class _RoleNotice extends StatelessWidget {
  final String message;

  const _RoleNotice({required this.message});

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppSpacing.sm),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 16, color: AppColors.textTertiary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      );
}

/// `GET /api/partner/hotels/{id}` rendered in sections, each backed by real DTO
/// fields. No section is invented, and none is editable — the four `PUT`
/// endpoints are out of C2 scope, so showing a text field here would be a form
/// that cannot save.
class _PropertyDetailPanel extends StatelessWidget {
  final PartnerState partner;
  final PartnerPropertiesState properties;
  final Future<void> Function() onReload;

  const _PropertyDetailPanel({
    required this.partner,
    required this.properties,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.partnerPropertyDetailHeading,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: properties.closeDetail,
                icon: const Icon(Icons.close_rounded),
                tooltip: l10n.partnerPropertyCloseDetail,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (properties.isDetailLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (properties.hasDetailError)
            _DetailError(properties: properties, partner: partner)
          else if (properties.detail != null)
            _DetailContent(detail: properties.detail!)
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  final PartnerPropertiesState properties;
  final PartnerState partner;

  const _DetailError({required this.properties, required this.partner});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final kind = properties.detailErrorKind;
    // A 404 here means the property is unknown *or* not owned — the backend
    // does not distinguish them and neither may this message.
    final text = switch (kind) {
      ApiErrorKind.unauthorized => l10n.partnerDashboardErrorUnauthorized,
      ApiErrorKind.forbidden => l10n.partnerDashboardErrorForbidden,
      ApiErrorKind.notFound => l10n.partnerPropertyDetailNotFound,
      ApiErrorKind.timeout => l10n.partnerDashboardErrorTimeout,
      ApiErrorKind.network => l10n.partnerDashboardErrorNetwork,
      ApiErrorKind.server => l10n.partnerDashboardErrorServer,
      _ => l10n.partnerDashboardErrorGeneric,
    };

    return Semantics(
      container: true,
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 18, color: AppColors.danger),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    text,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            if (properties.detailErrorMessage != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                properties.detailErrorMessage!,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.textTertiary),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            OceanSecondaryButton(
              label: AppLocalizations.of(context)!.partnerActionRetry,
              icon: Icons.refresh_rounded,
              fullWidth: false,
              onPressed: () {
                final id = properties.openPropertyId;
                if (id != null) properties.openProperty(partner, id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  final PartnerPropertyDetail detail;

  const _DetailContent({required this.detail});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final dateFmt = DateFormat.yMMMd(locale).add_Hm();
    final numFmt = NumberFormat('#,##0.0', locale);
    final coordFmt = NumberFormat('#,##0.0####', locale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          detail.name,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xxs,
          children: [
            PartnerPropertyStatusPill(status: detail.status),
            OceanStatusPill(
              label: detail.active
                  ? l10n.partnerPropertyActive
                  : l10n.partnerPropertyInactive,
              color: detail.active ? AppColors.success : AppColors.textTertiary,
              icon: detail.active
                  ? Icons.toggle_on_rounded
                  : Icons.toggle_off_outlined,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        // Says plainly whether guests can see this listing right now, combining
        // the two independent backend flags rather than leaving the reader to.
        Text(
          detail.active && detail.status.isPubliclyVisible
              ? l10n.partnerPropertyVisibilityPublic
              : l10n.partnerPropertyVisibilityNotPublic,
          style: theme.textTheme.bodySmall?.copyWith(
            color: detail.active && detail.status.isPubliclyVisible
                ? AppColors.success
                : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        PartnerPropertySection(
          title: l10n.partnerPropertySectionIdentity,
          children: [
            PartnerPropertyField(
                label: l10n.partnerPropertyFieldSlug, value: detail.slug),
            PartnerPropertyField(
              label: l10n.partnerPropertyFieldShortDescription,
              value: detail.shortDescription,
            ),
            PartnerPropertyField(
              label: l10n.partnerPropertyFieldDescription,
              value: detail.description,
            ),
          ],
        ),

        PartnerPropertySection(
          title: l10n.partnerPropertySectionLocation,
          children: [
            PartnerPropertyField(
                label: l10n.partnerPropertyFieldAddress, value: detail.address),
            PartnerPropertyField(
              label: l10n.partnerPropertyFieldCoordinates,
              // Only render a coordinate pair when both axes are present; one
              // axis is not a location.
              value: detail.hasCoordinates
                  ? '${coordFmt.format(detail.latitude)}, '
                      '${coordFmt.format(detail.longitude)}'
                  : null,
            ),
          ],
        ),

        PartnerPropertySection(
          title: l10n.partnerPropertySectionContact,
          children: [
            PartnerPropertyField(
                label: l10n.partnerPropertyFieldPhone, value: detail.phone),
            PartnerPropertyField(
                label: l10n.partnerPropertyFieldEmail, value: detail.email),
            PartnerPropertyField(
                label: l10n.partnerPropertyFieldWebsite, value: detail.website),
            PartnerPropertyField(
                label: l10n.partnerPropertyFieldFacebook,
                value: detail.facebook),
            PartnerPropertyField(
                label: l10n.partnerPropertyFieldInstagram,
                value: detail.instagram),
          ],
        ),

        PartnerPropertySection(
          title: l10n.partnerPropertySectionPolicies,
          children: [
            PartnerPropertyField(
                label: l10n.partnerPropertyFieldCheckIn, value: detail.checkIn),
            PartnerPropertyField(
                label: l10n.partnerPropertyFieldCheckOut,
                value: detail.checkOut),
            PartnerPropertyField(
              label: l10n.partnerPropertyFieldChildrenPolicy,
              value: detail.childrenPolicy,
            ),
            PartnerPropertyField(
                label: l10n.partnerPropertyFieldPetPolicy,
                value: detail.petPolicy),
            PartnerPropertyField(
              label: l10n.partnerPropertyFieldSmokingPolicy,
              value: detail.smokingPolicy,
            ),
          ],
        ),

        PartnerPropertySection(
          title: l10n.partnerPropertySectionVerification,
          children: [
            PartnerPropertyField(
              label: l10n.partnerPropertyFieldVerified,
              value: detail.verified
                  ? l10n.partnerPropertyVerified
                  : l10n.partnerPropertyNotVerified,
            ),
            PartnerPropertyField(
              label: l10n.partnerPropertyFieldFeatured,
              value: detail.featured
                  ? l10n.partnerPropertyFeatured
                  : l10n.partnerPropertyNotFeatured,
            ),
            // Both flags are admin-owned; PartnerPropertyTest asserts the
            // partner cannot change either. Saying so prevents the reader from
            // hunting for a control that will never exist here.
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxs),
              child: Text(
                l10n.partnerPropertyModerationNote,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: AppColors.textTertiary),
              ),
            ),
          ],
        ),

        PartnerPropertySection(
          title: l10n.partnerPropertySectionPerformance,
          children: [
            PartnerPropertyField(
              label: l10n.partnerPropertyFieldRating,
              value: detail.reviewCount == 0
                  ? null
                  : numFmt.format(detail.ratingAvg),
            ),
            PartnerPropertyField(
              label: l10n.partnerPropertyFieldReviewCount,
              value: NumberFormat('#,##0', locale).format(detail.reviewCount),
            ),
          ],
        ),

        PartnerPropertySection(
          title: l10n.partnerPropertySectionMetadata,
          children: [
            PartnerPropertyField(
              label: l10n.partnerPropertyFieldOwner,
              value: detail.ownerBusinessName,
            ),
            PartnerPropertyField(
              label: l10n.partnerPropertyFieldCreated,
              value: detail.createdAt == null
                  ? null
                  : dateFmt.format(detail.createdAt!),
            ),
            PartnerPropertyField(
              label: l10n.partnerPropertyFieldUpdated,
              value: detail.updatedAt == null
                  ? null
                  : dateFmt.format(detail.updatedAt!),
            ),
          ],
        ),
      ],
    );
  }
}
