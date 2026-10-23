import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../main.dart';
import '../models/receipt_model.dart';
import '../models/item_model.dart';


class ReceiptDetailScreen extends ConsumerWidget {
  final Receipt receipt;
  const ReceiptDetailScreen({super.key, required this.receipt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbService = ref.watch(dbProvider);

    return Scaffold(
      appBar: AppBar(title: Text(receipt.store)),
      body: Column(
        children: [
          // 1. The OCR Reference Box
          if (receipt.rawOcrText != null && receipt.rawOcrText!.isNotEmpty)
            Container(
              height: 150,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: SingleChildScrollView(
                child: SelectableText(
                  receipt.rawOcrText!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),

          const Divider(height: 1),

          // 2. The Items List
          Expanded(
            child: FutureBuilder<List<Item>>(
              future: dbService.getItemsForReceipt(receipt.receiptId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final items = snapshot.data!;
                if (items.isEmpty) return const Center(child: Text('No items added yet.'));

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      title: Text(item.itemName),
                      subtitle: Text('Qty: ${item.itemQty}'),
                      trailing: Text(
                        '\$${item.itemPrice.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AddItemDialog(receiptId: receipt.receiptId),
          ).then((_) {
            if (context.mounted) (context as Element).markNeedsBuild();
          });
        },
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Add Item'),
      ),
    );
  }
}

// -----------------------------------------------------------------
// The Popup Dialog to Add an Item
// -----------------------------------------------------------------
class AddItemDialog extends ConsumerStatefulWidget {
  final String receiptId;
  const AddItemDialog({super.key, required this.receiptId});

  @override
  ConsumerState<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends ConsumerState<AddItemDialog> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _qtyController = TextEditingController(text: '1'); // Default qty to 1

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    final name = _nameController.text.trim();
    final priceText = _priceController.text.trim();
    final qtyText = _qtyController.text.trim();

    if (name.isEmpty || priceText.isEmpty || qtyText.isEmpty) return;

    // Convert strings to numbers safely
    final price = double.tryParse(priceText) ?? 0.0;
    final qty = int.tryParse(qtyText) ?? 1;

    final newItem = Item(
      itemId: const Uuid().v4(),
      receiptId: widget.receiptId,
      itemName: name,
      itemPrice: price,
      itemQty: qty,
      splitType: 'equal', // Default
    );
    // assignedPersonIds is left empty, meaning it will show up on your Untagged Items screen!

    await ref.read(dbProvider).saveItem(newItem);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Item Name', border: OutlineInputBorder()),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _priceController,
                    decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder(), prefixText: '\$'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _qtyController,
                    decoration: const InputDecoration(labelText: 'Qty', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _saveItem, child: const Text('Add')),
      ],
    );
  }
}