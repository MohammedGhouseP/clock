import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/task_block.dart';
import '../models/enums.dart';
import '../models/user_profile.dart';
import '../models/daily_report.dart';
import '../services/storage_service.dart';

/// Central app state: today's task blocks, the live ticking timer for
/// whichever block is active, the user's profile, and history access.
///
/// Only one block can be "in progress" at a time — starting a new one
/// automatically pauses whatever was running before it.
class AppProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final _uuid = const Uuid();

  List<TaskBlock> todayBlocks = [];
  UserProfile profile = UserProfile();
  String? activeBlockId;

  Timer? _ticker;
  bool _loaded = false;

  DateTime get today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  bool get isPremium => profile.isPremium;

  Future<void> init() async {
    if (_loaded) return;
    todayBlocks = await _storage.loadBlocksForDate(today);
    profile = await _storage.loadProfile();
    await _refreshProfileTotals();
    final active = todayBlocks.where((b) => b.status == TaskStatus.inProgress);
    if (active.isNotEmpty) {
      activeBlockId = active.first.id;
      _startTicker();
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    await _storage.saveBlocksForDate(today, todayBlocks);
  }

  Future<void> _refreshProfileTotals() async {
    final dates = await _storage.getAllKnownDates();
    if (!dates.any((date) => date == today)) dates.add(today);

    final allBlocks = <TaskBlock>[];
    for (final date in dates) {
      allBlocks.addAll(await _storage.loadBlocksForDate(date));
    }

    profile.totalTasksCompletedAllTime = allBlocks
        .where((block) =>
            block.status == TaskStatus.completed ||
            block.status == TaskStatus.delayed)
        .length;
    profile.totalFocusSecondsAllTime =
        allBlocks.fold(0, (total, block) => total + block.totalActiveSeconds);
    await _storage.saveProfile(profile);
  }

  TaskBlock? _find(String id) {
    for (final b in todayBlocks) {
      if (b.id == id) return b;
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------

  Future<void> addBlock({
    required String title,
    required String category,
    required int plannedMinutes,
  }) async {
    final block = TaskBlock(
      id: _uuid.v4(),
      title: title,
      category: category,
      plannedMinutes: plannedMinutes,
      date: today,
    );
    todayBlocks.add(block);
    await _persist();
    notifyListeners();
  }

  Future<void> deleteBlock(String id) async {
    todayBlocks.removeWhere((b) => b.id == id);
    if (activeBlockId == id) {
      activeBlockId = null;
      _stopTicker();
    }
    await _persist();
    await _refreshProfileTotals();
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Timer / behavior tracking
  // ---------------------------------------------------------------------

  Future<void> startBlock(String id) async {
    final block = _find(id);
    if (block == null) return;

    // Only one block runs at a time — pause whatever was active before.
    if (activeBlockId != null && activeBlockId != id) {
      await pauseBlock(activeBlockId!);
    }

    block.status = TaskStatus.inProgress;
    block.startTime ??= DateTime.now();
    activeBlockId = id;
    _startTicker();
    await _persist();
    notifyListeners();
  }

  Future<void> pauseBlock(String id) async {
    final block = _find(id);
    if (block == null) return;
    block.status = TaskStatus.paused;
    block.pauseCount += 1;
    if (activeBlockId == id) {
      activeBlockId = null;
      _stopTicker();
    }
    await _persist();
    notifyListeners();
  }

  Future<void> resumeBlock(String id) => startBlock(id);

  Future<void> completeBlock(String id) async {
    final block = _find(id);
    if (block == null) return;
    block.endTime = DateTime.now();

    final plannedSeconds = block.plannedMinutes * 60;
    // Went noticeably (>10%) over planned time -> delayed, not a clean complete.
    block.status = block.totalActiveSeconds > (plannedSeconds * 1.1)
        ? TaskStatus.delayed
        : TaskStatus.completed;

    if (activeBlockId == id) {
      activeBlockId = null;
      _stopTicker();
    }

    await _persist();
    await _refreshProfileTotals();
    notifyListeners();
  }

  Future<void> failBlock(String id) async {
    final block = _find(id);
    if (block == null) return;
    block.status = TaskStatus.failed;
    block.endTime = DateTime.now();
    if (activeBlockId == id) {
      activeBlockId = null;
      _stopTicker();
    }
    await _persist();
    await _refreshProfileTotals();
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final block = activeBlockId != null ? _find(activeBlockId!) : null;
      if (block != null && block.status == TaskStatus.inProgress) {
        block.totalActiveSeconds += 1;
        notifyListeners();
      }
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  // ---------------------------------------------------------------------
  // Premium: notes & voice memos
  // ---------------------------------------------------------------------

  Future<void> updateNotes(String id, String notes) async {
    final block = _find(id);
    if (block == null) return;
    block.notes = notes;
    await _persist();
    notifyListeners();
  }

  Future<void> updateVoiceNote(String id, String? path) async {
    final block = _find(id);
    if (block == null) return;
    block.voiceNotePath = path;
    await _persist();
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // End-of-day report + history (premium)
  // ---------------------------------------------------------------------

  /// Finalizes today: anything not cleanly finished gets marked Failed,
  /// then streaks are recalculated from history. Irreversible by design —
  /// callers should confirm with the user first.
  Future<void> generateTodayReport() async {
    for (final b in todayBlocks) {
      if (b.status == TaskStatus.notStarted ||
          b.status == TaskStatus.inProgress ||
          b.status == TaskStatus.paused) {
        b.status = TaskStatus.failed;
      }
    }
    activeBlockId = null;
    _stopTicker();
    await _persist();
    await _recalculateStreaks();
    await _refreshProfileTotals();
    notifyListeners();
  }

  Future<List<DailyReport>> loadHistory() async {
    final dates = await _storage.getAllKnownDates();
    final reports = <DailyReport>[];
    for (final d in dates) {
      final blocks = await _storage.loadBlocksForDate(d);
      reports.add(DailyReport.fromBlocks(d, blocks));
    }
    return reports;
  }

  Future<void> _recalculateStreaks() async {
    final history = await loadHistory();
    history.sort((a, b) => b.date.compareTo(a.date));

    int streak = 0;
    DateTime cursor = today;
    for (final r in history) {
      if (r.date == cursor && r.completionRate >= 50) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else if (r.date == cursor) {
        break;
      }
    }
    profile.currentStreak = streak;
    if (streak > profile.longestStreak) profile.longestStreak = streak;
    await _storage.saveProfile(profile);
  }

  // ---------------------------------------------------------------------
  // Profile / premium
  // ---------------------------------------------------------------------

  Future<void> setPremium(bool value) async {
    profile.isPremium = value;
    await _storage.saveProfile(profile);
    notifyListeners();
  }

  Future<void> updateName(String name) async {
    profile.name = name;
    await _storage.saveProfile(profile);
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String email,
    required String phone,
    required String role,
  }) async {
    profile.name = name;
    profile.email = email;
    profile.phone = phone;
    profile.role = role;
    await _storage.saveProfile(profile);
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }
}
