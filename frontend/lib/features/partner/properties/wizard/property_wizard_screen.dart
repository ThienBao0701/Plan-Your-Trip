import 'package:flutter/material.dart';

import '../../../../app/surface_gate.dart';
import '../../../../app/routing/surface_router.dart';
import '../../../../core/partner/partner_property_models.dart';
import '../../../../core/partner/property_messages.dart';
import '../../../../design/app_breakpoints.dart';
import '../../../../design/app_colors.dart';
import '../../../../design/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import 'property_wizard_state.dart';
import 'property_wizard_steps.dart';

/// The Partner property onboarding wizard.
///
/// Seven steps over the Phase C property API — a readiness checkpoint, five
/// sections of the record, and a review. What it does **not** contain is as
/// deliberate as what it does: there is no publish action, no room, media,
/// pricing or availability, and no local copy of a property pretending to be
/// saved. A draft exists exactly when the backend says it does.
class PartnerPropertyWizardScreen extends StatefulWidget {
  final PropertyWizardState state;

  /// Called after a save the server confirmed, so the list behind the wizard
  /// can reload from the backend.
  final ValueChanged<PartnerPropertyDetail>? onSaved;

  const PartnerPropertyWizardScreen({
    super.key,
    required this.state,
    this.onSaved,
  });

  @override
  State<PartnerPropertyWizardScreen> createState() =>
      _PartnerPropertyWizardScreenState();
}

