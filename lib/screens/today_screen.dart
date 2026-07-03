import 'package:flutter/material.dart';

import '../widgets/task_card.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const tasks = [
      TaskCardData(
        itemName: '客廳冷氣',
        taskName: '清洗濾網',
        cycle: '每月',
        estimatedTime: '20 分鐘',
        riskLabel: '低風險',
      ),
      TaskCardData(
        itemName: '機車',
        taskName: '胎壓檢查',
        cycle: '每週',
        estimatedTime: '5 分鐘',
        riskLabel: '低風險',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const _TodayHero(),
        const SizedBox(height: 20),
        const _TaskSectionHeader(),
        const SizedBox(height: 12),
        for (final task in tasks) TaskCard(task: task),
      ],
    );
  }
}

class _TodayHero extends StatelessWidget {
  const _TodayHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5D7893), Color(0xFF8FA4B8)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A263746),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.24),
                  ),
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'v0.1',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          const Text(
            '生活維護管家',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '軍規邏輯，民用保養',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.today_outlined, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  '今日 2 件待處理',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskSectionHeader extends StatelessWidget {
  const _TaskSectionHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '今天要處理',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF263746),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '先把重要的保養事項接住，不讓它漏掉。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF687887),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
