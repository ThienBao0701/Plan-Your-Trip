/// Typed models for the Partner Finance module (C11), mapped one-to-one from
/// `backend-v1` (branch `develop`).
///
/// Source of truth, read from the authoritative backend worktree and verified
/// live on :8081:
///   * `controller/PartnerFinanceController` — `/api/partner/finance/**`
///   * `service/PartnerFinanceService`
///   * `dto/PartnerFinanceDto`
///
/// ## These are derived estimates, not accounting records
///
/// The service's own Javadoc is explicit, and the UI repeats it rather than
/// dressing these figures up as a statement of account:
///
///   * `COMMISSION_RATE` is a **hard-coded flat 0.15** — "no real commission or
///     tax engine exists yet".
///   * `ESTIMATED_TAX_RATE` is a **hard-coded 0.10**, "purely informational (not
///     a real tax computation)".
///   * Settlement and payout "periods" are **synthesized calendar months** from
///     paid booking revenue — "there is no real settlement ledger or payout
///     scheduler in the system yet".
///   * `pendingSettlement` is simply the whole window's net revenue, because
///     nothing tracks what has actually been settled.
///
/// There are also **no records and no identifiers**: no invoice id, payout id,
/// settlement id or refund id exists anywhere in this API. Every endpoint
/// returns aggregates only, so there is no detail view to open, nothing to
/// export, and no per-record IDOR surface.
///
/// ## Currency
///
/// **No finance DTO carries a currency.** Not one of the seven responses has a
/// currency field, so amounts are rendered as grouped numbers with no symbol and
/// the screen says so once. This is determined from `PartnerFinanceDto` directly
/// — not inferred from the C5 rate-plan or C7 promotion findings — and it is
/// *not* the `Booking`/`Payment` currency, which those DTOs do carry.
library;

import 'partner_dashboard_models.dart';

/// A money amount exactly as the server sent it.
///
/// The point of this type is what it **cannot** do: it exposes no operators, so
/// the compiler makes client-side money arithmetic impossible. Every derived
/// figure — commission, net, tax, refund percentage, settlement totals — is
/// computed by `PartnerFinanceService` with `BigDecimal` and
/// `RoundingMode.HALF_UP`, and is read from the response rather than recomputed.
///
/// [value] is a `double` because that is what `jsonDecode` yields for a JSON
/// number. It is used only for display formatting and chart geometry, never for
/// arithmetic that produces a figure shown as money. Amounts in this product are
/// whole-unit VND-scale integers, far below the 2^53 boundary where a double
/// stops representing integers exactly.
class PartnerMoney {
  final double value;

  const PartnerMoney(this.value);

  static const PartnerMoney zero = PartnerMoney(0);

  /// Null when the field was absent — which is not the same as zero, and the UI
  /// keeps them apart.
  static PartnerMoney? maybe(Object? raw) {
    final parsed = partnerAsDouble(raw);
    return parsed == null ? null : PartnerMoney(parsed);
  }

  /// For a field the backend always populates (it `setScale`s a `BigDecimal`,
  /// never returns null).
  static PartnerMoney required(Object? raw) =>
      PartnerMoney(partnerAsDouble(raw) ?? 0);

  bool get isZero => value == 0;

  @override
  String toString() => 'PartnerMoney($value)';

  @override
  bool operator ==(Object other) =>
      other is PartnerMoney && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// `PartnerFinanceDto.FinanceMetric` — a (label, amount) pair used for
/// month-bucketed monetary breakdowns. The label is a server string such as
/// `2026-08`; it is never reformatted into a different calendar.
class PartnerFinanceMetric {
  final String label;
  final PartnerMoney amount;

  const PartnerFinanceMetric({required this.label, required this.amount});

  static PartnerFinanceMetric? fromJson(Map<String, dynamic> json) {
    final label = partnerAsString(json['label']);
    if (label == null) return null;
    return PartnerFinanceMetric(
      label: label,
      amount: PartnerMoney.required(json['amount']),
    );
  }
}

/// The status a synthesized settlement period carries.
///
/// `PartnerFinanceService.monthlySettlements` sets `PAID` for any month before
/// the current one and `PENDING` otherwise. These are **not** persisted states —
/// no settlement ledger exists — so they are labelled as an estimate throughout.
enum PartnerSettlementStatus {
  paid,
  pending,
  unknown;

  static PartnerSettlementStatus parse(Object? raw) => switch (raw) {
        'PAID' => PartnerSettlementStatus.paid,
        'PENDING' => PartnerSettlementStatus.pending,
        _ => PartnerSettlementStatus.unknown,
      };
}

/// `PartnerFinanceDto.SettlementHistoryItem` — one synthesized calendar month.
///
/// Carries no identifier, because no settlement record exists to identify.
class PartnerSettlementPeriod {
  /// A `YearMonth` string such as `2026-08`, exactly as the server produced it.
  final String period;

