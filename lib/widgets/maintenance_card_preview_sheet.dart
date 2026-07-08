import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/item.dart';
import '../models/maintenance_card.dart';
import 'maintenance_preview_notices.dart';
import 'maintenance_step_tiles.dart';

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
              MaintenancePreviewTag(
                icon: Icons.category_outlined,
                label: widget.maintenanceTypeLabel,
              ),
              MaintenancePreviewTag(
                icon: Icons.health_and_safety_outlined,
                label: widget.riskLevelLabel,
              ),
              MaintenancePreviewTag(
                icon: Icons.schedule_outlined,
                label: '預估 ${widget.card.estimatedMinutes} 分鐘',
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_shouldHideSteps) ...[
            const HighRiskMaintenanceNotice(),
            if (widget.card.safetyNotice != null) ...[
              const SizedBox(height: 12),
              MaintenanceSafetyNotice(text: widget.card.safetyNotice!),
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
              const EmptyMaintenanceStepsNotice()
            else
              for (final step in widget.card.steps)
                if (_canCheckSteps)
                  MaintenanceStepChecklistTile(
                    order: step.order,
                    title: step.title,
                    description: step.description,
                    checked: _checkedStepIds.contains(step.id),
                    onChanged: (checked) {
                      _toggleStep(step.id, checked);
                    },
                  )
                else
                  MaintenanceStepPreviewTile(
                    order: step.order,
                    title: step.title,
                    description: step.description,
                  ),
            if (widget.card.safetyNotice != null) ...[
              const SizedBox(height: 12),
              MaintenanceSafetyNotice(text: widget.card.safetyNotice!),
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
