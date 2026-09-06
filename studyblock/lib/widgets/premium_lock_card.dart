import 'package:flutter/material.dart';

Future<bool> showPremiumContactDialog(BuildContext context) async {
  final emailController = TextEditingController(text: 'pbasha150@gmail.com');
  final contacted = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Connect for Premium'),
      content: TextField(
        controller: emailController,
        readOnly: true,
        decoration: const InputDecoration(
          labelText: 'Contact email',
          prefixIcon: Icon(Icons.email_outlined),
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('I have contacted support'),
        ),
      ],
    ),
  );
  emailController.dispose();
  return contacted ?? false;
}

class PremiumLockCard extends StatelessWidget {
  final String message;
  final VoidCallback onUpgrade;

  const PremiumLockCard(
      {super.key, required this.message, required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFF7E6),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.lock, color: Colors.amber, size: 32),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            ElevatedButton(
                onPressed: onUpgrade, child: const Text('Upgrade to Premium')),
          ],
        ),
      ),
    );
  }
}
