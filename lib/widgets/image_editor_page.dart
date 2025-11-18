import 'package:flutter/material.dart';

/// A reusable page to manage a list of image URLs:
/// - Add new URLs
/// - Delete existing
/// - Reorder
///
/// Use it with:
/// final result = await Navigator.of(context).push<List<String>>(
///   MaterialPageRoute(
///     builder: (_) => ImageUrlsEditorPage(
///       initialUrls: currentUrls,
///       title: 'Club Images',
///     ),
///   ),
/// );
class ImageUrlsEditorPage extends StatefulWidget {
  const ImageUrlsEditorPage({
    super.key,
    required this.initialUrls,
    this.title = 'Manage Images',
  });

  /// Starting list of URLs
  final List<String> initialUrls;

  /// Page title (so you can reuse in different sections)
  final String title;

  @override
  State<ImageUrlsEditorPage> createState() => _ImageUrlsEditorPageState();
}

class _ImageUrlsEditorPageState extends State<ImageUrlsEditorPage> {
  final _urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late List<String> _urls;

  @override
  void initState() {
    super.initState();
    _urls = List<String>.from(widget.initialUrls);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _addUrl() {
    if (!_formKey.currentState!.validate()) return;
    final raw = _urlController.text.trim();
    if (raw.isEmpty) return;

    setState(() {
      _urls.add(raw);
      _urlController.clear();
    });
  }

  void _removeAt(int index) {
    setState(() {
      _urls.removeAt(index);
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _urls.removeAt(oldIndex);
      _urls.insert(newIndex, item);
    });
  }

  void _saveAndClose() {
    Navigator.of(context).pop<List<String>>(_urls);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          TextButton(
            onPressed: _saveAndClose,
            child: const Text('Done'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Add new URL
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        labelText: 'Image URL',
                        hintText: 'https://example.com/image.jpg',
                      ),
                      keyboardType: TextInputType.url,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return null; // allow empty; we just won't add
                        }
                        // Super light validation
                        if (!v.startsWith('http')) {
                          return 'Must start with http';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _addUrl,
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // List of URLs
          Expanded(
            child: _urls.isEmpty
                ? Center(
                    child: Text(
                      'No images yet.\nAdd one using the field above.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: _urls.length,
                    onReorder: _onReorder,
                    itemBuilder: (context, index) {
                      final url = _urls[index];
                      return Dismissible(
                        key: ValueKey(url + index.toString()),
                        background: Container(
                          color: cs.errorContainer,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: Icon(Icons.delete, color: cs.onErrorContainer),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _removeAt(index),
                        child: ListTile(
                          key: ValueKey('tile_$index'),
                          leading: CircleAvatar(
                            backgroundColor: cs.surfaceVariant,
                            child: const Icon(Icons.image),
                          ),
                          title: Text(
                            url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            'Tap and hold drag handle to reorder',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          trailing: const Icon(Icons.drag_handle),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
