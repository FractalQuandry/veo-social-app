import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/dto/feed_item_dto.dart';

/// Different display styles for the feed
enum FeedDisplayStyle {
  fullscreen, // Original TikTok-like full-screen experience (default)
  card,
  compact,
  masonry,
  minimal;

  String get displayName {
    switch (this) {
      case FeedDisplayStyle.fullscreen:
        return 'Full Screen';
      case FeedDisplayStyle.card:
        return 'Card Grid';
      case FeedDisplayStyle.compact:
        return 'Compact List';
      case FeedDisplayStyle.masonry:
        return 'Masonry';
      case FeedDisplayStyle.minimal:
        return 'Minimal';
    }
  }

  String get description {
    switch (this) {
      case FeedDisplayStyle.fullscreen:
        return 'Immersive full-screen scrolling (Original)';
      case FeedDisplayStyle.card:
        return 'Large cards with media front and center';
      case FeedDisplayStyle.compact:
        return 'Smaller thumbnails, more posts visible';
      case FeedDisplayStyle.masonry:
        return 'Staggered grid with varying heights';
      case FeedDisplayStyle.minimal:
        return 'Clean, minimal design with whitespace';
    }
  }
}

/// Manages user preferences for feed display styles per feed type
class FeedDisplayPreferences extends ChangeNotifier {
  FeedDisplayPreferences() {
    _loadPreferences();
  }

  static const String _keyPrefix = 'feed_display_style_';

  final Map<FeedType, FeedDisplayStyle> _preferences = {};

  /// Get the display style for a specific feed type
  FeedDisplayStyle getStyle(FeedType feedType) {
    return _preferences[feedType] ?? FeedDisplayStyle.fullscreen;
  }

  /// Set the display style for a specific feed type
  Future<void> setStyle(FeedType feedType, FeedDisplayStyle style) async {
    _preferences[feedType] = style;
    notifyListeners();
    await _savePreference(feedType, style);
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    for (final feedType in FeedType.values) {
      final key = '$_keyPrefix${feedType.name}';
      final styleName = prefs.getString(key);
      if (styleName != null) {
        try {
          _preferences[feedType] = FeedDisplayStyle.values
              .firstWhere((style) => style.name == styleName);
        } catch (_) {
          // Invalid style name, use default
          _preferences[feedType] = FeedDisplayStyle.card;
        }
      }
    }
    notifyListeners();
  }

  Future<void> _savePreference(
      FeedType feedType, FeedDisplayStyle style) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix${feedType.name}';
    await prefs.setString(key, style.name);
  }

  /// Reset a specific feed preference to default
  Future<void> resetFeed(FeedType feedType) async {
    _preferences.remove(feedType);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix${feedType.name}';
    await prefs.remove(key);
  }

  /// Reset all preferences to default
  Future<void> resetAll() async {
    _preferences.clear();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    for (final feedType in FeedType.values) {
      final key = '$_keyPrefix${feedType.name}';
      await prefs.remove(key);
    }
  }
}

final feedDisplayPreferencesProvider =
    ChangeNotifierProvider<FeedDisplayPreferences>((ref) {
  return FeedDisplayPreferences();
});
