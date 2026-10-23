import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';
import '../models/item_model.dart';

class AiReceiptParser {
  // Replace with your actual Gemini API key (or load it from environment variables)
  static const String _apiKey = 'YOUR_GEMINI_API_KEY';

  static Future<ParsedAiReceiptResult?> parseReceiptWithAI(String rawText) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: Schema.object(
            description: 'Structured receipt data extracted from raw OCR text',
            properties: {
              'storeName': Schema.string(description: 'The name of the store or merchant'),
              'dateString': Schema.string(description: 'The date of the transaction (e.g. Oct 15, 2026 or 2026-10-15)'),
              'items': Schema.array(
                description: 'List of purchased items',
                items: Schema.object(
                  properties: {
                    'name': Schema.string(description: 'Name of the item'),
                    'quantity': Schema.integer(description: 'Quantity purchased (default to 1 if not specified)'),
                    'price': Schema.number(description: 'Total price for this line item as a decimal number'),
                  },
                  requiredFields: ['name', 'quantity', 'price'],
                ),
              ),
            },
            requiredFields: ['storeName', 'items'],
          ),
        ),
      );

      final prompt = '''
      You are an expert receipt parser. Analyze the following raw OCR text extracted from a store receipt. 
      Extract the store name, transaction date, and a list of all purchased items with their quantities and prices. Ignore taxes, subtotals, and change lines, focusing only on individual items.
      
      Raw OCR Text:
      $rawText
      ''';

      final response = await model.generateContent([Content.text(prompt)]);
      final jsonResponse = jsonDecode(response.text ?? '{}');

      // Map the AI JSON response directly into your Sembast Item objects
      String? storeName = jsonResponse['storeName'];
      String? dateString = jsonResponse['dateString'];

      List<Item> items = [];
      if (jsonResponse['items'] != null) {
        for (var itemJson in jsonResponse['items']) {
          items.add(Item(
            itemId: const Uuid().v4(),
            receiptId: '', // Assigned later when saving
            itemName: itemJson['name'] ?? 'Unknown Item',
            itemPrice: (itemJson['price'] as num?)?.toDouble() ?? 0.0,
            itemQty: itemJson['quantity'] ?? 1,
            splitType: 'equal',
          ));
        }
      }

      return ParsedAiReceiptResult(
        storeName: storeName,
        dateString: dateString,
        items: items,
        rawOcrText: rawText,
      );
    } catch (e) {
      print('AI Parsing Error: $e');
      return null;
    }
  }
}

class ParsedAiReceiptResult {
  final String? storeName;
  final String? dateString;
  final List<Item> items;
  final String rawOcrText;

  ParsedAiReceiptResult({
    required this.storeName,
    required this.dateString,
    required this.items,
    required this.rawOcrText,
  });
}