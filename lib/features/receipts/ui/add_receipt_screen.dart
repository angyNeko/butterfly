import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../main.dart'; // Imports dbProvider
import '../models/receipt_model.dart';
import '../services/ocr_service.dart';

class AddReceiptScreen extends ConsumerStatefulWidget {
  const AddReceiptScreen({super.key});

  @override
  ConsumerState<AddReceiptScreen> createState() => _AddReceiptScreenState();
}

class _AddReceiptScreenState extends ConsumerState<AddReceiptScreen> {
  final _storeController = TextEditingController();
  final _nameController = TextEditingController();
  String _scannedText = "No text scanned yet.";
  bool _isScanning = false;

  @override
  void dispose() {
    _storeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _scanImage(ImageSource source) async {
    setState(() => _isScanning = true);
    final ocrService = ref.read(ocrProvider);
    final text = await ocrService.scanReceipt(source);

    if (text != null) {
      setState(() => _scannedText = text);
    }
    setState(() => _isScanning = false);
  }

  Future<void> _saveReceipt() async {
    if (_storeController.text.isEmpty) return;

    final newReceipt = Receipt(
      receiptId: const Uuid().v4(),
      name: _nameController.text.isEmpty ? 'New Receipt' : _nameController.text,
      store: _storeController.text,
      date: DateTime.now(),
      rawOcrText: _scannedText,
    );

    await ref.read(dbProvider).saveReceipt(newReceipt);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Receipt')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _storeController,
              decoration: const InputDecoration(labelText: 'Store Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Receipt Name (Optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isScanning ? null : () => _scanImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
                ElevatedButton.icon(
                  onPressed: _isScanning ? null : () => _scanImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo),
                  label: const Text('Gallery'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Scanned Text (Use this to read prices):', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              height: 200,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: _isScanning
                    ? const Center(child: CircularProgressIndicator())
                    : Text(_scannedText),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saveReceipt,
              child: const Text('Save Receipt'),
            ),
          ],
        ),
      ),
    );
  }
}