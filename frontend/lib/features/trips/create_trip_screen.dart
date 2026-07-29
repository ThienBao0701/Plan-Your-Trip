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

class CreateTripScreen extends StatefulWidget {
  final String? prefilledDestination;
  final int? prefilledTravelers;
  final DateTimeRange? prefilledDateRange;

  const CreateTripScreen({
    super.key,
    this.prefilledDestination,
    this.prefilledTravelers,
    this.prefilledDateRange,
  });

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final title = TextEditingController();
  final destination = TextEditingController();
  final startDate = TextEditingController();
  final endDate = TextEditingController();
  final budget = TextEditingController();
  final notes = TextEditingController();
  final selectedPreferences = <String>{};
  int step = 0;
  int travelers = 2;
  String pace = 'balanced';
  String budgetStyle = 'comfort';
  bool saving = false;
  bool submitted = false;

  @override
  void initState() {
    super.initState();
    destination.text = widget.prefilledDestination ?? '';
    title.text = widget.prefilledDestination?.trim().isNotEmpty == true
        ? '${widget.prefilledDestination!.trim()} trip'
        : '';
    travelers = widget.prefilledTravelers ?? 2;
    final range = widget.prefilledDateRange;
    if (range != null) {
      startDate.text = _formatDate(range.start);
      endDate.text = _formatDate(range.end);
    }
  }

