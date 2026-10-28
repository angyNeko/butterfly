import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/person_model.dart';
import '../../../../main.dart'; // Imports dbProvider

class AddPersonDialog extends ConsumerStatefulWidget {
  final Person? personToEdit;

  const AddPersonDialog({super.key, this.personToEdit});

  @override
  ConsumerState<AddPersonDialog> createState() => _AddPersonDialogState();
}

class _AddPersonDialogState extends ConsumerState<AddPersonDialog> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.personToEdit?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.personToEdit != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Person' : 'Add Person'),
      content: TextField(
        controller: _nameController,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: 'Name',
          hintText: 'Enter person\'s name',
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.person_outline),
        ),
        onSubmitted: (_) => _savePerson(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _savePerson,
          child: Text(isEditing ? 'Update' : 'Save'),
        ),
      ],
    );
  }

  Future<void> _savePerson() async {
    final name = _nameController.text.trim();

    if (name.isNotEmpty) {
      final dbService = ref.read(dbProvider);

      if (widget.personToEdit != null) {
        widget.personToEdit!.name = name;
        await dbService.savePerson(widget.personToEdit!);
      } else {
        final newPerson = Person(
          personId: const Uuid().v4(),
          name: name,
        );
        await dbService.savePerson(newPerson);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }
}
