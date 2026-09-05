import 'package:flutter/material.dart';

import '../../../core/admin/admin_models.dart';
import '../../../design/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/glass_widgets.dart';
import '../admin_media_states.dart';
import '../widgets/admin_widgets.dart';

/// Admin Media — a **URL registry** for one place's gallery.
///
/// Nothing here uploads a file: the backend's media API takes an absolute
/// http/https URL in a JSON body and stores it, so the console registers URLs.
/// There is no file picker, no multipart request and no progress indicator,
/// because there is no endpoint that would accept one.
///
/// The surface opens on a place picker rather than a list of galleries, because
/// the admin API has no "list all media" read — its only read is
/// `GET /api/admin/places/{placeId}/media`.
class AdminMediaScreen extends StatelessWidget {
  final AdminMediaState state;

  /// D3D — supplied when the gallery was opened from a place's detail screen,
  /// in which case "back" means that screen rather than the picker. Null when
  /// the destination was entered from the navigation rail, so the picker stays
  /// the correct way back and no navigation loop is created.
  final VoidCallback? onBackToPlace;

  const AdminMediaScreen({
    super.key,
    required this.state,
    this.onBackToPlace,
  });

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: state,
        builder: (context, _) => state.hasSelection
            ? _Gallery(state: state, onBackToPlace: onBackToPlace)
            : _PlacePicker(state: state),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// Owner selection
// ═══════════════════════════════════════════════════════════════════════════

class _PlacePicker extends StatefulWidget {
  final AdminMediaState state;

  const _PlacePicker({required this.state});

  @override
  State<_PlacePicker> createState() => _PlacePickerState();
}

class _PlacePickerState extends State<_PlacePicker> {
  late final TextEditingController _search =
      TextEditingController(text: widget.state.placeQuery);

