import 'package:flutter/material.dart';

class DemoDataNotice extends StatelessWidget {
  const DemoDataNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0F6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD6E2EC)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFCF6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: Color(0xFF5D7893),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '生活項目與保養維修紀錄已可儲存到本機；目前尚未支援雲端同步。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF4D5D6B),
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
