import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminFeedbackDetailPage extends StatelessWidget {
  const AdminFeedbackDetailPage({
    super.key,
    required this.id,
  });

  final String id;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final ref = FirebaseFirestore.instance
        .collection('admin')
        .doc('feedback')
        .collection('messages')
        .doc(id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback Message'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: ref.get(),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snap.data!.data() as Map<String, dynamic>;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                data['topic'],
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                '${data['name']} • ${data['email']}',
                style: TextStyle(color: cs.outline),
              ),
              const SizedBox(height: 20),
              if (data['rating'] != null)
                Text('App Rating: ${data['rating']}/10'),
              const SizedBox(height: 12),
              Text(
                data['message'],
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                icon: Icon(
                  data['handled'] == true
                      ? Icons.undo
                      : Icons.check_circle_outline,
                ),
                label: Text(
                  data['handled'] == true
                      ? 'Mark as Unhandled'
                      : 'Mark as Handled',
                ),
                onPressed: () {
                  ref.update({'handled': !(data['handled'] == true)});
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