  @override
  void initState() {
    super.initState();
    // Deferred to after the frame: searchPlaces notifies synchronously, and
    // notifying while the AnimatedBuilder above is still building trips the
    // framework's `!_dirty` assertion. The shell primes this too, so the
    // callback only fires when the screen is used on its own.
    if (widget.state.placeSearchStatus == AdminLoadStatus.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.state.placeSearchStatus == AdminLoadStatus.idle) {
          widget.state.searchPlaces('');
        }
      });
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = widget.state;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.adminMediaPickOwnerTitle,
                  style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xxs),
              // Said plainly rather than hidden: the admin API can only read a
              // place's gallery, so a place is the only owner this console can
              // manage from end to end.
              Text(l10n.adminMediaOwnerScopeNotice,
                  style: theme.textTheme.labelSmall),
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                textField: true,
                label: l10n.adminMediaPlaceSearchLabel,
                child: TextField(
                  controller: _search,
                  enabled: state.placeSearchStatus != AdminLoadStatus.loading,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: const Icon(Icons.search),
                    labelText: l10n.adminMediaPlaceSearchLabel,
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: l10n.adminMediaPlaceSearchClear,
                            onPressed: () {
                              _search.clear();
                              state.searchPlaces('');
                              setState(() {});
                            },
                          ),
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: state.searchPlaces,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                  l10n.adminMediaPlaceSearchHint(
                      AdminMediaState.placeOptionLimit),
                  style: theme.textTheme.labelSmall),
            ],
          ),
        ),
        Expanded(
          child: state.placeSearchStatus == AdminLoadStatus.ready &&
                  state.placeOptions.isNotEmpty
              ? ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: state.placeOptions.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (context, i) {
                    final place = state.placeOptions[i];
                    return Semantics(
                      button: true,
                      label: l10n.adminMediaOpenGallerySemantic(
                          place.name ?? l10n.adminValueUnknown),
                      child: OceanGlassCard(
                        child: Material(
                          type: MaterialType.transparency,
                          child: ListTile(
                            title: Text(AdminFormats.text(context, place.name)),
                            subtitle: Text(AdminFormats.text(
                                context, place.location?.name)),
                            trailing:
                                AdminStatusChip(status: place.status.wire),
                            onTap: () => state.selectPlace(place),
                          ),
                        ),
                      ),
                    );
                  },
                )
              : AdminStateView(
                  status: state.placeSearchStatus == AdminLoadStatus.ready
                      ? AdminLoadStatus.ready
                      : state.placeSearchStatus,
                  message: state.placeSearchError,
                  emptyMessage: l10n.adminMediaNoPlacesFound,
                  onRetry: () => state.searchPlaces(state.placeQuery),
                ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Gallery
// ═══════════════════════════════════════════════════════════════════════════

class _Gallery extends StatelessWidget {
  final AdminMediaState state;
  final VoidCallback? onBackToPlace;

  const _Gallery({required this.state, this.onBackToPlace});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final place = state.owner!;

    final body = state.ownerMismatch
        // Deliberately not the generic error card: the operator needs to know
        // the response did not match the gallery that was asked for, and that
        // nothing here may be acted on until it does.
        ? AdminStateView(
            status: AdminLoadStatus.error,
            message: l10n.adminMediaOwnerMismatch,
            onRetry: state.refresh,
          )
        : state.isReady && !state.isEmpty
            ? AdminResponsiveGrid(
                wide: (context) => _AssetList(state: state, wide: true),
                narrow: (context) => _AssetList(state: state, wide: false),
              )
            : AdminStateView(
                status: state.status,
                message: state.errorMessage,
                emptyTitle: l10n.adminMediaEmptyTitle,
                emptyMessage: l10n.adminMediaEmptyMessage,
                onRetry: state.refresh,
              );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm, AppSpacing.sm, AppSpacing.md, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: onBackToPlace == null
                    ? l10n.adminMediaBackToPlaces
                    : l10n.adminMediaBackToPlaceDetail,
                onPressed: state.isMutating
                    ? null
                    : (onBackToPlace ?? state.clearSelection),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(AdminFormats.text(context, place.name),
                        style: theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis),
                    // The id is the thing every request on this screen is
                    // actually bound to, so an operator can confirm at a glance
                    // which gallery they are editing.
                    Text(l10n.adminMediaOwnerContext(place.id),
                        style: theme.textTheme.labelSmall,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (state.mutationUncertain)
          _Banner(
            tone: _BannerTone.warning,
            message: l10n.adminMediaActionUncertain,
            onDismiss: state.dismissMutationNotice,
          ),
        if (state.mutationError != null && !state.mutationUncertain)
          _Banner(
            tone: _BannerTone.error,
            message: state.mutationError!,
            onDismiss: state.dismissMutationNotice,
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.xs, AppSpacing.md, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xxs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: state.isMutating
                        ? null
                        : () => _openCreate(context, state),
                    icon: const Icon(Icons.add_link, size: 18),
                    label: Text(l10n.adminMediaAdd),
                  ),
                  if (state.isReady)
                    Text(
                      state.coverAsset == null
                          ? l10n.adminMediaNoCoverNotice
                          : l10n.adminMediaCoverIs(state.coverAsset!.id),
                      style: theme.textTheme.labelSmall,
                    ),
                ],
              ),
              // A registry, not an uploader — stated where the operator is
              // about to add something, so the absence of a file picker reads
              // as the product's shape rather than a missing feature.
              const SizedBox(height: AppSpacing.xxs),
              Text(l10n.adminMediaUrlRegistryNotice,
                  style: theme.textTheme.labelSmall),
              if (state.isReady && state.hasAmbiguousOrder) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(l10n.adminMediaAmbiguousOrderNotice,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.error)),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Expanded(child: body),
      ],
    );
  }
}

class _AssetList extends StatelessWidget {
  final AdminMediaState state;
  final bool wide;

  const _AssetList({required this.state, required this.wide});

