import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_breakpoints.dart';
import '../../design/app_colors.dart';
import '../../design/app_icon_sizes.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/add_to_trip_sheet.dart';
import '../../shared/widgets/bookmark_button.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../auth/login_screen.dart';
import '../hotels/hotel_room_selection_screen.dart';
import '../hotels/hotel_utils.dart';
import '../places/place_detail_screen.dart';

enum _SavedPlacesTab { allSaved, collections }

class SavedPlacesScreen extends StatefulWidget {
  final bool loading;

  const SavedPlacesScreen({super.key, this.loading = false});

  @override
  State<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends State<SavedPlacesScreen> {
  final search = TextEditingController();
  String? selectedCategory;
  SavedPlaceSort sort = SavedPlaceSort.newest;
  _SavedPlacesTab selectedTab = _SavedPlacesTab.allSaved;
  String? selectedCollectionId;
  int? selectedRealCollectionId;

  @override
  void initState() {
    super.initState();
    // In Real Mode, load the wishlist for the default "All saved" tab so its
    // list and counts are accurate. No-op / no HTTP in Demo Mode.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final app = AppScope.of(context);
      if (!app.demoMode) _loadRealWishlist();
    });
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final categories = app.savedPlaceCategories;
    final effectiveCategory =
        categories.contains(selectedCategory) ? selectedCategory : null;
    final results = app.savedPlaceResults(
      query: search.text,
      category: effectiveCategory,
      sort: sort,
    );
    final selectedCollection = selectedCollectionId == null
        ? null
        : app.savedCollectionById(selectedCollectionId!);

    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.savedPlacesTitle),
      ),
      body: BubbleBackground(
        child: SafeArea(
          top: false,
          child: widget.loading
              ? const Center(
                  child: SizedBox(width: 420, child: OceanLoadingState()),
                )
              : RefreshIndicator(
                  onRefresh: _handleRealRefresh,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    children: [
                      OceanContentConstraint(
                        maxWidth: AppBreakpoints.maxContentWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _SavedPlacesHeader(
                              count: app.demoMode
                                  ? app.savedPlaceCount
                                  : app.realWishlist.length,
                              collectionCount: app.demoMode
                                  ? app.savedCollectionCount
                                  : app.realSavedCollections.length,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _SavedPlacesTabs(
                              selected: selectedTab,
                              savedCount: app.demoMode
                                  ? app.savedPlaceCount
                                  : app.realWishlist.length,
                              collectionCount: app.demoMode
                                  ? app.savedCollectionCount
                                  : app.realSavedCollections.length,
                              onSelected: (tab) async {
                                setState(() {
                                  selectedTab = tab;
                                  if (tab == _SavedPlacesTab.allSaved) {
                                    selectedCollectionId = null;
                                    selectedRealCollectionId = null;
                                  }
                                });
                                if (!app.demoMode) {
                                  if (tab == _SavedPlacesTab.collections) {
                                    await _loadRealCollections();
                                  } else {
                                    await _loadRealWishlist();
                                  }
                                }
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            if (selectedTab == _SavedPlacesTab.allSaved)
                              !app.demoMode
                                  ? _buildRealWishlist(app, l10n)
                                  : _buildSavedList(
                                      app: app,
                                      l10n: l10n,
                                      categories: categories,
                                      effectiveCategory: effectiveCategory,
                                      results: results,
                                    )
                            else if (!app.demoMode)
                              _buildRealCollections(app, l10n)
                            else if (selectedCollection != null)
                              _CollectionDetailView(
                                collection: selectedCollection,
                                places: app.resolvedCollectionPlaces(
                                  selectedCollection.id,
                                ),
                                itemCount: app.savedCollectionItemCount(
                                  selectedCollection.id,
                                ),
                                onBack: () => setState(
                                  () => selectedCollectionId = null,
                                ),
                                onEdit: () => _editCollection(
                                  collection: selectedCollection,
                                ),
                                onDelete: () => _confirmDeleteCollection(
                                  selectedCollection,
                                ),
                                onAddSavedPlace: () =>
                                    _addSavedPlaceToCollection(
                                  selectedCollection,
                                ),
                                onOpen: _openCollectionPlace,
                                onAddToTrip: _addCollectionPlaceToTrip,
                                onRemove: _removeCollectionPlace,
                              )
                            else
                              _CollectionOverview(
                                collections: app.visibleSavedCollections,
                                itemCountFor: app.savedCollectionItemCount,
                                onCreate: () => _editCollection(),
                                onOpen: (collection) => setState(
                                  () => selectedCollectionId = collection.id,
                                ),
                                onEdit: (collection) =>
                                    _editCollection(collection: collection),
                                onDelete: _confirmDeleteCollection,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _handleRealRefresh() async {
    final app = AppScope.of(context);
    if (app.demoMode) return;
    if (selectedTab == _SavedPlacesTab.allSaved) {
      await _loadRealWishlist(refresh: true);
      return;
    }
    if (selectedRealCollectionId != null) {
      await _loadRealCollectionDetail(selectedRealCollectionId!, refresh: true);
      return;
    }
    await _loadRealCollections(refresh: true);
  }

  Future<void> _loadRealWishlist({bool refresh = false}) async {
    final app = AppScope.of(context);
    final outcome = await app.loadRealWishlist(refresh: refresh);
    if (mounted && outcome == WishlistActionResult.unauthenticated) {
      _showRealCollectionsReauth();
    }
  }

  Widget _buildRealWishlist(AppState app, AppLocalizations l10n) {
    if (app.realWishlistLoading && app.realWishlist.isEmpty) {
      return const OceanLoadingState();
    }
    final error = app.realWishlistError;
    if (error != null && app.realWishlist.isEmpty) {
      return OceanRecoverableErrorState(
        message: error == WishlistActionResult.network
            ? l10n.wishlistBookmarkNetworkMessage
            : l10n.wishlistRealErrorMessage,
        onReload: () => _loadRealWishlist(refresh: true),
      );
    }
    if (app.realWishlist.isEmpty) {
      return OceanEmptyState(
        title: l10n.wishlistRealEmptyTitle,
        message: l10n.wishlistRealEmptyMessage,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in app.realWishlist)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _RealWishlistCard(item: item),
          ),
      ],
    );
  }

  Widget _buildSavedList({
    required AppState app,
    required AppLocalizations l10n,
    required List<String> categories,
    required String? effectiveCategory,
    required List<ResolvedSavedPlace> results,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OceanSearchField(
            key: const Key('saved-places-search-field'),
            controller: search,
            hintText: l10n.savedPlacesSearchHint,
            semanticLabel: l10n.searchFieldSemanticLabel,
            onChanged: (_) => setState(() {}),
            onClear: () => setState(() => search.clear()),
          ),
          const SizedBox(height: AppSpacing.md),
          _SavedPlaceControls(
            categories: categories,
            selectedCategory: effectiveCategory,
            sort: sort,
            onCategory: (category) =>
                setState(() => selectedCategory = category),
            onSort: (value) => setState(() => sort = value),
          ),
          const SizedBox(height: AppSpacing.md),
          _WishlistBoundary(),
          const SizedBox(height: AppSpacing.md),
          if (app.visibleSavedPlaces.isEmpty)
            OceanEmptyState(
              title: l10n.savedPlacesEmptyTitle,
              message: l10n.savedPlacesEmptyMessage,
            )
          else if (results.isEmpty)
            OceanEmptyState(
              title: l10n.savedPlacesDemoEmptyTitle,
              message: l10n.savedPlacesDemoEmptyMessage,
              actionLabel: l10n.searchClearFilters,
              onAction: _clearFilters,
            )
          else ...[
            Semantics(
              label: l10n.savedPlacesCountSemantic(results.length),
              child: Text(
                l10n.savedPlacesCount(results.length),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _SavedPlaceResults(
              results: results,
              onOpen: _openPlace,
              onAddToTrip: _addToTrip,
              onHotel: _openHotelAvailability,
              onEditNote: _editNote,
              onManageCollections: _manageCollectionsForPlace,
              onRemove: _confirmRemove,
            ),
          ],
        ],
      );

  void _clearFilters() {
    setState(() {
      search.clear();
      selectedCategory = null;
      sort = SavedPlaceSort.newest;
    });
  }

  void _openPlace(ResolvedSavedPlace result) {
    final place = result.place;
    if (place == null) {
      _showMissingMessage();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlaceDetailScreen(place: place)),
    );
  }

  void _addToTrip(ResolvedSavedPlace result) {
    final place = result.place;
    if (place == null) {
      _showMissingMessage();
      return;
    }
    showAddToTripSheet(context, place);
  }

  void _openHotelAvailability(ResolvedSavedPlace result) {
    final place = result.place;
    if (place == null) {
      _showMissingMessage();
      return;
    }
    final app = AppScope.of(context);
    final today = app.now();
    final upcoming = _nextTrip(app.trips, today);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HotelRoomSelectionScreen(
          hotel: place,
          initialCriteria: defaultHotelCriteria(today: today, trip: upcoming)
              .copyWith(destination: place.city),
          today: today,
        ),
      ),
    );
  }

  Future<void> _confirmRemove(ResolvedSavedPlace result) async {
    final l10n = AppLocalizations.of(context)!;
    final placeName = result.place?.name ?? l10n.savedPlacesMissingTitle;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.savedPlacesRemoveConfirmTitle),
        content: Text(l10n.savedPlacesRemoveConfirmMessage(placeName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.profileCancel),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.bookmark_remove_rounded),
            label: Text(l10n.savedPlacesRemoveConfirmAction),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final app = AppScope.of(context);
    final outcome = app.removeSavedPlace(result.record.placeId);
    final message = switch (outcome) {
      SavedPlaceActionResult.success => l10n.savedPlacesRemovedPlace(placeName),
      SavedPlaceActionResult.unavailable => l10n.savedPlacesRealEmptyMessage,
      SavedPlaceActionResult.forbidden =>
        l10n.savedPlacesActionForbiddenMessage,
      SavedPlaceActionResult.notFound ||
      SavedPlaceActionResult.duplicate =>
        l10n.savedPlacesMissingMessage,
      SavedPlaceActionResult.invalidNote => l10n.savedPlacesNoteTooLongMessage,
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _editNote(ResolvedSavedPlace result) async {
    final l10n = AppLocalizations.of(context)!;
    final place = result.place;
    if (place == null) {
      _showMissingMessage();
      return;
    }
    final updated = await showDialog<String>(
      context: context,
      builder: (_) => _SavedPlaceNoteDialog(
        placeName: place.name,
        initialNote: result.record.note,
      ),
    );
    if (!mounted || updated == null) return;
    final app = AppScope.of(context);
    final outcome = app.updateSavedPlaceNote(result.record.placeId, updated);
    final message = switch (outcome) {
      SavedPlaceActionResult.success =>
        l10n.savedPlacesNoteSavedMessage(place.name),
      SavedPlaceActionResult.unavailable => l10n.savedPlacesRealEmptyMessage,
      SavedPlaceActionResult.forbidden =>
        l10n.savedPlacesActionForbiddenMessage,
      SavedPlaceActionResult.notFound ||
      SavedPlaceActionResult.duplicate =>
        l10n.savedPlacesMissingMessage,
      SavedPlaceActionResult.invalidNote => l10n.savedPlacesNoteTooLongMessage,
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _editCollection({SavedCollectionRecord? collection}) async {
    final l10n = AppLocalizations.of(context)!;
    final draft = await showDialog<_SavedCollectionDraft>(
      context: context,
      builder: (_) => _SavedCollectionDialog(
        editing: collection != null,
        initialName: collection?.name,
        initialDescription: collection?.description,
        initialCoverImageUrl: collection?.coverImageUrl,
        initialPrivateCollection: collection?.privateCollection ?? true,
      ),
    );
    if (!mounted || draft == null) return;
    final app = AppScope.of(context);
    final outcome = collection == null
        ? app.createSavedCollection(
            name: draft.name,
            description: draft.description,
            coverImageUrl: draft.coverImageUrl,
            privateCollection: draft.privateCollection,
          )
        : app.updateSavedCollection(
            collectionId: collection.id,
            name: draft.name,
            description: draft.description,
            coverImageUrl: draft.coverImageUrl,
            privateCollection: draft.privateCollection,
          );
    if (outcome == SavedCollectionActionResult.success) {
      setState(() {
        selectedTab = _SavedPlacesTab.collections;
        if (collection == null) selectedCollectionId = null;
      });
    }
    final message = outcome == SavedCollectionActionResult.success
        ? collection == null
            ? l10n.savedPlacesCollectionCreatedMessage(draft.name)
            : l10n.savedPlacesCollectionUpdatedMessage(draft.name)
        : _collectionMessage(outcome);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmDeleteCollection(
    SavedCollectionRecord collection,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.savedPlacesCollectionDeleteTitle(collection.name)),
        content: Text(l10n.savedPlacesCollectionDeleteMessage(collection.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.profileCancel),
          ),
          FilledButton.icon(
            key: Key('saved-collection-delete-confirm-${collection.id}'),
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text(l10n.savedPlacesCollectionDeleteAction),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final app = AppScope.of(context);
    final outcome = app.deleteSavedCollection(collection.id);
    if (outcome == SavedCollectionActionResult.success &&
        selectedCollectionId == collection.id) {
      setState(() => selectedCollectionId = null);
    }
    final message = outcome == SavedCollectionActionResult.success
        ? l10n.savedPlacesCollectionDeletedMessage(collection.name)
        : _collectionMessage(outcome);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _openCollectionPlace(ResolvedCollectionPlace result) {
    final place = result.place;
    if (place == null) {
      _showMissingMessage();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlaceDetailScreen(place: place)),
    );
  }

  void _addCollectionPlaceToTrip(ResolvedCollectionPlace result) {
    final place = result.place;
    if (place == null) {
      _showMissingMessage();
      return;
    }
    showAddToTripSheet(context, place);
  }

  void _removeCollectionPlace(
    SavedCollectionRecord collection,
    ResolvedCollectionPlace result,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final placeName = result.place?.name ?? l10n.savedPlacesMissingTitle;
    final app = AppScope.of(context);
    final outcome = app.removePlaceFromCollection(
      collectionId: collection.id,
      placeId: result.record.placeId,
    );
    final message = outcome == SavedCollectionActionResult.success
        ? l10n.savedPlacesCollectionRemovedPlaceMessage(
            placeName,
            collection.name,
          )
        : _collectionMessage(outcome, placeName: placeName);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addSavedPlaceToCollection(
    SavedCollectionRecord collection,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final app = AppScope.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final savedPlaces = app.savedPlaceResults(includeMissing: false);
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg + MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.savedPlacesCollectionAddSavedTitle(collection.name),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.savedPlacesCollectionAddSavedMessage,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (savedPlaces.isEmpty)
                      OceanEmptyState(
                        title: l10n.savedPlacesEmptyTitle,
                        message: l10n.savedPlacesEmptyMessage,
                      )
                    else
                      for (final result in savedPlaces)
                        if (result.place case final place?)
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: _CollectionMembershipRow(
                              place: place,
                              collectionId: collection.id,
                              collectionName: collection.name,
                              inCollection: app.isPlaceInCollection(
                                collectionId: collection.id,
                                placeId: place.id,
                              ),
                              onToggle: () {
                                final inCollection = app.isPlaceInCollection(
                                  collectionId: collection.id,
                                  placeId: place.id,
                                );
                                final outcome = inCollection
                                    ? app.removePlaceFromCollection(
                                        collectionId: collection.id,
                                        placeId: place.id,
                                      )
                                    : app.addPlaceToCollection(
                                        collectionId: collection.id,
                                        placeId: place.id,
                                      );
                                setSheetState(() {});
                                _showCollectionSnackForMembership(
                                  outcome: outcome,
                                  placeName: place.name,
                                  collectionName: collection.name,
                                  added: !inCollection,
                                );
                              },
                            ),
                          ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _manageCollectionsForPlace(ResolvedSavedPlace result) async {
    final l10n = AppLocalizations.of(context)!;
    final place = result.place;
    if (place == null) {
      _showMissingMessage();
      return;
    }
    final app = AppScope.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final collections = app.visibleSavedCollections;
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg + MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.savedPlacesManageCollectionsTitle(place.name),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.savedPlacesManageCollectionsMessage,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (collections.isEmpty)
                      OceanEmptyState(
                        title: l10n.savedPlacesCollectionsEmptyTitle,
                        message: l10n.savedPlacesCollectionsEmptyMessage,
                        actionLabel: l10n.savedPlacesCollectionCreateAction,
                        onAction: () async {
                          Navigator.pop(sheetContext);
                          await _editCollection();
                        },
                      )
                    else ...[
                      for (final collection in collections)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _CollectionMembershipRow(
                            place: place,
                            collectionId: collection.id,
                            collectionName: collection.name,
                            inCollection: app.isPlaceInCollection(
                              collectionId: collection.id,
                              placeId: place.id,
                            ),
                            onToggle: () {
                              final inCollection = app.isPlaceInCollection(
                                collectionId: collection.id,
                                placeId: place.id,
                              );
                              final outcome = inCollection
                                  ? app.removePlaceFromCollection(
                                      collectionId: collection.id,
                                      placeId: place.id,
                                    )
                                  : app.addPlaceToCollection(
                                      collectionId: collection.id,
                                      placeId: place.id,
                                    );
                              setSheetState(() {});
                              _showCollectionSnackForMembership(
                                outcome: outcome,
                                placeName: place.name,
                                collectionName: collection.name,
                                added: !inCollection,
                              );
                            },
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OceanSecondaryButton(
                          key: const Key('saved-collection-inline-create'),
                          label: l10n.savedPlacesCollectionCreateAction,
                          icon: Icons.create_new_folder_rounded,
                          fullWidth: false,
                          semanticLabel:
                              l10n.savedPlacesCollectionCreateSemantic,
                          onPressed: () async {
                            Navigator.pop(sheetContext);
                            await _editCollection();
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCollectionSnackForMembership({
    required SavedCollectionActionResult outcome,
    required String placeName,
    required String collectionName,
    required bool added,
  }) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final message = outcome == SavedCollectionActionResult.success
        ? added
            ? l10n.savedPlacesCollectionAddedPlaceMessage(
                placeName,
                collectionName,
              )
            : l10n.savedPlacesCollectionRemovedPlaceMessage(
                placeName,
                collectionName,
              )
        : _collectionMessage(
            outcome,
            placeName: placeName,
            collectionName: collectionName,
          );
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _collectionMessage(
    SavedCollectionActionResult outcome, {
    String? placeName,
    String? collectionName,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return switch (outcome) {
      SavedCollectionActionResult.success =>
        l10n.savedPlacesCollectionSavedMessage,
      SavedCollectionActionResult.unavailable =>
        l10n.savedPlacesCollectionsRealUnavailableMessage,
      SavedCollectionActionResult.invalidName =>
        l10n.savedPlacesCollectionInvalidNameMessage(
          SavedCollectionRecord.maxNameLength,
        ),
      SavedCollectionActionResult.invalidDescription =>
        l10n.savedPlacesCollectionInvalidDescriptionMessage(
          SavedCollectionRecord.maxDescriptionLength,
        ),
      SavedCollectionActionResult.invalidCover =>
        l10n.savedPlacesCollectionInvalidCoverMessage(
          SavedCollectionRecord.maxCoverImageUrlLength,
        ),
      SavedCollectionActionResult.collectionLimitReached =>
        l10n.savedPlacesCollectionLimitMessage(
          SavedCollectionRecord.maxCollectionsPerUser,
        ),
      SavedCollectionActionResult.collectionNotFound =>
        l10n.savedPlacesCollectionNotFoundMessage,
      SavedCollectionActionResult.placeNotFound =>
        l10n.savedPlacesCollectionPlaceNotFoundMessage,
      SavedCollectionActionResult.duplicateItem =>
        l10n.savedPlacesCollectionDuplicatePlaceMessage(
          placeName ?? l10n.savedPlacesMissingTitle,
          collectionName ?? l10n.savedPlacesCollectionsTitle,
        ),
      SavedCollectionActionResult.itemNotFound =>
        l10n.savedPlacesCollectionItemNotFoundMessage,
      SavedCollectionActionResult.itemLimitReached =>
        l10n.savedPlacesCollectionItemLimitMessage(
          SavedCollectionPlaceRecord.maxPlacesPerCollection,
        ),
      SavedCollectionActionResult.network =>
        l10n.savedPlacesCollectionNetworkErrorMessage,
      SavedCollectionActionResult.serverError =>
        l10n.savedPlacesCollectionServerErrorMessage,
      SavedCollectionActionResult.unauthenticated =>
        l10n.savedPlacesCollectionUnauthenticatedMessage,
    };
  }

  void _showMissingMessage() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.savedPlacesMissingMessage)),
    );
  }

  Trip? _nextTrip(List<Trip> trips, DateTime today) {
    final current = hotelDateOnly(today);
    final candidates = trips
        .where((trip) => !hotelDateOnly(trip.endDate).isBefore(current))
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    return candidates.isEmpty ? null : candidates.first;
  }

  // ── Real Mode Saved Collections (UI-17) ───────────────────────────────────

  Widget _buildRealCollections(AppState app, AppLocalizations l10n) {
    if (selectedRealCollectionId != null) {
      return _buildRealCollectionDetail(app, l10n, selectedRealCollectionId!);
    }
    if (app.realSavedCollectionsLoading && app.realSavedCollections.isEmpty) {
      return const OceanLoadingState();
    }
    if (app.realSavedCollectionsError != null &&
        app.realSavedCollections.isEmpty) {
      return OceanRecoverableErrorState(
        message: _collectionErrorMessage(l10n, app.realSavedCollectionsError!),
        onReload: () => _loadRealCollections(refresh: true),
      );
    }
    return _RealCollectionOverview(
      collections: app.realSavedCollections,
      onCreate: _createRealCollection,
      onOpen: (collection) => _openRealCollection(collection.id),
      onEdit: _editRealCollection,
      onDelete: _confirmDeleteRealCollection,
    );
  }

  Widget _buildRealCollectionDetail(
    AppState app,
    AppLocalizations l10n,
    int collectionId,
  ) {
    final detail = app.realSelectedCollectionDetail;
    final hasDetail = detail != null && detail.id == collectionId;
    if (app.realCollectionDetailLoading && !hasDetail) {
      return const OceanLoadingState();
    }
    if (!hasDetail) {
      final error = app.realCollectionDetailError;
      if (error == SavedCollectionActionResult.collectionNotFound) {
        return OceanEmptyState(
          title: l10n.savedPlacesCollectionNotFoundMessage,
          message: l10n.savedPlacesCollectionNotFoundMessage,
          actionLabel: l10n.savedPlacesCollectionBackAction,
          onAction: () => setState(() => selectedRealCollectionId = null),
        );
      }
      return OceanRecoverableErrorState(
        message: error != null ? _collectionErrorMessage(l10n, error) : null,
        onReload: () => _loadRealCollectionDetail(collectionId, refresh: true),
      );
    }
    return _RealCollectionDetailView(
      collection: detail,
      onBack: () => setState(() => selectedRealCollectionId = null),
      onEdit: () => _editRealCollection(detail.toSummary()),
      onDelete: () => _confirmDeleteRealCollection(detail.toSummary()),
      onAddSavedPlace: _showDeferredRealAddPlace,
      onRemove: (place) => _removeRealCollectionPlace(detail.id, place),
    );
  }

  Future<void> _loadRealCollections({bool refresh = false}) async {
    final app = AppScope.of(context);
    final outcome = await app.loadRealSavedCollections(refresh: refresh);
    if (mounted && outcome == SavedCollectionActionResult.unauthenticated) {
      _showRealCollectionsReauth();
    }
  }

  Future<void> _loadRealCollectionDetail(
    int collectionId, {
    bool refresh = false,
  }) async {
    final app = AppScope.of(context);
    final outcome = await app.loadRealCollectionDetail(
      collectionId,
      refresh: refresh,
    );
    if (mounted && outcome == SavedCollectionActionResult.unauthenticated) {
      _showRealCollectionsReauth();
    }
  }

  void _openRealCollection(int collectionId) {
    setState(() => selectedRealCollectionId = collectionId);
    _loadRealCollectionDetail(collectionId);
  }

  void _showRealCollectionsReauth() {
    showOceanSessionExpiredSheet(
      context,
      onLogin: () {
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      },
      onReturnHome: () => Navigator.of(context).pop(),
    );
  }

  bool _recoverableRealOutcome(SavedCollectionActionResult outcome) =>
      outcome == SavedCollectionActionResult.invalidName ||
      outcome == SavedCollectionActionResult.invalidDescription ||
      outcome == SavedCollectionActionResult.invalidCover ||
      outcome == SavedCollectionActionResult.collectionLimitReached ||
      outcome == SavedCollectionActionResult.network ||
      outcome == SavedCollectionActionResult.serverError;

  Future<void> _createRealCollection() async {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    _SavedCollectionDraft? draft;
    while (mounted) {
      draft = await showDialog<_SavedCollectionDraft>(
        context: context,
        builder: (_) => _SavedCollectionDialog(
          editing: false,
          initialName: draft?.name,
          initialDescription: draft?.description,
          initialCoverImageUrl: draft?.coverImageUrl,
          initialPrivateCollection: draft?.privateCollection ?? true,
        ),
      );
      if (draft == null || !mounted) return;
      final outcome = await app.createRealSavedCollection(
        name: draft.name,
        description: draft.description,
        coverImageUrl: draft.coverImageUrl,
        privateCollection: draft.privateCollection,
      );
      if (!mounted) return;
      if (outcome == SavedCollectionActionResult.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.savedPlacesCollectionCreatedMessage(draft.name)),
          ),
        );
        return;
      }
      if (outcome == SavedCollectionActionResult.unauthenticated) {
        _showRealCollectionsReauth();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_realCollectionActionMessage(l10n, outcome))),
      );
      if (!_recoverableRealOutcome(outcome)) return;
    }
  }

  Future<void> _editRealCollection(CollectionSummaryRecord collection) async {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    var seed = collection;
    while (mounted) {
      final draft = await showDialog<_SavedCollectionDraft>(
        context: context,
        builder: (_) => _SavedCollectionDialog(
          editing: true,
          initialName: seed.name,
          initialDescription: seed.description,
          initialCoverImageUrl: seed.coverImageUrl,
          initialPrivateCollection: seed.privateCollection,
        ),
      );
      if (draft == null || !mounted) return;
      seed = CollectionSummaryRecord(
        id: collection.id,
        name: draft.name,
        description: draft.description,
        coverImageUrl: draft.coverImageUrl,
        privateCollection: draft.privateCollection,
        sortOrder: collection.sortOrder,
        placeCount: collection.placeCount,
        createdAt: collection.createdAt,
        updatedAt: collection.updatedAt,
      );
      final outcome = await app.updateRealSavedCollection(
        collectionId: collection.id,
        name: draft.name,
        description: draft.description,
        coverImageUrl: draft.coverImageUrl,
        privateCollection: draft.privateCollection,
        sortOrder: collection.sortOrder,
      );
      if (!mounted) return;
      if (outcome == SavedCollectionActionResult.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.savedPlacesCollectionUpdatedMessage(draft.name)),
          ),
        );
        return;
      }
      if (outcome == SavedCollectionActionResult.unauthenticated) {
        _showRealCollectionsReauth();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_realCollectionActionMessage(l10n, outcome))),
      );
      if (!_recoverableRealOutcome(outcome)) return;
    }
  }

  Future<void> _confirmDeleteRealCollection(
    CollectionSummaryRecord collection,
  ) async {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.savedPlacesCollectionDeleteTitle(collection.name)),
        content: Text(l10n.savedPlacesCollectionDeleteMessage(collection.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.profileCancel),
          ),
          FilledButton.icon(
            key: Key('real-collection-delete-confirm-${collection.id}'),
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text(l10n.savedPlacesCollectionDeleteAction),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final outcome = await app.deleteRealSavedCollection(collection.id);
    if (!mounted) return;
    if (outcome == SavedCollectionActionResult.success) {
      if (selectedRealCollectionId == collection.id) {
        setState(() => selectedRealCollectionId = null);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(l10n.savedPlacesCollectionDeletedMessage(collection.name)),
        ),
      );
      return;
    }
    if (outcome == SavedCollectionActionResult.unauthenticated) {
      _showRealCollectionsReauth();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_realCollectionActionMessage(l10n, outcome))),
    );
  }

  Future<void> _removeRealCollectionPlace(
    int collectionId,
    CollectionPlaceRecord place,
  ) async {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final collectionName = app.realSelectedCollectionDetail?.name ?? '';
    final outcome = await app.removeRealCollectionPlace(
      collectionId: collectionId,
      placeId: place.placeId,
    );
    if (!mounted) return;
    if (outcome == SavedCollectionActionResult.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.savedPlacesCollectionRemovedPlaceMessage(
              place.name,
              collectionName,
            ),
          ),
        ),
      );
      return;
    }
    if (outcome == SavedCollectionActionResult.unauthenticated) {
      _showRealCollectionsReauth();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_realCollectionActionMessage(l10n, outcome))),
    );
  }

  void _showDeferredRealAddPlace() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: OceanEmptyState(
            title: l10n.savedPlacesCollectionAddPlaceDeferredTitle,
            message: l10n.savedPlacesCollectionAddPlaceDeferredMessage,
          ),
        ),
      ),
    );
  }

  String _collectionErrorMessage(
    AppLocalizations l10n,
    SavedCollectionActionResult outcome,
  ) {
    switch (outcome) {
      case SavedCollectionActionResult.network:
        return l10n.savedPlacesCollectionNetworkErrorMessage;
      case SavedCollectionActionResult.serverError:
        return l10n.savedPlacesCollectionServerErrorMessage;
      case SavedCollectionActionResult.unauthenticated:
        return l10n.savedPlacesCollectionUnauthenticatedMessage;
      case SavedCollectionActionResult.collectionNotFound:
        return l10n.savedPlacesCollectionNotFoundMessage;
      default:
        return l10n.savedPlacesCollectionServerErrorMessage;
    }
  }

  String _realCollectionActionMessage(
    AppLocalizations l10n,
    SavedCollectionActionResult outcome,
  ) {
    switch (outcome) {
      case SavedCollectionActionResult.invalidName:
        return l10n.savedPlacesCollectionInvalidNameMessage(
          SavedCollectionRecord.maxNameLength,
        );
      case SavedCollectionActionResult.invalidDescription:
        return l10n.savedPlacesCollectionInvalidDescriptionMessage(
          SavedCollectionRecord.maxDescriptionLength,
        );
      case SavedCollectionActionResult.invalidCover:
        return l10n.savedPlacesCollectionInvalidCoverMessage(
          SavedCollectionRecord.maxCoverImageUrlLength,
        );
      case SavedCollectionActionResult.collectionLimitReached:
        return l10n.savedPlacesCollectionLimitMessage(
          SavedCollectionRecord.maxCollectionsPerUser,
        );
      case SavedCollectionActionResult.collectionNotFound:
        return l10n.savedPlacesCollectionNotFoundMessage;
      case SavedCollectionActionResult.itemNotFound:
        return l10n.savedPlacesCollectionItemNotFoundMessage;
      case SavedCollectionActionResult.network:
        return l10n.savedPlacesCollectionNetworkErrorMessage;
      case SavedCollectionActionResult.serverError:
        return l10n.savedPlacesCollectionServerErrorMessage;
      case SavedCollectionActionResult.success:
        return l10n.savedPlacesCollectionSavedMessage;
      default:
        return l10n.savedPlacesCollectionServerErrorMessage;
    }
  }
}

