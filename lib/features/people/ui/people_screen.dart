import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main.dart'; // Imports dbProvider
import '../models/person_model.dart';
import './widgets/add_person_dialog.dart';

class PeopleScreen extends ConsumerWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbService = ref.watch(dbProvider);

    return Scaffold(
      // Note: We removed the AppBar here earlier since ManageScreen handles it!
      body: FutureBuilder<List<Person>>(
        future: dbService.getActivePeople(),
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
          // Show the popup dialog when clicked
          showDialog(
            context: context,
            builder: (context) => const AddPersonDialog(),
          ).then((_) {
            // When the dialog closes, force the screen to rebuild to show the new person
            if (context.mounted) {
              (context as Element).markNeedsBuild();
            }
          });
        },
        child: const Icon(Icons.person_add), // Updated icon
      ),
    );
  }
}
