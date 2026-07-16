import '../../core/mock/app_models.dart';

DateTime plannerDateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime plannerDateForDay(Trip trip, int dayNumber) =>
    plannerDateOnly(trip.startDate).add(Duration(days: dayNumber - 1));

int plannerDayForDate(Trip trip, DateTime date) {
  final start = plannerDateOnly(trip.startDate);
  final current = plannerDateOnly(date);
  return current.difference(start).inDays + 1;
}

int clampPlannerDay(Trip trip, int dayNumber) {
  if (trip.days <= 1) return 1;
  return dayNumber.clamp(1, trip.days);
}

bool plannerDayIsInTrip(Trip trip, int dayNumber) =>
    dayNumber >= 1 && dayNumber <= trip.days;

int? plannerMinutesFromTime(String value) {
  final parts = value.trim().split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null ||
      minute == null ||
      hour < 0 ||
      hour > 23 ||
      minute < 0 ||
      minute > 59) {
    return null;
  }
  return hour * 60 + minute;
}

bool plannerHasValidInterval(TimelineItem item) {
  final start = plannerMinutesFromTime(item.startTime);
  final end = plannerMinutesFromTime(item.endTime);
  return start != null && end != null && end > start;
}

int compareTimelineItems(TimelineItem a, TimelineItem b) {
  final aStart = plannerMinutesFromTime(a.startTime);
  final bStart = plannerMinutesFromTime(b.startTime);
  if (aStart != null && bStart != null && aStart != bStart) {
    return aStart.compareTo(bStart);
  }
  if (aStart != null && bStart == null) return -1;
  if (aStart == null && bStart != null) return 1;
  final sortOrder = a.sortOrder.compareTo(b.sortOrder);
  if (sortOrder != 0) return sortOrder;
  return a.id.compareTo(b.id);
}

List<TimelineItem> sortedPlannerItems(
  Iterable<TimelineItem> items, {
  required int tripId,
  required int dayNumber,
}) {
  return items
      .where((item) => item.tripId == tripId && item.dayNumber == dayNumber)
      .toList()
    ..sort(compareTimelineItems);
}

bool plannerIntervalsOverlap(TimelineItem a, TimelineItem b) {
  final aStart = plannerMinutesFromTime(a.startTime);
  final aEnd = plannerMinutesFromTime(a.endTime);
  final bStart = plannerMinutesFromTime(b.startTime);
  final bEnd = plannerMinutesFromTime(b.endTime);
  if (aStart == null || aEnd == null || bStart == null || bEnd == null) {
    return false;
  }
  if (aEnd <= aStart || bEnd <= bStart) return false;
  return aStart < bEnd && bStart < aEnd;
}

TimelineItem? findPlannerConflict(
  Iterable<TimelineItem> items,
  TimelineItem candidate, {
  int? ignoreId,
}) {
  if (!plannerHasValidInterval(candidate)) return null;
  for (final item in items) {
    if (ignoreId != null && item.id == ignoreId) continue;
    if (item.tripId != candidate.tripId) continue;
    if (item.dayNumber != candidate.dayNumber) continue;
    if (plannerIntervalsOverlap(item, candidate)) return item;
  }
  return null;
}
