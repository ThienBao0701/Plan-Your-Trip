import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/partner/partner_property_form_models.dart';
import '../../../core/partner/partner_property_models.dart';
import '../../../core/partner/property_catalogue.dart';

/// Where the editor stands before anything can be typed.
enum PropertyEditorStatus {
  /// The admin-managed catalogue is still loading.
  loading,
  ready,

  /// The catalogue could not be read. The form is not shown at all: without it
  /// the editor could only offer ids it invented.
  referenceError,
}

/// The free-text part of the form. The widget owns the controllers; the state
/// owns everything that is a choice from the catalogue.
class PropertyFormText {
  final String name;
  final String? shortDescription;
  final String? description;
  final String address;
  final String? latitude;
  final String? longitude;
  final String? phone;
  final String? email;
  final String? website;
  final String checkIn;
  final String checkOut;
  final String? childrenPolicy;
  final String? petPolicy;
  final String? smokingPolicy;
  final String? cancellationPolicy;
  final String? parkingDescription;
  final String? internetDescription;
  final String? languages;
  final String? paymentMethods;

  const PropertyFormText({
    required this.name,
    required this.address,
    required this.checkIn,
    required this.checkOut,
    this.shortDescription,
    this.description,
    this.latitude,
    this.longitude,
    this.phone,
    this.email,
    this.website,
    this.childrenPolicy,
    this.petPolicy,
    this.smokingPolicy,
    this.cancellationPolicy,
    this.parkingDescription,
    this.internetDescription,
    this.languages,
    this.paymentMethods,
  });

  /// `"Vietnamese, English"` → `["Vietnamese", "English"]`; blanks dropped.
  /// One implementation, shared with the onboarding wizard.
  static List<String> splitList(String? raw) => splitPropertyList(raw);
}

/// The Partner property editor: the catalogue it chooses from, the choices
/// made, and the writes that follow.
///
/// ## What this class refuses to do
///
/// * It never invents a category, location or amenity id. Every option comes
///   from the admin-managed catalogue, and the backend validates each id again.
/// * It never reports a save the server did not confirm. A create returns the
///   record the server wrote; an edit is a sequence of section requests, and the
///   first refusal stops it — the sections already accepted stay saved, and the
///   caller is told which failure ended it.
/// * It never publishes. Nothing here can change a property's `PlaceStatus`;
///   a created property is a draft because the backend makes it one.
class PartnerPropertyEditorState extends ChangeNotifier {
  final ApiClient api;

  /// The property being edited, or null when creating a new one.
  final PartnerPropertyDetail? original;

  PartnerPropertyEditorState({required this.api, this.original});

  bool get isCreating => original == null;

  /// The admin-managed reference data and the location cascade, shared with the
  /// Phase D onboarding wizard rather than implemented twice.
  late final PropertyCatalogue catalogue = PropertyCatalogue(api: api)
    ..addListener(notifyListeners);

  PropertyEditorStatus _status = PropertyEditorStatus.loading;
  PropertyEditorStatus get status => _status;
  bool get isReady => _status == PropertyEditorStatus.ready;

  int? _categoryId;
  int? _subcategoryId;

  final Set<int> _amenityIds = <int>{};

  int _starRating = 3;
  bool _freeCancellation = false;
  bool _parkingAvailable = false;
  bool _parkingFree = false;
  bool _wifiAvailable = false;
  bool _wifiFree = false;

  bool _saving = false;
  ApiFailure? _failure;

  List<PropertyCategoryOption> get categoryOptions => catalogue.categoryOptions;

  /// The direct children of the chosen category — the specific property type.
  List<PropertyCategoryOption> get subcategoryOptions =>
      catalogue.subcategoryOptions(_categoryId);

  List<PropertyLocationOption> get countryOptions => catalogue.countryOptions;
  List<PropertyLocationOption> get provinceOptions => catalogue.provinceOptions;
  List<PropertyLocationOption> get areaOptions => catalogue.areaOptions;

  Map<String, List<PropertyAmenityOption>> get amenityGroups =>
      catalogue.amenityGroups;

