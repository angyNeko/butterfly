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
  // Pass the image File directly instead of text
  static Future<ParsedReceiptData?> parseReceiptImage(File imageFile) async {
    final model = GenerativeModel(
      model: 'gemini-1.5-flash', // Multimodal model
      apiKey: 'YOUR_API_KEY_HERE',
    );

    try {
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

      final cleanJson = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
      final decoded = jsonDecode(cleanJson);

      List<Item> parsedItems = [];
      if (decoded['items'] != null) {
        for (var i in decoded['items']) {
          parsedItems.add(
              Item(
                itemId: const Uuid().v4(),
                receiptId: '', // Assigned in Dashboard later
                itemName: i['itemName']?.toString() ?? 'Unknown',
                itemPrice: double.tryParse(i['itemPrice'].toString()) ?? 0.0,
                itemQty: int.tryParse(i['itemQty'].toString()) ?? 1,
                splitType: "equal",
                assignedPersonIds: [],
              )
          );
        }
      }

      return ParsedReceiptData(
        storeName: decoded['storeName'],
        items: parsedItems,
      );

    } catch (_) {
      return null;
    }
  }
}