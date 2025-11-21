import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/favorites/favorites_repository.dart';
import '../models/favorite.dart';

class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({
    super.key,
    required this.type,
    required this.itemId,
    this.size = 24,
    this.iconColor,
  });

  /// e.g. 'eat_and_drink', 'event', 'attraction', 'club'
  final String type;

  /// The Firestore ID of the underlying item
  final String itemId;

  /// Icon size
  final double size;

  /// Optional override color
  final Color? iconColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(userFavoritesProvider);
    final repo = ref.watch(favoritesRepositoryProvider);

    final user = FirebaseAuth.instance.currentUser;

    final cs = Theme.of(context).colorScheme;
    final effectiveColor = iconColor ?? cs.primary;

    final isLoggedIn = user != null;

    return favoritesAsync.when(
      data: (favoritesMap) {
        final key = favoriteKey(type, itemId);
        final isFav = favoritesMap.containsKey(key);

        return IconButton(
          iconSize: size,
          tooltip: isFav ? 'Remove from favorites' : 'Save to favorites',
          onPressed: () async {
            if (!isLoggedIn) {
              // Not logged in → show a dialog or route to login.
              await _showLoginPrompt(context);
              return;
            }

            try {
              // Optimistic UI is handled by the stream
              await repo.toggleFavorite(type, itemId);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Could not update favorites: $e')),
              );
            }
          },
          icon: Icon(
            isFav ? Icons.favorite : Icons.favorite_border,
            color: isFav ? effectiveColor : cs.onSurfaceVariant,
          ),
        );
      },
      loading: () => IconButton(
        onPressed: null,
        icon: SizedBox(
          width: size,
          height: size,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (err, stack) => IconButton(
        onPressed: () async {
          if (!isLoggedIn) {
            await _showLoginPrompt(context);
            return;
          }
          try {
            await repo.toggleFavorite(type, itemId);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not update favorites: $e')),
            );
          }
        },
        icon: Icon(
          Icons.favorite_border,
          size: size,
          color: cs.error,
        ),
      ),
    );
  }

  Future<void> _showLoginPrompt(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sign in to save favorites'),
          content: const Text(
            'Create a free account or sign in to save your favorite places and events.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Not now'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Update with your real login route
                // context.push('/login');
              },
              child: const Text('Sign in'),
            ),
          ],
        );
      },
    );
  }
}
