import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/category.dart';
import '../../../models/section.dart';

class AdminCategoriesPage extends StatefulWidget {
  const AdminCategoriesPage({super.key});

  @override
  State<AdminCategoriesPage> createState() => _AdminCategoriesPageState();
}

class _AdminCategoriesPageState extends State<AdminCategoriesPage> {
  // Currently selected section slug (e.g. "attractions", "eat")
  String? _selectedSectionSlug;

  CollectionReference<Map<String, dynamic>> get _categoriesCol =>
      FirebaseFirestore.instance.collection('categories');

  CollectionReference<Map<String, dynamic>> get _sectionsCol =>
      FirebaseFirestore.instance.collection('sections');

  Future<void> _showCategoryDialog({Category? existing}) async {
    // Must have a section selected
    if (_selectedSectionSlug == null || _selectedSectionSlug!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create/select a section first.')),
      );
      return;
    }

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
                    await _categoriesCol.add({
                      'name': name,
                      'slug': slug,
                      'section': _selectedSectionSlug, // <- IMPORTANT
                      'isActive': isActive,
                      'sortOrder': sortOrder,
                      'createdAt': FieldValue.serverTimestamp(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                  } else {
                    await _categoriesCol.doc(existing.id).update({
                      'name': name,
                      'slug': slug,
                      'section': _selectedSectionSlug, // keep in sync
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
      await _categoriesCol.doc(cat.id).delete();
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
          // 🔽 Section selector from /sections
          Padding(
            padding: const EdgeInsets.all(16),
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _sectionsCol.orderBy('sortOrder').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Row(
                    children: [
                      Text('Section:'),
                      SizedBox(width: 12),
                      CircularProgressIndicator(),
                    ],
                  );
                }

                if (snapshot.hasError) {
                  return Text('Error loading sections: ${snapshot.error}');
                }

                final docs = snapshot.data?.docs ?? [];
                final sections = docs.map((d) => Section.fromDoc(d)).toList();

                if (sections.isEmpty) {
                  return const Text(
                    'No sections yet. Go to "Sections" and add one.',
                  );
                }

// Ensure selected slug is always valid
                if (_selectedSectionSlug == null ||
                    !sections.any((s) => s.slug == _selectedSectionSlug)) {
                  // 🔧 FIX: use setState so the whole widget (incl. categories) rebuilds
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() {
                      _selectedSectionSlug = sections.first.slug;
                    });
                  });
                }

                return Row(
                  children: [
                    const Text('Section:'),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedSectionSlug,
                        items: sections
                            .map(
                              (s) => DropdownMenuItem(
                                value: s.slug,
                                child: Text(s.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _selectedSectionSlug = value);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const Divider(height: 0),

          // 🔁 Categories for the selected section
          Expanded(
            child: _selectedSectionSlug == null
                ? const Center(
                    child: Text('Select a section to view its categories.'),
                  )
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _categoriesCol
                        .where('section', isEqualTo: _selectedSectionSlug)
                        .orderBy('sortOrder')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading categories: ${snapshot.error}',
                          ),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];

                      if (docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No categories yet for this section. Add your first one!',
                          ),
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
                              '${cat.slug} • order: ${cat.sortOrder}'
                              '${cat.isActive ? '' : ' • INACTIVE'}',
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
