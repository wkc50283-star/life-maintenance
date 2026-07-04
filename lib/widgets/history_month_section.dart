import 'package:flutter/material.dart';

class HistoryMonthSection extends StatelessWidget {
  final String month;
  final List<Widget> children;

  const HistoryMonthSection({
    super.key,
    required this.month,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 10),
            child: Text(
              month,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF263746),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ...children,
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
