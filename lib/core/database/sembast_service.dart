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
}