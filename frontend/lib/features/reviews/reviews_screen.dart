import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_breakpoints.dart';
import '../../design/app_colors.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';

class PlaceReviewSummaryCard extends StatelessWidget {
  final Place place;

  const PlaceReviewSummaryCard({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final summary = app.reviewSummaryForPlace(place.id);
    if (place.hotelDetail == null && summary.total == 0) {
      return const SizedBox.shrink();
    }
    return OceanGlassCard(
      key: const Key('place-review-summary'),
      semanticLabel: l10n.reviewSummarySemantic(place.name),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.reviews_rounded, color: AppColors.ocean),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.reviewSummaryTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      l10n.reviewPublicVisibilityNotice,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (!app.demoMode)
            OceanGlassSurface(
              blur: 0,
              color: AppColors.paleCyan,
              child: Text(
                l10n.reviewsRealUnavailableMessage,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else if (summary.total == 0)
            OceanEmptyState(
              title: l10n.reviewNoReviewsTitle,
              message: l10n.reviewNoReviewsMessage,
            )
          else ...[
            _AggregateRow(summary: summary),
            const SizedBox(height: AppSpacing.md),
            _RatingDistribution(summary: summary),
            const SizedBox(height: AppSpacing.md),
            for (final review in summary.preview)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _ReviewCard(
                  review: review,
                  publicSummary: true,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReviewDetailScreen(reviewId: review.id),
                    ),
                  ),
                ),
              ),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OceanSecondaryButton(
                key: const Key('place-see-all-reviews'),
                label: l10n.reviewSeeAllAction,
                icon: Icons.list_alt_rounded,
                fullWidth: false,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlaceReviewsScreen(place: place),
                  ),
                ),
              ),
              OceanPrimaryButton(
                key: const Key('place-write-review'),
                label: l10n.reviewWriteAction,
                icon: Icons.rate_review_rounded,
                semanticLabel: l10n.reviewWriteSemantic(place.name),
                fullWidth: false,
                onPressed: () => _openWriteReview(context, place),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openWriteReview(BuildContext context, Place place) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final eligibility = app.reviewEligibilityForPlace(place.id);
    final booking = eligibility.booking;
    if (!eligibility.canReview || booking == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(reviewActionMessage(l10n, eligibility.result))),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WriteReviewScreen(booking: booking)),
    );
  }
}

class PlaceReviewsScreen extends StatefulWidget {
  final Place place;

  const PlaceReviewsScreen({super.key, required this.place});

  @override
  State<PlaceReviewsScreen> createState() => _PlaceReviewsScreenState();
}

