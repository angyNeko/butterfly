import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/app_storage.dart';
import '../../../main.dart';
import '../../people/models/person_model.dart';
import '../../people/ui/people_screen.dart';
import '../../people/ui/widgets/add_person_dialog.dart';
import '../../receipts/models/item_model.dart';
import '../../receipts/models/receipt_model.dart';
import '../../receipts/services/ai_receipt_parser.dart';
import '../../receipts/ui/receipt_detail_screen.dart';
import '../../receipts/ui/receipts_screen.dart';
import '../../receipts/ui/untagged_items_screen.dart';
import '../../settings/providers/settings_provider.dart';
import '../../settings/ui/settings_screen.dart';
import 'widgets/grand_total_card.dart';
import 'widgets/person_balance_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _processReceipt(BuildContext context, WidgetRef ref, ImageSource source) async {
    final apiKey = ref.read(apiKeyProvider);
    if (apiKey == null || apiKey.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please set your Gemini API key in Settings first.')),
        );
      }
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile == null) return;

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
            Text(
              'Gemini Vision is analyzing...',
              style: TextStyle(color: Colors.white, decoration: TextDecoration.none, fontSize: 14),
            ),
          ],
        ),
      ),
    );

    try {
      final fileName = 'receipt_${const Uuid().v4()}.jpg';
      final destinationPath = await AppStorage.getImagePath(fileName);
      final savedFile = await File(pickedFile.path).copy(destinationPath);

      final dbService = ref.read(dbProvider);
      final receiptId = const Uuid().v4();

      final newReceipt = Receipt(
        receiptId: receiptId,
        name: 'New Receipt',
        store: 'New Receipt',
        date: DateTime.now(),
        receiptImg: savedFile.path,
      );
      await dbService.saveReceipt(newReceipt);

      ParsedReceiptData? parsedData;
      String? parseNote;
      try {
        parsedData = await AiReceiptParser.parseReceipt(savedFile, apiKey);
      } catch (e) {
        parseNote = e.toString().replaceAll('Exception: ', '');
      }

      if (parsedData != null) {
        if (parsedData.storeName != null && parsedData.storeName!.trim().isNotEmpty) {
          final cleanStore = parsedData.storeName!.trim();
          newReceipt.store = cleanStore;
          newReceipt.name = cleanStore;
          await dbService.saveReceipt(newReceipt);
        }

        for (var item in parsedData.items) {
          item.receiptId = receiptId;
          await dbService.saveItem(item);
        }
      }

      if (context.mounted) {
        Navigator.pop(context);
        if (parseNote != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Receipt saved! (Note: $parseNote)')),
          );
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ReceiptDetailScreen(receipt: newReceipt)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan failed: $errorMsg')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbService = ref.watch(dbProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Butterfly', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          dbService.getActivePeople(),
          dbService.getPersonBalances(),
          dbService.getAllReceipts(),
          dbService.getUntaggedItems(),
          dbService.getAllItems(),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final people = snapshot.data![0] as List<Person>;
          final balances = snapshot.data![1] as Map<String, double>;
          final receipts = snapshot.data![2] as List<Receipt>;
          final untaggedItems = snapshot.data![3] as List<Item>;
          final allItems = snapshot.data![4] as List<Item>;

          final grandTotal = balances.values.fold<double>(0.0, (sum, val) => sum + val);

          // Calculate receipt totals and item counts
          final receiptTotals = <String, double>{};
          final receiptItemCounts = <String, int>{};
          for (final item in allItems) {
            receiptTotals[item.receiptId] = (receiptTotals[item.receiptId] ?? 0.0) + (item.itemPrice * item.itemQty);
            receiptItemCounts[item.receiptId] = (receiptItemCounts[item.receiptId] ?? 0) + 1;
          }

          // Sort receipts newest first
          final recentReceipts = List<Receipt>.from(receipts)
            ..sort((a, b) => b.date.compareTo(a.date));

          return ListView(
            padding: const EdgeInsets.only(bottom: 90),
            children: [
              // 1. Hero Total Card
              GrandTotalCard(
                total: grandTotal,
                peopleCount: people.length,
                receiptsCount: receipts.length,
                untaggedCount: untaggedItems.length,
                onUntaggedTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UntaggedItemsScreen()),
                  );
                },
              ),

              // 2. People Balances Section
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'People Balances',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PeopleScreen()),
                        );
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
              ),

              if (people.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(Icons.person_add_outlined, size: 40, color: theme.colorScheme.outline),
                          const SizedBox(height: 8),
                          Text('No people added yet', style: theme.textTheme.titleSmall),
                          const SizedBox(height: 12),
                          FilledButton.tonal(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => const AddPersonDialog(),
                              ).then((_) {
                                if (context.mounted) (context as Element).markNeedsBuild();
                              });
                            },
                            child: const Text('Add Person'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12.0,
                      mainAxisSpacing: 12.0,
                      childAspectRatio: 1.15,
                    ),
                    itemCount: people.length > 4 ? 4 : people.length,
                    itemBuilder: (context, index) {
                      final person = people[index];
                      final balance = balances[person.personId] ?? 0.0;
                      return PersonBalanceCard(
                        person: person,
                        total: balance,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PeopleScreen()),
                          );
                        },
                      );
                    },
                  ),
                ),

              const SizedBox(height: 20),

              // 3. Recent Receipts Section
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Receipts',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ReceiptsScreen()),
                        );
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
              ),

              if (recentReceipts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 40, color: theme.colorScheme.outline),
                          const SizedBox(height: 8),
                          Text('No receipts scanned yet', style: theme.textTheme.titleSmall),
                          const SizedBox(height: 4),
                          Text(
                            'Scan a receipt using the + button below',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: recentReceipts.length > 5 ? 5 : recentReceipts.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final receipt = recentReceipts[index];
                    final total = receiptTotals[receipt.receiptId] ?? 0.0;
                    final itemCount = receiptItemCounts[receipt.receiptId] ?? 0;

                    return Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReceiptDetailScreen(receipt: receipt),
                            ),
                          ).then((_) {
                            if (context.mounted) (context as Element).markNeedsBuild();
                          });
                        },
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          foregroundColor: theme.colorScheme.onPrimaryContainer,
                          child: const Icon(Icons.receipt_long, size: 20),
                        ),
                        title: Text(
                          receipt.store,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${DateFormat.yMMMd().format(receipt.date)} • $itemCount ${itemCount == 1 ? "item" : "items"}',
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: Text(
                          '\$${total.toStringAsFixed(2)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    );
                  },
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
            backgroundColor: theme.colorScheme.primaryContainer,
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
            backgroundColor: theme.colorScheme.secondaryContainer,
            label: 'Scan Receipt',
            onTap: () => _processReceipt(context, ref, ImageSource.camera),
          ),
          SpeedDialChild(
            child: const Icon(Icons.photo_library),
            backgroundColor: theme.colorScheme.tertiaryContainer,
            label: 'Upload from Gallery',
            onTap: () => _processReceipt(context, ref, ImageSource.gallery),
          ),
        ],
      ),
    );
  }
}
