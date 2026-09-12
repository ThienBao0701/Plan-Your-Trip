/// Typed models for the Admin CMS surfaces built in D1b.
///
/// Every model here mirrors a real backend DTO on `develop@92a009a`. Nothing is
/// invented: a field exists here only because the corresponding Java record
/// declares it, and a field the backend declares as nullable stays nullable in
/// Dart. Enum-like values arrive as plain strings and are kept as strings unless
/// the client genuinely branches on them — where it does, parsing fails closed.
library;

// ── shared coercion ──────────────────────────────────────────────────────────
// File-private, matching the convention already used by the partner promotion
// and rate models. Kept private so the admin layer adds nothing to the global
// namespace and never reaches into partner internals for helpers.

int? _asInt(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double? _asDouble(Object? v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

String? _asString(Object? v) {
  if (v is! String) return null;
  final t = v.trim();
  return t.isEmpty ? null : t;
}

DateTime? _asInstant(Object? v) {
  if (v is! String) return null;
  return DateTime.tryParse(v)?.toLocal();
}

DateTime? _asDate(Object? v) {
  if (v is! String) return null;
  return DateTime.tryParse(v);
}

/// The backend's `PageResponse<T>` envelope — `{content, page, size,
/// totalElements, totalPages}` — introduced for the admin grids in D1a.
///
/// This is the *only* pagination shape the admin client understands. It is
/// generic over the row type so the six admin grids share one envelope, one set
/// of page-maths getters and one set of tests, rather than each re-deriving
/// "is there a next page" slightly differently.
class AdminPage<T> {
  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  const AdminPage({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  static AdminPage<T> empty<T>() => AdminPage<T>(
        content: const [],
        page: 0,
        size: 0,
        totalElements: 0,
        totalPages: 0,
      );

  /// Parses the envelope. Returns null when the payload is not a page — the
  /// caller maps that to [ApiErrorKind.malformed] rather than rendering a
  /// half-understood response.
  static AdminPage<T>? fromJson<T>(
    Map<String, dynamic> json,
    T? Function(Map<String, dynamic>) parseItem,
  ) {
    final raw = json['content'];
    if (raw is! List) return null;
    final items = <T>[];
    for (final entry in raw) {
      if (entry is! Map<String, dynamic>) continue;
      final item = parseItem(entry);
      if (item != null) items.add(item);
    }
    return AdminPage<T>(
      content: items,
      page: _asInt(json['page']) ?? 0,
      size: _asInt(json['size']) ?? items.length,
      totalElements: _asInt(json['totalElements']) ?? items.length,
      totalPages: _asInt(json['totalPages']) ?? 0,
    );
  }

  bool get isEmpty => content.isEmpty;
  bool get hasPrevious => page > 0;

  /// Derived from the server's own `totalPages`, never from whether the current
  /// page happened to come back full.
  bool get hasNext => page + 1 < totalPages;

  /// 1-based index of the first row on this page, for "showing X–Y of Z".
  /// Zero when the page is empty so the UI can omit the range entirely.
  int get firstRowNumber => content.isEmpty ? 0 : page * size + 1;

  int get lastRowNumber => content.isEmpty ? 0 : page * size + content.length;
}

// ── Dashboard ────────────────────────────────────────────────────────────────

/// One `{label, value, count}` row from `PartnerAnalyticsDto.MetricBreakdown`,
/// which the admin analytics DTO reuses.
class AdminMetricBreakdown {
  final String label;
  final double? value;
  final int count;

  const AdminMetricBreakdown({
    required this.label,
    required this.value,
    required this.count,
  });

  static AdminMetricBreakdown? fromJson(Map<String, dynamic> json) {
    final label = _asString(json['label']);
    if (label == null) return null;
    return AdminMetricBreakdown(
      label: label,
      value: _asDouble(json['value']),
      count: _asInt(json['count']) ?? 0,
    );
  }
}

/// `AdminAnalyticsDto.AdminAnalyticsOverviewResponse` from
/// `GET /api/admin/analytics/overview`.
///
/// Platform-wide and un-scoped — deliberately *not* the partner analytics
/// shape. Partner analytics answers "how is my property doing"; this answers
/// "how is the platform doing", and the two must not be conflated or share
/// widgets that imply one is the other.
///
/// `grossRevenue` and `revenueInRange` carry **no currency field**: the backend
/// does not supply one on this endpoint, so the UI renders the number without
/// inventing a symbol. That mirrors the money rule proven across C11 and I.
class AdminDashboardOverview {
  /// Range the backend actually applied. Null when it defaulted.
  final DateTime? from;
  final DateTime? to;

  final int totalBookings;
  final List<AdminMetricBreakdown> bookingsByStatus;
  final double? grossRevenue;
  final int activeHotels;
  final int activeRooms;
  final int totalUsers;
  final int totalPartners;
  final int bookingsInRange;
  final double? revenueInRange;

  const AdminDashboardOverview({
    required this.from,
    required this.to,
    required this.totalBookings,
    required this.bookingsByStatus,
    required this.grossRevenue,
    required this.activeHotels,
    required this.activeRooms,
    required this.totalUsers,
    required this.totalPartners,
    required this.bookingsInRange,
    required this.revenueInRange,
  });

  static AdminDashboardOverview fromJson(Map<String, dynamic> json) {
    final raw = json['bookingsByStatus'];
    final breakdowns = <AdminMetricBreakdown>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is! Map<String, dynamic>) continue;
        final b = AdminMetricBreakdown.fromJson(e);
        if (b != null) breakdowns.add(b);
      }
    }
    return AdminDashboardOverview(
      from: _asDate(json['from']),
      to: _asDate(json['to']),
      totalBookings: _asInt(json['totalBookings']) ?? 0,
      bookingsByStatus: breakdowns,
      grossRevenue: _asDouble(json['grossRevenue']),
      activeHotels: _asInt(json['activeHotels']) ?? 0,
      activeRooms: _asInt(json['activeRooms']) ?? 0,
      totalUsers: _asInt(json['totalUsers']) ?? 0,
      totalPartners: _asInt(json['totalPartners']) ?? 0,
      bookingsInRange: _asInt(json['bookingsInRange']) ?? 0,
      revenueInRange: _asDouble(json['revenueInRange']),
    );
  }

  /// True when the platform genuinely has no bookings yet — distinct from a
  /// failed load, so the dashboard can say "nothing yet" instead of "error".
  bool get hasNoBookings => totalBookings == 0;
}

// ── Bookings ─────────────────────────────────────────────────────────────────

/// `BookingDto.BookingSummaryResponse` — the row shape of
/// `GET /api/admin/bookings`.
class AdminBookingRow {
  final int id;
  final String? bookingCode;
  final int? hotelId;
  final String? hotelName;
  final int? roomId;
  final String? roomName;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int nights;
  final String? status;

  /// Backend-supplied amount and currency. Never converted or recomputed here.
  final double? finalPrice;
  final String? currency;

  final DateTime? createdAt;

  const AdminBookingRow({
    required this.id,
    required this.bookingCode,
    required this.hotelId,
    required this.hotelName,
    required this.roomId,
    required this.roomName,
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    required this.status,
    required this.finalPrice,
    required this.currency,
    required this.createdAt,
  });

  static AdminBookingRow? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id == null) return null;
    return AdminBookingRow(
      id: id,
      bookingCode: _asString(json['bookingCode']),
      hotelId: _asInt(json['hotelId']),
      hotelName: _asString(json['hotelName']),
      roomId: _asInt(json['roomId']),
      roomName: _asString(json['roomName']),
      checkIn: _asDate(json['checkIn']),
      checkOut: _asDate(json['checkOut']),
      nights: _asInt(json['nights']) ?? 0,
      status: _asString(json['status']),
      finalPrice: _asDouble(json['finalPrice']),
      currency: _asString(json['currency']),
      createdAt: _asInstant(json['createdAt']),
    );
  }
}

