import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

import '../models/ingredient.dart';


class ApiService {

  // 10.2.0.2 reaches the host machine from the Android emulator.
  // Swap to your machine's LAN IP (e.g. "http://192.168.1.129:8000")
  // when testing on a real physical device over Wi-Fi.
  static const String baseUrl = "http://10.0.2.2:8000";

  static const _timeout = Duration(seconds: 10);



  // GET inventory
  static Future<List<Ingredient>> getInventory() async {

    final response = await http.get(
      Uri.parse("$baseUrl/inventory")
    ).timeout(_timeout);


    if (response.statusCode == 200) {

      List data = jsonDecode(response.body);


      return data
          .map((item) => Ingredient.fromJson(item))
          .toList();

    } else {

      throw Exception(
        "Failed to load inventory"
      );

    }
  }



  // POST ingredient
  static Future<void> addIngredient(
      Ingredient ingredient) async {


    final response = await http.post(

      Uri.parse(
        "$baseUrl/ingredient"
      ),

      headers: {
        "Content-Type": "application/json",
      },

      body: jsonEncode(
        ingredient.toJson()
      ),

    ).timeout(_timeout);


    if (response.statusCode != 200) {

      throw Exception(
        "Failed to add ingredient"
      );

    }

  }

    static Future<void> updateIngredient(
      int id, Ingredient ingredient) async {

    final response = await http.put(
      Uri.parse("$baseUrl/ingredient/$id"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(
        ingredient.toJson()
      ),
    ).timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception(
        "Failed to update ingredient",
      );
    }
  }

    static Future<void> deleteIngredient(
      int id) async {

    final response = await http.delete(
      Uri.parse("$baseUrl/ingredient/$id"),
    ).timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception(
        "Failed to delete ingredient",
      );
    }
  }

  static Future<List<String>>
    getRecipes() async {

      final response = await http.get(
        Uri.parse("$baseUrl/recipes"),
      ).timeout(_timeout);

      if (response.statusCode == 200) {

        List data =
            jsonDecode(response.body);

        return data
            .map<String>(
                (item) => item.toString())
            .toList();

      }

      throw Exception(
        "Failed to load recipes",
      );
    }

    static Future<List<Map<String, dynamic>>>
        getRecipesDetailed() async {

      final response = await http.get(
        Uri.parse("$baseUrl/recipes"),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data
            .map<Map<String, dynamic>>(
                (item) => Map<String, dynamic>.from(item))
            .toList();
      }

      throw Exception("Failed to load recipes");
    }

    static Future<String?> getAiRecommendation() async {
      final response = await http.get(
        Uri.parse("$baseUrl/ai-recommendation"),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data["recipe_name"] as String?;
      }

      throw Exception("Failed to load AI recommendation");
    }

    static Future<List<Map<String, dynamic>>>
        getExpiryStatus() async {

      final response = await http.get(
        Uri.parse("$baseUrl/expiry-status"),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data
            .map<Map<String, dynamic>>(
                (item) => Map<String, dynamic>.from(item))
            .toList();
      }

      throw Exception("Failed to load expiry status");
    }
}
