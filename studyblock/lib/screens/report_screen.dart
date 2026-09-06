import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/daily_report.dart';
import '../widgets/stat_card.dart';
import '../widgets/task_block_card.dart';
import 'timer_screen.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final report = DailyReport.fromBlocks(app.today, app.todayBlocks);

    return Scaffold(
      appBar: AppBar(title: const Text("Today's Report")),
      body: app.todayBlocks.isEmpty
          ? const Center(child: Text('Add task blocks to see your report here'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.25,
                  children: [
                    StatCard(
                        label: 'Completed',
                        value: '${report.completed}',
                        icon: Icons.check_circle,
                        color: Colors.green),
                    StatCard(
                        label: 'Delayed',
                        value: '${report.delayed}',
                        icon: Icons.watch_later,
                        color: Colors.amber.shade800),
                    StatCard(
                        label: 'Failed',
                        value: '${report.failed}',
                        icon: Icons.cancel,
                        color: Colors.red),
                    StatCard(
                        label: 'Efficiency',
                        value: '${report.focusEfficiency.toStringAsFixed(0)}%',
                        icon: Icons.speed,
                        color: Colors.blue),
                  ],
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Focus time',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        Text('Planned: ${report.totalPlannedMinutes} min'),
                        Text(
                            'Actual: ${(report.totalActualSeconds / 60).toStringAsFixed(0)} min'),
                        Text(
                            'Paused / waited: ${(report.totalPausedSeconds / 60).toStringAsFixed(0)} min across ${report.totalPauseEvents} pause(s)'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmGenerate(context, app),
                    icon: const Icon(Icons.summarize),
                    label: const Text('Finalize End-of-Day Report'),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Blocks',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                ...app.todayBlocks.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TaskBlockCard(
                        block: b,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => TimerScreen(blockId: b.id))),
                      ),
                    )),
              ],
            ),
    );
  }

  void _confirmGenerate(BuildContext context, AppProvider app) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Finalize today's report?"),
        content: const Text(
            'Any block still not started, in progress, or waiting will be marked as Failed. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await app.generateTodayReport();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Finalize'),
          ),
        ],
      ),
    );
  }
}