// ── Payments ─────────────────────────────────────────────────────────────────

/// `PaymentDto.PaymentResponse` — the row shape of `GET /api/admin/payments`.
///
/// `providerTransactionId` and `checkoutUrl` exist on the DTO but are
/// deliberately **not** modelled: they are provider-side identifiers with no
/// operational meaning in a read-only grid, and the sensitive-data rule from D0
/// §9 is to surface only what the screen genuinely needs.
class AdminPaymentRow {
  final int id;
  final String? paymentCode;
  final int? bookingId;
  final String? bookingCode;
  final double? amount;
  final String? currency;
  final String? paymentMethod;
  final String? status;
  final String? provider;
  final String? failureReason;
  final DateTime? paidAt;
  final DateTime? refundedAt;
  final DateTime? createdAt;

  const AdminPaymentRow({
    required this.id,
    required this.paymentCode,
    required this.bookingId,
    required this.bookingCode,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.status,
    required this.provider,
    required this.failureReason,
    required this.paidAt,
    required this.refundedAt,
    required this.createdAt,
  });

  static AdminPaymentRow? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id == null) return null;
    return AdminPaymentRow(
      id: id,
      paymentCode: _asString(json['paymentCode']),
      bookingId: _asInt(json['bookingId']),
      bookingCode: _asString(json['bookingCode']),
      amount: _asDouble(json['amount']),
      currency: _asString(json['currency']),
      paymentMethod: _asString(json['paymentMethod']),
      status: _asString(json['status']),
      provider: _asString(json['provider']),
      failureReason: _asString(json['failureReason']),
      paidAt: _asInstant(json['paidAt']),
      refundedAt: _asInstant(json['refundedAt']),
      createdAt: _asInstant(json['createdAt']),
    );
  }
}

// ── Reviews ──────────────────────────────────────────────────────────────────

/// The partner's reply attached to a review (`ReviewDto.PartnerReplyInfo`).
class AdminReviewReply {
  final String? content;
  final DateTime? repliedAt;

  const AdminReviewReply({required this.content, required this.repliedAt});

  static AdminReviewReply? fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    return AdminReviewReply(
      content: _asString(raw['content']),
      repliedAt:
          _asInstant(raw['repliedAt']) ?? _asInstant(raw['partnerRepliedAt']),
    );
  }
}

/// `ReviewDto.ReviewResponse` — the row shape of `GET /api/admin/reviews`.
///
/// Unlike the partner surface, this one **does** carry `content`: D0 verified
/// live that an administrator can read the review body while a partner cannot.
/// That asymmetry is the reason review moderation belongs to the Admin CMS.
class AdminReviewRow {
  final int id;
  final int? bookingId;
  final String? bookingCode;
  final int? userId;
  final String? userName;
  final int? placeId;
  final String? placeName;
  final int? ratingOverall;
  final String? title;

  /// Guest-authored body. Admin-readable; must never be copied into an audit
  /// record or any log (see the D1a audit policy).
  final String? content;

  final String? status;
  final int helpfulCount;
  final int reportedCount;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final String? rejectReason;
  final DateTime? createdAt;
  final AdminReviewReply? partnerReply;

  const AdminReviewRow({
    required this.id,
    required this.bookingId,
    required this.bookingCode,
    required this.userId,
    required this.userName,
    required this.placeId,
    required this.placeName,
    required this.ratingOverall,
    required this.title,
    required this.content,
    required this.status,
    required this.helpfulCount,
    required this.reportedCount,
    required this.approvedAt,
    required this.rejectedAt,
    required this.rejectReason,
    required this.createdAt,
    required this.partnerReply,
  });

  static AdminReviewRow? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id == null) return null;
    return AdminReviewRow(
      id: id,
      bookingId: _asInt(json['bookingId']),
      bookingCode: _asString(json['bookingCode']),
      userId: _asInt(json['userId']),
      userName: _asString(json['userName']),
      placeId: _asInt(json['placeId']),
      placeName: _asString(json['placeName']),
      ratingOverall: _asInt(json['ratingOverall']),
      title: _asString(json['title']),
      content: _asString(json['content']),
      status: _asString(json['status']),
      helpfulCount: _asInt(json['helpfulCount']) ?? 0,
      reportedCount: _asInt(json['reportedCount']) ?? 0,
      approvedAt: _asInstant(json['approvedAt']),
      rejectedAt: _asInstant(json['rejectedAt']),
      rejectReason: _asString(json['rejectReason']),
      createdAt: _asInstant(json['createdAt']),
      partnerReply: AdminReviewReply.fromJson(json['partnerReply']),
    );
  }

  bool get hasPartnerReply => partnerReply?.content != null;
}

// ── Invoices ─────────────────────────────────────────────────────────────────

/// `InvoiceDto.InvoiceResponse` — the row shape of `GET /api/admin/invoices`.
///
/// Billing contact fields (`billingEmail`, `billingPhone`, `billingAddress`)
/// exist on the DTO but are not modelled: a list view has no need for customer
/// contact details, and D0 §9's rule is that admin access does not mean
/// displaying everything.
class AdminInvoiceRow {
  final int id;
  final String? invoiceNumber;
  final int? bookingId;
  final String? bookingCode;
  final int? paymentId;
  final int? hotelId;
  final String? hotelName;
  final String? status;
  final String? currency;
  final double? subtotal;
  final double? discountAmount;
  final double? taxAmount;
  final double? totalAmount;
  final DateTime? issuedAt;
  final DateTime? paidAt;
  final DateTime? cancelledAt;
  final DateTime? createdAt;

  const AdminInvoiceRow({
    required this.id,
    required this.invoiceNumber,
    required this.bookingId,
    required this.bookingCode,
    required this.paymentId,
    required this.hotelId,
    required this.hotelName,
    required this.status,
    required this.currency,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.issuedAt,
    required this.paidAt,
    required this.cancelledAt,
    required this.createdAt,
  });

