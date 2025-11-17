import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/section.dart';

class AdminSectionsPage extends StatefulWidget {
  const AdminSectionsPage({super.key});

  @override
  State<AdminSectionsPage> createState() => _AdminSectionsPageState();
}

class _AdminSectionsPageState extends State<AdminSectionsPage> {
  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('sections');

  Future<void> _showSectionDialog({Section? existing}) async {
    final formKey = GlobalKey<FormState>();

    String name = existing?.name ?? '';
    String slug = existing?.slug ?? '';
    bool isActive = existing?.isActive ?? true;
    int sortOrder = existing?.sortOrder ?? 0;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(existing == null ? 'Add Section' : 'Edit Section'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: name,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      helperText: 'Display label, e.g. Eat & Drink',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                    onSaved: (v) => name = v!.trim(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: slug,
                    decoration: const InputDecoration(
                      labelText: 'Slug (internal key)',
                      helperText: 'e.g. attractions, eat, stay, events',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                    onSaved: (v) => slug = v!.trim(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: sortOrder.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Sort Order',
                      helperText: 'Lower = higher in the list',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (int.tryParse(v.trim()) == null) {
                        return 'Must be a number';
                      }
                      return null;
                    },
                    onSaved: (v) => sortOrder = int.parse(v!.trim()),
                  ),
                  const SizedBox(height: 12),
                  StatefulBuilder(
                    builder: (context, setInnerState) {
                      return SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Active'),
                        value: isActive,
                        onChanged: (value) {
                          setInnerState(() => isActive = value);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                formKey.currentState!.save();

                try {
                  if (existing == null) {
                    await _col.add({
                      'name': name,
                      'slug': slug,
                      'isActive': isActive,
                      'sortOrder': sortOrder,
                      'createdAt': FieldValue.serverTimestamp(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                  } else {
                    await _col.doc(existing.id).update({
                      'name': name,
                      'slug': slug,
                      'isActive': isActive,
                      'sortOrder': sortOrder,
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                  }

                  if (context.mounted) Navigator.of(context).pop();
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving section: $e')),
                  );
                }
              },
              child: Text(existing == null ? 'Add' : 'Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteSection(Section section) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Section'),
        content: Text(
          'Delete "${section.name}"?\n\n'
          'Categories that reference this section slug ("${section.slug}") will NOT be automatically updated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _col.doc(section.id).delete();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting section: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sections'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _col.orderBy('sortOrder').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading sections: ${snapshot.error}'),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text('No sections yet. Add your first one!'),
            );
          }

          final sections = docs.map((d) => Section.fromDoc(d)).toList();

          return ListView.separated(
            itemCount: sections.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final s = sections[index];
              return ListTile(
                title: Text(s.name),
                subtitle: Text(
                  '${s.slug} • order: ${s.sortOrder}${s.isActive ? '' : ' • INACTIVE'}',
                ),
                leading: CircleAvatar(
                  backgroundColor: s.isActive
                      ? cs.primary.withOpacity(0.1)
                      : cs.error.withOpacity(0.1),
                  child: Icon(
                    s.isActive ? Icons.dashboard : Icons.dashboard_customize,
                    color: s.isActive ? cs.primary : cs.error,
                  ),
                ),
                onTap: () => _showSectionDialog(existing: s),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteSection(s),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSectionDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Section'),
      ),
    );
  }
}