  int? get categoryId => _categoryId;
  int? get subcategoryId => _subcategoryId;
  int? get countryId => catalogue.countryId;
  int? get provinceId => catalogue.provinceId;
  int? get areaId => catalogue.areaId;
  bool get isLoadingLocationChildren => catalogue.isLoadingChildren;
  Set<int> get selectedAmenityIds => Set.unmodifiable(_amenityIds);
  int get starRating => _starRating;
  bool get freeCancellation => _freeCancellation;
  bool get parkingAvailable => _parkingAvailable;
  bool get parkingFree => _parkingFree;
  bool get wifiAvailable => _wifiAvailable;
  bool get wifiFree => _wifiFree;
  bool get isSaving => _saving;
  ApiFailure? get failure => _failure;

  /// The unit the property will be placed in: the area when one is chosen,
  /// otherwise the province or city. Null until a valid one is picked — and, on
  /// an existing property whose location has not been touched, the one it
  /// already has.
  int? get selectedLocationId {
    if (!catalogue.hasPickedLocation) {
      final current = original?.administrativeUnit?.id;
      if (current != null) return current;
    }
    return catalogue.pickedUnitId;
  }

  /// What the location row should show when nothing has been re-picked.
  String? get currentLocationLabel => original?.administrativeUnit?.label;

  bool get hasPickedLocation => catalogue.hasPickedLocation;

  /// Loads the catalogue the editor chooses from, then pre-selects whatever the
  /// property being edited already uses.
  Future<void> load() async {
    _status = PropertyEditorStatus.loading;
    notifyListeners();

    await catalogue.load();
    if (!catalogue.isReady) {
      _status = PropertyEditorStatus.referenceError;
      notifyListeners();
      return;
    }

    _applyOriginal();
    _status = PropertyEditorStatus.ready;
    notifyListeners();
  }

  @override
  void dispose() {
    catalogue.removeListener(notifyListeners);
    catalogue.dispose();
    super.dispose();
  }

  void _applyOriginal() {
    final property = original;
    if (property == null) {
      // A new property: default to the only category when there is one.
      if (categoryOptions.length == 1) _categoryId = categoryOptions.first.id;
      return;
    }
    // Everything below mirrors the stored record into the form's own choices.
    _categoryId = property.category?.id;
    _subcategoryId = property.subcategory?.id;
    _starRating = property.starRating ?? _starRating;
    _freeCancellation = property.freeCancellation ?? false;
    _parkingAvailable = property.parkingAvailable ?? false;
    _parkingFree = property.parkingFree ?? false;
    _wifiAvailable = property.wifiAvailable ?? false;
    _wifiFree = property.wifiFree ?? false;
    _amenityIds
      ..clear()
      ..addAll(property.amenities.map((amenity) => amenity.id));
  }

  void selectCategory(int? id) {
    if (_categoryId == id) return;
    _categoryId = id;
    // The subcategory must be a child of the category, so it cannot survive a
    // change of category.
    _subcategoryId = null;
    _clearFailure();
    notifyListeners();
  }

  void selectSubcategory(int? id) {
    _subcategoryId = id;
    _clearFailure();
    notifyListeners();
  }

  Future<void> selectCountry(int? id) async {
    _clearFailure();
    await catalogue.selectCountry(id);
  }

  Future<void> selectProvince(int? id) async {
    _clearFailure();
    await catalogue.selectProvince(id);
  }

  void selectArea(int? id) {
    _clearFailure();
    catalogue.selectArea(id);
  }

  void toggleAmenity(int id) {
    if (!_amenityIds.remove(id)) _amenityIds.add(id);
    _clearFailure();
    notifyListeners();
  }

  void setStarRating(int value) {
    _starRating = value;
    _clearFailure();
    notifyListeners();
  }

  void setFreeCancellation(bool value) {
    _freeCancellation = value;
    notifyListeners();
  }

  void setParkingAvailable(bool value) {
    _parkingAvailable = value;
    if (!value) _parkingFree = false;
    notifyListeners();
  }

  void setParkingFree(bool value) {
    _parkingFree = value;
    notifyListeners();
  }

