import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/mock/app_models.dart';
import '../../core/mock/mock_data.dart';
import '../../design/app_colors.dart';
import '../../design/app_spacing.dart';
import 'glass_widgets.dart';

final _money = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

class PlaceCard extends StatelessWidget {
  final Place place;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;
  const PlaceCard({super.key, required this.place, this.onTap, this.onAdd});
  @override
  Widget build(BuildContext context) => GlassCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radius)),
            child: Image.network(place.imageUrl,
                height: 130,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    height: 130,
                    color: AppColors.ocean.withValues(alpha: .18)))),
        Padding(
            padding: const EdgeInsets.all(12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text(place.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium)),
                const Icon(Icons.star_rounded,
                    color: AppColors.warning, size: 18),
                Text(' ${place.rating}',
                    style: const TextStyle(fontWeight: FontWeight.w700))
              ]),
              const SizedBox(height: 4),
              Text(
                  '${place.locationName} • ${place.category} • ${place.priceLevel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: Text(place.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium)),
                IconButton.filledTonal(
                    onPressed: onAdd, icon: const Icon(Icons.add_rounded))
              ]),
            ])),
      ]));
}

class TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback? onTap;
  const TripCard({super.key, required this.trip, this.onTap});
  @override
  Widget build(BuildContext context) => GlassCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Stack(children: [
        ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radius),
            child: Image.network(trip.imageUrl,
                height: 210,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    height: 210,
                    color: AppColors.violet.withValues(alpha: .25)))),
        Positioned.fill(
            child: DecoratedBox(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.radius),
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: .08),
                          Colors.black.withValues(alpha: .65)
                        ])))),
        Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(trip.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: Colors.white)),
              const SizedBox(height: 6),
              Text(
                  '${DateFormat('dd/MM').format(trip.startDate)} – ${DateFormat('dd/MM/yyyy').format(trip.endDate)} • ${trip.days} days • ${trip.travelers} travelers',
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Text('Budget ${_money.format(trip.budget)}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800)),
            ])),
      ]));
}

class TimelineCard extends StatelessWidget {
  final TimelineItem item;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  const TimelineCard(
      {super.key, required this.item, this.onDelete, this.onEdit});
  @override
  Widget build(BuildContext context) => GlassCard(
      onTap: onEdit,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Text(item.startTime,
              style: const TextStyle(
                  fontWeight: FontWeight.w900, color: AppColors.ocean)),
          Container(
              width: 2,
              height: 52,
              margin: const EdgeInsets.symmetric(vertical: 6),
              color: AppColors.ocean.withValues(alpha: .28)),
          Text(item.endTime,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.slate))
        ]),
        const SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.title, style: Theme.of(context).textTheme.titleMedium),
          if (item.place != null)
            Text(item.place!.name,
                style: const TextStyle(
                    color: AppColors.ocean, fontWeight: FontWeight.w700)),
          if (item.category.isNotEmpty)
            Chip(
                label:
                    Text(item.category, style: const TextStyle(fontSize: 11)),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact),
          const SizedBox(height: 4),
          if (item.notes.isNotEmpty)
            Text(item.notes, style: Theme.of(context).textTheme.bodyMedium)
        ])),
        Column(children: [
          if (onEdit != null)
            IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined,
                    color: AppColors.ocean, size: 20)),
          IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.coral)),
        ]),
      ]));
}

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const ExpenseCard(
      {super.key, required this.expense, this.onEdit, this.onDelete});
  @override
  Widget build(BuildContext context) => GlassCard(
          child: Row(children: [
        CircleAvatar(
            backgroundColor: AppColors.ocean.withValues(alpha: .12),
            child: Icon(MockData.expenseCategoryIcon(expense.category),
                color: AppColors.ocean, size: 20)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(expense.title, style: Theme.of(context).textTheme.titleMedium),
          Text(expense.category, style: Theme.of(context).textTheme.bodyMedium)
        ])),
        Text(_money.format(expense.amount),
            style: const TextStyle(
                fontWeight: FontWeight.w900, color: AppColors.midnight)),
        const SizedBox(width: 4),
        PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                color: AppColors.slate, size: 20),
            onSelected: (v) {
              if (v == 'edit') onEdit?.call();
              if (v == 'delete') onDelete?.call();
            },
            itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Edit')
                      ])),
                  const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline_rounded,
                            size: 18, color: AppColors.coral),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: AppColors.coral))
                      ])),
                ]),
      ]));
}
