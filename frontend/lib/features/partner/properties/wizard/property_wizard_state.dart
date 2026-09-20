import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_failure.dart';
import '../../../../core/partner/partner_models.dart';
import '../../../../core/partner/partner_property_form_models.dart';
import '../../../../core/partner/partner_property_models.dart';
import '../../../../core/partner/property_catalogue.dart';

/// The steps of the property onboarding wizard, in order.
///
/// A typed step rather than an index: every guard, every progress indicator and
/// every "fix this" jump in the review names one of these, so a step can never
/// be confused with the number of a different one.
enum PropertyWizardStep {
  businessProfile,
  basics,
  location,
  contact,
  amenities,
  policies,
  review;

  bool get isFirst => index == 0;
  bool get isLast => index == PropertyWizardStep.values.length - 1;

  PropertyWizardStep? get next =>
      isLast ? null : PropertyWizardStep.values[index + 1];
  PropertyWizardStep? get previous =>
      isFirst ? null : PropertyWizardStep.values[index - 1];

  /// The steps that hold property data — the readiness checkpoint and the
  /// review are not sections of the record.
  static const List<PropertyWizardStep> dataSteps = [
    PropertyWizardStep.basics,
    PropertyWizardStep.location,
    PropertyWizardStep.contact,
    PropertyWizardStep.amenities,
    PropertyWizardStep.policies,
  ];
}

enum PropertyWizardStatus {
  /// The catalogue, and for a resumed draft the property itself, are loading.
  loading,
  ready,

  /// The admin-managed catalogue could not be read. No form is shown on top of
  /// this: without it the wizard could only offer ids it invented.
  referenceError,

  /// A resumed draft could not be loaded — 404 (not yours or gone), 401, 403.
  propertyError,
}

/// Why a save is not possible yet, when it is not.
enum PropertyWizardSaveBlock {
  /// Nothing has changed since the last save.
  nothingToSave,

  /// A new property cannot be stored until every field the create contract
  /// requires is present — including the check-in/check-out times, which live
  /// in the details step. See [PropertyWizardState.canSaveDraft].
  incompleteForCreate,
}

/// The Partner property onboarding wizard.
///
/// ## What it is
///
/// An orchestration layer over the Phase C property API: the same
/// `POST /api/partner/hotels` and the same section `PUT`s, arranged as steps.
/// There is no wizard entity, no wizard endpoint and no local canonical copy of
/// a property — once a draft exists, the backend record is the truth and this
/// class holds only the form's working values.
///
/// ## What it refuses to do
///
/// * **It never publishes.** Nothing here can change a `PlaceStatus`; a created
///   property is a DRAFT because the backend makes it one.
/// * **It never invents a value to make a save possible.** The create contract
///   requires a name, category, star rating, location, address and check-in/out
///   times; until the partner has supplied all of them the draft is not created
///   and the wizard says so, rather than fabricating a rating or a time.
/// * **It never reports a save the server did not confirm.** Every success
///   comes from the record the server returned.
class PropertyWizardState extends ChangeNotifier {
  final ApiClient api;

  /// The business profile, read from the workspace. The readiness step shows a
  /// summary of it; the backend is what actually enforces approval.
  final PartnerProfile? profile;

  /// The draft being resumed, or null when starting a new property.
  final int? resumePropertyId;

  PropertyWizardState({
    required this.api,
    required this.profile,
    this.resumePropertyId,
  });

  PartnerVerificationStatus get profileStatus =>
      profile?.verificationStatus ?? PartnerVerificationStatus.unknown;

  late final PropertyCatalogue catalogue = PropertyCatalogue(api: api)
    ..addListener(_onCatalogueChanged);

  PropertyWizardStatus _status = PropertyWizardStatus.loading;
  PropertyWizardStatus get status => _status;
  bool get isReady => _status == PropertyWizardStatus.ready;

  /// The record the backend holds, once the property exists. Null while a new
  /// property has not been created yet.
  PartnerPropertyDetail? _saved;
  PartnerPropertyDetail? get saved => _saved;
  bool get propertyExists => _saved != null;
  int? get propertyId => _saved?.id ?? resumePropertyId;

  PropertyWizardStep _currentStep = PropertyWizardStep.businessProfile;
  PropertyWizardStep get currentStep => _currentStep;

