import 'package:flutter/material.dart';

import '../../../core/admin/admin_models.dart';
import '../../../design/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/glass_widgets.dart';
import '../admin_catalog_states.dart';
import '../widgets/admin_widgets.dart';

/// One place: identity, lifecycle, rooms and a read-only gallery.
///
/// **No place editor.** `PUT /api/admin/places/{id}` exists, but it is a
/// destructive full replace — it deletes every tag, opening hour and amenity and
/// rebuilds them from the request body. A form that did not round-trip all three
/// perfectly would silently delete them, and the detail response does not return
/// them in the shape the request wants. So the writable surface here is exactly
/// the three targeted mutations the backend offers safely: status, verified and
/// featured.
///
/// **No media mutations.** The gallery is read-only; media management is D3C-B.
class AdminPlaceDetailScreen extends StatelessWidget {
  final AdminPlaceDetailState state;
  final VoidCallback onBack;

  /// D3D — opens this place's media gallery. Optional: the screen is still
  /// complete without it, and the gallery card stays read-only when no handler
  /// is supplied, so nothing here implies an action the host cannot perform.
  final VoidCallback? onManageMedia;

  const AdminPlaceDetailScreen({
    super.key,
    required this.state,
    required this.onBack,
    this.onManageMedia,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        if (!state.isReady) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BackBar(onBack: onBack, title: l10n.adminNavCatalog),
              Expanded(
                child: state.isNotFound
                    ? Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: OceanEmptyState(
                            title: l10n.adminCatalogNotFoundTitle,
                            message: l10n.adminCatalogNotFoundMessage,
                          ),
                        ),
                      )
                    : AdminStateView(
                        status: state.status,
                        message: state.error,
                        onRetry: state.refresh,
                      ),
              ),
            ],
          );
        }

        final place = state.place!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BackBar(
              onBack: onBack,
              title: place.name ?? l10n.adminValueUnknown,
              trailing: AdminStatusChip(status: place.status.wire),
            ),
            if (state.mutationUncertain)
              _Banner(
                  tone: _BannerTone.warning,
                  message: l10n.adminCatalogActionUncertain),
            if (state.mutationError != null && !state.mutationUncertain)
              _Banner(tone: _BannerTone.error, message: state.mutationError!),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _LifecycleCard(state: state),
                  const SizedBox(height: AppSpacing.sm),
                  _FlagsCard(state: state),
                  const SizedBox(height: AppSpacing.sm),
                  _IdentityCard(place: place),
                  const SizedBox(height: AppSpacing.sm),
                  _RoomsCard(state: state),
                  const SizedBox(height: AppSpacing.sm),
                  _GalleryCard(place: place, onManageMedia: onManageMedia),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BackBar extends StatelessWidget {
  final VoidCallback onBack;
  final String title;
  final Widget? trailing;

  const _BackBar({required this.onBack, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm, AppSpacing.sm, AppSpacing.md, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: l10n.adminCatalogBackToList,
            onPressed: onBack,
          ),
          Expanded(
            child: Text(title,
                style: Theme.of(context).textTheme.titleMedium,
                overflow: TextOverflow.ellipsis),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.xs),
            trailing!,
          ],
        ],
      ),
    );
  }
}

enum _BannerTone { warning, error }

class _Banner extends StatelessWidget {
  final _BannerTone tone;
  final String message;

  const _Banner({required this.tone, required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = tone == _BannerTone.warning
        ? scheme.tertiaryContainer
        : scheme.errorContainer;
    final fg = tone == _BannerTone.warning
        ? scheme.onTertiaryContainer
        : scheme.onErrorContainer;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.xs, AppSpacing.md, 0),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
              tone == _BannerTone.warning
                  ? Icons.help_outline
                  : Icons.error_outline,
              size: 18,
              color: fg),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(message,
                style:
                    Theme.of(context).textTheme.bodySmall?.copyWith(color: fg)),
          ),
        ],
      ),
    );
  }
}

/// Offers exactly the transitions the backend's own table allows from the
/// current state — anything else answers 400, so no button is drawn for it.
/// ARCHIVED gets the destructive treatment because nothing leaves it.
class _LifecycleCard extends StatelessWidget {
  final AdminPlaceDetailState state;

  const _LifecycleCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final allowed = state.allowedTransitions;