class _SavedCollectionDraft {
  final String name;
  final String? description;
  final String? coverImageUrl;
  final bool privateCollection;

  const _SavedCollectionDraft({
    required this.name,
    required this.description,
    required this.coverImageUrl,
    required this.privateCollection,
  });
}

class _SavedCollectionDialog extends StatefulWidget {
  final bool editing;
  final String? initialName;
  final String? initialDescription;
  final String? initialCoverImageUrl;
  final bool initialPrivateCollection;

  const _SavedCollectionDialog({
    required this.editing,
    this.initialName,
    this.initialDescription,
    this.initialCoverImageUrl,
    this.initialPrivateCollection = true,
  });

  @override
  State<_SavedCollectionDialog> createState() => _SavedCollectionDialogState();
}

class _SavedCollectionDialogState extends State<_SavedCollectionDialog> {
  late final TextEditingController nameController;
  late final TextEditingController descriptionController;
  late final TextEditingController coverController;
  late bool privateCollection;
  String? nameError;
  String? descriptionError;
  String? coverError;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.initialName ?? '');
    descriptionController =
        TextEditingController(text: widget.initialDescription ?? '');
    coverController =
        TextEditingController(text: widget.initialCoverImageUrl ?? '');
    privateCollection = widget.initialPrivateCollection;
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    coverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final editing = widget.editing;
    return AlertDialog(
      title: Text(
        editing
            ? l10n.savedPlacesCollectionEditTitle
            : l10n.savedPlacesCollectionCreateTitle,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('saved-collection-name-field'),
              controller: nameController,
              autofocus: true,
              maxLength: SavedCollectionRecord.maxNameLength,
              decoration: InputDecoration(
                labelText: l10n.savedPlacesCollectionNameLabel,
                helperText: l10n.savedPlacesCollectionNameHelper(
                  SavedCollectionRecord.maxNameLength,
                ),
                errorText: nameError,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              key: const Key('saved-collection-description-field'),
              controller: descriptionController,
              maxLength: SavedCollectionRecord.maxDescriptionLength,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.savedPlacesCollectionDescriptionLabel,
                helperText: l10n.savedPlacesCollectionDescriptionHelper(
                  SavedCollectionRecord.maxDescriptionLength,
                ),
                errorText: descriptionError,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              key: const Key('saved-collection-cover-field'),
              controller: coverController,
              maxLength: SavedCollectionRecord.maxCoverImageUrlLength,
              decoration: InputDecoration(
                labelText: l10n.savedPlacesCollectionCoverLabel,
                helperText: l10n.savedPlacesCollectionCoverHelper(
                  SavedCollectionRecord.maxCoverImageUrlLength,
                ),
                errorText: coverError,
              ),
            ),
            SwitchListTile.adaptive(
              key: const Key('saved-collection-private-switch'),
              value: privateCollection,
              onChanged: (value) => setState(() => privateCollection = value),
              title: Text(l10n.savedPlacesCollectionPrivateLabel),
              subtitle: Text(l10n.savedPlacesCollectionPrivateHelper),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.profileCancel),
        ),
        FilledButton.icon(
          key: const Key('saved-collection-save'),
          onPressed: _submit,
          icon: Icon(
              editing ? Icons.save_rounded : Icons.create_new_folder_rounded),
          label: Text(
            editing
                ? l10n.savedPlacesCollectionSaveAction
                : l10n.savedPlacesCollectionCreateAction,
          ),
        ),
      ],
    );
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final name = nameController.text;
    final description = descriptionController.text;
    final cover = coverController.text;
    final nextNameError =
        name.trim().isEmpty || name.length > SavedCollectionRecord.maxNameLength
            ? l10n.savedPlacesCollectionInvalidNameMessage(
                SavedCollectionRecord.maxNameLength,
              )
            : null;
    final nextDescriptionError =
        description.length > SavedCollectionRecord.maxDescriptionLength
            ? l10n.savedPlacesCollectionInvalidDescriptionMessage(
                SavedCollectionRecord.maxDescriptionLength,
              )
            : null;
    final nextCoverError =
        cover.length > SavedCollectionRecord.maxCoverImageUrlLength
            ? l10n.savedPlacesCollectionInvalidCoverMessage(
                SavedCollectionRecord.maxCoverImageUrlLength,
              )
            : null;
    if (nextNameError != null ||
        nextDescriptionError != null ||
        nextCoverError != null) {
      setState(() {
        nameError = nextNameError;
        descriptionError = nextDescriptionError;
        coverError = nextCoverError;
      });
      return;
    }
    Navigator.pop(
      context,
      _SavedCollectionDraft(
        name: name,
        description: description.isEmpty ? null : description,
        coverImageUrl: cover.isEmpty ? null : cover,
        privateCollection: privateCollection,
      ),
    );
  }
}

