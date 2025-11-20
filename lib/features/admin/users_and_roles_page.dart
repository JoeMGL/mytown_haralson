import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UsersAndRolesPage extends StatefulWidget {
  const UsersAndRolesPage({super.key});

  @override
  State<UsersAndRolesPage> createState() => _UsersAndRolesPageState();
}

class _UsersAndRolesPageState extends State<UsersAndRolesPage> {
  final _usersRef = FirebaseFirestore.instance.collection('users');

  String _search = '';
  String _roleFilter = 'all';
  bool _showDisabledOnly = false;

  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // --------- FIRESTORE ACTION HELPERS ---------

  Future<void> _updateRole(String userId, String newRole) async {
    try {
      await _usersRef.doc(userId).update({'role': newRole});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Updated role to "$newRole".')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating role: $e')),
      );
    }
  }

  Future<void> _setDisabled(String userId, bool disabled) async {
    try {
      await _usersRef.doc(userId).update({'isDisabled': disabled});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(disabled ? 'User disabled.' : 'User enabled.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating disabled flag: $e')),
      );
    }
  }

  Future<void> _softDeleteUser(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete user?'),
        content: const Text(
          'This will mark the account as deleted and disabled. '
          'You can undo this later by editing the user document in Firestore.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _usersRef.doc(userId).update({
        'deleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'isDisabled': true,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User marked as deleted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting user: $e')),
      );
    }
  }

  Future<void> _sendPasswordReset(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent to $email')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending reset email: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending reset email: $e')),
      );
    }
  }

  /// Mark user for force logout by setting a flag in Firestore.
  Future<void> _markForceLogout(String userId) async {
    try {
      await _usersRef.doc(userId).update({
        'forceLogoutAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User marked for force logout.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking force logout: $e')),
      );
    }
  }

  Future<void> _approveAllClaims(
    String userId,
    Map<String, dynamic> data,
  ) async {
    final pendingShops =
        List<String>.from(data['pendingShopClaims'] ?? const <String>[]);
    final pendingClubs =
        List<String>.from(data['pendingClubClaims'] ?? const <String>[]);

    if (pendingShops.isEmpty && pendingClubs.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pending claims to approve.')),
      );
      return;
    }

    final approvedShops =
        List<String>.from(data['approvedShopIds'] ?? const <String>[]);
    final approvedClubs =
        List<String>.from(data['approvedClubIds'] ?? const <String>[]);

    try {
      await _usersRef.doc(userId).update({
        'approvedShopIds': [
          ...approvedShops,
          ...pendingShops.where((id) => !approvedShops.contains(id)),
        ],
        'approvedClubIds': [
          ...approvedClubs,
          ...pendingClubs.where((id) => !approvedClubs.contains(id)),
        ],
        'pendingShopClaims': <String>[],
        'pendingClubClaims': <String>[],
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Approved all pending claims.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving claims: $e')),
      );
    }
  }

  // --------- DETAIL SHEET UI ---------

  void _showUserDetailSheet(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final uid = doc.id;
    final email = (data['email'] as String?) ?? '(no email)';
    final createdAt = data['createdAt'];
    final lastLoginAt = data['lastLoginAt'];
    final role = (data['role'] as String?) ?? 'user';
    final isDisabled = data['isDisabled'] == true;
    final deleted = data['deleted'] == true;
    final pendingShopClaims =
        List<String>.from(data['pendingShopClaims'] ?? const []);
    final pendingClubClaims =
        List<String>.from(data['pendingClubClaims'] ?? const []);
    final approvedShopIds =
        List<String>.from(data['approvedShopIds'] ?? const []);
    final approvedClubIds =
        List<String>.from(data['approvedClubIds'] ?? const []);

    String createdText = 'Unknown';
    if (createdAt is Timestamp) {
      createdText = createdAt.toDate().toString();
    }

    String lastLoginText = 'Never';
    if (lastLoginAt is Timestamp) {
      lastLoginText = lastLoginAt.toDate().toString();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        String localRole = role;
        bool localDisabled = isDisabled;

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                top: 8,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: email + role chip
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          child: Text(
                            email.isNotEmpty ? email[0].toUpperCase() : '?',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                email,
                                style: Theme.of(ctx)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'UID: $uid',
                                style: Theme.of(ctx)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: cs.outline),
                              ),
                              const SizedBox(height: 4),
                              if (deleted)
                                Text(
                                  'ACCOUNT MARKED AS DELETED',
                                  style: Theme.of(ctx)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: cs.error),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Role',
                              style: TextStyle(fontSize: 12),
                            ),
                            DropdownButton<String>(
                              value: localRole,
                              items: const [
                                DropdownMenuItem(
                                    value: 'admin', child: Text('Admin')),
                                DropdownMenuItem(
                                    value: 'manager', child: Text('Manager')),
                                DropdownMenuItem(
                                    value: 'editor', child: Text('Editor')),
                                DropdownMenuItem(
                                    value: 'viewer', child: Text('Viewer')),
                                DropdownMenuItem(
                                    value: 'user', child: Text('User')),
                              ],
                              onChanged: (value) async {
                                if (value == null || value == localRole) {
                                  return;
                                }
                                setModalState(() => localRole = value);
                                await _updateRole(uid, value);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Disabled'),
                      subtitle: const Text(
                          'Disabled users cannot sign in to the app.'),
                      value: localDisabled,
                      onChanged: (v) async {
                        setModalState(() => localDisabled = v);
                        await _setDisabled(uid, v);
                      },
                    ),

                    const Divider(),

                    // Timestamps
                    ListTile(
                      dense: true,
                      title: const Text('Created'),
                      subtitle: Text(createdText),
                      leading: const Icon(Icons.calendar_today_outlined),
                    ),
                    ListTile(
                      dense: true,
                      title: const Text('Last login'),
                      subtitle: Text(lastLoginText),
                      leading: const Icon(Icons.login_outlined),
                    ),

                    if (approvedShopIds.isNotEmpty ||
                        approvedClubIds.isNotEmpty)
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.verified_user_outlined),
                        title: const Text('Approved ownership'),
                        subtitle: Text(
                          '${approvedShopIds.length} shop(s), '
                          '${approvedClubIds.length} club(s)',
                        ),
                      ),

                    if (pendingShopClaims.isNotEmpty ||
                        pendingClubClaims.isNotEmpty)
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.hourglass_bottom_outlined),
                        title: const Text('Pending claims'),
                        subtitle: Text(
                          '${pendingShopClaims.length} shop(s), '
                          '${pendingClubClaims.length} club(s)',
                        ),
                      ),

                    const SizedBox(height: 12),
                    Text(
                      'Actions',
                      style: Theme.of(ctx)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.lock_reset, size: 18),
                          label: const Text('Reset password'),
                          onPressed: email == '(no email)'
                              ? null
                              : () => _sendPasswordReset(email),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.logout, size: 18),
                          label: const Text('Force logout'),
                          onPressed: () => _markForceLogout(uid),
                        ),
                        if (pendingShopClaims.isNotEmpty ||
                            pendingClubClaims.isNotEmpty)
                          OutlinedButton.icon(
                            icon: const Icon(Icons.verified_user_outlined,
                                size: 18),
                            label: const Text('Approve all claims'),
                            onPressed: () => _approveAllClaims(uid, data),
                          ),
                        TextButton.icon(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Soft delete'),
                          style: TextButton.styleFrom(
                            foregroundColor: cs.error,
                          ),
                          onPressed: () => _softDeleteUser(uid),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --------- MAIN BUILD ---------

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // 🔍 Search & filters
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search by email or UID',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() => _search = value.trim().toLowerCase());
                  },
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _roleFilter,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All roles')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'manager', child: Text('Manager')),
                  DropdownMenuItem(value: 'editor', child: Text('Editor')),
                  DropdownMenuItem(value: 'viewer', child: Text('Viewer')),
                  DropdownMenuItem(value: 'user', child: Text('User')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _roleFilter = value);
                },
              ),
              const SizedBox(width: 12),
              FilterChip(
                label: const Text('Disabled only'),
                selected: _showDisabledOnly,
                onSelected: (v) {
                  setState(() => _showDisabledOnly = v);
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream:
                _usersRef.orderBy('createdAt', descending: false).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error loading users: ${snapshot.error}'),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No users found yet.\n'
                      'Users will appear here after they register or sign in.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final docs = snapshot.data!.docs;

              final filtered = docs.where((doc) {
                final data = doc.data();
                final email = (data['email'] as String? ?? '').toLowerCase();
                final uid = doc.id.toLowerCase();
                final role = (data['role'] as String? ?? 'user').toLowerCase();
                final isDisabled = data['isDisabled'] == true;

                if (_showDisabledOnly && !isDisabled) return false;
                if (_roleFilter != 'all' && role != _roleFilter) {
                  return false;
                }
                if (_search.isNotEmpty) {
                  if (!email.contains(_search) && !uid.contains(_search)) {
                    return false;
                  }
                }
                return true;
              }).toList();

              if (filtered.isEmpty) {
                return const Center(
                  child: Text('No users match your filters.'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final doc = filtered[index];
                  final data = doc.data();
                  final uid = doc.id;
                  final email = (data['email'] as String?) ?? '(no email)';
                  final role = (data['role'] as String?) ?? 'user';
                  final isDisabled = data['isDisabled'] == true;
                  final deleted = data['deleted'] == true;
                  final createdAt = data['createdAt'];
                  final lastLoginAt = data['lastLoginAt'];

                  String createdText = 'Unknown';
                  if (createdAt is Timestamp) {
                    createdText = createdAt.toDate().toString();
                  }

                  String lastLoginText = 'Never';
                  if (lastLoginAt is Timestamp) {
                    lastLoginText = lastLoginAt.toDate().toString();
                  }

                  final badgeColor = switch (role) {
                    'admin' => cs.error,
                    'manager' => cs.primary,
                    'editor' => cs.secondary,
                    'viewer' => cs.tertiary,
                    _ => cs.outline,
                  };

                  return InkWell(
                    onTap: () => _showUserDetailSheet(doc),
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 12, top: 4),
                              child: CircleAvatar(
                                child: Text(
                                  email.isNotEmpty
                                      ? email[0].toUpperCase()
                                      : '?',
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          email,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          color: badgeColor.withOpacity(0.15),
                                        ),
                                        child: Text(
                                          role.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: badgeColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'UID: $uid',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: cs.outline),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Created: $createdText',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  Text(
                                    'Last login: $lastLoginText',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  if (isDisabled || deleted)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        deleted ? 'Deleted' : 'Disabled',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: cs.error,
                                            ),
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap for details & actions',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: cs.primary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
