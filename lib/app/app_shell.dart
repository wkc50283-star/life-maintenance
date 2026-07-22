import 'package:flutter/material.dart';

import '../diagnostics/runtime_diagnostics.dart';
import '../screens/add_screen.dart';
import '../screens/history_screen.dart';
import '../screens/items_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/today_screen.dart';
import 'app_composition_root.dart';
import 'ui_tokens.dart';

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
    ),
    _AppShellDestination(
      title: '生活項目',
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
    ),
    _AppShellDestination(
      title: '新增',
      icon: Icons.add_circle_outline,
      selectedIcon: Icons.add_circle,
    ),
    _AppShellDestination(
      title: '史略',
      icon: Icons.history_outlined,
      selectedIcon: Icons.history,
    ),
    _AppShellDestination(
      title: '設定',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
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
    } catch (error, stackTrace) {
      RuntimeDiagnostics.report(
        stage: 'composition_root.initialize',
        error: error,
        stackTrace: stackTrace,
      );
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
    final transitionDuration = UiMotion.durationOf(context);

    return Scaffold(
      key: const ValueKey('app-shell'),
      appBar: AppBar(
        centerTitle: false,
        toolbarHeight: 68,
        titleSpacing: UiSpace.md,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: UiColors.iconSurface,
                borderRadius: BorderRadius.circular(UiRadius.control),
              ),
              child: Icon(destination.selectedIcon, color: UiColors.primary),
            ),
            const SizedBox(width: UiSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '生活管理',
                    style: TextStyle(
                      color: UiColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(destination.title),
                ],
              ),
            ),
          ],
        ),
      ),
      body: switch ((_runtimeReady, _initializationError)) {
        (false, null) => const Center(child: CircularProgressIndicator()),
        (false, _) => _RuntimeLoadFailure(onRetry: _initializeRuntime),
        (true, _) => AnimatedSwitcher(
          key: const ValueKey('shell-tab-transition'),
          duration: transitionDuration,
          switchInCurve: UiMotion.standardCurve,
          switchOutCurve: UiMotion.standardCurve,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.025, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: KeyedSubtree(
            key: ValueKey('shell-destination-$_currentIndex'),
            child: _destinationScreen(_currentIndex),
          ),
        ),
      },
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: UiColors.surfaceWarm,
          border: Border(top: BorderSide(color: UiColors.border)),
          boxShadow: [
            BoxShadow(
              color: Color(0x0F263746),
              blurRadius: 18,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: NavigationBar(
          key: const ValueKey('primary-navigation'),
          selectedIndex: _currentIndex,
          onDestinationSelected: _selectDestination,
          destinations: [
            for (final item in _destinations)
              NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: item.title,
              ),
          ],
        ),
      ),
    );
  }

  void _selectDestination(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  Widget _destinationScreen(int index) => switch (index) {
    0 => TodayScreen(onQuickAdd: () => _selectDestination(2)),
    1 => const ItemsScreen(),
    2 => const AddScreen(),
    3 => const HistoryScreen(),
    4 => const SettingsScreen(),
    _ => const SizedBox.shrink(),
  };
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
  });

  final String title;
  final IconData icon;
  final IconData selectedIcon;
}