  final Set<PropertyWizardStep> _visited = {PropertyWizardStep.businessProfile};
  Set<PropertyWizardStep> get visitedSteps => Set.unmodifiable(_visited);

  bool _saving = false;
  bool get isSaving => _saving;

  ApiFailure? _failure;
  ApiFailure? get failure => _failure;

  DateTime? _lastSavedAt;
  DateTime? get lastSavedAt => _lastSavedAt;

  /// True once a save has been made in this session — for the "saved just now"
  /// line, which must never appear before the server confirmed one.
  bool get hasSavedInSession => _lastSavedAt != null;

  // ── The form's working values ────────────────────────────────────────────

  String name = '';
  String shortDescription = '';
  String description = '';
  int? categoryId;
  int? subcategoryId;

  /// Null until the partner picks one. The schema requires 1–5 and has no value
  /// meaning "unclassified", so the wizard asks instead of defaulting.
  int? starRating;

  String address = '';
  String latitude = '';
  String longitude = '';

  String phone = '';
  String email = '';
  String website = '';

  final Set<int> amenityIds = <int>{};

  /// Prefilled and visible from the first frame of the details step, so nothing
  /// is ever submitted that the partner has not seen and can change.
  String checkIn = '14:00';
  String checkOut = '12:00';
  String childrenPolicy = '';
  String petPolicy = '';
  String smokingPolicy = '';
  String cancellationPolicy = '';
  String parkingDescription = '';
  String internetDescription = '';
  String languages = '';
  String paymentMethods = '';
  bool freeCancellation = false;
  bool parkingAvailable = false;
  bool parkingFree = false;
  bool wifiAvailable = false;
  bool wifiFree = false;

  // ── Loading ──────────────────────────────────────────────────────────────

  /// Loads the catalogue and, when resuming, the draft itself; then opens at
  /// the first step that is not complete.
  Future<void> load() async {
    _status = PropertyWizardStatus.loading;
    _failure = null;
    notifyListeners();

    await catalogue.load();
    if (!catalogue.isReady) {
      _status = PropertyWizardStatus.referenceError;
      notifyListeners();
      return;
    }

    final resumeId = resumePropertyId;
    if (resumeId != null) {
      final result = await api.getPartnerProperty(resumeId);
      if (!result.success || result.data == null) {
        _status = PropertyWizardStatus.propertyError;
        _failure = ApiFailure(
          kind: result.errorKind ?? ApiErrorKind.network,
          serverMessage: result.message,
        );
        notifyListeners();
        return;
      }
      _applyRecord(result.data!);
    } else if (catalogue.categoryOptions.length == 1) {
      // One accommodation root is the common case; choosing it for the partner
      // removes a choice with one option. The specific type stays theirs.
      categoryId = catalogue.categoryOptions.first.id;
    }

    _status = PropertyWizardStatus.ready;
    // A resumed draft opens where the work actually stopped; a new property at
    // the readiness checkpoint.
    _currentStep = resumeId == null
        ? PropertyWizardStep.businessProfile
        : firstIncompleteStep;
    _visited.add(_currentStep);
    notifyListeners();
  }

  /// Mirrors a backend record into the form. This is also the save baseline:
  /// "dirty" always means "different from what the server holds".
  void _applyRecord(PartnerPropertyDetail record) {
    _saved = record;
    name = record.name;
    shortDescription = record.shortDescription ?? '';
    description = record.description ?? '';
    categoryId = record.category?.id;
    subcategoryId = record.subcategory?.id;
    starRating = record.starRating;
    address = record.address ?? '';
    latitude = record.latitude?.toString() ?? '';
    longitude = record.longitude?.toString() ?? '';
    phone = record.phone ?? '';
    email = record.email ?? '';
    website = record.website ?? '';
    amenityIds
      ..clear()
      ..addAll(record.amenities.map((amenity) => amenity.id));
    checkIn = record.checkIn ?? checkIn;
    checkOut = record.checkOut ?? checkOut;
    childrenPolicy = record.childrenPolicy ?? '';
    petPolicy = record.petPolicy ?? '';
    smokingPolicy = record.smokingPolicy ?? '';
    cancellationPolicy = record.cancellationPolicy ?? '';
    parkingDescription = record.parkingDescription ?? '';
    internetDescription = record.internetDescription ?? '';
    languages = record.languages.join(', ');
    paymentMethods = record.paymentMethods.join(', ');
    freeCancellation = record.freeCancellation ?? false;
    parkingAvailable = record.parkingAvailable ?? false;
    parkingFree = record.parkingFree ?? false;
    wifiAvailable = record.wifiAvailable ?? false;
    wifiFree = record.wifiFree ?? false;
  }

