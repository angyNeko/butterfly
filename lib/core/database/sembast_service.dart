import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sembast/sembast_io.dart';
import '../../features/people/models/person_model.dart';
import '../../features/receipts/models/receipt_model.dart';
import '../../features/receipts/models/item_model.dart';
import '../../features/stores/models/store_record.dart'; // Updated to match your file
import '../../features/stores/models/store_item.dart';


class SembastService {
  final Database _db;

  // We create a store specifically for people, using their String UUID as the key
  final _peopleStore = stringMapStoreFactory.store('people');final _storesStore = stringMapStoreFactory.store('stores');
  final _storeItemsStore = stringMapStoreFactory.store('storeItems');
  final _itemsStore = stringMapStoreFactory.store('items');
  final _receiptsStore = stringMapStoreFactory.store('receipts');

  SembastService._(this._db);

  static Future<SembastService> create() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, 'butterfly.db');
    final db = await databaseFactoryIo.openDatabase(dbPath);
    return SembastService._(db);
  }

  // Save a person
  Future<void> savePerson(Person person) async {
    await _peopleStore.record(person.personId).put(_db, person.toMap());
  }

  // Get all people
  Future<List<Person>> getAllPeople() async {
    final snapshots = await _peopleStore.find(_db);
    return snapshots.map((snapshot) => Person.fromMap(snapshot.value)).toList();
  }

  // Get ONLY active people
  Future<List<Person>> getActivePeople() async {
    // 1. Create a Finder that filters where 'active' equals true
    final finder = Finder(filter: Filter.equals('active', true));

    // 2. Pass the finder into the query
    final snapshots = await _peopleStore.find(_db, finder: finder);

    // 3. Map the results
    return snapshots.map((snapshot) => Person.fromMap(snapshot.value)).toList();
  }

  // Bonus: A helper to "soft delete" a person
  Future<void> archivePerson(Person person) async {
    person.active = false;
    await savePerson(person); // Just overwrite them with active set to false
  }

  Future<void> saveReceipt(Receipt receipt) async {
    await _receiptsStore.record(receipt.receiptId).put(_db, receipt.toMap());
  }

  Future<List<Receipt>> getAllReceipts() async {
    final snapshots = await _receiptsStore.find(_db);
    return snapshots.map((snapshot) => Receipt.fromMap(snapshot.value)).toList();
  }

  Future<List<Item>> getItemsForReceipt(String receiptId) async {
    // Filter the items store where the receiptId matches
    final finder = Finder(filter: Filter.equals('receiptId', receiptId));
    final snapshots = await _itemsStore.find(_db, finder: finder);

    return snapshots.map((s) => Item.fromMap(s.value)).toList();
  }

  Future<void> saveItem(Item item) async {
    await _itemsStore.record(item.itemId).put(_db, item.toMap());
  }

  Future<List<Item>> getUntaggedItems() async {
    final snapshots = await _itemsStore.find(_db);
    final allItems = snapshots.map((s) => Item.fromMap(s.value)).toList();
    // Filter locally to find items with no assigned people
    return allItems.where((item) => item.assignedPersonIds.isEmpty).toList();
  }

  Future<void> saveStore(StoreRecord store) async {
    await _storesStore.record(store.storeId).put(_db, store.toMap());
  }

  Future<void> saveStoreItem(StoreItem storeItem) async {
    await _storeItemsStore.record(storeItem.storeItemId).put(_db, storeItem.toMap());
  }
}