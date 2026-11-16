import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resepku/providers/favorite_provider.dart';
import 'package:resepku/widgets/recipe_image.dart';

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
              : ListView.separated(
                  itemCount: favorite.items.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final recipe = favorite.items[index];

                    return Dismissible(
                      // key unik dan stabil: id resep, bukan index
                      key: ValueKey(recipe.id),
                      direction: DismissDirection.endToStart, // geser ke kiri
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) {
                        favorite.toggle(recipe);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${recipe.name} dihapus dari favorit',
                            ),
                          ),
                        );
                      },
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: RecipeImage(
                              url: recipe.image,
                              cacheWidth: 168,
                            ),
                          ),
                        ),
                        title: Text(recipe.name),
                        subtitle: Text(recipe.cuisine),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
