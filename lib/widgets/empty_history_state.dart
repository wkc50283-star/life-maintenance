import 'package:flutter/material.dart';

import '../app/ui_tokens.dart';
import 'ui_v2_components.dart';

class EmptyHistoryState extends StatelessWidget {
  const EmptyHistoryState({super.key});

  @override
  Widget build(BuildContext context) {
    return const UiSurfaceCard(
      padding: EdgeInsets.all(UiSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.history_toggle_off_outlined, color: UiColors.primary),
          SizedBox(height: UiSpace.sm),
          Text('目前還沒有履歷紀錄。', style: UiType.cardTitle),
          SizedBox(height: UiSpace.xs),
          Text('事情完成或正式結案後，完整過程會保留在這裡。', style: UiType.body),
        ],
      ),
    );
  }
}
