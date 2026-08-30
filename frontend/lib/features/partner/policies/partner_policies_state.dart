import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/partner/partner_models.dart';
import '../../../core/partner/partner_policy_models.dart';
import '../../../core/partner/partner_state.dart';

/// Outcome of a policy or settings save.
enum PartnerPolicySaveResult {
  success,
  unauthorized,

  /// 403. For workspace settings this is the real team-role refusal
  /// (`SETTINGS_WRITE_ROLES`); for property policies it means the profile is
  /// no longer approved.
  forbidden,

  /// Uniform 404 — the property is unknown or not owned, or the partner profile
  /// is gone.
  notFound,

  /// 400 from bean validation, e.g. `"checkIn: must not be null"`.
  validation,
  failed,

  /// May have been committed before the connection dropped.
  uncertain,
}

/// Where the Policies module stands.
enum PartnerPoliciesStatus {
  idle,
  noProperties,
  noPropertySelected,
  loading,
  ready,
  unauthorized,
  forbidden,

  /// 404 — property not available to this account.
  notFound,
  error,
}

/// State for the Partner Policies module.
///
/// Feature-scoped `ChangeNotifier`, same paradigm as C1–C5. [PartnerState]
/// keeps workspace identity, team role and the selected property, and is
/// neither extended nor duplicated.
///
/// ## Two domains, two authorization rules
///
/// The screen shows both, but they are **not** one object:
///
///  * **Property policies** — `PUT /hotels/{id}/policies`, scoped to the
///    selected property, **owner-only** because `PartnerPropertyService` is not
///    team-aware.
///  * **Workspace settings** — `PUT /settings`, partner-wide, writable by
///    **OWNER or MANAGER** via the one team-aware resolver in the API.
///
/// Each keeps its own draft, dirty flag and save state so a refusal on one can
/// never be mistaken for a refusal on the other.
class PartnerPoliciesState extends ChangeNotifier {
  final ApiClient api;

  PartnerPoliciesState({required this.api});

  PartnerPoliciesStatus _status = PartnerPoliciesStatus.idle;
  String? _errorMessage;
  int? _loadedPropertyId;

  PartnerPropertyPolicies? _savedPolicies;
  PartnerPropertyPolicies? _draftPolicies;
  bool _savingPolicies = false;
  String? _policiesErrorMessage;

  PartnerWorkspaceSettings? _savedSettings;
  PartnerWorkspaceSettings? _draftSettings;
  bool _savingSettings = false;
  String? _settingsErrorMessage;

  /// Non-null when the settings request itself failed, so the panel can say
  /// what happened instead of silently showing nothing.
  ApiErrorKind? _settingsLoadErrorKind;

  int _loadToken = 0;

  PartnerPoliciesStatus get status => _status;
  String? get errorMessage => _errorMessage;
  int? get loadedPropertyId => _loadedPropertyId;

  PartnerPropertyPolicies? get savedPolicies => _savedPolicies;
  PartnerPropertyPolicies? get draftPolicies => _draftPolicies;
  bool get isSavingPolicies => _savingPolicies;
  String? get policiesErrorMessage => _policiesErrorMessage;

  PartnerWorkspaceSettings? get savedSettings => _savedSettings;
  PartnerWorkspaceSettings? get draftSettings => _draftSettings;
  bool get isSavingSettings => _savingSettings;
  String? get settingsErrorMessage => _settingsErrorMessage;
  ApiErrorKind? get settingsLoadErrorKind => _settingsLoadErrorKind;

  bool get isLoading => _status == PartnerPoliciesStatus.loading;
  bool get isReady => _status == PartnerPoliciesStatus.ready;
  bool get isRetryable => _status == PartnerPoliciesStatus.error;

  /// The property-policy draft differs from what the server holds.
  bool get policiesDirty {
    final saved = _savedPolicies;
    final draft = _draftPolicies;
    if (saved == null || draft == null) return false;
    return !saved.sameAs(draft);
  }

  /// The settings draft differs from what the server holds.
  bool get settingsDirty {
    final saved = _savedSettings;
    final draft = _draftSettings;
    if (saved == null || draft == null) return false;
    return !saved.sameAs(draft);
  }

  /// The backend refuses a policy write without both times, so the form knows
  /// before it asks.
  bool get canSubmitPolicies => _draftPolicies?.canSubmit ?? false;

