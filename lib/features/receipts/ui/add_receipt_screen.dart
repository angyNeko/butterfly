import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../core/config/app_storage.dart';
import '../../../main.dart';
import '../models/item_model.dart';
import '../models/receipt_model.dart';
import '../services/ai_receipt_parser.dart';
import 'receipt_detail_screen.dart'; // Ensure exact spelling matches your file

class AddReceiptScreen extends ConsumerStatefulWidget {
  const AddReceiptScreen({super.key});

  @override
  ConsumerState<AddReceiptScreen> createState() => _AddReceiptScreenState();
}

class _AddReceiptScreenState extends ConsumerState<AddReceiptScreen> {
  final _storeController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isScanning = false;

  List<Item> _scannedItems = [];
  String? _persistentImagePath;

  @override
  void dispose() {
    _storeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _scanReceipt(ImageSource source) async {
    setState(() => _isScanning = true);

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        // 1. Safely copy from temporary picker cache to persistent app storage
        final fileName = 'receipt_${const Uuid().v4()}.jpg';
        final destinationPath = await AppStorage.getImagePath(fileName);
        final savedFile = await File(pickedFile.path).copy(destinationPath);

        _persistentImagePath = savedFile.path;

        // 2. Pass the image file directly to the Multimodal Gemini Vision model
        final parsedData = await AiReceiptParser.parseReceiptImage(savedFile);

        if (parsedData != null) {
          setState(() {
            _scannedItems = parsedData.items;
            if (_storeController.text.isEmpty && parsedData.storeName != null) {
              _storeController.text = parsedData.storeName!;
            }
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _saveAndProceed() async {
    if (_storeController.text.trim().isEmpty) return;

    final dbService = ref.read(dbProvider);
    final receiptId = const Uuid().v4();

    // 1. Create Receipt with persistent image path
    final newReceipt = Receipt(
      receiptId: receiptId,
      name: _nameController.text.isEmpty ? 'New Receipt' : _nameController.text,
      store: _storeController.text.trim(),
      date: DateTime.now(),
      receiptImg: _persistentImagePath,
    );
    await dbService.saveReceipt(newReceipt);

    // 2. Save all scanned items
    for (var item in _scannedItems) {
      item.receiptId = receiptId;
      await dbService.saveItem(item);
    }

    // 3. Navigate to detail screen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ReceiptDetailScreen(receipt: newReceipt),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final receiptColor = isDark ? Colors.grey.shade900 : Colors.grey.shade100;

    return Scaffold(
      appBar: AppBar(title: const Text('Scan New Receipt')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          TextField(
            controller: _storeController,
            decoration: const InputDecoration(
              labelText: 'Store Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.storefront),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Receipt Name (Optional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.receipt_long),
            ),
          ),
          const SizedBox(height: 24),

          // Receipt Paper UI
          Container(
            height: 300,
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: receiptColor,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Theme.of(context).dividerColor, width: 2),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 20), blurRadius: 8, offset: const Offset(0, 4))
              ],
            ),
            child: _isScanning
                ? const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 24),
                Text('Gemini Vision is analyzing...', style: TextStyle(fontFamily: 'monospace')),
              ],
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _scannedItems.isEmpty
                      ? 'ITEMS:\n\nNo items yet.\nScan a receipt to auto-populate.'
                      : 'ITEMS (${_scannedItems.length} found):\n\n${_scannedItems.map((i) => "- ${i.itemName} (\$${i.itemPrice})").join('\n')}',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                ),
                const Spacer(),
                if (_scannedItems.isEmpty)
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      '*** WAITING FOR IMAGE ***',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 16),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isScanning ? null : () => _scanReceipt(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isScanning ? null : () => _scanReceipt(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _isScanning || _storeController.text.trim().isEmpty ? null : _saveAndProceed,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Save Receipt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}