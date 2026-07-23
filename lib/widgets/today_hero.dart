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
      padding: const EdgeInsets.all(UiSpace.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(UiRadius.hero),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF173B63), Color(0xFF275D98)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x21173B63),
            blurRadius: 20,
            offset: Offset(0, 10),
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
                child: const Icon(Icons.home_outlined, color: Colors.white),
              ),
              const SizedBox(width: UiSpace.sm),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: MediaQuery.withClampedTextScaling(
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
                ),
              ),
            ],
          ),
          const SizedBox(height: UiSpace.md),
          const Text(
            '生活總覽',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.12,
            ),
          ),
          const SizedBox(height: UiSpace.xs),
          Text(
            '管理生活項目、提醒與處理紀錄',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: UiSpace.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusPill(
                icon: Icons.notifications_none_rounded,
                label: '今日提醒 $reminderCount',
              ),
              _StatusPill(
                icon: Icons.handyman_outlined,
                label: '進行中案件 $openCaseCount',
              ),
              _StatusPill(
                icon: Icons.flag_outlined,
                label: '階段性重點 $milestoneCount',
              ),
            ],
          ),
          if (onQuickAdd != null) ...[
            const SizedBox(height: UiSpace.md),
            UiPressFeedback(
              child: FilledButton.icon(
                key: const ValueKey('overview-quick-add'),
                onPressed: onQuickAdd,
                style: FilledButton.styleFrom(
                  backgroundColor: UiColors.surface,
                  foregroundColor: UiColors.primary,
                  minimumSize: const Size(48, 50),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('快速新增'),
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
  const _StatusPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
