import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../main.dart';
import '../models/person_model.dart';

class PeopleScreen extends ConsumerWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbService = ref.watch(dbProvider);

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
        onPressed: () async {
          // 1. Await the list of people to get the actual length
          final currentPeople = await dbService.getAllPeople();

          // 2. Use the new standard constructor we made for the Person model
          final newPerson = Person(
            personId: const Uuid().v4(),
            name: 'Person ${currentPeople.length + 1}',
          );

          // 3. Await the save operation
          await dbService.savePerson(newPerson);

          // 4. Force UI rebuild (checking if context is mounted is a Flutter best practice after using await)
          if (context.mounted) {
            (context as Element).markNeedsBuild();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}