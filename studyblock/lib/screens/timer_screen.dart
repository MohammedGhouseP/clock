import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/enums.dart';
import '../models/task_block.dart';
import '../utils/status_utils.dart';
import 'notes_screen.dart';

class TimerScreen extends StatelessWidget {
  final String blockId;
  const TimerScreen({super.key, required this.blockId});

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = two(d.inHours);
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    return d.inHours > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final block = app.todayBlocks.firstWhere((b) => b.id == blockId);
    final planned = Duration(minutes: block.plannedMinutes);
    final remaining = planned - block.actualDuration;
    final color = StatusUtils.color(block.status);

    return Scaffold(
      appBar: AppBar(title: Text(block.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 6),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_fmt(block.actualDuration),
                          style: const TextStyle(
                              fontSize: 32, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        remaining.isNegative
                            ? '${_fmt(remaining.abs())} over'
                            : '${_fmt(remaining)} left',
                        style: TextStyle(
                            color: remaining.isNegative
                                ? Colors.orange
                                : Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Chip(
                  label: Text(StatusUtils.label(block.status)),
                  backgroundColor: color.withValues(alpha: 0.15),
                  labelStyle:
                      TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _controls(context, app, block),
          const SizedBox(height: 24),
          _behaviorCard(block),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => NotesScreen(blockId: blockId))),
            icon: const Icon(Icons.edit_note),
            label: const Text('Notes & Voice Memo'),
          ),
        ],
      ),
    );
  }

  Widget _controls(BuildContext context, AppProvider app, TaskBlock block) {
    final status = block.status;
    final buttons = <Widget>[];

    if (status == TaskStatus.notStarted || status == TaskStatus.paused) {
      buttons.add(ElevatedButton.icon(
        onPressed: () => app.startBlock(blockId),
        icon: const Icon(Icons.play_arrow),
        label: Text(status == TaskStatus.paused ? 'Resume' : 'Start',
            softWrap: false),
      ));
    }

    if (status == TaskStatus.inProgress) {
      buttons.add(OutlinedButton.icon(
        onPressed: () => app.pauseBlock(blockId),
        icon: const Icon(Icons.pause),
        label: const Text('Wait / Pause', softWrap: false),
      ));
    }

    if (status == TaskStatus.inProgress || status == TaskStatus.paused) {
      buttons.add(ElevatedButton.icon(
        onPressed: () => app.completeBlock(blockId),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        icon: const Icon(Icons.check),
        label: const Text('Complete', softWrap: false),
      ));
    }

    if (status == TaskStatus.notStarted ||
        status == TaskStatus.inProgress ||
        status == TaskStatus.paused) {
      buttons.add(TextButton.icon(
        onPressed: () => _confirmFail(context, app),
        icon: const Icon(Icons.close, color: Colors.red),
        label: const Text('Give up',
            softWrap: false, style: TextStyle(color: Colors.red)),
      ));
    }

    return Wrap(spacing: 8, runSpacing: 8, children: buttons);
  }

  void _confirmFail(BuildContext context, AppProvider app) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mark as Failed?'),
        content: const Text(
            "This block will be recorded as failed in today's report."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              app.failBlock(blockId);
              Navigator.pop(context);
            },
            child:
                const Text('Mark Failed', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _behaviorCard(TaskBlock block) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Behavior tracked',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            _row('Times paused / waited', '${block.pauseCount}'),
            _row('Category', block.category),
            _row('Planned', '${block.plannedMinutes} min'),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: const TextStyle(color: Colors.grey)),
            Text(v)
          ],
        ),
      );
}
