import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../core/mock/mock_data.dart';
import '../../design/app_colors.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../../shared/widgets/travel_cards.dart';
import '../trips/create_trip_screen.dart';

final _money = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

class ExpensesScreen extends StatefulWidget {
  final int? filterTripId;
  const ExpensesScreen({super.key, this.filterTripId});
  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  int? _tripId;

  @override
  void initState() {
    super.initState();
    _tripId = widget.filterTripId;
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final expenses =
        _tripId == null ? app.expenses : app.expensesForTrip(_tripId!);
    final total = expenses.fold<double>(0, (a, b) => a + b.amount);

    Trip? selectedTrip;
    double budget = 0;
    if (_tripId != null) {
      try {
        selectedTrip = app.trips.firstWhere((t) => t.id == _tripId);
        budget = selectedTrip.budget;
      } catch (_) {}
    }

    return ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
        children: [
          Row(children: [
            Expanded(
                child: Text('Expenses',
                    style: Theme.of(context).textTheme.headlineMedium)),
            if (app.trips.isNotEmpty && widget.filterTripId == null)
              IconButton(
                  onPressed: () => _showTripFilter(context, app),
                  icon: Icon(
                      _tripId == null
                          ? Icons.filter_list_rounded
                          : Icons.filter_list_off_rounded,
                      color:
                          _tripId == null ? AppColors.slate : AppColors.ocean)),
            IconButton.filled(
                onPressed: () => _showAddSheet(context, app),
                icon: const Icon(Icons.add_rounded)),
          ]),
          if (_tripId != null && selectedTrip != null)
            Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                    onTap: () => setState(() => _tripId = null),
                    child: Chip(
                        label: Text('Trip: ${selectedTrip.title}',
                            style: const TextStyle(color: AppColors.ocean)),
                        deleteIcon: const Icon(Icons.close_rounded,
                            size: 16, color: AppColors.ocean),
                        onDeleted: () => setState(() => _tripId = null)))),
          const SizedBox(height: 8),
          // Summary card
          GlassCard(
              child: Row(children: [
            _summaryTile('Spent', _money.format(total), AppColors.coral,
                Icons.payments_rounded),
            if (budget > 0) ...[
              const SizedBox(width: 8),
              _summaryTile('Budget', _money.format(budget), AppColors.ocean,
                  Icons.savings_rounded),
              const SizedBox(width: 8),
              _summaryTile(
                  'Left',
                  _money.format((budget - total).clamp(0, double.infinity)),
                  budget - total >= 0 ? AppColors.mint : AppColors.coral,
                  Icons.account_balance_wallet_rounded),
            ],
          ])),
          const SizedBox(height: 16),
          if (expenses.isEmpty)
            const PremiumEmptyState(
                'No expenses yet. Tap + to add your first expense.'),
          ...expenses.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ExpenseCard(
                  expense: e,
                  onEdit: () => _showEditSheet(context, app, e),
                  onDelete: () => _confirmDelete(context, app, e)))),
        ]);
  }

  Widget _summaryTile(String label, String value, Color color, IconData icon) =>
      Expanded(
          child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: color.withValues(alpha: .08)),
              child: Column(children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 4),
                Text(label,
                    style:
                        const TextStyle(fontSize: 10, color: AppColors.slate)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: color,
                        fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ])));

  void _showTripFilter(BuildContext context, AppState app) {
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Filter by trip',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      ListTile(
                          title: const Text('All trips'),
                          leading: const Icon(Icons.apps_rounded),
                          selected: _tripId == null,
                          onTap: () {
                            setState(() => _tripId = null);
                            Navigator.pop(context);
                          }),
                      ...app.trips.map((t) => ListTile(
                          title: Text(t.title),
                          subtitle: Text('${t.days} days'),
                          leading: const Icon(Icons.map_rounded),
                          selected: _tripId == t.id,
                          onTap: () {
                            setState(() => _tripId = t.id);
                            Navigator.pop(context);
                          })),
                    ]))));
  }

  void _showAddSheet(BuildContext context, AppState app) {
    if (app.trips.isEmpty) {
      final nav = Navigator.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Create a trip before adding expenses.'),
          action: SnackBarAction(
              label: 'Create trip',
              onPressed: () => nav.push(MaterialPageRoute(
                  builder: (_) => const CreateTripScreen())))));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExpenseSheet(
        trips: app.trips,
        initialTripId:
            _tripId ?? (app.trips.isNotEmpty ? app.trips.first.id : null),
        onSave: (e) {
          if (!app.addExpense(e)) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content:
                    Text('Expense must belong to a trip and be above 0.')));
            return;
          }
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Expense added!')));
        },
      ),
    );
  }

  void _showEditSheet(BuildContext context, AppState app, Expense e) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExpenseSheet(
        trips: app.trips,
        existing: e,
        initialTripId: e.tripId,
        onSave: (updated) {
          if (!app.updateExpense(updated)) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content:
                    Text('Expense must belong to a trip and be above 0.')));
            return;
          }
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Expense updated!')));
        },
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, AppState app, Expense e) {
    final nav = Navigator.of(ctx);
    final messenger = ScaffoldMessenger.of(ctx);
    showDialog(
        context: ctx,
        builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                title: const Text('Delete expense?'),
                content: Text('Delete "${e.title}"?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel')),
                  FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.coral),
                      onPressed: () {
                        app.deleteExpense(e.id);
                        nav.pop();
                        messenger.showSnackBar(
                            const SnackBar(content: Text('Expense deleted.')));
                      },
                      child: const Text('Delete')),
                ]));
  }
}

