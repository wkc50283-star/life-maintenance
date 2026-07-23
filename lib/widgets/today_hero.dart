import 'package:flutter/material.dart';

import '../app/ui_tokens.dart';
import 'ui_v2_components.dart';

class TodayHero extends StatelessWidget {
  final int reminderCount;
  final int openCaseCount;
  final int milestoneCount;
  final VoidCallback? onQuickAdd;

  const TodayHero({
    super.key,
    required this.reminderCount,
    required this.openCaseCount,
    required this.milestoneCount,
    this.onQuickAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(UiSpace.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(UiRadius.hero),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF173B63), Color(0xFF275D98)],
        ),
        boxShadow: UiShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  '生活總覽',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.12,
                  ),
                ),
              ),
              const SizedBox(width: UiSpace.sm),
              MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.3,
                child: Text(
                  _todayLabel(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: UiSpace.xxs),
          Text(
            '管理生活項目、提醒與處理紀錄',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: UiSpace.sm),
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.1,
            child: Row(
              children: [
                Expanded(
                  child: _StatusPill(
                    icon: Icons.notifications_none_rounded,
                    label: '今日提醒',
                    count: reminderCount,
                  ),
                ),
                const SizedBox(width: UiSpace.xs),
                Expanded(
                  child: _StatusPill(
                    icon: Icons.handyman_outlined,
                    label: '進行中案件',
                    count: openCaseCount,
                  ),
                ),
                const SizedBox(width: UiSpace.xs),
                Expanded(
                  child: _StatusPill(
                    icon: Icons.flag_outlined,
                    label: '階段性重點',
                    count: milestoneCount,
                  ),
                ),
              ],
            ),
          ),
          if (onQuickAdd != null) ...[
            const SizedBox(height: UiSpace.sm),
            UiPressFeedback(
              child: SizedBox(
                width: double.infinity,
                height: 40,
                child: FilledButton.icon(
                  key: const ValueKey('overview-quick-add'),
                  onPressed: onQuickAdd,
                  style: FilledButton.styleFrom(
                    backgroundColor: UiColors.surface,
                    foregroundColor: UiColors.primary,
                    minimumSize: const Size(48, 40),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('新增生活項目'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _todayLabel() {
  final now = DateTime.now();
  const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
  return '${now.month} 月 ${now.day} 日・週${weekdays[now.weekday - 1]}';
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.count,
  });

  final IconData icon;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(UiRadius.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (constraints.maxWidth >= 72) ...[
              Icon(icon, color: Colors.white, size: 15),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                '$label $count',
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
