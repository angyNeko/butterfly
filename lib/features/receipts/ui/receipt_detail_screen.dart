import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../main.dart';
import '../../people/models/person_model.dart';
import '../../people/ui/widgets/add_person_dialog.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/item_model.dart';
import '../models/receipt_model.dart';

class ReceiptDetailScreen extends ConsumerStatefulWidget {
  final Receipt receipt;
  const ReceiptDetailScreen({super.key, required this.receipt});

  @override
  ConsumerState<ReceiptDetailScreen> createState() => _ReceiptDetailScreenState();
}

class _ReceiptDetailScreenState extends ConsumerState<ReceiptDetailScreen> {
  late Receipt _receipt;
  bool _showImage = true;

  static const List<String> _popularCurrencies = ['₱', '\$', '€', '£', '¥', '₩', '₹'];

  @override
  void initState() {
    super.initState();
    _receipt = widget.receipt;
  }

  void _refresh() {
    setState(() {});
  }

  void _openFullscreenImage(BuildContext context) {
    if (_receipt.receiptImg == null || _receipt.receiptImg!.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(_receipt.store),
          ),
          body: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.file(
                File(_receipt.receiptImg!),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editReceiptStore() async {
    final controller = TextEditingController(text: _receipt.store);
    final newStore = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Store Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Store Name',
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

    if (newStore != null && newStore.isNotEmpty && newStore != _receipt.store) {
      _receipt.store = newStore;
      _receipt.name = newStore;
      await ref.read(dbProvider).saveReceipt(_receipt);
      _refresh();
    }
  }

  Future<void> _showCurrencyOverrideDialog(BuildContext context, String defaultCurrency) async {
    final isCustom = _receipt.currency != null &&
        _receipt.currency!.isNotEmpty &&
        !_popularCurrencies.contains(_receipt.currency);

    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Currency for this Receipt'),
        children: [
          ListTile(
            leading: const Icon(Icons.restore),
            title: Text('Use Default ($defaultCurrency)'),
            selected: _receipt.currency == null || _receipt.currency!.isEmpty,
            onTap: () => Navigator.pop(context, '__DEFAULT__'),
          ),
          const Divider(),
          for (final c in _popularCurrencies)
            ListTile(
              leading: Text(
                c,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              title: Text(_getCurrencyLabel(c)),
              selected: _receipt.currency == c,
              onTap: () => Navigator.pop(context, c),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(isCustom ? 'Custom (${_receipt.currency})' : 'Custom Currency...'),
            onTap: () async {
              Navigator.pop(context, '__CUSTOM__');
            },
          ),
        ],
      ),
    );

    if (selected == null) return;

    if (selected == '__DEFAULT__') {
      _receipt.currency = null;
      await ref.read(dbProvider).saveReceipt(_receipt);
      _refresh();
    } else if (selected == '__CUSTOM__') {
      if (!context.mounted) return;
      final customController = TextEditingController(text: _receipt.currency ?? '');
      final customSymbol = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Custom Currency'),
          content: TextField(
            controller: customController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Symbol / Code',
              hintText: 'e.g. CHF, R\$, kr, ฿',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(context, customController.text.trim()),
              child: const Text('Save'),
            ),
          ],
        ),
      );

