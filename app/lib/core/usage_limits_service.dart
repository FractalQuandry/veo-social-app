import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks and enforces daily usage limits for content generation
class UsageLimitsService extends ChangeNotifier {
  UsageLimitsService() {
    _loadUsage();
  }

  static const int maxVideosPerDay = 3;
  static const int maxImagesPerDay = 10;

  static const String _lastResetKey = 'usage_limits_last_reset';
  static const String _videosUsedKey = 'usage_limits_videos_used';
  static const String _imagesUsedKey = 'usage_limits_images_used';

  int _videosUsedToday = 0;
  int _imagesUsedToday = 0;

  int get videosUsedToday => _videosUsedToday;
  int get imagesUsedToday => _imagesUsedToday;
  int get videosRemaining => maxVideosPerDay - _videosUsedToday;
  int get imagesRemaining => maxImagesPerDay - _imagesUsedToday;

  bool get canGenerateVideo => _videosUsedToday < maxVideosPerDay;
  bool get canGenerateImage => _imagesUsedToday < maxImagesPerDay;

  Future<void> _loadUsage() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if we need to reset (new day)
    final lastResetStr = prefs.getString(_lastResetKey);
    final today = _getTodayDateString();

    if (lastResetStr != today) {
      // New day - reset counters
      _videosUsedToday = 0;
      _imagesUsedToday = 0;
      await _saveUsage();
    } else {
      // Same day - load existing usage
      _videosUsedToday = prefs.getInt(_videosUsedKey) ?? 0;
      _imagesUsedToday = prefs.getInt(_imagesUsedKey) ?? 0;
    }
    notifyListeners();
  }

  Future<void> _saveUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayDateString();

    await prefs.setString(_lastResetKey, today);
    await prefs.setInt(_videosUsedKey, _videosUsedToday);
    await prefs.setInt(_imagesUsedKey, _imagesUsedToday);
  }

  /// Record video generation and check if within limits
  Future<bool> recordVideoGeneration() async {
    await _loadUsage(); // Ensure we have latest data

    if (!canGenerateVideo) {
      return false;
    }

    _videosUsedToday++;
    await _saveUsage();
    notifyListeners();
    return true;
  }

  /// Record image generation and check if within limits
  Future<bool> recordImageGeneration() async {
    await _loadUsage(); // Ensure we have latest data

    if (!canGenerateImage) {
      return false;
    }

    _imagesUsedToday++;
    await _saveUsage();
    notifyListeners();
    return true;
  }

  /// Get time until quota resets
  Duration getTimeUntilReset() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return tomorrow.difference(now);
  }

  /// Get a formatted string for time until reset
  String getResetTimeString() {
    final duration = getTimeUntilReset();
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String _getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Reset usage (for testing purposes)
  Future<void> resetUsage() async {
    _videosUsedToday = 0;
    _imagesUsedToday = 0;
    await _saveUsage();
    notifyListeners();
  }
}

final usageLimitsServiceProvider =
    ChangeNotifierProvider<UsageLimitsService>((ref) {
  return UsageLimitsService();
});
