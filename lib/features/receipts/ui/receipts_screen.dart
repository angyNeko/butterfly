import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ocr_service.dart';

class ReceiptsScreen extends ConsumerWidget {
  const ReceiptsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipts'),
      ),
      body: const Center(
        child: Text('Receipts list will go here.'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Access the OCR service
          final ocrService = ref.read(ocrProvider);

          // Open the camera (you can change this to ImageSource.gallery to test existing photos)
          final extractedText = await ocrService.scanReceipt(ImageSource.camera);

          if (extractedText != null) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scan complete!')),
              );
            }
          }
        },
        child: const Icon(Icons.document_scanner),
      ),
    );
  }
}