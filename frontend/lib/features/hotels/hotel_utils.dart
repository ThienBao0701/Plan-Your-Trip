import 'dart:math' as math;

import '../../core/mock/app_models.dart';

enum HotelCriteriaError {
  pastCheckIn,
  checkOutNotAfterCheckIn,
  invalidAdults,
  invalidChildren,
  invalidExtraBeds,
}

enum BookingSection { all, upcoming, active, history, cancelled }

DateTime hotelDateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

HotelStayCriteria defaultHotelCriteria({
  required DateTime today,
  Trip? trip,
}) {
  if (trip != null &&
      !hotelDateOnly(trip.endDate).isBefore(hotelDateOnly(today))) {
    final checkIn = hotelDateOnly(trip.startDate).isBefore(hotelDateOnly(today))
        ? hotelDateOnly(today)
        : hotelDateOnly(trip.startDate);
    final tripCheckOut = hotelDateOnly(trip.endDate);
    final checkOut = tripCheckOut.isAfter(checkIn)
        ? tripCheckOut
        : checkIn.add(const Duration(days: 1));
    return HotelStayCriteria(
      destination: trip.destination,
      checkIn: checkIn,
      checkOut: checkOut,
      adults: math.max(1, trip.travelers),
      children: 0,
      tripId: trip.id,
    );
  }
  return HotelStayCriteria(
    checkIn: hotelDateOnly(today).add(const Duration(days: 7)),
    checkOut: hotelDateOnly(today).add(const Duration(days: 9)),
    adults: 2,
    children: 0,
  );
}

HotelCriteriaError? validateHotelCriteria(
  HotelStayCriteria criteria, {
  required DateTime today,
}) {
  final current = hotelDateOnly(today);
  final checkIn = hotelDateOnly(criteria.checkIn);
  final checkOut = hotelDateOnly(criteria.checkOut);
  if (checkIn.isBefore(current)) return HotelCriteriaError.pastCheckIn;
  if (!checkOut.isAfter(checkIn)) {
    return HotelCriteriaError.checkOutNotAfterCheckIn;
  }
  if (criteria.adults < 1) return HotelCriteriaError.invalidAdults;
  if (criteria.children < 0) return HotelCriteriaError.invalidChildren;
  if (criteria.extraBeds < 0) return HotelCriteriaError.invalidExtraBeds;
  return null;
}

List<Place> accommodationPlaces(List<Place> places) {
  final result = places
      .where((place) =>
          place.effectiveCategorySlug.toLowerCase() == 'accommodation')
      .toList();
  result.sort((a, b) {
    final featured = (b.isFeatured ? 1 : 0).compareTo(a.isFeatured ? 1 : 0);
    if (featured != 0) return featured;
    final rating = b.rating.compareTo(a.rating);
    return rating == 0 ? a.name.compareTo(b.name) : rating;
  });
  return result;
}

List<Place> filterHotels(List<Place> hotels, HotelStayCriteria criteria) {
  final keyword = criteria.destination.trim().toLowerCase();
  if (keyword.isEmpty) return List<Place>.from(hotels);
  return hotels
      .where((hotel) =>
          hotel.name.toLowerCase().contains(keyword) ||
          hotel.city.toLowerCase().contains(keyword) ||
          hotel.locationName.toLowerCase().contains(keyword) ||
          hotel.province.toLowerCase().contains(keyword) ||
          hotel.description.toLowerCase().contains(keyword) ||
          hotel.tags.any((tag) => tag.toLowerCase().contains(keyword)))
      .toList();
}

List<HotelRoom> availableRoomsFor(
  Place hotel,
  HotelStayCriteria criteria,
) {
  final rooms = hotel.hotelDetail?.rooms ?? const <HotelRoom>[];
  final result =
      rooms.where((room) => roomFitsCriteria(room, criteria)).toList();
  result.sort((a, b) {
    final aPrice = a.priceFrom ?? double.infinity;
    final bPrice = b.priceFrom ?? double.infinity;
    final price = aPrice.compareTo(bPrice);
    return price == 0 ? a.roomName.compareTo(b.roomName) : price;
  });
  return result;
}

