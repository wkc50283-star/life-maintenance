import 'package:flutter/material.dart';

import 'app/app_composition_root.dart';
import 'screens/add_screen.dart';
import 'screens/history_screen.dart';
import 'screens/items_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/today_screen.dart';

void main() {
  runApp(const LifeMaintenanceApp());
}

class LifeMaintenanceApp extends StatefulWidget {
  const LifeMaintenanceApp({super.key, this.compositionRoot});

  final AppCompositionRoot? compositionRoot;

  @override
  State<LifeMaintenanceApp> createState() => _LifeMaintenanceAppState();
}

class _LifeMaintenanceAppState extends State<LifeMaintenanceApp> {
  late final AppCompositionRoot _compositionRoot =
      widget.compositionRoot ?? AppCompositionRoot.production();
  late final bool _ownsCompositionRoot = widget.compositionRoot == null;

  @override
  void dispose() {
    if (_ownsCompositionRoot) {
      _compositionRoot.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppCompositionScope(
      root: _compositionRoot,
      child: MaterialApp(
        title: '生活維護管家',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6F8FAF),
            brightness: Brightness.light,
            surface: const Color(0xFFF7F3EA),
            primary: const Color(0xFF5D7893),
            secondary: const Color(0xFF8FA4B8),
          ),
          scaffoldBackgroundColor: const Color(0xFFF7F3EA),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Color(0xFFF7F3EA),
            foregroundColor: Color(0xFF263746),
            titleTextStyle: TextStyle(
              color: Color(0xFF263746),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            color: Colors.white,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFFE4E0D8)),
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: const Color(0xFFFFFCF6),
            indicatorColor: const Color(0xFFDCE8F2),
            labelTextStyle: WidgetStateProperty.resolveWith(
              (states) => TextStyle(
                color: states.contains(WidgetState.selected)
                    ? const Color(0xFF263746)
                    : const Color(0xFF687887),
                fontWeight: states.contains(WidgetState.selected)
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
            iconTheme: WidgetStateProperty.resolveWith(
              (states) => IconThemeData(
                color: states.contains(WidgetState.selected)
                    ? const Color(0xFF5D7893)
                    : const Color(0xFF7C8995),
              ),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF5D7893),
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        home: MainShell(compositionRoot: _compositionRoot),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({required this.compositionRoot, super.key});

  final AppCompositionRoot compositionRoot;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  bool _runtimeReady = false;

  final List<Widget> _pages = const [
    TodayScreen(),
    ItemsScreen(),
    AddScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  final List<String> _titles = const ['今日', '我的項目', '新增', '履歷', '設定'];

  @override
  void initState() {
    super.initState();
    _initializeRuntime();
  }

  Future<void> _initializeRuntime() async {
    await widget.compositionRoot.initialize();

    if (!mounted) {
      return;
    }

    setState(() {
      _runtimeReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_currentIndex]), centerTitle: true),
      body: !_runtimeReady
          ? const Center(child: CircularProgressIndicator())
          : _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: '今日',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: '我的項目',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: '新增',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: '履歷',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
    );
  }
}