  void setWifiAvailable(bool value) {
    _wifiAvailable = value;
    if (!value) _wifiFree = false;
    notifyListeners();
  }

  void setWifiFree(bool value) {
    _wifiFree = value;
    notifyListeners();
  }

  void _clearFailure() {
    if (_failure != null) _failure = null;
  }

  /// Saves the form. Returns the server's own record on success, null on a
  /// refusal — in which case [failure] says why.
  ///
  /// A second call while one is in flight is ignored, so a double tap cannot
  /// create two properties.
  Future<PartnerPropertyDetail?> save(PropertyFormText text) async {
    if (_saving) return null;
    final categoryId = _categoryId;
    final locationId = selectedLocationId;
    if (categoryId == null || locationId == null) return null;

    _saving = true;
    _failure = null;
    notifyListeners();

    final saved = isCreating
        ? await _create(text, categoryId, locationId)
        : await _update(text, categoryId, locationId);

    _saving = false;
    notifyListeners();
    return saved;
  }

  Future<PartnerPropertyDetail?> _create(
    PropertyFormText text,
    int categoryId,
    int locationId,
  ) async {
    final result = await api.createPartnerProperty(PartnerPropertyDraft(
      name: text.name.trim(),
      shortDescription: _clean(text.shortDescription),
      description: _clean(text.description),
      categoryId: categoryId,
      subcategoryId: _subcategoryId,
      administrativeUnitId: locationId,
      address: text.address.trim(),
      latitude: _number(text.latitude),
      longitude: _number(text.longitude),
      phone: _clean(text.phone),
      email: _clean(text.email),
      website: _clean(text.website),
      starRating: _starRating,
      checkIn: text.checkIn.trim(),
      checkOut: text.checkOut.trim(),
      childrenPolicy: _clean(text.childrenPolicy),
      petPolicy: _clean(text.petPolicy),
      smokingPolicy: _clean(text.smokingPolicy),
      cancellationPolicy: _clean(text.cancellationPolicy),
      freeCancellation: _freeCancellation,
      parkingAvailable: _parkingAvailable,
      parkingFree: _parkingFree,
      parkingDescription: _clean(text.parkingDescription),
      wifiAvailable: _wifiAvailable,
      wifiFree: _wifiFree,
      internetDescription: _clean(text.internetDescription),
      languages: PropertyFormText.splitList(text.languages),
      paymentMethods: PropertyFormText.splitList(text.paymentMethods),
      amenityIds: _amenityIds.toList(growable: false),
    ));
    if (result.success) return result.data;
    _failure = result.failure;
    return null;
  }

