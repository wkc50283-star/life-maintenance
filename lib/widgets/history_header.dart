import 'package:flutter/material.dart';

import 'ui_v2_components.dart';

class HistoryHeader extends StatelessWidget {
  const HistoryHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const UiCompactPageHeader(
      title: '史略',
      description: '處理過程、結果與後續注意都完整保留。',
    );
  }
}
