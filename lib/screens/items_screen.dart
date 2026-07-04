import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/enums.dart';
import '../models/item.dart';
import '../widgets/items_category_chips.dart';
import '../widgets/items_header.dart';

class ItemsScreen extends StatelessWidget {
  const ItemsScreen({super.key});

  static const _categories = ['全部', '家電', '車輛', '房屋', '保固證件', '其他'];

  @override
  Widget build(BuildContext context) {
    final items = MockData.items;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const ItemsHeader(),
        const SizedBox(height: 18),
        const ItemsCategoryChips(categories: _categories),
        const SizedBox(height: 18),
        if (items.isEmpty)
          const _EmptyItemsState()
        else
          for (final item in items) _ProductItemCard(item: item),
      ],
    );
  }
}

class _ProductItemCard extends StatelessWidget {
  final Item item;

  const _ProductItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _iconForCategory(item.category),
                    color: const Color(0xFF5D7893),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: const Color(0xFF263746),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 7),
                      _InfoPill(label: _labelForCategory(item.category)),
                    ],
                  ),
                ),
                _StatusTag(label: _labelForStatus(item.status)),
              ],
            ),
            const SizedBox(height: 16),
            _ItemInfoRow(
              icon: Icons.place_outlined,
              text: '位置：${item.location ?? '未設定'}',
            ),
            const SizedBox(height: 10),
            _ItemInfoRow(
              icon: Icons.event_available_outlined,
              text: _dateLineForItem(item),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;

  const _InfoPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5F8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: const Color(0xFF5D7893),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  final String label;

  const _StatusTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFEAD9B8)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: const Color(0xFF7A6338),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ItemInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ItemInfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF8FA4B8)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF4D5D6B),
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
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
        '目前還沒有物品。',
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
