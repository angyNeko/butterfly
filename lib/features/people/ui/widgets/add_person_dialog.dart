import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/person_model.dart';
import '../../../../main.dart'; // Imports dbProvider


class AddPersonDialog extends ConsumerStatefulWidget {
  const AddPersonDialog({super.key});

  @override
  ConsumerState<AddPersonDialog> createState() => _AddPersonDialogState();
}

class _AddPersonDialogState extends ConsumerState<AddPersonDialog> {
  // A controller to read the text the user types
  final _nameController = TextEditingController();

  @override
  void dispose() {
    // Always dispose controllers to prevent memory leaks
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Person'),
      content: TextField(
        controller: _nameController,
        autofocus: true, // Automatically opens the keyboard
        textCapitalization: TextCapitalization.words, // Capitalizes the first letter
        decoration: const InputDecoration(
          labelText: 'Name',
          hintText: 'Enter person\'s name',
          border: OutlineInputBorder(), // Modern Material 3 boxed look
        ),
        onSubmitted: (_) => _savePerson(), // Save if they hit enter on keyboard
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), // Close without saving
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _savePerson,
          child: const Text('Save'),
        ),
      ],
    );
  }

  // Extracted the save logic into a helper function
  Future<void> _savePerson() async {
    final name = _nameController.text.trim();

    // Only save if they actually typed something
    if (name.isNotEmpty) {
      final dbService = ref.read(dbProvider);

      final newPerson = Person(
        personId: const Uuid().v4(),
        name: name,
      );

      await dbService.savePerson(newPerson);

      if (mounted) {
        Navigator.pop(context); // Close the dialog after saving
      }
    }
  }
}