  void _onCatalogueChanged() {
    _failure = null;
    notifyListeners();
  }

  @override
  void dispose() {
    catalogue.removeListener(_onCatalogueChanged);
    catalogue.dispose();
    super.dispose();
  }

  // ── The gate ─────────────────────────────────────────────────────────────

  /// Property management is open only to an approved business profile. The
  /// wizard shows the status and the way to fix it; the backend decides.
  bool get isProfileApproved =>
      profileStatus == PartnerVerificationStatus.approved;

  // ── Location ─────────────────────────────────────────────────────────────

  /// The unit the property will be placed in: whatever was picked here, or the
  /// one a resumed draft already has until the partner picks another.
  int? get selectedLocationId {
    if (!catalogue.hasPickedLocation) {
      final current = _saved?.administrativeUnit?.id;
      if (current != null) return current;
    }
    return catalogue.pickedUnitId;
  }

  /// The chosen path for display — the catalogue's own names, or the stored
  /// record's full path when nothing has been re-picked.
  String? get locationLabel {
    if (catalogue.hasPickedLocation) {
      final path = catalogue.pickedPath;
      return path.isEmpty ? null : path.join(' → ');
    }
    return _saved?.administrativeUnit?.label;
  }

  // ── Validation ───────────────────────────────────────────────────────────

  static final RegExp timePattern = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
  static final RegExp emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static bool isValidCoordinate(String raw, double bound) {
    final text = raw.trim();
    if (text.isEmpty) return true;
    final parsed = double.tryParse(text);
    return parsed != null && parsed >= -bound && parsed <= bound;
  }

  bool get isBasicsValid =>
      name.trim().isNotEmpty &&
      categoryId != null &&
      starRating != null &&
      starRating! >= 1 &&
      starRating! <= 5;

  bool get isLocationValid =>
      selectedLocationId != null &&
      address.trim().isNotEmpty &&
      isValidCoordinate(latitude, 90) &&
      isValidCoordinate(longitude, 180);

  /// Contact has no required field in the domain; an address that *is* given
  /// must still be a real one.
  bool get isContactValid =>
      email.trim().isEmpty || emailPattern.hasMatch(email.trim());

  bool get isPoliciesValid =>
      timePattern.hasMatch(checkIn.trim()) &&
      timePattern.hasMatch(checkOut.trim());

  /// Whether [step] may be left going forward.
  bool isStepValid(PropertyWizardStep step) => switch (step) {
        PropertyWizardStep.businessProfile => isProfileApproved,
        PropertyWizardStep.basics => isBasicsValid,
        PropertyWizardStep.location => isLocationValid,
        PropertyWizardStep.contact => isContactValid,
        PropertyWizardStep.amenities => true,
        PropertyWizardStep.policies => isPoliciesValid,
        PropertyWizardStep.review => true,
      };

  /// Whether [step] holds everything it needs — what the review's completeness
  /// list and the resume logic both read.
  ///
  /// Contact and amenities carry no required field, so they count as complete
  /// once the partner has been there; they never block progress.
  bool isStepComplete(PropertyWizardStep step) => switch (step) {
        PropertyWizardStep.businessProfile => isProfileApproved,
        PropertyWizardStep.basics => isBasicsValid,
        PropertyWizardStep.location => isLocationValid,
        PropertyWizardStep.contact =>
          isContactValid && (_visited.contains(step) || _hasAnyContact),
        PropertyWizardStep.amenities =>
          _visited.contains(step) || amenityIds.isNotEmpty,
        PropertyWizardStep.policies => isPoliciesValid,
        PropertyWizardStep.review => false,
      };

  bool get _hasAnyContact =>
      phone.trim().isNotEmpty ||
      email.trim().isNotEmpty ||
      website.trim().isNotEmpty;

