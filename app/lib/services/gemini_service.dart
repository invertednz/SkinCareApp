import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'env.dart';
import 'data_mode.dart';

/// Service for Gemini AI food recognition from meal photos
class GeminiService {
  static GeminiService? _instance;
  GenerativeModel? _model;

  GeminiService._();

  static GeminiService get instance {
    _instance ??= GeminiService._();
    return _instance!;
  }

  /// Initialize the Gemini model
  void _ensureInitialized() {
    if (_model != null) return;
    
    final apiKey = Env.geminiApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not configured in .env');
    }

    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );
  }

  /// Check if Gemini is available (not in mock mode and API key configured)
  static bool get isAvailable {
    if (DataModeService.isMock) return false;
    final apiKey = Env.geminiApiKey;
    return apiKey != null && apiKey.isNotEmpty;
  }

  /// Analyze a meal photo and extract food items
  /// Returns a list of food items detected in the image
  Future<MealAnalysisResult> analyzeMealPhoto(Uint8List imageBytes) async {
    // In mock mode, return mock data
    if (DataModeService.isMock) {
      return _getMockResult();
    }

    _ensureInitialized();

    try {
      final prompt = '''
Analyze this meal photo and identify all food items visible.
Return a JSON object with the following structure:
{
  "foods": [
    {"name": "food item name", "portion": "estimated portion size", "category": "breakfast|lunch|dinner|snack"}
  ],
  "meal_type": "breakfast|lunch|dinner|snack",
  "notes": "any relevant observations about the meal"
}

Be specific about food items (e.g., "grilled chicken breast" not just "chicken").
Estimate portion sizes when visible (e.g., "1 cup", "2 slices", "medium bowl").
If you cannot identify a food clearly, use your best guess with a note.
Only return valid JSON, no additional text.
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _model!.generateContent(content);
      final text = response.text;

      if (text == null || text.isEmpty) {
        throw Exception('Empty response from Gemini');
      }

      return _parseResponse(text);
    } catch (e) {
      // Return error result
      return MealAnalysisResult(
        foods: [],
        mealType: null,
        notes: 'Analysis failed: $e',
        error: e.toString(),
      );
    }
  }

  MealAnalysisResult _parseResponse(String text) {
    try {
      // Clean up the response - remove markdown code blocks if present
      var cleanText = text.trim();
      if (cleanText.startsWith('```json')) {
        cleanText = cleanText.substring(7);
      } else if (cleanText.startsWith('```')) {
        cleanText = cleanText.substring(3);
      }
      if (cleanText.endsWith('```')) {
        cleanText = cleanText.substring(0, cleanText.length - 3);
      }
      cleanText = cleanText.trim();

      // Parse JSON manually to avoid importing dart:convert in multiple places
      final foods = <FoodItem>[];
      String? mealType;
      String? notes;

      // Simple JSON parsing for our known structure
      if (cleanText.contains('"foods"')) {
        // Extract foods array
        final foodsMatch = RegExp(r'"foods"\s*:\s*\[(.*?)\]', dotAll: true).firstMatch(cleanText);
        if (foodsMatch != null) {
          final foodsStr = foodsMatch.group(1) ?? '';
          // Extract individual food objects
          final foodMatches = RegExp(r'\{[^}]+\}').allMatches(foodsStr);
          for (final match in foodMatches) {
            final foodObj = match.group(0) ?? '';
            final name = _extractJsonString(foodObj, 'name');
            final portion = _extractJsonString(foodObj, 'portion');
            final category = _extractJsonString(foodObj, 'category');
            if (name != null && name.isNotEmpty) {
              foods.add(FoodItem(name: name, portion: portion, category: category));
            }
          }
        }

        // Extract meal_type
        mealType = _extractJsonString(cleanText, 'meal_type');
        
        // Extract notes
        notes = _extractJsonString(cleanText, 'notes');
      }

      return MealAnalysisResult(
        foods: foods,
        mealType: mealType,
        notes: notes,
      );
    } catch (e) {
      return MealAnalysisResult(
        foods: [],
        mealType: null,
        notes: 'Failed to parse response: $text',
        error: e.toString(),
      );
    }
  }

  String? _extractJsonString(String json, String key) {
    final pattern = RegExp('"$key"\\s*:\\s*"([^"]*)"');
    final match = pattern.firstMatch(json);
    return match?.group(1);
  }

  MealAnalysisResult _getMockResult() {
    return MealAnalysisResult(
      foods: [
        FoodItem(name: 'Grilled Chicken Breast', portion: '150g', category: 'lunch'),
        FoodItem(name: 'Mixed Green Salad', portion: '1 cup', category: 'lunch'),
        FoodItem(name: 'Brown Rice', portion: '1/2 cup', category: 'lunch'),
        FoodItem(name: 'Olive Oil Dressing', portion: '1 tbsp', category: 'lunch'),
      ],
      mealType: 'lunch',
      notes: 'Mock data - healthy balanced meal with protein, vegetables, and whole grains.',
    );
  }
}

/// Result of meal photo analysis
class MealAnalysisResult {
  final List<FoodItem> foods;
  final String? mealType;
  final String? notes;
  final String? error;

  MealAnalysisResult({
    required this.foods,
    this.mealType,
    this.notes,
    this.error,
  });

  bool get hasError => error != null;
  bool get isEmpty => foods.isEmpty;
}

/// Individual food item detected in a meal
class FoodItem {
  final String name;
  final String? portion;
  final String? category;

  FoodItem({
    required this.name,
    this.portion,
    this.category,
  });

  @override
  String toString() {
    if (portion != null && portion!.isNotEmpty) {
      return '$name ($portion)';
    }
    return name;
  }
}
