/// Typed models for the Partner Bookings module (C8), mapped one-to-one from
/// `backend-v1` (branch `develop`).
///
/// Source of truth, read from the authoritative backend worktree and verified
/// against the running backend on :8081:
///   * `controller/PartnerBookingController` — `/api/partner/bookings`
///   * `controller/PartnerStayController` — `/api/partner/stays/{bookingId}`
///   * `dto/PartnerBookingDto`, `dto/PartnerGuestStayDto`, `dto/BookingDto`,
///     `dto/PaymentDto`, `dto/InvoiceDto`, `dto/PageResponse`
///   * `dto/PartnerCheckInDto`, `dto/PartnerCheckOutDto`
///   * `service/PartnerBookingService`, `PartnerCheckInService`,
///     `PartnerCheckOutService`, `BookingStatusEngineService`
///   * `repository/BookingSpecification`, `model/BookingStatus`
///
/// ## What a partner may and may not do
///
/// A partner can **read** bookings for hotels they own and **advance the
/// lifecycle**: check-in, check-out, no-show, complete. A partner **cannot
/// cancel or modify** a booking — `BookingService.cancel` and
/// `BookingService.modify` compare `booking.getUser().getId()` against the
/// caller and answer **403** for anyone else, including the property's owner.
/// Those two surfaces are the customer's, and C8 renders no control for them.
///
/// ## Currency — unlike promotions and rate plans, bookings carry one
///
/// `BookingResponse`, `PartnerBookingSummaryResponse`, `PaymentResponse` and
/// `InvoiceSummaryResponse` all carry `String currency` (live: `"VND"`). Amounts
/// are therefore shown with the server's own code. Nothing is converted, and no
/// symbol is inferred from the app locale.
///
/// ## Nights are half-open — deliberately unlike C4 and C5
///
/// `nights = ChronoUnit.DAYS.between(checkInDate, checkOutDate)`, so a stay runs
/// `checkIn <= night < checkOut`. That is *not* the inclusive-both-ends rule the
/// C4 calendar and C5 rate windows use. The client never recomputes it: `nights`
/// and `totalNights` are read straight from the server.
library;

/// `model/BookingStatus` — the ten persisted values, and nothing invented.
///
/// Transitions are owned by `BookingStatusEngineService`; an illegal one is a
/// **422**, not a 409.
enum PartnerBookingStatus {
  pending,
  confirmed,
  checkInReady,
  checkedIn,
  checkedOut,
  completed,
  cancelled,
  refunded,
  archived,
  noShow,

  /// A value this build does not know. Rendered as-is rather than guessed at,
  /// and never offered as a filter.
  unknown;

  static PartnerBookingStatus parse(Object? raw) {
    if (raw is! String) return PartnerBookingStatus.unknown;
    switch (raw) {
      case 'PENDING':
        return PartnerBookingStatus.pending;
      case 'CONFIRMED':
        return PartnerBookingStatus.confirmed;
      case 'CHECK_IN_READY':
        return PartnerBookingStatus.checkInReady;
      case 'CHECKED_IN':
        return PartnerBookingStatus.checkedIn;
      case 'CHECKED_OUT':
        return PartnerBookingStatus.checkedOut;
      case 'COMPLETED':
        return PartnerBookingStatus.completed;
      case 'CANCELLED':
        return PartnerBookingStatus.cancelled;
      case 'REFUNDED':
        return PartnerBookingStatus.refunded;
      case 'ARCHIVED':
        return PartnerBookingStatus.archived;
      case 'NO_SHOW':
        return PartnerBookingStatus.noShow;
      default:
        return PartnerBookingStatus.unknown;
    }
  }

  String? get wireValue => switch (this) {
        PartnerBookingStatus.pending => 'PENDING',
        PartnerBookingStatus.confirmed => 'CONFIRMED',
        PartnerBookingStatus.checkInReady => 'CHECK_IN_READY',
        PartnerBookingStatus.checkedIn => 'CHECKED_IN',
        PartnerBookingStatus.checkedOut => 'CHECKED_OUT',
        PartnerBookingStatus.completed => 'COMPLETED',
        PartnerBookingStatus.cancelled => 'CANCELLED',
        PartnerBookingStatus.refunded => 'REFUNDED',
        PartnerBookingStatus.archived => 'ARCHIVED',
        PartnerBookingStatus.noShow => 'NO_SHOW',
        PartnerBookingStatus.unknown => null,
      };

  /// The values a filter may offer.
  ///
  /// `BookingSpecification.withStatus` catches `IllegalArgumentException` and
  /// returns an **empty specification**, so an unrecognised status is *silently
  /// ignored* and the caller gets the unfiltered list back with HTTP 200. A UI
  /// that let a user supply free text would therefore quietly lie about what it
  /// filtered. Only these real enum values are ever sent.
  static const List<PartnerBookingStatus> filterable = [
    PartnerBookingStatus.pending,
    PartnerBookingStatus.confirmed,
    PartnerBookingStatus.checkInReady,
    PartnerBookingStatus.checkedIn,
    PartnerBookingStatus.checkedOut,
    PartnerBookingStatus.completed,
    PartnerBookingStatus.cancelled,
    PartnerBookingStatus.refunded,
    PartnerBookingStatus.archived,
    PartnerBookingStatus.noShow,
  ];

