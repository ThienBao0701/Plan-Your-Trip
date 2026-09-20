import 'dart:convert';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Client-side form rules, matching the backend's own (`AccountPassword`,
/// `AuthDtos`) so a form does not submit something the server will certainly
/// refuse.
///
/// They are a convenience, never an authority: every rule is enforced again
/// server-side, and a field the server refuses anyway is marked from its
/// `fieldErrors`.
class AuthValidators {
  const AuthValidators._();

  /// Backend: `@AccountPassword` — at least 8 characters, at most 72 bytes.
  static const int passwordMinCharacters = 8;
  static const int passwordMaxBytes = 72;

  /// Backend: `@Size(max = 120)` on `fullName`.
  static const int fullNameMaxLength = 120;

  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? fullName(AppLocalizations l10n, String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return l10n.authValidationName;
    if (name.length > fullNameMaxLength) return l10n.authValidationName;
    return null;
  }

  static String? email(AppLocalizations l10n, String? value) =>
      _email.hasMatch(value?.trim() ?? '') ? null : l10n.authValidationEmail;

  /// A password being set: length rules apply.
  static String? newPassword(AppLocalizations l10n, String? value) {
    final password = value ?? '';
    if (password.isEmpty) return l10n.authValidationPasswordRequired;
    // Code points, so an emoji or a Vietnamese character counts once.
    if (password.runes.length < passwordMinCharacters) {
      return l10n.authValidationPasswordMin;
    }
    if (utf8.encode(password).length > passwordMaxBytes) {
      return l10n.authValidationPasswordMax;
    }
    return null;
  }

  /// A password being presented for sign-in or re-authentication: required only.
  static String? existingPassword(AppLocalizations l10n, String? value) =>
      (value ?? '').isEmpty ? l10n.authValidationPasswordRequired : null;

  static String? confirmation(
    AppLocalizations l10n,
    String? value,
    String password,
  ) {
    if ((value ?? '').isEmpty) return l10n.authValidationConfirmPassword;
    if (value != password) return l10n.authValidationPasswordMismatch;
    return null;
  }

  /// A one-time token pasted from an account link.
  static String? linkToken(AppLocalizations l10n, String? value) =>
      (value?.trim() ?? '').isEmpty ? l10n.authValidationTokenRequired : null;
}

/// The show/hide control shared by every password field.
class PasswordVisibilityToggle extends StatelessWidget {
  final bool visible;
  final ValueChanged<bool> onChanged;

  /// Uses the "confirm password" labels, which are separate strings for screen
  /// readers that announce both fields on one form.
  final bool confirmation;

  const PasswordVisibilityToggle({
    super.key,
    required this.visible,
    required this.onChanged,
    this.confirmation = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = confirmation
        ? (visible ? l10n.authHideConfirmPassword : l10n.authShowConfirmPassword)
        : (visible ? l10n.authHidePassword : l10n.authShowPassword);
    return Semantics(
      button: true,
      label: label,
      child: IconButton(
        tooltip: label,
        icon: Icon(
          visible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
        ),
        onPressed: () => onChanged(!visible),
      ),
    );
  }
}
