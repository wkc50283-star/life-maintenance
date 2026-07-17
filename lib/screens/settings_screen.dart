import 'package:flutter/material.dart';

import '../widgets/demo_data_notice.dart';
import '../widgets/safety_guide_sheet.dart';
import '../widgets/setting_card.dart';
import '../widgets/settings_header.dart';

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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const SettingsHeader(),
        const SizedBox(height: 12),
        const DemoDataNotice(),
        const SizedBox(height: 18),
        for (final setting in _settings)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: setting.highlighted
                ? () {
                    showSafetyGuideSheet(context);
                  }
                : null,
            child: SettingCard(
              title: setting.title,
              content: setting.content,
              icon: setting.icon,
              highlighted: setting.highlighted,
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
