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
          for (var index = 0; index < children.length; index++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 18,
                    child: Column(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xFF5D7893),
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (index != children.length - 1)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.only(top: 4),
                              color: const Color(0xFFD6E2EC),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: children[index]),
                ],
              ),
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
