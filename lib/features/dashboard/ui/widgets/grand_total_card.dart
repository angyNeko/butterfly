import 'package:flutter/material.dart';

class GrandTotalCard extends StatelessWidget {
  final double total;
  final String currency;
  final int peopleCount;
  final int receiptsCount;
  final int untaggedCount;
  final VoidCallback? onUntaggedTap;

  const GrandTotalCard({
    super.key,
    required this.total,
    this.currency = '₱',
    this.peopleCount = 0,
    this.receiptsCount = 0,
    this.untaggedCount = 0,
    this.onUntaggedTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onContainer = theme.colorScheme.onPrimaryContainer;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, size: 20, color: onContainer.withValues(alpha: 0.8)),
                    const SizedBox(width: 8),
                    Text(
                      'Total Unsettled',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: onContainer.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (untaggedCount > 0 && onUntaggedTap != null)
                  InkWell(
                    onTap: onUntaggedTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade700, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.label_off_outlined, size: 14, color: onContainer),
                          const SizedBox(width: 4),
                          Text(
                            '$untaggedCount Untagged',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: onContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$currency${total.toStringAsFixed(2)}',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: onContainer,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildMetric(
                  icon: Icons.people_outline,
                  label: '$peopleCount ${peopleCount == 1 ? "Person" : "People"}',
                  color: onContainer,
                ),
                const SizedBox(width: 16),
                _buildMetric(
                  icon: Icons.receipt_long_outlined,
                  label: '$receiptsCount ${receiptsCount == 1 ? "Receipt" : "Receipts"}',
                  color: onContainer,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric({required IconData icon, required String label, required Color color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: color.withValues(alpha: 0.85), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