  /// One request per **changed** section, in a fixed order.
  ///
  /// A section the partner did not touch is not written: the backend creates a
  /// "Property updated" notification per section endpoint, and nobody needs four
  /// of them for a corrected phone number. Saving with nothing changed therefore
  /// sends nothing at all and returns the record as it already is.
  ///
  /// The first refusal stops the sequence: what was already accepted stays
  /// saved, and the record returned by the last accepted section is dropped in
  /// favour of the failure, so nothing claims a save that did not finish.
  Future<PartnerPropertyDetail?> _update(
    PropertyFormText text,
    int categoryId,
    int locationId,
  ) async {
    final property = original!;
    PartnerPropertyDetail? latest = property;

    final basics = PartnerPropertyBasics(
      name: text.name.trim(),
      // The public identifier is carried through exactly as it was read.
      slug: property.slug ?? '',
      shortDescription: _clean(text.shortDescription),
      description: _clean(text.description),
      categoryId: categoryId,
      subcategoryId: _subcategoryId,
    );
    if (basics.name != property.name ||
        basics.shortDescription != property.shortDescription ||
        basics.description != property.description ||
        basics.categoryId != property.category?.id ||
        basics.subcategoryId != property.subcategory?.id) {
      final result = await api.updatePartnerPropertyBasics(
          propertyId: property.id, basics: basics);
      if (!result.success) return _fail(result.failure);
      latest = result.data;
    }

    final placement = PartnerPropertyPlacement(
      address: text.address.trim(),
      latitude: _number(text.latitude),
      longitude: _number(text.longitude),
      administrativeUnitId: locationId,
    );
    if (placement.address != property.address ||
        placement.latitude != property.latitude ||
        placement.longitude != property.longitude ||
        placement.administrativeUnitId != property.administrativeUnit?.id) {
      final result = await api.updatePartnerPropertyPlacement(
          propertyId: property.id, placement: placement);
      if (!result.success) return _fail(result.failure);
      latest = result.data;
    }

    final contact = PartnerPropertyContact(
      phone: _clean(text.phone),
      email: _clean(text.email),
      website: _clean(text.website),
      // Not shown by this editor: carried through rather than erased.
      facebook: property.facebook,
      instagram: property.instagram,
    );
    if (contact.phone != property.phone ||
        contact.email != property.email ||
        contact.website != property.website) {
      final result = await api.updatePartnerPropertyContact(
          propertyId: property.id, contact: contact);
      if (!result.success) return _fail(result.failure);
      latest = result.data;
    }

    final details = PartnerPropertyDetails(
      checkIn: text.checkIn.trim(),
      checkOut: text.checkOut.trim(),
      childrenPolicy: _clean(text.childrenPolicy),
      petPolicy: _clean(text.petPolicy),
      smokingPolicy: _clean(text.smokingPolicy),
      starRating: _starRating,
      cancellationPolicy: _clean(text.cancellationPolicy),
      freeCancellation: _freeCancellation,
      parkingAvailable: _parkingAvailable,
      parkingFree: _parkingFree,
      parkingDescription: _clean(text.parkingDescription),
      wifiAvailable: _wifiAvailable,
      wifiFree: _wifiFree,
      internetDescription: _clean(text.internetDescription),
      languages: PropertyFormText.splitList(text.languages),
      paymentMethods: PropertyFormText.splitList(text.paymentMethods),
    );
    if (_detailsChanged(property, details)) {
      final result = await api.updatePartnerPropertyDetails(
          propertyId: property.id, details: details);
      if (!result.success) return _fail(result.failure);
      latest = result.data;
    }

    if (_amenitiesChanged(property)) {
      final result = await api.updatePartnerPropertyAmenities(
        propertyId: property.id,
        amenityIds: _amenityIds.toList(growable: false),
      );
      if (!result.success) return _fail(result.failure);
      latest = result.data;
    }

    return latest;
  }

  /// The stored record carries check-in/out as `"HH:mm"`, and the booleans as
  /// null when the property has no `HotelDetail` row at all — which is not
  /// "false", so a property without one counts as changed.
  bool _detailsChanged(
      PartnerPropertyDetail property, PartnerPropertyDetails details) {
    return details.checkIn != (property.checkIn ?? '') ||
        details.checkOut != (property.checkOut ?? '') ||
        details.childrenPolicy != property.childrenPolicy ||
        details.petPolicy != property.petPolicy ||
        details.smokingPolicy != property.smokingPolicy ||
        details.starRating != property.starRating ||
        details.cancellationPolicy != property.cancellationPolicy ||
        details.freeCancellation != (property.freeCancellation ?? false) ||
        details.parkingAvailable != (property.parkingAvailable ?? false) ||
        details.parkingFree != (property.parkingFree ?? false) ||
        details.parkingDescription != property.parkingDescription ||
        details.wifiAvailable != (property.wifiAvailable ?? false) ||
        details.wifiFree != (property.wifiFree ?? false) ||
        details.internetDescription != property.internetDescription ||
        !_sameList(details.languages, property.languages) ||
        !_sameList(details.paymentMethods, property.paymentMethods) ||
        property.starRating == null;
  }

  bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _amenitiesChanged(PartnerPropertyDetail property) {
    final before = property.amenities.map((amenity) => amenity.id).toSet();
    return before.length != _amenityIds.length ||
        !before.containsAll(_amenityIds);
  }

  PartnerPropertyDetail? _fail(ApiFailure? failure) {
    _failure = failure;
    return null;
  }

  String? _clean(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  double? _number(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : double.tryParse(trimmed);
  }
}