class _PartnerPropertyWizardScreenState
    extends State<PartnerPropertyWizardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = PropertyWizardControllers();
  final _headingFocus = FocusNode(debugLabel: 'wizard-step-heading');

  PropertyWizardStep? _renderedStep;
  bool _showStepError = false;

  PropertyWizardState get _state => widget.state;

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _state.load();
      if (mounted) _controllers.syncFrom(_state);
    });
  }

  void _onStateChanged() {
    // A step change moves focus to the new heading, so assistive technology
    // follows the wizard instead of staying on the previous step's last field.
    final step = _state.currentStep;
    if (_renderedStep != step) {
      _renderedStep = step;
      _showStepError = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _headingFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    _controllers.dispose();
    _headingFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) => PopScope(
        // Leaving with unsaved work asks first; nothing typed is dropped
        // silently.
        canPop: !_state.hasUnsavedChanges,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _confirmExit();
        },
        child: Scaffold(
          appBar: OceanGlassAppBar(
            leading: IconButton(
              key: const Key('wizard-close'),
              tooltip: l10n.commonBackSemantic,
              onPressed: _state.isSaving ? null : _confirmExit,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            title: Text(l10n.partnerWizardTitle),
          ),
          body: BubbleBackground(
            child: SafeArea(
              top: false,
              child: switch (_state.status) {
                PropertyWizardStatus.loading => _centered(
                    key: const Key('wizard-loading'),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: AppSpacing.md),
                        Text(l10n.partnerWizardLoading),
                      ],
                    ),
                  ),
                PropertyWizardStatus.referenceError => _centered(
                    key: const Key('wizard-reference-error'),
                    child: OceanStateView(
                      icon: Icons.cloud_off_rounded,
                      title: l10n.partnerPropertyReferenceError,
                      message: l10n.partnerWizardSubtitle,
                      semanticLabel: l10n.partnerPropertyReferenceError,
                      actionLabel: l10n.partnerActionRetry,
                      onAction: () async {
                        await _state.load();
                        if (mounted) _controllers.syncFrom(_state);
                      },
                    ),
                  ),
                PropertyWizardStatus.propertyError => _centered(
                    key: const Key('wizard-property-error'),
                    child: OceanStateView(
                      icon: Icons.error_outline_rounded,
                      title: l10n.partnerWizardPropertyError,
                      message: _state.failure == null
                          ? l10n.partnerPropertyActionNotFound
                          : propertyFailureMessage(l10n, _state.failure!),
                      semanticLabel: l10n.partnerWizardPropertyError,
                      actionLabel: l10n.partnerWizardReviewDone,
                      onAction: () => Navigator.maybePop(context),
                    ),
                  ),
                PropertyWizardStatus.ready => _body(context, l10n),
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _centered({required Widget child, Key? key}) => Center(
        key: key,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: OceanContentConstraint(
            maxWidth: AppBreakpoints.maxContentWidth,
            child: child,
          ),
        ),
      );

  Widget _body(BuildContext context, AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The rail needs room of its own; below a tablet the steps become a
        // single compact line above the form instead.
        final wide = constraints.maxWidth >= AppBreakpoints.tablet;
        final content = Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: OceanContentConstraint(
              maxWidth: AppBreakpoints.maxContentWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _draftBanner(context, l10n),
                  const SizedBox(height: AppSpacing.md),
                  OceanGlassCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: PropertyWizardStepView(
                        state: _state,
                        controllers: _controllers,
                        headingFocus: _headingFocus,
                        onEditBusinessProfile: _openBusinessProfile,
                        onJump: _jumpTo,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        return Column(
          children: [
            if (!wide) _CompactSteps(state: _state, onJump: _jumpTo),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (wide) _StepRail(state: _state, onJump: _jumpTo),
                  Expanded(child: Column(children: [content])),
                ],
              ),
            ),
            _ActionBar(
              state: _state,
              showStepError: _showStepError,
              onBack: _state.currentStep.isFirst ? null : _state.goBack,
              onContinue: _continue,
              onSave: _save,
            ),
          ],
        );
      },
    );
  }

  Widget _draftBanner(BuildContext context, AppLocalizations l10n) => Container(
        key: const Key('wizard-draft-banner'),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        child: Row(
          children: [
            const Icon(Icons.edit_note_rounded, size: 18),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                l10n.partnerWizardDraftNotice,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      );

  void _jumpTo(PropertyWizardStep step) {
    if (!_state.goTo(step)) {
      setState(() => _showStepError = true);
    }
  }

  void _continue() {
    // The form's own validators speak for the fields; the state decides whether
    // the step as a whole may be left.
    _formKey.currentState?.validate();
    if (_state.goNext()) return;
    setState(() => _showStepError = true);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    _formKey.currentState?.validate();
    final saved = await _state.saveDraft();
    if (!mounted) return;
    _controllers.syncFrom(_state);
    final record = _state.saved;
    if (!saved || record == null) return;

    // Only now, with the server's own record in hand, is anything reported as
    // saved.
    widget.onSaved?.call(record);
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(l10n.partnerWizardReviewSavedBody(record.name)),
      ),
    );
  }

  Future<void> _openBusinessProfile() =>
      SurfaceNavigation.open(context, SurfaceRouter.account);

  /// Save / discard / keep editing, then leave. Never loses typed data without
  /// asking.
  Future<void> _confirmExit() async {
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    if (!_state.hasUnsavedChanges) {
      navigator.pop();
      return;
    }

    final choice = await showDialog<_ExitChoice>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('wizard-leave-dialog'),
        title: Text(l10n.partnerWizardLeaveTitle),
        content: Text(l10n.partnerWizardLeaveBody),
        actions: [
          TextButton(
            key: const Key('wizard-leave-cancel'),
            onPressed: () => Navigator.of(context).pop(_ExitChoice.cancel),
            child: Text(l10n.partnerWizardLeaveCancel),
          ),
          TextButton(
            key: const Key('wizard-leave-discard'),
            onPressed: () => Navigator.of(context).pop(_ExitChoice.discard),
            child: Text(l10n.partnerWizardLeaveDiscard),
          ),
          if (_state.canSaveDraft)
            TextButton(
              key: const Key('wizard-leave-save'),
              onPressed: () => Navigator.of(context).pop(_ExitChoice.save),
              child: Text(l10n.partnerWizardLeaveSave),
            ),
        ],
      ),
    );
    if (!mounted || choice == null || choice == _ExitChoice.cancel) return;

    if (choice == _ExitChoice.discard) {
      _state.discardChanges();
      _controllers.syncFrom(_state);
      navigator.pop();
      return;
    }

    await _save();
    if (!mounted) return;
    // A refused save keeps the wizard open with everything intact.
    if (_state.failure == null) navigator.pop();
  }
}

enum _ExitChoice { save, discard, cancel }

/// The desktop progress rail: where the partner is, what is done, and what can
/// be opened directly.
class _StepRail extends StatelessWidget {
  final PropertyWizardState state;
  final ValueChanged<PropertyWizardStep> onJump;