  /// Where a resumed draft opens: the first step that is not complete, or the
  /// review when everything is.
  PropertyWizardStep get firstIncompleteStep {
    if (!isProfileApproved) return PropertyWizardStep.businessProfile;
    for (final step in PropertyWizardStep.dataSteps) {
      if (!isStepComplete(step)) return step;
    }
    return PropertyWizardStep.review;
  }

  /// The steps a partner may jump to directly: the ones already visited, and
  /// any step whose predecessors are all complete. A required step cannot be
  /// skipped by clicking the progress rail — reaching the review by jumping
  /// over an empty Basics is exactly what this prevents.
  bool canOpen(PropertyWizardStep step) {
    if (!isProfileApproved) return step == PropertyWizardStep.businessProfile;
    if (_visited.contains(step)) return true;
    for (final earlier in PropertyWizardStep.values) {
      if (earlier.index >= step.index) break;
      if (!isStepComplete(earlier)) return false;
    }
    return true;
  }

  // ── Navigation ───────────────────────────────────────────────────────────

  /// Moves forward when the current step validates. Returns false when it does
  /// not, so the screen can show the reason where it belongs.
  bool goNext() {
    if (!isStepValid(_currentStep)) return false;
    final next = _currentStep.next;
    if (next == null) return false;
    _currentStep = next;
    _visited.add(next);
    _failure = null;
    notifyListeners();
    return true;
  }

  void goBack() {
    final previous = _currentStep.previous;
    if (previous == null) return;
    _currentStep = previous;
    _visited.add(previous);
    _failure = null;
    notifyListeners();
  }

  /// Jumps to [step] — the review's "fix this" action and the progress rail.
  bool goTo(PropertyWizardStep step) {
    if (!canOpen(step)) return false;
    _currentStep = step;
    _visited.add(step);
    _failure = null;
    notifyListeners();
    return true;
  }

  // ── Editing ──────────────────────────────────────────────────────────────

  /// One entry point for every text field, so a change always clears a stale
  /// failure and always refreshes the dirty state.
  void setText(void Function() apply) {
    apply();
    _failure = null;
    notifyListeners();
  }

  void selectCategory(int? id) {
    if (categoryId == id) return;
    categoryId = id;
    // A subcategory must be a child of the category, so it cannot survive a
    // change of category.
    subcategoryId = null;
    _failure = null;
    notifyListeners();
  }

  void selectSubcategory(int? id) {
    subcategoryId = id;
    _failure = null;
    notifyListeners();
  }

  void setStarRating(int? value) {
    starRating = value;
    _failure = null;
    notifyListeners();
  }

  void toggleAmenity(int id) {
    if (!amenityIds.remove(id)) amenityIds.add(id);
    _failure = null;
    notifyListeners();
  }

  void setFlag(void Function() apply) {
    apply();
    _failure = null;
    notifyListeners();
  }

  // ── Dirty state ──────────────────────────────────────────────────────────

  bool get isBasicsDirty {
    final record = _saved;
    if (record == null) return name.trim().isNotEmpty;
    return name.trim() != record.name ||
        _clean(shortDescription) != record.shortDescription ||
        _clean(description) != record.description ||
        categoryId != record.category?.id ||
        subcategoryId != record.subcategory?.id;
  }

  bool get isLocationDirty {
    final record = _saved;
    if (record == null) return address.trim().isNotEmpty;
    return address.trim() != record.address ||
        _number(latitude) != record.latitude ||
        _number(longitude) != record.longitude ||
        selectedLocationId != record.administrativeUnit?.id;
  }

  bool get isContactDirty {
    final record = _saved;
    if (record == null) return _hasAnyContact;
    return _clean(phone) != record.phone ||
        _clean(email) != record.email ||
        _clean(website) != record.website;
  }

  bool get isAmenitiesDirty {
    final record = _saved;
    if (record == null) return amenityIds.isNotEmpty;
    final before = record.amenities.map((amenity) => amenity.id).toSet();
    return before.length != amenityIds.length ||
        !before.containsAll(amenityIds);
  }

