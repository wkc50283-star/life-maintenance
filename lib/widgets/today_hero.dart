import 'package:flutter/material.dart';

import '../app/ui_tokens.dart';
import 'ui_v2_components.dart';

class TodayHero extends StatelessWidget {
  const TodayHero({
    super.key,
    required this.reminderCount,
    required this.openCaseCount,
    required this.milestoneCount,
    this.onQuickAdd,
  });

  final int reminderCount;
  final int openCaseCount;
  final int milestoneCount;
  final VoidCallback? onQuickAdd;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(child: Text('生活總覽', style: UiType.pageTitle)),
          const SizedBox(width: UiSpace.sm),
          IconButton(
            tooltip: '通知',
            onPressed: null,
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: UiColors.primary,
              size: 22,
            ),
          ),
        ],
      ),
      Text('今天是 ${_todayLabel()}', style: UiType.pageIntro),
      const SizedBox(height: UiSpace.md),
      MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.25,
        child: Row(
          children: [
            Expanded(
              child: _StatusCard(
                cardKey: const ValueKey('overview-status-reminders'),
                icon: Icons.notifications_none_rounded,
                label: '今日提醒',
                count: reminderCount,
                unit: '項提醒',
              ),
            ),
            const SizedBox(width: UiSpace.xs),
            Expanded(
              child: _StatusCard(
                cardKey: const ValueKey('overview-status-cases'),
                icon: Icons.home_repair_service_outlined,
                label: '進行中案件',
                count: openCaseCount,
                unit: '件',
              ),
            ),
            const SizedBox(width: UiSpace.xs),
            Expanded(
              child: _StatusCard(
                cardKey: const ValueKey('overview-status-milestones'),
                icon: Icons.flag_outlined,
                label: '階段性重點',
                count: milestoneCount,
                unit: '項',
              ),
            ),
          ],
        ),
      ),
      if (onQuickAdd != null) ...[
        const SizedBox(height: UiSpace.md),
        const Text('快速操作', style: UiType.sectionTitle),
        const SizedBox(height: UiSpace.xs),
        UiActionCard(
          semanticLabel: '新增生活項目',
          onTap: onQuickAdd,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: UiSpace.sm,
              vertical: UiSpace.xs,
            ),
            child: Row(
              key: const ValueKey('overview-quick-add'),
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: UiColors.iconSurface,
                    borderRadius: BorderRadius.circular(UiRadius.control),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: UiColors.primary,
                    size: 19,
                  ),
                ),
                const SizedBox(width: UiSpace.sm),
                const Expanded(child: Text('新增生活項目', style: UiType.cardTitle)),
                const Icon(
                  Icons.add_circle_rounded,
                  color: UiColors.accent,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    ],
  );
}

String _todayLabel() {
  final now = DateTime.now();
  const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
  return '${now.month}/ ${now.day} （週${weekdays[now.weekday - 1]}）';
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.cardKey,
    required this.icon,
    required this.label,
    required this.count,
    required this.unit,
  });

  final IconData icon;
  final Key cardKey;
  final String label;
  final int count;
  final String unit;

  @override
  Widget build(BuildContext context) => Container(
    key: cardKey,
    constraints: const BoxConstraints(minHeight: 104),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
    decoration: BoxDecoration(
      color: UiColors.surface,
      borderRadius: BorderRadius.circular(UiRadius.card),
      border: Border.all(color: UiColors.border),
      boxShadow: UiShadow.card,
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: UiColors.primary, size: 20),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
          style: UiType.caption.copyWith(color: UiColors.textPrimary),
        ),
        const SizedBox(height: 4),
        Text('$count', style: UiType.pageTitle.copyWith(fontSize: 22)),
        Text(unit, style: UiType.caption),
      ],
    ),
  );
}
