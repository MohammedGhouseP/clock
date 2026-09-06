import 'enums.dart';

/// A single time-block task, e.g. "Study DBMS - 2 hours".
///
/// Tracks not just the planned duration but also real user behavior:
/// how many times it was paused, how long it sat waiting, and how the
/// actual time spent compares with what was planned.
class TaskBlock {
  final String id;
  String title;
  String category;
  int plannedMinutes;
  DateTime date; // the day (midnight) this block belongs to
  DateTime createdAt;

  DateTime? startTime;
  DateTime? endTime;

  int pauseCount;
  int totalPausedSeconds;
  int totalActiveSeconds;

  TaskStatus status;

  // Premium-only fields
  String? notes;
  String? voiceNotePath;

  TaskBlock({
    required this.id,
    required this.title,
    this.category = 'General',
    required this.plannedMinutes,
    required this.date,
    DateTime? createdAt,
    this.startTime,
    this.endTime,
    this.pauseCount = 0,
    this.totalPausedSeconds = 0,
    this.totalActiveSeconds = 0,
    this.status = TaskStatus.notStarted,
    this.notes,
    this.voiceNotePath,
  }) : createdAt = createdAt ?? DateTime.now();

  Duration get plannedDuration => Duration(minutes: plannedMinutes);
  Duration get actualDuration => Duration(seconds: totalActiveSeconds);

  /// 0.0 - 1.5+ ratio of actual time spent vs planned time (capped for UI bars).
  double get progressRatio {
    if (plannedMinutes == 0) return 0.0;
    final ratio = totalActiveSeconds / (plannedMinutes * 60);
    return ratio.clamp(0.0, 1.5);
  }

  bool get isOverdue => totalActiveSeconds > plannedMinutes * 60;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'plannedMinutes': plannedMinutes,
        'date': date.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'startTime': startTime?.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'pauseCount': pauseCount,
        'totalPausedSeconds': totalPausedSeconds,
        'totalActiveSeconds': totalActiveSeconds,
        'status': status.index,
        'notes': notes,
        'voiceNotePath': voiceNotePath,
      };

  factory TaskBlock.fromJson(Map<String, dynamic> json) => TaskBlock(
        id: json['id'] as String,
        title: json['title'] as String,
        category: (json['category'] as String?) ?? 'General',
        plannedMinutes: json['plannedMinutes'] as int,
        date: DateTime.parse(json['date'] as String),
        createdAt: json['createdAt'] is String
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
        startTime: json['startTime'] != null
            ? DateTime.parse(json['startTime'] as String)
            : null,
        endTime: json['endTime'] != null
            ? DateTime.parse(json['endTime'] as String)
            : null,
        pauseCount: (json['pauseCount'] as int?) ?? 0,
        totalPausedSeconds: (json['totalPausedSeconds'] as int?) ?? 0,
        totalActiveSeconds: (json['totalActiveSeconds'] as int?) ?? 0,
        status: TaskStatus.values[(json['status'] as int?) ?? 0],
        notes: json['notes'] as String?,
        voiceNotePath: json['voiceNotePath'] as String?,
      );
}