  static AdminInvoiceRow? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id == null) return null;
    return AdminInvoiceRow(
      id: id,
      invoiceNumber: _asString(json['invoiceNumber']),
      bookingId: _asInt(json['bookingId']),
      bookingCode: _asString(json['bookingCode']),
      paymentId: _asInt(json['paymentId']),
      hotelId: _asInt(json['hotelId']),
      hotelName: _asString(json['hotelName']),
      status: _asString(json['status']),
      currency: _asString(json['currency']),
      subtotal: _asDouble(json['subtotal']),
      discountAmount: _asDouble(json['discountAmount']),
      taxAmount: _asDouble(json['taxAmount']),
      totalAmount: _asDouble(json['totalAmount']),
      issuedAt: _asInstant(json['issuedAt']),
      paidAt: _asInstant(json['paidAt']),
      cancelledAt: _asInstant(json['cancelledAt']),
      createdAt: _asInstant(json['createdAt']),
    );
  }
}

// ── Activity log ─────────────────────────────────────────────────────────────

/// `AdminActivityLogDto.AdminActivityLogResponse` from
/// `GET /api/admin/activity-logs` (added in D1a).
///
/// `actorEmail` is the snapshot the backend took at write time, not a live
/// lookup — the UI must present it as historical fact and never re-resolve it.
/// `beforeState`/`afterState` are short safe scalars by backend policy; the
/// client still treats them as opaque strings and renders them verbatim without
/// interpreting them as any particular enum.
class AdminActivityLogRow {
  final int id;
  final int? actorUserId;
  final String? actorEmail;
  final String? action;
  final String? targetType;
  final int? targetId;
  final String? description;
  final String? beforeState;
  final String? afterState;
  final DateTime? createdAt;

  const AdminActivityLogRow({
    required this.id,
    required this.actorUserId,
    required this.actorEmail,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.description,
    required this.beforeState,
    required this.afterState,
    required this.createdAt,
  });

  static AdminActivityLogRow? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id == null) return null;
    return AdminActivityLogRow(
      id: id,
      actorUserId: _asInt(json['actorUserId']),
      actorEmail: _asString(json['actorEmail']),
      action: _asString(json['action']),
      targetType: _asString(json['targetType']),
      targetId: _asInt(json['targetId']),
      description: _asString(json['description']),
      beforeState: _asString(json['beforeState']),
      afterState: _asString(json['afterState']),
      createdAt: _asInstant(json['createdAt']),
    );
  }

  /// A system/batch entry rather than a human administrator's action. The
  /// backend writes the literal `SYSTEM` in `actorEmail` and leaves
  /// `actorUserId` null for these.
  bool get isSystemActor => actorUserId == null;

  bool get hasStateTransition => beforeState != null || afterState != null;
}
// ── Partner management (D2C) ─────────────────────────────────────────────────
// Every field below exists on a Java record verified in the D2B contract freeze
// against `develop@3467d45`. Nothing is invented, and fields the backend does
// not return are simply absent here rather than defaulted to a plausible value.

/// The five states of `PartnerVerificationStatus`, exactly as the backend
/// spells them on the wire.
///
/// Held as an enum rather than a bare string because the UI genuinely branches
/// on it — approve and reject are legal only from [submitted], suspend only
/// from [approved] — and a typo in a string comparison would silently offer an
/// action the backend answers 422 to. Parsing fails closed: an unrecognised
/// value becomes [unknown] and offers no action at all.
enum AdminPartnerStatus {
  draft('DRAFT'),
  submitted('SUBMITTED'),
  approved('APPROVED'),
  rejected('REJECTED'),
  suspended('SUSPENDED'),
  unknown('');

  final String wire;
  const AdminPartnerStatus(this.wire);

  static AdminPartnerStatus parse(String? raw) {
    if (raw == null) return AdminPartnerStatus.unknown;
    for (final s in AdminPartnerStatus.values) {
      if (s != AdminPartnerStatus.unknown && s.wire == raw) return s;
    }
    return AdminPartnerStatus.unknown;
  }

  /// `POST /{id}/approve` and `/reject` both require SUBMITTED (else 422).
  bool get canApproveOrReject => this == AdminPartnerStatus.submitted;

  /// `POST /{id}/suspend` requires APPROVED (else 422).
  bool get canSuspend => this == AdminPartnerStatus.approved;

  /// Terminal with no reactivate endpoint anywhere in the backend — see the
  /// D2B freeze, finding D2A-F1. The UI must never imply this is recoverable.
  bool get isTerminalSuspension => this == AdminPartnerStatus.suspended;
}

/// A row of `GET /api/admin/partners` and the body of `GET /api/admin/partners/{id}`.
///
/// Mirrors `PartnerProfileDto.PartnerProfileResponse`. The contact block
/// (`userEmail`, `email`, `phone`, `address`, `taxCode`, `representativeName`)
/// is genuine PII: it is the business identity an administrator verifies
/// against, so it is modelled — but the D2B freeze keeps it off the list grid
/// and shows it only on the detail view.
class AdminPartnerRow {
  final int id;
  final int? userId;
  final String? userName;
  final String? userEmail;
  final String? businessName;
  final String? businessType;
  final String? representativeName;
  final String? phone;
  final String? email;
  final String? address;
  final String? taxCode;
  final String? website;
  final AdminPartnerStatus status;

  /// The backend reuses this one column for a rejection reason *and* a
  /// suspension reason (D2A-F4), so the UI labels it by [status] rather than
  /// calling it "rejection reason" unconditionally.
  final String? statusReason;

  final DateTime? submittedAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final int? approvedById;
  final String? approvedByName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminPartnerRow({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.businessName,
    required this.businessType,
    required this.representativeName,
    required this.phone,
    required this.email,
    required this.address,
    required this.taxCode,
    required this.website,
    required this.status,
    required this.statusReason,
    required this.submittedAt,
    required this.approvedAt,
    required this.rejectedAt,
    required this.approvedById,
    required this.approvedByName,
    required this.createdAt,
    required this.updatedAt,
  });

  static AdminPartnerRow? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id == null) return null;
    return AdminPartnerRow(
      id: id,
      userId: _asInt(json['userId']),
      userName: _asString(json['userName']),
      userEmail: _asString(json['userEmail']),
      businessName: _asString(json['businessName']),
      businessType: _asString(json['businessType']),
      representativeName: _asString(json['representativeName']),
      phone: _asString(json['phone']),
      email: _asString(json['email']),
      address: _asString(json['address']),
      taxCode: _asString(json['taxCode']),
      website: _asString(json['website']),
      status: AdminPartnerStatus.parse(_asString(json['verificationStatus'])),
      statusReason: _asString(json['rejectReason']),
      submittedAt: _asInstant(json['submittedAt']),
      approvedAt: _asInstant(json['approvedAt']),
      rejectedAt: _asInstant(json['rejectedAt']),
      approvedById: _asInt(json['approvedById']),
      approvedByName: _asString(json['approvedByName']),
      createdAt: _asInstant(json['createdAt']),
      updatedAt: _asInstant(json['updatedAt']),
    );
  }
}

/// `GET /api/admin/partners/{id}/detail` — `AdminPartnerDetailResponse`.
///
/// A counts summary, not a rich object. There is no admin endpoint that lists a
/// partner's properties, so [ownedHotelCount] is all the UI can honestly show
/// about them. [payoutAccountStatus] is a status string only; no account
/// number, bank name or balance is exposed by any admin endpoint.
class AdminPartnerDetail {
  final int partnerProfileId;
  final String? businessName;
  final AdminPartnerStatus status;
  final int ownedHotelCount;
  final int teamMemberCount;
  final String? payoutAccountStatus;
  final DateTime? createdAt;

