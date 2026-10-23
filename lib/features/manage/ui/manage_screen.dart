import 'package:flutter/material.dart';
import '../../people/ui/people_screen.dart';
import '../../receipts/ui/receipts_screen.dart';

class ManageScreen extends StatelessWidget {
  const ManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Records'),
      ),
      // GridView.count is the easiest way to make a grid with a set number of columns
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        children: [
          _buildGridCard(
            context,
            icon: Icons.receipt_long,
            title: 'Receipts',
            destination: const ReceiptsScreen(),
          ),
          _buildGridCard(
            context,
            icon: Icons.people,
            title: 'People',
            destination: const PeopleScreen(),
          ),
        ],
      ),
    );
  }

  // A reusable component for your grid items
  Widget _buildGridCard(BuildContext context, {required IconData icon, required String title, required Widget destination}) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      clipBehavior: Clip.hardEdge, // Keeps the ripple effect inside the rounded corners
      child: InkWell( // Makes the card clickable with a Material ripple
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}