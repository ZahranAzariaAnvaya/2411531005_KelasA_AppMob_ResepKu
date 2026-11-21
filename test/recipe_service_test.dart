import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:resepku/models/recipe.dart';
import 'package:resepku/services/recipe_service.dart';

void main() {
  group('Recipe.fromJson', () {
    test('rating int 5 dibaca sebagai 5.0', () {
      final recipe = Recipe.fromJson({
        'id': 1,
        'name': 'Nasi Goreng',
        'rating': 5, // int, bukan 5.0
      });

      expect(recipe.rating, 5.0);
      expect(recipe.rating, isA<double>());
    });

    test('field yang tidak ada diberi nilai bawaan', () {
      final recipe = Recipe.fromJson({'id': 2, 'name': 'Soto'});

      expect(recipe.cuisine, '-');
      expect(recipe.difficulty, '-');
      expect(recipe.prepTimeMinutes, 0);
      expect(recipe.cookTimeMinutes, 0);
      expect(recipe.servings, 1);
      expect(recipe.caloriesPerServing, 0);
      expect(recipe.rating, 0.0);
      expect(recipe.image, '');
      expect(recipe.ingredients, isEmpty);
      expect(recipe.instructions, isEmpty);
    });
  });

  group('RecipeService.fetchRecipes', () {
    test('mengembalikan List<Recipe> dari respons palsu', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'recipes': [
              {'id': 1, 'name': 'Nasi Goreng', 'rating': 4.5},
              {'id': 2, 'name': 'Soto Ayam', 'rating': 5},
            ],
          }),
          200,
        );
      });
      final service = RecipeService(client: mockClient);

      final recipes = await service.fetchRecipes();

      expect(recipes, hasLength(2));
      expect(recipes.first.name, 'Nasi Goreng');
      expect(recipes.last.rating, 5.0);
    });

    test('melempar RecipeServiceException jika status 404', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Not Found', 404);
      });
      final service = RecipeService(client: mockClient);

      expect(service.fetchRecipes(), throwsA(isA<RecipeServiceException>()));
    });
  });
}
