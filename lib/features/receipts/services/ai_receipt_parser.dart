import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';
import '../models/item_model.dart';

class ParsedReceiptData {
  final String? storeName;
  final List<Item> items;
  ParsedReceiptData({this.storeName, required this.items});
}

class AiReceiptParser {
  // Pass the image File directly along with the user's API key
  static Future<ParsedReceiptData?> parseReceipt(File imageFile, String apiKey) async {
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty) {
      throw Exception('Gemini API key is empty.');
    }

    final model = GenerativeModel(
      model: 'gemini-3.5-flash-lite',
      apiKey: cleanKey,
    );

    final prompt = TextPart('''
    Extract the store name and items from this receipt image.
    Respond ONLY with valid JSON in this exact format:
    {
      "storeName": "Store Name",
      "items": [ {"itemName": "Item Name", "itemPrice": 10.50, "itemQty": 1} ]
    }
    ''');

    // Convert image to bytes
    final imageBytes = await imageFile.readAsBytes();
    final imagePart = DataPart('image/jpeg', imageBytes);

    // Send image + prompt to Gemini
    final response = await model.generateContent([
      Content.multi([prompt, imagePart])
    ]);

    final responseText = response.text;
    if (responseText == null || responseText.trim().isEmpty) {
      throw Exception('Gemini returned an empty response.');
    }

    final firstBrace = responseText.indexOf('{');
    final lastBrace = responseText.lastIndexOf('}');
    if (firstBrace == -1 || lastBrace == -1) {
      throw Exception('Could not parse JSON from Gemini response.');
    }

    final jsonString = responseText.substring(firstBrace, lastBrace + 1);
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;

    List<Item> parsedItems = [];
    if (decoded['items'] is List) {
      for (var i in (decoded['items'] as List)) {
        if (i is Map) {
          parsedItems.add(
            Item(
              itemId: const Uuid().v4(),
              receiptId: '', // Assigned in Dashboard later
              itemName: i['itemName']?.toString() ?? 'Unknown Item',
              itemPrice: double.tryParse(i['itemPrice']?.toString() ?? '') ?? 0.0,
              itemQty: int.tryParse(i['itemQty']?.toString() ?? '') ?? 1,
              splitType: "equal",
              assignedPersonIds: [],
            ),
          );
        }
      }
    }

    return ParsedReceiptData(
      storeName: decoded['storeName']?.toString(),
      items: parsedItems,
    );
  }
}
