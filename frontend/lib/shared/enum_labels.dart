import '../l10n/app_localizations.dart';

// ── Shared localized enum labels ─────────────────────────────────────────────
// Raw backend UPPER-token → localized label, with a humanized fallback for any
// unrecognised token (never throws). These map the personalization dimension
// enums (TravelStyle / WeatherType / BudgetLevel / CrowdLevel / AccessibilityLevel)
// shared by the demo Place-detail screen and the real Interest Profile (UI-52).
// The localization strings themselves are the single source of truth in the ARB
// files; this file only routes a wire token to the right key.

/// Title-cases an unknown UPPER_SNAKE token as a last-resort human label.
String humanizeEnumToken(String raw) {
  final cleaned = raw.replaceAll('_', ' ').trim().toLowerCase();
  if (cleaned.isEmpty) return raw;
  return cleaned
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

/// `TravelStyle` (SOLO/COUPLE/FAMILY/FRIENDS/BUSINESS/BACKPACKER/LUXURY).
String travelStyleLabel(AppLocalizations l10n, String raw) {
  switch (raw.toUpperCase()) {
    case 'SOLO':
      return l10n.travelStyleSolo;
    case 'COUPLE':
      return l10n.travelStyleCouple;
    case 'FAMILY':
      return l10n.travelStyleFamily;
    case 'FRIENDS':
      return l10n.travelStyleFriends;
    case 'BUSINESS':
      return l10n.travelStyleBusiness;
    case 'BACKPACKER':
      return l10n.travelStyleBackpacker;
    case 'LUXURY':
      return l10n.travelStyleLuxury;
    default:
      return humanizeEnumToken(raw);
  }
}

/// `WeatherType` (SUNNY/CLOUDY/RAINY/COOL/ANY).
String weatherTypeLabel(AppLocalizations l10n, String raw) {
  switch (raw.toUpperCase()) {
    case 'SUNNY':
      return l10n.weatherSunny;
    case 'CLOUDY':
      return l10n.weatherCloudy;
    case 'RAINY':
      return l10n.weatherRainy;
    case 'COOL':
      return l10n.weatherCool;
    case 'ANY':
      return l10n.weatherAny;
    default:
      return humanizeEnumToken(raw);
  }
}

/// `BudgetLevel` (FREE/LOW/MEDIUM/HIGH/LUXURY).
String budgetLevelLabel(AppLocalizations l10n, String raw) {
  switch (raw.toUpperCase()) {
    case 'FREE':
      return l10n.budgetFree;
    case 'LOW':
      return l10n.budgetLow;
    case 'MEDIUM':
      return l10n.budgetMedium;
    case 'HIGH':
      return l10n.budgetHigh;
    case 'LUXURY':
      return l10n.budgetLuxury;
    default:
      return humanizeEnumToken(raw);
  }
}

/// `CrowdLevel` (LOW/MEDIUM/HIGH).
String crowdLevelLabel(AppLocalizations l10n, String raw) {
  switch (raw.toUpperCase()) {
    case 'LOW':
      return l10n.crowdLow;
    case 'MEDIUM':
      return l10n.crowdMedium;
    case 'HIGH':
      return l10n.crowdHigh;
    default:
      return humanizeEnumToken(raw);
  }
}

/// `AccessibilityLevel` (LOW/MEDIUM/HIGH).
String accessibilityLevelLabel(AppLocalizations l10n, String raw) {
  switch (raw.toUpperCase()) {
    case 'LOW':
      return l10n.accessibilityLow;
    case 'MEDIUM':
      return l10n.accessibilityMedium;
    case 'HIGH':
      return l10n.accessibilityHigh;
    default:
      return humanizeEnumToken(raw);
  }
}