      if (customSymbol != null && customSymbol.isNotEmpty) {
        _receipt.currency = customSymbol;
        await ref.read(dbProvider).saveReceipt(_receipt);
        _refresh();
      }
    } else {
      _receipt.currency = selected;
      await ref.read(dbProvider).saveReceipt(_receipt);
      _refresh();
    }
  }

  String _getCurrencyLabel(String symbol) {
    switch (symbol) {
      case '₱':
        return 'Philippine Peso (PHP)';
      case '\$':
        return 'US Dollar (USD)';
      case '€':
        return 'Euro (EUR)';
      case '£':
        return 'British Pound (GBP)';
      case '¥':
        return 'Yen / Yuan (JPY/CNY)';
      case '₩':
        return 'Korean Won (KRW)';
      case '₹':
        return 'Indian Rupee (INR)';
      default:
        return symbol;
    }
  }

  Future<void> _confirmDeleteReceipt() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Receipt?'),
        content: Text('Are you sure you want to delete "${_receipt.store}" and all its items?'),
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

    if (confirmed == true && mounted) {
      await ref.read(dbProvider).deleteReceipt(_receipt.receiptId);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted "${_receipt.store}"')),
        );
      }
    }
  }

  void _openTagSheet(Item item, List<Person> allPeople, String currency) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _TagItemSheet(
        item: item,
        allPeople: allPeople,
        currency: currency,
        onSaved: _refresh,
      ),
    );
  }

  void _openAddItemDialog(String currency) {
    showDialog(
      context: context,
      builder: (context) => _AddOrEditItemDialog(
        receiptId: _receipt.receiptId,
        currency: currency,
        onSaved: _refresh,
      ),
    );
  }

  void _openEditItemDialog(Item item, String currency) {
    showDialog(
      context: context,
      builder: (context) => _AddOrEditItemDialog(
        receiptId: _receipt.receiptId,
        existingItem: item,
        currency: currency,
        onSaved: _refresh,
      ),
    );
  }

  Future<void> _deleteItem(Item item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item?'),
        content: Text('Remove "${item.itemName}" from this receipt?'),
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
      await ref.read(dbProvider).deleteItem(item.itemId);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dbService = ref.watch(dbProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultCurrency = ref.watch(currencyProvider);
    final activeCurrency = _receipt.currency?.isNotEmpty == true ? _receipt.currency! : defaultCurrency;
    final isOverridden = _receipt.currency != null && _receipt.currency!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _receipt.store,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat.yMMMd().add_jm().format(_receipt.date),
                  style: theme.textTheme.bodySmall,
                ),
                if (isOverridden) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      activeCurrency,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isOverridden ? Icons.paid : Icons.payments_outlined),
            tooltip: 'Currency: $activeCurrency ${isOverridden ? "(Custom)" : "(Default)"}',
            onPressed: () => _showCurrencyOverrideDialog(context, defaultCurrency),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Store Name',
            onPressed: _editReceiptStore,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete Receipt',
            onPressed: _confirmDeleteReceipt,
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          dbService.getItemsForReceipt(_receipt.receiptId),
          dbService.getActivePeople(),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data![0] as List<Item>;
          final people = snapshot.data![1] as List<Person>;
          final peopleMap = {for (var p in people) p.personId: p};

          final total = items.fold<double>(
            0.0,
            (sum, item) => sum + (item.itemPrice * item.itemQty),
          );
          final taggedCount = items.where((i) => i.assignedPersonIds.isNotEmpty).length;
          final untaggedCount = items.length - taggedCount;

          return Column(
            children: [
              // 1. Receipt Image Preview (Collapsible)
              if (_receipt.receiptImg != null && _receipt.receiptImg!.isNotEmpty) ...[
                AnimatedCrossFade(
                  firstChild: Card(
                    clipBehavior: Clip.antiAlias,
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: InkWell(
                      onTap: () => _openFullscreenImage(context),
                      child: Stack(
                        children: [
                          Container(
                            height: 160,
                            width: double.infinity,
                            color: Colors.black12,
                            child: Image.file(
                              File(_receipt.receiptImg!),
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              errorBuilder: (context, error, stackTrace) => const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.broken_image, size: 36),
                                    SizedBox(height: 6),
                                    Text('Image not available'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.8),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.zoom_in, color: Colors.white, size: 18),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Tap to view receipt image',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.expand_less, color: Colors.white, size: 20),
                                    visualDensity: VisualDensity.compact,
                                    tooltip: 'Hide preview',
                                    onPressed: () => setState(() => _showImage = false),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  secondChild: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _showImage = true),
                      icon: const Icon(Icons.receipt_outlined, size: 18),
                      label: const Text('Show Receipt Image'),
                    ),
                  ),
                  crossFadeState: _showImage ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                  duration: const Duration(milliseconds: 200),
                ),
              ],

              // 2. Items Section Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Items (${items.length})',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (items.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: untaggedCount == 0
                              ? Colors.green.withValues(alpha: 0.15)
                              : Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: untaggedCount == 0 ? Colors.green : Colors.amber.shade700,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          untaggedCount == 0 ? '✓ All Tagged' : '$untaggedCount Untagged',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: untaggedCount == 0
                                ? Colors.green
                                : (isDark ? Colors.amber.shade300 : Colors.amber.shade900),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // 3. Items List
              Expanded(
                child: items.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 64, color: theme.colorScheme.outline),
                      const SizedBox(height: 12),
                      Text(
                        'No items in this receipt.',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap "Add Item" below to create items.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                )
                    : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: items.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isTagged = item.assignedPersonIds.isNotEmpty;

                    return Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isTagged
                              ? theme.colorScheme.outlineVariant.withValues(alpha: 0.5)
                              : Colors.amber.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: InkWell(
                        onTap: () => _openTagSheet(item, people, activeCurrency),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top row: Item Name, Price, Actions
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.itemName,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$activeCurrency${item.itemPrice.toStringAsFixed(2)}',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, size: 20),
                                    padding: EdgeInsets.zero,
                                    onSelected: (val) {
                                      if (val == 'tag') {
                                        _openTagSheet(item, people, activeCurrency);
                                      } else if (val == 'edit') {
                                        _openEditItemDialog(item, activeCurrency);
                                      } else if (val == 'delete') {
                                        _deleteItem(item);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'tag',
                                        child: Row(
                                          children: [
                                            Icon(Icons.person_add_outlined, size: 18),
                                            SizedBox(width: 8),
                                            Text('Assign Person'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_outlined, size: 18),
                                            SizedBox(width: 8),
                                            Text('Edit Item'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Delete Item', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // Bottom row: Tagging status / assigned people
                              if (!isTagged) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.person_add_alt, size: 15, color: isDark ? Colors.amber.shade300 : Colors.amber.shade800),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Untagged • Tap to assign',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.amber.shade300 : Colors.amber.shade900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    for (final personId in item.assignedPersonIds) ...[
                                      Chip(
                                        avatar: CircleAvatar(
                                          radius: 10,
                                          backgroundColor: theme.colorScheme.primary,
                                          child: Text(
                                            peopleMap[personId]?.name.isNotEmpty == true
                                                ? peopleMap[personId]!.name[0].toUpperCase()
                                                : '?',
                                            style: TextStyle(fontSize: 10, color: theme.colorScheme.onPrimary),
                                          ),
                                        ),
                                        label: Text(
                                          peopleMap[personId]?.name ?? 'Unknown',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ],
                                    if (item.assignedPersonIds.length > 1)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Text(
                                          '($activeCurrency${(item.itemPrice / item.assignedPersonIds.length).toStringAsFixed(2)} ea)',
                                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 4. Modern Bottom Bar with Total & Add Button
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    border: Border(
                      top: BorderSide(color: theme.dividerColor),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total (${items.length} ${items.length == 1 ? "item" : "items"})',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          Text(
                            '$activeCurrency${total.toStringAsFixed(2)}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      FilledButton.icon(
                        onPressed: () => _openAddItemDialog(activeCurrency),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Item'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------
// Tag Item Bottom Sheet: Assign 1 or more people to this item
// -----------------------------------------------------------------
class _TagItemSheet extends ConsumerStatefulWidget {
  final Item item;
  final List<Person> allPeople;
  final String currency;
  final VoidCallback onSaved;

  const _TagItemSheet({
    required this.item,
    required this.allPeople,
    required this.currency,
    required this.onSaved,
  });

  @override
  ConsumerState<_TagItemSheet> createState() => _TagItemSheetState();
}

class _TagItemSheetState extends ConsumerState<_TagItemSheet> {
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
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final people = widget.allPeople;
    final c = widget.currency;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sheet handle
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

            // Item Name & Price Title
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.itemName,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$c${widget.item.itemPrice.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_selectedIds.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() => _selectedIds.clear()),
                    child: const Text('Clear All'),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Split summary preview
            if (_selectedIds.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _selectedIds.length == 1
                      ? 'Assigned to 1 person ($c${widget.item.itemPrice.toStringAsFixed(2)})'
                      : 'Split between ${_selectedIds.length} people: $c${(widget.item.itemPrice / _selectedIds.length).toStringAsFixed(2)} each',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
            ],

            const Divider(),

            // People selection list
            Expanded(
              child: people.isEmpty
                  ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_outline, size: 48),
                    const SizedBox(height: 8),
                    const Text('No active people found.'),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const AddPersonDialog(),
                        ).then((_) {
                          if (mounted) setState(() {});
                        });
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add Person'),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: people.length,
                itemBuilder: (context, index) {
                  final person = people[index];
                  final isSelected = _selectedIds.contains(person.personId);

                  return CheckboxListTile(
                    value: isSelected,
                    title: Text(person.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                    secondary: CircleAvatar(
                      backgroundColor: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      foregroundColor: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                      child: Text(person.name.isNotEmpty ? person.name[0].toUpperCase() : '?'),
                    ),
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
              ),
            ),

            const SizedBox(height: 12),

            FilledButton(
              onPressed: _saveTags,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                _selectedIds.isEmpty ? 'Remove Tagging' : 'Save Assignment (${_selectedIds.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------
// Add or Edit Item Dialog
// -----------------------------------------------------------------
class _AddOrEditItemDialog extends ConsumerStatefulWidget {
  final String receiptId;
  final Item? existingItem;
  final String currency;
  final VoidCallback onSaved;

  const _AddOrEditItemDialog({
    required this.receiptId,
    this.existingItem,
    required this.currency,
    required this.onSaved,
  });

  @override
  ConsumerState<_AddOrEditItemDialog> createState() => _AddOrEditItemDialogState();
}

class _AddOrEditItemDialogState extends ConsumerState<_AddOrEditItemDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _qtyController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingItem?.itemName ?? '');
    _priceController = TextEditingController(
      text: widget.existingItem != null ? widget.existingItem!.itemPrice.toStringAsFixed(2) : '',
    );
    _qtyController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final priceText = _priceController.text.trim();
    final qtyText = _qtyController.text.trim();

    if (name.isEmpty || priceText.isEmpty) return;

    final price = double.tryParse(priceText) ?? 0.0;
    final qty = int.tryParse(qtyText) ?? 1;

    final db = ref.read(dbProvider);

    if (widget.existingItem != null) {
      widget.existingItem!.itemName = name;
      widget.existingItem!.itemPrice = price;
      await db.saveItem(widget.existingItem!);
    } else {
      final count = qty < 1 ? 1 : qty;
      for (int i = 0; i < count; i++) {
        final newItem = Item(
          itemId: const Uuid().v4(),
          receiptId: widget.receiptId,
          itemName: name,
          itemPrice: price,
          itemQty: 1,
          splitType: 'equal',
        );
        await db.saveItem(newItem);
      }
    }

    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingItem != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Item' : 'New Item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: 'Price',
                      border: const OutlineInputBorder(),
                      prefixText: widget.currency,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                if (!isEditing) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _qtyController,
                      decoration: const InputDecoration(
                        labelText: 'Qty',
                        border: OutlineInputBorder(),
                        helperText: 'Creates 1 per qty',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _save,
          child: Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}