  @override
  Widget build(BuildContext context) => ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: state.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, i) =>
            _AssetCard(state: state, asset: state.items[i], wide: wide),
      );
}

class _AssetCard extends StatelessWidget {
  final AdminMediaState state;
  final AdminMediaAsset asset;
  final bool wide;

  const _AssetCard({
    required this.state,
    required this.asset,
    required this.wide,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final details = _Details(asset: asset);
    final actions = _Actions(state: state, asset: asset);

    return Semantics(
      // A node of its own (container) that keeps its own label
      // (explicitChildNodes): without the latter every descendant's text is
      // merged into one long label and the card stops being identifiable, and
      // its fields stop being separately navigable.
      container: true,
      explicitChildNodes: true,
      label: l10n.adminMediaAssetSemantic(asset.id),
      child: OceanGlassCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Preview(asset: asset),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: details),
                    const SizedBox(width: AppSpacing.md),
                    actions,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Preview(asset: asset),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: _Badges(asset: asset)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    details,
                    const SizedBox(height: AppSpacing.xs),
                    actions,
                  ],
                ),
        ),
      ),
    );
  }
}

/// A preview that is allowed to fail.
///
/// A registered URL may 404, may be behind auth, may have expired, or may not
/// be an image at all — VIDEO and DOCUMENT are legitimate media types here. So
/// only an IMAGE is even attempted, and a failure renders a neutral placeholder
/// instead of an exception escaping into the widget tree.
class _Preview extends StatelessWidget {
  final AdminMediaAsset asset;

  static const double _size = 72;

  const _Preview({required this.asset});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final url = asset.previewUrl;
    final renderable =
        asset.mediaType.isRenderableAsImage && AdminMediaUrl.isAcceptable(url);

