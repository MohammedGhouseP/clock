import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_block.dart';
import '../models/user_profile.dart';

/// Wraps SharedPreferences for simple local (on-device) persistence.
///
/// Each day's task blocks are stored under a per-date key so history can be
/// listed independently of "today". Swap this class for a Hive/SQLite/cloud
/// backed implementation later without touching the rest of the app —
/// everything else talks to AppProvider, not to storage directly.
class StorageService {
  static const _profileKey = 'user_profile';
  static const _knownDatesKey = 'known_dates';

  String _dateKey(DateTime date) =>
      'blocks_${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<List<TaskBlock>> loadBlocksForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_dateKey(date));
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => TaskBlock.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveBlocksForDate(DateTime date, List<TaskBlock> blocks) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(blocks.map((b) => b.toJson()).toList());
    await prefs.setString(_dateKey(date), raw);
    await _registerDate(date);
  }

  Future<void> _registerDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final dates = prefs.getStringList(_knownDatesKey) ?? [];
    final key = _dateKey(date);
    if (!dates.contains(key)) {
      dates.add(key);
      await prefs.setStringList(_knownDatesKey, dates);
    }
  }

  Future<List<DateTime>> getAllKnownDates() async {
    final prefs = await SharedPreferences.getInstance();
    final dates = prefs.getStringList(_knownDatesKey) ?? [];
    final parsed = dates.map((k) {
      final datePart = k.replaceFirst('blocks_', '');
      return DateTime.parse(datePart);
    }).toList();
    parsed.sort((a, b) => b.compareTo(a));
    return parsed;
  }

  Future<UserProfile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null) return UserProfile();
    return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }
}
