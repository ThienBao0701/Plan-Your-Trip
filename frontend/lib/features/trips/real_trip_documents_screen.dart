import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_breakpoints.dart';
import '../../design/app_colors.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../auth/login_screen.dart';
import 'trip_documents_screen.dart' show tripDocumentTypeLabel;

/// UI43 — Real Mode trip documents (`/api/me/trips/{tripId}/documents`). Lists a
/// real trip's attached travel documents (pinned first), and supports attach
/// (by URL) / edit / delete / pin (owner or EDITOR collaborator). The client
/// never uploads a raw file — a document points at a media asset registered by
/// URL, matching the backend contract; nothing is fabricated.
class RealTripDocumentsScreen extends StatefulWidget {
  final int tripId;
  final String? tripTitle;

  const RealTripDocumentsScreen({
    super.key,
    required this.tripId,
    this.tripTitle,
  });

  @override
  State<RealTripDocumentsScreen> createState() =>
      _RealTripDocumentsScreenState();
}

class _RealTripDocumentsScreenState extends State<RealTripDocumentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.of(context).loadRealDocuments(widget.tripId);
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

  String _messageForOutcome(AppLocalizations l10n, DocumentOutcome o) {
    return switch (o) {
      DocumentOutcome.forbidden => l10n.documentsRealForbiddenMessage,
      DocumentOutcome.notFound => l10n.documentsRealGoneMessage,
      DocumentOutcome.validation => l10n.documentsRealUrlRequiredMessage,
      DocumentOutcome.network => l10n.documentsRealNetworkMessage,
      _ => l10n.documentsRealActionErrorMessage,
    };
  }

  Future<void> _openForm(AppState app, RealTripDocument? existing) async {
    final l10n = AppLocalizations.of(context)!;
    final outcome = await showModalBottomSheet<DocumentOutcome>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _DocumentFormSheet(
        tripId: widget.tripId,
        existing: existing,
      ),
    );
    if (!mounted || outcome == null) return;
    switch (outcome) {
      case DocumentOutcome.success:
        _snack(existing == null
            ? l10n.documentsRealCreatedMessage
            : l10n.documentsRealUpdatedMessage);
      case DocumentOutcome.sessionExpired:
        _reauth();
      case DocumentOutcome.busy:
        break;
      default:
        _snack(_messageForOutcome(l10n, outcome));
    }
  }

  Future<void> _togglePin(AppState app, RealTripDocument doc) async {
    final l10n = AppLocalizations.of(context)!;
    final outcome =
        await app.setRealDocumentPinned(widget.tripId, doc.id, !doc.pinned);
    if (!mounted) return;
    switch (outcome) {
      case DocumentOutcome.success:
        _snack(doc.pinned
            ? l10n.documentsRealUnpinnedMessage
            : l10n.documentsRealPinnedMessage);
      case DocumentOutcome.sessionExpired:
        _reauth();
      case DocumentOutcome.busy:
        break;
      default:
        _snack(_messageForOutcome(l10n, outcome));
    }
  }

  Future<void> _delete(AppState app, RealTripDocument doc) async {
    final l10n = AppLocalizations.of(context)!;
    final title = (doc.title ?? '').trim().isNotEmpty
        ? doc.title!.trim()
        : l10n.tripDocumentsTitle;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.tripDocumentDeleteConfirmTitle),
        content: Text(l10n.tripDocumentDeleteConfirmMessage(title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.profileCancel),
          ),
          FilledButton.tonalIcon(
            key: const Key('document-delete-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text(l10n.tripDocumentDeleteAction),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final outcome = await app.deleteRealDocument(widget.tripId, doc.id);
    if (!mounted) return;
    switch (outcome) {
      case DocumentOutcome.success:
        _snack(l10n.tripDocumentDeletedMessage);
      case DocumentOutcome.sessionExpired:
        _reauth();
      case DocumentOutcome.busy:
        break;
      default:
        _snack(_messageForOutcome(l10n, outcome));
    }
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
        title: Text(widget.tripTitle?.trim().isNotEmpty == true
            ? widget.tripTitle!.trim()
            : l10n.tripDocumentsTitle),
        actions: [
          if (app.realDocumentsLoaded)
            IconButton(
              key: const Key('documents-add'),
              tooltip: l10n.documentsRealAddSemantic,
              onPressed: app.realDocumentMutationInFlight
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
    if (app.realDocumentsError == DocumentOutcome.sessionExpired &&
        !app.realDocumentsLoaded) {
      return _centered(
        OceanSessionExpiredState(
          key: const Key('documents-session-expired'),
          onLogin: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
          onReturnHome: () => Navigator.maybePop(context),
        ),
      );
    }
    if (app.realDocumentsLoading && !app.realDocumentsLoaded) {
      return _centered(
        Semantics(
          liveRegion: true,
          label: l10n.documentsRealLoadingMessage,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(key: Key('documents-loading')),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.documentsRealLoadingMessage),
            ],
          ),
        ),
      );
    }
    if (app.realDocumentsError != null && !app.realDocumentsLoaded) {
      return _centered(
        OceanRecoverableErrorState(
          key: const Key('documents-error'),
          message: app.realDocumentsError == DocumentOutcome.notFound
              ? l10n.documentsRealGoneMessage
              : app.realDocumentsError == DocumentOutcome.forbidden
                  ? l10n.documentsRealForbiddenMessage
                  : l10n.documentsRealErrorMessage,
          onReload: () => app.loadRealDocuments(widget.tripId, refresh: true),
        ),
      );
    }
    final docs = app.realDocumentsFor(widget.tripId);
    final locale = Localizations.localeOf(context).toString();
    return RefreshIndicator(
      onRefresh: () => app.loadRealDocuments(widget.tripId, refresh: true),
      child: ListView(
        key: const Key('documents-content'),
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
                OceanGlassSurface(
                  blur: 0,
                  radius: AppRadii.lg,
                  color: AppColors.paleCyan,
                  child: Text(
                    l10n.tripDocumentNoUploadNotice,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (docs.isEmpty)
                  OceanEmptyState(
                    key: const Key('documents-empty'),
                    title: l10n.tripDocumentsRealEmptyTitle,
                    message: l10n.tripDocumentsRealEmptyMessage,
                    actionLabel: l10n.tripDocumentAddAction,
                    onAction: app.realDocumentMutationInFlight
                        ? null
                        : () => _openForm(app, null),
                  )
                else
                  for (final d in docs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _DocumentCard(
                        document: d,
                        locale: locale,
                        onEdit: () => _openForm(app, d),
                        onTogglePin: () => _togglePin(app, d),
                        onDelete: () => _delete(app, d),
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

String realDocumentTypeLabel(AppLocalizations l10n, RealTripDocument doc) {
  final view = doc.typeView;
  if (view != null) return tripDocumentTypeLabel(l10n, view);
  return doc.documentType.trim().isEmpty
      ? l10n.documentsRealTypeUnknown
      : doc.documentType;
}

IconData realDocumentTypeIcon(TripDocumentType? type) {
  return switch (type) {
    TripDocumentType.flightTicket => Icons.flight_rounded,
    TripDocumentType.hotelBooking => Icons.hotel_rounded,
    TripDocumentType.trainTicket => Icons.train_rounded,
    TripDocumentType.busTicket => Icons.directions_bus_rounded,
    TripDocumentType.passport => Icons.badge_rounded,
    TripDocumentType.visa => Icons.badge_rounded,
    TripDocumentType.insurance => Icons.health_and_safety_rounded,
    TripDocumentType.tour => Icons.explore_rounded,
    TripDocumentType.receipt => Icons.receipt_long_rounded,
    TripDocumentType.pdf => Icons.picture_as_pdf_rounded,
    TripDocumentType.image => Icons.image_rounded,
    TripDocumentType.other => Icons.description_rounded,
    null => Icons.description_rounded,
  };
}

class _DocumentCard extends StatelessWidget {
  final RealTripDocument document;
  final String locale;
  final VoidCallback onEdit;
  final VoidCallback onTogglePin;
  final VoidCallback onDelete;

  const _DocumentCard({
    required this.document,
    required this.locale,
    required this.onEdit,
    required this.onTogglePin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = (document.title ?? '').trim().isNotEmpty
        ? document.title!.trim()
        : realDocumentTypeLabel(l10n, document);
    final date = document.updatedAt != null
        ? DateFormat.yMMMd(locale).format(document.updatedAt!.toLocal())
        : null;
    final url = (document.mediaUrl ?? '').trim();
    return OceanGlassCard(
      key: Key('document-card-${document.id}'),
      onTap: onEdit,
      semanticLabel: l10n.tripDocumentCardSemantic(title),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.ocean.withValues(alpha: .12),
            child: Icon(
              realDocumentTypeIcon(document.typeView),
              color: AppColors.ocean,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  realDocumentTypeLabel(l10n, document),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if ((document.notes ?? '').trim().isNotEmpty)
                  Text(
                    document.notes!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                if (url.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  SelectableText(
                    url,
                    maxLines: 1,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.turquoise600),
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (document.pinned)
                      OceanStatusPill(
                        label: l10n.tripDocumentPinned,
                        icon: Icons.push_pin_rounded,
                        color: AppColors.warning,
                      ),
                    if (date != null)
                      OceanStatusPill(
                        label: date,
                        icon: Icons.update_rounded,
                        color: AppColors.turquoise600,
                      ),
                    if ((document.uploadedByUserName ?? '').trim().isNotEmpty)
                      OceanStatusPill(
                        label: document.uploadedByUserName!.trim(),
                        icon: Icons.person_rounded,
                        color: AppColors.slate,
                      ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                key: Key('document-pin-${document.id}'),
                tooltip: document.pinned
                    ? l10n.tripDocumentUnpinAction
                    : l10n.tripDocumentPinAction,
                onPressed: onTogglePin,
                icon: Icon(document.pinned
                    ? Icons.push_pin_rounded
                    : Icons.push_pin_outlined),
              ),
              IconButton(
                key: Key('document-delete-${document.id}'),
                tooltip: l10n.tripDocumentDeleteAction,
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocumentFormSheet extends StatefulWidget {
  final int tripId;
  final RealTripDocument? existing;

  const _DocumentFormSheet({required this.tripId, this.existing});

  @override
  State<_DocumentFormSheet> createState() => _DocumentFormSheetState();
}

class _DocumentFormSheetState extends State<_DocumentFormSheet> {
  late final TextEditingController _title;
  late final TextEditingController _notes;
  late final TextEditingController _url;
  late TripDocumentType _type;
  bool _urlError = false;

  @override
  void initState() {
    super.initState();
    final d = widget.existing;
    _title = TextEditingController(text: d?.title ?? '');
    _notes = TextEditingController(text: d?.notes ?? '');
    _url = TextEditingController(text: d?.mediaUrl ?? '');
    _type = d?.typeView ?? TripDocumentType.pdf;
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _url.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final app = AppScope.of(context);
    final isEdit = widget.existing != null;
    final url = _url.text.trim();
    // On create the backend requires a url (the client never uploads a file);
    // on update media fields are ignored, so the url is optional.
    setState(() => _urlError = !isEdit && url.isEmpty);
    if (!isEdit && url.isEmpty) return;
    final payload = RealTripDocumentPayload(
      documentType: _type,
      title: _title.text.trim().isEmpty ? null : _title.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      url: url.isEmpty ? null : url,
    );
    final existing = widget.existing;
    final outcome = existing == null
        ? await app.createRealDocument(widget.tripId, payload)
        : await app.updateRealDocument(widget.tripId, existing.id, payload);
    if (!mounted) return;
    Navigator.of(context).pop(outcome);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final saving = app.realDocumentMutationInFlight;
    final isEdit = widget.existing != null;
    return SafeArea(
      child: Padding(
        key: const Key('document-form-content'),
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
                isEdit
                    ? l10n.tripDocumentEditTitle
                    : l10n.tripDocumentCreateTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const Key('document-field-title'),
                controller: _title,
                decoration:
                    InputDecoration(labelText: l10n.tripDocumentTitleLabel),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<TripDocumentType>(
                key: const Key('document-field-type'),
                initialValue: _type,
                isExpanded: true,
                decoration:
                    InputDecoration(labelText: l10n.tripDocumentTypeLabel),
                items: [
                  for (final type in TripDocumentType.values)
                    DropdownMenuItem(
                      value: type,
                      child: Text(tripDocumentTypeLabel(l10n, type)),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _type = v);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                key: const Key('document-field-url'),
                controller: _url,
                enabled: !isEdit,
                decoration: InputDecoration(
                  labelText: l10n.tripDocumentMediaUrlLabel,
                  helperText: l10n.tripDocumentMediaHelper,
                  errorText:
                      _urlError ? l10n.documentsRealUrlRequiredMessage : null,
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                key: const Key('document-field-notes'),
                controller: _notes,
                decoration:
                    InputDecoration(labelText: l10n.tripDocumentNotesLabel),
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.md),
              OceanGlassSurface(
                blur: 0,
                radius: AppRadii.lg,
                color: AppColors.paleCyan,
                child: Text(
                  l10n.tripDocumentNoUploadNotice,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              OceanPrimaryButton(
                key: const Key('document-form-save'),
                label:
                    isEdit ? l10n.walletSaveAction : l10n.tripDocumentAddAction,
                icon: Icons.check_rounded,
                onPressed: saving ? null : _submit,
                semanticLabel:
                    isEdit ? l10n.walletSaveAction : l10n.tripDocumentAddAction,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
