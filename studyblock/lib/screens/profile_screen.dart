import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/stat_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _editProfile(BuildContext context, AppProvider app) async {
    final nameController = TextEditingController(text: app.profile.name);
    final emailController = TextEditingController(text: app.profile.email);
    final phoneController = TextEditingController(text: app.profile.phone);
    final roleController = TextEditingController(text: app.profile.role);
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit profile'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter your name'
                      : null,
                ),
                TextFormField(
                  controller: roleController,
                  decoration: const InputDecoration(
                    labelText: 'Role or status',
                    prefixIcon: Icon(Icons.school_outlined),
                    hintText: 'Student',
                  ),
                ),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true) {
      await app.updateProfile(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        role: roleController.text.trim().isEmpty
            ? 'Student'
            : roleController.text.trim(),
      );
    }

    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    roleController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final profile = app.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Edit profile',
            onPressed: () => _editProfile(context, app),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                const CircleAvatar(
                    radius: 40, child: Icon(Icons.person, size: 40)),
                const SizedBox(height: 12),
                Text(profile.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Text(profile.role,
                    style: TextStyle(color: Colors.grey.shade600)),
                if (profile.email.isNotEmpty)
                  Text(profile.email,
                      style: TextStyle(color: Colors.grey.shade600)),
                if (profile.phone.isNotEmpty)
                  Text(profile.phone,
                      style: TextStyle(color: Colors.grey.shade600)),
                Text(
                    'Member since ${DateFormat('MMM yyyy').format(profile.memberSince)}',
                    style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 10),
                const Chip(
                  label: Text('All features available'),
                  backgroundColor: Color(0xFFE5F5E9),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              StatCard(
                  label: 'Tasks completed',
                  value: '${profile.totalTasksCompletedAllTime}',
                  icon: Icons.check_circle,
                  color: Colors.green),
              StatCard(
                  label: 'Current streak',
                  value: '${profile.currentStreak} days',
                  icon: Icons.local_fire_department,
                  color: Colors.orange),
              StatCard(
                  label: 'Total focus time',
                  value:
                      '${(profile.totalFocusSecondsAllTime / 3600).toStringAsFixed(1)}h',
                  icon: Icons.timer,
                  color: Colors.blue),
              StatCard(
                  label: 'Longest streak',
                  value: '${profile.longestStreak} days',
                  icon: Icons.emoji_events,
                  color: Colors.purple),
            ],
          ),
          const SizedBox(height: 24),
          const Card(
            child: ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text('StudyBlock is ready to use'),
              subtitle: Text(
                  'Notes, voice memos, history, and reports are available.'),
            ),
          ),
        ],
      ),
    );
  }
}
