import '../../core/mock/app_models.dart';

enum TripSection { ongoing, upcoming, past }

DateTime tripDateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

TripSection sectionForTrip(Trip trip, DateTime today) {
  final current = tripDateOnly(today);
  final start = tripDateOnly(trip.startDate);
  final end = tripDateOnly(trip.endDate);
  if (!start.isAfter(current) && !end.isBefore(current)) {
    return TripSection.ongoing;
  }
  if (start.isAfter(current)) return TripSection.upcoming;
  return TripSection.past;
}

Map<TripSection, List<Trip>> groupTripsBySection(
  Iterable<Trip> trips,
  DateTime today,
) {
  final grouped = {
    TripSection.ongoing: <Trip>[],
    TripSection.upcoming: <Trip>[],
    TripSection.past: <Trip>[],
  };
  for (final trip in trips) {
    grouped[sectionForTrip(trip, today)]!.add(trip);
  }
  grouped[TripSection.ongoing]!.sort((a, b) => a.endDate.compareTo(b.endDate));
  grouped[TripSection.upcoming]!
      .sort((a, b) => a.startDate.compareTo(b.startDate));
  grouped[TripSection.past]!.sort((a, b) => b.endDate.compareTo(a.endDate));
  return grouped;
}
