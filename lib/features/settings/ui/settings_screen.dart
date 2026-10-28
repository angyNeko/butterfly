import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isObscured = true;

  static const Map<String, String> _presetCurrencies = {
    '₱': '₱ (PHP - Philippine Peso)',
    '\$': '\$ (USD - US Dollar)',
    '€': '€ (EUR - Euro)',
    '£': '£ (GBP - British Pound)',
    '¥': '¥ (JPY/CNY - Yen/Yuan)',
    '₩': '₩ (KRW - Won)',
    '₹': '₹ (INR - Indian Rupee)',
    'C\$': 'C\$ (CAD - Canadian Dollar)',
    'A\$': 'A\$ (AUD - Australian Dollar)',
    'S\$': 'S\$ (SGD - Singapore Dollar)',
  };

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _showCustomCurrencyDialog(String currentCurrency) async {
    final controller = TextEditingController(text: currentCurrency);
    final custom = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Currency Symbol'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Currency Symbol / Code',
            hintText: 'e.g. CHF, R\$, kr, ฿',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (custom != null && custom.isNotEmpty) {
      await ref.read(currencyProvider.notifier).saveCurrency(custom);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Default currency set to $custom')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(themeModeProvider);
    final apiKey = ref.watch(apiKeyProvider);
    final currentCurrency = ref.watch(currencyProvider);

    // Keep controller synced if API key loads from database
    if (apiKey != null && _apiKeyController.text != apiKey) {
      if (_apiKeyController.text.isEmpty) {
        _apiKeyController.text = apiKey;
      }
    }

    final isPreset = _presetCurrencies.containsKey(currentCurrency);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: [
          // 1. Theme Setting
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('App Theme'),
            subtitle: const Text('Choose light, dark, or system default'),
            trailing: DropdownButton<ThemeMode>(
              value: currentTheme,
              onChanged: (ThemeMode? newMode) {
                if (newMode != null) {
                  ref.read(themeModeProvider.notifier).setTheme(newMode);
                }
              },
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('System'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text('Light'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text('Dark'),
                ),
              ],
            ),
          ),

          const Divider(),

          // 2. Default Currency Setting
          ListTile(
            leading: const Icon(Icons.payments_outlined),
            title: const Text('Default Currency'),
            subtitle: Text(
              isPreset ? _presetCurrencies[currentCurrency]! : 'Custom ($currentCurrency)',
            ),
            trailing: DropdownButton<String>(
              value: isPreset ? currentCurrency : 'custom',
              onChanged: (String? val) {
                if (val == null) return;
                if (val == 'custom') {
                  _showCustomCurrencyDialog(currentCurrency);
                } else {
                  ref.read(currencyProvider.notifier).saveCurrency(val);
                }
              },
              items: [
                ..._presetCurrencies.entries.map(
                  (e) => DropdownMenuItem(
                    value: e.key,
                    child: Text('${e.key} - ${e.value.split(" - ").first.replaceAll(RegExp(r'[^A-Z]'), '')}'),
                  ),
                ),
                DropdownMenuItem(
                  value: 'custom',
                  child: Text(isPreset ? 'Custom...' : 'Custom ($currentCurrency)'),
                ),
              ],
            ),
            onTap: () => _showCustomCurrencyDialog(currentCurrency),
          ),

          const Divider(),

          // 3. Gemini API Key Setting
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.key),
                    SizedBox(width: 12),
                    Text(
                      'Gemini API Key',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Required for AI receipt parsing.',
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _apiKeyController,
                        obscureText: _isObscured,
                        decoration: InputDecoration(
                          hintText: 'Enter your Gemini API key',
                          isDense: true,
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility),
                            onPressed: () {
                              setState(() {
                                _isObscured = !_isObscured;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final newKey = _apiKeyController.text.trim();
                        await ref.read(apiKeyProvider.notifier).saveApiKey(newKey);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Gemini API Key saved')),
                          );
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
