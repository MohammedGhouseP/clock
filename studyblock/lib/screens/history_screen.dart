import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/daily_report.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<DailyReport>? _reports;
  String? _lastSignature;
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    _loading = true;
    final app = context.read<AppProvider>();
    try {
      final reports = await app.loadHistory();
      if (mounted) setState(() => _reports = reports);
    } finally {
      _loading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final signature = app.todayBlocks
        .map((block) =>
            '${block.id}:${block.status.index}:${block.totalActiveSeconds}:${block.endTime}')
        .join('|');
    if (_lastSignature != signature) {
      _lastSignature = signature;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: _reports == null
          ? const Center(child: CircularProgressIndicator())
          : _reports!.isEmpty
              ? const Center(child: Text('No past reports yet'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reports!.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final r = _reports![i];
                    return Card(
                      child: ListTile(
                        title:
                            Text(DateFormat('EEE, d MMM yyyy').format(r.date)),
                        subtitle: Text(
                            '${r.completed} completed · ${r.delayed} delayed · ${r.failed} failed'),
                        trailing: Text(
                            '${r.completionRate.toStringAsFixed(0)}%',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                ),
    );
  }
}