bool roomFitsCriteria(HotelRoom room, HotelStayCriteria criteria) {
  return room.sellable &&
      criteria.adults <= room.maxAdults &&
      criteria.children <= room.maxChildren &&
      criteria.guests <= room.maxGuests;
}

HotelPricingQuote buildLocalHotelQuote({
  required Place hotel,
  required HotelRoom room,
  required HotelRatePlan ratePlan,
  required HotelStayCriteria criteria,
  required DateTime generatedAt,
  String currency = 'VND',
}) {
  final nights = math.max(1, criteria.nights);
  if (!ratePlan.eligible) {
    return HotelPricingQuote(
      roomId: room.id,
      roomName: room.roomName,
      roomCode: room.roomCode,
      placeId: hotel.id,
      hotelId: hotel.id,
      checkIn: hotelDateOnly(criteria.checkIn),
      checkOut: hotelDateOnly(criteria.checkOut),
      nights: nights,
      adults: criteria.adults,
      children: criteria.children,
      extraBeds: criteria.extraBeds,
      selectedRatePlanId: ratePlan.ratePlanId,
      selectedRatePlanCode: ratePlan.code,
      selectedRatePlanName: ratePlan.rateName,
      mealPlanType: ratePlan.mealPlan,
      cancellationPolicyType: ratePlan.cancellationPolicyType,
      refundable: ratePlan.refundable,
      cancellationDeadline: ratePlan.cancellationDeadline,
      currency: currency,
      inventoryAvailable: room.sellable,
      availableRooms: room.availableQuantity,
      quoteGeneratedAt: generatedAt,
      quoteExpiresAt: generatedAt.add(const Duration(minutes: 15)),
      eligibilityReason: ratePlan.reason,
    );
  }

  final nightly = ratePlan.finalNightlyRate ??
      (ratePlan.baseNightlyRate ?? room.priceFrom ?? 0) +
          ratePlan.derivedAdjustment +
          ratePlan.occupancyAdjustment +
          ratePlan.childSupplement +
          ratePlan.extraBedSupplement;
  final subtotal = ratePlan.staySubtotal ?? nightly * nights;
  return HotelPricingQuote(
    roomId: room.id,
    roomName: room.roomName,
    roomCode: room.roomCode,
    placeId: hotel.id,
    hotelId: hotel.id,
    checkIn: hotelDateOnly(criteria.checkIn),
    checkOut: hotelDateOnly(criteria.checkOut),
    nights: nights,
    adults: criteria.adults,
    children: criteria.children,
    extraBeds: criteria.extraBeds,
    selectedRatePlanId: ratePlan.ratePlanId,
    selectedRatePlanCode: ratePlan.code,
    selectedRatePlanName: ratePlan.rateName,
    mealPlanType: ratePlan.mealPlan,
    cancellationPolicyType: ratePlan.cancellationPolicyType,
    refundable: ratePlan.refundable,
    cancellationDeadline: ratePlan.cancellationDeadline,
    baseNightlyRate: ratePlan.baseNightlyRate ?? room.priceFrom,
    derivedAdjustment: ratePlan.derivedAdjustment,
    occupancyAdjustment: ratePlan.occupancyAdjustment,
    childSupplement: ratePlan.childSupplement,
    extraBedSupplement: ratePlan.extraBedSupplement,
    finalNightlyRate: nightly,
    staySubtotal: subtotal,
    totalBeforeCustomerBenefits: subtotal,
    finalQuotedPrice: subtotal,
    currency: currency,
    inventoryAvailable: room.sellable,
    availableRooms: room.availableQuantity,
    quoteGeneratedAt: generatedAt,
    quoteExpiresAt: generatedAt.add(const Duration(minutes: 15)),
    warnings: const ['Local preview quote. No inventory is reserved.'],
  );
}