  @override
  void dispose() {
    title.dispose();
    destination.dispose();
    startDate.dispose();
    endDate.dispose();
    budget.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: step == 0 ? l10n.commonBackSemantic : l10n.createBackStep,
          onPressed: step == 0 ? _close : () => setState(() => step--),
          icon: Icon(step == 0
              ? Icons.arrow_back_rounded
              : Icons.chevron_left_rounded),
        ),
        title: Text(l10n.createTripTitle),
        actions: [
          IconButton(
            tooltip: l10n.createCloseSemantic,
            onPressed: _close,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: BubbleBackground(
        child: SafeArea(
          top: false,
          child: ListView(
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
                    Text(
                      l10n.createStepLabel(step + 1),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      child: LinearProgressIndicator(
                        value: (step + 1) / 3,
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: switch (step) {
                        0 => _DestinationStep(
                            key: const ValueKey('create-step-1'),
                            title: title,
                            destination: destination,
                            onSuggestion: (value) {
                              destination.text = value;
                              if (title.text.trim().isEmpty) {
                                title.text = '$value trip';
                              }
                              setState(() {});
                            },
                          ),
                        1 => _DatesStep(
                            key: const ValueKey('create-step-2'),
                            startDate: startDate,
                            endDate: endDate,
                            travelers: travelers,
                            budget: budget,
                            onTravelers: (value) =>
                                setState(() => travelers = value),
                          ),
                        _ => _PersonalizationStep(
                            key: const ValueKey('create-step-3'),
                            title: title,
                            destination: destination,
                            startDate: startDate,
                            endDate: endDate,
                            travelers: travelers,
                            notes: notes,
                            preferences: selectedPreferences,
                            pace: pace,
                            budgetStyle: budgetStyle,
                            onPreference: _togglePreference,
                            onPace: (value) => setState(() => pace = value),
                            onBudgetStyle: (value) =>
                                setState(() => budgetStyle = value),
                          ),
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (saving)
                      const Center(
                        child: SizedBox(
                          width: 360,
                          child: OceanLoadingState(),
                        ),
                      )
                    else
                      OceanPrimaryButton(
                        key: const Key('create-primary-action'),
                        label: step == 2
                            ? l10n.createSubmitAction
                            : l10n.createContinueAction,
                        semanticLabel: step == 2
                            ? l10n.createSubmitSemantic
                            : l10n.createContinueSemantic,
                        icon: step == 2
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                        onPressed: step == 2 ? _submit : _next,
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

  void _togglePreference(String value) {
    setState(() {
      if (selectedPreferences.contains(value)) {
        selectedPreferences.remove(value);
      } else if (selectedPreferences.length < 3) {
        selectedPreferences.add(value);
      }
    });
  }

  void _next() {
    if (step == 0 && !_validateDestination()) return;
    if (step == 1 && !_validateDates()) return;
    setState(() => step++);
  }

  bool _validateDestination() {
    final l10n = AppLocalizations.of(context)!;
    if (destination.text.trim().isEmpty) {
      _snack(l10n.createDestinationRequired);
      return false;
    }
    if (title.text.trim().isEmpty) {
      title.text = '${destination.text.trim()} trip';
    }
    return true;
  }

  bool _validateDates() {
    final l10n = AppLocalizations.of(context)!;
    final start = _parseDate(startDate.text);
    final end = _parseDate(endDate.text);
    if (start == null || end == null) {
      _snack(l10n.createDatesRequired);
      return false;
    }
    if (end.isBefore(start)) {
      _snack(l10n.createInvalidDateRange);
      return false;
    }
    if (travelers < 1 || travelers > 20) {
      _snack(l10n.createInvalidTravelers);
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (saving || submitted) return;
    if (!_validateDestination() || !_validateDates()) return;
    final app = AppScope.of(context);
    final dest = destination.text.trim();
    final tripTitle =
        title.text.trim().isEmpty ? '$dest trip' : title.text.trim();
    final start = _parseDate(startDate.text)!;
    final end = _parseDate(endDate.text)!;

    // Real Mode — backend-confirmed create; never optimistic, never inserts a
    // local demo trip, and preserves the form on a recoverable failure.
    if (!app.demoMode) {
      setState(() => saving = true);
      final result = await app.createRealTrip(
        title: tripTitle,
        destination: dest,
        startDate: start,
        endDate: end,
        description: notes.text.trim().isEmpty ? null : notes.text.trim(),
      );
      if (!mounted) return;
      setState(() => saving = false);
      if (result == TripActionResult.success) {
        final messenger = ScaffoldMessenger.of(context);
        final nav = Navigator.of(context);
        if (nav.canPop()) nav.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.tripCreatedMessage),
          ),
        );
        return;
      }
      _handleRealCreateFailure(result);
      return;
    }

    setState(() {
      saving = true;
      submitted = true;
    });
    final matchedPlace = app.places.where((place) {
      final value = dest.toLowerCase();
      return place.city.toLowerCase().contains(value) ||
          place.locationName.toLowerCase().contains(value) ||
          place.name.toLowerCase().contains(value);
    }).toList();
    final imageUrl = matchedPlace.isEmpty
        ? (app.places.isEmpty ? '' : app.places.first.imageUrl)
        : matchedPlace.first.imageUrl;
    final trip = Trip(
      id: app.newId,
      title: title.text.trim().isEmpty ? '$dest trip' : title.text.trim(),
      destination: dest,
      imageUrl: imageUrl,
      startDate: _parseDate(startDate.text)!,
      endDate: _parseDate(endDate.text)!,
      travelers: travelers,
      budget: _parseBudget(),
      notes: notes.text.trim(),
    );
    app.addTrip(trip);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop(trip);
    } else {
      setState(() => saving = false);
    }
    messenger.showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.tripCreatedMessage)),
    );
  }

  void _handleRealCreateFailure(TripActionResult result) {
    final l10n = AppLocalizations.of(context)!;
    if (result == TripActionResult.sessionExpired) {
      _reauthCreate();
      return;
    }
    final message = result == TripActionResult.forbidden
        ? l10n.tripRealPermissionDeniedMessage
        : l10n.createTripRealErrorMessage;
    _snack(message);
  }

  void _reauthCreate() {
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

  Future<void> _close() async {
    if (!_hasDraft) {
      Navigator.maybePop(context);
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.createDiscardTitle),
        content: Text(l10n.createDiscardMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.profileCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.createDiscardAction),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.maybePop(context);
  }

  bool get _hasDraft =>
      title.text.trim().isNotEmpty ||
      destination.text.trim().isNotEmpty ||
      startDate.text.trim().isNotEmpty ||
      endDate.text.trim().isNotEmpty ||
      budget.text.trim().isNotEmpty ||
      notes.text.trim().isNotEmpty ||
      selectedPreferences.isNotEmpty;

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  double _parseBudget() =>
      double.tryParse(budget.text.replaceAll(',', '').replaceAll('.', '')) ?? 0;

  DateTime? _parseDate(String value) {
    try {
      return DateFormat('dd/MM/yyyy').parseStrict(value.trim());
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime value) => DateFormat('dd/MM/yyyy').format(value);
}

class _DestinationStep extends StatelessWidget {
  final TextEditingController title;
  final TextEditingController destination;
  final ValueChanged<String> onSuggestion;

  const _DestinationStep({
    super.key,
    required this.title,
    required this.destination,
    required this.onSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final suggestions = app.places.map((place) => place.city).toSet().toList();
    return OceanGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.createDestinationTitle,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.createDestinationSubtitle,
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            key: const Key('create-destination-field'),
            controller: destination,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n.createDestinationLabel,
              prefixIcon: const Icon(Icons.place_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: const Key('create-title-field'),
            controller: title,
            decoration: InputDecoration(
              labelText: l10n.createTripNameLabel,
              prefixIcon: const Icon(Icons.drive_file_rename_outline_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.createDestinationSuggestions,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final suggestion in suggestions)
                ActionChip(
                  label: Text(suggestion),
                  onPressed: () => onSuggestion(suggestion),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DatesStep extends StatelessWidget {
  final TextEditingController startDate;
  final TextEditingController endDate;
  final TextEditingController budget;
  final int travelers;
  final ValueChanged<int> onTravelers;

  const _DatesStep({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.travelers,
    required this.budget,
    required this.onTravelers,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.createDatesTitle,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.createDatesSubtitle,
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.lg),
          _DateField(
            key: const Key('create-start-date-field'),
            controller: startDate,
            label: l10n.createStartDateLabel,
          ),
          const SizedBox(height: AppSpacing.md),
          _DateField(
            key: const Key('create-end-date-field'),
            controller: endDate,
            label: l10n.createEndDateLabel,
          ),
          const SizedBox(height: AppSpacing.md),
          _TravelerStepper(value: travelers, onChanged: onTravelers),
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: const Key('create-budget-field'),
            controller: budget,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.createBudgetLabel,
              prefixIcon: const Icon(Icons.savings_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _DateField({super.key, required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      textField: true,
      label: label,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.datetime,
        decoration: InputDecoration(
          labelText: label,
          helperText: l10n.createDateFormatHint,
          prefixIcon: const Icon(Icons.calendar_month_rounded),
        ),
      ),
    );
  }
}

class _TravelerStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _TravelerStepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassSurface(
      blur: 0,
      color: AppColors.surfaceOverlay,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.createTravelersLabel,
                    style: Theme.of(context).textTheme.titleMedium),
                Text(l10n.tripTravelerCount(value),
                    style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
          IconButton.outlined(
            tooltip: l10n.createDecreaseTravelers,
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton.outlined(
            tooltip: l10n.createIncreaseTravelers,
            onPressed: value < 20 ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}

class _PersonalizationStep extends StatelessWidget {
  final TextEditingController title;
  final TextEditingController destination;
  final TextEditingController startDate;
  final TextEditingController endDate;
  final TextEditingController notes;
  final int travelers;
  final Set<String> preferences;
  final String pace;
  final String budgetStyle;
  final ValueChanged<String> onPreference;
  final ValueChanged<String> onPace;
  final ValueChanged<String> onBudgetStyle;

  const _PersonalizationStep({
    super.key,
    required this.title,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.notes,
    required this.travelers,
    required this.preferences,
    required this.pace,
    required this.budgetStyle,
    required this.onPreference,
    required this.onPace,
    required this.onBudgetStyle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final prefOptions = {
      'food': l10n.createPreferenceFood,
      'culture': l10n.createPreferenceCulture,
      'nature': l10n.createPreferenceNature,
      'relax': l10n.createPreferenceRelax,
      'adventure': l10n.createPreferenceAdventure,
      'shopping': l10n.createPreferenceShopping,
    };
    return OceanGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.createPersonalizationTitle,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.createPersonalizationSubtitle,
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.createPreferencesTitle,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final entry in prefOptions.entries)
                FilterChip(
                  label: Text(entry.value),
                  selected: preferences.contains(entry.key),
                  onSelected: (_) => onPreference(entry.key),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _SegmentedDraftChoice(
            title: l10n.createPaceTitle,
            value: pace,
            options: {
              'slow': l10n.createPaceSlow,
              'balanced': l10n.createPaceBalanced,
              'packed': l10n.createPacePacked,
            },
            onChanged: onPace,
          ),
          const SizedBox(height: AppSpacing.md),
          _SegmentedDraftChoice(
            title: l10n.createBudgetStyleTitle,
            value: budgetStyle,
            options: {
              'saving': l10n.createBudgetSaving,
              'comfort': l10n.createBudgetComfort,
              'premium': l10n.createBudgetPremium,
            },
            onChanged: onBudgetStyle,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: notes,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: l10n.createNotesLabel,
              prefixIcon: const Icon(Icons.notes_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OceanGlassSurface(
            blur: 0,
            color: AppColors.paleCyan,
            child: Text(
              l10n.createPersonalizationLocalOnly,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.createReviewTitle,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.createReviewSummary(
              title.text.trim().isEmpty
                  ? destination.text.trim()
                  : title.text.trim(),
              destination.text.trim(),
              startDate.text.trim(),
              endDate.text.trim(),
              travelers,
            ),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _SegmentedDraftChoice extends StatelessWidget {
  final String title;
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  const _SegmentedDraftChoice({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          SegmentedButton<String>(
            segments: [
              for (final entry in options.entries)
                ButtonSegment(value: entry.key, label: Text(entry.value)),
            ],
            selected: {value},
            onSelectionChanged: (values) => onChanged(values.first),
          ),
        ],
      );
}
