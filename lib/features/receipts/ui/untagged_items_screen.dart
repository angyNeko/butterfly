import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../main.dart';
import '../models/item_model.dart';
import '../../people/models/person_model.dart';

class UntaggedItemsScreen extends ConsumerWidget {
  const UntaggedItemsScreen({super.key});

  void _openTaggingSheet(BuildContext context, WidgetRef ref, Item item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TagItemSheet(item: item),
    ).then((_) {
      if (context.mounted) {
        (context as Element).markNeedsBuild(); // Refresh list after sheet closes
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbService = ref.watch(dbProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Untagged Items')),
      body: FutureBuilder<List<Item>>(
        future: dbService.getUntaggedItems(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final items = snapshot.data!;
          if (items.isEmpty) return const Center(child: Text('All items are tagged!'));

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(item.itemName),
                subtitle: Text('\$${item.itemPrice.toStringAsFixed(2)}'),
                trailing: const Icon(Icons.person_add_alt_1),
                onTap: () => _openTaggingSheet(context, ref, item),
              );
            },

          );
        },

      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final mockItem = Item(
            itemId: const Uuid().v4(),
            receiptId: 'test-receipt-123',
            itemName: 'Test Pizza',
            itemPrice: 15.99,
            itemQty: 1,
            splitType: 'equal',
            assignedPersonIds: const [],
          );

          await ref.read(dbProvider).saveItem(mockItem);
          if (context.mounted) {
            (context as Element).markNeedsBuild(); // Refresh the list
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Stateful Bottom Sheet to handle checkbox interactions cleanly
class TagItemSheet extends ConsumerStatefulWidget {
  final Item item;
  const TagItemSheet({super.key, required this.item});

  @override
  ConsumerState<TagItemSheet> createState() => _TagItemSheetState();
}

class _TagItemSheetState extends ConsumerState<TagItemSheet> {
  late List<String> _selectedIds;
  bool _splitEqually = true;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.item.assignedPersonIds);
    _splitEqually = widget.item.splitType == 'equal';
  }

  Future<void> _saveTags() async {
    widget.item.assignedPersonIds = _selectedIds;
    widget.item.splitType = _splitEqually ? 'equal' : 'assigned';

    await ref.read(dbProvider).saveItem(widget.item);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dbService = ref.read(dbProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        children: [
          Text('Tag: ${widget.item.itemName}', style: Theme.of(context).textTheme.titleLarge),
          SwitchListTile(
            title: const Text('Split Equally'),
            value: _splitEqually,
            onChanged: (val) => setState(() => _splitEqually = val),
          ),
          const Divider(),
          Expanded(
            child: FutureBuilder<List<Person>>(
              future: dbService.getActivePeople(), // Only load active people for tagging
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final people = snapshot.data!;

                return ListView.builder(
                  itemCount: people.length,
                  itemBuilder: (context, index) {
                    final person = people[index];
                    return CheckboxListTile(
                      title: Text(person.name),
                      value: _selectedIds.contains(person.personId),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedIds.add(person.personId);
                          } else {
                            _selectedIds.remove(person.personId);
                          }
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
          FilledButton(
            onPressed: _saveTags,
            child: const Text('Save Tags'),
          ),
        ],
      ),
    );
  }
}