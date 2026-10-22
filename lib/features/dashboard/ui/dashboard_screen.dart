import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main.dart';
import '../../people/models/person_model.dart';
import 'widgets/grand_total_card.dart';
import 'widgets/person_balance_card.dart';
import '../../settings/ui/settings_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbService = ref.watch(objectBoxProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Butterfly Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Person>>(
        future: Future.value(dbService.getAllPeople()),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final people = snapshot.data!;
          const double grandTotal = 0.00; // Placeholder

          return Column(
            children: [
              // Extracted Grand Total Component
              const GrandTotalCard(total: grandTotal),

              Expanded(
                child: people.isEmpty
                    ? const Center(child: Text('Add people to see their balances.'))
                    : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Two columns side-by-side
                    crossAxisSpacing: 2.0,
                    mainAxisSpacing: 5.0,
                    childAspectRatio: 1.2, // Makes the cards perfectly square
                  ),
                  itemCount: people.length,
                  itemBuilder: (context, index) {
                    final person = people[index];
                    const double personTotal = 0.00; // Placeholder

                    return PersonBalanceCard(
                      person: person,
                      total: personTotal,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}