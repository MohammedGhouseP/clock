import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../providers/app_provider.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _titleController = TextEditingController();
  final _customDurationController = TextEditingController();
  String _category = 'Study';
  int _plannedMinutes = 60;

  final _categories = const [
    'Study',
    'Work',
    'Fitness',
    'Reading',
    'Personal',
    'Other'
  ];
  final _durations = const [15, 30, 45, 60, 90, 120, 180];

  @override
  void dispose() {
    _titleController.dispose();
    _customDurationController.dispose();
    super.dispose();
  }

  String _durationLabel(int d) {
    if (d < 60) return '${d}m';
    final h = d ~/ 60;
    final m = d % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.9;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('New Task Block',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Task title',
                  hintText: 'e.g. Study - DBMS chapter 4',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Category',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _categories
                    .map((c) => ChoiceChip(
                          label: Text(c),
                          selected: _category == c,
                          onSelected: (_) => setState(() => _category = c),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              const Text('Planned duration',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _durations
                    .map((d) => ChoiceChip(
                          label: Text(_durationLabel(d)),
                          selected: _plannedMinutes == d,
                          onSelected: (_) =>
                              setState(() => _plannedMinutes = d),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 180,
                child: TextField(
                  controller: _customDurationController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Custom minutes',
                    hintText: 'e.g. 2 or 90',
                    border: OutlineInputBorder(),
                    suffixText: 'min',
                  ),
                  onChanged: (value) {
                    final minutes = int.tryParse(value);
                    if (minutes != null && minutes > 0) {
                      setState(() => _plannedMinutes = minutes);
                    }
                  },
                  onSubmitted: (_) => FocusScope.of(context).unfocus(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    FocusScope.of(context).unfocus();
                    final title = _titleController.text.trim();
                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Enter a task title first.')),
                      );
                      return;
                    }
                    final customMinutes =
                        int.tryParse(_customDurationController.text.trim());
                    if (_customDurationController.text.trim().isNotEmpty &&
                        (customMinutes == null || customMinutes < 1)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Enter at least 1 minute.')),
                      );
                      return;
                    }
                    final plannedMinutes =
                        customMinutes != null && customMinutes > 0
                            ? customMinutes
                            : _plannedMinutes;
                    await context.read<AppProvider>().addBlock(
                          title: title,
                          category: _category,
                          plannedMinutes: plannedMinutes,
                        );
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Create Block'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