  const AdminPartnerDetail({
    required this.partnerProfileId,
    required this.businessName,
    required this.status,
    required this.ownedHotelCount,
    required this.teamMemberCount,
    required this.payoutAccountStatus,
    required this.createdAt,
  });

  static AdminPartnerDetail? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['partnerProfileId']);
    if (id == null) return null;
    return AdminPartnerDetail(
      partnerProfileId: id,
      businessName: _asString(json['businessName']),
      status: AdminPartnerStatus.parse(_asString(json['verificationStatus'])),
      ownedHotelCount: _asInt(json['ownedHotelCount']) ?? 0,
      teamMemberCount: _asInt(json['teamMemberCount']) ?? 0,
      payoutAccountStatus: _asString(json['payoutAccountStatus']),
      createdAt: _asInstant(json['createdAt']),
    );
  }
}

/// A row of `GET /api/admin/partners/{id}/team` — `PartnerTeamMemberResponse`.
///
/// Read-only in the admin console: invite, role change and removal are
/// partner-side operations (`/api/partner/team`) and no admin equivalent
/// exists. [role] stays a plain string because the admin console never branches
/// on a partner's internal permission model.
class AdminPartnerTeamMember {
  final int id;
  final int? partnerProfileId;
  final int? userId;
  final String? userName;
  final String? userEmail;
  final String? role;
  final bool active;
  final DateTime? invitedAt;
  final DateTime? joinedAt;

  const AdminPartnerTeamMember({
    required this.id,
    required this.partnerProfileId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.role,
    required this.active,
    required this.invitedAt,
    required this.joinedAt,
  });

  static AdminPartnerTeamMember? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id == null) return null;
    return AdminPartnerTeamMember(
      id: id,
      partnerProfileId: _asInt(json['partnerProfileId']),
      userId: _asInt(json['userId']),
      userName: _asString(json['userName']),
      userEmail: _asString(json['userEmail']),
      role: _asString(json['role']),
      active: json['active'] == true,
      invitedAt: _asInstant(json['invitedAt']),
      joinedAt: _asInstant(json['joinedAt']),
    );
  }
}

/// `GET /api/admin/partners/{id}/settings` — `PartnerSettingsResponse`.
///
/// Preferences only. The backend deliberately keeps payout data out of this
/// DTO, and there is no admin settings mutation endpoint, so this is read-only
/// everywhere in the admin console.
class AdminPartnerSettings {
  final int id;
  final int? partnerProfileId;
  final String? defaultLanguage;
  final String? timezone;
  final bool notificationEmailEnabled;
  final bool notificationSmsEnabled;
  final bool notificationInAppEnabled;
  final bool bookingNotificationEnabled;
  final bool paymentNotificationEnabled;
  final bool reviewNotificationEnabled;
  final bool promotionNotificationEnabled;

  const AdminPartnerSettings({
    required this.id,
    required this.partnerProfileId,
    required this.defaultLanguage,
    required this.timezone,
    required this.notificationEmailEnabled,
    required this.notificationSmsEnabled,
    required this.notificationInAppEnabled,
    required this.bookingNotificationEnabled,
    required this.paymentNotificationEnabled,
    required this.reviewNotificationEnabled,
    required this.promotionNotificationEnabled,
  });

  static AdminPartnerSettings? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id == null) return null;
    return AdminPartnerSettings(
      id: id,
      partnerProfileId: _asInt(json['partnerProfileId']),
      defaultLanguage: _asString(json['defaultLanguage']),
      timezone: _asString(json['timezone']),
      notificationEmailEnabled: json['notificationEmailEnabled'] == true,
      notificationSmsEnabled: json['notificationSmsEnabled'] == true,
      notificationInAppEnabled: json['notificationInAppEnabled'] == true,
      bookingNotificationEnabled: json['bookingNotificationEnabled'] == true,
      paymentNotificationEnabled: json['paymentNotificationEnabled'] == true,
      reviewNotificationEnabled: json['reviewNotificationEnabled'] == true,
      promotionNotificationEnabled:
          json['promotionNotificationEnabled'] == true,
    );
  }
}

/// A row of `GET /api/admin/partners/{id}/activity-logs` —
/// `PartnerActivityLogResponse`.
///
/// This is the **partner's own operational history** (what the partner's team
/// did), which is a different record from [AdminActivityLogRow] (what an
/// administrator did). The two are never merged: they answer different
/// questions and have different retention guarantees.
class AdminPartnerActivityRow {
  final int id;
  final int? partnerProfileId;
  final int? actorUserId;
  final String? actorName;
  final String? action;
  final String? entityType;
  final int? entityId;
  final String? description;
  final DateTime? createdAt;

  const AdminPartnerActivityRow({
    required this.id,
    required this.partnerProfileId,
    required this.actorUserId,
    required this.actorName,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.description,
    required this.createdAt,
  });

  static AdminPartnerActivityRow? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id == null) return null;
    return AdminPartnerActivityRow(
      id: id,
      partnerProfileId: _asInt(json['partnerProfileId']),
      actorUserId: _asInt(json['actorUserId']),
      actorName: _asString(json['actorName']),
      action: _asString(json['action']),
      entityType: _asString(json['entityType']),
      entityId: _asInt(json['entityId']),
      description: _asString(json['description']),
      createdAt: _asInstant(json['createdAt']),
    );
  }
}
// ── Catalog (D3C-A) ──────────────────────────────────────────────────────────
// Verified against `develop@3467d45`: AdminPlaceController, AdminRoomController
// and PlaceService.ALLOWED_TRANSITIONS. Nothing here is inferred from the D3B
// document alone — every field and every transition was re-read from source.

/// The seven states of `PlaceStatus`, exactly as the backend spells them.
///
/// Parsing fails closed to [unknown] rather than defaulting to a plausible
/// state: mapping an unrecognised value onto PUBLISHED or DRAFT would make the
/// console assert something about a place that the backend never said.
enum AdminPlaceStatus {
  draft('DRAFT'),
  pendingReview('PENDING_REVIEW'),
  approved('APPROVED'),
  published('PUBLISHED'),
  hidden('HIDDEN'),
  rejected('REJECTED'),
  archived('ARCHIVED'),
  unknown('');

  final String wire;
  const AdminPlaceStatus(this.wire);

  static AdminPlaceStatus parse(String? raw) {
    if (raw == null) return AdminPlaceStatus.unknown;
    for (final s in AdminPlaceStatus.values) {
      if (s != AdminPlaceStatus.unknown && s.wire == raw) return s;
    }
    return AdminPlaceStatus.unknown;
  }

