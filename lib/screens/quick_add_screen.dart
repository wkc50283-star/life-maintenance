import 'package:flutter/material.dart';

import '../app/ui_tokens.dart';
import '../widgets/add_entry_card.dart';
import '../widgets/ui_v2_components.dart';
import 'add_screen.dart';
import 'formal_planning_screens.dart';

/// 第一層只呈現使用者能立即理解的拍照、語音與輸入入口。
///
/// 既有正式功能沒有被刪除，完整新增頁仍可由「更多建立方式」進入。
class QuickAddScreen extends StatefulWidget {
  const QuickAddScreen({super.key, this.onShowItems});

  final VoidCallback? onShowItems;

  @override
  State<QuickAddScreen> createState() => QuickAddScreenState();
}

class QuickAddScreenState extends State<QuickAddScreen> {
  Future<void> showItemCreationMenu() async {
    final method = await showModalBottomSheet<_QuickEntryMethod>(
      context: context,
      showDragHandle: true,
      builder: (_) => const _QuickEntryMethodSheet(),
    );
    if (!mounted || method == null) return;
    await _handleMethod(method);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('quick-add-scroll'),
      padding: UiInsets.pageCompact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const UiCompactPageHeader(
            icon: Icons.auto_awesome_outlined,
            title: '現在需要記住或處理什麼？',
            description: '先選擇最方便的方式開始；系統功能會在需要時出現。',
          ),
          UiSurfaceCard(
            key: const ValueKey('quick-entry-primary-card'),
            padding: const EdgeInsets.all(UiSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('快速開始', style: UiType.sectionTitle),
                const SizedBox(height: UiSpace.xxs),
                Text(
                  '例如：客廳冷氣漏水、下週四晚上七點看牙。',
                  style: UiType.body,
                ),
                const SizedBox(height: UiSpace.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _QuickEntryButton(
                        buttonKey: const ValueKey('quick-entry-photo'),
                        icon: Icons.photo_camera_outlined,
                        label: '拍照',
                        onPressed: () =>
                            _handleMethod(_QuickEntryMethod.photo),
                      ),
                    ),
                    const SizedBox(width: UiSpace.xs),
                    Expanded(
                      child: _QuickEntryButton(
                        buttonKey: const ValueKey('quick-entry-voice'),
                        icon: Icons.mic_none_rounded,
                        label: '語音',
                        onPressed: () =>
                            _handleMethod(_QuickEntryMethod.voice),
                      ),
                    ),
                    const SizedBox(width: UiSpace.xs),
                    Expanded(
                      child: _QuickEntryButton(
                        buttonKey: const ValueKey('quick-entry-text'),
                        icon: Icons.keyboard_outlined,
                        label: '輸入',
                        emphasized: true,
                        onPressed: () =>
                            _handleMethod(_QuickEntryMethod.text),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: UiSpace.md),
          ExpansionTile(
            key: const ValueKey('quick-entry-more-methods'),
            tilePadding: const EdgeInsets.symmetric(horizontal: UiSpace.xs),
            childrenPadding: const EdgeInsets.only(bottom: UiSpace.sm),
            leading: const Icon(Icons.tune_rounded),
            title: const Text('更多建立方式'),
            subtitle: const Text('保養、提醒、案件與完成紀錄都保留在這裡'),
            children: [
              AddEntryCard(
                icon: Icons.dashboard_customize_outlined,
                title: '查看全部正式功能',
                description: '開啟原有完整新增頁，選擇保養、提醒、排程、案件或完成紀錄。',
                onTap: _openAllCreationTools,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleMethod(_QuickEntryMethod method) async {
    switch (method) {
      case _QuickEntryMethod.text:
        await _openItemForm();
        return;
      case _QuickEntryMethod.photo:
        _showUnavailableMessage('拍照建立尚未啟用，先使用輸入建立。');
        return;
      case _QuickEntryMethod.voice:
        _showUnavailableMessage('語音建立尚未啟用，先使用輸入建立。');
        return;
    }
  }

  Future<void> _openItemForm() async {
    final result = await Navigator.of(context).push<ItemFormResult>(
      MaterialPageRoute<ItemFormResult>(
        builder: (_) => const ItemFormScreen(usesTypedResult: true),
      ),
    );
    if (!mounted || result?.createdItemId == null) return;
    if (result!.showItems) widget.onShowItems?.call();
  }

  Future<void> _openAllCreationTools() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AddScreen(onShowItems: widget.onShowItems),
      ),
    );
  }

  void _showUnavailableMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

enum _QuickEntryMethod { photo, voice, text }

class _QuickEntryMethodSheet extends StatelessWidget {
  const _QuickEntryMethodSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          UiSpace.md,
          UiSpace.xs,
          UiSpace.md,
          UiSpace.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('選擇開始方式', style: UiType.sectionTitle),
            const SizedBox(height: UiSpace.xxs),
            Text('只顯示三個最直接的入口。', style: UiType.body),
            const SizedBox(height: UiSpace.md),
            Row(
              children: [
                Expanded(
                  child: _QuickEntryButton(
                    buttonKey: const ValueKey('quick-entry-sheet-photo'),
                    icon: Icons.photo_camera_outlined,
                    label: '拍照',
                    onPressed: () => Navigator.pop(
                      context,
                      _QuickEntryMethod.photo,
                    ),
                  ),
                ),
                const SizedBox(width: UiSpace.xs),
                Expanded(
                  child: _QuickEntryButton(
                    buttonKey: const ValueKey('quick-entry-sheet-voice'),
                    icon: Icons.mic_none_rounded,
                    label: '語音',
                    onPressed: () => Navigator.pop(
                      context,
                      _QuickEntryMethod.voice,
                    ),
                  ),
                ),
                const SizedBox(width: UiSpace.xs),
                Expanded(
                  child: _QuickEntryButton(
                    buttonKey: const ValueKey('quick-entry-sheet-text'),
                    icon: Icons.keyboard_outlined,
                    label: '輸入',
                    emphasized: true,
                    onPressed: () => Navigator.pop(
                      context,
                      _QuickEntryMethod.text,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickEntryButton extends StatelessWidget {
  const _QuickEntryButton({
    required this.buttonKey,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.emphasized = false,
  });

  final Key buttonKey;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final child = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon),
        const SizedBox(height: UiSpace.xxs),
        Text(label, textAlign: TextAlign.center),
      ],
    );

    return Semantics(
      button: true,
      label: '$label開始',
      child: emphasized
          ? FilledButton(
              key: buttonKey,
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(72),
                padding: const EdgeInsets.symmetric(
                  horizontal: UiSpace.xs,
                  vertical: UiSpace.sm,
                ),
              ),
              child: child,
            )
          : OutlinedButton(
              key: buttonKey,
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(72),
                padding: const EdgeInsets.symmetric(
                  horizontal: UiSpace.xs,
                  vertical: UiSpace.sm,
                ),
              ),
              child: child,
            ),
    );
  }
}
