import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminFeedbackPage extends StatefulWidget {
  const AdminFeedbackPage({super.key});

  @override
  State<AdminFeedbackPage> createState() => _AdminFeedbackPageState();
}

class _AdminFeedbackPageState extends State<AdminFeedbackPage> {
  String _topicFilter = 'All';
  bool _unhandledOnly = false;

  final List<String> _topics = const [
    'All',
    'General Question',
    'App Feedback',
    'Report a Bug',
    'Suggest a Place or Event',
    'Business / Partner Inquiry',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final query = FirebaseFirestore.instance
        .collection('admin')
        .doc('feedback')
        .collection('messages')
        .orderBy('createdAt', descending: true);

    return Material(
      color: cs.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Header + filters
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _topicFilter,
                      decoration: const InputDecoration(
                        labelText: 'Filter by Topic',
                        border: OutlineInputBorder(),
                      ),
                      items: _topics
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(t),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        setState(() => _topicFilter = v ?? 'All');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Unhandled toggle
                  FilterChip(
                    label: const Text('Unhandled'),
                    selected: _unhandledOnly,
                    onSelected: (v) => setState(() => _unhandledOnly = v),
                  ),
                ],
              ),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: query.snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final matchesTopic =
                        _topicFilter == 'All' || data['topic'] == _topicFilter;

                    final matchesHandled =
                        !_unhandledOnly || data['handled'] == false;

                    return matchesTopic && matchesHandled;
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('No feedback found'),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final id = docs[i].id;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: ListTile(
                          title: Text(data['topic']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['message'] ?? ''),
                              const SizedBox(height: 4),
                              Text(
                                '${data['name']} • ${data['email']}',
                                style: TextStyle(color: cs.outline),
                              ),
                            ],
                          ),
                          trailing: Icon(
                            data['handled'] == true
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: data['handled'] == true
                                ? cs.primary
                                : cs.outline,
                          ),
                          onTap: () {
                            context.push('/admin/feedback/$id');
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