  /// Loads the selected property's policies and the workspace settings.
  ///
  /// The two are independent requests: settings failing must not blank the
  /// policy form, and vice versa. Only the property request decides the
  /// screen-level status, because it is the one scoped to the selection.
  Future<void> load(PartnerState partner, int? propertyId) async {
    if (partner.properties.isEmpty) {
      _finishWithoutData(PartnerPoliciesStatus.noProperties);
      return;
    }
    if (propertyId == null) {
      _finishWithoutData(PartnerPoliciesStatus.noPropertySelected);
      return;
    }
    if (!partner.properties.any((p) => p.id == propertyId)) {
      // Never ask for a property the workspace does not authorize.
      _finishWithoutData(PartnerPoliciesStatus.notFound);
      return;
    }

    final token = ++_loadToken;
    _status = PartnerPoliciesStatus.loading;
    _errorMessage = null;
    _policiesErrorMessage = null;
    _settingsErrorMessage = null;
    if (propertyId != _loadedPropertyId) {
      // A draft belonging to another property must never survive the switch.
      _savedPolicies = null;
      _draftPolicies = null;
    }
    notifyListeners();

    final results = await Future.wait([
      api.getPartnerProperty(propertyId),
      api.getPartnerWorkspaceSettings(),
    ]);
    if (token != _loadToken) return;

    final propertyResult = results[0] as CollectionApiResult<dynamic>;
    final settingsResult =
        results[1] as CollectionApiResult<PartnerWorkspaceSettings>;

    if (!propertyResult.success || propertyResult.data == null) {
      _savedPolicies = null;
      _draftPolicies = null;
      _loadedPropertyId = propertyId;
      _status = switch (propertyResult.errorKind) {
        ApiErrorKind.unauthorized => PartnerPoliciesStatus.unauthorized,
        ApiErrorKind.forbidden => PartnerPoliciesStatus.forbidden,
        ApiErrorKind.notFound => PartnerPoliciesStatus.notFound,
        _ => PartnerPoliciesStatus.error,
      };
      _errorMessage = propertyResult.message;
      notifyListeners();
      return;
    }

    final detail = propertyResult.data!;
    final policies = PartnerPropertyPolicies(
      checkIn: detail.checkIn,
      checkOut: detail.checkOut,
      childrenPolicy: detail.childrenPolicy,
      petPolicy: detail.petPolicy,
      smokingPolicy: detail.smokingPolicy,
    );
    _savedPolicies = policies;
    _draftPolicies = policies;
    _loadedPropertyId = propertyId;

    if (settingsResult.success && settingsResult.data != null) {
      _savedSettings = settingsResult.data;
      _draftSettings = settingsResult.data;
      _settingsLoadErrorKind = null;
    } else {
      _savedSettings = null;
      _draftSettings = null;
      _settingsLoadErrorKind = settingsResult.errorKind ?? ApiErrorKind.network;
    }

    _status = PartnerPoliciesStatus.ready;
    _errorMessage = null;
    notifyListeners();
  }

  // ── Property policy draft ────────────────────────────────────────────────

  void setCheckIn(String value) {
    final draft = _draftPolicies;
    if (draft == null) return;
    _draftPolicies = draft.copyWith(checkIn: value);
    _policiesErrorMessage = null;
    notifyListeners();
  }

  void setCheckOut(String value) {
    final draft = _draftPolicies;
    if (draft == null) return;
    _draftPolicies = draft.copyWith(checkOut: value);
    _policiesErrorMessage = null;
    notifyListeners();
  }

  /// Sets a house rule. An empty string clears it back to null, which the
  /// backend accepts and which is genuinely different from an empty string.
  void setChildrenPolicy(String? value) => _setRule(children: value);
  void setPetPolicy(String? value) => _setRule(pet: value);
  void setSmokingPolicy(String? value) => _setRule(smoking: value);

  void _setRule({String? children, String? pet, String? smoking}) {
    final draft = _draftPolicies;
    if (draft == null) return;
    String? clean(String? v) {
      if (v == null) return null;
      final t = v.trim();
      return t.isEmpty ? null : t;
    }

    _draftPolicies = PartnerPropertyPolicies(
      checkIn: draft.checkIn,
      checkOut: draft.checkOut,
      childrenPolicy: children == null ? draft.childrenPolicy : clean(children),
      petPolicy: pet == null ? draft.petPolicy : clean(pet),
      smokingPolicy: smoking == null ? draft.smokingPolicy : clean(smoking),
    );
    _policiesErrorMessage = null;
    notifyListeners();
  }

  /// Discards the property-policy draft.
  void revertPolicies() {
    if (_savedPolicies == null) return;
    _draftPolicies = _savedPolicies;
    _policiesErrorMessage = null;
    notifyListeners();
  }

  /// `PUT /hotels/{id}/policies` with the complete five-field body.
  Future<PartnerPolicySaveResult> savePolicies() async {
    final propertyId = _loadedPropertyId;
    final draft = _draftPolicies;
    if (propertyId == null || draft == null) {
      return PartnerPolicySaveResult.notFound;
    }
    if (!draft.canSubmit) return PartnerPolicySaveResult.validation;
    if (_savingPolicies) return PartnerPolicySaveResult.failed;

    _savingPolicies = true;
    _policiesErrorMessage = null;
    notifyListeners();

    final result = await api.updatePartnerPolicies(
      propertyId: propertyId,
      policies: draft,
    );

    _savingPolicies = false;

    if (!result.success || result.data == null) {
      _policiesErrorMessage = result.message;
      notifyListeners();
      return switch (result.errorKind) {
        ApiErrorKind.unauthorized => PartnerPolicySaveResult.unauthorized,
        ApiErrorKind.forbidden => PartnerPolicySaveResult.forbidden,
        ApiErrorKind.notFound => PartnerPolicySaveResult.notFound,
        ApiErrorKind.validation => PartnerPolicySaveResult.validation,
        ApiErrorKind.uncertain => PartnerPolicySaveResult.uncertain,
        _ => PartnerPolicySaveResult.failed,
      };
    }

    // Re-read from the server's own answer rather than trusting the draft.
    final detail = result.data!;
    final saved = PartnerPropertyPolicies(
      checkIn: detail.checkIn,
      checkOut: detail.checkOut,
      childrenPolicy: detail.childrenPolicy,
      petPolicy: detail.petPolicy,
      smokingPolicy: detail.smokingPolicy,
    );
    _savedPolicies = saved;
    _draftPolicies = saved;
    _policiesErrorMessage = null;
    notifyListeners();
    return PartnerPolicySaveResult.success;
  }

