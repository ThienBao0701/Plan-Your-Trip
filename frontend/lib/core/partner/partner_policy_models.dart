/// Typed models for the Partner Policies module (C6), mapped one-to-one from
/// `backend-v1` (branch `develop`).
///
/// Source of truth, read from the authoritative backend worktree and verified
/// against the running backend:
///   * `controller/PartnerHotelController` — `PUT /api/partner/hotels/{id}/policies`
///   * `dto/PartnerHotelDto.PartnerPolicyRequest` / `PartnerHotelResponse`
///   * `controller/PartnerSettingsController` — `GET/PUT /api/partner/settings`
///   * `dto/PartnerSettingsDto.PartnerSettingsRequest` / `PartnerSettingsResponse`
///   * `service/PartnerPropertyService`, `service/PartnerSettingsService`
///
/// ## Two policy domains, two different authorization rules
///
/// These are deliberately **not** merged into one settings object, because the
/// backend governs them differently:
///
/// | Domain | Endpoint | Scope | Who may write |
/// |---|---|---|---|
/// | Property policies | `PUT /hotels/{id}/policies` | one property | **owner only** (`PartnerPropertyService` is not team-aware) |
/// | Workspace settings | `PUT /settings` | the whole partner | **OWNER or MANAGER** (`SETTINGS_WRITE_ROLES`) |
///
/// `PartnerSettingsService.resolveAccess` is the *only* team-aware resolver in
/// the partner API; every other service resolves owner-only. C6 mirrors both
/// rules separately rather than picking one.
///
/// ## Both payloads are complete
///
/// Unlike the property `PUT` (C2) and the rate-plan `PUT` (C5), which null out
/// omitted optional fields, these two requests carry **every** field the form
/// shows — 5 and 9 respectively. There is no hidden state to erase, which is
/// why C6 ships real edit forms where earlier phases deliberately did not.
library;

/// The five fields of `dto/PartnerHotelDto.PartnerPolicyRequest`, read back from
/// `PartnerHotelResponse`.
///
/// `checkIn`/`checkOut` are `LocalTime` (`@NotNull` on write) and arrive as
/// `"HH:mm:ss"`. The three house-rule strings are genuinely nullable — verified
/// live, where all three are null for the seeded property.
class PartnerPropertyPolicies {
  /// `"HH:mm"`, seconds trimmed. Kept as a string because a policy time has no
  /// date and manufacturing one to get a `DateTime` would invent data.
  final String? checkIn;
  final String? checkOut;
  final String? childrenPolicy;
  final String? petPolicy;
  final String? smokingPolicy;

  const PartnerPropertyPolicies({
    this.checkIn,
    this.checkOut,
    this.childrenPolicy,
    this.petPolicy,
    this.smokingPolicy,
  });

  /// The backend requires both times on write (`@NotNull`), so a form cannot be
  /// submitted until they are present.
  bool get canSubmit => checkIn != null && checkOut != null;

  bool get hasHouseRules =>
      childrenPolicy != null || petPolicy != null || smokingPolicy != null;

  PartnerPropertyPolicies copyWith({
    String? checkIn,
    String? checkOut,
    Object? childrenPolicy = _unset,
    Object? petPolicy = _unset,
    Object? smokingPolicy = _unset,
  }) =>
      PartnerPropertyPolicies(
        checkIn: checkIn ?? this.checkIn,
        checkOut: checkOut ?? this.checkOut,
        // Sentinel-based so a field can be cleared back to null, which the
        // backend accepts and which "?? this.x" could never express.
        childrenPolicy: childrenPolicy == _unset
            ? this.childrenPolicy
            : childrenPolicy as String?,
        petPolicy: petPolicy == _unset ? this.petPolicy : petPolicy as String?,
        smokingPolicy: smokingPolicy == _unset
            ? this.smokingPolicy
            : smokingPolicy as String?,
      );

  /// The complete `PartnerPolicyRequest` body. Every field the record declares
  /// is sent, so nothing can be silently erased by omission.
  Map<String, dynamic> toRequestJson() => {
        'checkIn': checkIn,
        'checkOut': checkOut,
        'childrenPolicy': childrenPolicy,
        'petPolicy': petPolicy,
        'smokingPolicy': smokingPolicy,
      };

  /// Reads the policy slice out of a `PartnerHotelResponse`.
  static PartnerPropertyPolicies fromHotelJson(Map<String, dynamic> json) =>
      PartnerPropertyPolicies(
        checkIn: _asTime(json['checkIn']),
        checkOut: _asTime(json['checkOut']),
        childrenPolicy: _asString(json['childrenPolicy']),
        petPolicy: _asString(json['petPolicy']),
        smokingPolicy: _asString(json['smokingPolicy']),
      );

  bool sameAs(PartnerPropertyPolicies other) =>
      checkIn == other.checkIn &&
      checkOut == other.checkOut &&
      childrenPolicy == other.childrenPolicy &&
      petPolicy == other.petPolicy &&
      smokingPolicy == other.smokingPolicy;
}

const Object _unset = Object();