  /// `PlaceService.ALLOWED_TRANSITIONS`, mirrored exactly. Anything outside this
  /// map answers 400, so the console offers only what the backend accepts —
  /// and [unknown] offers nothing at all.
  static const Map<AdminPlaceStatus, List<AdminPlaceStatus>> _transitions = {
    AdminPlaceStatus.draft: [
      AdminPlaceStatus.pendingReview,
      AdminPlaceStatus.approved,
      AdminPlaceStatus.published,
      AdminPlaceStatus.hidden,
      AdminPlaceStatus.archived,
    ],
    AdminPlaceStatus.pendingReview: [
      AdminPlaceStatus.approved,
      AdminPlaceStatus.rejected,
      AdminPlaceStatus.hidden,
      AdminPlaceStatus.archived,
    ],
    AdminPlaceStatus.approved: [
      AdminPlaceStatus.published,
      AdminPlaceStatus.hidden,
      AdminPlaceStatus.archived,
    ],
    AdminPlaceStatus.published: [
      AdminPlaceStatus.hidden,
      AdminPlaceStatus.archived,
    ],
    AdminPlaceStatus.hidden: [
      AdminPlaceStatus.published,
      AdminPlaceStatus.archived,
    ],
    AdminPlaceStatus.rejected: [
      AdminPlaceStatus.draft,
      AdminPlaceStatus.archived,
    ],
    // Terminal. Nothing in the backend moves a place out of ARCHIVED, so the
    // console must never imply otherwise.
    AdminPlaceStatus.archived: [],
    AdminPlaceStatus.unknown: [],
  };

  List<AdminPlaceStatus> get allowedNext =>
      _transitions[this] ?? const <AdminPlaceStatus>[];

  bool canTransitionTo(AdminPlaceStatus target) => allowedNext.contains(target);

  /// `validateFeaturedVerified`: both flags may only be set **true** on an
  /// APPROVED or PUBLISHED place. Clearing either is unguarded in both
  /// directions, so the console allows it from any state.
  bool get canSetFlagsTrue =>
      this == AdminPlaceStatus.approved || this == AdminPlaceStatus.published;

  /// ARCHIVED is reachable from every other state and has no exit.
  bool get isTerminal => this == AdminPlaceStatus.archived;

  /// Guest-visible. Public reads gate strictly on `status == PUBLISHED`.
  bool get isPubliclyVisible => this == AdminPlaceStatus.published;
}

/// A named reference the catalog DTOs embed for category, subcategory and
/// location. `type`, `icon` and `color` exist on `CategoryRef` but the console
/// renders only the name, so they are not modelled.
class AdminCatalogRef {
  final int id;
  final String? name;
  final String? slug;

  const AdminCatalogRef(
      {required this.id, required this.name, required this.slug});

  static AdminCatalogRef? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final id = _asInt(json['id']);
    if (id == null) return null;
    return AdminCatalogRef(
      id: id,
      name: _asString(json['name']),
      slug: _asString(json['slug']),
    );
  }
}

/// A row of `GET /api/admin/places` — `PlaceDto.PlaceSummaryResponse`.
class AdminPlaceRow {
  final int id;
  final String? name;
  final String? slug;
  final AdminCatalogRef? category;
  final AdminCatalogRef? subcategory;
  final AdminCatalogRef? location;
  final String? address;
  final String? shortDescription;
  final int priceLevel;
  final double ratingAvg;
  final int reviewCount;
  final AdminPlaceStatus status;
  final bool featured;
  final bool verified;
  final String? coverImageUrl;
  final DateTime? createdAt;

  const AdminPlaceRow({
    required this.id,
    required this.name,
    required this.slug,
    required this.category,
    required this.subcategory,
    required this.location,
    required this.address,
    required this.shortDescription,
    required this.priceLevel,
    required this.ratingAvg,
    required this.reviewCount,
    required this.status,
    required this.featured,
    required this.verified,
    required this.coverImageUrl,
    required this.createdAt,
  });

  static AdminPlaceRow? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id == null) return null;
    return AdminPlaceRow(
      id: id,
      name: _asString(json['name']),
      slug: _asString(json['slug']),
      category:
          AdminCatalogRef.fromJson(json['category'] as Map<String, dynamic>?),
      subcategory: AdminCatalogRef.fromJson(
          json['subcategory'] as Map<String, dynamic>?),
      // The list DTO calls it administrativeUnit; the detail DTO calls the same
      // thing location. Both are read here so one model serves both.
      location: AdminCatalogRef.fromJson((json['administrativeUnit'] ??
          json['location']) as Map<String, dynamic>?),
      address: _asString(json['address']),
      shortDescription: _asString(json['shortDescription']),
      priceLevel: _asInt(json['priceLevel']) ?? 0,
      ratingAvg: _asDouble(json['ratingAvg']) ?? 0,
      reviewCount: _asInt(json['reviewCount']) ?? 0,
      status: AdminPlaceStatus.parse(_asString(json['status'])),
      featured: json['featured'] == true,
      verified: json['verified'] == true,
      coverImageUrl: _asString(json['coverImageUrl']),
      createdAt: _asInstant(json['createdAt']),
    );
  }
}

/// One image in a place's gallery — `PlaceDetailResponse.ImageRef`.
///
/// Read-only in D3C-A. Media *mutations* are D3C-B, and the D3B media freeze
/// keeps the URL out of any clickable affordance.
class AdminCatalogImage {
  final int id;
  final String? url;
  final String? thumbnailUrl;
  final String? altText;
  final int sortOrder;
  final bool cover;

  const AdminCatalogImage({
    required this.id,
    required this.url,
    required this.thumbnailUrl,
    required this.altText,
    required this.sortOrder,
    required this.cover,
  });

  static AdminCatalogImage? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id == null) return null;
    return AdminCatalogImage(
      id: id,
      url: _asString(json['url']),
      thumbnailUrl: _asString(json['thumbnailUrl']),
      altText: _asString(json['altText']),
      sortOrder: _asInt(json['sortOrder']) ?? 0,
      cover: json['cover'] == true,
    );
  }
}

/// `GET /api/admin/places/{id}` — `PlaceDetailResponse`.
///
/// `similarPlaces`, `groupedOpeningHours` and the full `metadata` block are
/// returned by the backend but not modelled: the console shows none of them,
/// and a model field nothing renders is a maintenance cost with no reader.
class AdminPlaceDetail {
  final int id;
  final String? name;
  final String? slug;
  final String? shortDescription;
  final String? description;
  final String? address;
  final String? googleMapUrl;
  final double? latitude;
  final double? longitude;
  final AdminCatalogRef? category;
  final AdminCatalogRef? subcategory;
  final AdminCatalogRef? location;
  final double ratingAvg;
  final int ratingCount;
  final int priceLevel;
  final bool featured;
  final bool verified;
  final AdminPlaceStatus status;
  final List<String> tags;
  final List<String> amenities;
  final String? coverImageUrl;
  final List<AdminCatalogImage> gallery;

  /// True when the backend embedded a `hotelDetail` block — the only reliable
  /// signal that this place is a hotel and therefore has rooms.
  final bool isHotel;

  const AdminPlaceDetail({
    required this.id,
    required this.name,
    required this.slug,
    required this.shortDescription,
    required this.description,
    required this.address,
    required this.googleMapUrl,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.subcategory,
    required this.location,
    required this.ratingAvg,
    required this.ratingCount,
    required this.priceLevel,
    required this.featured,
    required this.verified,
    required this.status,
    required this.tags,
    required this.amenities,
    required this.coverImageUrl,
    required this.gallery,
    required this.isHotel,
  });