class _SavedPlaceNoteDialog extends StatefulWidget {
  final String placeName;
  final String? initialNote;

  const _SavedPlaceNoteDialog({
    required this.placeName,
    required this.initialNote,
  });

  @override
  State<_SavedPlaceNoteDialog> createState() => _SavedPlaceNoteDialogState();
}

class _SavedPlaceNoteDialogState extends State<_SavedPlaceNoteDialog> {
  late final TextEditingController controller;
  String? errorText;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialNote ?? '');
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.savedPlacesEditNoteTitle(widget.placeName)),
      content: TextField(
        key: const Key('saved-place-note-field'),
        controller: controller,
        autofocus: true,
        maxLines: 4,
        decoration: InputDecoration(
          labelText: l10n.savedPlacesNoteFieldLabel,
          helperText: l10n.savedPlacesNoteFieldHelper(
            SavedPlaceRecord.maxNoteLength,
          ),
          errorText: errorText,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.profileCancel),
        ),
        FilledButton.icon(
          key: const Key('saved-place-note-save'),
          onPressed: () {
            if (controller.text.length > SavedPlaceRecord.maxNoteLength) {
              setState(() => errorText = l10n.savedPlacesNoteTooLongMessage);
              return;
            }
            Navigator.pop(context, controller.text);
          },
          icon: const Icon(Icons.edit_note_rounded),
          label: Text(l10n.savedPlacesNoteSaveAction),
        ),
      ],
    );
  }
}

