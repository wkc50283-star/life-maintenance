import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/enums.dart';
import '../models/item.dart';
import '../repositories/item_local_repository.dart';
import '../services/local_storage_service.dart';
import '../widgets/items_category_chips.dart';
import '../widgets/items_header.dart';
import '../widgets/product_item_card.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  static const _categories = ['全部', '家電', '車輛', '房屋', '保固證件', '其他'];

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final ItemLocalRepository _repository = ItemLocalRepository(
    LocalStorageService(),
  );
  List<Item>? _localItems;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void activate() {
    super.activate();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await _repository.loadItems();
    if (!mounted) {
      return;
    }

    setState(() {
      _localItems = items;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localItems = _localItems;
    final items = localItems == null || localItems.isEmpty
        ? MockData.items
        : localItems;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const ItemsHeader(),
        const SizedBox(height: 18),
        const ItemsCategoryChips(categories: ItemsScreen._categories),
        const SizedBox(height: 18),
        if (items.isEmpty)
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
            ),
      ],
    );
  }
}

class _EmptyItemsState extends StatelessWidget {
  const _EmptyItemsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4E0D8)),
      ),
      child: Text(
        '目前還沒有項目。',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF687887),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

IconData _iconForCategory(ItemCategory category) {
  return switch (category) {
    ItemCategory.appliance => Icons.ac_unit_outlined,
    ItemCategory.vehicle => Icons.two_wheeler_outlined,
    ItemCategory.house => Icons.home_work_outlined,
    ItemCategory.warrantyDocument => Icons.description_outlined,
    ItemCategory.other => Icons.inventory_2_outlined,
  };
}

String _labelForCategory(ItemCategory category) {
  return switch (category) {
    ItemCategory.appliance => '家電',
    ItemCategory.vehicle => '車輛',
    ItemCategory.house => '房屋',
    ItemCategory.warrantyDocument => '保固證件',
    ItemCategory.other => '其他',
  };
}

String _labelForStatus(ItemStatus status) {
  return switch (status) {
    ItemStatus.active => '正常追蹤',
    ItemStatus.paused => '暫停',
    ItemStatus.archived => '已封存',
  };
}

String _dateLineForItem(Item item) {
  final warrantyEndDate = item.warrantyEndDate;
  if (warrantyEndDate != null) {
    return '保固到期：${_formatDate(warrantyEndDate)}';
  }

  return '建立日期：${_formatDate(item.createdAt)}';
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}/$month/$day';
}