  final PartnerMoney grossAmount;
  final PartnerMoney commissionAmount;
  final PartnerMoney netAmount;
  final PartnerSettlementStatus status;

  const PartnerSettlementPeriod({
    required this.period,
    required this.grossAmount,
    required this.commissionAmount,
    required this.netAmount,
    required this.status,
  });

  static PartnerSettlementPeriod? fromJson(Map<String, dynamic> json) {
    final period = partnerAsString(json['period']);
    if (period == null) return null;
    return PartnerSettlementPeriod(
      period: period,
      grossAmount: PartnerMoney.required(json['grossAmount']),
      commissionAmount: PartnerMoney.required(json['commissionAmount']),
      netAmount: PartnerMoney.required(json['netAmount']),
      status: PartnerSettlementStatus.parse(json['status']),
    );
  }
}

/// `PartnerFinanceDto.PartnerRevenueResponse`.
class PartnerFinanceRevenue {
  final List<PartnerTimeSeriesPoint> revenueByDay;
  final List<PartnerFinanceMetric> revenueByMonth;
  final List<PartnerMetricBreakdown> revenueByHotel;
  final List<PartnerMetricBreakdown> revenueByRoom;

  /// Both are server-computed; the client never divides revenue by a count.
  final PartnerMoney averageBookingValue;
  final PartnerMoney highestBooking;

  const PartnerFinanceRevenue({
    required this.revenueByDay,
    required this.revenueByMonth,
    required this.revenueByHotel,
    required this.revenueByRoom,
    required this.averageBookingValue,
    required this.highestBooking,
  });

  bool get isEmpty =>
      revenueByMonth.isEmpty &&
      revenueByHotel.isEmpty &&
      revenueByRoom.isEmpty &&
      revenueByDay.every((p) => p.value == 0);

  static PartnerFinanceRevenue fromJson(Map<String, dynamic> json) =>
      PartnerFinanceRevenue(
        revenueByDay:
            _list(json['revenueByDay'], PartnerTimeSeriesPoint.fromJson),
        revenueByMonth:
            _list(json['revenueByMonth'], PartnerFinanceMetric.fromJson),
        revenueByHotel:
            _list(json['revenueByHotel'], PartnerMetricBreakdown.fromJson),
        revenueByRoom:
            _list(json['revenueByRoom'], PartnerMetricBreakdown.fromJson),
        averageBookingValue: PartnerMoney.required(json['averageBookingValue']),
        highestBooking: PartnerMoney.required(json['highestBooking']),
      );
}

/// `PartnerFinanceDto.PartnerCommissionResponse`.
class PartnerCommission {
  final PartnerMoney gross;
  final PartnerMoney commission;
  final PartnerMoney net;

  /// The flat platform rate as a fraction (live: `0.15`). Server-supplied and
  /// hard-coded there; the client neither applies nor re-derives it.
  final double commissionRate;

  const PartnerCommission({
    required this.gross,
    required this.commission,
    required this.net,
    required this.commissionRate,
  });

  static PartnerCommission fromJson(Map<String, dynamic> json) =>
      PartnerCommission(
        gross: PartnerMoney.required(json['gross']),
        commission: PartnerMoney.required(json['commission']),
        net: PartnerMoney.required(json['net']),
        commissionRate: partnerAsDouble(json['commissionRate']) ?? 0,
      );
}

/// `PartnerFinanceDto.PartnerSettlementResponse`.
///
/// **Two of these scalars can contradict the history**, and the UI says so
/// rather than reconciling them. `getSettlement` computes `paid` and
/// `lastSettlement` from "every period that is not the current period" — which
/// includes **future** months — while `monthlySettlements` marks any month that
/// is not before the current one as `PENDING`. So a future month is counted into
/// `paid` while appearing as `PENDING` in the same response. Reported, not
/// papered over. See [historyContradictsPaid].
class PartnerSettlement {
  final PartnerMoney currentSettlement;
  final PartnerMoney lastSettlement;
  final PartnerMoney pending;
  final PartnerMoney paid;
  final List<PartnerSettlementPeriod> settlementHistory;
  final PartnerMoney estimatedNextSettlement;

  const PartnerSettlement({
    required this.currentSettlement,
    required this.lastSettlement,
    required this.pending,
    required this.paid,
    required this.settlementHistory,
    required this.estimatedNextSettlement,
  });

  bool get isEmpty => settlementHistory.isEmpty;

  List<PartnerSettlementPeriod> get paidPeriods => settlementHistory
      .where((p) => p.status == PartnerSettlementStatus.paid)
      .toList(growable: false);