  /// Whether `BookingStatusEngineService.ALLOWED` permits `→ CHECKED_IN`.
  bool get canCheckIn =>
      this == PartnerBookingStatus.confirmed ||
      this == PartnerBookingStatus.checkInReady;

  /// Only a `CHECKED_IN` booking may be checked out.
  bool get canCheckOut => this == PartnerBookingStatus.checkedIn;

  /// `CONFIRMED` and `CHECK_IN_READY` may be marked as a no-show.
  bool get canMarkNoShow =>
      this == PartnerBookingStatus.confirmed ||
      this == PartnerBookingStatus.checkInReady;

  /// Only a `CHECKED_OUT` booking may be completed.
  bool get canComplete => this == PartnerBookingStatus.checkedOut;

  /// The stay is over or void; no operational action remains.
  bool get isClosed =>
      this == PartnerBookingStatus.completed ||
      this == PartnerBookingStatus.cancelled ||
      this == PartnerBookingStatus.refunded ||
      this == PartnerBookingStatus.archived ||
      this == PartnerBookingStatus.noShow;
}

/// The lifecycle action a partner may perform, and the endpoint behind it.
enum PartnerBookingAction {
  checkIn,
  checkOut,
  noShow,
  complete;

  /// Path segment on `PATCH /api/partner/bookings/{id}/…`.
  String get path => switch (this) {
        PartnerBookingAction.checkIn => 'check-in',
        PartnerBookingAction.checkOut => 'check-out',
        PartnerBookingAction.noShow => 'no-show',
        PartnerBookingAction.complete => 'complete',
      };

  /// Every one of these is a one-way transition — `BookingStatusEngineService`
  /// defines no edge back — so each needs an explicit confirmation step.
  bool get isIrreversible => true;

  bool isAvailableFor(PartnerBookingStatus status) => switch (this) {
        PartnerBookingAction.checkIn => status.canCheckIn,
        PartnerBookingAction.checkOut => status.canCheckOut,
        PartnerBookingAction.noShow => status.canMarkNoShow,
        PartnerBookingAction.complete => status.canComplete,
      };
}

/// `PartnerGuestStayDto.StaySchedule.currentStayState` — a **response-level**
/// classification the backend derives from status + dates + today. It is not a
/// database enum and must not be confused with [PartnerBookingStatus].
enum PartnerStayState {
  upcoming,
  readyForCheckIn,
  inHouse,
  checkedOut,
  completed,
  cancelled,
  noShow,
  expired,
  unknown;

  static PartnerStayState parse(Object? raw) {
    if (raw is! String) return PartnerStayState.unknown;
    switch (raw) {
      case 'UPCOMING':
        return PartnerStayState.upcoming;
      case 'READY_FOR_CHECK_IN':
        return PartnerStayState.readyForCheckIn;
      case 'IN_HOUSE':
        return PartnerStayState.inHouse;
      case 'CHECKED_OUT':
        return PartnerStayState.checkedOut;
      case 'COMPLETED':
        return PartnerStayState.completed;
      case 'CANCELLED':
        return PartnerStayState.cancelled;
      case 'NO_SHOW':
        return PartnerStayState.noShow;
      case 'EXPIRED':
        return PartnerStayState.expired;
      default:
        return PartnerStayState.unknown;
    }
  }
}

/// `PartnerGuestStayResponse.operationalWarnings` — derived tokens, not stored.
enum PartnerStayWarning {
  cancelledStay,
  completedStay,
  currentlyStaying,
  checkOutOverdue,
  futureBooking,
  checkInOverdue,
  unknown;

  static PartnerStayWarning parse(Object? raw) {
    if (raw is! String) return PartnerStayWarning.unknown;
    switch (raw) {
      case 'CANCELLED_STAY':
        return PartnerStayWarning.cancelledStay;
      case 'COMPLETED_STAY':
        return PartnerStayWarning.completedStay;
      case 'CURRENTLY_STAYING':
        return PartnerStayWarning.currentlyStaying;
      case 'CHECK_OUT_OVERDUE':
        return PartnerStayWarning.checkOutOverdue;
      case 'FUTURE_BOOKING':
        return PartnerStayWarning.futureBooking;
      case 'CHECK_IN_OVERDUE':
        return PartnerStayWarning.checkInOverdue;
      default:
        return PartnerStayWarning.unknown;
    }
  }

  /// Warnings that need the operator's attention now, as opposed to those that
  /// merely describe a settled stay.
  bool get isActionable =>
      this == PartnerStayWarning.checkOutOverdue ||
      this == PartnerStayWarning.checkInOverdue;
}

