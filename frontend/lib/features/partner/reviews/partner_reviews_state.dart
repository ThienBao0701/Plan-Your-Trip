import 'package:flutter/foundation.dart';

import '../../../core/mock/app_models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/partner/partner_state.dart';

/// Outcome of publishing or editing a partner reply.
enum PartnerReplyResult {
  success,
  unauthorized,

  /// 403 — the partner profile exists but is not APPROVED.
  forbidden,

  /// Uniform 404 — unknown review, or one on a place this partner does not own.
  notFound,

  /// 422 — the review is not `APPROVED`, so it cannot be replied to.
  notReplyable,

  /// 400 — blank or over-long content.
  validation,

  failed,

  /// The reply may already be published, and there is no endpoint to withdraw
  /// it. The caller must re-read rather than retry blindly.
  uncertain,
}

/// Which reviews the operator wants to see. Applied on the client, over a list
/// the server returns **in full** — see the class doc.
enum PartnerReviewFilter { all, needsReply, replied }

/// Where the reviews module stands.
enum PartnerReviewsStatus {
  idle,
  loading,
  ready,

  /// No property is selected, so there is no place whose reviews to list.
  noProperty,

  unauthorized,
  forbidden,
  notFound,
  error,
}

/// State for the Partner Reviews module (C12).
///
/// ## The backend gives a partner very little here
///
/// `PartnerReviewController` has exactly **one** endpoint —
/// `PUT /api/partner/reviews/{id}/reply`. There is no partner review list, no
/// detail, and no moderation. So the list comes from the **public**
/// `GET /api/places/{placeId}/reviews`, which `ApiClient.getPlaceReviews`
/// (UI-29) already implements and which returns only `APPROVED` reviews — by
/// happy coincidence exactly the set a partner may reply to, since any other
/// status is a 422.
///
/// **A partner cannot read a review's text.** `ReviewService.getReview` gates
/// `GET /api/reviews/{id}` on `checkOwnerOrAdmin` against the review's *author*,
/// so a partner gets 403 (verified live). The fields available are rating,
/// title, author name, status, date and the partner's own reply. The screen says
/// so rather than leaving an operator wondering why there is no review body.
///
/// ## Filtering is client-side, and legitimately so
///
/// The place endpoint takes no filter, no sort and no page — it returns the
/// property's complete approved list in one response. Filtering a complete list
/// is honest; it would not be if the server were paginating. The absence of
/// pagination is reported as a scalability concern instead.
class PartnerReviewsState extends ChangeNotifier {
  final ApiClient api;

  PartnerReviewsState({required this.api});

  PartnerReviewsStatus _status = PartnerReviewsStatus.idle;
  String? _errorMessage;

  List<ReviewSummaryRecord> _reviews = const [];
  int? _placeId;
  PartnerReviewFilter _filter = PartnerReviewFilter.all;

  int? _openReviewId;
  int? _pendingReplyId;

  int _loadToken = 0;

  PartnerReviewsStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<ReviewSummaryRecord> get reviews => List.unmodifiable(_reviews);
  int? get placeId => _placeId;
  PartnerReviewFilter get filter => _filter;
  int? get openReviewId => _openReviewId;
  int? get pendingReplyId => _pendingReplyId;

  bool get isLoading => _status == PartnerReviewsStatus.loading;
  bool get isReady => _status == PartnerReviewsStatus.ready;
  bool get isRetryable => _status == PartnerReviewsStatus.error;

  /// The property genuinely has no approved reviews.
  bool get isEmpty => isReady && _reviews.isEmpty;

  /// The filter matched nothing although reviews exist — a different message.
  bool get isFilteredEmpty =>
      isReady && _reviews.isNotEmpty && visibleReviews.isEmpty;

  /// Reviews after the client-side filter.
  List<ReviewSummaryRecord> get visibleReviews => switch (_filter) {
        PartnerReviewFilter.all => _reviews,
        PartnerReviewFilter.needsReply =>
          _reviews.where((r) => r.partnerReply == null).toList(growable: false),
        PartnerReviewFilter.replied =>
          _reviews.where((r) => r.partnerReply != null).toList(growable: false),
      };

  int get needsReplyCount =>
      _reviews.where((r) => r.partnerReply == null).length;

  int get repliedCount => _reviews.where((r) => r.partnerReply != null).length;

  ReviewSummaryRecord? get openReview {
    final id = _openReviewId;
    if (id == null) return null;
    for (final review in _reviews) {
      if (review.id == id) return review;
    }
    return null;
  }

