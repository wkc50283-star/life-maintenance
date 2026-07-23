import 'package:flutter/material.dart';

import 'ui_v2_components.dart';

class ItemsHeader extends StatelessWidget {
  const ItemsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const UiCompactPageHeader(
      icon: Icons.inventory_2_outlined,
      title: '生活項目',
      description: '家電、車輛、房屋、文件與重要生活內容，都整理在這裡。',
    );
  }
}
