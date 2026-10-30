import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';
import '../models/item_model.dart';

class ParsedReceiptData {
  final String? storeName;
  final String? currency;
  final List<Item> items;
  ParsedReceiptData({this.storeName, this.currency, required this.items});
}

class AiReceiptParser {
  // Pass the image File directly along with the user's API key
  static Future<ParsedReceiptData?> parseReceipt(File imageFile, String apiKey) async {
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty) {
      throw Exception('Gemini API key is empty.');
    }

    final model = GenerativeModel(
      model: 'gemini-3.5-flash-lite', // do not change to 1.5 flash; 1.5 is not available anymore
      apiKey: cleanKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );

    final prompt = TextPart('''
Extract the store name, detected currency symbol, and all purchased items from this receipt image.

MANDATORY RULES FOR ITEMS AND QUANTITY:
1. EVERY item in the "items" array MUST have "itemQty": 1.
2. If an item on the receipt has a quantity greater than 1 (for example: "Spam + Egg (2) P258.00" or "2x Latte \$10.00"):
   - Split it into separate individual items with "itemQty": 1 each!
   - Compute the unit price ("itemPrice" = total line price divided by quantity).
   - For example, "Spam + Egg (2) P258.00" must become TWO separate items in the list:
     {"itemName": "Spam + Egg", "itemPrice": 129.00, "itemQty": 1},
     {"itemName": "Spam + Egg", "itemPrice": 129.00, "itemQty": 1}
3. Never output an item with "itemQty" greater than 1. Each individual physical item must be its own entry so it can be tagged to a specific person.
4. Detect the currency symbol if present on the receipt (e.g. "₱" or "P" for Philippine Peso, "\$" for Dollar, "€" for Euro, etc.).
5. Exclude subtotal, discounts, total savings, VAT/tax, service charge, and total. Only list real items.

Respond ONLY with valid JSON in this exact structure:
{
  "storeName": "Store Name",
  "receiptDate": "MM/DD/YYYY",
  "currency": "PHP",
  "items": [
    {"itemName": "Item Name", "itemPrice": 12.50, "itemQty": 1}
  ]
}
''');

    // Convert image to bytes
    final imageBytes = await imageFile.readAsBytes();
    String mimeType = 'image/jpeg';
    if (imageBytes.length >= 8 &&
        imageBytes[0] == 0x89 &&
        imageBytes[1] == 0x50 &&
        imageBytes[2] == 0x4E &&
        imageBytes[3] == 0x47) {
      mimeType = 'image/png';
    } else if (imageBytes.length >= 12 &&
        imageBytes[0] == 0x52 &&
        imageBytes[1] == 0x49 &&
        imageBytes[2] == 0x46 &&
        imageBytes[3] == 0x46 &&
        imageBytes[8] == 0x57 &&
        imageBytes[9] == 0x45 &&
        imageBytes[10] == 0x42 &&
        imageBytes[11] == 0x50) {
      mimeType = 'image/webp';
    }

    final imagePart = DataPart(mimeType, imageBytes);

    // Send image + prompt to Gemini
    final response = await model.generateContent([
      Content.multi([prompt, imagePart])
    ]);

    final responseText = response.text;
    if (responseText == null || responseText.trim().isEmpty) {
      throw Exception('Gemini returned an empty response.');
    }

    print(responseText);

    final firstBrace = responseText.indexOf('{');
    final lastBrace = responseText.lastIndexOf('}');
    if (firstBrace == -1 || lastBrace == -1) {
      throw Exception('Could not parse JSON from Gemini response.');
    }

    final jsonString = responseText.substring(firstBrace, lastBrace + 1);
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;

    String? detectedCurrency = decoded['currency']?.toString().trim();
    if (detectedCurrency != null && detectedCurrency.isNotEmpty) {
      if (detectedCurrency.toUpperCase() == 'P' || detectedCurrency.toUpperCase() == 'PHP') {
        detectedCurrency = '₱';
      } else if (detectedCurrency.toUpperCase() == 'USD') {
        detectedCurrency = '\$';
      } else if (detectedCurrency.toUpperCase() == 'EUR') {
        detectedCurrency = '€';
      }
    } else {
      detectedCurrency = null;
    }

    List<Item> parsedItems = [];
    if (decoded['items'] is List) {
      for (var i in (decoded['items'] as List)) {
        if (i is Map) {
          final itemName = i['itemName']?.toString().trim() ?? 'Unknown Item';
          final rawPrice = double.tryParse(i['itemPrice']?.toString() ?? '') ?? 0.0;
          int qty = int.tryParse(i['itemQty']?.toString() ?? '') ?? 1;
          if (qty < 1) qty = 1;

          // If AI still returned qty > 1, expand into multiple single-qty items
          final unitPrice = qty > 1 ? (rawPrice / qty) : rawPrice;
          final roundedPrice = double.parse(unitPrice.toStringAsFixed(2));

          for (int q = 0; q < qty; q++) {
            parsedItems.add(
              Item(
                itemId: const Uuid().v4(),
                receiptId: '', // Assigned by caller
                itemName: itemName,
                itemPrice: roundedPrice,
                itemQty: 1,
                splitType: "equal",
                assignedPersonIds: [],
              ),
            );
          }
        }
      }
    }

    return ParsedReceiptData(
      storeName: decoded['storeName']?.toString().trim(),
      currency: detectedCurrency,
      items: parsedItems,
    );
  }
}
