import 'package:flutter/material.dart';

class SettingsHeader extends StatelessWidget {
  const SettingsHeader({super.key});

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
            '本機資料與安全界線。',
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
