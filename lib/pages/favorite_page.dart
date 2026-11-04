import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resepku/providers/favorite_provider.dart';

class FavoritePage extends StatelessWidget {
  const FavoritePage({super.key});

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Semua Favorit?'),
          content: const Text(
            'Apakah Anda yakin ingin menghapus '
            'semua resep dari daftar favorit?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (!context.mounted) return;

    if (confirmed == true) {
      context.read<FavoriteProvider>().clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoriteProvider>(
      builder: (context, favorite, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Favorit Saya'),
            actions: [
              TextButton(
                onPressed: favorite.count > 0
                    ? () => _confirmClear(context)
                    : null,
                child: const Text('Hapus semua'),
              ),
            ],
          ),
          body: favorite.count == 0
              ? const Center(
                  child: Text(
                    'Belum ada resep favorit.\n'
                    'Tekan ikon hati di daftar resep.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView(
                  children: [
                    for (final recipe in favorite.items)
                      ListTile(
                        title: Text(recipe.name),
                        subtitle: Text(recipe.cuisine),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            favorite.toggle(recipe);
                          },
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}
