import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferenceStorage {
  static const _localeCode = 'ui_locale_code';
  static const _tripReminders = 'trip_reminders_enabled';
  static const _bookingUpdates = 'booking_updates_enabled';
  static const _travelTips = 'travel_tips_enabled';
  static const _reduceMotion = 'reduce_motion_enabled';

  Future<Locale?> locale() async {
    final code = (await SharedPreferences.getInstance()).getString(_localeCode);
    if (code == null || code.isEmpty) return null;
    if (code != 'en' && code != 'vi') return null;
    return Locale(code);
  }

  Future<void> saveLocale(Locale? locale) async {
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_localeCode);
      return;
    }
    await prefs.setString(_localeCode, locale.languageCode);
  }

  Future<bool> tripReminders() => _bool(_tripReminders, fallback: true);
  Future<bool> bookingUpdates() => _bool(_bookingUpdates, fallback: true);
  Future<bool> travelTips() => _bool(_travelTips, fallback: false);
  Future<bool> reduceMotion() => _bool(_reduceMotion, fallback: false);

  Future<void> saveTripReminders(bool value) =>
      _saveBool(_tripReminders, value);
  Future<void> saveBookingUpdates(bool value) =>
      _saveBool(_bookingUpdates, value);
  Future<void> saveTravelTips(bool value) => _saveBool(_travelTips, value);
  Future<void> saveReduceMotion(bool value) => _saveBool(_reduceMotion, value);

  Future<bool> _bool(String key, {required bool fallback}) async =>
      (await SharedPreferences.getInstance()).getBool(key) ?? fallback;

  Future<void> _saveBool(String key, bool value) async =>
      (await SharedPreferences.getInstance()).setBool(key, value);
}
