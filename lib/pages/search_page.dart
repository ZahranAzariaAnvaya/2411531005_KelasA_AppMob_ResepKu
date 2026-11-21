import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resepku/models/recipe.dart';
import 'package:resepku/services/recipe_service.dart';
import 'package:resepku/widgets/error_view.dart';
import 'package:resepku/widgets/recipe_tile.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  String _query = '';
  // null = user belum mencari
  Future<List<Recipe>>? _resultsFuture;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Future baru dibuat di dalam setState, hanya saat user menekan Enter
  void _search(String query) {
    final text = query.trim();
    if (text.isEmpty) return;
    setState(() {
      _query = text;
      _resultsFuture = context.read<RecipeService>().searchRecipes(text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Cari resep, misalnya pasta',
            border: InputBorder.none,
          ),
          onSubmitted: _search,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Belum mencari
    if (_resultsFuture == null) {
      return const Center(child: Text('Ketik kata kunci lalu tekan Enter.'));
    }

    return FutureBuilder<List<Recipe>>(
      future: _resultsFuture,
      builder: (context, snapshot) {
        // 1. Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // 2. Error state
        if (snapshot.hasError) {
          return ErrorView(
            message: 'Gagal mencari resep.\n${snapshot.error}',
            onRetry: () => _search(_query),
          );
        }
        // 3. Hasil kosong
        final recipes = snapshot.data ?? [];
        if (recipes.isEmpty) {
          return Center(child: Text('Tidak ada resep untuk "$_query".'));
        }
        // 4. Data state
        return ListView.builder(
          itemCount: recipes.length,
          itemBuilder: (context, index) => RecipeTile(recipe: recipes[index]),
        );
      },
    );
  }
}
