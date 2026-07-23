import 'package:flutter/material.dart';

import '../app/ui_tokens.dart';

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
      padding: const EdgeInsets.only(bottom: UiSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: UiSpace.sm),
            child: Text(month, style: UiType.sectionTitle),
          ),
          for (var index = 0; index < children.length; index++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 20,
                    child: Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: UiColors.accent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: UiColors.surface,
                              width: 3,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x332F80ED),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        if (index != children.length - 1)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.only(top: UiSpace.xxs),
                              color: UiColors.borderStrong,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: UiSpace.sm),
                  Expanded(child: children[index]),
                ],
              ),
            ),
          const SizedBox(height: UiSpace.xs),
        ],
      ),
    );
  }
}