    return OceanGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.adminCatalogSectionLifecycle,
                style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            AdminCardRow(
                label: l10n.adminFilterStatus,
                value: state.placeStatus.wire,
                emphasise: true),
            AdminCardRow(
              label: l10n.adminCatalogPublicVisibility,
              value: state.placeStatus.isPubliclyVisible
                  ? l10n.adminCatalogVisibleToGuests
                  : l10n.adminCatalogHiddenFromGuests,
            ),
            const SizedBox(height: AppSpacing.xs),
            if (state.placeStatus.isTerminal)
              Text(l10n.adminCatalogArchivedNotice,
                  style:
                      theme.textTheme.bodySmall?.copyWith(color: scheme.error))
            else if (allowed.isEmpty)
              Text(l10n.adminCatalogNoTransitions,
                  style: theme.textTheme.bodySmall)
            else
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final target in allowed)
                    if (target.isTerminal)
                      OutlinedButton.icon(
                        onPressed: state.isMutating
                            ? null
                            : () => _confirmArchive(context),
                        icon: const Icon(Icons.inventory_2_outlined, size: 18),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: scheme.error,
                          side: BorderSide(color: scheme.error),
                        ),
                        label: Text(l10n.adminCatalogArchive),
                      )
                    else
                      FilledButton.tonal(
                        onPressed: state.isMutating
                            ? null
                            : () => state.changeStatus(target),
                        child: Text(target.wire),
                      ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmArchive(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => const _ArchiveDialog(),
    );
    if (ok == true) await state.changeStatus(AdminPlaceStatus.archived);
  }
}

/// Archiving is the one irreversible action in the catalog: every state can
/// reach ARCHIVED and nothing leaves it, so there is no restore control anywhere
/// in this console — because there is no endpoint for one to call.
class _ArchiveDialog extends StatefulWidget {
  const _ArchiveDialog();

  @override
  State<_ArchiveDialog> createState() => _ArchiveDialogState();
}

class _ArchiveDialogState extends State<_ArchiveDialog> {
  bool _acknowledged = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, color: scheme.error),
      title: Text(l10n.adminCatalogArchiveTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Bullet(text: l10n.adminCatalogArchiveWarningIrreversible),
            _Bullet(text: l10n.adminCatalogArchiveWarningVisibility),
            _Bullet(text: l10n.adminCatalogArchiveWarningRooms),
            const SizedBox(height: AppSpacing.xs),
            CheckboxListTile(
              value: _acknowledged,
              onChanged: (v) => setState(() => _acknowledged = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.adminCatalogArchiveAcknowledge,
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.adminPartnerCancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: scheme.error),
          onPressed:
              _acknowledged ? () => Navigator.of(context).pop(true) : null,
          child: Text(l10n.adminCatalogArchiveConfirm),
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;

  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('•  '),
            Expanded(
                child:
                    Text(text, style: Theme.of(context).textTheme.bodySmall)),
          ],
        ),
      );
}

/// Verified and featured. The backend refuses to set either **true** outside
/// APPROVED/PUBLISHED, so the switch is disabled in every other state — with the
/// reason stated, rather than a control that silently fails.
class _FlagsCard extends StatelessWidget {
  final AdminPlaceDetailState state;

  const _FlagsCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final place = state.place!;
    final canSetTrue = state.placeStatus.canSetFlagsTrue;