  const _StepRail({required this.state, required this.onJump});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: l10n.partnerWizardProgressLabel,
      child: SizedBox(
        width: 240,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final step in PropertyWizardStep.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: _RailEntry(
                    step: step,
                    label: stepLabel(l10n, step),
                    current: state.currentStep == step,
                    complete: state.isStepComplete(step),
                    enabled: state.canOpen(step),
                    onTap: () => onJump(step),
                    theme: theme,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailEntry extends StatelessWidget {
  final PropertyWizardStep step;
  final String label;
  final bool current;
  final bool complete;
  final bool enabled;
  final VoidCallback onTap;
  final ThemeData theme;

  const _RailEntry({
    required this.step,
    required this.label,
    required this.current,
    required this.complete,
    required this.enabled,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      selected: current,
      // The state is in words as well as colour: "complete" is never only a
      // green tick.
      label:
          '${l10n.partnerWizardStepOf(step.index + 1, PropertyWizardStep.values.length)}: $label'
          '${complete ? ', ${l10n.partnerWizardReviewComplete}' : ''}',
      child: TextButton(
        key: Key('wizard-rail-${step.name}'),
        onPressed: enabled ? onTap : null,
        style: TextButton.styleFrom(
          alignment: AlignmentDirectional.centerStart,
          backgroundColor: current ? AppColors.paleCyan : null,
        ),
        child: Row(
          children: [
            Icon(
              complete
                  ? Icons.check_circle_rounded
                  : (current
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded),
              size: 18,
              color: complete ? AppColors.ocean : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                  color: enabled ? AppColors.textPrimary : AppColors.disabled,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The phone-width progress line: one row, scrollable, same rules.
class _CompactSteps extends StatelessWidget {
  final PropertyWizardState state;
  final ValueChanged<PropertyWizardStep> onJump;

  const _CompactSteps({required this.state, required this.onJump});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final step = state.currentStep;
    return Semantics(
      container: true,
      label: l10n.partnerWizardProgressLabel,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.partnerWizardStepOf(
                  step.index + 1, PropertyWizardStep.values.length),
              key: const Key('wizard-compact-step'),
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: AppSpacing.xxs),
            LinearProgressIndicator(
              value: (step.index + 1) / PropertyWizardStep.values.length,
            ),
          ],
        ),
      ),
    );
  }
}

/// The persistent action area: Back, the save state, Save draft and Continue.
class _ActionBar extends StatelessWidget {
  final PropertyWizardState state;
  final bool showStepError;
  final VoidCallback? onBack;
  final VoidCallback onContinue;
  final Future<void> Function() onSave;

  const _ActionBar({
    required this.state,
    required this.showStepError,
    required this.onBack,
    required this.onContinue,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final failure = state.failure;
    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showStepError && !state.isStepValid(state.currentStep))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                l10n.partnerWizardStepIncomplete,
                key: const Key('wizard-step-error'),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.danger),
              ),
            ),
          if (failure != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                propertyFailureMessage(l10n, failure),
                key: const Key('wizard-save-error'),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.danger),
              ),
            ),
          Text(
            _saveHint(l10n),
            key: const Key('wizard-save-hint'),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              if (onBack != null)
                OceanSecondaryButton(
                  key: const Key('wizard-back'),
                  label: l10n.partnerWizardActionBack,
                  icon: Icons.arrow_back_rounded,
                  fullWidth: false,
                  onPressed: state.isSaving ? null : onBack,
                ),
              OceanSecondaryButton(
                key: const Key('wizard-save'),
                label: l10n.partnerWizardActionSaveDraft,
                icon: Icons.save_outlined,
                fullWidth: false,
                onPressed: state.canSaveDraft ? () => onSave() : null,
              ),
              if (!state.currentStep.isLast)
                OceanPrimaryButton(
                  key: const Key('wizard-continue'),
                  label: l10n.partnerWizardActionContinue,
                  icon: Icons.arrow_forward_rounded,
                  fullWidth: false,
                  onPressed: state.isSaving ? null : onContinue,
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// What the save state is right now — never "saved" before the server said so.
  String _saveHint(AppLocalizations l10n) {
    if (state.isSaving) return l10n.partnerWizardSaving;
    final block = state.saveBlock;
    if (block == PropertyWizardSaveBlock.incompleteForCreate) {
      return l10n.partnerWizardSaveBlockedCreate;
    }
    final savedAt = state.lastSavedAt;
    if (block == PropertyWizardSaveBlock.nothingToSave) {
      if (savedAt == null) return l10n.partnerWizardSaveBlockedClean;
      final now = DateTime.now();
      final justNow = now.difference(savedAt).inMinutes < 1;
      return justNow
          ? l10n.partnerWizardSavedJustNow
          : l10n.partnerWizardSavedAt(
              '${savedAt.hour.toString().padLeft(2, '0')}:'
              '${savedAt.minute.toString().padLeft(2, '0')}');
    }
    return l10n.partnerWizardDraftNotice;
  }
}
