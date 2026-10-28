import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main.dart';
import '../../receipts/models/item_model.dart';
import '../../receipts/models/receipt_model.dart';
import '../models/person_model.dart';
import 'widgets/add_person_dialog.dart';

class PeopleScreen extends ConsumerStatefulWidget {
  const PeopleScreen({super.key});

  @override
  ConsumerState<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends ConsumerState<PeopleScreen> {
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  void _refresh() {
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getAvatarColor(String name) {
    const colors = [
      Colors.teal,
      Colors.indigo,
      Colors.deepOrange,
      Colors.pink,
      Colors.purple,
      Colors.blue,
      Colors.cyan,
      Colors.amber,
      Colors.green,
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  Future<void> _deletePerson(Person person) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Person?'),
        content: Text('Remove "${person.name}" from your people list?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(dbProvider).deletePerson(person.personId);
      _refresh();
    }
  }

  Future<void> _settlePersonBalance(Person person, List<Item> assignedItems) async {
    if (assignedItems.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settle Balance?'),
        content: Text(
          'Mark all ${assignedItems.length} items as settled for "${person.name}"? This removes their tag from these items.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Settle All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = ref.read(dbProvider);
      for (final item in assignedItems) {
        item.assignedPersonIds.remove(person.personId);
        await db.saveItem(item);
      }
      _refresh();
    }
  }

  void _openPersonDetail(
    BuildContext context,
    Person person,
    double balance,
    List<Item> personItems,
    Map<String, Receipt> receiptsMap,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _PersonDetailSheet(
        person: person,
        balance: balance,
        items: personItems,
        receiptsMap: receiptsMap,
        avatarColor: _getAvatarColor(person.name),
        onItemUntagged: _refresh,
        onSettleAll: () {
          Navigator.pop(context);
          _settlePersonBalance(person, personItems);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dbService = ref.watch(dbProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search people...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
        )
            : const Text('People'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          dbService.getActivePeople(),
          dbService.getAllItems(),
          dbService.getAllReceipts(),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allPeople = snapshot.data![0] as List<Person>;
          final allItems = snapshot.data![1] as List<Item>;
          final allReceipts = snapshot.data![2] as List<Receipt>;
          final receiptsMap = {for (var r in allReceipts) r.receiptId: r};

          // Compute balances & items per person
          final balances = <String, double>{};
          final itemsByPerson = <String, List<Item>>{};

          for (final item in allItems) {
            if (item.assignedPersonIds.isNotEmpty) {
              final share = (item.itemPrice * item.itemQty) / item.assignedPersonIds.length;
              for (final pId in item.assignedPersonIds) {
                balances[pId] = (balances[pId] ?? 0.0) + share;
                itemsByPerson.putIfAbsent(pId, () => []).add(item);
              }
            }
          }

          final grandTotal = balances.values.fold<double>(0.0, (sum, val) => sum + val);

          // Filter by search
          final people = _searchQuery.isEmpty
              ? allPeople
              : allPeople.where((p) => p.name.toLowerCase().contains(_searchQuery)).toList();

          if (allPeople.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline, size: 72, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('No people added yet', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    'Add friends or group members to split bills with!',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const AddPersonDialog(),
                      ).then((saved) {
                        if (saved == true) _refresh();
                      });
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add Person'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // 1. Top Summary Banner
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${allPeople.length} ${allPeople.length == 1 ? "Person" : "People"}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Total Unsettled',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '\$${grandTotal.toStringAsFixed(2)}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),

              // 2. People List
              Expanded(
                child: people.isEmpty
                    ? Center(
                  child: Text('No results for "$_searchQuery"'),
                )
                    : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: people.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final person = people[index];
                    final balance = balances[person.personId] ?? 0.0;
                    final personItems = itemsByPerson[person.personId] ?? [];
                    final avatarColor = _getAvatarColor(person.name);

                    return Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _openPersonDetail(
                          context,
                          person,
                          balance,
                          personItems,
                          receiptsMap,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              // Avatar with Initial
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: avatarColor,
                                child: Text(
                                  person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Name & Items count
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      person.name,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      personItems.isEmpty
                                          ? 'No items assigned'
                                          : '${personItems.length} ${personItems.length == 1 ? "item" : "items"} assigned',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.outline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Balance & Actions
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '\$${balance.toStringAsFixed(2)}',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: balance > 0
                                          ? theme.colorScheme.error
                                          : theme.colorScheme.outline,
                                    ),
                                  ),
                                  Text(
                                    balance > 0 ? 'Owed' : 'Settled',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: balance > 0 ? Colors.red.shade400 : Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(width: 4),

                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, size: 20),
                                padding: EdgeInsets.zero,
                                onSelected: (val) {
                                  if (val == 'details') {
                                    _openPersonDetail(
                                      context,
                                      person,
                                      balance,
                                      personItems,
                                      receiptsMap,
                                    );
                                  } else if (val == 'edit') {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AddPersonDialog(personToEdit: person),
                                    ).then((saved) {
                                      if (saved == true) _refresh();
                                    });
                                  } else if (val == 'settle') {
                                    _settlePersonBalance(person, personItems);
                                  } else if (val == 'delete') {
                                    _deletePerson(person);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'details',
                                    child: Row(
                                      children: [
                                        Icon(Icons.receipt_outlined, size: 18),
                                        SizedBox(width: 8),
                                        Text('View Items'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_outlined, size: 18),
                                        SizedBox(width: 8),
                                        Text('Edit Name'),
                                      ],
                                    ),
                                  ),
                                  if (personItems.isNotEmpty)
                                    const PopupMenuItem(
                                      value: 'settle',
                                      child: Row(
                                        children: [
                                          Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
                                          SizedBox(width: 8),
                                          Text('Settle All', style: TextStyle(color: Colors.green)),
                                        ],
                                      ),
                                    ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete Person', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddPersonDialog(),
          ).then((saved) {
            if (saved == true) _refresh();
          });
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add Person'),
      ),
    );
  }
}

// -----------------------------------------------------------------
// Person Detail Sheet: Shows breakdown of all items assigned to them
// -----------------------------------------------------------------
class _PersonDetailSheet extends ConsumerStatefulWidget {
  final Person person;
  final double balance;
  final List<Item> items;
  final Map<String, Receipt> receiptsMap;
  final Color avatarColor;
  final VoidCallback onItemUntagged;
  final VoidCallback onSettleAll;

  const _PersonDetailSheet({
    required this.person,
    required this.balance,
    required this.items,
    required this.receiptsMap,
    required this.avatarColor,
    required this.onItemUntagged,
    required this.onSettleAll,
  });

  @override
  ConsumerState<_PersonDetailSheet> createState() => _PersonDetailSheetState();
}

class _PersonDetailSheetState extends ConsumerState<_PersonDetailSheet> {
  late List<Item> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
  }

  Future<void> _untagItem(Item item) async {
    item.assignedPersonIds.remove(widget.person.personId);
    await ref.read(dbProvider).saveItem(item);
    setState(() {
      _items.removeWhere((i) => i.itemId == item.itemId);
    });
    widget.onItemUntagged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _items.fold<double>(
      0.0,
      (sum, item) => sum + ((item.itemPrice * item.itemQty) / (item.assignedPersonIds.isEmpty ? 1 : item.assignedPersonIds.length)),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Person Header
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: widget.avatarColor,
                child: Text(
                  widget.person.name.isNotEmpty ? widget.person.name[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.person.name,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_items.length} ${_items.length == 1 ? "item" : "items"} assigned',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: total > 0 ? theme.colorScheme.error : theme.colorScheme.outline,
                    ),
                  ),
                  const Text('Total Owed', style: TextStyle(fontSize: 11)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(),

          // Items breakdown list
          Expanded(
            child: _items.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline, size: 56, color: Colors.green.shade400),
                  const SizedBox(height: 8),
                  const Text('All settled! No items assigned.'),
                ],
              ),
            )
                : ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _items[index];
                final receipt = widget.receiptsMap[item.receiptId];
                final isSplit = item.assignedPersonIds.length > 1;
                final personShare = (item.itemPrice * item.itemQty) / (item.assignedPersonIds.isEmpty ? 1 : item.assignedPersonIds.length);

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.itemName, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(
                    receipt != null ? receipt.store : 'Receipt',
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${personShare.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (isSplit)
                            Text(
                              'split ${item.assignedPersonIds.length} ways',
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.red),
                        tooltip: 'Untag item',
                        onPressed: () => _untagItem(item),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          if (_items.isNotEmpty) ...[
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: widget.onSettleAll,
              child: const Text('Settle All Items'),
            ),
          ],
        ],
      ),
    );
  }
}
