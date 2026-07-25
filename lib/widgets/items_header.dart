import 'package:flutter/material.dart';

import 'ui_v2_components.dart';

class ItemsHeader extends StatelessWidget {
  const ItemsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const UiCompactPageHeader(
      title: '生活項目',
      description: '長期需要管理與記住的生活內容。',
    );
  }
}
