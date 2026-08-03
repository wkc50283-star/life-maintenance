import 'package:flutter/material.dart';

import '../diagnostics/runtime_diagnostics.dart';
import '../screens/add_screen.dart';
import '../screens/history_screen.dart';
import '../screens/items_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/today_screen.dart';
import '../widgets/ui_v2_components.dart';
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
      title: '履歷',
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
  bool _showQuickCapture = false;
  final _addScreenKey = GlobalKey<AddScreenState>();
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

    if (!mounted) return;
    setState(() => _runtimeReady = true);
  }

  @override
  Widget build(BuildContext context) {
    final transitionDuration = UiMotion.durationOf(context);

    return Scaffold(
      key: const ValueKey('app-shell'),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: switch ((_runtimeReady, _initializationError)) {
                (false, null) => const Center(
                  child: CircularProgressIndicator(),
                ),
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
                        begin: const Offset(0.02, 0),
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
            ),
            if (_runtimeReady && _showQuickCapture)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  UiSpace.md,
                  UiSpace.xs,
                  UiSpace.md,
                  UiSpace.sm,
                ),
                child: _QuickCaptureActions(
                  onPhoto: () => _showUnavailable('拍照建立尚未啟用，先使用輸入建立。'),
                  onVoice: () => _showUnavailable('語音建立尚未啟用，先使用輸入建立。'),
                  onText: _openItemCreation,
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: UiBottomNavigation(
        navigationKey: const ValueKey('primary-navigation'),
        currentIndex: _currentIndex,
        onSelected: _selectDestination,
        items: [
          for (final item in _destinations)
            UiNavigationItem(
              label: item.title,
              icon: item.icon,
              selectedIcon: item.selectedIcon,
            ),
        ],
      ),
    );
  }

  void _selectDestination(int index) {
    if (index == 2) {
      setState(() => _showQuickCapture = !_showQuickCapture);
      return;
    }
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
      _showQuickCapture = false;
    });
  }

  Widget _destinationScreen(int index) => switch (index) {
    0 => TodayScreen(onQuickAdd: _openItemCreation),
    1 => const ItemsScreen(),
    2 => AddScreen(
      key: _addScreenKey,
      onShowItems: () => _selectDestination(1),
    ),
    3 => const HistoryScreen(),
    4 => const SettingsScreen(),
    _ => const SizedBox.shrink(),
  };

  void _openItemCreation() {
    setState(() {
      _currentIndex = 2;
      _showQuickCapture = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addScreenKey.currentState?.showItemCreationMenu();
    });
  }

  void _showUnavailable(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _QuickCaptureActions extends StatelessWidget {
  const _QuickCaptureActions({
    required this.onPhoto,
    required this.onVoice,
    required this.onText,
  });

  final VoidCallback onPhoto;
  final VoidCallback onVoice;
  final VoidCallback onText;

  @override
  Widget build(BuildContext context) => UiSurfaceCard(
    key: const ValueKey('overview-capture-section'),
    padding: const EdgeInsets.symmetric(
      horizontal: UiSpace.sm,
      vertical: UiSpace.xs,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _QuickCaptureButton(
            buttonKey: const ValueKey('overview-capture-voice'),
            icon: Icons.mic_none_rounded,
            label: '語音',
            onPressed: onVoice,
          ),
        ),
        const SizedBox(width: UiSpace.xs),
        Expanded(
          child: _QuickCaptureButton(
            buttonKey: const ValueKey('overview-capture-photo'),
            icon: Icons.photo_camera_outlined,
            label: '拍照',
            onPressed: onPhoto,
          ),
        ),
        const SizedBox(width: UiSpace.xs),
        Expanded(
          child: _QuickCaptureButton(
            buttonKey: const ValueKey('overview-capture-text'),
            icon: Icons.keyboard_outlined,
            label: '輸入',
            onPressed: onText,
          ),
        ),
      ],
    ),
  );
}

class _QuickCaptureButton extends StatelessWidget {
  const _QuickCaptureButton({
    required this.buttonKey,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final Key buttonKey;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label，前往新增生活項目',
    button: true,
    child: OutlinedButton(
      key: buttonKey,
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(68),
        padding: const EdgeInsets.symmetric(
          horizontal: UiSpace.xs,
          vertical: UiSpace.sm,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 26, color: UiColors.success),
          const SizedBox(height: UiSpace.xxs),
          Text(label, style: UiType.cardTitle, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
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
