// import 'package:uuid/uuid.dart';
// import '../models/item_model.dart';
// import '../models/receipt_model.dart';
//
// class ReceiptParser {
//   /// Parses raw text extracted by ML Kit and returns provisional database objects.
//   static ParsedReceiptData parseRawText(String rawText) {
//     // 1. Split raw output into clean lines
//     List<String> lines = rawText
//         .split('\n')
//         .map((line) => line.trim())
//         .where((line) => line.isNotEmpty)
//         .toList();
//
//     // 2. Extract Data using your heuristic algorithms
//     String? storeName = _extractStoreName(lines);
//     String? dateString = _extractDate(lines);
//     List<Item> items = _extractItems(lines);
//
//     return ParsedReceiptData(
//       storeName: storeName,
//       dateString: dateString,
//       items: items,
//       rawOcrText: rawText,
//     );
//   }
//
//   static String? _extractStoreName(List<String> lines) {
//     for (String line in lines) {
//       if (RegExp(r'^[=\-_]+$').hasMatch(line)) continue;
//       if (RegExp(r'[A-Za-z0-9]').hasMatch(line)) {
//         return line;
//       }
//     }
//     return null;
//   }
//
//   static String? _extractDate(List<String> lines) {
//     RegExp datePattern = RegExp(
//       r'([A-Za-z]{3}\s+\d{1,2},\s+\d{4}|\d{1,2}/\d{1,2}/\d{4}|\d{4}-\d{2}-\d{2})',
//       caseSensitive: false,
//     );
//     for (String line in lines) {
//       Match? match = datePattern.firstMatch(line);
//       if (match != null) return match.group(0);
//     }
//     return null;
//   }
//
//   static List<Item> _extractItems(List<String> lines) {
//     List<Item> items = [];
//
//     // Simplified to find ANY valid price anywhere on the line
//     RegExp pricePattern = RegExp(r'(P|\$|¥)?\s*\d+\.\d{2}');
//     RegExp qtyPattern = RegExp(r'\((\d+)\)');
//
//     // These words will be ignored so they don't accidentally become item names
//     RegExp summaryPattern = RegExp(
//       r'(subtotal|vat|total|tax|cash|card|payment|change)',
//       caseSensitive: false,
//     );
//
//     // This will act as the algorithm's "Memory"
//     String? pendingItemName;
//
//     for (String line in lines) {
//       if (summaryPattern.hasMatch(line)) continue;
//
//       Match? priceMatch = pricePattern.firstMatch(line);
//
//       if (priceMatch != null) {
//         // We found a price! Clean it and parse it.
//         String priceStr = priceMatch.group(0)!
//             .replaceAll(RegExp(r'[P\$¥\sA-Za-z*]'), '');
//
//         double parsedPrice = double.tryParse(priceStr) ?? 0.0;
//
//         int quantity = 1;
//         Match? qtyMatch = qtyPattern.firstMatch(line);
//         if (qtyMatch != null) {
//           quantity = int.tryParse(qtyMatch.group(1)!) ?? 1;
//         }
//
//         // Strip price and qty from the line to see if a name is attached
//         String itemName = line
//             .replaceAll(pricePattern, '')
//             .replaceAll(qtyPattern, '')
//             .replaceAll(RegExp(r'[._\-=]+$'), '')
//             .trim();
//
//         // If itemName is empty, ML Kit put the price on its own line!
//         // Let's pair it with the orphaned name we saved in memory.
//         if (itemName.isEmpty && pendingItemName != null) {
//           itemName = pendingItemName;
//           pendingItemName = null; // Clear memory after pairing them
//         } else if (itemName.isEmpty) {
//           itemName = 'Unknown Item';
//         }
//
//         items.add(Item(
//           itemId: const Uuid().v4(),
//           receiptId: '',
//           itemName: itemName,
//           itemPrice: parsedPrice,
//           itemQty: quantity,
//           splitType: 'equal',
//         ));
//       } else {
//         // There is NO price on this line.
//         // If it's a valid word, save it to memory! It might be an item name waiting for its price.
//         if (line.length > 2 && !RegExp(r'^[=\-_]+$').hasMatch(line)) {
//           pendingItemName = line;
//         }
//       }
//     }
//     return items;
//   }
// }
//
// // A helper class to pass the structured data back to the UI
// class ParsedReceiptData {
//   final String? storeName;
//   final String? dateString;
//   final List<Item> items;
//   final String rawOcrText;
//
//   ParsedReceiptData({
//     required this.storeName,
//     required this.dateString,
//     required this.items,
//     required this.rawOcrText,
//   });
// }