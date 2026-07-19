import 'package:flutter/material.dart';

import '../screens/add_screen.dart';
import '../screens/history_screen.dart';
import '../screens/items_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/today_screen.dart';
import 'app_composition_root.dart';

class AppShell extends StatefulWidget {
  const AppShell({required this.compositionRoot, super.key});

  final AppCompositionRoot compositionRoot;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _destinations = <_AppShellDestination>[
    _AppShellDestination(
      title: '生活總覽',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      screen: TodayScreen(),
    ),
    _AppShellDestination(
      title: '生活項目',
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
      screen: ItemsScreen(),
    ),
    _AppShellDestination(
      title: '新增',
      icon: Icons.add_circle_outline,
      selectedIcon: Icons.add_circle,
      screen: AddScreen(),
    ),
    _AppShellDestination(
      title: '史略',
      icon: Icons.history_outlined,
      selectedIcon: Icons.history,
      screen: HistoryScreen(),
    ),
    _AppShellDestination(
      title: '設定',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      screen: SettingsScreen(),
    ),
  ];

  int _currentIndex = 0;
  bool _runtimeReady = false;
  Object? _initializationError;

  @override
  void initState() {
    super.initState();
    _initializeRuntime();
  }

  Future<void> _initializeRuntime() async {
    setState(() => _initializationError = null);
    try {
      await widget.compositionRoot.initialize();
    } catch (error) {
      if (!mounted) return;
      setState(() => _initializationError = error);
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _runtimeReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final destination = _destinations[_currentIndex];

    return Scaffold(
      key: const ValueKey('app-shell'),
      appBar: AppBar(title: Text(destination.title)),
      body: switch ((_runtimeReady, _initializationError)) {
        (false, null) => const Center(child: CircularProgressIndicator()),
        (false, _) => _RuntimeLoadFailure(onRetry: _initializeRuntime),
        (true, _) => destination.screen,
      },
      bottomNavigationBar: NavigationBar(
        key: const ValueKey('primary-navigation'),
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          for (final item in _destinations)
            NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: item.title,
            ),
        ],
      ),
    );
  }
}

class _RuntimeLoadFailure extends StatelessWidget {
  const _RuntimeLoadFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 42,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              '暫時無法開啟生活資料。',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '資料沒有被刪除，請稍後再試一次。',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('重新開啟'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppShellDestination {
  const _AppShellDestination({
    required this.title,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
  });

  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;
}