  static AdminPlaceDetail? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id == null) return null;

    List<String> names(Object? raw, String key) {
      if (raw is! List) return const [];
      final out = <String>[];
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          final v = _asString(e[key]);
          if (v != null) out.add(v);
        }
      }
      return out;
    }

    final gallery = <AdminCatalogImage>[];
    final rawGallery = json['galleryImages'];
    if (rawGallery is List) {
      for (final e in rawGallery) {
        if (e is Map<String, dynamic>) {
          final img = AdminCatalogImage.fromJson(e);
          if (img != null) gallery.add(img);
        }
      }
    }

    return AdminPlaceDetail(
      id: id,
      name: _asString(json['name']),
      slug: _asString(json['slug']),
      shortDescription: _asString(json['shortDescription']),
      description: _asString(json['description']),
      address: _asString(json['address']),
      googleMapUrl: _asString(json['googleMapUrl']),
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      category:
          AdminCatalogRef.fromJson(json['category'] as Map<String, dynamic>?),
      subcategory: AdminCatalogRef.fromJson(
          json['subcategory'] as Map<String, dynamic>?),
      location:
          AdminCatalogRef.fromJson(json['location'] as Map<String, dynamic>?),
      ratingAvg: _asDouble(json['ratingAvg']) ?? 0,
      ratingCount: _asInt(json['ratingCount']) ?? 0,
      priceLevel: _asInt(json['priceLevel']) ?? 0,
      featured: json['featured'] == true,
      verified: json['verified'] == true,
      status: AdminPlaceStatus.parse(_asString(json['status'])),
      tags: names(json['tags'], 'tag'),
      amenities: names(json['amenities'], 'name'),
      coverImageUrl: _asString(json['coverImageUrl']),
      gallery: gallery,
      isHotel: json['hotelDetail'] is Map,
    );
  }
}

/// A row of `GET /api/admin/hotels/{placeId}/rooms` — `HotelRoomResponse`.
///
/// Catalog fields only. Inventory (`availableQuantity` is a live operations
/// figure) and pricing are shown as read-only context, never as controls: they
/// belong to Admin Operations and Admin Commercial respectively.
class AdminCatalogRoom {
  final int id;
  final String? roomName;
  final String? roomCode;
  final String? roomType;
  final String? bedType;
  final int? bedCount;
  final int? maxGuests;
  final double? roomSizeSqm;
  final int? quantity;
  final bool active;
  final String? coverImageUrl;

  const AdminCatalogRoom({
    required this.id,
    required this.roomName,
    required this.roomCode,
    required this.roomType,
    required this.bedType,
    required this.bedCount,
    required this.maxGuests,
    required this.roomSizeSqm,
    required this.quantity,
    required this.active,
    required this.coverImageUrl,
  });

  static AdminCatalogRoom? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id == null) return null;
    return AdminCatalogRoom(
      id: id,
      roomName: _asString(json['roomName']),
      roomCode: _asString(json['roomCode']),
      roomType: _asString(json['roomType']),
      bedType: _asString(json['bedType']),
      bedCount: _asInt(json['bedCount']),
      maxGuests: _asInt(json['maxGuests']),
      roomSizeSqm: _asDouble(json['roomSizeSqm']),
      quantity: _asInt(json['quantity']),
      active: json['active'] == true,
      coverImageUrl: _asString(json['coverImageUrl']),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// D3C-B — Admin Media (URL registry)
// ═══════════════════════════════════════════════════════════════════════════

/// `MediaType` — the three values the backend enum declares.
///
/// [unknown] exists so a value added server-side later renders as itself rather
/// than crashing a parse, and so nothing that depends on a *known* type (cover
/// eligibility) is ever granted to a value this build does not understand.
enum AdminMediaType {
  image('IMAGE'),
  video('VIDEO'),
  document('DOCUMENT'),
  unknown('');

  final String wire;
  const AdminMediaType(this.wire);

  static AdminMediaType parse(String? raw) {
    for (final t in AdminMediaType.values) {
      if (t != AdminMediaType.unknown && t.wire == raw) return t;
    }
    return AdminMediaType.unknown;
  }

  /// `MediaAssetService` refuses a cover that is not an IMAGE, on create, on
  /// update and on `setCover` alike.
  bool get canBeCover => this == AdminMediaType.image;

  /// Only an IMAGE is worth attempting to render. A VIDEO or DOCUMENT URL is
  /// not an image, and `Image.network` would simply fail on it.
  bool get isRenderableAsImage => this == AdminMediaType.image;

  /// The three values a create/update form may offer. [unknown] is never
  /// offered — it is a read-side fallback only.
  static List<AdminMediaType> get selectable => const [
        AdminMediaType.image,
        AdminMediaType.video,
        AdminMediaType.document
      ];
}

/// `MediaOwnerType`.
///
/// The backend enum has five members, but they are not equal in what the admin
/// API actually lets a console do with them:
///
/// * `SUBMISSION` has no entity at all — `validateOwnerExists` answers 400.
/// * `ROOM`, `REVIEW` and `TRIP_DOCUMENT` can be *created* through
///   `POST /api/admin/media`, but there is no admin endpoint that lists them
///   back. The only admin read is `GET /api/admin/places/{placeId}/media`.
/// * `PLACE` is therefore the only owner an administrator can create, see,
///   edit, deactivate, re-cover and reorder — a complete loop.
///
/// [isAdminManageable] encodes that, and the console offers only those owners.
/// Creating a ROOM asset from here would produce a row the same console could
/// never find again.
enum AdminMediaOwnerType {
  place('PLACE'),
  room('ROOM'),
  review('REVIEW'),
  tripDocument('TRIP_DOCUMENT'),
  submission('SUBMISSION'),
  unknown('');

  final String wire;
  const AdminMediaOwnerType(this.wire);

  static AdminMediaOwnerType parse(String? raw) {
    for (final t in AdminMediaOwnerType.values) {
      if (t != AdminMediaOwnerType.unknown && t.wire == raw) return t;
    }
    return AdminMediaOwnerType.unknown;
  }

  /// The backend rejects SUBMISSION outright.
  bool get isSupportedByBackend =>
      this != AdminMediaOwnerType.submission &&
      this != AdminMediaOwnerType.unknown;

  /// Has a complete admin read+write loop. See the class doc.
  bool get isAdminManageable => this == AdminMediaOwnerType.place;

  static List<AdminMediaOwnerType> get manageable =>
      AdminMediaOwnerType.values.where((t) => t.isAdminManageable).toList();
}

/// One row of `MediaAssetResponse`.
class AdminMediaAsset {
  final int id;
  final AdminMediaOwnerType ownerType;
  final int? ownerId;
  final String? url;
  final String? thumbnailUrl;
  final AdminMediaType mediaType;
  final String? altText;
  final int sortOrder;
  final bool cover;
  final bool active;
  final int? uploadedByUserId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminMediaAsset({
    required this.id,
    required this.ownerType,
    required this.ownerId,
    required this.url,
    required this.thumbnailUrl,
    required this.mediaType,
    required this.altText,
    required this.sortOrder,
    required this.cover,
    required this.active,
    required this.uploadedByUserId,
    required this.createdAt,
    required this.updatedAt,
  });

  static AdminMediaAsset? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id == null) return null;
    return AdminMediaAsset(
      id: id,
      ownerType: AdminMediaOwnerType.parse(_asString(json['ownerType'])),
      ownerId: _asInt(json['ownerId']),
      url: _asString(json['url']),
      thumbnailUrl: _asString(json['thumbnailUrl']),
      mediaType: AdminMediaType.parse(_asString(json['mediaType'])),
      altText: _asString(json['altText']),
      sortOrder: _asInt(json['sortOrder']) ?? 0,
      cover: json['cover'] == true,
      active: json['active'] == true,
      uploadedByUserId: _asInt(json['uploadedByUserId']),
      createdAt: _asInstant(json['createdAt']),
      updatedAt: _asInstant(json['updatedAt']),
    );
  }

  /// The URL the *preview* uses — the thumbnail when one was registered, since
  /// that is what it is for, otherwise the asset itself. Never rewritten.
  String? get previewUrl =>
      (thumbnailUrl != null && thumbnailUrl!.trim().isNotEmpty)
          ? thumbnailUrl
          : url;

  /// True when the URL carries a query string. A media URL can legitimately be
  /// a signed link, and D3M's audit trail redacts exactly this part — so the
  /// console does not print it on a list either.
  bool get urlHasQuery => AdminMediaUrl.hasQuery(url);

  /// Origin + path, mirroring the backend's own `redactUrl`. This is a *display*
  /// form only: [url] stays intact for the preview and for the edit form, so
  /// saving can never silently rewrite what the operator registered.
  String get displayUrl => AdminMediaUrl.redact(url) ?? (url ?? '');
}

