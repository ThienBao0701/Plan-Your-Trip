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
      promotionNotificationEnabled: json['promotionNotificationEnabled'] == true,
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