  bool get isPoliciesDirty {
    final record = _saved;
    if (record == null) return true;
    return checkIn.trim() != (record.checkIn ?? '') ||
        checkOut.trim() != (record.checkOut ?? '') ||
        _clean(childrenPolicy) != record.childrenPolicy ||
        _clean(petPolicy) != record.petPolicy ||
        _clean(smokingPolicy) != record.smokingPolicy ||
        starRating != record.starRating ||
        _clean(cancellationPolicy) != record.cancellationPolicy ||
        freeCancellation != (record.freeCancellation ?? false) ||
        parkingAvailable != (record.parkingAvailable ?? false) ||
        parkingFree != (record.parkingFree ?? false) ||
        _clean(parkingDescription) != record.parkingDescription ||
        wifiAvailable != (record.wifiAvailable ?? false) ||
        wifiFree != (record.wifiFree ?? false) ||
        _clean(internetDescription) != record.internetDescription ||
        !_sameList(splitPropertyList(languages), record.languages) ||
        !_sameList(splitPropertyList(paymentMethods), record.paymentMethods);
  }

  Set<PropertyWizardStep> get dirtySteps => {
        if (isBasicsDirty) PropertyWizardStep.basics,
        if (isLocationDirty) PropertyWizardStep.location,
        if (isContactDirty) PropertyWizardStep.contact,
        if (isAmenitiesDirty) PropertyWizardStep.amenities,
        if (propertyExists && isPoliciesDirty) PropertyWizardStep.policies,
      };

  /// True when there is work the backend does not have yet.
  bool get hasUnsavedChanges =>
      propertyExists ? dirtySteps.isNotEmpty : _hasAnyInput;

  bool get _hasAnyInput =>
      name.trim().isNotEmpty ||
      address.trim().isNotEmpty ||
      _hasAnyContact ||
      amenityIds.isNotEmpty ||
      subcategoryId != null ||
      starRating != null;

  // ── Saving ───────────────────────────────────────────────────────────────

  /// Everything the create contract requires (`PartnerHotelCreateRequest`):
  /// name, category, star rating, administrative unit, address and both times.
  bool get hasMinimumForCreate =>
      isBasicsValid && isLocationValid && isPoliciesValid;

  /// Whether **Save draft** can do anything right now, and if not, why.
  PropertyWizardSaveBlock? get saveBlock {
    if (!propertyExists) {
      return hasMinimumForCreate
          ? null
          : PropertyWizardSaveBlock.incompleteForCreate;
    }
    return dirtySteps.isEmpty ? PropertyWizardSaveBlock.nothingToSave : null;
  }

  bool get canSaveDraft => saveBlock == null && !_saving && isProfileApproved;

  /// Persists the draft: one create for a property that does not exist yet,
  /// otherwise one request per changed section.
  ///
  /// Returns true only when the server confirmed. A refusal leaves every typed
  /// value where it is and puts the reason in [failure].
  Future<bool> saveDraft() async {
    if (_saving || !canSaveDraft) return false;
    _saving = true;
    _failure = null;
    notifyListeners();

    final ok = propertyExists ? await _updateSections() : await _create();

    _saving = false;
    if (ok) _lastSavedAt = DateTime.now();
    notifyListeners();
    return ok;
  }

  Future<bool> _create() async {
    final locationId = selectedLocationId;
    final category = categoryId;
    final rating = starRating;
    if (locationId == null || category == null || rating == null) return false;

    final result = await api.createPartnerProperty(PartnerPropertyDraft(
      name: name.trim(),
      shortDescription: _clean(shortDescription),
      description: _clean(description),
      categoryId: category,
      subcategoryId: subcategoryId,
      administrativeUnitId: locationId,
      address: address.trim(),
      latitude: _number(latitude),
      longitude: _number(longitude),
      phone: _clean(phone),
      email: _clean(email),
      website: _clean(website),
      starRating: rating,
      checkIn: checkIn.trim(),
      checkOut: checkOut.trim(),
      childrenPolicy: _clean(childrenPolicy),
      petPolicy: _clean(petPolicy),
      smokingPolicy: _clean(smokingPolicy),
      cancellationPolicy: _clean(cancellationPolicy),
      freeCancellation: freeCancellation,
      parkingAvailable: parkingAvailable,
      parkingFree: parkingFree,
      parkingDescription: _clean(parkingDescription),
      wifiAvailable: wifiAvailable,
      wifiFree: wifiFree,
      internetDescription: _clean(internetDescription),
      languages: splitPropertyList(languages),
      paymentMethods: splitPropertyList(paymentMethods),
      amenityIds: amenityIds.toList(growable: false),
    ));
    if (!result.success || result.data == null) {
      _failure = result.failure;
      return false;
    }
    _applyRecord(result.data!);
    return true;
  }

