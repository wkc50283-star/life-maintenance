import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _settings = [
    _SettingCardData(
      title: '預設提醒時間',
      content: '每天 09:00',
      icon: Icons.notifications_active_outlined,
      highlighted: false,
    ),
    _SettingCardData(
      title: '安全界線',
      content: '高風險維修不提供 DIY 步驟，請尋求合格專業人員協助。',
      icon: Icons.health_and_safety_outlined,
      highlighted: true,
    ),
    _SettingCardData(
      title: '資料儲存',
      content: '目前資料先保存在本機，雲端同步後續版本開放。',
      icon: Icons.storage_outlined,
      highlighted: false,
    ),
    _SettingCardData(
      title: '匯出資料',
      content: '後續可匯出保養與維修紀錄。',
      icon: Icons.ios_share_outlined,
      highlighted: false,
    ),
    _SettingCardData(
      title: '版本資訊',
      content: '生活維護管家 v0.1',
      icon: Icons.info_outline,
      highlighted: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const _SettingsHeader(),
        const SizedBox(height: 18),
        for (final setting in _settings) _SettingCard(setting: setting),
      ],
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4E0D8)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '設定',
            style: TextStyle(
              color: Color(0xFF263746),
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '提醒時間、安全界線與資料管理。',
            style: TextStyle(
              color: Color(0xFF687887),
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final _SettingCardData setting;

  const _SettingCard({required this.setting});

  @override
  Widget build(BuildContext context) {
    final iconColor = setting.highlighted
        ? const Color(0xFF7A6338)
        : const Color(0xFF5D7893);
    final iconBackground = setting.highlighted
        ? const Color(0xFFFFF7E6)
        : const Color(0xFFE8F0F6);
    final borderColor = setting.highlighted
        ? const Color(0xFFEAD9B8)
        : const Color(0xFFE4E0D8);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(setting.icon, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          setting.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: const Color(0xFF263746),
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      if (setting.highlighted) const _SafetyBadge(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    setting.content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF4D5D6B),
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafetyBadge extends StatelessWidget {
  const _SafetyBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFEAD9B8)),
      ),
      child: Text(
        '重要',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFF7A6338),
          fontWeight: FontWeight.w800,
        ),
      ),
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