/// `dto/PartnerBookingDto.PartnerBookingSummaryResponse` — 15 fields.
///
/// Note it carries **no `hotelId`**: the list cannot be grouped or filtered by
/// property on the client. `roomId` is present and *is* a server-supported
/// filter, which is how the UI narrows to one property's rooms.
class PartnerBookingSummary {
  final int id;
  final String bookingCode;
  final int? roomId;
  final String? roomName;
  final String? roomCode;
  final String? guestName;

  /// Present on the DTO, and `BookingSpecification.withGuest` matches against
  /// it. Deliberately **not** rendered in the list — see the screen doc.
  final String? guestEmail;

  final DateTime? checkIn;
  final DateTime? checkOut;

  /// Server-computed, half-open (`DAYS.between(checkIn, checkOut)`). Never
  /// recomputed here.
  final int nights;

  final PartnerBookingStatus status;
  final double? finalPrice;
  final String? currency;
  final DateTime? createdAt;

  const PartnerBookingSummary({
    required this.id,
    required this.bookingCode,
    required this.nights,
    required this.status,
    this.roomId,
    this.roomName,
    this.roomCode,
    this.guestName,
    this.guestEmail,
    this.checkIn,
    this.checkOut,
    this.finalPrice,
    this.currency,
    this.createdAt,
  });

  static PartnerBookingSummary? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id == null) return null;
    return PartnerBookingSummary(
      id: id,
      bookingCode: _asString(json['bookingCode']) ?? '',
      roomId: _asInt(json['roomId']),
      roomName: _asString(json['roomName']),
      roomCode: _asString(json['roomCode']),
      guestName: _asString(json['guestName']),
      guestEmail: _asString(json['guestEmail']),
      checkIn: _asDate(json['checkIn']),
      checkOut: _asDate(json['checkOut']),
      nights: _asInt(json['nights']) ?? 0,
      status: PartnerBookingStatus.parse(json['status']),
      finalPrice: _asDouble(json['finalPrice']),
      currency: _asString(json['currency']),
      createdAt: _asInstant(json['createdAt']),
    );
  }
}

