import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../main.dart'; // Imports objectBoxProvider
import '../models/person_model.dart';

class PeopleScreen extends ConsumerWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbService = ref.watch(objectBoxProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('People'),
      ),
      body: FutureBuilder<List<Person>>(
        future: Future.value(dbService.getAllPeople()),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final people = snapshot.data!;
          if (people.isEmpty) {
            return const Center(child: Text('No people added yet.'));
          }

          return ListView.builder(
            itemCount: people.length,
            itemBuilder: (context, index) {
              final person = people[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: const Icon(Icons.person),
                ),
                title: Text(person.name),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // We will replace this with a popup dialog later to type a real name
          final newPerson = Person()
            ..personId = const Uuid().v4()
            ..name = 'Person ${dbService.getAllPeople().length + 1}';

          dbService.savePerson(newPerson);
          (context as Element).markNeedsBuild();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}