import 'package:flutter/material.dart';

import 'prototypes/life_management_visual_prototypes.dart';

void main() {
  runApp(const PrototypeReviewApp());
}

/// Review-only entrypoint for visual approval.
///
/// Run with:
/// `flutter run -t lib/prototype_main.dart`
///
/// This entrypoint is not imported by the production application and does not
/// access repositories, persistence, Drift, or SharedPreferences.
class PrototypeReviewApp extends StatelessWidget {
  const PrototypeReviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '生活管理樣板審查',
      home: PrototypeReviewShell(),
    );
  }
}

class PrototypeReviewShell extends StatefulWidget {
  const PrototypeReviewShell({super.key});

  @override
  State<PrototypeReviewShell> createState() => _PrototypeReviewShellState();
}

class _PrototypeReviewShellState extends State<PrototypeReviewShell> {
  int _selectedIndex = 0;

  static const _pages = <Widget>[
    HomeVisualPrototype(),
    ItemDetailVisualPrototype(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '首頁樣板',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: '項目詳情',
          ),
        ],
      ),
    );
  }
}