  List<PartnerSettlementPeriod> get pendingPeriods => settlementHistory
      .where((p) => p.status == PartnerSettlementStatus.pending)
      .toList(growable: false);

  /// True when the `paid` scalar claims money was settled although no period in
  /// the history is marked `PAID`. A pure comparison of two server values — no
  /// arithmetic, and nothing is corrected.
  bool get historyContradictsPaid =>
      !paid.isZero && paidPeriods.isEmpty && settlementHistory.isNotEmpty;

  static PartnerSettlement fromJson(Map<String, dynamic> json) =>
      PartnerSettlement(
        currentSettlement: PartnerMoney.required(json['currentSettlement']),
        lastSettlement: PartnerMoney.required(json['lastSettlement']),
        pending: PartnerMoney.required(json['pending']),
        paid: PartnerMoney.required(json['paid']),
        settlementHistory:
            _list(json['settlementHistory'], PartnerSettlementPeriod.fromJson),
        estimatedNextSettlement:
            PartnerMoney.required(json['estimatedNextSettlement']),
      );
}

/// `PartnerFinanceDto.PartnerPayoutResponse`.
///
/// The same synthesized month buckets, split by the same status rule. No payout
/// record, reference, bank detail or provider identifier exists in this API — so
/// none can be displayed, and none can leak.
class PartnerPayouts {
  final List<PartnerSettlementPeriod> upcomingPayouts;
  final List<PartnerSettlementPeriod> completedPayouts;

  /// `LocalDate.now().withDayOfMonth(1).plusMonths(1)` — an assumed monthly
  /// cadence, not a scheduled date.
  final DateTime? estimatedPayoutDate;

  const PartnerPayouts({
    required this.upcomingPayouts,
    required this.completedPayouts,
    this.estimatedPayoutDate,
  });

  bool get isEmpty => upcomingPayouts.isEmpty && completedPayouts.isEmpty;

  static PartnerPayouts fromJson(Map<String, dynamic> json) => PartnerPayouts(
        upcomingPayouts:
            _list(json['upcomingPayouts'], PartnerSettlementPeriod.fromJson),
        completedPayouts:
            _list(json['completedPayouts'], PartnerSettlementPeriod.fromJson),
        estimatedPayoutDate: partnerAsDate(json['estimatedPayoutDate']),
      );
}

/// `PartnerFinanceDto.PartnerInvoiceFinanceResponse` — counts by status plus a
/// total. There is **no invoice list and no invoice document**: the partner API
/// exposes no invoice id and no download endpoint, so no export control is
/// offered.
class PartnerInvoiceFinance {
  final int issued;
  final int paid;
  final int cancelled;
  final int refunded;
  final PartnerMoney totalInvoiceAmount;

  const PartnerInvoiceFinance({
    required this.issued,
    required this.paid,
    required this.cancelled,
    required this.refunded,
    required this.totalInvoiceAmount,
  });

  int get total => issued + paid + cancelled + refunded;

  bool get isEmpty => total == 0;

  static PartnerInvoiceFinance fromJson(Map<String, dynamic> json) =>
      PartnerInvoiceFinance(
        issued: partnerAsInt(json['issued']) ?? 0,
        paid: partnerAsInt(json['paid']) ?? 0,
        cancelled: partnerAsInt(json['cancelled']) ?? 0,
        refunded: partnerAsInt(json['refunded']) ?? 0,
        totalInvoiceAmount: PartnerMoney.required(json['totalInvoiceAmount']),
      );
}

/// `PartnerFinanceDto.PartnerRefundResponse`.
///
/// A partner **cannot initiate a refund**: no partner refund endpoint exists,
/// and `PaymentService`'s refund is admin-side. This is a read-only count, so no
/// refund action is offered.
class PartnerRefunds {
  final int refundCount;
  final PartnerMoney refundAmount;

  /// Server-computed percentage over refunded + paid payments. Not re-derived.
  final double refundPercentage;

  const PartnerRefunds({
    required this.refundCount,
    required this.refundAmount,
    required this.refundPercentage,
  });

  bool get isEmpty => refundCount == 0;

  static PartnerRefunds fromJson(Map<String, dynamic> json) => PartnerRefunds(
        refundCount: partnerAsInt(json['refundCount']) ?? 0,
        refundAmount: PartnerMoney.required(json['refundAmount']),
        refundPercentage: partnerAsDouble(json['refundPercentage']) ?? 0,
      );
}

List<T> _list<T>(Object? raw, T? Function(Map<String, dynamic>) parse) {
  if (raw is! List) return const [];
  final items = <T>[];
  for (final entry in raw) {
    if (entry is! Map<String, dynamic>) continue;
    final item = parse(entry);
    if (item != null) items.add(item);
  }
  return List.unmodifiable(items);
}