  /// One request per changed section, in a fixed order. The first refusal stops
  /// the sequence; the sections already accepted stay saved, and the record is
  /// refreshed from the server's last answer so the form shows what is stored.
  Future<bool> _updateSections() async {
    final record = _saved!;
    final locationId = selectedLocationId;
    final category = categoryId;
    if (locationId == null || category == null) return false;

    if (isBasicsDirty) {
      final result = await api.updatePartnerPropertyBasics(
        propertyId: record.id,
        basics: PartnerPropertyBasics(
          name: name.trim(),
          // The public identifier goes back exactly as it was read.
          slug: record.slug ?? '',
          shortDescription: _clean(shortDescription),
          description: _clean(description),
          categoryId: category,
          subcategoryId: subcategoryId,
        ),
      );
      if (!_accept(result)) return false;
    }

    if (isLocationDirty) {
      final result = await api.updatePartnerPropertyPlacement(
        propertyId: record.id,
        placement: PartnerPropertyPlacement(
          address: address.trim(),
          latitude: _number(latitude),
          longitude: _number(longitude),
          administrativeUnitId: locationId,
        ),
      );
      if (!_accept(result)) return false;
    }

    if (isContactDirty) {
      final result = await api.updatePartnerPropertyContact(
        propertyId: record.id,
        contact: PartnerPropertyContact(
          phone: _clean(phone),
          email: _clean(email),
          website: _clean(website),
          // Not shown by this wizard: carried through rather than erased.
          facebook: record.facebook,
          instagram: record.instagram,
        ),
      );
      if (!_accept(result)) return false;
    }

    if (isPoliciesDirty) {
      final rating = starRating;
      if (rating == null) return false;
      final result = await api.updatePartnerPropertyDetails(
        propertyId: record.id,
        details: PartnerPropertyDetails(
          checkIn: checkIn.trim(),
          checkOut: checkOut.trim(),
          childrenPolicy: _clean(childrenPolicy),
          petPolicy: _clean(petPolicy),
          smokingPolicy: _clean(smokingPolicy),
          starRating: rating,
          cancellationPolicy: _clean(cancellationPolicy),
          freeCancellation: freeCancellation,
          parkingAvailable: parkingAvailable,
          parkingFree: parkingFree,
          parkingDescription: _clean(parkingDescription),
          wifiAvailable: wifiAvailable,
          wifiFree: wifiFree,
          internetDescription: _clean(internetDescription),
          languages: splitPropertyList(languages),
          paymentMethods: splitPropertyList(paymentMethods),
        ),
      );
      if (!_accept(result)) return false;
    }

    if (isAmenitiesDirty) {
      final result = await api.updatePartnerPropertyAmenities(
        propertyId: record.id,
        amenityIds: amenityIds.toList(growable: false),
      );
      if (!_accept(result)) return false;
    }

    return true;
  }

  /// Takes the server's record as the new truth, or records the refusal.
  bool _accept(ApiWriteResult<PartnerPropertyDetail> result) {
    if (!result.success || result.data == null) {
      _failure = result.failure;
      return false;
    }
    _saved = result.data;
    return true;
  }

  /// Throws away unsaved edits by returning to the stored record. For a
  /// property that does not exist yet there is nothing stored, so this clears
  /// the form.
  void discardChanges() {
    final record = _saved;
    if (record != null) {
      _applyRecord(record);
    } else {
      name = '';
      shortDescription = '';
      description = '';
      subcategoryId = null;
      starRating = null;
      address = '';
      latitude = '';
      longitude = '';
      phone = '';
      email = '';
      website = '';
      amenityIds.clear();
    }
    _failure = null;
    notifyListeners();
  }

  String? _clean(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  double? _number(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : double.tryParse(trimmed);
  }

  bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
