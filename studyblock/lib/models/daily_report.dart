import 'task_block.dart';
import 'enums.dart';

/// Aggregated end-of-day summary derived from a day's list of TaskBlocks.
class DailyReport {
  final DateTime date;
  final int totalBlocks;
  final int completed;
  final int delayed;
  final int failed;
  final int totalPlannedMinutes;
  final int totalActualSeconds;
  final int totalPausedSeconds;
  final int totalPauseEvents;

  DailyReport({
    required this.date,
    required this.totalBlocks,
    required this.completed,
    required this.delayed,
    required this.failed,
    required this.totalPlannedMinutes,
    required this.totalActualSeconds,
    required this.totalPausedSeconds,
    required this.totalPauseEvents,
  });

  double get completionRate =>
      totalBlocks == 0 ? 0.0 : (completed / totalBlocks) * 100;

  /// How efficiently planned time was used (caps credit at 100% per block,
  /// so running massively over plan doesn't inflate the score).
  double get focusEfficiency {
    if (totalPlannedMinutes == 0) return 0.0;
    final plannedSeconds = totalPlannedMinutes * 60;
    final effective =
        totalActualSeconds > plannedSeconds ? plannedSeconds : totalActualSeconds;
    return (effective / plannedSeconds) * 100;
  }

  factory DailyReport.fromBlocks(DateTime date, List<TaskBlock> blocks) {
    int completed = 0, delayed = 0, failed = 0;
    int plannedMin = 0, actualSec = 0, pausedSec = 0, pauseEvents = 0;
    for (final b in blocks) {
      if (b.status == TaskStatus.completed) completed++;
      if (b.status == TaskStatus.delayed) delayed++;
      if (b.status == TaskStatus.failed) failed++;
      plannedMin += b.plannedMinutes;
      actualSec += b.totalActiveSeconds;
      pausedSec += b.totalPausedSeconds;
      pauseEvents += b.pauseCount;
    }
    return DailyReport(
      date: date,
      totalBlocks: blocks.length,
      completed: completed,
      delayed: delayed,
      failed: failed,
      totalPlannedMinutes: plannedMin,
      totalActualSeconds: actualSec,
      totalPausedSeconds: pausedSec,
      totalPauseEvents: pauseEvents,
    );
  }
}
