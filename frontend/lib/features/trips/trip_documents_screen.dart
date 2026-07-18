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

class TripDocumentsScreen extends StatefulWidget {
  final Trip trip;

  const TripDocumentsScreen({super.key, required this.trip});

  @override
  State<TripDocumentsScreen> createState() => _TripDocumentsScreenState();
}

class _TripDocumentsScreenState extends State<TripDocumentsScreen> {
  TripDocumentType? _typeFilter;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final trip = app.tripById(widget.trip.id);
    final docs = trip == null
        ? <TripDocument>[]
        : app
            .documentsForTrip(trip.id)
            .where((doc) => _typeFilter == null || doc.type == _typeFilter)
            .toList();

    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.tripDocumentsTitle),
      ),
      body: BubbleBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            key: const Key('trip-documents-screen'),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              OceanContentConstraint(
                maxWidth: AppBreakpoints.maxContentWidth,
                child: trip == null
                    ? OceanEmptyState(
                        title: l10n.tripDocumentsEmptyTitle,
                        message: l10n.tripDocumentsTripDeletedMessage,
                      )
                    : !app.demoMode
                        ? OceanEmptyState(
                            title: l10n.tripDocumentsRealEmptyTitle,
                            message: l10n.tripDocumentsRealEmptyMessage,
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _DocumentsHeader(trip: trip),
                              const SizedBox(height: AppSpacing.md),
                              _DocumentControls(
                                typeFilter: _typeFilter,
                                onTypeChanged: (value) =>
                                    setState(() => _typeFilter = value),
                                onAdd: () => _showEditor(trip),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              if (docs.isEmpty)
                                OceanEmptyState(
                                  title: l10n.tripDocumentsEmptyTitle,
                                  message: l10n.tripDocumentsEmptyMessage,
                                )
                              else
                                for (final document in docs)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.sm,
                                    ),
                                    child: _TripDocumentCard(
                                      document: document,
                                      onTap: () => _showDetail(document),
                                    ),
                                  ),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditor(Trip trip, [TripDocument? document]) async {
    final result = await showModalBottomSheet<WalletActionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TripDocumentEditor(trip: trip, document: document),
    );
    if (!mounted || result == null) return;
    if (result == WalletActionResult.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.tripDocumentSavedMessage),
        ),
      );
      return;
    }
    _showResultMessage(result);
  }

  Future<void> _showDetail(TripDocument document) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TripDocumentDetailSheet(
        document: document,
        onEdit: () {
          Navigator.pop(context);
          final trip = AppScope.of(context).tripById(document.tripId);
          if (trip != null) _showEditor(trip, document);
        },
        onPin: () {
          final app = AppScope.of(context);
          final result = app.setTripDocumentPinned(
            document.id,
            !document.pinned,
          );
          Navigator.pop(context);
          _showResultMessage(result);
        },
        onSaveToWallet: () {
          final app = AppScope.of(context);
          final existed = app.travelWalletItems
              .any((item) => item.linkedDocumentId == document.id);
          final imported = app.importTripDocumentToWallet(document.id);
          Navigator.pop(context);
          if (imported == null) {
            _showResultMessage(WalletActionResult.unavailable);
            return;
          }
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                existed
                    ? l10n.tripDocumentWalletDuplicateMessage
                    : l10n.tripDocumentWalletImportedMessage,
              ),
            ),
          );
        },
        onDelete: () {
          Navigator.pop(context);
          _confirmDelete(document);
        },
      ),
    );
  }

  Future<void> _confirmDelete(TripDocument document) async {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.tripDocumentDeleteConfirmTitle),
        content: Text(l10n.tripDocumentDeleteConfirmMessage(document.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.profileCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.tripDocumentDeleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = app.deleteTripDocument(document.id);
    if (!mounted) return;
    if (result == WalletActionResult.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.tripDocumentDeletedMessage)),
      );
    } else {
      _showResultMessage(result);
    }
  }

  void _showResultMessage(WalletActionResult result) {
    final l10n = AppLocalizations.of(context)!;
    final message = switch (result) {
      WalletActionResult.success => l10n.tripDocumentSavedMessage,
      WalletActionResult.unavailable => l10n.walletActionUnavailable,
      WalletActionResult.blank => l10n.walletTitleRequiredMessage,
      WalletActionResult.duplicate => l10n.walletDuplicateMessage,
      WalletActionResult.rejected => l10n.walletActionRejectedMessage,
      WalletActionResult.invalidDateRange => l10n.walletInvalidDateMessage,
      WalletActionResult.unsafeUrl => l10n.tripDocumentUnsafeUrlMessage,
      WalletActionResult.notFound => l10n.walletNotFoundMessage,
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DocumentsHeader extends StatelessWidget {
  final Trip trip;

  const _DocumentsHeader({required this.trip});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.folder_copy_rounded,
                color: AppColors.ocean,
                size: 36,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.tripDocumentsTitle,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      l10n.tripDocumentsDemoSubtitle(trip.title),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              OceanStatusPill(
                label: l10n.demoModeLabel,
                icon: Icons.science_rounded,
              ),
            ],
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
        ],
      ),
    );
  }
}

