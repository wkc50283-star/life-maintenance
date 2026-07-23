import 'package:flutter/material.dart';

import 'ui_v2_components.dart';

class SettingsHeader extends StatelessWidget {
  const SettingsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const UiCompactPageHeader(
      icon: Icons.settings_outlined,
      title: '設定',
      description: '查看資料說明、安全界線與 App 使用資訊。',
    );
  }
}
