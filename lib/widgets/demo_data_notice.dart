import 'package:flutter/material.dart';

import '../app/ui_tokens.dart';

class DemoDataNotice extends StatelessWidget {
  const DemoDataNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: UiColors.surfaceBlue,
        borderRadius: BorderRadius.circular(UiRadius.card),
        border: Border.all(color: UiColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: UiColors.surface,
              borderRadius: BorderRadius.circular(UiRadius.control),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: UiColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '生活項目與保養維修紀錄已可儲存到本機；目前尚未支援雲端同步。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: UiColors.textSecondary,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
