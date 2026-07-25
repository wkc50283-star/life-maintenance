import 'package:flutter/material.dart';

import '../app/ui_tokens.dart';
import '../widgets/demo_data_notice.dart';
import '../widgets/safety_guide_sheet.dart';
import '../widgets/setting_card.dart';
import '../widgets/settings_header.dart';
import '../widgets/ui_v2_components.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _settings = [
    _SettingCardData(
      title: '安全界線',
      content: '高風險維修不提供 DIY 步驟，請尋求合格專業人員協助。',
      icon: Icons.health_and_safety_outlined,
      highlighted: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: UiInsets.pageCompact,
      children: [
        const UiMotionEntrance(child: SettingsHeader()),
        const SizedBox(height: UiSpace.xxs),
        const UiMotionEntrance(child: DemoDataNotice()),
        const SizedBox(height: UiSpace.md),
        const UiSectionHeader(
          title: '資料與安全',
          icon: Icons.shield_outlined,
          description: '了解資料保存方式與處理生活事項時的安全邊界。',
        ),
        const SizedBox(height: UiSpace.sm),
        for (final setting in _settings)
          UiMotionEntrance(
            duration: UiMotion.emphasized,
            child: UiActionCard(
              semanticLabel: setting.highlighted
                  ? '開啟${setting.title}說明'
                  : setting.title,
              onTap: setting.highlighted
                  ? () => showSafetyGuideSheet(context)
                  : null,
              child: SettingCard(
                title: setting.title,
                content: setting.content,
                icon: setting.icon,
                highlighted: setting.highlighted,
              ),
            ),
          ),
      ],
    );
  }
}

class _SettingCardData {
  final String title;
  final String content;
  final IconData icon;
  final bool highlighted;

  const _SettingCardData({
    required this.title,
    required this.content,
    required this.icon,
    required this.highlighted,
  });
}
