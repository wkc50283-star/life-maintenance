import 'package:flutter/material.dart';

import 'ui_v2_components.dart';

class HistoryHeader extends StatelessWidget {
  const HistoryHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const UiCompactPageHeader(
      icon: Icons.history_rounded,
      title: '史略',
      description: '完成過的處理、費用、結果與後續注意，都會完整保留。',
    );
  }
}
