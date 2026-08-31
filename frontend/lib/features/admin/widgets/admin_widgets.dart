import 'package:flutter/material.dart';

import '../../../core/admin/admin_models.dart';
import '../../../core/network/api_client.dart';
import '../../../design/app_breakpoints.dart';
import '../../../design/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/glass_widgets.dart';

/// Where an admin grid currently stands. Mirrors the partner modules' status
/// enums so the five grids share one vocabulary and one set of views.
enum AdminLoadStatus {
  idle,
  loading,
  ready,
  unauthorized,
  forbidden,
  notFound,
  error,
}

/// Maps an [ApiErrorKind] to the grid status the UI renders.
///
/// Deliberately preserves the backend's distinctions rather than flattening
/// everything to "error": a 403 on an admin route means the session is not an
/// administrator, which is a different remedy from a network failure, and
/// `uncertain` must never be shown as a clean failure.
AdminLoadStatus adminStatusFor(ApiErrorKind? kind) => switch (kind) {
      ApiErrorKind.unauthorized => AdminLoadStatus.unauthorized,
      ApiErrorKind.forbidden => AdminLoadStatus.forbidden,
      ApiErrorKind.notFound => AdminLoadStatus.notFound,
      _ => AdminLoadStatus.error,
    };

/// Renders the non-content states shared by every admin surface.
///
/// One implementation so a loading spinner, an empty grid and a 403 look the
/// same in all six modules — and so a new module cannot accidentally invent a
/// seventh way of saying "nothing here".
class AdminStateView extends StatelessWidget {
  final AdminLoadStatus status;
  final String? message;
  final String? emptyTitle;
  final String? emptyMessage;
  final VoidCallback? onRetry;

  const AdminStateView({
    super.key,
    required this.status,
    this.message,
    this.emptyTitle,
    this.emptyMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          // The grids place this inside an Expanded, so the available height is
          // bounded. On a short viewport (320x900 with a toolbar above) the
          // state card is taller than that box, and without a scroll view it
          // overflows rather than becoming reachable.
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: _content(context)),
          ),
        ),
      );

  Widget _content(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case AdminLoadStatus.loading:
      case AdminLoadStatus.idle:
        return OceanLoadingState(title: l10n.adminLoading);
      case AdminLoadStatus.unauthorized:
        return OceanRecoverableErrorState(
          message: l10n.adminErrorUnauthorized,
          onReload: onRetry,
        );
      case AdminLoadStatus.forbidden:
        // No retry: retrying cannot change the caller's role, and offering one
        // would imply the refusal is transient.
        return OceanRecoverableErrorState(message: l10n.adminErrorForbidden);
      case AdminLoadStatus.notFound:
        return OceanRecoverableErrorState(
          message: l10n.adminErrorNotFound,
          onReload: onRetry,
        );
      case AdminLoadStatus.error:
        return OceanRecoverableErrorState(
          message: message ?? l10n.adminErrorGeneric,
          onReload: onRetry,
        );
      case AdminLoadStatus.ready:
        return OceanEmptyState(
          title: emptyTitle ?? l10n.adminEmptyTitle,
          message: emptyMessage ?? l10n.adminEmptyMessage,
        );
    }
  }
}

/// Page navigation driven entirely by the backend's `PageResponse` metadata.
///
/// `hasNext` comes from the server's `totalPages`, never from "the page came
/// back full", so the last page is correct even when it is exactly full. The
/// row range and total are shown because an operator needs to know the size of
/// what they are looking at before acting on it.
class AdminPaginationBar extends StatelessWidget {
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final int firstRowNumber;
  final int lastRowNumber;
  final bool isLoading;
  final ValueChanged<int> onPageChanged;

  const AdminPaginationBar({
    super.key,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.firstRowNumber,
    required this.lastRowNumber,
    required this.isLoading,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasPrevious = page > 0;
    final hasNext = page + 1 < totalPages;
    final compact = MediaQuery.sizeOf(context).width < AppBreakpoints.tablet;

    final range = totalElements == 0
        ? l10n.adminPaginationEmpty
        : l10n.adminPaginationRange(
            firstRowNumber, lastRowNumber, totalElements);

    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed:
              hasPrevious && !isLoading ? () => onPageChanged(page - 1) : null,
          icon: const Icon(Icons.chevron_left),
          tooltip: l10n.adminPaginationPrevious,
        ),
        Text(
          l10n.adminPaginationPageOf(
              page + 1, totalPages == 0 ? 1 : totalPages),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        IconButton(
          onPressed:
              hasNext && !isLoading ? () => onPageChanged(page + 1) : null,
          icon: const Icon(Icons.chevron_right),
          tooltip: l10n.adminPaginationNext,
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(range,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.xs),
                Center(child: controls),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child:
                      Text(range, style: Theme.of(context).textTheme.bodySmall),
                ),
                controls,
              ],
            ),
    );
  }
}

/// One selectable sort option, mapping a human label to the backend field name.
///
/// The client never sends a free-text sort expression: it sends only a value
/// that came from this list, which the backend then re-validates against its own
/// allowlist and rejects with 400 if unknown. Two independent checks, and the
/// UI cannot express an invalid one.
class AdminSortOption {
  /// Backend entity property, e.g. `createdAt`.
  final String field;

  final String Function(AppLocalizations) label;

  const AdminSortOption({required this.field, required this.label});
}

/// Sort + direction control. Emits `field,dir` exactly as `AdminPaging` parses.
class AdminSortControl extends StatelessWidget {
  final List<AdminSortOption> options;
  final String selectedField;
  final bool descending;
  final bool enabled;
  final void Function(String field, bool descending) onChanged;

