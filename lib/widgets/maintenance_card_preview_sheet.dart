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
  VoidCallback? onCompleteSteps,
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
          onCompleteSteps: onCompleteSteps,
        ),
      );
    },
  );
}

class _MaintenanceCardPreviewSheet extends StatefulWidget {
  final MaintenanceCard card;
  final Item? item;
  final String maintenanceTypeLabel;
  final String riskLevelLabel;
  final VoidCallback? onCompleteSteps;

  const _MaintenanceCardPreviewSheet({
    required this.card,
    required this.item,
    required this.maintenanceTypeLabel,
    required this.riskLevelLabel,
    required this.onCompleteSteps,
  });

  @override
  State<_MaintenanceCardPreviewSheet> createState() =>
      _MaintenanceCardPreviewSheetState();
}

class _MaintenanceCardPreviewSheetState
    extends State<_MaintenanceCardPreviewSheet> {
  final Set<String> _checkedStepIds = <String>{};

  bool get _shouldHideSteps {
    return widget.card.riskLevel == RiskLevel.high ||
        widget.card.riskLevel == RiskLevel.unknown;
  }

  bool get _canCheckSteps {
    return widget.card.riskLevel == RiskLevel.low && !_shouldHideSteps;
  }

  bool get _canCompleteSteps {
    return _canShowCompleteStepsButton &&
        widget.card.steps.every((step) => _checkedStepIds.contains(step.id));
  }

  bool get _canShowCompleteStepsButton {
    return _canCheckSteps &&
        widget.card.steps.isNotEmpty &&
        widget.onCompleteSteps != null;
  }

  void _toggleStep(String stepId, bool checked) {
    setState(() {
      if (checked) {
        _checkedStepIds.add(stepId);
      } else {
        _checkedStepIds.remove(stepId);
      }
    });
  }

  void _completeSteps() {
    widget.onCompleteSteps?.call();
    Navigator.of(context).pop();
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
            widget.card.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF263746),
              fontWeight: FontWeight.w800,
            ),
          ),
          if (widget.item != null) ...[
            const SizedBox(height: 6),
            Text(
              widget.item!.name,
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
                label: widget.maintenanceTypeLabel,
              ),
              _PreviewTag(
                icon: Icons.health_and_safety_outlined,
                label: widget.riskLevelLabel,
              ),
              _PreviewTag(
                icon: Icons.schedule_outlined,
                label: '預估 ${widget.card.estimatedMinutes} 分鐘',
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_shouldHideSteps) ...[
            const _HighRiskNotice(),
            if (widget.card.safetyNotice != null) ...[
              const SizedBox(height: 12),
              _SafetyNotice(text: widget.card.safetyNotice!),
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
            if (widget.card.steps.isEmpty)
              const _EmptyStepsNotice()
            else
              for (final step in widget.card.steps)
                if (_canCheckSteps)
                  _StepChecklistTile(
                    step: step,
                    checked: _checkedStepIds.contains(step.id),
                    onChanged: (checked) {
                      _toggleStep(step.id, checked);
                    },
                  )
                else
                  _StepPreviewTile(step: step),
            if (widget.card.safetyNotice != null) ...[
              const SizedBox(height: 12),
              _SafetyNotice(text: widget.card.safetyNotice!),
            ],
            if (_canShowCompleteStepsButton) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _canCompleteSteps ? _completeSteps : null,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text(_canCompleteSteps ? '完成步驟' : '請先完成所有步驟'),
                ),
              ),
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

class _StepChecklistTile extends StatelessWidget {
  final MaintenanceStep step;
  final bool checked;
  final ValueChanged<bool> onChanged;

  const _StepChecklistTile({
    required this.step,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: checked ? const Color(0xFFE8F0F6) : const Color(0xFFFFFCF6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: checked ? const Color(0xFFB8CBDC) : const Color(0xFFE4E0D8),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          onChanged(!checked);
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: checked,
              onChanged: (value) {
                onChanged(value ?? false);
              },
              activeColor: const Color(0xFF5D7893),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${step.order}. ${step.title}',
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
