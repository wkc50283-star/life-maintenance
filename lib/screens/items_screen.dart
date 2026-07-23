import 'package:flutter/material.dart';

import '../app/app_composition_root.dart';
import '../app/ui_tokens.dart';
import '../models/enums.dart';
import '../models/item.dart';
import '../repositories/item_read_repository.dart';
import '../widgets/items_header.dart';
import '../widgets/product_item_card.dart';
import 'item_detail_screen.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  late ItemReadRepository _itemRepository;
  bool _dependenciesInitialized = false;
  List<Item>? _items;
  Object? _loadError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dependenciesInitialized) return;
    _itemRepository = AppCompositionScope.of(context).itemReadRepository;
    _dependenciesInitialized = true;
    _loadItems();
  }

  @override
  void activate() {
    super.activate();
    if (_dependenciesInitialized) _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final items = await _itemRepository.loadItems();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return ListView(
      padding: UiInsets.pageCompact,
      children: [
        const ItemsHeader(),
        const SizedBox(height: UiSpace.xs),
        if (_loadError != null)
          _ItemsLoadFailure(onRetry: _loadItems)
        else if (items == null)
          const Center(child: CircularProgressIndicator())
        else if (items.isEmpty)
          const _EmptyItemsState()
        else
          for (final item in items)
            ProductItemCard(
              title: item.name,
              categoryLabel: _labelForCategory(item.category),
              statusLabel: _labelForStatus(item.status),
              location: item.location ?? '未設定',
              dateLine: _dateLineForItem(item),
              icon: _iconForCategory(item.category),
              onTap: () async {
                final changed = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => ItemDetailScreen(item: item),
                  ),
                );
                if (changed == true) await _loadItems();
              },
            ),
      ],
    );
  }
}

class _EmptyItemsState extends StatelessWidget {
  const _EmptyItemsState();

  @override
  Widget build(BuildContext context) {
    return const _ItemsMessageCard(
      icon: Icons.inventory_2_outlined,
      message: '目前還沒有生活項目。',
      supporting: '從「新增」建立第一個想長期管理的生活項目。',
    );
  }
}

class _ItemsLoadFailure extends StatelessWidget {
  const _ItemsLoadFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _ItemsMessageCard(
      message: '暫時無法讀取生活項目。',
      icon: Icons.cloud_off_outlined,
      supporting: '資料沒有被刪除，請稍後重新讀取。',
      action: OutlinedButton(onPressed: onRetry, child: const Text('重新讀取')),
    );
  }
}

class _ItemsMessageCard extends StatelessWidget {
  const _ItemsMessageCard({
    required this.message,
    required this.icon,
    required this.supporting,
    this.action,
  });

  final String message;
  final IconData icon;
  final String supporting;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(UiSpace.lg),
      decoration: BoxDecoration(
        color: UiColors.surface,
        borderRadius: BorderRadius.circular(UiRadius.card),
        border: Border.all(color: UiColors.border),
        boxShadow: UiShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: UiColors.iconSurface,
              borderRadius: BorderRadius.circular(UiRadius.control),
            ),
            child: Icon(icon, color: UiColors.primary),
          ),
          const SizedBox(height: UiSpace.md),
          Text(message, style: UiType.cardTitle),
          const SizedBox(height: UiSpace.xs),
          Text(supporting, style: UiType.body),
          if (action != null) ...[const SizedBox(height: UiSpace.md), action!],
        ],
      ),
    );
  }
}

IconData _iconForCategory(ItemCategory category) => switch (category) {
  ItemCategory.appliance => Icons.ac_unit_outlined,
  ItemCategory.vehicle => Icons.two_wheeler_outlined,
  ItemCategory.house => Icons.home_work_outlined,
  ItemCategory.warrantyDocument => Icons.description_outlined,
  ItemCategory.other => Icons.inventory_2_outlined,
};

String _labelForCategory(ItemCategory category) => switch (category) {
  ItemCategory.appliance => '家電',
  ItemCategory.vehicle => '車輛',
  ItemCategory.house => '房屋',
  ItemCategory.warrantyDocument => '保固證件',
  ItemCategory.other => '其他',
};

String _labelForStatus(ItemStatus status) => switch (status) {
  ItemStatus.active => '正常追蹤',
  ItemStatus.paused => '暫停',
  ItemStatus.archived => '已封存',
};

String _dateLineForItem(Item item) {
  final warrantyEndDate = item.warrantyEndDate;
  return warrantyEndDate == null
      ? '建立日期：${_formatDate(item.createdAt)}'
      : '保固到期：${_formatDate(warrantyEndDate)}';
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}/$month/$day';
}