    return OceanGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.adminCatalogSectionFlags,
                style: Theme.of(context).textTheme.titleSmall),
            // A ListTile paints its ink on the nearest Material ancestor, and
            // the glass card is a DecoratedBox with its own gradient in
            // between — so the splash would land underneath the card and never
            // be seen. A transparent Material of their own puts the ink back on
            // top without adding a second visible surface.
            Material(
              type: MaterialType.transparency,
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.adminCatalogFilterVerified),
                    value: place.verified,
                    onChanged:
                        state.isMutating || (!place.verified && !canSetTrue)
                            ? null
                            : (v) => state.setVerified(v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.adminCatalogFilterFeatured),
                    value: place.featured,
                    onChanged:
                        state.isMutating || (!place.featured && !canSetTrue)
                            ? null
                            : (v) => state.setFeatured(v),
                  ),
                ],
              ),
            ),
            if (!canSetTrue)
              Text(l10n.adminCatalogFlagsRequireApproved,
                  style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

/// Read-only identity. Every field here comes from `PlaceDetailResponse`; none
/// is editable because there is no safe partial-update endpoint.
class _IdentityCard extends StatelessWidget {
  final AdminPlaceDetail place;

  const _IdentityCard({required this.place});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.adminCatalogSectionIdentity,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            AdminCardRow(
                label: l10n.adminCatalogColName,
                value: AdminFormats.text(context, place.name),
                emphasise: true),
            AdminCardRow(
                label: l10n.adminCatalogColCategory,
                value: AdminFormats.text(context, place.category?.name)),
            AdminCardRow(
                label: l10n.adminCatalogColLocation,
                value: AdminFormats.text(context, place.location?.name)),
            AdminCardRow(
                label: l10n.adminPartnerAddress,
                value: AdminFormats.text(context, place.address)),
            AdminCardRow(
                label: l10n.adminCatalogColRating,
                value: '${place.ratingAvg} (${place.ratingCount})'),
            AdminCardRow(
                label: l10n.adminCatalogPriceLevel,
                value: '${place.priceLevel}'),
            if (place.tags.isNotEmpty)
              AdminCardRow(
                  label: l10n.adminCatalogTags, value: place.tags.join(', ')),
            if (place.amenities.isNotEmpty)
              AdminCardRow(
                  label: l10n.adminCatalogAmenities,
                  value: place.amenities.join(', ')),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.adminCatalogReadOnlyNotice,
                style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

/// Rooms as a catalog relationship only. No inventory editor, no rate editor,
/// no booking controls — those are Admin Operations and Admin Commercial.
class _RoomsCard extends StatelessWidget {
  final AdminPlaceDetailState state;

  const _RoomsCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return OceanGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.adminCatalogSectionRooms,
                style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            if (state.roomsStatus == AdminLoadStatus.loading)
              const LinearProgressIndicator()
            else if (state.notAHotel)
              // The rooms endpoint answers 404 for a place with no hotel detail.
              // That is an ordinary catalog fact, not a failure.
              Text(l10n.adminCatalogNotAHotel, style: theme.textTheme.bodySmall)
            else if (state.roomsStatus != AdminLoadStatus.ready)
              Text(l10n.adminCatalogRoomsUnavailable,
                  style: theme.textTheme.bodySmall)
            else if (state.rooms.isEmpty)
              Text(l10n.adminCatalogRoomsEmpty,
                  style: theme.textTheme.bodySmall)
            else ...[
              for (final room in state.rooms)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                                AdminFormats.text(context, room.roomName),
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                          ),
                          AdminStatusChip(
                              status: room.active
                                  ? l10n.adminCatalogRoomActive
                                  : l10n.adminCatalogRoomInactive),
                        ],
                      ),
                      AdminCardRow(
                          label: l10n.adminCatalogRoomCode,
                          value: AdminFormats.text(context, room.roomCode)),
                      AdminCardRow(
                          label: l10n.adminCatalogRoomType,
                          value: AdminFormats.text(context, room.roomType)),
                      AdminCardRow(
                          label: l10n.adminCatalogRoomQuantity,
                          value: room.quantity == null
                              ? l10n.adminValueUnknown
                              : AdminFormats.count(room.quantity!)),
                    ],
                  ),
                ),
              Text(l10n.adminCatalogRoomsBoundaryNotice,
                  style: theme.textTheme.labelSmall),
            ],
          ],
        ),
      ),
    );
  }
}

/// Read-only gallery summary. Media management is D3C-B, and the D3B media
/// freeze keeps the URL out of any clickable affordance — it renders as text.
class _GalleryCard extends StatelessWidget {
  final AdminPlaceDetail place;
  final VoidCallback? onManageMedia;

  const _GalleryCard({required this.place, this.onManageMedia});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return OceanGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.adminCatalogSectionMedia,
                style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            AdminCardRow(
                label: l10n.adminCatalogMediaCount,
                value: AdminFormats.count(place.gallery.length)),
            AdminCardRow(
              label: l10n.adminCatalogMediaCover,
              value: place.coverImageUrl == null
                  ? l10n.adminCatalogMediaNoCover
                  : l10n.adminCatalogMediaHasCover,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.adminCatalogMediaReadOnlyNotice,
                style: theme.textTheme.labelSmall),
            if (onManageMedia != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Semantics(
                  // A node of its own that keeps its own label: annotating the
                  // button directly merges this name with the button's text
                  // into one string, and the control stops being addressable
                  // by the name that says which place it opens.
                  container: true,
                  explicitChildNodes: true,
                  label: l10n.adminCatalogManageMediaSemantic(
                      place.name ?? l10n.adminValueUnknown),
                  child: OutlinedButton.icon(
                    onPressed: onManageMedia,
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: Text(l10n.adminCatalogManageMedia),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