  // ── Workspace settings draft ─────────────────────────────────────────────

  void toggleSetting(PartnerSettingsToggle toggle, bool value) {
    final draft = _draftSettings;
    if (draft == null) return;
    _draftSettings = switch (toggle) {
      PartnerSettingsToggle.email =>
        draft.copyWith(notificationEmailEnabled: value),
      PartnerSettingsToggle.sms =>
        draft.copyWith(notificationSmsEnabled: value),
      PartnerSettingsToggle.inApp =>
        draft.copyWith(notificationInAppEnabled: value),
      PartnerSettingsToggle.booking =>
        draft.copyWith(bookingNotificationEnabled: value),
      PartnerSettingsToggle.payment =>
        draft.copyWith(paymentNotificationEnabled: value),
      PartnerSettingsToggle.review =>
        draft.copyWith(reviewNotificationEnabled: value),
      PartnerSettingsToggle.promotion =>
        draft.copyWith(promotionNotificationEnabled: value),
    };
    _settingsErrorMessage = null;
    notifyListeners();
  }

  void revertSettings() {
    if (_savedSettings == null) return;
    _draftSettings = _savedSettings;
    _settingsErrorMessage = null;
    notifyListeners();
  }

  /// `PUT /settings` with the complete nine-field body.
  ///
  /// A 403 here is the backend's team-role refusal, which carries its own
  /// explanation ("Your role does not allow you to manage business/notification
  /// settings") — surfaced rather than replaced with a generic message.
  Future<PartnerPolicySaveResult> saveSettings() async {
    final draft = _draftSettings;
    if (draft == null) return PartnerPolicySaveResult.notFound;
    if (_savingSettings) return PartnerPolicySaveResult.failed;

    _savingSettings = true;
    _settingsErrorMessage = null;
    notifyListeners();

    final result = await api.updatePartnerWorkspaceSettings(draft);

    _savingSettings = false;

    if (!result.success || result.data == null) {
      _settingsErrorMessage = result.message;
      notifyListeners();
      return switch (result.errorKind) {
        ApiErrorKind.unauthorized => PartnerPolicySaveResult.unauthorized,
        ApiErrorKind.forbidden => PartnerPolicySaveResult.forbidden,
        ApiErrorKind.notFound => PartnerPolicySaveResult.notFound,
        ApiErrorKind.validation => PartnerPolicySaveResult.validation,
        ApiErrorKind.uncertain => PartnerPolicySaveResult.uncertain,
        _ => PartnerPolicySaveResult.failed,
      };
    }

    _savedSettings = result.data;
    _draftSettings = result.data;
    _settingsErrorMessage = null;
    notifyListeners();
    return PartnerPolicySaveResult.success;
  }

  void reset() {
    _loadToken++;
    _status = PartnerPoliciesStatus.idle;
    _errorMessage = null;
    _loadedPropertyId = null;
    _savedPolicies = null;
    _draftPolicies = null;
    _savingPolicies = false;
    _policiesErrorMessage = null;
    _savedSettings = null;
    _draftSettings = null;
    _savingSettings = false;
    _settingsErrorMessage = null;
    _settingsLoadErrorKind = null;
    notifyListeners();
  }

  void _finishWithoutData(PartnerPoliciesStatus status) {
    _loadToken++;
    _status = status;
    _errorMessage = null;
    _savedPolicies = null;
    _draftPolicies = null;
    _policiesErrorMessage = null;
    _settingsErrorMessage = null;
    notifyListeners();
  }
}

/// UX-only mirror of the backend's two write rules.
///
/// * Property policies: `PartnerPropertyService` is owner-only.
/// * Workspace settings: `SETTINGS_WRITE_ROLES` = OWNER, MANAGER.
///
/// Both fail closed for [PartnerTeamRole.unknown]. Hiding a control is never
/// authorization — the backend re-checks every request.
class PartnerPolicyPermissions {
  const PartnerPolicyPermissions._();

  static bool canEditPropertyPolicies(PartnerTeamRole role) =>
      role == PartnerTeamRole.owner;

  static bool canEditWorkspaceSettings(PartnerTeamRole role) =>
      role.canEditSettings;
}
