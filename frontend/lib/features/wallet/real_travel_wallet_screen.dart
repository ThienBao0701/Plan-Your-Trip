import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_breakpoints.dart';
import '../../design/app_colors.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../auth/login_screen.dart';
import 'travel_wallet_screen.dart' show walletItemTypeLabel, walletStatusLabel;

/// UI50 — Real Mode Travel Wallet (`/api/me/travel-wallet`). Lists the customer's
/// wallet items (documents / vouchers / tickets) with add / edit / delete and
/// favorite / archive toggles. Every item is owner-only. Standalone (metadata)
/// items only — importing from a document/booking/invoice is a separate backend
/// flow left for a later phase. `referenceNumber` is write-only (masked
/// server-side): the form takes a raw value and the card shows only the mask.
class RealTravelWalletScreen extends StatefulWidget {
  const RealTravelWalletScreen({super.key});

  @override
  State<RealTravelWalletScreen> createState() => _RealTravelWalletScreenState();
}

class _RealTravelWalletScreenState extends State<RealTravelWalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.of(context).loadRealWallet();
    });
  }

  void _reauth() {
    showOceanSessionExpiredSheet(
      context,
      onLogin: () {
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      },
      onReturnHome: () => Navigator.of(context).pop(),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _messageForOutcome(AppLocalizations l10n, WalletOutcome o) {
    return switch (o) {
      WalletOutcome.forbidden => l10n.walletRealForbiddenMessage,
      WalletOutcome.notFound => l10n.walletRealGoneMessage,
      WalletOutcome.validation => l10n.walletRealTitleRequiredMessage,
      WalletOutcome.network => l10n.walletRealNetworkMessage,
      _ => l10n.walletRealActionErrorMessage,
    };
  }

  Future<void> _openForm(AppState app, RealWalletItem? existing) async {
    final l10n = AppLocalizations.of(context)!;
    final outcome = await showModalBottomSheet<WalletOutcome>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _WalletFormSheet(existing: existing),
    );
    if (!mounted || outcome == null) return;
    switch (outcome) {
      case WalletOutcome.success:
        _snack(existing == null
            ? l10n.walletRealCreatedMessage
            : l10n.walletRealUpdatedMessage);
      case WalletOutcome.sessionExpired:
        _reauth();
      case WalletOutcome.busy:
        break;
      default:
        _snack(_messageForOutcome(l10n, outcome));
    }
  }

  Future<void> _handle(WalletOutcome outcome, String successMessage) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    switch (outcome) {
      case WalletOutcome.success:
        _snack(successMessage);
      case WalletOutcome.busy:
        break;
      case WalletOutcome.sessionExpired:
        _reauth();
      default:
        _snack(_messageForOutcome(l10n, outcome));
    }
  }

  Future<void> _toggleFavorite(AppState app, RealWalletItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final outcome =
        await app.setRealWalletItemFavorite(item.id, !item.favorite);
    await _handle(
        outcome,
        item.favorite
            ? l10n.walletRealUnfavoritedMessage
            : l10n.walletRealFavoritedMessage);
  }

  Future<void> _toggleArchive(AppState app, RealWalletItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final outcome =
        await app.setRealWalletItemArchived(item.id, !item.archived);
    await _handle(
        outcome,
        item.archived
            ? l10n.walletRealRestoredMessage
            : l10n.walletRealArchivedMessage);
  }

  Future<void> _delete(AppState app, RealWalletItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final title = item.displayTitle.trim().isEmpty
        ? l10n.walletRealUntitled
        : item.displayTitle.trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.walletRealDeleteConfirmTitle),
        content: Text(l10n.walletRealDeleteConfirmMessage(title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.profileCancel),
          ),
          FilledButton.tonalIcon(
            key: const Key('wallet-delete-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text(l10n.walletRealDeleteAction),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final outcome = await app.deleteRealWalletItem(item.id);
    await _handle(outcome, l10n.walletRealDeletedMessage);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.travelWalletTitle),
        actions: [
          if (app.realWalletLoaded)
            IconButton(
              key: const Key('wallet-add'),
              tooltip: l10n.walletRealAddSemantic,
              onPressed: app.realWalletMutationInFlight
                  ? null
                  : () => _openForm(app, null),
              icon: const Icon(Icons.add_rounded),
            ),
        ],
      ),
      body: BubbleBackground(
        child: SafeArea(top: false, child: _body(context, app, l10n)),
      ),
    );
  }

  Widget _body(BuildContext context, AppState app, AppLocalizations l10n) {
    if (app.realWalletError == WalletOutcome.sessionExpired &&
        !app.realWalletLoaded) {
      return _centered(
        OceanSessionExpiredState(
          key: const Key('wallet-session-expired'),
          onLogin: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
          onReturnHome: () => Navigator.maybePop(context),
        ),
      );
    }
    if (app.realWalletLoading && !app.realWalletLoaded) {
      return _centered(
        Semantics(
          liveRegion: true,
          label: l10n.walletRealLoadingMessage,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(key: Key('wallet-loading')),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.walletRealLoadingMessage),
            ],
          ),
        ),
      );
    }
    if (app.realWalletError != null && !app.realWalletLoaded) {
      return _centered(
        OceanRecoverableErrorState(
          key: const Key('wallet-error'),
          message: app.realWalletError == WalletOutcome.forbidden
              ? l10n.walletRealForbiddenMessage
              : app.realWalletError == WalletOutcome.notFound
                  ? l10n.walletRealGoneMessage
                  : l10n.walletRealErrorMessage,
          onReload: () => app.loadRealWallet(refresh: true),
        ),
      );
    }
    final items = app.realWalletItems;
    final locale = Localizations.localeOf(context).toString();
    return RefreshIndicator(
      onRefresh: () => app.loadRealWallet(refresh: true),
      child: ListView(
        key: const Key('wallet-content'),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          OceanContentConstraint(
            maxWidth: AppBreakpoints.maxContentWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (items.isEmpty)
                  OceanEmptyState(
                    key: const Key('wallet-empty'),
                    title: l10n.walletRealListEmptyTitle,
                    message: l10n.walletRealListEmptyMessage,
                    actionLabel: l10n.walletRealAddSemantic,
                    onAction: app.realWalletMutationInFlight
                        ? null
                        : () => _openForm(app, null),
                  )
                else
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _WalletCard(
                        item: item,
                        locale: locale,
                        busy: app.realWalletMutationInFlight,
                        onFavorite: () => _toggleFavorite(app, item),
                        onArchive: () => _toggleArchive(app, item),
                        onEdit: () => _openForm(app, item),
                        onDelete: () => _delete(app, item),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _centered(Widget child) => ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xxl,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          OceanContentConstraint(
            maxWidth: AppBreakpoints.maxContentWidth,
            child: Center(child: child),
          ),
        ],
      );
}

/// Localized type label for a real wallet item, falling back to the raw code.
String realWalletTypeLabel(AppLocalizations l10n, RealWalletItem item) {
  final view = item.typeView;
  if (view != null) return walletItemTypeLabel(l10n, view);
  return item.walletItemType.trim().isEmpty
      ? l10n.walletTypeLabel
      : item.walletItemType;
}

/// Localized effective-status label for a real wallet item, falling back to raw.
String realWalletStatusLabel(AppLocalizations l10n, RealWalletItem item) {
  final view = item.effectiveStatusView;
  if (view != null) return walletStatusLabel(l10n, view);
  return item.effectiveStatus.trim().isEmpty
      ? l10n.walletStatusLabel
      : item.effectiveStatus;
}

Color _statusColor(RealWalletItem item) {
  switch (item.effectiveStatusView) {
    case WalletItemStatus.active:
      return AppColors.success;
    case WalletItemStatus.upcoming:
      return AppColors.ocean;
    case WalletItemStatus.expired:
      return AppColors.danger;
    case WalletItemStatus.cancelled:
      return AppColors.warning;
    case WalletItemStatus.archived:
    case null:
      return AppColors.textTertiary;
  }
}

class _WalletCard extends StatelessWidget {
  final RealWalletItem item;
  final String locale;
  final bool busy;
  final VoidCallback onFavorite;
  final VoidCallback onArchive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _WalletCard({
    required this.item,
    required this.locale,
    required this.busy,
    required this.onFavorite,
    required this.onArchive,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = DateFormat.yMMMd(locale);
    final title = item.displayTitle.trim().isEmpty
        ? l10n.walletRealUntitled
        : item.displayTitle.trim();
    String? validity;
    if (item.validFrom != null && item.validUntil != null) {
      validity = l10n.walletValidPeriod(
          date.format(item.validFrom!), date.format(item.validUntil!));
    } else if (item.validUntil != null) {
      validity = l10n.walletValidUntil(date.format(item.validUntil!));
    } else if (item.validFrom != null) {
      validity = l10n.walletValidFrom(date.format(item.validFrom!));
    }
    return OceanGlassCard(
      key: Key('wallet-card-${item.id}'),
      onTap: onEdit,
      semanticLabel: l10n.walletItemSemantic(title),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child:
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
              ),
              IconButton(
                key: Key('wallet-favorite-${item.id}'),
                tooltip: item.favorite
                    ? l10n.walletRealUnfavoriteSemantic(title)
                    : l10n.walletRealFavoriteSemantic(title),
                onPressed: busy ? null : onFavorite,
                icon: Icon(
                  item.favorite
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: item.favorite ? AppColors.warning : null,
                ),
              ),
            ],
          ),
          if ((item.issuer ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              item.issuer!.trim(),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          if ((item.referenceNumberMasked ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              l10n.walletMaskedReference(item.referenceNumberMasked!.trim()),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          if (validity != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              validity,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          if ((item.tripPlanTitle ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              '${l10n.walletLinkedTripLabel}: ${item.tripPlanTitle!.trim()}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              OceanStatusPill(
                label: realWalletTypeLabel(l10n, item),
                icon: Icons.folder_copy_rounded,
                color: AppColors.turquoise600,
              ),
              OceanStatusPill(
                label: realWalletStatusLabel(l10n, item),
                icon: Icons.flag_rounded,
                color: _statusColor(item),
              ),
              if (item.archived)
                OceanStatusPill(
                  label: l10n.walletStatusArchived,
                  icon: Icons.inventory_2_rounded,
                  color: AppColors.textTertiary,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OceanSecondaryButton(
                key: Key('wallet-archive-${item.id}'),
                label: item.archived
                    ? l10n.walletRealRestoreAction
                    : l10n.walletRealArchiveAction,
                icon: item.archived
                    ? Icons.unarchive_rounded
                    : Icons.archive_rounded,
                fullWidth: false,
                onPressed: busy ? null : onArchive,
                semanticLabel: item.archived
                    ? l10n.walletRealRestoreAction
                    : l10n.walletRealArchiveAction,
              ),
              OceanSecondaryButton(
                key: Key('wallet-delete-${item.id}'),
                label: l10n.walletRealDeleteAction,
                icon: Icons.delete_outline_rounded,
                fullWidth: false,
                onPressed: busy ? null : onDelete,
                semanticLabel: l10n.walletRealDeleteAction,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WalletFormSheet extends StatefulWidget {
  final RealWalletItem? existing;

  const _WalletFormSheet({this.existing});

  @override
  State<_WalletFormSheet> createState() => _WalletFormSheetState();
}

class _WalletFormSheetState extends State<_WalletFormSheet> {
  late final TextEditingController _title;
  late final TextEditingController _issuer;
  late final TextEditingController _reference;
  late WalletItemType _type;
  DateTime? _validFrom;
  DateTime? _validUntil;
  bool _titleError = false;

  @override
  void initState() {
    super.initState();
    final i = widget.existing;
    _title = TextEditingController(text: i?.displayTitle ?? '');
    _issuer = TextEditingController(text: i?.issuer ?? '');
    _reference = TextEditingController();
    _type = i?.typeView ?? WalletItemType.other;
    _validFrom = i?.validFrom;
    _validUntil = i?.validUntil;
  }

  @override
  void dispose() {
    _title.dispose();
    _issuer.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<void> _pick(bool from) async {
    final initial = (from ? _validFrom : _validUntil) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (from) {
        _validFrom = picked;
      } else {
        _validUntil = picked;
      }
    });
  }

  Future<void> _submit() async {
    final app = AppScope.of(context);
    final title = _title.text.trim();
    setState(() => _titleError = title.isEmpty);
    if (title.isEmpty) return;
    final payload = RealWalletItemPayload(
      walletItemType: _type,
      displayTitle: title,
      issuer: _issuer.text.trim().isEmpty ? null : _issuer.text.trim(),
      referenceNumber:
          _reference.text.trim().isEmpty ? null : _reference.text.trim(),
      validFrom: _validFrom,
      validUntil: _validUntil,
    );
    final existing = widget.existing;
    final outcome = existing == null
        ? await app.createRealWalletItem(payload)
        : await app.updateRealWalletItem(existing.id, payload);
    if (!mounted) return;
    Navigator.of(context).pop(outcome);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat.yMMMd(locale);
    final saving = app.realWalletMutationInFlight;
    final isEdit = widget.existing != null;
    final masked = widget.existing?.referenceNumberMasked;
    return SafeArea(
      child: Padding(
        key: const Key('wallet-form-content'),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEdit ? l10n.walletRealEditTitle : l10n.walletRealCreateTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              GlassTextField(
                key: const Key('wallet-field-title'),
                controller: _title,
                hint: l10n.walletRealTitleField,
                icon: Icons.title_rounded,
              ),
              if (_titleError)
                _fieldError(context, l10n.walletRealTitleRequiredMessage),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<WalletItemType>(
                key: const Key('wallet-field-type'),
                initialValue: _type,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.walletTypeLabel,
                  prefixIcon: const Icon(Icons.folder_copy_rounded),
                ),
                items: [
                  for (final t in WalletItemType.values)
                    DropdownMenuItem(
                      value: t,
                      child: Text(walletItemTypeLabel(l10n, t)),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _type = v);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              GlassTextField(
                key: const Key('wallet-field-issuer'),
                controller: _issuer,
                hint: l10n.walletRealIssuerField,
                icon: Icons.business_rounded,
              ),
              const SizedBox(height: AppSpacing.sm),
              GlassTextField(
                key: const Key('wallet-field-reference'),
                controller: _reference,
                hint: l10n.walletRealReferenceField,
                icon: Icons.confirmation_number_rounded,
              ),
              Padding(
                padding: const EdgeInsets.only(
                    top: AppSpacing.xxs, left: AppSpacing.sm),
                child: Text(
                  (masked != null && masked.trim().isNotEmpty)
                      ? l10n.walletRealReferenceHint(masked.trim())
                      : l10n.walletRealReferenceNote,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      key: const Key('wallet-field-validFrom'),
                      onTap: () => _pick(true),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: l10n.walletRealValidFromField,
                          prefixIcon: const Icon(Icons.event_available_rounded),
                        ),
                        child: Text(_validFrom != null
                            ? date.format(_validFrom!)
                            : l10n.walletRealDateNone),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: InkWell(
                      key: const Key('wallet-field-validUntil'),
                      onTap: () => _pick(false),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: l10n.walletRealValidUntilField,
                          prefixIcon: const Icon(Icons.event_busy_rounded),
                        ),
                        child: Text(_validUntil != null
                            ? date.format(_validUntil!)
                            : l10n.walletRealDateNone),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              OceanPrimaryButton(
                key: const Key('wallet-form-save'),
                label: l10n.walletRealSaveAction,
                icon: Icons.check_rounded,
                onPressed: saving ? null : _submit,
                semanticLabel: l10n.walletRealSaveAction,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldError(BuildContext context, String message) => Padding(
        padding:
            const EdgeInsets.only(top: AppSpacing.xxs, left: AppSpacing.sm),
        child: Text(
          message,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.danger),
        ),
      );
}
