import 'package:flutter/material.dart';
import '../models/enums.dart';

class StatusUtils {
  static String label(TaskStatus status) {
    switch (status) {
      case TaskStatus.notStarted:
        return 'Not Started';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.paused:
        return 'Waiting';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.delayed:
        return 'Delayed';
      case TaskStatus.failed:
        return 'Failed';
    }
  }

  static Color color(TaskStatus status) {
    switch (status) {
      case TaskStatus.notStarted:
        return Colors.grey;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.paused:
        return Colors.orange;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.delayed:
        return Colors.amber.shade800;
      case TaskStatus.failed:
        return Colors.red;
    }
  }

  static IconData icon(TaskStatus status) {
    switch (status) {
      case TaskStatus.notStarted:
        return Icons.schedule;
      case TaskStatus.inProgress:
        return Icons.play_circle_fill;
      case TaskStatus.paused:
        return Icons.pause_circle_filled;
      case TaskStatus.completed:
        return Icons.check_circle;
      case TaskStatus.delayed:
        return Icons.watch_later;
      case TaskStatus.failed:
        return Icons.cancel;
    }
  }
}
