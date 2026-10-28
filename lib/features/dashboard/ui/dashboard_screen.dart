import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/app_storage.dart';
import '../../../main.dart';
import '../../people/models/person_model.dart';
import '../../people/ui/widgets/add_person_dialog.dart';
import 'widgets/grand_total_card.dart';
import 'widgets/person_balance_card.dart';
import '../../receipts/models/receipt_model.dart';
import '../../receipts/services/ai_receipt_parser.dart';
import '../../receipts/ui/receipt_detail_screen.dart';
import '../../settings/ui/settings_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _processReceipt(BuildContext context, WidgetRef ref, ImageSource source) async {
    // 1. Instantly open camera or gallery
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile == null) return; // User cancelled

    // 2. Show loading dialog
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Gemini Vision is analyzing...', style: TextStyle(color: Colors.white, decoration: TextDecoration.none, fontSize: 14)),
          ],
        ),
      ),
    );

    try {
      // 3. Move from temp cache to persistent Android AppStorage
      final fileName = 'receipt_${const Uuid().v4()}.jpg';
      final destinationPath = await AppStorage.getImagePath(fileName);
      final savedFile = await File(pickedFile.path).copy(destinationPath);

      // 4. Send the physical file directly to Gemini
      final parsedData = await AiReceiptParser.parseReceiptImage(savedFile);

      if (parsedData != null) {
        final dbService = ref.read(dbProvider);
        final receiptId = const Uuid().v4();

        // 5. Save Receipt with persistent image path
        final newReceipt = Receipt(
          receiptId: receiptId,
          name: 'New Receipt',
          store: parsedData.storeName ?? 'Unknown Store',
          date: DateTime.now(),
          receiptImg: savedFile.path,
        );
        await dbService.saveReceipt(newReceipt);

        // 6. Save all items extracted by Gemini
        for (var item in parsedData.items) {
          item.receiptId = receiptId;
          await dbService.saveItem(item);
        }

        // 7. Route to details screen to allow user to edit/tag!
        if (context.mounted) {
          Navigator.pop(context); // Close loading
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ReceiptDetailScreen(receipt: newReceipt)),
          );
          return;
        }
      }
    } catch (e) {
      print("Gemini Scan Error: $e");
    }

    // Handle failure
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scan failed')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbService = ref.watch(dbProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Butterfly Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Person>>(
        future: dbService.getActivePeople(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final people = snapshot.data!;
          return Column(
            children: [
              const GrandTotalCard(total: 0.0),
              Expanded(
                child: people.isEmpty
                    ? const Center(child: Text('Add people to see their balances.'))
                    : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12.0,
                    mainAxisSpacing: 12.0,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: people.length,
                  itemBuilder: (context, index) {
                    return PersonBalanceCard(person: people[index], total: 0.0);
                  },
                ),
              ),
            ],
          );
        },
      ),

      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        spacing: 15,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.person_add),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            label: 'Add Person',
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const AddPersonDialog(),
              ).then((_) {
                if (context.mounted) (context as Element).markNeedsBuild();
              });
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.camera_alt),
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            label: 'Scan Receipt',
            onTap: () => _processReceipt(context, ref, ImageSource.camera),
          ),
          SpeedDialChild(
            child: const Icon(Icons.photo_library),
            backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
            label: 'Upload from Gallery',
            onTap: () => _processReceipt(context, ref, ImageSource.gallery),
          ),
        ],
      ),
    );
  }
}