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
  bool _integrityCheckComplete = false;
  bool _hasIntegrityIssues = false;
  bool _usesDriftItemRead = false;

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
    widget.compositionRoot.localDataIntegrityService.addListener(
      _onIntegrityChanged,
    );
    _runIntegrityPreflight();
  }

  @override
  void dispose() {
    widget.compositionRoot.localDataIntegrityService.removeListener(
      _onIntegrityChanged,
    );
    super.dispose();
  }

  Future<void> _runIntegrityPreflight() async {
    final root = widget.compositionRoot;
    final initialization = await root.initialize();

    if (!mounted) {
      return;
    }

    final hasIssues = root.localDataIntegrityService.hasIssues;
    setState(() {
      _integrityCheckComplete = true;
      _hasIntegrityIssues = hasIssues;
      _usesDriftItemRead = initialization.usesDriftItemRead;
      if (hasIssues) {
        _currentIndex = 1;
      }
    });
  }

  void _onIntegrityChanged() {
    if (!mounted) {
      return;
    }

    final hasIssues =
        widget.compositionRoot.localDataIntegrityService.hasIssues;
    if (_hasIntegrityIssues == hasIssues) {
      return;
    }

    setState(() {
      _hasIntegrityIssues = hasIssues;
      if (hasIssues && (_currentIndex == 0 || _currentIndex == 2)) {
        _currentIndex = 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_currentIndex]), centerTitle: true),
      body: !_integrityCheckComplete
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_hasIntegrityIssues) const _LocalDataIntegrityBanner(),
                Expanded(child: _pages[_currentIndex]),
              ],
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (_usesDriftItemRead && index == 2) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('資料已安全匯入；新增功能將在正式寫入切換後開放')),
            );
            return;
          }
          if (_hasIntegrityIssues && (index == 0 || index == 2)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('本機資料正在保護中，暫時只能查看生活項目、履歷與設定')),
            );
            return;
          }

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

class _LocalDataIntegrityBanner extends StatelessWidget {
  const _LocalDataIntegrityBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7C96A)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: Color(0xFF7A5B00)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '部分本機資料無法完整讀取。為保護原始資料，新增與修改已暫停；現有可讀資料仍可查看。',
              style: TextStyle(
                color: Color(0xFF5F4700),
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
