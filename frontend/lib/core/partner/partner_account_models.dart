/// Typed models for the Partner account surfaces C12 adds — team management and
/// the payout account — mapped one-to-one from `backend-v1` (branch `develop`).
///
/// Source of truth:
///   * `controller/PartnerSettingsController` — `/api/partner/team**`,
///     `/api/partner/payout-account`
///   * `service/PartnerSettingsService`, `dto/PartnerSettingsDto`
///
/// ## Two models are reused, not redeclared
///
/// [PartnerTeamMember] is C0's (`partner_models.dart`) — it already carries id,
/// profile, user, role and active, which is everything the team UI needs. Only
/// the role helpers and the payout account are new here.
///
/// ## Reviews are deliberately absent from this file
///
/// C12's review surface introduces **no new model**. The list reuses UI-29's
/// `ReviewSummaryRecord` (`GET /api/places/{placeId}/reviews`), and the reply
/// endpoint returns the same review shape. Adding a partner-specific review DTO
/// would have been a second definition of a model that already exists.
///
/// ## Role rules, read from `PartnerSettingsService`
///
///   * `SETTINGS_WRITE_ROLES` = OWNER, MANAGER — C6 already mirrors this.
///   * `PAYOUT_WRITE_ROLES` = **OWNER, FINANCE** — new in C12.
///   * Team add / update / remove call `requireOwner` — **OWNER only**.
///
/// Reads are open to any resolved team member; only writes are gated.
library;

import 'partner_models.dart';

/// The wire literal for a role, or null for [PartnerTeamRole.unknown] — which
/// therefore can never be sent.
String? partnerTeamRoleWire(PartnerTeamRole role) => switch (role) {
      PartnerTeamRole.owner => 'OWNER',
      PartnerTeamRole.manager => 'MANAGER',
      PartnerTeamRole.revenue => 'REVENUE',
      PartnerTeamRole.reservations => 'RESERVATIONS',
      PartnerTeamRole.frontDesk => 'FRONT_DESK',
      PartnerTeamRole.finance => 'FINANCE',
      PartnerTeamRole.content => 'CONTENT',
      PartnerTeamRole.housekeeping => 'HOUSEKEEPING',
      PartnerTeamRole.viewer => 'VIEWER',
      PartnerTeamRole.unknown => null,
    };

/// The five real roles, in the backend's own declaration order.
///
/// `SUPER_PARTNER` does not exist in `PartnerTeamRole` and is never created.
const List<PartnerTeamRole> partnerAssignableRoles = [
  PartnerTeamRole.owner,
  PartnerTeamRole.manager,
  PartnerTeamRole.frontDesk,
  PartnerTeamRole.finance,
  PartnerTeamRole.viewer,
];

/// `dto/PartnerSettingsDto.PartnerPayoutAccountResponse`.
///
/// ## The full account number never exists on this side
///
/// `PartnerSettingsService` documents it plainly: "No payout is ever executed
/// and no real bank account number is ever persisted — `bankAccountLast4` is
/// derived once from the request and the full number is discarded immediately
/// after." So the response carries only the last four digits, and there is
/// nothing sensitive to mask on the client because nothing sensitive is ever
/// sent back.
class PartnerPayoutAccount {
  final int id;
  final int? partnerProfileId;
  final String? accountHolderName;
  final String? bankName;

  /// The only fragment of the account number that exists server-side.
  final String? bankAccountLast4;

  final String? payoutMethod;

  /// Server vocabulary (live: `VERIFIED`). Shown verbatim — the client does not
  /// re-interpret a verification state it does not own.
  final String? status;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PartnerPayoutAccount({
    required this.id,
    this.partnerProfileId,
    this.accountHolderName,
    this.bankName,
    this.bankAccountLast4,
    this.payoutMethod,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  static PartnerPayoutAccount? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id == null) return null;
    return PartnerPayoutAccount(
      id: id,
      partnerProfileId: _asInt(json['partnerProfileId']),
      accountHolderName: _asString(json['accountHolderName']),
      bankName: _asString(json['bankName']),
      bankAccountLast4: _asString(json['bankAccountLast4']),
      payoutMethod: _asString(json['payoutMethod']),
      status: _asString(json['status']),
      createdAt: _asInstant(json['createdAt']),
      updatedAt: _asInstant(json['updatedAt']),
    );
  }
}

/// `model/PayoutMethod`, mirrored so only real values can be submitted.
enum PartnerPayoutMethod {
  bankTransfer,
  manual,
  unknown;

  static PartnerPayoutMethod parse(Object? raw) => switch (raw) {
        'BANK_TRANSFER' => PartnerPayoutMethod.bankTransfer,
        'MANUAL' => PartnerPayoutMethod.manual,
        _ => PartnerPayoutMethod.unknown,
      };

  String? get wireValue => switch (this) {
        PartnerPayoutMethod.bankTransfer => 'BANK_TRANSFER',
        PartnerPayoutMethod.manual => 'MANUAL',
        PartnerPayoutMethod.unknown => null,
      };

  /// The two the backend enum actually declares. `unknown` has no wire value,
  /// so it can never be submitted.
  static const List<PartnerPayoutMethod> selectable = [
    PartnerPayoutMethod.bankTransfer,
    PartnerPayoutMethod.manual,
  ];
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

DateTime? _asInstant(Object? value) {
  if (value is! String) return null;
  return DateTime.tryParse(value)?.toLocal();
}