class _SavedPlacesHeader extends StatelessWidget {
  final int count;
  final int collectionCount;

  const _SavedPlacesHeader({
    required this.count,
    required this.collectionCount,
  });

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassCard(
      semanticLabel: l10n.savedPlacesTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OceanStatusPill(
                label:
                    app.demoMode ? l10n.demoModeLabel : l10n.profileRealStatus,
                icon: app.demoMode
                    ? Icons.science_rounded
                    : Icons.cloud_done_rounded,
              ),
              OceanStatusPill(
                label: l10n.savedPlacesCount(count),
                icon: Icons.bookmarks_rounded,
                color: AppColors.turquoise600,
                semanticLabel: l10n.savedPlacesCountSemantic(count),
              ),
              OceanStatusPill(
                label: l10n.savedPlacesCollectionCount(collectionCount),
                icon: Icons.folder_copy_rounded,
                color: AppColors.success,
                semanticLabel:
                    l10n.savedPlacesCollectionCountSemantic(collectionCount),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.savedPlacesSubtitle,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            app.demoMode
                ? l10n.savedPlacesDemoBoundary
                : l10n.savedPlacesRealEmptyMessage,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _SavedPlaceControls extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final SavedPlaceSort sort;
  final ValueChanged<String?> onCategory;
  final ValueChanged<SavedPlaceSort> onSort;

  const _SavedPlaceControls({
    required this.categories,
    required this.selectedCategory,
    required this.sort,
    required this.onCategory,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          label: l10n.savedPlacesFilterSemantic,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: ChoiceChip(
                    label: Text(l10n.savedPlacesAllFilter),
                    selected: selectedCategory == null,
                    onSelected: (_) => onCategory(null),
                  ),
                ),
                for (final category in categories)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: selectedCategory == category,
                      onSelected: (_) => onCategory(category),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            ChoiceChip(
              label: Text(l10n.savedPlacesSortNewest),
              selected: sort == SavedPlaceSort.newest,
              onSelected: (_) => onSort(SavedPlaceSort.newest),
            ),
            ChoiceChip(
              label: Text(l10n.savedPlacesSortName),
              selected: sort == SavedPlaceSort.name,
              onSelected: (_) => onSort(SavedPlaceSort.name),
            ),
          ],
        ),
      ],
    );
  }
}

