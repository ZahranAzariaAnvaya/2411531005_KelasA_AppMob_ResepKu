import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resepku/models/recipe.dart';
import 'package:resepku/providers/favorite_provider.dart';
import 'package:resepku/widgets/recipe_image.dart';
import 'package:resepku/services/recipe_service.dart';

enum _MenuAction { rename, delete }

class DetailPage extends StatefulWidget {
  const DetailPage({super.key, required this.recipe});

  final Recipe recipe;

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late int _servings;

  @override
  void initState() {
    super.initState();
    _servings = widget.recipe.servings;
  }

  void _addServing() {
    setState(() => _servings++);
  }

  void _removeServing() {
    if (_servings > 1) {
      setState(() => _servings--);
    }
  }

  void _onMenuSelected(_MenuAction action) {
    switch (action) {
      case _MenuAction.rename:
        _renameRecipe();
      case _MenuAction.delete:
        _deleteRecipe();
    }
  }

  // Ubah nama: dialog berisi TextField, lalu PUT /recipes/{id}
  Future<void> _renameRecipe() async {
    final service = context.read<RecipeService>();
    final messenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController(text: widget.recipe.name);

    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Ubah nama resep'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nama baru'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
    // Tunda dispose sampai animasi tutup dialog selesai
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());

    if (newName == null || newName.isEmpty) return;
    if (!mounted) return;

    try {
      final updated = await service.updateRecipe(
        id: widget.recipe.id,
        name: newName,
      );
      if (!mounted) return;
      // dummyjson hanya menyimulasikan perubahan, jadi cukup ditampilkan
      messenger.showSnackBar(
        SnackBar(content: Text('Nama diubah menjadi "${updated.name}".')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Gagal mengubah: $e')));
    }
  }

  // Hapus: dialog konfirmasi, lalu DELETE /recipes/{id}
  Future<void> _deleteRecipe() async {
    final service = context.read<RecipeService>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus resep?'),
          content: Text('Resep "${widget.recipe.name}" akan dihapus.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    if (!mounted) return;

    try {
      final deleted = await service.deleteRecipe(widget.recipe.id);
      if (!mounted) return;
      if (deleted) {
        messenger.showSnackBar(
          SnackBar(content: Text('"${widget.recipe.name}" dihapus.')),
        );
        navigator.pop(); // tutup halaman detail
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final totalCalories = recipe.caloriesPerServing * _servings;

    final isFavorite = context.watch<FavoriteProvider>().isFavorite(recipe);

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.name),
        actions: [
          IconButton(
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: () => context.read<FavoriteProvider>().toggle(recipe),
          ),
          PopupMenuButton<_MenuAction>(
            onSelected: _onMenuSelected,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _MenuAction.rename,
                child: Text('Ubah nama'),
              ),
              PopupMenuItem(value: _MenuAction.delete, child: Text('Hapus')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: RecipeImage(url: recipe.image),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${recipe.cuisine} • ${recipe.difficulty} • ${recipe.totalTimeMinutes} menit',
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Text('Porsi', style: textTheme.titleMedium),
                  const Spacer(),
                  IconButton.filledTonal(
                    onPressed: _servings > 1 ? _removeServing : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('$_servings', style: textTheme.titleLarge),
                  ),
                  IconButton.filledTonal(
                    onPressed: _addServing,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total kalori: $totalCalories kkal',
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          Text('Bahan', style: textTheme.titleLarge),
          for (final item in recipe.ingredients)
            ListTile(
              dense: true,
              leading: const Icon(Icons.check_circle_outline),
              title: Text(item),
            ),
          if (recipe.instructions.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Langkah', style: textTheme.titleLarge),
            for (final (index, step) in recipe.instructions.indexed)
              ListTile(
                dense: true,
                leading: CircleAvatar(radius: 12, child: Text('${index + 1}')),
                title: Text(step),
              ),
          ],
        ],
      ),
    );
  }
}
