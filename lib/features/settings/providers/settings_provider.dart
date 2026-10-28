import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../main.dart'; // Imports dbProvider

class ApiKeyNotifier extends Notifier<String?> {
  @override
  String? build() {
    loadApiKey();
    return null;
  }

  Future<void> loadApiKey() async {
    final db = ref.read(dbProvider);
    final key = await db.getSetting('gemini_api_key');
    state = key;
  }

  Future<void> saveApiKey(String newKey) async {
    final db = ref.read(dbProvider);
    await db.saveSetting('gemini_api_key', newKey);
    state = newKey;
  }
}

final apiKeyProvider = NotifierProvider<ApiKeyNotifier, String?>(() {
  return ApiKeyNotifier();
});