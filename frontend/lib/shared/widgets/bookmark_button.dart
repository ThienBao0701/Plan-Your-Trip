import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_colors.dart';
import '../../features/auth/login_screen.dart';
import '../../l10n/app_localizations.dart';
import 'glass_widgets.dart';

/// A single, mode-aware bookmark (save-to-wishlist) toggle shared across every
/// screen that exposes a bookmark affordance (Home, Explore, Place Detail,
/// Hotel Search, Category Discovery, and the Wishlist tab).
///
/// - **Demo Mode**: toggles the local demo wishlist synchronously; zero HTTP.
/// - **Real Mode**: calls the backend wishlist API, disables itself while the
///   request is in flight, and never flips the icon before the backend
///   confirms. A 401 shows the shared session-expired sheet — it never logs the
///   user out or clears state.
///
/// Because it reads its saved/in-flight state from [AppState] (an
/// [AppScope]-provided [ChangeNotifier]), a confirmed change on one instance
/// automatically updates every other mounted bookmark control for the same
/// place.
class BookmarkButton extends StatefulWidget {
  final int placeId;
  final String placeName;

  /// Icon size; defaults to the framework's [IconButton] default when null.
  final double? iconSize;

  /// Colour when saved (defaults to [AppColors.ocean]) and when not saved
  /// (defaults to the ambient icon theme).
  final Color? savedColor;
  final Color? unsavedColor;

  const BookmarkButton({
    super.key,
    required this.placeId,
    required this.placeName,
    this.iconSize,
    this.savedColor,
    this.unsavedColor,
  });

  @override
  State<BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends State<BookmarkButton> {
  @override
  void initState() {
    super.initState();
    // In Real Mode, make sure the wishlist membership is known so this icon
    // renders accurately. No-op if already loaded/loading, and never in demo.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final app = AppScope.of(context);
      if (!app.demoMode) app.ensureRealWishlistLoaded();
    });
  }

  Future<void> _toggle() async {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final isDemo = app.demoMode;
    final outcome = await app.toggleBookmark(widget.placeId);
    if (!mounted) return;
    if (outcome == BookmarkOutcome.sessionExpired) {
      _showReauth();
      return;
    }
    final message = _messageFor(l10n, outcome, isDemo);
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _showReauth() {
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

  String? _messageFor(
    AppLocalizations l10n,
    BookmarkOutcome outcome,
    bool isDemo,
  ) {
    switch (outcome) {
      case BookmarkOutcome.added:
        return isDemo
            ? l10n.savedPlacesSavedMessage(widget.placeName)
            : l10n.wishlistBookmarkAddedMessage(widget.placeName);
      case BookmarkOutcome.removed:
        return isDemo
            ? l10n.savedPlacesRemovedPlace(widget.placeName)
            : l10n.wishlistBookmarkRemovedMessage(widget.placeName);
      case BookmarkOutcome.duplicate:
        return l10n.savedPlacesAlreadySavedMessage(widget.placeName);
      case BookmarkOutcome.notFound:
        return l10n.savedPlacesMissingMessage;
      case BookmarkOutcome.notPublished:
        return l10n.wishlistBookmarkNotPublishedMessage(widget.placeName);
      case BookmarkOutcome.network:
        return l10n.wishlistBookmarkNetworkMessage;
      case BookmarkOutcome.serverError:
        return l10n.wishlistBookmarkServerErrorMessage;
      case BookmarkOutcome.forbidden:
        return l10n.savedPlacesActionForbiddenMessage;
      case BookmarkOutcome.invalid:
      case BookmarkOutcome.unavailable:
        return l10n.wishlistBookmarkUnavailableMessage;
      case BookmarkOutcome.sessionExpired:
        return null; // handled by the session-expired sheet
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final saved = app.isPlaceBookmarked(widget.placeId);
    final inFlight = app.isWishlistActionInFlight(widget.placeId);
    final toggleLabel = saved
        ? l10n.savedPlacesRemoveSemantic(widget.placeName)
        : l10n.savedPlacesSaveSemantic(widget.placeName);
    final label = inFlight
        ? l10n.wishlistBookmarkSavingSemantic(widget.placeName)
        : toggleLabel;
    final size = widget.iconSize;
    final Widget icon = inFlight
        ? SizedBox(
            width: size ?? 20,
            height: size ?? 20,
            child: const CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(
            saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            color: saved
                ? (widget.savedColor ?? AppColors.ocean)
                : widget.unsavedColor,
            size: size,
          );
    return Semantics(
      button: true,
      toggled: saved,
      enabled: !inFlight,
      label: label,
      child: IconButton(
        tooltip: label,
        onPressed: inFlight ? null : _toggle,
        icon: icon,
      ),
    );
  }
}
