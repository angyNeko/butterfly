import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sembast/sembast_io.dart';
import '../../features/people/models/person_model.dart';

class SembastService {
  final Database _db;

  // We create a store specifically for people, using their String UUID as the key
  final _peopleStore = stringMapStoreFactory.store('people');

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
}