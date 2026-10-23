import 'package:flutter/material.dart';
import '../../features/dashboard/ui/dashboard_screen.dart';
import '../../features/manage/ui/manage_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    ManageScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // If we are on the Dashboard (index 0), allow it to close the app.
      canPop: _currentIndex == 0,

      // Updated to the new Flutter standard to avoid deprecation warnings
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }

        // The user pressed back while on the Manage tab.
        // Switch them back to the Dashboard!
        setState(() {
          _currentIndex = 0;
        });
      },
      child: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_outlined),
              selectedIcon: Icon(Icons.folder),
              label: 'Manage',
            ),
          ],
        ),
      ),
    );
  }
}