bool quoteBlocksConfirmation(
  HotelPricingQuote quote, {
  required DateTime now,
}) {
  return hotelDateOnly(now).isAfter(hotelDateOnly(quote.quoteExpiresAt)) ||
      now.isAfter(quote.quoteExpiresAt) ||
      !quote.inventoryAvailable ||
      quote.finalQuotedPrice == null ||
      quote.finalQuotedPrice! <= 0;
}

bool bookingInSection(
  DemoBooking booking,
  BookingSection section, {
  required DateTime today,
}) {
  if (section == BookingSection.all) return true;
  final current = hotelDateOnly(today);
  final checkIn = hotelDateOnly(booking.criteria.checkIn);
  switch (section) {
    case BookingSection.upcoming:
      return (booking.status == BookingStatus.pending ||
              booking.status == BookingStatus.confirmed ||
              booking.status == BookingStatus.checkInReady) &&
          !checkIn.isBefore(current);
    case BookingSection.active:
      return booking.status == BookingStatus.checkedIn;
    case BookingSection.history:
      return booking.status == BookingStatus.checkedOut ||
          booking.status == BookingStatus.completed ||
          booking.status == BookingStatus.cancelled ||
          booking.status == BookingStatus.refunded ||
          booking.status == BookingStatus.archived ||
          booking.status == BookingStatus.noShow;
    case BookingSection.cancelled:
      return booking.status == BookingStatus.cancelled;
    case BookingSection.all:
      return true;
  }
}

List<BookingTimelineEvent> bookingTimelineFor(DemoBooking booking) {
  final events = <BookingTimelineEvent>[
    BookingTimelineEvent(code: 'CREATED', occurredAt: booking.createdAt),
  ];
  if (booking.paidAt != null &&
      booking.paymentStatus == BookingPaymentStatus.paid) {
    events.add(BookingTimelineEvent(code: 'PAID', occurredAt: booking.paidAt!));
  }
  if (booking.confirmedAt != null) {
    events.add(BookingTimelineEvent(
      code: 'CONFIRMED',
      occurredAt: booking.confirmedAt!,
    ));
  }
  if (booking.modifiedAt != null) {
    events.add(BookingTimelineEvent(
      code: 'MODIFIED',
      occurredAt: booking.modifiedAt!,
    ));
  }
  if (booking.actualCheckInAt != null) {
    events.add(BookingTimelineEvent(
      code: 'CHECKED_IN',
      occurredAt: booking.actualCheckInAt!,
    ));
  }
  if (booking.actualCheckOutAt != null) {
    events.add(BookingTimelineEvent(
      code: 'CHECKED_OUT',
      occurredAt: booking.actualCheckOutAt!,
    ));
  }
  if (booking.completedAt != null) {
    events.add(BookingTimelineEvent(
      code: 'COMPLETED',
      occurredAt: booking.completedAt!,
    ));
  }
  if (booking.cancelledAt != null) {
    events.add(BookingTimelineEvent(
      code: 'CANCELLED',
      occurredAt: booking.cancelledAt!,
    ));
  }
  if (booking.archivedAt != null) {
    events.add(BookingTimelineEvent(
      code: 'ARCHIVED',
      occurredAt: booking.archivedAt!,
    ));
  }
  if (booking.refundedAt != null &&
      booking.paymentStatus == BookingPaymentStatus.refunded) {
    events.add(BookingTimelineEvent(
      code: 'REFUNDED',
      occurredAt: booking.refundedAt!,
    ));
  }
  events.sort((a, b) {
    final time = a.occurredAt.compareTo(b.occurredAt);
    return time == 0 ? a.code.compareTo(b.code) : time;
  });
  return events;
}

bool itineraryAlreadyHasBooking(
  List<TimelineItem> timeline,
  DemoBooking booking,
) {
  final tripId = booking.criteria.tripId;
  if (tripId == null) return false;
  return timeline.any((item) =>
      item.tripId == tripId &&
      item.placeId == booking.hotel.id &&
      item.title == booking.hotel.name &&
      item.category == 'Hotel');
}