  /// Whether the review may be replied to at all. `ReviewService.partnerReply`
  /// answers anything other than `APPROVED` with a 422, so a non-approved review
  /// never gets a reply box.
  bool canReplyTo(ReviewSummaryRecord review) => review.status == 'APPROVED';

  /// Loads the selected property's approved reviews.
  ///
  /// The place endpoint is public, so it is asked for a property only when the
  /// workspace lists it — an id the partner does not own never leaves the
  /// client.
  Future<void> load(PartnerState partner, int? propertyId) async {
    final token = ++_loadToken;
    if (propertyId != _placeId) {
      _reviews = const [];
      _openReviewId = null;
      _filter = PartnerReviewFilter.all;
    }
    _status = PartnerReviewsStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final owned =
        propertyId != null && partner.properties.any((p) => p.id == propertyId);
    if (!owned) {
      _placeId = null;
      _reviews = const [];
      _openReviewId = null;
      _status = PartnerReviewsStatus.noProperty;
      notifyListeners();
      return;
    }

    final result = await api.getPlaceReviews(propertyId);
    if (token != _loadToken) return;

    if (!result.success) {
      _reviews = const [];
      _openReviewId = null;
      _status = switch (result.errorKind) {
        ApiErrorKind.unauthorized => PartnerReviewsStatus.unauthorized,
        ApiErrorKind.forbidden => PartnerReviewsStatus.forbidden,
        ApiErrorKind.notFound => PartnerReviewsStatus.notFound,
        _ => PartnerReviewsStatus.error,
      };
      _errorMessage = result.message;
      notifyListeners();
      return;
    }

    _placeId = propertyId;
    _reviews = result.data ?? const [];

    final open = _openReviewId;
    if (open != null && !_reviews.any((r) => r.id == open)) {
      _openReviewId = null;
    }

    _status = PartnerReviewsStatus.ready;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> refresh(PartnerState partner) => load(partner, _placeId);

  void setFilter(PartnerReviewFilter filter) {
    if (_filter == filter) return;
    _filter = filter;
    // A review hidden by the new filter must not stay open beside it.
    final open = openReview;
    if (open != null && !visibleReviews.contains(open)) _openReviewId = null;
    notifyListeners();
  }

  /// Opens one review. Refuses an id outside the loaded list.
  void openReviewDetail(int reviewId) {
    if (!_reviews.any((r) => r.id == reviewId)) return;
    if (_openReviewId == reviewId) return;
    _openReviewId = reviewId;
    notifyListeners();
  }

  void closeDetail() {
    if (_openReviewId == null) return;
    _openReviewId = null;
    notifyListeners();
  }

  /// Publishes or replaces the partner reply.
  ///
  /// One reply exists per review: the first call creates it, later calls replace
  /// it. **There is no delete endpoint**, so this is publishing something that
  /// cannot be withdrawn — the caller is expected to have confirmed. On success
  /// the list is re-read rather than patched locally, because the reply
  /// timestamps are server-generated.
  Future<PartnerReplyResult> submitReply({
    required PartnerState partner,
    required int reviewId,
    required String content,
  }) async {
    final review = _reviews.where((r) => r.id == reviewId).firstOrNull;
    if (review == null) return PartnerReplyResult.notFound;
    if (!canReplyTo(review)) return PartnerReplyResult.notReplyable;
    if (content.trim().isEmpty) return PartnerReplyResult.validation;
    if (_pendingReplyId != null) return PartnerReplyResult.failed;

    _pendingReplyId = reviewId;
    notifyListeners();

    final result =
        await api.replyToPartnerReview(reviewId: reviewId, content: content);

    _pendingReplyId = null;

    if (!result.success) {
      notifyListeners();
      return switch (result.errorKind) {
        ApiErrorKind.unauthorized => PartnerReplyResult.unauthorized,
        ApiErrorKind.forbidden => PartnerReplyResult.forbidden,
        ApiErrorKind.notFound => PartnerReplyResult.notFound,
        ApiErrorKind.unprocessable => PartnerReplyResult.notReplyable,
        ApiErrorKind.validation => PartnerReplyResult.validation,
        ApiErrorKind.uncertain => PartnerReplyResult.uncertain,
        _ => PartnerReplyResult.failed,
      };
    }

    // The reply body, its timestamps and the display name all come from the
    // server; re-reading is the only way to show what was actually stored.
    await load(partner, _placeId);
    return PartnerReplyResult.success;
  }

  void reset() {
    _loadToken++;
    _status = PartnerReviewsStatus.idle;
    _errorMessage = null;
    _reviews = const [];
    _placeId = null;
    _filter = PartnerReviewFilter.all;
    _openReviewId = null;
    _pendingReplyId = null;
    notifyListeners();
  }
}
