import 'package:flutter/material.dart';

import 'ui_v2_components.dart';

class EmptyHistoryState extends StatelessWidget {
  const EmptyHistoryState({super.key});

  @override
  Widget build(BuildContext context) {
    return const UiEmptyState(
      icon: Icons.history_toggle_off_outlined,
      title: '目前還沒有履歷紀錄。',
      description: '事情完成或正式結案後，完整過程會依時間整理在這裡。',
    );
  }
}
