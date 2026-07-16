import 'package:flutter/material.dart';

import '../../design/app_colors.dart';
import '../../l10n/app_localizations.dart';

enum TripExpenseCategory {
  accommodation,
  food,
  transport,
  attraction,
  shopping,
  health,
  visa,
  insurance,
  other,
}

extension TripExpenseCategoryData on TripExpenseCategory {
  String get code {
    switch (this) {
      case TripExpenseCategory.accommodation:
        return 'ACCOMMODATION';
      case TripExpenseCategory.food:
        return 'FOOD';
      case TripExpenseCategory.transport:
        return 'TRANSPORT';
      case TripExpenseCategory.attraction:
        return 'ATTRACTION';
      case TripExpenseCategory.shopping:
        return 'SHOPPING';
      case TripExpenseCategory.health:
        return 'HEALTH';
      case TripExpenseCategory.visa:
        return 'VISA';
      case TripExpenseCategory.insurance:
        return 'INSURANCE';
      case TripExpenseCategory.other:
        return 'OTHER';
    }
  }

  IconData get icon {
    switch (this) {
      case TripExpenseCategory.accommodation:
        return Icons.hotel_rounded;
      case TripExpenseCategory.food:
        return Icons.restaurant_rounded;
      case TripExpenseCategory.transport:
        return Icons.directions_car_rounded;
      case TripExpenseCategory.attraction:
        return Icons.local_activity_rounded;
      case TripExpenseCategory.shopping:
        return Icons.shopping_bag_rounded;
      case TripExpenseCategory.health:
        return Icons.local_hospital_rounded;
      case TripExpenseCategory.visa:
        return Icons.badge_rounded;
      case TripExpenseCategory.insurance:
        return Icons.verified_user_rounded;
      case TripExpenseCategory.other:
        return Icons.receipt_long_rounded;
    }
  }

  Color get color {
    switch (this) {
      case TripExpenseCategory.accommodation:
        return AppColors.ocean;
      case TripExpenseCategory.food:
        return AppColors.success;
      case TripExpenseCategory.transport:
        return AppColors.coral;
      case TripExpenseCategory.attraction:
        return AppColors.violet;
      case TripExpenseCategory.shopping:
        return AppColors.warning;
      case TripExpenseCategory.health:
        return AppColors.danger;
      case TripExpenseCategory.visa:
        return AppColors.turquoise600;
      case TripExpenseCategory.insurance:
        return AppColors.ocean700;
      case TripExpenseCategory.other:
        return AppColors.textSecondary;
    }
  }

  String label(AppLocalizations l10n) {
    switch (this) {
      case TripExpenseCategory.accommodation:
        return l10n.expenseCategoryAccommodation;
      case TripExpenseCategory.food:
        return l10n.expenseCategoryFood;
      case TripExpenseCategory.transport:
        return l10n.expenseCategoryTransport;
      case TripExpenseCategory.attraction:
        return l10n.expenseCategoryAttraction;
      case TripExpenseCategory.shopping:
        return l10n.expenseCategoryShopping;
      case TripExpenseCategory.health:
        return l10n.expenseCategoryHealth;
      case TripExpenseCategory.visa:
        return l10n.expenseCategoryVisa;
      case TripExpenseCategory.insurance:
        return l10n.expenseCategoryInsurance;
      case TripExpenseCategory.other:
        return l10n.expenseCategoryOther;
    }
  }

  static TripExpenseCategory fromCode(String code) {
    final normalized = code.trim().toUpperCase();
    for (final category in TripExpenseCategory.values) {
      if (category.code == normalized) return category;
    }
    switch (code.trim().toLowerCase()) {
      case 'hotel':
        return TripExpenseCategory.accommodation;
      case 'food':
        return TripExpenseCategory.food;
      case 'transport':
        return TripExpenseCategory.transport;
      case 'activity':
      case 'entertainment':
        return TripExpenseCategory.attraction;
      case 'shopping':
        return TripExpenseCategory.shopping;
      default:
        return TripExpenseCategory.other;
    }
  }
}