// ── Add / Edit expense sheet ─────────────────────────────────────────────────

class _ExpenseSheet extends StatefulWidget {
  final List<Trip> trips;
  final int? initialTripId;
  final Expense? existing;
  final void Function(Expense) onSave;

  const _ExpenseSheet({
    required this.trips,
    required this.onSave,
    this.initialTripId,
    this.existing,
  });

  @override
  State<_ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends State<_ExpenseSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _notesCtrl;
  late String _category;
  late int? _tripId;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _amountCtrl = TextEditingController(
        text: e != null ? e.amount.toInt().toString() : '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _category = e?.category ?? MockData.expenseCategories.first;
    _tripId = e?.tripId ?? widget.initialTripId;
    _date = e?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a title.')));
      return;
    }
    if (_tripId == null && widget.trips.isNotEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select a trip.')));
      return;
    }
    if (_tripId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Create a trip before adding expenses.')));
      return;
    }
    final amount = double.tryParse(
            _amountCtrl.text.replaceAll(',', '').replaceAll('.', '')) ??
        0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Amount must be greater than 0.')));
      return;
    }
    final e = widget.existing;
    final expense = e != null
        ? e.copyWith(
            title: title,
            category: _category,
            amount: amount,
            date: _date,
            notes: _notesCtrl.text.trim(),
            tripId: _tripId,
          )
        : Expense(
            id: DateTime.now().millisecondsSinceEpoch,
            tripId: _tripId!,
            title: title,
            category: _category,
            amount: amount,
            date: _date,
            notes: _notesCtrl.text.trim(),
          );
    widget.onSave(expense);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    return Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                      child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                              color: AppColors.slate.withValues(alpha: .4),
                              borderRadius: BorderRadius.circular(2)))),
                  Text(widget.existing == null ? 'Add expense' : 'Edit expense',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                          hintText: 'Expense title',
                          prefixIcon: Icon(Icons.receipt_long_rounded))),
                  const SizedBox(height: 12),
                  TextField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          hintText: 'Amount (₫)',
                          prefixIcon: Icon(Icons.payments_rounded))),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                          children: MockData.expenseCategories
                              .map((c) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                      label: Text(c),
                                      selected: _category == c,
                                      onSelected: (_) =>
                                          setState(() => _category = c))))
                              .toList())),
                  const SizedBox(height: 12),
                  if (widget.trips.isNotEmpty) ...[
                    DropdownButtonFormField<int>(
                        initialValue: _tripId,
                        decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.map_rounded),
                            hintText: 'Select trip'),
                        items: widget.trips
                            .map((t) => DropdownMenuItem(
                                value: t.id,
                                child: Text(t.title,
                                    overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (v) => setState(() => _tripId = v)),
                    const SizedBox(height: 12),
                  ],
                  GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white.withValues(alpha: .70),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: .80))),
                          child: Row(children: [
                            const Icon(Icons.calendar_today_rounded,
                                color: AppColors.ocean),
                            const SizedBox(width: 12),
                            Text(fmt.format(_date)),
                          ]))),
                  const SizedBox(height: 12),
                  TextField(
                      controller: _notesCtrl,
                      decoration: const InputDecoration(
                          hintText: 'Notes (optional)',
                          prefixIcon: Icon(Icons.notes_rounded))),
                  const SizedBox(height: 20),
                  GlassButton(
                      text: widget.existing == null
                          ? 'Add expense'
                          : 'Save changes',
                      icon: Icons.check_rounded,
                      onPressed: _save),
                ])));
  }
}
