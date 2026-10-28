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

class CurrencyNotifier extends Notifier<String> {
  static const String defaultCurrency = '₱'; // Default to Peso or $

  @override
  String build() {
    loadCurrency();
    return defaultCurrency;
  }

  Future<void> loadCurrency() async {
    final db = ref.read(dbProvider);
    final currency = await db.getSetting('default_currency');
    if (currency != null && currency.isNotEmpty) {
      state = currency;
    }
  }

  Future<void> saveCurrency(String newCurrency) async {
    final clean = newCurrency.trim();
    if (clean.isEmpty) return;
    final db = ref.read(dbProvider);
    await db.saveSetting('default_currency', clean);
    state = clean;
  }
}

final currencyProvider = NotifierProvider<CurrencyNotifier, String>(() {
  return CurrencyNotifier();
});