/// `dto/PageResponse<T>` — real server-side pagination.
///
/// The list is sorted `createdAt DESC` by the service and the sort is not a
/// request parameter, so the client offers no sort control.
class PartnerBookingPage {
  final List<PartnerBookingSummary> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  const PartnerBookingPage({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  static const PartnerBookingPage empty = PartnerBookingPage(
    content: [],
    page: 0,
    size: 0,
    totalElements: 0,
    totalPages: 0,
  );

  bool get hasNext => page + 1 < totalPages;
  bool get hasPrevious => page > 0;

  /// 1-based index of the first row on this page, for "showing X–Y of Z".
  int get firstIndex => content.isEmpty ? 0 : page * size + 1;
  int get lastIndex => content.isEmpty ? 0 : page * size + content.length;

  static PartnerBookingPage? fromJson(Map<String, dynamic> json) {
    final raw = json['content'];
    if (raw is! List) return null;
    final items = <PartnerBookingSummary>[];
    for (final entry in raw) {
      if (entry is! Map<String, dynamic>) continue;
      final item = PartnerBookingSummary.fromJson(entry);
      if (item != null) items.add(item);
    }
    return PartnerBookingPage(
      content: List.unmodifiable(items),
      page: _asInt(json['page']) ?? 0,
      size: _asInt(json['size']) ?? items.length,
      totalElements: _asInt(json['totalElements']) ?? items.length,
      totalPages: _asInt(json['totalPages']) ?? 1,
    );
  }
}

/// `dto/BookingDto.BookingResponse`.
///
/// Only the fields a partner operations screen legitimately needs are mapped.
/// The customer's payment-benefit ledger — `couponCode`,
/// `couponDiscountAmount`, `creditAmountUsed`, `loyaltyDiscountAmount`,
/// `loyaltyPointsRedeemed`, `giftCardAmountUsed`, `giftCardReference` — is
/// present on the DTO but **deliberately not mapped**: it is the guest's
/// financial detail, it does not change what a front desk does, and
/// `PartnerGuestStayDto` documents the same exclusion for the stay projection.
class PartnerBooking {
  final int id;
  final String bookingCode;
  final String? guestName;
  final String? guestEmail;
  final int? hotelId;
  final String? hotelName;
  final int? roomId;
  final String? roomName;
  final String? roomCode;

  final DateTime? checkIn;
  final DateTime? checkOut;

  /// Server-computed and half-open. Never recomputed.
  final int nights;
  final int adults;
  final int children;
  final int numberOfRooms;

  final PartnerBookingStatus status;

  /// Bookings carry a currency, unlike rate plans (C5) and promotions (C7).
  final String? currency;

  final double? basePrice;
  final double? ratePlanPrice;
  final double? discountAmount;
  final double? finalPrice;

  final String? specialRequest;
  final String? partnerNote;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;
  final DateTime? actualCheckInAt;
  final DateTime? actualCheckOutAt;
  final DateTime? completedAt;
  final DateTime? archivedAt;
  final DateTime? lastStatusChangedAt;
  final String? cancelReason;

  // Rate-plan snapshot (backend phase 7.29). These are the values captured
  // **at booking time** — never re-derived from today's rate plan.
  final int? selectedRatePlanId;
  final String? selectedRatePlanCode;
  final String? selectedRatePlanName;
  final String? mealPlanType;
  final String? cancellationPolicyType;
  final DateTime? cancellationDeadlineAt;
  final bool? refundable;
  final double? nightlyRateSnapshot;
  final double? ratePlanAdjustmentSnapshot;

  const PartnerBooking({
    required this.id,
    required this.bookingCode,
    required this.nights,
    required this.adults,
    required this.children,
    required this.numberOfRooms,
    required this.status,
    this.guestName,
    this.guestEmail,
    this.hotelId,
    this.hotelName,
    this.roomId,
    this.roomName,
    this.roomCode,
    this.checkIn,
    this.checkOut,
    this.currency,
    this.basePrice,
    this.ratePlanPrice,
    this.discountAmount,
    this.finalPrice,
    this.specialRequest,
    this.partnerNote,
    this.createdAt,
    this.updatedAt,
    this.confirmedAt,
    this.cancelledAt,
    this.actualCheckInAt,
    this.actualCheckOutAt,
    this.completedAt,
    this.archivedAt,
    this.lastStatusChangedAt,
    this.cancelReason,
    this.selectedRatePlanId,
    this.selectedRatePlanCode,
    this.selectedRatePlanName,
    this.mealPlanType,
    this.cancellationPolicyType,
    this.cancellationDeadlineAt,
    this.refundable,
    this.nightlyRateSnapshot,
    this.ratePlanAdjustmentSnapshot,
  });

  /// True when the booking captured a rate plan. When false the price came from
  /// the room's base price, and no rate-plan group is rendered.
  bool get hasRatePlanSnapshot =>
      selectedRatePlanId != null ||
      selectedRatePlanName != null ||
      nightlyRateSnapshot != null;

  bool get hasDiscount => (discountAmount ?? 0) > 0;

  static PartnerBooking? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id == null) return null;
    return PartnerBooking(
      id: id,
      bookingCode: _asString(json['bookingCode']) ?? '',
      guestName: _asString(json['userFullName']),
      guestEmail: _asString(json['userEmail']),
      hotelId: _asInt(json['hotelId']),
      hotelName: _asString(json['hotelName']),
      roomId: _asInt(json['roomId']),
      roomName: _asString(json['roomName']),
      roomCode: _asString(json['roomCode']),
      checkIn: _asDate(json['checkIn']),
      checkOut: _asDate(json['checkOut']),
      nights: _asInt(json['nights']) ?? 0,
      adults: _asInt(json['adults']) ?? 0,
      children: _asInt(json['children']) ?? 0,
      numberOfRooms: _asInt(json['numberOfRooms']) ?? 0,
      status: PartnerBookingStatus.parse(json['status']),
      currency: _asString(json['currency']),
      basePrice: _asDouble(json['basePrice']),
      ratePlanPrice: _asDouble(json['ratePlanPrice']),
      discountAmount: _asDouble(json['discountAmount']),
      finalPrice: _asDouble(json['finalPrice']),
      specialRequest: _asString(json['specialRequest']),
      partnerNote: _asString(json['partnerNote']),
      createdAt: _asInstant(json['createdAt']),
      updatedAt: _asInstant(json['updatedAt']),
      confirmedAt: _asInstant(json['confirmedAt']),
      cancelledAt: _asInstant(json['cancelledAt']),
      actualCheckInAt: _asInstant(json['actualCheckInAt']),
      actualCheckOutAt: _asInstant(json['actualCheckOutAt']),
      completedAt: _asInstant(json['completedAt']),
      archivedAt: _asInstant(json['archivedAt']),
      lastStatusChangedAt: _asInstant(json['lastStatusChangedAt']),
      cancelReason: _asString(json['cancelReason']),
      selectedRatePlanId: _asInt(json['selectedRatePlanId']),
      selectedRatePlanCode: _asString(json['selectedRatePlanCode']),
      selectedRatePlanName: _asString(json['selectedRatePlanName']),
      mealPlanType: _asString(json['mealPlanType']),
      cancellationPolicyType: _asString(json['cancellationPolicyType']),
      cancellationDeadlineAt: _asInstant(json['cancellationDeadlineAt']),
      refundable:
          json['refundable'] is bool ? json['refundable'] as bool : null,
      nightlyRateSnapshot: _asDouble(json['nightlyRateSnapshot']),
      ratePlanAdjustmentSnapshot: _asDouble(json['ratePlanAdjustmentSnapshot']),
    );
  }
}

/// `dto/PaymentDto.PaymentResponse`, minus the fields a partner must not see.
///
/// **`providerTransactionId` and `checkoutUrl` are deliberately not mapped.** A
/// checkout URL is a live payment link and a provider transaction id is a
/// gateway-side identifier; neither belongs on an operations screen, and not
/// parsing them means they cannot be rendered by accident later.
class PartnerBookingPayment {
  final int id;
  final String? paymentCode;
  final double? amount;
  final String? currency;
  final String? paymentMethod;
  final String? status;
  final String? provider;
  final String? failureReason;
  final DateTime? paidAt;
  final DateTime? failedAt;
  final DateTime? refundedAt;
  final DateTime? createdAt;

