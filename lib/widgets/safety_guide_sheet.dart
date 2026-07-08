import 'package:flutter/material.dart';

void showSafetyGuideSheet(BuildContext context) {
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
        child: const _SafetyGuideSheet(),
      );
    },
  );
}

class _SafetyGuideSheet extends StatelessWidget {
  const _SafetyGuideSheet();

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
            '安全分類規則',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF263746),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '生活維護管家會依風險等級決定是否顯示保養步驟。高風險與未知風險只做記錄與提醒，不提供自行維修教學。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF687887),
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          const _RiskRuleCard(
            label: 'low 低風險',
            text: '可提供安全保養步驟，例如清潔、檢查、簡單更換耗材。',
            icon: Icons.check_circle_outline,
          ),
          const _RiskRuleCard(
            label: 'medium 中風險',
            text: '只顯示靜態提醒或注意事項，不提供完成步驟操作。',
            icon: Icons.info_outline,
          ),
          const _RiskRuleCard(
            label: 'high 高風險',
            text: '不提供 DIY 維修教學，只引導尋求合格專業人員。',
            icon: Icons.health_and_safety_outlined,
            highlighted: true,
          ),
          const _RiskRuleCard(
            label: 'unknown 未知風險',
            text: '一律視為高風險處理，不提供 DIY 步驟。',
            icon: Icons.help_outline,
            highlighted: true,
          ),
          const SizedBox(height: 6),
          const _SafetyNoticeBox(
            title: '高風險範例',
            text: '電力、瓦斯、煞車、冷媒、結構施工、高壓設備、高溫設備。',
          ),
          const SizedBox(height: 10),
          const _SafetyNoticeBox(
            title: 'App 原則',
            text: '可以幫你記錄問題、店家、費用、結果與後續追蹤，但不教高風險維修。',
          ),
        ],
      ),
    );
  }
}

class _RiskRuleCard extends StatelessWidget {
  final String label;
  final String text;
  final IconData icon;
  final bool highlighted;

  const _RiskRuleCard({
    required this.label,
    required this.text,
    required this.icon,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = highlighted
        ? const Color(0xFF7A6338)
        : const Color(0xFF5D7893);
    final iconBackground = highlighted
        ? const Color(0xFFFFF7E6)
        : const Color(0xFFE8F0F6);
    final borderColor = highlighted
        ? const Color(0xFFEAD9B8)
        : const Color(0xFFE4E0D8);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: const Color(0xFF263746),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  text,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF4D5D6B),
                    height: 1.45,
                    fontWeight: FontWeight.w600,
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

class _SafetyNoticeBox extends StatelessWidget {
  final String title;
  final String text;

  const _SafetyNoticeBox({required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0F6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD6E2EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: const Color(0xFF263746),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF506272),
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
