import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../design/app_colors.dart';
import '../../../../design/app_radii.dart';
import '../../../../design/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/glass_widgets.dart';

/// An inline notice. [warning] is used for the live-policy caution and for
/// server-supplied failures.
class PartnerPolicyNotice extends StatelessWidget {
  final String message;
  final bool warning;

  const PartnerPolicyNotice({
    super.key,
    required this.message,
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        liveRegion: warning,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(
                color: warning ? AppColors.warning : AppColors.divider),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                warning
                    ? Icons.warning_amber_rounded
                    : Icons.info_outline_rounded,
                size: 16,
                color: warning ? AppColors.warning : AppColors.textTertiary,
              ),
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

/// A `HH:mm` policy time.
///
/// Deliberately a constrained text field rather than a clock picker: the
/// backend stores a bare `LocalTime` with no date, and the value round-trips as
/// `"HH:mm"`. Input is filtered to digits and a colon so a malformed string
/// cannot reach the wire.
class PartnerPolicyTimeField extends StatefulWidget {
  final String label;
  final String? value;
  final bool enabled;
  final bool required;
  final ValueChanged<String> onChanged;

  const PartnerPolicyTimeField({
    super.key,
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.required = false,
  });

  @override
  State<PartnerPolicyTimeField> createState() => _PartnerPolicyTimeFieldState();
}

class _PartnerPolicyTimeFieldState extends State<PartnerPolicyTimeField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value ?? '');

  @override
  void didUpdateWidget(PartnerPolicyTimeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Follow an external revert without stomping the caret while typing.
    final incoming = widget.value ?? '';
    if (incoming != oldWidget.value && incoming != _controller.text) {
      _controller.text = incoming;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final missing = widget.required && (widget.value ?? '').isEmpty;

    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      keyboardType: TextInputType.datetime,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
        LengthLimitingTextInputFormatter(5),
      ],
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.required ? '${widget.label} *' : widget.label,
        hintText: 'HH:mm',
        helperText: l10n.partnerPoliciesTimeHelper,
        errorText: missing ? l10n.partnerPoliciesTimeRequired : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        isDense: true,
      ),
    );
  }
}

/// A free-text house rule. Empty clears the field back to null, which is what
/// the backend stores and is genuinely different from an empty string.
class PartnerPolicyTextField extends StatefulWidget {
  final String label;
  final String? value;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  const PartnerPolicyTextField({
    super.key,
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  State<PartnerPolicyTextField> createState() => _PartnerPolicyTextFieldState();
}

class _PartnerPolicyTextFieldState extends State<PartnerPolicyTextField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value ?? '');

  @override
  void didUpdateWidget(PartnerPolicyTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = widget.value ?? '';
    if (incoming != (oldWidget.value ?? '') && incoming != _controller.text) {
      _controller.text = incoming;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      minLines: 1,
      maxLines: 3,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: l10n.partnerPoliciesRuleHint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        isDense: true,
      ),
    );
  }
}

/// A read-only settings row, for values the backend stores as free text with no
/// validated set to offer.
class PartnerPolicyReadOnlyRow extends StatelessWidget {
  final String label;
  final String? value;

  const PartnerPolicyReadOnlyRow({
    super.key,
    required this.label,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final shown = value ?? l10n.partnerPropertyNotSet;

    return Semantics(
      container: true,
      label: '$label: $shown',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  shown,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: value == null
                        ? AppColors.textTertiary
                        : AppColors.textPrimary,
                    fontStyle:
                        value == null ? FontStyle.italic : FontStyle.normal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One notification toggle.
class PartnerPolicySwitch extends StatelessWidget {
  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const PartnerPolicySwitch({
    super.key,
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Material(
        // A ListTile paints its background and ink on the nearest Material
        // ancestor. `OceanGlassCard` is a DecoratedBox with its own gradient,
        // which would hide those effects entirely — Flutter asserts on exactly
        // this. A transparent Material gives the tile something to paint on
        // without altering the glass surface behind it.
        type: MaterialType.transparency,
        child: SwitchListTile.adaptive(
          value: value,
          onChanged: enabled ? onChanged : null,
          title: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      enabled ? AppColors.textPrimary : AppColors.textTertiary,
                ),
          ),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
      );
}

/// Save / revert for one editable section.
///
/// Both controls stay hidden until the draft actually differs, so the console
/// never invites a write that would change nothing.
class PartnerPolicySaveBar extends StatelessWidget {
  final bool dirty;
  final bool saving;
  final bool canSave;
  final VoidCallback onRevert;
  final VoidCallback onSave;

  const PartnerPolicySaveBar({
    super.key,
    required this.dirty,
    required this.saving,
    required this.canSave,
    required this.onRevert,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (saving) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      );
    }

    if (!dirty) {
      return Semantics(
        liveRegion: true,
        child: Text(
          l10n.partnerPoliciesNoChanges,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: AppColors.textTertiary),
        ),
      );
    }

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        OceanPrimaryButton(
          label: l10n.partnerPoliciesSave,
          fullWidth: false,
          onPressed: canSave ? onSave : null,
        ),
        OceanSecondaryButton(
          label: l10n.partnerPoliciesRevert,
          fullWidth: false,
          onPressed: onRevert,
        ),
      ],
    );
  }
}