/// `dto/PartnerSettingsDto.PartnerSettingsResponse` — partner-level workspace
/// preferences, not guest-facing policy.
///
/// `defaultLanguage` and `timezone` are free-text `String`s on both the request
/// and the entity — there is **no enum and no validated set**, so the client
/// shows what the server stored rather than mapping to a closed list it would
/// have to invent.
class PartnerWorkspaceSettings {
  final int? id;
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

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PartnerWorkspaceSettings({
    required this.notificationEmailEnabled,
    required this.notificationSmsEnabled,
    required this.notificationInAppEnabled,
    required this.bookingNotificationEnabled,
    required this.paymentNotificationEnabled,
    required this.reviewNotificationEnabled,
    required this.promotionNotificationEnabled,
    this.id,
    this.partnerProfileId,
    this.defaultLanguage,
    this.timezone,
    this.createdAt,
    this.updatedAt,
  });

  /// Which delivery channels are on. Reported as a count so the summary never
  /// implies a channel the backend does not model.
  int get enabledChannelCount => [
        notificationEmailEnabled,
        notificationSmsEnabled,
        notificationInAppEnabled,
      ].where((on) => on).length;

  int get enabledTopicCount => [
        bookingNotificationEnabled,
        paymentNotificationEnabled,
        reviewNotificationEnabled,
        promotionNotificationEnabled,
      ].where((on) => on).length;

  PartnerWorkspaceSettings copyWith({
    bool? notificationEmailEnabled,
    bool? notificationSmsEnabled,
    bool? notificationInAppEnabled,
    bool? bookingNotificationEnabled,
    bool? paymentNotificationEnabled,
    bool? reviewNotificationEnabled,
    bool? promotionNotificationEnabled,
  }) =>
      PartnerWorkspaceSettings(
        id: id,
        partnerProfileId: partnerProfileId,
        defaultLanguage: defaultLanguage,
        timezone: timezone,
        notificationEmailEnabled:
            notificationEmailEnabled ?? this.notificationEmailEnabled,
        notificationSmsEnabled:
            notificationSmsEnabled ?? this.notificationSmsEnabled,
        notificationInAppEnabled:
            notificationInAppEnabled ?? this.notificationInAppEnabled,
        bookingNotificationEnabled:
            bookingNotificationEnabled ?? this.bookingNotificationEnabled,
        paymentNotificationEnabled:
            paymentNotificationEnabled ?? this.paymentNotificationEnabled,
        reviewNotificationEnabled:
            reviewNotificationEnabled ?? this.reviewNotificationEnabled,
        promotionNotificationEnabled:
            promotionNotificationEnabled ?? this.promotionNotificationEnabled,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  /// The complete `PartnerSettingsRequest` body — all nine fields.
  ///
  /// `defaultLanguage`/`timezone` are echoed back unchanged: the service applies
  /// them only when non-null, and C6 does not edit them (there is no validated
  /// set to offer), so resending the stored value leaves them untouched.
  Map<String, dynamic> toRequestJson() => {
        'defaultLanguage': defaultLanguage,
        'timezone': timezone,
        'notificationEmailEnabled': notificationEmailEnabled,
        'notificationSmsEnabled': notificationSmsEnabled,
        'notificationInAppEnabled': notificationInAppEnabled,
        'bookingNotificationEnabled': bookingNotificationEnabled,
        'paymentNotificationEnabled': paymentNotificationEnabled,
        'reviewNotificationEnabled': reviewNotificationEnabled,
        'promotionNotificationEnabled': promotionNotificationEnabled,
      };

  bool sameAs(PartnerWorkspaceSettings other) =>
      notificationEmailEnabled == other.notificationEmailEnabled &&
      notificationSmsEnabled == other.notificationSmsEnabled &&
      notificationInAppEnabled == other.notificationInAppEnabled &&
      bookingNotificationEnabled == other.bookingNotificationEnabled &&
      paymentNotificationEnabled == other.paymentNotificationEnabled &&
      reviewNotificationEnabled == other.reviewNotificationEnabled &&
      promotionNotificationEnabled == other.promotionNotificationEnabled;

  static PartnerWorkspaceSettings? fromJson(Map<String, dynamic> json) {
    // Every boolean is a primitive on the record, so a body without them is not
    // a settings payload.
    if (!json.containsKey('notificationEmailEnabled')) return null;
    return PartnerWorkspaceSettings(
      id: _asInt(json['id']),
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
      createdAt: _asInstant(json['createdAt']),
      updatedAt: _asInstant(json['updatedAt']),
    );
  }
}

/// Which notification toggle a switch targets, so one handler serves all seven.
enum PartnerSettingsToggle {
  email,
  sms,
  inApp,
  booking,
  payment,
  review,
  promotion,
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String? _asString(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// `LocalTime` arrives as `"HH:mm:ss"`. Trimmed to `"HH:mm"` for display and for
/// the write payload, which the backend parses either way.
String? _asTime(Object? value) {
  final raw = _asString(value);
  if (raw == null) return null;
  final parts = raw.split(':');
  if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
  return raw;
}

DateTime? _asInstant(Object? value) {
  if (value is! String) return null;
  return DateTime.tryParse(value)?.toLocal();
}