class _DocumentControls extends StatelessWidget {
  final TripDocumentType? typeFilter;
  final ValueChanged<TripDocumentType?> onTypeChanged;
  final VoidCallback onAdd;

  const _DocumentControls({
    required this.typeFilter,
    required this.onTypeChanged,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassCard(
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 260,
            child: DropdownButtonFormField<TripDocumentType?>(
              key: const Key('trip-document-type-filter'),
              initialValue: typeFilter,
              isExpanded: true,
              decoration:
                  InputDecoration(labelText: l10n.tripDocumentTypeLabel),
              items: [
                DropdownMenuItem<TripDocumentType?>(
                  value: null,
                  child: Text(l10n.walletFilterAll),
                ),
                for (final type in TripDocumentType.values)
                  DropdownMenuItem<TripDocumentType?>(
                    value: type,
                    child: Text(
                      tripDocumentTypeLabel(l10n, type),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: onTypeChanged,
            ),
          ),
          OceanPrimaryButton(
            key: const Key('trip-document-add'),
            label: l10n.tripDocumentAddAction,
            icon: Icons.add_rounded,
            semanticLabel: l10n.tripDocumentAddAction,
            fullWidth: false,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class _TripDocumentCard extends StatelessWidget {
  final TripDocument document;
  final VoidCallback onTap;

  const _TripDocumentCard({
    required this.document,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    return OceanGlassCard(
      key: Key('trip-document-${document.id}'),
      onTap: onTap,
      semanticLabel: l10n.tripDocumentCardSemantic(document.title),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.ocean.withValues(alpha: .12),
            child: Icon(
              _documentIcon(document.type),
              color: AppColors.ocean,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  tripDocumentTypeLabel(l10n, document.type),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (document.notes.isNotEmpty)
                  Text(
                    document.notes,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
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
                    OceanStatusPill(
                      label: date.format(document.updatedAt),
                      icon: Icons.update_rounded,
                    ),
                    if (document.hasSafeMedia)
                      OceanStatusPill(
                        label: document.mediaLabel.isEmpty
                            ? l10n.tripDocumentSafeLinkLabel
                            : document.mediaLabel,
                        icon: Icons.link_rounded,
                        color: AppColors.turquoise600,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TripDocumentDetailSheet extends StatelessWidget {
  final TripDocument document;
  final VoidCallback onEdit;
  final VoidCallback onPin;
  final VoidCallback onSaveToWallet;
  final VoidCallback onDelete;

  const _TripDocumentDetailSheet({
    required this.document,
    required this.onEdit,
    required this.onPin,
    required this.onSaveToWallet,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    return OceanGlassBottomSheet(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(document.title,
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                OceanStatusPill(
                  label: tripDocumentTypeLabel(l10n, document.type),
                  icon: _documentIcon(document.type),
                ),
                OceanStatusPill(
                  label: document.pinned
                      ? l10n.tripDocumentPinned
                      : l10n.tripDocumentUnpinned,
                  icon: Icons.push_pin_rounded,
                  color: document.pinned ? AppColors.warning : AppColors.ocean,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _DocRow(
              icon: Icons.person_rounded,
              label: l10n.tripDocumentUploaderLabel,
              value: document.uploaderName.isEmpty
                  ? l10n.walletNoValue
                  : document.uploaderName,
            ),
            _DocRow(
              icon: Icons.update_rounded,
              label: l10n.walletUpdatedLabel,
              value: date.format(document.updatedAt),
            ),
            if (document.notes.isNotEmpty)
              _DocRow(
                icon: Icons.notes_rounded,
                label: l10n.tripDocumentNotesLabel,
                value: document.notes,
              ),
            if (document.hasSafeMedia)
              _DocRow(
                icon: Icons.link_rounded,
                label: l10n.tripDocumentMediaLabel,
                value: document.mediaLabel.isEmpty
                    ? l10n.tripDocumentSafeLinkLabel
                    : document.mediaLabel,
              ),
            const SizedBox(height: AppSpacing.md),
            OceanGlassSurface(
              blur: 0,
              color: AppColors.paleCyan,
              child: Text(
                l10n.tripDocumentNoUploadNotice,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OceanSecondaryButton(
                  key: const Key('trip-document-edit'),
                  label: l10n.walletEditAction,
                  icon: Icons.edit_rounded,
                  fullWidth: false,
                  onPressed: onEdit,
                ),
                OceanSecondaryButton(
                  key: const Key('trip-document-pin'),
                  label: document.pinned
                      ? l10n.tripDocumentUnpinAction
                      : l10n.tripDocumentPinAction,
                  icon: Icons.push_pin_rounded,
                  fullWidth: false,
                  onPressed: onPin,
                ),
                OceanSecondaryButton(
                  key: const Key('trip-document-save-wallet'),
                  label: l10n.tripDocumentSaveToWalletAction,
                  icon: Icons.wallet_rounded,
                  fullWidth: false,
                  onPressed: onSaveToWallet,
                ),
                OceanSecondaryButton(
                  key: const Key('trip-document-delete'),
                  label: l10n.tripDocumentDeleteAction,
                  icon: Icons.delete_rounded,
                  fullWidth: false,
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TripDocumentEditor extends StatefulWidget {
  final Trip trip;
  final TripDocument? document;

  const _TripDocumentEditor({
    required this.trip,
    this.document,
  });

  @override
  State<_TripDocumentEditor> createState() => _TripDocumentEditorState();
}

class _TripDocumentEditorState extends State<_TripDocumentEditor> {
  late final TextEditingController _title;
  late final TextEditingController _notes;
  late final TextEditingController _mediaLabel;
  late final TextEditingController _mediaUrl;
  late TripDocumentType _type;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final doc = widget.document;
    _title = TextEditingController(text: doc?.title ?? '');
    _notes = TextEditingController(text: doc?.notes ?? '');
    _mediaLabel = TextEditingController(text: doc?.mediaLabel ?? '');
    _mediaUrl = TextEditingController(text: doc?.mediaUrl ?? '');
    _type = doc?.type ?? TripDocumentType.pdf;
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _mediaLabel.dispose();
    _mediaUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final doc = widget.document;
    return OceanGlassBottomSheet(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              doc == null
                  ? l10n.tripDocumentCreateTitle
                  : l10n.tripDocumentEditTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('trip-document-title-field'),
              controller: _title,
              decoration:
                  InputDecoration(labelText: l10n.tripDocumentTitleLabel),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<TripDocumentType>(
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
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _notes,
              decoration:
                  InputDecoration(labelText: l10n.tripDocumentNotesLabel),
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              key: const Key('trip-document-media-label-field'),
              controller: _mediaLabel,
              decoration:
                  InputDecoration(labelText: l10n.tripDocumentMediaLabel),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              key: const Key('trip-document-media-url-field'),
              controller: _mediaUrl,
              decoration: InputDecoration(
                labelText: l10n.tripDocumentMediaUrlLabel,
                helperText: l10n.tripDocumentMediaHelper,
              ),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppSpacing.md),
            OceanGlassSurface(
              blur: 0,
              color: AppColors.paleCyan,
              child: Text(
                l10n.tripDocumentNoUploadNotice,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            OceanPrimaryButton(
              key: const Key('trip-document-save'),
              label: l10n.walletSaveAction,
              icon: Icons.save_rounded,
              onPressed: _saving
                  ? null
                  : () {
                      setState(() => _saving = true);
                      final now = app.now();
                      final draft = TripDocument(
                        id: doc?.id ??
                            'doc-local-${now.microsecondsSinceEpoch}-${app.tripDocuments.length}',
                        tripId: widget.trip.id,
                        tripDayId: doc?.tripDayId,
                        tripActivityId: doc?.tripActivityId,
                        type: _type,
                        title: _title.text.trim(),
                        notes: _notes.text.trim(),
                        mediaLabel: _mediaLabel.text.trim(),
                        mediaUrl: _mediaUrl.text.trim(),
                        uploaderName: doc?.uploaderName ?? l10n.demoModeLabel,
                        pinned: doc?.pinned ?? false,
                        createdAt: doc?.createdAt ?? now,
                        updatedAt: now,
                      );
                      final result = doc == null
                          ? app.addTripDocument(draft)
                          : app.updateTripDocument(draft);
                      Navigator.pop(context, result);
                    },
            ),
            const SizedBox(height: AppSpacing.sm),
            OceanSecondaryButton(
              label: l10n.profileCancel,
              icon: Icons.close_rounded,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DocRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.ocean),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelLarge),
                  Text(value, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      );
}

String tripDocumentTypeLabel(AppLocalizations l10n, TripDocumentType type) {
  switch (type) {
    case TripDocumentType.flightTicket:
      return l10n.docTypeFlightTicket;
    case TripDocumentType.hotelBooking:
      return l10n.docTypeHotelBooking;
    case TripDocumentType.trainTicket:
      return l10n.docTypeTrainTicket;
    case TripDocumentType.busTicket:
      return l10n.docTypeBusTicket;
    case TripDocumentType.passport:
      return l10n.docTypePassport;
    case TripDocumentType.visa:
      return l10n.docTypeVisa;
    case TripDocumentType.insurance:
      return l10n.docTypeInsurance;
    case TripDocumentType.tour:
      return l10n.docTypeTour;
    case TripDocumentType.receipt:
      return l10n.docTypeReceipt;
    case TripDocumentType.pdf:
      return l10n.docTypePdf;
    case TripDocumentType.image:
      return l10n.docTypeImage;
    case TripDocumentType.other:
      return l10n.docTypeOther;
  }
}

IconData _documentIcon(TripDocumentType type) {
  switch (type) {
    case TripDocumentType.flightTicket:
      return Icons.flight_rounded;
    case TripDocumentType.hotelBooking:
      return Icons.hotel_rounded;
    case TripDocumentType.trainTicket:
      return Icons.train_rounded;
    case TripDocumentType.busTicket:
      return Icons.directions_bus_rounded;
    case TripDocumentType.passport:
    case TripDocumentType.visa:
      return Icons.badge_rounded;
    case TripDocumentType.insurance:
      return Icons.health_and_safety_rounded;
    case TripDocumentType.tour:
      return Icons.explore_rounded;
    case TripDocumentType.receipt:
      return Icons.receipt_long_rounded;
    case TripDocumentType.pdf:
      return Icons.picture_as_pdf_rounded;
    case TripDocumentType.image:
      return Icons.image_rounded;
    case TripDocumentType.other:
      return Icons.description_rounded;
  }
}
