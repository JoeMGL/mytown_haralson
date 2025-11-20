import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ContactFeedbackPage extends StatefulWidget {
  const ContactFeedbackPage({super.key});

  @override
  State<ContactFeedbackPage> createState() => _ContactFeedbackPageState();
}

class _ContactFeedbackPageState extends State<ContactFeedbackPage> {
  final _formKey = GlobalKey<FormState>();

  // Form fields
  String _name = '';
  String _email = '';
  String _topic = 'General Question';
  String _message = '';
  double _rating = 5;

  bool _submitting = false;

  final List<String> _topics = const [
    'General Question',
    'App Feedback',
    'Report a Bug',
    'Suggest a Place or Event',
    'Business / Partner Inquiry',
    'Other',
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _submitting = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('admin')
          .doc('feedback')
          .collection('messages')
          .add({
        'name': _name,
        'email': _email,
        'topic': _topic,
        'message': _message,
        'rating': _rating,
        'createdAt': FieldValue.serverTimestamp(),
        'source': 'visit_haralson_app',
        'handled': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanks! Your message has been sent.')),
        );
      }

      // Reset form
      _formKey.currentState!.reset();
      setState(() {
        _topic = 'General Question';
        _rating = 5;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact & Feedback'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header / static contact info
              Card(
                elevation: 0,
                color: cs.surfaceVariant.withOpacity(0.4),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'We’d love to hear from you',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Send us questions, ideas, or feedback about Visit Haralson. '
                        'You can also report app issues or suggest new places and events.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.email_outlined, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'hello@visitharalson.com',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.public_outlined, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'VisitHaralson.com',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Send us a message',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),

                    // Name
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'Your name',
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                      onSaved: (v) => _name = v?.trim() ?? '',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'you@example.com',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onSaved: (v) => _email = v?.trim() ?? '',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!v.contains('@') || !v.contains('.')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Topic
                    DropdownButtonFormField<String>(
                      value: _topic,
                      decoration: const InputDecoration(
                        labelText: 'What is this about?',
                        border: OutlineInputBorder(),
                      ),
                      items: _topics
                          .map(
                            (t) => DropdownMenuItem<String>(
                              value: t,
                              child: Text(t),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _topic = value;
                        });
                      },
                      onSaved: (v) => _topic = v ?? 'General Question',
                    ),
                    const SizedBox(height: 16),

                    // Rating slider (optional)
                    Text(
                      'How is your experience with the app?',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('Needs work'),
                        Expanded(
                          child: Slider(
                            value: _rating,
                            min: 1,
                            max: 10,
                            divisions: 9,
                            label: _rating.toStringAsFixed(0),
                            onChanged: (value) {
                              setState(() {
                                _rating = value;
                              });
                            },
                          ),
                        ),
                        const Text('Love it'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Message
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        hintText:
                            'Tell us what’s on your mind – details help us respond.',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 6,
                      textInputAction: TextInputAction.newline,
                      onSaved: (v) => _message = v?.trim() ?? '',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please enter a message';
                        }
                        if (v.trim().length < 10) {
                          return 'Please add a bit more detail';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _submitting ? null : _submit,
                        icon: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_outlined),
                        label: Text(
                          _submitting ? 'Sending...' : 'Send Message',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'By submitting, you agree we may contact you at the email you provided if we have questions about your message.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.outline),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
