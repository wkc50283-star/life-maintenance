import 'package:flutter/material.dart';

class MaintenancePreviewTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const MaintenancePreviewTag({
    super.key,
    required this.icon,
    required this.label,
  });

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

class HighRiskMaintenanceNotice extends StatelessWidget {
  const HighRiskMaintenanceNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return const _NoticeBox(
      icon: Icons.shield_outlined,
      text: '此項目屬於高風險或未知風險，請尋求合格專業人員協助。',
    );
  }
}

class MaintenanceSafetyNotice extends StatelessWidget {
  final String text;

  const MaintenanceSafetyNotice({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return _NoticeBox(icon: Icons.info_outline, text: text);
  }
}

class EmptyMaintenanceStepsNotice extends StatelessWidget {
  const EmptyMaintenanceStepsNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return const _NoticeBox(icon: Icons.notes_outlined, text: '目前沒有步驟內容。');
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