    Widget fallback(String semantic, IconData icon) => Semantics(
          container: true,
          label: semantic,
          child: Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: scheme.onSurfaceVariant),
          ),
        );

    if (!renderable) {
      return fallback(
        asset.mediaType.isRenderableAsImage
            ? l10n.adminMediaPreviewUnavailable
            : l10n.adminMediaPreviewNotAnImage,
        switch (asset.mediaType) {
          AdminMediaType.video => Icons.videocam_outlined,
          AdminMediaType.document => Icons.description_outlined,
          _ => Icons.broken_image_outlined,
        },
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url!,
        width: _size,
        height: _size,
        fit: BoxFit.cover,
        semanticLabel: asset.altText,
        errorBuilder: (context, error, stack) => fallback(
            l10n.adminMediaPreviewUnavailable, Icons.broken_image_outlined),
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : SizedBox(
                width: _size,
                height: _size,
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: progress.expectedTotalBytes == null
                          ? null
                          : progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

/// State badges. Every one pairs its colour with a word, so nothing here is
/// communicated by colour alone.
class _Badges extends StatelessWidget {
  final AdminMediaAsset asset;

  const _Badges({required this.asset});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xxs,
      children: [
        AdminStatusChip(
            status:
                asset.active ? l10n.adminMediaActive : l10n.adminMediaInactive),
        Chip(
          avatar: Icon(
              switch (asset.mediaType) {
                AdminMediaType.image => Icons.image_outlined,
                AdminMediaType.video => Icons.videocam_outlined,
                AdminMediaType.document => Icons.description_outlined,
                AdminMediaType.unknown => Icons.help_outline,
              },
              size: 15),
          label: Text(asset.mediaType == AdminMediaType.unknown
              ? l10n.adminValueUnknown
              : asset.mediaType.wire),
          visualDensity: VisualDensity.compact,
        ),
        if (asset.cover)
          Chip(
            avatar: const Icon(Icons.star, size: 15),
            label: Text(l10n.adminMediaCover),
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}

class _Details extends StatelessWidget {
  final AdminMediaAsset asset;

  const _Details({required this.asset});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wide = AdminResponsiveGrid.isWide(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (wide) ...[
          _Badges(asset: asset),
          const SizedBox(height: AppSpacing.xs),
        ],
        // The URL is shown as origin + path. A media URL can legitimately be a
        // signed link, and D3M redacts exactly this part in the audit trail —
        // so a gallery listing does not print a bearer parameter either. The
        // stored value is untouched and the edit form shows it in full.
        AdminCardRow(
            label: l10n.adminMediaUrl,
            value: asset.displayUrl,
            emphasise: true),
        if (asset.urlHasQuery)
          Text(l10n.adminMediaUrlQueryHidden,
              style: Theme.of(context).textTheme.labelSmall),
        if (asset.thumbnailUrl != null && asset.thumbnailUrl!.isNotEmpty)
          AdminCardRow(
              label: l10n.adminMediaThumbnailUrl,
              value: AdminMediaUrl.redact(asset.thumbnailUrl) ?? ''),
        AdminCardRow(
            label: l10n.adminMediaAltText,
            value: AdminFormats.text(context, asset.altText)),
        AdminCardRow(
            label: l10n.adminMediaSortOrder,
            value: AdminFormats.count(asset.sortOrder)),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  final AdminMediaState state;
  final AdminMediaAsset asset;

  const _Actions({required this.state, required this.asset});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final busy = state.isMutating;
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xxs,
      alignment: WrapAlignment.end,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_upward),
          tooltip: l10n.adminMediaMoveUp,
          onPressed: busy || !state.canMoveUp(asset)
              ? null
              : () => state.moveMedia(asset, up: true),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_downward),
          tooltip: l10n.adminMediaMoveDown,
          onPressed: busy || !state.canMoveDown(asset)
              ? null
              : () => state.moveMedia(asset, up: false),
        ),
        // Offered only when the backend would accept it: an active IMAGE that
        // is not already the cover. Anything else answers 400 or 404.
        if (state.canSetCover(asset))
          TextButton.icon(
            onPressed: busy ? null : () => state.setCover(asset),
            icon: const Icon(Icons.star_outline, size: 18),
            label: Text(l10n.adminMediaSetCover),
          ),
        TextButton.icon(
          onPressed: busy ? null : () => _openEdit(context, state, asset),
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: Text(l10n.adminMediaEdit),
        ),
        if (asset.active)
          TextButton.icon(
            onPressed:
                busy ? null : () => _confirmDeactivate(context, state, asset),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            icon: const Icon(Icons.visibility_off_outlined, size: 18),
            label: Text(l10n.adminMediaDeactivate),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Create / edit / deactivate
// ═══════════════════════════════════════════════════════════════════════════

Future<void> _openCreate(BuildContext context, AdminMediaState state) async {
  final result = await showDialog<_MediaFormResult>(
    context: context,
    builder: (ctx) => const _MediaFormDialog(existing: null),
  );
  if (result == null) return;
  await state.createMedia(
    url: result.url,
    mediaType: result.mediaType,
    thumbnailUrl: result.thumbnailUrl,
    altText: result.altText,
    sortOrder: result.sortOrder,
    cover: result.cover,
  );
}

Future<void> _openEdit(
    BuildContext context, AdminMediaState state, AdminMediaAsset asset) async {
  final result = await showDialog<_MediaFormResult>(
    context: context,
    builder: (ctx) => _MediaFormDialog(existing: asset),
  );
  if (result == null) return;
  await state.updateMedia(
    asset,
    url: result.url,
    mediaType: result.mediaType,
    thumbnailUrl: result.thumbnailUrl,
    altText: result.altText,
    sortOrder: result.sortOrder,
    cover: result.cover,
  );
}

Future<void> _confirmDeactivate(
    BuildContext context, AdminMediaState state, AdminMediaAsset asset) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => _DeactivateDialog(asset: asset),
  );
  if (ok == true) await state.deactivateMedia(asset);
}

class _MediaFormResult {
  final String url;
  final AdminMediaType mediaType;
  final String? thumbnailUrl;
  final String? altText;
  final int? sortOrder;
  final bool cover;

  const _MediaFormResult({
    required this.url,
    required this.mediaType,
    required this.thumbnailUrl,
    required this.altText,
    required this.sortOrder,
    required this.cover,
  });
}

/// One form for both create and update.
///
/// It offers exactly the fields `MediaAssetRequest` carries and the backend
/// actually applies. `ownerType`/`ownerId` are not among them: on create they
/// are the place already open, and on update the service ignores them outright,
/// so an editor for them would be a control that does nothing.
class _MediaFormDialog extends StatefulWidget {
  final AdminMediaAsset? existing;

  const _MediaFormDialog({required this.existing});

  @override
  State<_MediaFormDialog> createState() => _MediaFormDialogState();
}

class _MediaFormDialogState extends State<_MediaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _url =
      TextEditingController(text: widget.existing?.url ?? '');
  late final TextEditingController _thumbnail =
      TextEditingController(text: widget.existing?.thumbnailUrl ?? '');
  late final TextEditingController _altText =
      TextEditingController(text: widget.existing?.altText ?? '');
  late final TextEditingController _sortOrder = TextEditingController(
      text: widget.existing == null ? '' : '${widget.existing!.sortOrder}');

  // An asset whose stored type this build does not recognise opens on IMAGE
  // rather than on a value the dropdown cannot offer.
  late AdminMediaType _mediaType = switch (widget.existing?.mediaType) {
    null || AdminMediaType.unknown => AdminMediaType.image,
    final t => t,
  };
  late bool _cover = widget.existing?.cover ?? false;

  @override
  void dispose() {
    _url.dispose();
    _thumbnail.dispose();
    _altText.dispose();
    _sortOrder.dispose();
    super.dispose();
  }

  /// Mirrors `MediaAssetService.validateUrl` and nothing more: absolute, http
  /// or https, with a host. No host allowlist and no extension check, because
  /// the server has neither and a stricter client would reject values the
  /// product accepts.
  String? _validateUrl(String? value, {required bool required}) {
    final l10n = AppLocalizations.of(context)!;
    final text = value?.trim() ?? '';
    if (text.isEmpty) return required ? l10n.adminMediaUrlRequired : null;
    if (!AdminMediaUrl.isAcceptable(text)) return l10n.adminMediaUrlInvalid;
    return null;
  }

  String? _validateSortOrder(String? value) {
    final l10n = AppLocalizations.of(context)!;
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final parsed = int.tryParse(text);
    if (parsed == null || parsed < 0) return l10n.adminMediaSortOrderInvalid;
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final thumbnail = _thumbnail.text.trim();
    final alt = _altText.text.trim();
    final order = _sortOrder.text.trim();
    Navigator.of(context).pop(_MediaFormResult(
      url: _url.text.trim(),
      mediaType: _mediaType,
      thumbnailUrl: thumbnail.isEmpty ? null : thumbnail,
      altText: alt.isEmpty ? null : alt,
      sortOrder: order.isEmpty ? null : int.tryParse(order),
      cover: _cover,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final editing = widget.existing != null;
    final canCover = _mediaType.canBeCover;

    return AlertDialog(
      title: Text(editing ? l10n.adminMediaEditTitle : l10n.adminMediaAddTitle),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.adminMediaUrlRegistryNotice,
                  style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: AppSpacing.xs),
              Semantics(
                textField: true,
                label: l10n.adminMediaUrl,
                child: TextFormField(
                  controller: _url,
                  autocorrect: false,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: l10n.adminMediaUrl,
                    helperText: l10n.adminMediaUrlHelper,
                    helperMaxLines: 2,
                  ),
                  validator: (v) => _validateUrl(v, required: true),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Semantics(
                textField: true,
                label: l10n.adminMediaThumbnailUrl,
                child: TextFormField(
                  controller: _thumbnail,
                  autocorrect: false,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                      labelText: l10n.adminMediaThumbnailUrlOptional),
                  validator: (v) => _validateUrl(v, required: false),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              // The decoration label alone is merged into the button's node
              // ("Type IMAGE"), so the field has no name of its own. An
              // explicit container keeps the name and leaves the selected
              // value as its own child node.
              Semantics(
                container: true,
                explicitChildNodes: true,
                label: l10n.adminMediaType,
                child: DropdownButtonFormField<AdminMediaType>(
                  initialValue: _mediaType,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l10n.adminMediaType),
                  items: [
                    for (final t in AdminMediaType.selectable)
                      DropdownMenuItem(value: t, child: Text(t.wire)),
                  ],
                  onChanged: (v) => setState(() {
                    _mediaType = v ?? _mediaType;
                    // The backend refuses a non-IMAGE cover, so the flag is
                    // dropped rather than sent and rejected.
                    if (!_mediaType.canBeCover) _cover = false;
                  }),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Semantics(
                textField: true,
                label: l10n.adminMediaAltText,
                child: TextFormField(
                  controller: _altText,
                  decoration: InputDecoration(
                      labelText: l10n.adminMediaAltTextOptional),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Semantics(
                textField: true,
                label: l10n.adminMediaSortOrder,
                child: TextFormField(
                  controller: _sortOrder,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: l10n.adminMediaSortOrderOptional),
                  validator: _validateSortOrder,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Material(
                type: MaterialType.transparency,
                child: CheckboxListTile(
                  value: _cover,
                  onChanged: canCover
                      ? (v) => setState(() => _cover = v ?? false)
                      : null,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.adminMediaSetAsCover),
                  subtitle: Text(
                      canCover
                          ? l10n.adminMediaCoverReplacesPrevious
                          : l10n.adminMediaCoverImageOnly,
                      style: Theme.of(context).textTheme.labelSmall),
                ),
              ),
              if (editing) ...[
                const SizedBox(height: AppSpacing.xs),
                // Said out loud because it is surprising: the update replaces
                // the editable fields wholesale, so clearing a box clears the
                // stored value.
                Text(l10n.adminMediaEditReplacesNotice,
                    style: Theme.of(context).textTheme.labelSmall),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.adminPartnerCancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(editing ? l10n.adminMediaSave : l10n.adminMediaCreate),
        ),
      ],
    );
  }
}

/// Deactivation is a soft delete with no counterpart: the admin API has no
/// reactivate, so this is the one media action the operator cannot walk back
/// from inside the console.
class _DeactivateDialog extends StatefulWidget {
  final AdminMediaAsset asset;

  const _DeactivateDialog({required this.asset});

  @override
  State<_DeactivateDialog> createState() => _DeactivateDialogState();
}

class _DeactivateDialogState extends State<_DeactivateDialog> {
  bool _acknowledged = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, color: scheme.error),
      title: Text(l10n.adminMediaDeactivateTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Bullet(text: l10n.adminMediaDeactivateWarningHidden),
            _Bullet(text: l10n.adminMediaDeactivateWarningNoRestore),
            if (widget.asset.cover)
              _Bullet(text: l10n.adminMediaDeactivateWarningCover),
            const SizedBox(height: AppSpacing.xs),
            Material(
              type: MaterialType.transparency,
              child: CheckboxListTile(
                value: _acknowledged,
                onChanged: (v) => setState(() => _acknowledged = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.adminMediaDeactivateAcknowledge,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.adminPartnerCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: scheme.error),
          onPressed:
              _acknowledged ? () => Navigator.of(context).pop(true) : null,
          child: Text(l10n.adminMediaDeactivateConfirm),
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

enum _BannerTone { warning, error }

class _Banner extends StatelessWidget {
  final _BannerTone tone;
  final String message;
  final VoidCallback onDismiss;

  const _Banner({
    required this.tone,
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            tooltip: l10n.adminMediaDismissNotice,
            color: fg,
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}