  const PartnerBookingPayment({
    required this.id,
    this.paymentCode,
    this.amount,
    this.currency,
    this.paymentMethod,
    this.status,
    this.provider,
    this.failureReason,
    this.paidAt,
    this.failedAt,
    this.refundedAt,
    this.createdAt,
  });

  static PartnerBookingPayment? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id == null) return null;
    return PartnerBookingPayment(
      id: id,
      paymentCode: _asString(json['paymentCode']),
      amount: _asDouble(json['amount']),
      currency: _asString(json['currency']),
      paymentMethod: _asString(json['paymentMethod']),
      status: _asString(json['status']),
      provider: _asString(json['provider']),
      failureReason: _asString(json['failureReason']),
      paidAt: _asInstant(json['paidAt']),
      failedAt: _asInstant(json['failedAt']),
      refundedAt: _asInstant(json['refundedAt']),
      createdAt: _asInstant(json['createdAt']),
    );
  }
}

/// `dto/InvoiceDto.InvoiceSummaryResponse` — the summary only; no line items are
/// exposed to partners.
class PartnerBookingInvoice {
  final int id;
  final String? invoiceNumber;
  final String? status;
  final double? totalAmount;
  final String? currency;
  final DateTime? issuedAt;

  const PartnerBookingInvoice({
    required this.id,
    this.invoiceNumber,
    this.status,
    this.totalAmount,
    this.currency,
    this.issuedAt,
  });

  static PartnerBookingInvoice? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id == null) return null;
    return PartnerBookingInvoice(
      id: id,
      invoiceNumber: _asString(json['invoiceNumber']),
      status: _asString(json['status']),
      totalAmount: _asDouble(json['totalAmount']),
      currency: _asString(json['currency']),
      issuedAt: _asInstant(json['issuedAt']),
    );
  }
}

/// `dto/BookingDto.TimelineEvent` — the backend's own lifecycle audit.
///
/// [description] is server-authored English; it is shown as supporting detail
/// beneath the localized [event] label, the same way C7 showed the server's
/// voucher `reason` verbatim. No local audit log is fabricated.
class PartnerBookingTimelineEvent {
  final String event;
  final DateTime? occurredAt;
  final String? description;

  const PartnerBookingTimelineEvent({
    required this.event,
    this.occurredAt,
    this.description,
  });

  static PartnerBookingTimelineEvent? fromJson(Map<String, dynamic> json) {
    final event = _asString(json['event']);
    if (event == null) return null;
    return PartnerBookingTimelineEvent(
      event: event,
      occurredAt: _asInstant(json['occurredAt']),
      description: _asString(json['description']),
    );
  }
}

/// `dto/PartnerBookingDto.PartnerBookingDetailResponse`.
class PartnerBookingDetail {
  final PartnerBooking booking;
  final List<PartnerBookingPayment> payments;
  final PartnerBookingInvoice? invoice;
  final List<PartnerBookingTimelineEvent> timeline;

  const PartnerBookingDetail({
    required this.booking,
    required this.payments,
    required this.timeline,
    this.invoice,
  });

  bool get hasPayments => payments.isNotEmpty;

  static PartnerBookingDetail? fromJson(Map<String, dynamic> json) {
    final bookingJson = json['booking'];
    if (bookingJson is! Map<String, dynamic>) return null;
    final booking = PartnerBooking.fromJson(bookingJson);
    if (booking == null) return null;

    final payments = <PartnerBookingPayment>[];
    final rawPayments = json['payments'];
    if (rawPayments is List) {
      for (final entry in rawPayments) {
        if (entry is! Map<String, dynamic>) continue;
        final payment = PartnerBookingPayment.fromJson(entry);
        if (payment != null) payments.add(payment);
      }
    }

    final events = <PartnerBookingTimelineEvent>[];
    final rawTimeline = json['timeline'];
    if (rawTimeline is Map<String, dynamic> && rawTimeline['events'] is List) {
      for (final entry in rawTimeline['events'] as List) {
        if (entry is! Map<String, dynamic>) continue;
        final event = PartnerBookingTimelineEvent.fromJson(entry);
        if (event != null) events.add(event);
      }
    }

    final rawInvoice = json['invoice'];
    return PartnerBookingDetail(
      booking: booking,
      payments: List.unmodifiable(payments),
      timeline: List.unmodifiable(events),
      invoice: rawInvoice is Map<String, dynamic>
          ? PartnerBookingInvoice.fromJson(rawInvoice)
          : null,
    );
  }
}

/// `PartnerGuestStayDto.StaySchedule`.
class PartnerStaySchedule {
  final DateTime? checkInDate;
  final DateTime? checkOutDate;

  /// Server-computed, half-open. Never recomputed on the client.
  final int totalNights;

