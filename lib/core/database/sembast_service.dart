import 'package:sembast/sembast_io.dart';

import '../../features/people/models/person_model.dart';
import '../../features/receipts/models/receipt_model.dart';
import '../../features/receipts/models/item_model.dart';
import '../../features/stores/models/store_record.dart';
import '../../features/stores/models/store_item.dart';
import '../config/app_storage.dart';

class SembastService {
  final Database _db;

  // 1. Define the distinct stores (tables)
  final _peopleStore = stringMapStoreFactory.store('people');
  final _storesStore = stringMapStoreFactory.store('stores');
  final _storeItemsStore = stringMapStoreFactory.store('storeItems');
  final _itemsStore = stringMapStoreFactory.store('items');
  final _receiptsStore = stringMapStoreFactory.store('receipts');
  final _settingsStore = stringMapStoreFactory.store('settings');

  SembastService._(this._db);

  static Future<SembastService> create() async {
    // Fetch the safe external path using the AppStorage helper
    final dbPath = await AppStorage.getDatabasePath();

    // Open Sembast database at the custom external path
    final db = await databaseFactoryIo.openDatabase(dbPath);
    return SembastService._(db);
  }

  // --- SETTINGS ---

  Future<void> saveSetting(String key, String value) async {
    await _settingsStore.record(key).put(_db, {'value': value});
  }

  Future<String?> getSetting(String key) async {
    final record = await _settingsStore.record(key).get(_db);
    return record?['value'] as String?;
  }

  // --- PEOPLE ---
  Future<void> savePerson(Person person) async {
    await _peopleStore.record(person.personId).put(_db, person.toMap());
  }

  Future<List<Person>> getAllPeople() async {
    final snapshots = await _peopleStore.find(_db);
    return snapshots.map((s) => Person.fromMap(s.value)).toList();
  }

  Future<List<Person>> getActivePeople() async {
    final finder = Finder(filter: Filter.equals('active', true));
    final snapshots = await _peopleStore.find(_db, finder: finder);
    return snapshots.map((s) => Person.fromMap(s.value)).toList();
  }

  Future<void> archivePerson(Person person) async {
    person.active = false;
    await savePerson(person);
  }

  // --- RECEIPTS ---
  Future<void> saveReceipt(Receipt receipt) async {
    await _receiptsStore.record(receipt.receiptId).put(_db, receipt.toMap());
  }

  Future<List<Receipt>> getAllReceipts() async {
    final snapshots = await _receiptsStore.find(_db);
    return snapshots.map((s) => Receipt.fromMap(s.value)).toList();
  }

  // --- ITEMS ---
  Future<void> saveItem(Item item) async {
    await _itemsStore.record(item.itemId).put(_db, item.toMap());
  }

  Future<List<Item>> getUntaggedItems() async {
    final snapshots = await _itemsStore.find(_db);
    final allItems = snapshots.map((s) => Item.fromMap(s.value)).toList();
    // Filter locally to find items with no assigned people
    return allItems.where((item) => item.assignedPersonIds.isEmpty).toList();
  }

  Future<List<Item>> getItemsForReceipt(String receiptId) async {
    final finder = Finder(filter: Filter.equals('receiptId', receiptId));
    final snapshots = await _itemsStore.find(_db, finder: finder);
    return snapshots.map((s) => Item.fromMap(s.value)).toList();
  }

  // --- STORES ---
  Future<void> saveStore(StoreRecord store) async {
    await _storesStore.record(store.storeId).put(_db, store.toMap());
  }

  Future<void> saveStoreItem(StoreItem storeItem) async {
    await _storeItemsStore.record(storeItem.storeItemId).put(_db, storeItem.toMap());
  }
}