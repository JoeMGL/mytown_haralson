import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/category.dart';

class AdminCategoriesPage extends StatefulWidget {
  const AdminCategoriesPage({super.key});

  @override
  State<AdminCategoriesPage> createState() => _AdminCategoriesPageState();
}

class _AdminCategoriesPageState extends State<AdminCategoriesPage> {
  // Which section’s categories we’re editing
  String _selectedSection = 'attractions';

  // If you want other sections, add them here
  final List<String> _sections = [
    'attractions',
    'eat',
    'stay',
    'events',
    // 'shopping',
    // 'services',
  ];

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('categories');

  Future<void> _showCategoryDialog({Category? existing}) async {
    final formKey = GlobalKey<FormState>();

    String name = existing?.name ?? '';
    String slug = existing?.slug ?? '';
    bool isActive = existing?.isActive ?? true;
    int sortOrder = existing?.sortOrder ?? 0;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(existing == null ? 'Add Category' : 'Edit Category'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: name,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                    onSaved: (v) => name = v!.trim(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: slug,
                    decoration: const InputDecoration(
                      labelText: 'Slug (used in code & queries)',
                      helperText: 'e.g. outdoor, history, family',
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
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active'),
                    value: isActive,
                    onChanged: (value) {
                      setState(() {
                        isActive = value;
                      });
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
                    // Add new
                    await _col.add({
                      'name': name,
                      'slug': slug,
                      'section': _selectedSection,
                      'isActive': isActive,
                      'sortOrder': sortOrder,
                      'createdAt': FieldValue.serverTimestamp(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                  } else {
                    // Update existing
                    await _col.doc(existing.id).update({
                      'name': name,
                      'slug': slug,
                      'section': _selectedSection,
                      'isActive': isActive,
                      'sortOrder': sortOrder,
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                  }

                  if (context.mounted) Navigator.of(context).pop();
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving category: $e')),
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

  Future<void> _deleteCategory(Category cat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Delete "${cat.name}"? This cannot be undone.'),
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
      await _col.doc(cat.id).delete();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting category: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
      ),
      body: Column(
        children: [
          // Section selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Section:'),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedSection,
                  items: _sections
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(s),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedSection = value);
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 0),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _col
                  .where('section', isEqualTo: _selectedSection)
                  .orderBy('sortOrder')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child:
                          Text('Error loading categories: ${snapshot.error}'));
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No categories yet. Add your first one!'),
                  );
                }

                final categories =
                    docs.map((d) => Category.fromDoc(d)).toList();

                return ListView.separated(
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const Divider(height: 0),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    return ListTile(
                      title: Text(cat.name),
                      subtitle: Text(
                        '${cat.slug} • order: ${cat.sortOrder}${cat.isActive ? '' : ' • INACTIVE'}',
                      ),
                      leading: CircleAvatar(
                        backgroundColor: cat.isActive
                            ? cs.primary.withOpacity(0.1)
                            : cs.error.withOpacity(0.1),
                        child: Icon(
                          cat.isActive ? Icons.label : Icons.label_off,
                          color: cat.isActive ? cs.primary : cs.error,
                        ),
                      ),
                      onTap: () => _showCategoryDialog(existing: cat),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteCategory(cat),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
    );
  }
}