  final DateTime? actualCheckInAt;
  final DateTime? actualCheckOutAt;
  final PartnerStayState state;
  final int currentNightNumber;
  final int remainingNights;

  const PartnerStaySchedule({
    required this.totalNights,
    required this.state,
    required this.currentNightNumber,
    required this.remainingNights,
    this.checkInDate,
    this.checkOutDate,
    this.actualCheckInAt,
    this.actualCheckOutAt,
  });

  static PartnerStaySchedule fromJson(Map<String, dynamic> json) =>
      PartnerStaySchedule(
        checkInDate: _asDate(json['checkInDate']),
        checkOutDate: _asDate(json['checkOutDate']),
        totalNights: _asInt(json['totalNights']) ?? 0,
        actualCheckInAt: _asInstant(json['actualCheckInAt']),
        actualCheckOutAt: _asInstant(json['actualCheckOutAt']),
        state: PartnerStayState.parse(json['currentStayState']),
        currentNightNumber: _asInt(json['currentNightNumber']) ?? 0,
        remainingNights: _asInt(json['remainingNights']) ?? 0,
      );
}

/// `PartnerGuestStayDto.StayModification` — one immutable modification row.
///
/// This is **history**, made by the customer through their own endpoint. A
/// partner can read it and cannot create one.
class PartnerStayModification {
  final DateTime? previousCheckIn;
  final DateTime? newCheckIn;
  final DateTime? previousCheckOut;
  final DateTime? newCheckOut;
  final int previousAdults;
  final int newAdults;
  final int previousChildren;
  final int newChildren;
  final String? previousRatePlan;
  final String? newRatePlan;
  final double? previousPrice;
  final double? newPrice;
  final DateTime? modifiedAt;

  const PartnerStayModification({
    required this.previousAdults,
    required this.newAdults,
    required this.previousChildren,
    required this.newChildren,
    this.previousCheckIn,
    this.newCheckIn,
    this.previousCheckOut,
    this.newCheckOut,
    this.previousRatePlan,
    this.newRatePlan,
    this.previousPrice,
    this.newPrice,
    this.modifiedAt,
  });

  bool get changedDates =>
      previousCheckIn != newCheckIn || previousCheckOut != newCheckOut;
  bool get changedOccupancy =>
      previousAdults != newAdults || previousChildren != newChildren;
  bool get changedPrice => previousPrice != newPrice;

  static PartnerStayModification fromJson(Map<String, dynamic> json) =>
      PartnerStayModification(
        previousCheckIn: _asDate(json['previousCheckIn']),
        newCheckIn: _asDate(json['newCheckIn']),
        previousCheckOut: _asDate(json['previousCheckOut']),
        newCheckOut: _asDate(json['newCheckOut']),
        previousAdults: _asInt(json['previousAdults']) ?? 0,
        newAdults: _asInt(json['newAdults']) ?? 0,
        previousChildren: _asInt(json['previousChildren']) ?? 0,
        newChildren: _asInt(json['newChildren']) ?? 0,
        previousRatePlan: _asString(json['previousRatePlan']),
        newRatePlan: _asString(json['newRatePlan']),
        previousPrice: _asDouble(json['previousPrice']),
        newPrice: _asDouble(json['newPrice']),
        modifiedAt: _asInstant(json['modifiedAt']),
      );
}

/// `PartnerGuestStayDto.StayCheckAudit` — at most one check-in and one
/// check-out row per booking (the backend's idempotency guarantee).
class PartnerStayCheckAudit {
  final int? partnerProfileId;
  final int? partnerUserId;
  final String? operation;

  /// `QR_SCAN` or `MANUAL` on a check-out; always null on a check-in, which
  /// records no method.
  final String? method;

  final DateTime? timestamp;

  const PartnerStayCheckAudit({
    this.partnerProfileId,
    this.partnerUserId,
    this.operation,
    this.method,
    this.timestamp,
  });

  static PartnerStayCheckAudit fromJson(Map<String, dynamic> json) =>
      PartnerStayCheckAudit(
        partnerProfileId: _asInt(json['partnerProfileId']),
        partnerUserId: _asInt(json['partnerUserId']),
        operation: _asString(json['operation']),
        method: _asString(json['method']),
        timestamp: _asInstant(json['timestamp']),
      );
}

/// `dto/PartnerGuestStayDto.PartnerGuestStayResponse` — the consolidated
/// read-only stay projection from `GET /api/partner/stays/{bookingId}`.
///
/// A superset of the booking detail *for the stay use-case*: it adds the derived
/// schedule/state, voucher classification, modification history, check-in and
/// check-out audits and operational warnings — but carries **no price or
/// payment**. C8 therefore reads both endpoints and shows each for what it
/// actually owns.
class PartnerGuestStay {
  final int bookingId;
  final String bookingCode;
  final PartnerBookingStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? guestName;
  final int adults;
  final int children;
  final int? hotelId;
  final String? hotelName;
  final int? roomId;
  final String? roomName;
  final String? roomCode;
  final PartnerStaySchedule schedule;
  final bool voucherAvailable;
  final String? voucherStatus;
  final List<PartnerBookingTimelineEvent> timeline;
  final List<PartnerStayModification> modifications;
  final PartnerStayCheckAudit? checkInAudit;
  final PartnerStayCheckAudit? checkOutAudit;
  final List<PartnerStayWarning> warnings;