/// URL rules shared by the media models, the media state and the media forms.
///
/// [isAcceptable] mirrors `MediaAssetService.validateUrl` — absolute, http or
/// https, with a host. It is a convenience so an obviously bad value is caught
/// before a round trip; it deliberately does **not** add rules of its own (no
/// host allowlist, no extension check), because the server is the authority and
/// a stricter client would silently reject values the product accepts.
class AdminMediaUrl {
  const AdminMediaUrl._();

  static const Set<String> allowedSchemes = {'http', 'https'};

  static bool isAcceptable(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme) return false;
    if (!allowedSchemes.contains(uri.scheme.toLowerCase())) return false;
    return uri.host.isNotEmpty;
  }

  static bool hasQuery(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    final uri = Uri.tryParse(value.trim());
    return uri != null && uri.query.isNotEmpty;
  }

  /// Scheme, host and path only. Returns null for a null/blank input and the
  /// original string when it cannot be parsed — never a guess.
  static String? redact(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    if (uri == null || uri.host.isEmpty) return value.trim();
    // The query is dropped either way; [hasQuery] is what tells the UI to say
    // so, rather than printing a possibly-signed parameter on a list.
    return '${uri.scheme}://${uri.host}${uri.path}';
  }
}

/// One entry of `MediaReorderRequest.items`.
///
/// The backend rejects a repeated `mediaId` **and** a repeated `sortOrder`
/// rather than normalising either, so a caller builds a complete, conflict-free
/// ordering for one gallery and submits it whole.
class AdminMediaOrder {
  final int mediaId;
  final int sortOrder;

  const AdminMediaOrder({required this.mediaId, required this.sortOrder});
}

/// D3D — the canonical identity of the gallery a media surface is bound to.
///
/// The media console can be reached two ways: through its own place picker, and
/// directly from a place's detail screen. Both must arrive at the *same* kind of
/// owner, carried as an id rather than reconstructed from anything on screen —
/// a name, a heading, a form field. This type is that identity.
///
/// [name] is display-only and may be absent; nothing about a request is ever
/// derived from it.
class AdminMediaOwner {
  final AdminMediaOwnerType type;
  final int id;
  final String? name;

  /// The only owner this console manages. See [AdminMediaOwnerType].
  const AdminMediaOwner.place({required this.id, this.name})
      : type = AdminMediaOwnerType.place;

  /// True when [asset] genuinely belongs to this owner. A mutation is refused
  /// unless this holds, so a stale or mismatched row can never be re-targeted.
  bool owns(AdminMediaAsset asset) =>
      asset.ownerType == type && asset.ownerId == id;
}

// ═══════════════════════════════════════════════════════════════════════════
// D10 — Admin reference data
// ═══════════════════════════════════════════════════════════════════════════
//
// `AmenityResponse` and `CategoryResponse` on `develop@f26bb97`, field for
// field. Both are flat records with no envelope: the admin reads return a bare
// JSON array, not a `PageResponse`, so nothing here touches [AdminPage].
//
// Every field the backend declares as nullable stays nullable. `active` is a
// Java primitive `boolean` and therefore always present — but it is parsed the
// same defensive way as everywhere else in this file (`== true`), so a missing
// or non-boolean value reads as false rather than throwing.

/// One row of `GET /api/admin/amenities`.
class AdminAmenity {
  final int id;
  final String? name;
  final String? slug;
  final String? icon;
  final String? groupName;
  final String? description;
  final int? sortOrder;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminAmenity({
    required this.id,
    required this.name,
    required this.slug,
    required this.icon,
    required this.groupName,
    required this.description,
    required this.sortOrder,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Null when the row carries no usable id. Every admin action addresses a row
  /// by id, so a row without one cannot be acted on and is dropped rather than
  /// rendered as an untouchable entry.
  static AdminAmenity? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id == null) return null;
    return AdminAmenity(
      id: id,
      name: _asString(json['name']),
      slug: _asString(json['slug']),
      icon: _asString(json['icon']),
      groupName: _asString(json['groupName']),
      description: _asString(json['description']),
      sortOrder: _asInt(json['sortOrder']),
      active: json['active'] == true,
      createdAt: _asInstant(json['createdAt']),
      updatedAt: _asInstant(json['updatedAt']),
    );
  }
}

/// One row of `GET /api/admin/categories`.
///
/// `parentId` is the only hierarchy signal the flat list carries — the nested
/// `GET /api/categories/tree` shape is a public endpoint and is not used by the
/// console. The grid therefore resolves a parent's *name* from the rows it
/// already holds rather than by a second request.
class AdminCategory {
  final int id;
  final int? parentId;
  final String? name;
  final String? slug;
  final String? type;
  final String? icon;
  final String? color;
  final String? coverImageUrl;
  final int? sortOrder;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminCategory({
    required this.id,
    required this.parentId,
    required this.name,
    required this.slug,
    required this.type,
    required this.icon,
    required this.color,
    required this.coverImageUrl,
    required this.sortOrder,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  /// True when this category sits at the top of the tree.
  bool get isRoot => parentId == null;

  static AdminCategory? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id == null) return null;
    return AdminCategory(
      id: id,
      parentId: _asInt(json['parentId']),
      name: _asString(json['name']),
      slug: _asString(json['slug']),
      type: _asString(json['type']),
      icon: _asString(json['icon']),
      color: _asString(json['color']),
      coverImageUrl: _asString(json['coverImageUrl']),
      sortOrder: _asInt(json['sortOrder']),
      active: json['active'] == true,
      createdAt: _asInstant(json['createdAt']),
      updatedAt: _asInstant(json['updatedAt']),
    );
  }
}

