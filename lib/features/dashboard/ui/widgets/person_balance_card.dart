import 'package:flutter/material.dart';
import '../../../people/models/person_model.dart';

class PersonBalanceCard extends StatelessWidget {
  final Person person;
  final double total;
  final String currency;
  final int itemsCount;
  final VoidCallback? onTap;

  const PersonBalanceCard({
    super.key,
    required this.person,
    required this.total,
    this.currency = '₱',
    this.itemsCount = 0,
    this.onTap,
  });

  Color _getAvatarColor(String name) {
    const colors = [
      Colors.teal,
      Colors.indigo,
      Colors.deepOrange,
      Colors.pink,
      Colors.purple,
      Colors.blue,
      Colors.cyan,
      Colors.amber,
      Colors.green,
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOwed = total > 0;
    final avatarColor = _getAvatarColor(person.name);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isOwed
              ? theme.colorScheme.outlineVariant.withValues(alpha: 0.6)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: avatarColor,
                    child: Text(
                      person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isOwed
                          ? Colors.red.withValues(alpha: 0.12)
                          : Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isOwed ? 'Owed' : 'Settled',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isOwed ? Colors.red.shade400 : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$currency${total.toStringAsFixed(2)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: isOwed ? theme.colorScheme.error : theme.colorScheme.outline,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