  const PartnerGuestStay({
    required this.bookingId,
    required this.bookingCode,
    required this.status,
    required this.adults,
    required this.children,
    required this.schedule,
    required this.voucherAvailable,
    required this.timeline,
    required this.modifications,
    required this.warnings,
    this.createdAt,
    this.updatedAt,
    this.guestName,
    this.hotelId,
    this.hotelName,
    this.roomId,
    this.roomName,
    this.roomCode,
    this.voucherStatus,
    this.checkInAudit,
    this.checkOutAudit,
  });

  bool get hasModifications => modifications.isNotEmpty;
  bool get hasAudit => checkInAudit != null || checkOutAudit != null;

  List<PartnerStayWarning> get actionableWarnings =>
      warnings.where((w) => w.isActionable).toList(growable: false);

  static PartnerGuestStay? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['bookingId']);
    if (id == null) return null;

    final occupancy = json['occupancy'];
    final occ = occupancy is Map<String, dynamic>
        ? occupancy
        : const <String, dynamic>{};

    final scheduleJson = json['schedule'];
    final schedule = scheduleJson is Map<String, dynamic>
        ? PartnerStaySchedule.fromJson(scheduleJson)
        : PartnerStaySchedule.fromJson(const <String, dynamic>{});

    final voucher = json['voucher'];
    final voucherMap =
        voucher is Map<String, dynamic> ? voucher : const <String, dynamic>{};

    final events = <PartnerBookingTimelineEvent>[];
    final rawTimeline = json['timeline'];
    if (rawTimeline is Map<String, dynamic> && rawTimeline['events'] is List) {
      for (final entry in rawTimeline['events'] as List) {
        if (entry is! Map<String, dynamic>) continue;
        final event = PartnerBookingTimelineEvent.fromJson(entry);
        if (event != null) events.add(event);
      }
    }

    final modifications = <PartnerStayModification>[];
    final rawMods = json['modifications'];
    if (rawMods is List) {
      for (final entry in rawMods) {
        if (entry is! Map<String, dynamic>) continue;
        modifications.add(PartnerStayModification.fromJson(entry));
      }
    }

    final warnings = <PartnerStayWarning>[];
    final rawWarnings = json['operationalWarnings'];
    if (rawWarnings is List) {
      for (final entry in rawWarnings) {
        warnings.add(PartnerStayWarning.parse(entry));
      }
    }

    final checkIn = json['checkInAudit'];
    final checkOut = json['checkOutAudit'];

    return PartnerGuestStay(
      bookingId: id,
      bookingCode: _asString(json['bookingCode']) ?? '',
      status: PartnerBookingStatus.parse(json['bookingStatus']),
      createdAt: _asInstant(json['createdAt']),
      updatedAt: _asInstant(json['updatedAt']),
      guestName: _asString(json['guestName']),
      adults: _asInt(occ['adults']) ?? 0,
      children: _asInt(occ['children']) ?? 0,
      hotelId: _asInt(json['hotelId']),
      hotelName: _asString(json['hotelName']),
      roomId: _asInt(json['roomId']),
      roomName: _asString(json['roomName']),
      roomCode: _asString(json['roomCode']),
      schedule: schedule,
      voucherAvailable: voucherMap['voucherAvailable'] == true,
      voucherStatus: _asString(voucherMap['voucherStatus']),
      timeline: List.unmodifiable(events),
      modifications: List.unmodifiable(modifications),
      checkInAudit: checkIn is Map<String, dynamic>
          ? PartnerStayCheckAudit.fromJson(checkIn)
          : null,
      checkOutAudit: checkOut is Map<String, dynamic>
          ? PartnerStayCheckAudit.fromJson(checkOut)
          : null,
      warnings: List.unmodifiable(warnings),
    );
  }
}

/// `dto/PartnerCheckInDto.CheckInResponse` and
/// `dto/PartnerCheckOutDto.CheckOutResponse` — identical eight-field shapes.
///
/// Both endpoints are **idempotent**: repeating the operation on a booking that
/// is already in the target state returns 200 with the unchanged timestamp and
/// a message saying so, writing no second audit row and sending no second
/// notification. [message] is the server's own wording and is shown verbatim.
class PartnerFrontDeskResult {
  final bool success;
  final String? bookingCode;
  final PartnerBookingStatus status;

  /// `checkedInAt` or `checkedOutAt`, depending on which endpoint answered.
  final DateTime? occurredAt;

  final String? hotelName;
  final String? roomName;
  final String? guestName;
  final String? message;

  const PartnerFrontDeskResult({
    required this.success,
    required this.status,
    this.bookingCode,
    this.occurredAt,
    this.hotelName,
    this.roomName,
    this.guestName,
    this.message,
  });