class _SavedPlacesTabs extends StatelessWidget {
  final _SavedPlacesTab selected;
  final int savedCount;
  final int collectionCount;
  final ValueChanged<_SavedPlacesTab> onSelected;

  const _SavedPlacesTabs({
    required this.selected,
    required this.savedCount,
    required this.collectionCount,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      container: true,
      label: l10n.savedPlacesSectionTabsSemantic,
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          ChoiceChip(
            key: const Key('saved-places-tab-all'),
            label: Text(l10n.savedPlacesAllSavedTab(savedCount)),
            selected: selected == _SavedPlacesTab.allSaved,
            onSelected: (_) => onSelected(_SavedPlacesTab.allSaved),
          ),
          ChoiceChip(
            key: const Key('saved-places-tab-collections'),
            label: Text(l10n.savedPlacesCollectionsTab(collectionCount)),
            selected: selected == _SavedPlacesTab.collections,
            onSelected: (_) => onSelected(_SavedPlacesTab.collections),
          ),
        ],
      ),
    );
  }
}

class _WishlistBoundary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassSurface(
      blur: 0,
      color: AppColors.paleCyan,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.folder_copy_outlined, color: AppColors.ocean),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.savedPlacesWishlistBoundaryTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  l10n.savedPlacesWishlistBoundaryMessage,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionOverview extends StatelessWidget {
  final List<SavedCollectionRecord> collections;
  final int Function(String collectionId) itemCountFor;
  final VoidCallback onCreate;
  final ValueChanged<SavedCollectionRecord> onOpen;
  final ValueChanged<SavedCollectionRecord> onEdit;
  final ValueChanged<SavedCollectionRecord> onDelete;

  const _CollectionOverview({
    required this.collections,
    required this.itemCountFor,
    required this.onCreate,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OceanGlassSurface(
          blur: 0,
          color: AppColors.paleCyan,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;
              final text = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.savedPlacesCollectionsTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    l10n.savedPlacesCollectionsBoundaryMessage,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              );
              final action = OceanPrimaryButton(
                key: const Key('saved-collection-create'),
                label: l10n.savedPlacesCollectionCreateAction,
                icon: Icons.create_new_folder_rounded,
                fullWidth: compact,
                semanticLabel: l10n.savedPlacesCollectionCreateSemantic,
                onPressed: onCreate,
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    text,
                    const SizedBox(height: AppSpacing.md),
                    action,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: text),
                  const SizedBox(width: AppSpacing.md),
                  action,
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (collections.isEmpty)
          OceanEmptyState(
            title: l10n.savedPlacesCollectionsEmptyTitle,
            message: l10n.savedPlacesCollectionsEmptyMessage,
            actionLabel: l10n.savedPlacesCollectionCreateAction,
            onAction: onCreate,
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= AppBreakpoints.tablet;
              if (wide) {
                return Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    for (final collection in collections)
                      SizedBox(
                        width: (constraints.maxWidth - AppSpacing.md) / 2,
                        child: _CollectionCard(
                          collection: collection,
                          itemCount: itemCountFor(collection.id),
                          onOpen: () => onOpen(collection),
                          onEdit: () => onEdit(collection),
                          onDelete: () => onDelete(collection),
                        ),
                      ),
                  ],
                );
              }
              return Column(
                children: [
                  for (final collection in collections)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _CollectionCard(
                        collection: collection,
                        itemCount: itemCountFor(collection.id),
                        onOpen: () => onOpen(collection),
                        onEdit: () => onEdit(collection),
                        onDelete: () => onDelete(collection),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final SavedCollectionRecord collection;
  final int itemCount;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CollectionCard({
    required this.collection,
    required this.itemCount,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final updated = DateFormat.yMMMd(Localizations.localeOf(context).toString())
        .format(collection.updatedAt.toLocal());
    return OceanGlassCard(
      onTap: onOpen,
      semanticLabel:
          l10n.savedPlacesCollectionCardSemantic(collection.name, itemCount),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: AppSpacing.minTouchTarget,
                height: AppSpacing.minTouchTarget,
                decoration: BoxDecoration(
                  color: AppColors.paleCyan,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: const Icon(
                  Icons.folder_copy_rounded,
                  color: AppColors.ocean,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collection.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if ((collection.description ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        collection.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              OceanStatusPill(
                label: l10n.savedPlacesCollectionItemCount(itemCount),
                icon: Icons.place_outlined,
                color: AppColors.ocean,
                semanticLabel:
                    l10n.savedPlacesCollectionItemCountSemantic(itemCount),
              ),
              OceanStatusPill(
                label: collection.privateCollection
                    ? l10n.savedPlacesCollectionPrivateLabel
                    : l10n.savedPlacesCollectionVisibleLabel,
                icon: collection.privateCollection
                    ? Icons.lock_outline_rounded
                    : Icons.visibility_outlined,
                color: AppColors.turquoise600,
              ),
              OceanStatusPill(
                label: l10n.savedPlacesCollectionUpdated(updated),
                icon: Icons.update_rounded,
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              OceanPrimaryButton(
                key: Key('saved-collection-open-${collection.id}'),
                label: l10n.savedPlacesCollectionOpenAction,
                icon: Icons.folder_open_rounded,
                fullWidth: false,
                semanticLabel:
                    l10n.savedPlacesCollectionOpenSemantic(collection.name),
                onPressed: onOpen,
              ),
              OceanSecondaryButton(
                key: Key('saved-collection-edit-${collection.id}'),
                label: l10n.savedPlacesCollectionEditAction,
                icon: Icons.edit_rounded,
                fullWidth: false,
                semanticLabel:
                    l10n.savedPlacesCollectionEditSemantic(collection.name),
                onPressed: onEdit,
              ),
              IconButton(
                key: Key('saved-collection-delete-${collection.id}'),
                tooltip:
                    l10n.savedPlacesCollectionDeleteSemantic(collection.name),
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CollectionDetailView extends StatelessWidget {
  final SavedCollectionRecord collection;
  final List<ResolvedCollectionPlace> places;
  final int itemCount;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddSavedPlace;
  final ValueChanged<ResolvedCollectionPlace> onOpen;
  final ValueChanged<ResolvedCollectionPlace> onAddToTrip;
  final void Function(
    SavedCollectionRecord collection,
    ResolvedCollectionPlace result,
  ) onRemove;

  const _CollectionDetailView({
    required this.collection,
    required this.places,
    required this.itemCount,
    required this.onBack,
    required this.onEdit,
    required this.onDelete,
    required this.onAddSavedPlace,
    required this.onOpen,
    required this.onAddToTrip,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OceanGlassCard(
          semanticLabel: l10n.savedPlacesCollectionDetailSemantic(
            collection.name,
            itemCount,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OceanSecondaryButton(
                    key: const Key('saved-collection-back'),
                    label: l10n.savedPlacesCollectionBackAction,
                    icon: Icons.arrow_back_rounded,
                    fullWidth: false,
                    semanticLabel: l10n.savedPlacesCollectionBackSemantic,
                    onPressed: onBack,
                  ),
                  OceanSecondaryButton(
                    key: Key('saved-collection-detail-edit-${collection.id}'),
                    label: l10n.savedPlacesCollectionEditAction,
                    icon: Icons.edit_rounded,
                    fullWidth: false,
                    semanticLabel:
                        l10n.savedPlacesCollectionEditSemantic(collection.name),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    key: Key(
                      'saved-collection-detail-delete-${collection.id}',
                    ),
                    tooltip: l10n
                        .savedPlacesCollectionDeleteSemantic(collection.name),
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                collection.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if ((collection.description ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  collection.description!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  OceanStatusPill(
                    label: l10n.savedPlacesCollectionItemCount(itemCount),
                    icon: Icons.place_outlined,
                    color: AppColors.ocean,
                    semanticLabel:
                        l10n.savedPlacesCollectionItemCountSemantic(itemCount),
                  ),
                  OceanStatusPill(
                    label: collection.privateCollection
                        ? l10n.savedPlacesCollectionPrivateLabel
                        : l10n.savedPlacesCollectionVisibleLabel,
                    icon: collection.privateCollection
                        ? Icons.lock_outline_rounded
                        : Icons.visibility_outlined,
                    color: AppColors.turquoise600,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              OceanPrimaryButton(
                key: Key('saved-collection-add-saved-${collection.id}'),
                label: l10n.savedPlacesCollectionAddSavedAction,
                icon: Icons.add_location_alt_rounded,
                semanticLabel:
                    l10n.savedPlacesCollectionAddSavedSemantic(collection.name),
                onPressed: onAddSavedPlace,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (places.isEmpty)
          OceanEmptyState(
            title: l10n.savedPlacesCollectionEmptyTitle,
            message: l10n.savedPlacesCollectionEmptyMessage,
            actionLabel: l10n.savedPlacesCollectionAddSavedAction,
            onAction: onAddSavedPlace,
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= AppBreakpoints.tablet;
              if (wide) {
                return Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    for (final result in places)
                      SizedBox(
                        width: (constraints.maxWidth - AppSpacing.md) / 2,
                        child: _CollectionPlaceCard(
                          result: result,
                          onOpen: () => onOpen(result),
                          onAddToTrip: () => onAddToTrip(result),
                          onRemove: () => onRemove(collection, result),
                        ),
                      ),
                  ],
                );
              }
              return Column(
                children: [
                  for (final result in places)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _CollectionPlaceCard(
                        result: result,
                        onOpen: () => onOpen(result),
                        onAddToTrip: () => onAddToTrip(result),
                        onRemove: () => onRemove(collection, result),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _CollectionPlaceCard extends StatelessWidget {
  final ResolvedCollectionPlace result;
  final VoidCallback onOpen;
  final VoidCallback onAddToTrip;
  final VoidCallback onRemove;

  const _CollectionPlaceCard({
    required this.result,
    required this.onOpen,
    required this.onAddToTrip,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final place = result.place;
    if (place == null) {
      return _MissingCollectionPlaceCard(result: result, onRemove: onRemove);
    }
    final l10n = AppLocalizations.of(context)!;
    final added = DateFormat.yMMMd(Localizations.localeOf(context).toString())
        .format(result.record.addedAt.toLocal());
    return OceanGlassCard(
      onTap: onOpen,
      semanticLabel: l10n.savedPlacesCollectionPlaceSemantic(
        place.name,
        added,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PlaceImage(place: place, stacked: false),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    OceanStatusPill(
                      label: place.category,
                      icon: Icons.place_outlined,
                      color: AppColors.ocean,
                    ),
                    OceanStatusPill(
                      label: l10n.savedPlacesCollectionAddedOn(added),
                      icon: Icons.playlist_add_check_rounded,
                      color: AppColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${place.locationName} · ${place.city}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    OceanSecondaryButton(
                      key: Key('saved-collection-place-details-${place.id}'),
                      label: l10n.savedPlacesViewDetailsAction,
                      icon: Icons.info_outline_rounded,
                      fullWidth: false,
                      semanticLabel:
                          l10n.savedPlacesOpenDetailSemantic(place.name),
                      onPressed: onOpen,
                    ),
                    OceanSecondaryButton(
                      key: Key('saved-collection-place-add-trip-${place.id}'),
                      label: l10n.placeAddToTrip,
                      icon: Icons.add_location_alt_rounded,
                      fullWidth: false,
                      semanticLabel: l10n.placeAddToTripSemantic(place.name),
                      onPressed: onAddToTrip,
                    ),
                    OceanSecondaryButton(
                      key: Key('saved-collection-place-remove-${place.id}'),
                      label: l10n.savedPlacesCollectionRemovePlaceAction,
                      icon: Icons.playlist_remove_rounded,
                      fullWidth: false,
                      semanticLabel: l10n
                          .savedPlacesCollectionRemovePlaceSemantic(place.name),
                      onPressed: onRemove,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingCollectionPlaceCard extends StatelessWidget {
  final ResolvedCollectionPlace result;
  final VoidCallback onRemove;

  const _MissingCollectionPlaceCard({
    required this.result,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassCard(
      semanticLabel: l10n.savedPlacesCollectionStaleItemTitle,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppSpacing.minTouchTarget,
            height: AppSpacing.minTouchTarget,
            decoration: BoxDecoration(
              color: AppColors.paleCyan,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: const Icon(Icons.link_off_rounded, color: AppColors.ocean),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.savedPlacesCollectionStaleItemTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  l10n.savedPlacesCollectionStaleItemMessage(
                    result.record.placeId,
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            tooltip: l10n.savedPlacesCollectionRemoveStaleSemantic,
            onPressed: onRemove,
            icon: const Icon(Icons.playlist_remove_rounded),
          ),
        ],
      ),
    );
  }
}

class _RealCollectionOverview extends StatelessWidget {
  final List<CollectionSummaryRecord> collections;
  final VoidCallback onCreate;
  final ValueChanged<CollectionSummaryRecord> onOpen;
  final ValueChanged<CollectionSummaryRecord> onEdit;
  final ValueChanged<CollectionSummaryRecord> onDelete;

  const _RealCollectionOverview({
    required this.collections,
    required this.onCreate,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OceanGlassSurface(
          blur: 0,
          color: AppColors.paleCyan,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;
              final text = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.savedPlacesCollectionsTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    l10n.savedPlacesCollectionsBoundaryMessage,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              );
              final action = OceanPrimaryButton(
                key: const Key('real-collection-create'),
                label: l10n.savedPlacesCollectionCreateAction,
                icon: Icons.create_new_folder_rounded,
                fullWidth: compact,
                semanticLabel: l10n.savedPlacesCollectionCreateSemantic,
                onPressed: onCreate,
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    text,
                    const SizedBox(height: AppSpacing.md),
                    action,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: text),
                  const SizedBox(width: AppSpacing.md),
                  action,
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (collections.isEmpty)
          OceanEmptyState(
            title: l10n.savedPlacesCollectionsEmptyTitle,
            message: l10n.savedPlacesCollectionsEmptyMessage,
            actionLabel: l10n.savedPlacesCollectionCreateAction,
            onAction: onCreate,
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= AppBreakpoints.tablet;
              if (wide) {
                return Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    for (final collection in collections)
                      SizedBox(
                        width: (constraints.maxWidth - AppSpacing.md) / 2,
                        child: _RealCollectionCard(
                          collection: collection,
                          onOpen: () => onOpen(collection),
                          onEdit: () => onEdit(collection),
                          onDelete: () => onDelete(collection),
                        ),
                      ),
                  ],
                );
              }
              return Column(
                children: [
                  for (final collection in collections)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _RealCollectionCard(
                        collection: collection,
                        onOpen: () => onOpen(collection),
                        onEdit: () => onEdit(collection),
                        onDelete: () => onDelete(collection),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _RealCollectionCard extends StatelessWidget {
  final CollectionSummaryRecord collection;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RealCollectionCard({
    required this.collection,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final updated = DateFormat.yMMMd(Localizations.localeOf(context).toString())
        .format(collection.updatedAt.toLocal());
    return OceanGlassCard(
      onTap: onOpen,
      semanticLabel: l10n.savedPlacesCollectionCardSemantic(
        collection.name,
        collection.placeCount,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: AppSpacing.minTouchTarget,
                height: AppSpacing.minTouchTarget,
                decoration: BoxDecoration(
                  color: AppColors.paleCyan,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: const Icon(
                  Icons.folder_copy_rounded,
                  color: AppColors.ocean,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collection.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if ((collection.description ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        collection.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              OceanStatusPill(
                label: l10n.savedPlacesCollectionItemCount(
                  collection.placeCount,
                ),
                icon: Icons.place_outlined,
                color: AppColors.ocean,
                semanticLabel: l10n.savedPlacesCollectionItemCountSemantic(
                  collection.placeCount,
                ),
              ),
              OceanStatusPill(
                label: collection.privateCollection
                    ? l10n.savedPlacesCollectionPrivateLabel
                    : l10n.savedPlacesCollectionVisibleLabel,
                icon: collection.privateCollection
                    ? Icons.lock_outline_rounded
                    : Icons.visibility_outlined,
                color: AppColors.turquoise600,
              ),
              OceanStatusPill(
                label: l10n.savedPlacesCollectionUpdated(updated),
                icon: Icons.update_rounded,
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              OceanPrimaryButton(
                key: Key('real-collection-open-${collection.id}'),
                label: l10n.savedPlacesCollectionOpenAction,
                icon: Icons.folder_open_rounded,
                fullWidth: false,
                semanticLabel:
                    l10n.savedPlacesCollectionOpenSemantic(collection.name),
                onPressed: onOpen,
              ),
              OceanSecondaryButton(
                key: Key('real-collection-edit-${collection.id}'),
                label: l10n.savedPlacesCollectionEditAction,
                icon: Icons.edit_rounded,
                fullWidth: false,
                semanticLabel:
                    l10n.savedPlacesCollectionEditSemantic(collection.name),
                onPressed: onEdit,
              ),
              IconButton(
                key: Key('real-collection-delete-${collection.id}'),
                tooltip:
                    l10n.savedPlacesCollectionDeleteSemantic(collection.name),
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RealCollectionDetailView extends StatelessWidget {
  final CollectionDetailRecord collection;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddSavedPlace;
  final ValueChanged<CollectionPlaceRecord> onRemove;

  const _RealCollectionDetailView({
    required this.collection,
    required this.onBack,
    required this.onEdit,
    required this.onDelete,
    required this.onAddSavedPlace,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OceanGlassCard(
          semanticLabel: l10n.savedPlacesCollectionDetailSemantic(
            collection.name,
            collection.placeCount,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OceanSecondaryButton(
                    key: const Key('real-collection-back'),
                    label: l10n.savedPlacesCollectionBackAction,
                    icon: Icons.arrow_back_rounded,
                    fullWidth: false,
                    semanticLabel: l10n.savedPlacesCollectionBackSemantic,
                    onPressed: onBack,
                  ),
                  OceanSecondaryButton(
                    key: Key('real-collection-detail-edit-${collection.id}'),
                    label: l10n.savedPlacesCollectionEditAction,
                    icon: Icons.edit_rounded,
                    fullWidth: false,
                    semanticLabel:
                        l10n.savedPlacesCollectionEditSemantic(collection.name),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    key: Key(
                      'real-collection-detail-delete-${collection.id}',
                    ),
                    tooltip: l10n
                        .savedPlacesCollectionDeleteSemantic(collection.name),
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                collection.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if ((collection.description ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  collection.description!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  OceanStatusPill(
                    label: l10n.savedPlacesCollectionItemCount(
                      collection.placeCount,
                    ),
                    icon: Icons.place_outlined,
                    color: AppColors.ocean,
                    semanticLabel: l10n.savedPlacesCollectionItemCountSemantic(
                      collection.placeCount,
                    ),
                  ),
                  OceanStatusPill(
                    label: collection.privateCollection
                        ? l10n.savedPlacesCollectionPrivateLabel
                        : l10n.savedPlacesCollectionVisibleLabel,
                    icon: collection.privateCollection
                        ? Icons.lock_outline_rounded
                        : Icons.visibility_outlined,
                    color: AppColors.turquoise600,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              OceanPrimaryButton(
                key: Key('real-collection-add-saved-${collection.id}'),
                label: l10n.savedPlacesCollectionAddSavedAction,
                icon: Icons.add_location_alt_rounded,
                semanticLabel:
                    l10n.savedPlacesCollectionAddSavedSemantic(collection.name),
                onPressed: onAddSavedPlace,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (collection.places.isEmpty)
          OceanEmptyState(
            title: l10n.savedPlacesCollectionEmptyTitle,
            message: l10n.savedPlacesCollectionEmptyMessage,
            actionLabel: l10n.savedPlacesCollectionAddSavedAction,
            onAction: onAddSavedPlace,
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= AppBreakpoints.tablet;
              if (wide) {
                return Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    for (final place in collection.places)
                      SizedBox(
                        width: (constraints.maxWidth - AppSpacing.md) / 2,
                        child: _RealCollectionPlaceCard(
                          place: place,
                          onRemove: () => onRemove(place),
                        ),
                      ),
                  ],
                );
              }
              return Column(
                children: [
                  for (final place in collection.places)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _RealCollectionPlaceCard(
                        place: place,
                        onRemove: () => onRemove(place),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _RealCollectionPlaceCard extends StatelessWidget {
  final CollectionPlaceRecord place;
  final VoidCallback onRemove;

  const _RealCollectionPlaceCard({
    required this.place,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final added = DateFormat.yMMMd(Localizations.localeOf(context).toString())
        .format(place.addedAt.toLocal());
    return OceanGlassCard(
      semanticLabel: l10n.savedPlacesCollectionPlaceSemantic(place.name, added),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              color: AppColors.paleCyan,
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.place_rounded,
              color: AppColors.ocean,
              size: AppIconSizes.lg,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if ((place.categoryName ?? '').isNotEmpty)
                      OceanStatusPill(
                        label: place.categoryName!,
                        icon: Icons.place_outlined,
                        color: AppColors.ocean,
                      ),
                    OceanStatusPill(
                      label: l10n.savedPlacesCollectionAddedOn(added),
                      icon: Icons.playlist_add_check_rounded,
                      color: AppColors.success,
                    ),
                    if (place.ratingAvg > 0)
                      OceanStatusPill(
                        label: place.ratingAvg.toStringAsFixed(1),
                        icon: Icons.star_rounded,
                        color: AppColors.warning,
                      ),
                  ],
                ),
                if ((place.address ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    place.address!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    Tooltip(
                      message: l10n.savedPlacesCollectionPlaceHydrationMessage,
                      child: OceanSecondaryButton(
                        key: Key(
                            'real-collection-place-details-${place.placeId}'),
                        label: l10n.savedPlacesViewDetailsAction,
                        icon: Icons.info_outline_rounded,
                        fullWidth: false,
                        semanticLabel:
                            l10n.savedPlacesCollectionPlaceHydrationMessage,
                        onPressed: null,
                      ),
                    ),
                    Tooltip(
                      message: l10n.savedPlacesCollectionPlaceHydrationMessage,
                      child: OceanSecondaryButton(
                        key: Key(
                          'real-collection-place-add-trip-${place.placeId}',
                        ),
                        label: l10n.placeAddToTrip,
                        icon: Icons.add_location_alt_rounded,
                        fullWidth: false,
                        semanticLabel:
                            l10n.savedPlacesCollectionPlaceHydrationMessage,
                        onPressed: null,
                      ),
                    ),
                    OceanSecondaryButton(
                      key: Key('real-collection-place-remove-${place.placeId}'),
                      label: l10n.savedPlacesCollectionRemovePlaceAction,
                      icon: Icons.playlist_remove_rounded,
                      fullWidth: false,
                      semanticLabel:
                          l10n.savedPlacesCollectionRemovePlaceSemantic(
                        place.name,
                      ),
                      onPressed: onRemove,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionMembershipRow extends StatelessWidget {
  final Place place;
  final String collectionId;
  final String collectionName;
  final bool inCollection;
  final VoidCallback onToggle;

  const _CollectionMembershipRow({
    required this.place,
    required this.collectionId,
    required this.collectionName,
    required this.inCollection,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassSurface(
      blur: 0,
      color: AppColors.surfaceOverlay,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inCollection
                      ? l10n.savedPlacesCollectionMembershipIn(collectionName)
                      : l10n.savedPlacesCollectionMembershipOut(
                          collectionName,
                        ),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            flex: 0,
            child: Semantics(
              button: true,
              toggled: inCollection,
              label: inCollection
                  ? l10n.savedPlacesCollectionRemoveMembershipSemantic(
                      place.name,
                      collectionName,
                    )
                  : l10n.savedPlacesCollectionAddMembershipSemantic(
                      place.name,
                      collectionName,
                    ),
              child: OceanSecondaryButton(
                key: Key('saved-collection-toggle-${place.id}-$collectionId'),
                label: inCollection
                    ? l10n.savedPlacesCollectionInAction
                    : l10n.savedPlacesCollectionAddAction,
                icon: inCollection
                    ? Icons.check_circle_rounded
                    : Icons.add_circle_outline_rounded,
                fullWidth: false,
                onPressed: onToggle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedPlaceResults extends StatelessWidget {
  final List<ResolvedSavedPlace> results;
  final ValueChanged<ResolvedSavedPlace> onOpen;
  final ValueChanged<ResolvedSavedPlace> onAddToTrip;
  final ValueChanged<ResolvedSavedPlace> onHotel;
  final ValueChanged<ResolvedSavedPlace> onEditNote;
  final ValueChanged<ResolvedSavedPlace> onManageCollections;
  final ValueChanged<ResolvedSavedPlace> onRemove;

  const _SavedPlaceResults({
    required this.results,
    required this.onOpen,
    required this.onAddToTrip,
    required this.onHotel,
    required this.onEditNote,
    required this.onManageCollections,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= AppBreakpoints.tablet;
          if (wide) {
            return Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                for (final result in results)
                  SizedBox(
                    width: (constraints.maxWidth - AppSpacing.md) / 2,
                    child: _SavedPlaceCard(
                      result: result,
                      onTap: () => onOpen(result),
                      onAddToTrip: () => onAddToTrip(result),
                      onHotel: () => onHotel(result),
                      onEditNote: () => onEditNote(result),
                      onManageCollections: () => onManageCollections(result),
                      onRemove: () => onRemove(result),
                    ),
                  ),
              ],
            );
          }
          return Column(
            children: [
              for (final result in results)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _SavedPlaceCard(
                    result: result,
                    onTap: () => onOpen(result),
                    onAddToTrip: () => onAddToTrip(result),
                    onHotel: () => onHotel(result),
                    onEditNote: () => onEditNote(result),
                    onManageCollections: () => onManageCollections(result),
                    onRemove: () => onRemove(result),
                  ),
                ),
            ],
          );
        },
      );
}

class _SavedPlaceCard extends StatelessWidget {
  final ResolvedSavedPlace result;
  final VoidCallback onTap;
  final VoidCallback onAddToTrip;
  final VoidCallback onHotel;
  final VoidCallback onEditNote;
  final VoidCallback onManageCollections;
  final VoidCallback onRemove;

  const _SavedPlaceCard({
    required this.result,
    required this.onTap,
    required this.onAddToTrip,
    required this.onHotel,
    required this.onEditNote,
    required this.onManageCollections,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final place = result.place;
    if (place == null) {
      return _MissingSavedPlaceCard(result: result, onRemove: onRemove);
    }
    final l10n = AppLocalizations.of(context)!;
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toString())
        .format(result.record.savedAt.toLocal());
    return OceanGlassCard(
      onTap: onTap,
      semanticLabel: l10n.savedPlacesCardSemantic(place.name, date),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 430;
          final image = _PlaceImage(place: place, stacked: stacked);
          final details = _SavedPlaceDetails(
            place: place,
            result: result,
            savedDate: date,
            onAddToTrip: onAddToTrip,
            onHotel: onHotel,
            onEditNote: onEditNote,
            onManageCollections: onManageCollections,
            onRemove: onRemove,
          );
          return stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    image,
                    const SizedBox(height: AppSpacing.md),
                    details,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    image,
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: details),
                  ],
                );
        },
      ),
    );
  }
}

class _SavedPlaceDetails extends StatelessWidget {
  final Place place;
  final ResolvedSavedPlace result;
  final String savedDate;
  final VoidCallback onAddToTrip;
  final VoidCallback onHotel;
  final VoidCallback onEditNote;
  final VoidCallback onManageCollections;
  final VoidCallback onRemove;

  const _SavedPlaceDetails({
    required this.place,
    required this.result,
    required this.savedDate,
    required this.onAddToTrip,
    required this.onHotel,
    required this.onEditNote,
    required this.onManageCollections,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                place.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Semantics(
              button: true,
              toggled: true,
              label: l10n.savedPlacesRemoveSemantic(place.name),
              child: IconButton(
                key: Key('saved-place-remove-${place.id}'),
                tooltip: l10n.savedPlacesRemoveSemantic(place.name),
                onPressed: onRemove,
                icon: const Icon(
                  Icons.bookmark_rounded,
                  color: AppColors.ocean,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            OceanStatusPill(
              label: place.category,
              icon: Icons.place_outlined,
              color: AppColors.ocean,
            ),
            OceanStatusPill(
              label: l10n.savedPlacesSavedOn(savedDate),
              icon: Icons.event_available_rounded,
              color: AppColors.turquoise600,
            ),
            if (place.rating > 0)
              OceanStatusPill(
                label: place.rating.toStringAsFixed(1),
                icon: Icons.star_rounded,
                color: AppColors.warning,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${place.locationName} · ${place.city}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if ((result.record.note ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.savedPlacesNote(result.record.note!),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          alignment: WrapAlignment.end,
          children: [
            OceanSecondaryButton(
              key: Key('saved-place-details-${place.id}'),
              label: l10n.savedPlacesViewDetailsAction,
              icon: Icons.info_outline_rounded,
              fullWidth: false,
              semanticLabel: l10n.savedPlacesOpenDetailSemantic(place.name),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlaceDetailScreen(place: place),
                ),
              ),
            ),
            OceanSecondaryButton(
              key: Key('saved-place-add-trip-${place.id}'),
              label: l10n.placeAddToTrip,
              icon: Icons.add_location_alt_rounded,
              fullWidth: false,
              semanticLabel: l10n.placeAddToTripSemantic(place.name),
              onPressed: onAddToTrip,
            ),
            OceanSecondaryButton(
              key: Key('saved-place-edit-note-${place.id}'),
              label: l10n.savedPlacesEditNoteAction,
              icon: Icons.edit_note_rounded,
              fullWidth: false,
              semanticLabel: l10n.savedPlacesEditNoteSemantic(place.name),
              onPressed: onEditNote,
            ),
            OceanSecondaryButton(
              key: Key('saved-place-collections-${place.id}'),
              label: l10n.savedPlacesAddToCollectionAction,
              icon: Icons.folder_copy_rounded,
              fullWidth: false,
              semanticLabel:
                  l10n.savedPlacesManageCollectionsSemantic(place.name),
              onPressed: onManageCollections,
            ),
            if (place.hotelDetail != null)
              OceanPrimaryButton(
                key: Key('saved-place-hotel-${place.id}'),
                label: l10n.savedPlacesHotelAction,
                icon: Icons.king_bed_rounded,
                fullWidth: false,
                semanticLabel: l10n.hotelCheckAvailabilitySemantic(place.name),
                onPressed: onHotel,
              ),
          ],
        ),
      ],
    );
  }
}

class _MissingSavedPlaceCard extends StatelessWidget {
  final ResolvedSavedPlace result;
  final VoidCallback onRemove;

  const _MissingSavedPlaceCard({
    required this.result,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassCard(
      semanticLabel: l10n.savedPlacesMissingTitle,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppSpacing.minTouchTarget,
            height: AppSpacing.minTouchTarget,
            decoration: BoxDecoration(
              color: AppColors.paleCyan,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: const Icon(
              Icons.link_off_rounded,
              color: AppColors.ocean,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.savedPlacesMissingTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  l10n.savedPlacesMissingRecordMessage(result.record.placeId),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            tooltip: l10n.savedPlacesRemoveAction,
            onPressed: onRemove,
            icon: const Icon(Icons.bookmark_remove_rounded),
          ),
        ],
      ),
    );
  }
}

class _PlaceImage extends StatelessWidget {
  final Place place;
  final bool stacked;

  const _PlaceImage({required this.place, required this.stacked});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Image.network(
          place.imageUrl,
          width: stacked ? double.infinity : 128,
          height: stacked ? 180 : 128,
          fit: BoxFit.cover,
          excludeFromSemantics: true,
          errorBuilder: (_, __, ___) => Container(
            width: stacked ? double.infinity : 128,
            height: stacked ? 180 : 128,
            color: AppColors.paleCyan,
            alignment: Alignment.center,
            child: const Icon(
              Icons.place_rounded,
              color: AppColors.ocean,
              size: AppIconSizes.lg,
            ),
          ),
        ),
      );
}

/// Real Mode wishlist item card. Renders ONLY the fields the backend
/// `WishlistPlaceSummary` actually returns (no image/city/full Place), with a
/// neutral placeholder and a localized note explaining the limited details.
/// The saved/remove control reuses the shared [BookmarkButton], which keeps the
/// item in sync with every other bookmark control for the same place.
class _RealWishlistCard extends StatelessWidget {
  final WishlistItemRecord item;

  const _RealWishlistCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final place = item.place;
    final subtitleParts = <String>[
      if (place.categoryName != null && place.categoryName!.trim().isNotEmpty)
        place.categoryName!,
      if (place.address != null && place.address!.trim().isNotEmpty)
        place.address!,
    ];
    return OceanGlassCard(
      key: Key('real-wishlist-item-${item.placeId}'),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.paleCyan,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.place_rounded, color: AppColors.ocean),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium,
                    ),
                    if (subtitleParts.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitleParts.join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              BookmarkButton(placeId: place.id, placeName: place.name),
            ],
          ),
          if (place.shortDescription != null &&
              place.shortDescription!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              place.shortDescription!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium,
            ),
          ],
          if (place.ratingAvg > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            OceanStatusPill(
              label: '${place.ratingAvg.toStringAsFixed(1)}'
                  ' · ${place.reviewCount}',
              icon: Icons.star_rounded,
              color: AppColors.ocean,
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.wishlistRealPartialDetailsNote,
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