  const AdminSortControl({
    super.key,
    required this.options,
    required this.selectedField,
    required this.descending,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButton<String>(
          value: selectedField,
          onChanged: enabled
              ? (v) {
                  if (v != null) onChanged(v, descending);
                }
              : null,
          items: [
            for (final o in options)
              DropdownMenuItem(value: o.field, child: Text(o.label(l10n))),
          ],
        ),
        IconButton(
          onPressed:
              enabled ? () => onChanged(selectedField, !descending) : null,
          icon: Icon(descending ? Icons.arrow_downward : Icons.arrow_upward),
          tooltip:
              descending ? l10n.adminSortDescending : l10n.adminSortAscending,
        ),
      ],
    );
  }
}

/// A single-select filter row. `null` means "no filter", which the client sends
/// by omitting the query parameter entirely rather than sending an empty value.
class AdminFilterChips extends StatelessWidget {
  final List<String> values;
  final String? selected;
  final bool enabled;
  final ValueChanged<String?> onChanged;
  final String Function(BuildContext, String) labelOf;

  const AdminFilterChips({
    super.key,
    required this.values,
    required this.selected,
    required this.enabled,
    required this.onChanged,
    required this.labelOf,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        ChoiceChip(
          label: Text(l10n.adminFilterAll),
          selected: selected == null,
          onSelected: enabled ? (_) => onChanged(null) : null,
        ),
        for (final v in values)
          ChoiceChip(
            label: Text(labelOf(context, v)),
            selected: selected == v,
            onSelected: enabled ? (_) => onChanged(v) : null,
          ),
      ],
    );
  }
}

/// Layout helper: an admin grid is a table on wide viewports and stacked cards
/// on narrow ones. Centralised so no module has to re-decide the breakpoint,
/// and so the 320-wide case is handled identically everywhere.
class AdminResponsiveGrid extends StatelessWidget {
  final WidgetBuilder wide;
  final WidgetBuilder narrow;

  const AdminResponsiveGrid({
    super.key,
    required this.wide,
    required this.narrow,
  });

  /// Tables need real horizontal room; below this a stacked card reads better
  /// than a table that must scroll sideways to show its first useful column.
  static const double tableBreakpoint = AppBreakpoints.desktop;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tableBreakpoint;

  @override
  Widget build(BuildContext context) =>
      isWide(context) ? wide(context) : narrow(context);
}

/// Consistent key/value line used by the narrow-viewport cards.
class AdminCardRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasise;

  const AdminCardRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasise = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              value,
              style: emphasise
                  ? theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)
                  : theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// A status pill coloured by a small, explicit map.
///
/// Colour is always paired with the status text — never the only signal —
/// which keeps the grids readable for colour-blind operators (§10 of the
/// frontend guidance).
class AdminStatusChip extends StatelessWidget {
  final String? status;

  const AdminStatusChip({super.key, required this.status});

  static Color colorFor(BuildContext context, String? status) {
    final scheme = Theme.of(context).colorScheme;
    return switch (status) {
      'CONFIRMED' ||
      'PAID' ||
      'APPROVED' ||
      'COMPLETED' ||
      'ISSUED' =>
        scheme.primary,
      'PENDING' || 'CHECK_IN_READY' => scheme.tertiary,
      'CANCELLED' || 'REJECTED' || 'FAILED' || 'NO_SHOW' => scheme.error,
      'REFUNDED' ||
      'ARCHIVED' ||
      'HIDDEN' ||
      'EXPIRED' =>
        scheme.onSurfaceVariant,
      _ => scheme.onSurfaceVariant,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = status ?? l10n.adminValueUnknown;
    return OceanStatusPill(
      label: label,
      color: colorFor(context, status),
      semanticLabel: label,
    );
  }
}

/// Formatting helpers shared by the admin grids.
///
/// Money is rendered **exactly as the backend supplies it**: the amount is
/// formatted for readability and the currency string is appended verbatim when
/// — and only when — the backend sent one. No locale-derived symbol, no
/// conversion, no client-side arithmetic. Endpoints that omit currency (the
/// admin analytics overview) therefore show a bare number, which is the honest
/// representation of what the server actually said.
class AdminFormats {
  const AdminFormats._();

  static String money(BuildContext context, double? amount, String? currency) {
    final l10n = AppLocalizations.of(context)!;
    if (amount == null) return l10n.adminValueUnknown;
    final formatted = amount
        .toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return currency == null ? formatted : '$formatted $currency';
  }

  static String count(int value) => value
      .toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  static String date(BuildContext context, DateTime? value) {
    if (value == null) return AppLocalizations.of(context)!.adminValueUnknown;
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  static String dateTime(BuildContext context, DateTime? value) {
    if (value == null) return AppLocalizations.of(context)!.adminValueUnknown;
    return '${date(context, value)} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  static String text(BuildContext context, String? value) =>
      value ?? AppLocalizations.of(context)!.adminValueUnknown;
}

/// Wraps a grid body with its filter/sort toolbar and pagination bar.
class AdminGridScaffold extends StatelessWidget {
  final Widget? toolbar;
  final Widget body;
  final AdminPage<Object?>? page;
  final bool isLoading;
  final ValueChanged<int>? onPageChanged;

  const AdminGridScaffold({
    super.key,
    required this.body,
    required this.isLoading,
    this.toolbar,
    this.page,
    this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = page;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (toolbar != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
            child: toolbar,
          ),
        Expanded(child: body),
        if (p != null && onPageChanged != null)
          AdminPaginationBar(
            page: p.page,
            size: p.size,
            totalElements: p.totalElements,
            totalPages: p.totalPages,
            firstRowNumber: p.firstRowNumber,
            lastRowNumber: p.lastRowNumber,
            isLoading: isLoading,
            onPageChanged: onPageChanged!,
          ),
      ],
    );
  }
}
