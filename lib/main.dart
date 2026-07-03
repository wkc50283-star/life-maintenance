import 'package:flutter/material.dart';

import 'screens/add_screen.dart';
import 'screens/history_screen.dart';
import 'screens/items_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/today_screen.dart';

void main() {
  runApp(const LifeMaintenanceApp());
}

class LifeMaintenanceApp extends StatelessWidget {
  const LifeMaintenanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    TodayScreen(),
    ItemsScreen(),
    AddScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  final List<String> _titles = const ['今日', '物品', '新增', '履歷', '設定'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_currentIndex]), centerTitle: true),
      body: _pages[_currentIndex],
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
            label: '物品',
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

class TaskItem {
  final String itemName;
  final String taskName;
  final String cycle;
  final String estimatedTime;
  final String riskLabel;

  const TaskItem({
    required this.itemName,
    required this.taskName,
    required this.cycle,
    required this.estimatedTime,
    required this.riskLabel,
  });
}

class ItemInfo {
  final String name;
  final String category;
  final String nextTask;

  const ItemInfo({
    required this.name,
    required this.category,
    required this.nextTask,
  });
}

class HistoryRecord {
  final String date;
  final String title;
  final String note;

  const HistoryRecord({
    required this.date,
    required this.title,
    required this.note,
  });
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const SectionHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.primaryContainer.withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final TaskItem task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.build_outlined)),
        title: Text('${task.itemName}｜${task.taskName}'),
        subtitle: Text(
          '${task.cycle}｜預估 ${task.estimatedTime}｜${task.riskLabel}',
        ),
        trailing: FilledButton(onPressed: () {}, child: const Text('完成')),
      ),
    );
  }
}

class ItemCard extends StatelessWidget {
  final ItemInfo item;

  const ItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.inventory_2_outlined)),
        title: Text(item.name),
        subtitle: Text('${item.category}｜${item.nextTask}'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class HistoryCard extends StatelessWidget {
  final HistoryRecord record;

  const HistoryCard({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.event_note_outlined)),
        title: Text(record.title),
        subtitle: Text('${record.date}\n${record.note}'),
        isThreeLine: true,
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;

  const InfoCard({
    super.key,
    required this.title,
    required this.content,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title),
        subtitle: Text(content),
      ),
    );
  }
}
