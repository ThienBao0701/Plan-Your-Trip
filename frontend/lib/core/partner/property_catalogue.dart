/// The admin-managed reference data a property is built from, and the one
/// implementation of the location cascade.
///
/// Phase C put this inside `PartnerPropertyEditorState`. Phase D needs exactly
/// the same behaviour in the onboarding wizard, so it lives here and both use
/// it — one place that decides what a property may be classified as, where it
/// may sit, and which amenities describe it. Nothing here invents an option:
/// every id comes from `GET /api/categories`, `/api/locations/...` and
/// `/api/amenities`, and the backend validates each one again on write.
library;

import 'package:flutter/foundation.dart';

import '../network/api_client.dart';
import 'partner_property_form_models.dart';

enum PropertyCatalogueStatus {
  /// Nothing requested yet.
  idle,
  loading,
  ready,

  /// The catalogue could not be read. A form must not be shown on top of this:
  /// without the catalogue it could only offer ids the client invented.
  error,
}

class PropertyCatalogue extends ChangeNotifier {
  final ApiClient api;

  PropertyCatalogue({required this.api});

  PropertyCatalogueStatus _status = PropertyCatalogueStatus.idle;
  PropertyCatalogueStatus get status => _status;
  bool get isReady => _status == PropertyCatalogueStatus.ready;

  List<PropertyCategoryOption> _categories = const [];
  List<PropertyAmenityOption> _amenities = const [];
  List<PropertyLocationOption> _countries = const [];
  List<PropertyLocationOption> _provinces = const [];
  List<PropertyLocationOption> _areas = const [];

  int? _countryId;
  int? _provinceId;
  int? _areaId;
  bool _touched = false;
  bool _loadingChildren = false;

  /// The accommodation roots a property may be classified under. Anything the
  /// backend does not type as ACCOMMODATION is not offered, because it would be
  /// refused.
  List<PropertyCategoryOption> get categoryOptions => _categories
      .where((c) => c.isAccommodation && c.active && c.isRoot)
      .toList(growable: false);

  /// The direct children of [categoryId] — the specific property type.
  List<PropertyCategoryOption> subcategoryOptions(int? categoryId) {
    if (categoryId == null) return const [];
    return _categories
        .where((c) => c.active && c.isAccommodation && c.parentId == categoryId)
        .toList(growable: false);
  }

  List<PropertyLocationOption> get countryOptions =>
      _countries.where((unit) => unit.active).toList(growable: false);
  List<PropertyLocationOption> get provinceOptions =>
      _provinces.where((unit) => unit.active).toList(growable: false);

  /// Only units a property may actually sit in (active PROVINCE, CITY or AREA).
  List<PropertyLocationOption> get areaOptions =>
      _areas.where((unit) => unit.canHoldProperty).toList(growable: false);

  /// The amenities that describe a property, grouped by the backend's own
  /// `groupName`. Room-level and other place-type groups are not offered.
  Map<String, List<PropertyAmenityOption>> get amenityGroups {
    final groups = <String, List<PropertyAmenityOption>>{};
    for (final amenity in _amenities.where((a) => a.describesProperty)) {
      groups.putIfAbsent(amenity.groupName ?? '', () => []).add(amenity);
    }
    return groups;
  }

  /// Every property-level amenity, flat — for resolving a selected id to a name.
  List<PropertyAmenityOption> get amenityOptions =>
      _amenities.where((a) => a.describesProperty).toList(growable: false);

  int? get countryId => _countryId;
  int? get provinceId => _provinceId;
  int? get areaId => _areaId;
  bool get isLoadingChildren => _loadingChildren;

  /// True once a province or area was actually picked here — as opposed to the
  /// only country being pre-selected, which is not the partner choosing a place.
  bool get hasPickedLocation => _touched;

  /// The unit a property would be placed in: the area when one is chosen,
  /// otherwise the province or city. Null until one is picked.
  int? get pickedUnitId => _areaId ?? _provinceId;

  /// The label of the picked unit, for the "selected path" summary.
  String? get pickedUnitLabel {
    final id = pickedUnitId;
    if (id == null) return null;
    for (final unit in [..._areas, ..._provinces]) {
      if (unit.id == id) return unit.label;
    }
    return null;
  }

  /// The country → province/city → area path as chosen so far, for display.
  List<String> get pickedPath {
    final path = <String>[];
    for (final entry in [
      (_countryId, _countries),
      (_provinceId, _provinces),
      (_areaId, _areas),
    ]) {
      final id = entry.$1;
      if (id == null) continue;
      for (final unit in entry.$2) {
        if (unit.id == id) path.add(unit.name);
      }
    }
    return path;
  }

  /// Loads categories, amenities and the top of the location tree.
  ///
  /// When exactly one country exists — the common case — it is pre-selected so
  /// the partner is not asked to make a choice with one option. That is
  /// deliberately **not** counted as picking a location.
  Future<void> load() async {
    _status = PropertyCatalogueStatus.loading;
    notifyListeners();

    final categories = await api.getPropertyCategories();
    final amenities = await api.getPropertyAmenities();
    final countries = await api.getLocationRoots();

    if (!categories.success || !amenities.success || !countries.success) {
      _status = PropertyCatalogueStatus.error;
      notifyListeners();
      return;
    }

    _categories = categories.data ?? const [];
    _amenities = amenities.data ?? const [];
    _countries = countries.data ?? const [];
    _status = PropertyCatalogueStatus.ready;
    notifyListeners();

    if (countryOptions.length == 1 && _countryId == null) {
      await _selectCountry(countryOptions.first.id, touched: false);
    }
  }

  Future<void> selectCountry(int? id) => _selectCountry(id, touched: true);

  Future<void> _selectCountry(int? id, {required bool touched}) async {
    _countryId = id;
    // A parent change invalidates everything below it: a province from another
    // country is not a location, it is a mistake waiting to be saved.
    _provinceId = null;
    _areaId = null;
    _provinces = const [];
    _areas = const [];
    if (touched) _touched = true;
    if (id == null) {
      notifyListeners();
      return;
    }
    await _loadChildren(id, into: (units) => _provinces = units);
  }

  Future<void> selectProvince(int? id) async {
    _provinceId = id;
    _areaId = null;
    _areas = const [];
    _touched = true;
    if (id == null) {
      notifyListeners();
      return;
    }
    await _loadChildren(id, into: (units) => _areas = units);
  }

  void selectArea(int? id) {
    _areaId = id;
    _touched = true;
    notifyListeners();
  }

  Future<void> _loadChildren(
    int parentId, {
    required void Function(List<PropertyLocationOption>) into,
  }) async {
    _loadingChildren = true;
    notifyListeners();
    final result = await api.getLocationChildren(parentId);
    _loadingChildren = false;
    // A level that failed to load leaves an empty list: the form then has
    // nothing to offer rather than an option that does not exist.
    into(result.success ? (result.data ?? const []) : const []);
    notifyListeners();
  }
}
