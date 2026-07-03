import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/item.dart';
import '../models/maintenance_card.dart';

void showMaintenanceCardPreview(
  BuildContext context, {
  required MaintenanceCard? card,
  required Item? item,
  required String maintenanceTypeLabel,
  required String riskLevelLabel,
}) {
  if (card == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('找不到對應的保養步驟卡'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFF7F3EA),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: _MaintenanceCardPreviewSheet(
          card: card,
          item: item,
          maintenanceTypeLabel: maintenanceTypeLabel,
          riskLevelLabel: riskLevelLabel,
        ),
      );
    },
  );
}

class _MaintenanceCardPreviewSheet extends StatelessWidget {
  final MaintenanceCard card;
  final Item? item;
  final String maintenanceTypeLabel;
  final String riskLevelLabel;

  const _MaintenanceCardPreviewSheet({
    required this.card,
    required this.item,
    required this.maintenanceTypeLabel,
    required this.riskLevelLabel,
  });

  bool get _shouldHideSteps {
    return card.riskLevel == RiskLevel.high ||
        card.riskLevel == RiskLevel.unknown;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFB8CBDC),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            card.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF263746),
              fontWeight: FontWeight.w800,
            ),
          ),
          if (item != null) ...[
            const SizedBox(height: 6),
            Text(
              item!.name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF687887),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PreviewTag(
                icon: Icons.category_outlined,
                label: maintenanceTypeLabel,
              ),
              _PreviewTag(
                icon: Icons.health_and_safety_outlined,
                label: riskLevelLabel,
              ),
              _PreviewTag(
                icon: Icons.schedule_outlined,
                label: '預估 ${card.estimatedMinutes} 分鐘',
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_shouldHideSteps) ...[
            const _HighRiskNotice(),
            if (card.safetyNotice != null) ...[
              const SizedBox(height: 12),
              _SafetyNotice(text: card.safetyNotice!),
            ],
          ] else ...[
            Text(
              '步驟列表',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF263746),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            if (card.steps.isEmpty)
              const _EmptyStepsNotice()
            else
              for (final step in card.steps) _StepPreviewTile(step: step),
            if (card.safetyNotice != null) ...[
              const SizedBox(height: 12),
              _SafetyNotice(text: card.safetyNotice!),
            ],
          ],
        ],
      ),
    );
  }
}

class _PreviewTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PreviewTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE4E0D8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF5D7893)),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF4D5D6B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepPreviewTile extends StatelessWidget {
  final MaintenanceStep step;

  const _StepPreviewTile({required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E0D8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              step.order.toString(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: const Color(0xFF5D7893),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF263746),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (step.description.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    step.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF687887),
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HighRiskNotice extends StatelessWidget {
  const _HighRiskNotice();

  @override
  Widget build(BuildContext context) {
    return _NoticeBox(
      icon: Icons.shield_outlined,
      text: '此項目屬於高風險或未知風險，請尋求合格專業人員協助。',
    );
  }
}

class _SafetyNotice extends StatelessWidget {
  final String text;

  const _SafetyNotice({required this.text});

  @override
  Widget build(BuildContext context) {
    return _NoticeBox(icon: Icons.info_outline, text: text);
  }
}

class _EmptyStepsNotice extends StatelessWidget {
  const _EmptyStepsNotice();

  @override
  Widget build(BuildContext context) {
    return _NoticeBox(icon: Icons.notes_outlined, text: '目前沒有步驟內容。');
  }
}

class _NoticeBox extends StatelessWidget {
  final IconData icon;
  final String text;

  const _NoticeBox({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6E2EC)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF5D7893), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF506272),
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
