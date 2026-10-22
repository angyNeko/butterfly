import 'package:flutter/material.dart';
import '../../../people/models/person_model.dart';

class PersonBalanceCard extends StatelessWidget {
  final Person person;
  final double total;

  const PersonBalanceCard({
    super.key,
    required this.person,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      // Elevation 0 and surfaceContainer matches modern Material 3 grid styling
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              child: Text(person.name.isNotEmpty ? person.name.substring(0, 1).toUpperCase() : '?'),
            ),
            const Spacer(),
            Text(
              person.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '\$${total.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}