  static PartnerFrontDeskResult? fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('success')) return null;
    return PartnerFrontDeskResult(
      success: json['success'] == true,
      bookingCode: _asString(json['bookingCode']),
      status: PartnerBookingStatus.parse(json['bookingStatus']),
      occurredAt:
          _asInstant(json['checkedInAt']) ?? _asInstant(json['checkedOutAt']),
      hotelName: _asString(json['hotelName']),
      roomName: _asString(json['roomName']),
      guestName: _asString(json['guestName']),
      message: _asString(json['message']),
    );
  }
}

/// The server-supported query for `GET /api/partner/bookings`.
///
/// Every field here maps to a real `@RequestParam`. There is deliberately **no
/// `hotelId`** — the endpoint does not accept one, so the list is partner-wide
/// and the UI says so instead of filtering silently.
class PartnerBookingQuery {
  final PartnerBookingStatus? status;
  final String? guest;
  final String? bookingCode;
  final int? roomId;
  final DateTime? checkInFrom;
  final DateTime? checkInTo;

  /// One of the backend's mutually-exclusive boolean shortcuts, or null.
  final PartnerBookingQuickFilter? quickFilter;

  final int page;
  final int size;

  const PartnerBookingQuery({
    this.status,
    this.guest,
    this.bookingCode,
    this.roomId,
    this.checkInFrom,
    this.checkInTo,
    this.quickFilter,
    this.page = 0,
    this.size = 20,
  });

  bool get hasActiveFilters =>
      status != null ||
      (guest != null && guest!.isNotEmpty) ||
      (bookingCode != null && bookingCode!.isNotEmpty) ||
      roomId != null ||
      checkInFrom != null ||
      checkInTo != null ||
      quickFilter != null;

  /// A partial range is a real request the backend honours — `from` alone means
  /// "on or after", `to` alone means "on or before" — so neither half is
  /// dropped.
  Map<String, String> toQueryParameters() => {
        if (status?.wireValue != null) 'status': status!.wireValue!,
        if (guest != null && guest!.trim().isNotEmpty) 'guest': guest!.trim(),
        if (bookingCode != null && bookingCode!.trim().isNotEmpty)
          'bookingCode': bookingCode!.trim(),
        if (roomId != null) 'roomId': '$roomId',
        if (checkInFrom != null) 'checkInFrom': _isoDate(checkInFrom!),
        if (checkInTo != null) 'checkInTo': _isoDate(checkInTo!),
        if (quickFilter != null) quickFilter!.parameter: 'true',
        'page': '$page',
        'size': '$size',
      };

  PartnerBookingQuery copyWith({
    PartnerBookingStatus? status,
    String? guest,
    String? bookingCode,
    int? roomId,
    DateTime? checkInFrom,
    DateTime? checkInTo,
    PartnerBookingQuickFilter? quickFilter,
    int? page,
    int? size,
    bool clearStatus = false,
    bool clearGuest = false,
    bool clearBookingCode = false,
    bool clearRoom = false,
    bool clearDates = false,
    bool clearQuickFilter = false,
  }) =>
      PartnerBookingQuery(
        status: clearStatus ? null : (status ?? this.status),
        guest: clearGuest ? null : (guest ?? this.guest),
        bookingCode:
            clearBookingCode ? null : (bookingCode ?? this.bookingCode),
        roomId: clearRoom ? null : (roomId ?? this.roomId),
        checkInFrom: clearDates ? null : (checkInFrom ?? this.checkInFrom),
        checkInTo: clearDates ? null : (checkInTo ?? this.checkInTo),
        quickFilter:
            clearQuickFilter ? null : (quickFilter ?? this.quickFilter),
        page: page ?? this.page,
        size: size ?? this.size,
      );
}

/// The backend's boolean shortcut parameters.
///
/// They are `AND`ed onto the specification, and several combined would silently
/// contradict each other (`inHouse` + `cancelled` can never both hold), so the
/// UI treats them as one mutually-exclusive choice.
enum PartnerBookingQuickFilter {
  arrivalToday,
  departureToday,
  upcoming,
  inHouse,
  cancelled,
  completed;

  String get parameter => switch (this) {
        PartnerBookingQuickFilter.arrivalToday => 'arrivalToday',
        PartnerBookingQuickFilter.departureToday => 'departureToday',
        PartnerBookingQuickFilter.upcoming => 'upcoming',
        PartnerBookingQuickFilter.inHouse => 'inHouse',
        PartnerBookingQuickFilter.cancelled => 'cancelled',
        PartnerBookingQuickFilter.completed => 'completed',
      };
}

String _isoDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

String? _asString(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// `LocalDate` — a calendar day with no zone, parsed as a plain local date so it
/// cannot shift across a timezone boundary.
DateTime? _asDate(Object? value) {
  if (value is! String) return null;
  final parts = value.split('-');
  if (parts.length < 3) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2].substring(0, 2));
  if (year == null || month == null || day == null) return null;
  return DateTime(year, month, day);
}

DateTime? _asInstant(Object? value) {
  if (value is! String) return null;
  return DateTime.tryParse(value)?.toLocal();
}