/// Vocabularies for the two reference pickers.
///
/// <h4>Why these are not free text</h4>
///
/// `Amenity.groupName` and `Category.type` are plain, unvalidated `String`
/// columns on the backend — nothing rejects a typo. `Category.type` is matched
/// by `CustomerCouponService` against `CouponDefinition.placeType`
/// (`equalsIgnoreCase`) and by `PersonalizationRule` targeting, so a mistyped
/// value silently stops live coupons from matching, with no error anywhere. A
/// picker is the client-side guard against that.
///
/// <h4>Where the values come from</h4>
///
/// **Primarily from the data itself**: [optionsFrom] collects the distinct
/// values present in the rows the console actually loaded, which is what keeps
/// the picker correct as the product's vocabulary moves. [seededGroupNames] and
/// [seededCategoryTypes] are a *fallback for an empty list only* — a first-run
/// database with no rows yet would otherwise offer nothing to choose from. They
/// are transcribed from `DataInitializer` on `develop@f26bb97`, **not** from
/// `AmenityController`'s Swagger summary, which documents five groups and omits
/// the `ATTRACTION` group the seed actually creates.
class AdminReferenceVocabulary {
  const AdminReferenceVocabulary._();

  /// The six amenity groups `DataInitializer` seeds. `ATTRACTION` is included
  /// deliberately: it exists in the data and dropping it would make the picker
  /// unable to reproduce rows the product already has.
  static const List<String> seededGroupNames = [
    'ATTRACTION',
    'CAFE',
    'GENERAL',
    'HOTEL',
    'RESTAURANT',
    'ROOM',
  ];

  /// The ten category types `DataInitializer` seeds, on roots and children
  /// alike (a child carries its root's type).
  static const List<String> seededCategoryTypes = [
    'ACCOMMODATION',
    'ATTRACTION',
    'CAFE',
    'ENTERTAINMENT',
    'FOOD',
    'PHOTO_SPOT',
    'SHOPPING',
    'TOUR',
    'TRANSPORTATION',
    'WELLNESS',
  ];

  /// Distinct, sorted, non-blank values observed in [values], falling back to
  /// [fallback] when nothing was observed.
  ///
  /// [current] is always included even when no other row uses it, so opening
  /// the edit dialog for a row whose stored value has since become unique never
  /// silently rewrites it to something else.
  static List<String> optionsFrom(
    Iterable<String?> values, {
    required List<String> fallback,
    String? current,
  }) {
    final seen = <String>{};
    for (final v in values) {
      final t = v?.trim();
      if (t != null && t.isNotEmpty) seen.add(t);
    }
    if (seen.isEmpty) seen.addAll(fallback);
    final c = current?.trim();
    if (c != null && c.isNotEmpty) seen.add(c);
    final out = seen.toList()..sort();
    return out;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// D11 — Admin locations
// ═══════════════════════════════════════════════════════════════════════════
//
// `LocationDto.LocationResponse` on `develop@f26bb97`, field for field. The
// backend entity is `AdministrativeUnit` in table `administrative_units`; every
// REST path, both controllers, both DTOs and this console say **Location**, and
// nothing is renamed on either side.
//
// Like the other two reference reads, `GET /api/admin/locations` returns a bare
// JSON array with no envelope, no ordering and no paging.

/// One row of `GET /api/admin/locations`.
///
/// Four of these fields are **server-owned** as far as this console is
/// concerned — `parentId`, `fullPath`, `level`, `latitude`/`longitude` — but
/// they still live on the model, because `PUT` is a full replace: an update
/// that omitted them would write null over each one. They are carried so they
/// can be echoed back unchanged.
class AdminLocation {
  final int id;
  final int? parentId;
  final String? code;
  final String? name;
  final String? slug;
  final String? type;
  final int? level;
  final String? oldName;
  final String? fullPath;
  final double? latitude;
  final double? longitude;
  final int? sortOrder;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminLocation({
    required this.id,
    required this.parentId,
    required this.code,
    required this.name,
    required this.slug,
    required this.type,
    required this.level,
    required this.oldName,
    required this.fullPath,
    required this.latitude,
    required this.longitude,
    required this.sortOrder,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Null when the row carries no usable id — every action addresses a row by
  /// id, so a row without one is dropped rather than rendered untouchable.
  static AdminLocation? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id == null) return null;
    return AdminLocation(
      id: id,
      parentId: _asInt(json['parentId']),
      code: _asString(json['code']),
      name: _asString(json['name']),
      slug: _asString(json['slug']),
      type: _asString(json['type']),
      level: _asInt(json['level']),
      oldName: _asString(json['oldName']),
      fullPath: _asString(json['fullPath']),
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      sortOrder: _asInt(json['sortOrder']),
      active: json['active'] == true,
      createdAt: _asInstant(json['createdAt']),
      updatedAt: _asInstant(json['updatedAt']),
    );
  }

  /// True when this location sits at the top of the tree.
  bool get isRoot => parentId == null;

  /// True when the server stored a usable coordinate pair. A lone latitude or
  /// longitude is not rendered as a position, because half a pair is not one —
  /// the backend enforces no pairing rule, so the console checks.
  bool get hasCoordinates => latitude != null && longitude != null;

  /// Lower-cased haystack for the client-side filter: name, slug, code and
  /// oldName, which is also what the backend's own search query covers.
  String get searchHaystack => [
        name,
        slug,
        code,
        oldName,
      ].whereType<String>().join(' ').toLowerCase();

  bool matchesFilter(String query) {
    final q = query.trim().toLowerCase();
    return q.isEmpty || searchHaystack.contains(q);
  }
}

/// The closed `UnitType` vocabulary, transcribed from the backend enum.
///
/// Unlike `Amenity.groupName` and `Category.type` — unvalidated strings, so the
/// console derives their pickers from observed data — `LocationRequest.type` is
/// a `@NotNull UnitType`. The server rejects anything else with a 400, so the
/// list is fixed rather than discovered, and **no value may be added here that
/// the backend enum does not declare.**
///
/// `WARD` and `COMMUNE` are included because the enum declares them, even
/// though `DataInitializer` seeds no instance of either. Which parent/child
/// pairings are legal is **not** encoded: the backend enforces no rule, and the
/// console does not invent one.
class AdminLocationType {
  const AdminLocationType._();

  static const List<String> values = [
    'COUNTRY',
    'PROVINCE',
    'CITY',
    'WARD',
    'COMMUNE',
    'AREA',
  ];

  /// [current] is appended when the stored value is not one this build knows,
  /// so opening the edit dialog for such a row cannot silently rewrite it.
  static List<String> optionsWith(String? current) {
    final c = current?.trim();
    if (c == null || c.isEmpty || values.contains(c)) return values;
    return [...values, c];
  }
}