class _PlaceReviewsScreenState extends State<PlaceReviewsScreen> {
  ReviewSort _sort = ReviewSort.newest;
  int? _rating;
  bool _verifiedOnly = false;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final reviews = app.publicReviewsForPlace(
      widget.place.id,
      sort: _sort,
      rating: _rating,
      verifiedOnly: _verifiedOnly,
    );

    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.reviewsTitle),
      ),
      body: BubbleBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            key: const Key('reviews-list-screen'),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              OceanContentConstraint(
                maxWidth: AppBreakpoints.maxContentWidth,
                child: !app.demoMode
                    ? OceanEmptyState(
                        title: l10n.reviewsRealUnavailableTitle,
                        message: l10n.reviewsRealUnavailableMessage,
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ReviewsHeader(place: widget.place),
                          const SizedBox(height: AppSpacing.md),
                          _ReviewFilters(
                            sort: _sort,
                            rating: _rating,
                            verifiedOnly: _verifiedOnly,
                            onSortChanged: (value) =>
                                setState(() => _sort = value),
                            onRatingChanged: (value) =>
                                setState(() => _rating = value),
                            onVerifiedChanged: (value) =>
                                setState(() => _verifiedOnly = value),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          if (reviews.isEmpty)
                            OceanEmptyState(
                              title: l10n.reviewFilteredEmptyTitle,
                              message: l10n.reviewFilteredEmptyMessage,
                            )
                          else
                            for (final review in reviews)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: _ReviewCard(
                                  review: review,
                                  publicSummary: true,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ReviewDetailScreen(
                                          reviewId: review.id),
                                    ),
                                  ),
                                ),
                              ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyReviewsScreen extends StatelessWidget {
  const MyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final reviews = app.myReviews();
    final grouped = {
      for (final status in ReviewStatus.values)
        status: reviews.where((review) => review.status == status).toList(),
    };

    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.myReviewsTitle),
      ),
      body: BubbleBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            key: const Key('my-reviews-screen'),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              OceanContentConstraint(
                maxWidth: AppBreakpoints.maxContentWidth,
                child: !app.demoMode
                    ? OceanEmptyState(
                        title: l10n.myReviewsRealEmptyTitle,
                        message: l10n.myReviewsRealEmptyMessage,
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OceanGlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.myReviewsTitle,
                                  style:
                                      Theme.of(context).textTheme.displaySmall,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  l10n.myReviewsSubtitle,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          if (reviews.isEmpty)
                            OceanEmptyState(
                              title: l10n.myReviewsEmptyTitle,
                              message: l10n.myReviewsEmptyMessage,
                            )
                          else
                            for (final entry in grouped.entries)
                              if (entry.value.isNotEmpty) ...[
                                _SectionTitle(
                                  title: reviewStatusLabel(l10n, entry.key),
                                  count: entry.value.length,
                                ),
                                for (final review in entry.value)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.sm,
                                    ),
                                    child: _ReviewCard(
                                      review: review,
                                      publicSummary: false,
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ReviewDetailScreen(
                                            reviewId: review.id,
                                            authorView: true,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: AppSpacing.md),
                              ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReviewDetailScreen extends StatelessWidget {
  final int reviewId;
  final bool authorView;

  const ReviewDetailScreen({
    super.key,
    required this.reviewId,
    this.authorView = false,
  });

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final review = app.reviewById(reviewId);
    final canShowFull = review != null &&
        (authorView || review.authorUserId == app.currentDemoUser.id);
    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.reviewDetailTitle),
      ),
      body: BubbleBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            key: const Key('review-detail-screen'),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              OceanContentConstraint(
                maxWidth: AppBreakpoints.maxContentWidth,
                child: review == null
                    ? OceanEmptyState(
                        title: l10n.reviewNotFoundTitle,
                        message: l10n.reviewNotFoundMessage,
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OceanGlassCard(
                            semanticLabel: l10n.reviewCardSemantic(
                              review.placeName,
                              review.ratingOverall,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: AppSpacing.xs,
                                  runSpacing: AppSpacing.xs,
                                  children: [
                                    OceanStatusPill(
                                      label: reviewStatusLabel(
                                        l10n,
                                        review.status,
                                      ),
                                      icon: Icons.verified_rounded,
                                      color: _reviewStatusColor(review.status),
                                    ),
                                    if (review.hasVerifiedBooking &&
                                        canShowFull)
                                      OceanStatusPill(
                                        label: l10n.reviewVerifiedStay,
                                        icon: Icons.hotel_rounded,
                                        color: AppColors.success,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                _Stars(rating: review.ratingOverall),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  review.title.isEmpty
                                      ? l10n.reviewUntitled
                                      : review.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  review.placeName,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  l10n.reviewAuthorLine(review.authorName),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                if (canShowFull && review.content.isNotEmpty)
                                  Text(
                                    review.content,
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  )
                                else
                                  OceanGlassSurface(
                                    blur: 0,
                                    color: AppColors.paleCyan,
                                    child: Text(
                                      l10n.reviewPublicSummaryOnly,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (canShowFull) ...[
                            const SizedBox(height: AppSpacing.md),
                            _FullReviewMetadata(review: review),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          OceanGlassSurface(
                            blur: 0,
                            color: AppColors.paleCyan,
                            child: Text(
                              l10n.reviewUnsupportedActionsNotice,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WriteReviewScreen extends StatefulWidget {
  final DemoBooking booking;

  const WriteReviewScreen({super.key, required this.booking});

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  int _overall = 5;
  int? _cleanliness;
  int? _service;
  int? _location;
  int? _value;
  int? _facilities;
  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final eligibility = app.reviewEligibilityForBooking(widget.booking);
    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.reviewWriteTitle),
      ),
      body: BubbleBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            key: const Key('write-review-screen'),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              OceanContentConstraint(
                maxWidth: AppBreakpoints.maxContentWidth,
                child: !eligibility.canReview
                    ? OceanEmptyState(
                        title: l10n.reviewIneligibleTitle,
                        message: reviewActionMessage(l10n, eligibility.result),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OceanGlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.booking.hotel.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  widget.booking.room.roomName,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                OceanStatusPill(
                                  label: l10n.reviewVerifiedStay,
                                  icon: Icons.hotel_rounded,
                                  color: AppColors.success,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  l10n.reviewBackendCreateNotice,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          OceanGlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  l10n.reviewOverallRatingLabel,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                _RatingPicker(
                                  key: const Key('review-overall-picker'),
                                  value: _overall,
                                  onChanged: (value) =>
                                      setState(() => _overall = value),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                TextField(
                                  key: const Key('review-title-field'),
                                  controller: _title,
                                  maxLength: 200,
                                  decoration: InputDecoration(
                                    labelText: l10n.reviewTitleLabel,
                                    helperText: l10n.reviewTitleHelper,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                TextField(
                                  key: const Key('review-content-field'),
                                  controller: _content,
                                  maxLength: 5000,
                                  minLines: 4,
                                  maxLines: 8,
                                  decoration: InputDecoration(
                                    labelText: l10n.reviewContentLabel,
                                    helperText: l10n.reviewContentHelper,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  l10n.reviewCategoryRatingsTitle,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.sm,
                                  children: [
                                    _OptionalRatingDropdown(
                                      label: l10n.reviewCategoryCleanliness,
                                      value: _cleanliness,
                                      onChanged: (value) =>
                                          setState(() => _cleanliness = value),
                                    ),
                                    _OptionalRatingDropdown(
                                      label: l10n.reviewCategoryService,
                                      value: _service,
                                      onChanged: (value) =>
                                          setState(() => _service = value),
                                    ),
                                    _OptionalRatingDropdown(
                                      label: l10n.reviewCategoryLocation,
                                      value: _location,
                                      onChanged: (value) =>
                                          setState(() => _location = value),
                                    ),
                                    _OptionalRatingDropdown(
                                      label: l10n.reviewCategoryValue,
                                      value: _value,
                                      onChanged: (value) =>
                                          setState(() => _value = value),
                                    ),
                                    _OptionalRatingDropdown(
                                      label: l10n.reviewCategoryFacilities,
                                      value: _facilities,
                                      onChanged: (value) =>
                                          setState(() => _facilities = value),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          OceanPrimaryButton(
                            key: const Key('review-submit-action'),
                            label: l10n.reviewSubmitAction,
                            icon: Icons.send_rounded,
                            onPressed: _submitting ? null : _submit,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_submitting) return;
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    setState(() => _submitting = true);
    final result = app.createDemoReviewForBooking(
      bookingCode: widget.booking.code,
      ratingOverall: _overall,
      ratingCleanliness: _cleanliness,
      ratingService: _service,
      ratingLocation: _location,
      ratingValue: _value,
      ratingFacilities: _facilities,
      title: _title.text,
      content: _content.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(reviewActionMessage(l10n, result))),
    );
    if (result == ReviewActionResult.success) {
      Navigator.pop(context, true);
    }
  }
}

class _ReviewsHeader extends StatelessWidget {
  final Place place;

  const _ReviewsHeader({required this.place});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final summary = app.reviewSummaryForPlace(place.id);
    return OceanGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(place.name, style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.reviewsSubtitle,
              style: Theme.of(context).textTheme.bodyLarge),
          if (summary.total > 0) ...[
            const SizedBox(height: AppSpacing.md),
            _AggregateRow(summary: summary),
          ],
        ],
      ),
    );
  }
}

class _AggregateRow extends StatelessWidget {
  final PlaceReviewSummary summary;

  const _AggregateRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final average = summary.average;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        if (average != null)
          OceanStatusPill(
            label: l10n.reviewAggregateAverage(average.toStringAsFixed(1)),
            icon: Icons.star_rounded,
            color: AppColors.ocean,
            semanticLabel:
                l10n.reviewRatingSemantic(average.toStringAsFixed(1)),
          ),
        OceanStatusPill(
          label: l10n.reviewCountExact(summary.total),
          icon: Icons.reviews_rounded,
          color: AppColors.turquoise600,
        ),
        if (summary.verifiedCount > 0)
          OceanStatusPill(
            label: l10n.reviewVerifiedCount(summary.verifiedCount),
            icon: Icons.hotel_rounded,
            color: AppColors.success,
          ),
      ],
    );
  }
}

class _RatingDistribution extends StatelessWidget {
  final PlaceReviewSummary summary;

  const _RatingDistribution({required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = summary.total == 0 ? 1 : summary.total;
    return Semantics(
      label: l10n.reviewDistributionSemantic,
      child: Column(
        children: [
          for (var rating = 5; rating >= 1; rating--)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
              child: Row(
                children: [
                  SizedBox(width: 42, child: Text(l10n.reviewStars(rating))),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      child: LinearProgressIndicator(
                        value: (summary.distribution[rating] ?? 0) / total,
                        minHeight: 8,
                        backgroundColor: AppColors.mist,
                        color: AppColors.ocean,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  SizedBox(
                    width: 28,
                    child: Text('${summary.distribution[rating] ?? 0}'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ReviewFilters extends StatelessWidget {
  final ReviewSort sort;
  final int? rating;
  final bool verifiedOnly;
  final ValueChanged<ReviewSort> onSortChanged;
  final ValueChanged<int?> onRatingChanged;
  final ValueChanged<bool> onVerifiedChanged;

  const _ReviewFilters({
    required this.sort,
    required this.rating,
    required this.verifiedOnly,
    required this.onSortChanged,
    required this.onRatingChanged,
    required this.onVerifiedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.reviewFiltersTitle,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              SizedBox(
                width: 240,
                child: DropdownButtonFormField<ReviewSort>(
                  key: const Key('review-sort-filter'),
                  initialValue: sort,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l10n.reviewSortLabel),
                  items: [
                    for (final value in ReviewSort.values)
                      DropdownMenuItem(
                        value: value,
                        child: Text(reviewSortLabel(l10n, value)),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) onSortChanged(value);
                  },
                ),
              ),
              SizedBox(
                width: 240,
                child: DropdownButtonFormField<int?>(
                  key: const Key('review-rating-filter'),
                  initialValue: rating,
                  isExpanded: true,
                  decoration:
                      InputDecoration(labelText: l10n.reviewFilterRating),
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text(l10n.walletFilterAll),
                    ),
                    for (var value = 5; value >= 1; value--)
                      DropdownMenuItem<int?>(
                        value: value,
                        child: Text(l10n.reviewStars(value)),
                      ),
                  ],
                  onChanged: onRatingChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          FilterChip(
            key: const Key('review-verified-filter'),
            label: Text(l10n.reviewFilterVerifiedOnly),
            selected: verifiedOnly,
            onSelected: onVerifiedChanged,
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final TravelerReview review;
  final bool publicSummary;
  final VoidCallback onTap;

  const _ReviewCard({
    required this.review,
    required this.publicSummary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    return OceanGlassCard(
      key: Key('review-card-${review.id}'),
      onTap: onTap,
      semanticLabel: l10n.reviewCardSemantic(
        review.placeName,
        review.ratingOverall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  review.title.isEmpty ? l10n.reviewUntitled : review.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              _Stars(rating: review.ratingOverall),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            publicSummary
                ? l10n.reviewAuthorLine(review.authorName)
                : review.placeName,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              OceanStatusPill(
                label: reviewStatusLabel(l10n, review.status),
                icon: Icons.verified_rounded,
                color: _reviewStatusColor(review.status),
              ),
              OceanStatusPill(
                label: date.format(review.createdAt),
                icon: Icons.calendar_month_rounded,
                color: AppColors.turquoise600,
              ),
              if (!publicSummary && review.hasVerifiedBooking)
                OceanStatusPill(
                  label: l10n.reviewVerifiedStay,
                  icon: Icons.hotel_rounded,
                  color: AppColors.success,
                ),
            ],
          ),
          if (!publicSummary && review.content.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              review.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _FullReviewMetadata extends StatelessWidget {
  final TravelerReview review;

  const _FullReviewMetadata({required this.review});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    return OceanGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.reviewDetailMetadataTitle,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          _DetailRow(
            icon: Icons.confirmation_number_rounded,
            label: l10n.reviewLinkedBookingLabel,
            value: review.bookingCode.isEmpty
                ? l10n.walletNoValue
                : maskSensitiveReference(review.bookingCode),
          ),
          _DetailRow(
            icon: Icons.calendar_month_rounded,
            label: l10n.reviewCreatedAtLabel,
            value: date.format(review.createdAt),
          ),
          if (review.approvedAt != null)
            _DetailRow(
              icon: Icons.check_circle_rounded,
              label: l10n.reviewApprovedAtLabel,
              value: date.format(review.approvedAt!),
            ),
          if (review.rejectedAt != null)
            _DetailRow(
              icon: Icons.cancel_rounded,
              label: l10n.reviewRejectedAtLabel,
              value: date.format(review.rejectedAt!),
            ),
          if (review.rejectReason.isNotEmpty)
            _DetailRow(
              icon: Icons.notes_rounded,
              label: l10n.reviewRejectReasonLabel,
              value: review.rejectReason,
            ),
          _DetailRow(
            icon: Icons.thumb_up_rounded,
            label: l10n.reviewHelpfulCountLabel,
            value: '${review.helpfulCount}',
          ),
          _DetailRow(
            icon: Icons.report_rounded,
            label: l10n.reviewReportedCountLabel,
            value: '${review.reportedCount}',
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$label $value',
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.ocean),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.labelLarge),
                    Text(value, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final int count;

  const _SectionTitle({required this.title, required this.count});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(
          AppLocalizations.of(context)!.reviewSectionHeader(title, count),
          style: Theme.of(context).textTheme.titleLarge,
        ),
      );
}

class _Stars extends StatelessWidget {
  final int rating;

  const _Stars({required this.rating});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final safe = rating.clamp(1, 5);
    return Semantics(
      label: l10n.reviewRatingOutOfFive(safe),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 1; i <= 5; i++)
              Icon(
                i <= safe ? Icons.star_rounded : Icons.star_border_rounded,
                color: AppColors.ocean,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}

class _RatingPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _RatingPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => SegmentedButton<int>(
        segments: [
          for (var rating = 1; rating <= 5; rating++)
            ButtonSegment(value: rating, label: Text('$rating')),
        ],
        selected: {value},
        onSelectionChanged: (selected) => onChanged(selected.first),
      );
}

class _OptionalRatingDropdown extends StatelessWidget {
  final String label;
  final int? value;
  final ValueChanged<int?> onChanged;

  const _OptionalRatingDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<int?>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          DropdownMenuItem<int?>(
            value: null,
            child: Text(l10n.reviewCategorySkipped),
          ),
          for (var rating = 1; rating <= 5; rating++)
            DropdownMenuItem<int?>(
              value: rating,
              child: Text(l10n.reviewStars(rating)),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

String reviewStatusLabel(AppLocalizations l10n, ReviewStatus status) {
  switch (status) {
    case ReviewStatus.pending:
      return l10n.reviewStatusPending;
    case ReviewStatus.approved:
      return l10n.reviewStatusApproved;
    case ReviewStatus.rejected:
      return l10n.reviewStatusRejected;
    case ReviewStatus.hidden:
      return l10n.reviewStatusHidden;
    case ReviewStatus.reported:
      return l10n.reviewStatusReported;
  }
}

String reviewSortLabel(AppLocalizations l10n, ReviewSort sort) {
  switch (sort) {
    case ReviewSort.newest:
      return l10n.reviewSortNewest;
    case ReviewSort.oldest:
      return l10n.reviewSortOldest;
    case ReviewSort.highestRating:
      return l10n.reviewSortHighest;
    case ReviewSort.lowestRating:
      return l10n.reviewSortLowest;
    case ReviewSort.mostHelpful:
      return l10n.reviewSortHelpful;
  }
}

String reviewCategoryLabel(
  AppLocalizations l10n,
  ReviewRatingCategory category,
) {
  switch (category) {
    case ReviewRatingCategory.cleanliness:
      return l10n.reviewCategoryCleanliness;
    case ReviewRatingCategory.service:
      return l10n.reviewCategoryService;
    case ReviewRatingCategory.location:
      return l10n.reviewCategoryLocation;
    case ReviewRatingCategory.value:
      return l10n.reviewCategoryValue;
    case ReviewRatingCategory.facilities:
      return l10n.reviewCategoryFacilities;
  }
}

String reviewActionMessage(
  AppLocalizations l10n,
  ReviewActionResult result,
) {
  switch (result) {
    case ReviewActionResult.success:
      return l10n.reviewSubmittedMessage;
    case ReviewActionResult.unavailable:
      return l10n.reviewUnavailableMessage;
    case ReviewActionResult.notFound:
      return l10n.reviewNotFoundMessage;
    case ReviewActionResult.ineligible:
      return l10n.reviewIneligibleCompletedOnly;
    case ReviewActionResult.duplicate:
      return l10n.reviewDuplicateMessage;
    case ReviewActionResult.invalidRating:
      return l10n.reviewInvalidRatingMessage;
    case ReviewActionResult.titleTooLong:
      return l10n.reviewTitleTooLongMessage;
    case ReviewActionResult.contentTooLong:
      return l10n.reviewContentTooLongMessage;
    case ReviewActionResult.unsupported:
      return l10n.reviewUnsupportedActionsNotice;
  }
}

Color _reviewStatusColor(ReviewStatus status) {
  switch (status) {
    case ReviewStatus.approved:
      return AppColors.success;
    case ReviewStatus.pending:
    case ReviewStatus.reported:
      return AppColors.warning;
    case ReviewStatus.rejected:
    case ReviewStatus.hidden:
      return AppColors.danger;
  }
}
