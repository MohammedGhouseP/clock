import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../widgets/task_block_card.dart';
import 'add_task_screen.dart';
import 'timer_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final blocks = app.todayBlocks;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${app.profile.name}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
                child: Text(DateFormat('EEE, d MMM').format(DateTime.now()))),
          ),
        ],
      ),
      body: blocks.isEmpty
          ? _EmptyState(onAdd: () => _openAdd(context))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (app.activeBlockId != null) ...[
                  _ActiveBanner(blockId: app.activeBlockId!),
                  const SizedBox(height: 16),
                ],
                Text(
                  "Today's Blocks (${blocks.length})",
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 10),
                ...blocks.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TaskBlockCard(
                        block: b,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => TimerScreen(blockId: b.id))),
                      ),
                    )),
                const SizedBox(height: 80),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAdd(context),
        icon: const Icon(Icons.add),
        label: const Text('New Block'),
      ),
    );
  }

  void _openAdd(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const AddTaskScreen(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No blocks planned for today',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: onAdd, child: const Text('Add your first block')),
          ],
        ),
      ),
    );
  }
}

class _ActiveBanner extends StatelessWidget {
  final String blockId;
  const _ActiveBanner({required this.blockId});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final block = app.todayBlocks.firstWhere((b) => b.id == blockId);
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => TimerScreen(blockId: blockId))),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF3A5BA0), Color(0xFF5B7FD6)]),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Icon(Icons.play_circle_fill, color: Colors.white, size: 34),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(block.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16)),
                  Text('In progress · tap to view timer',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.85), fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
