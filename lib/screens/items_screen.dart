import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/enums.dart';
import '../models/item.dart';
import '../models/maintenance_record.dart';
import '../repositories/item_local_repository.dart';
import '../repositories/maintenance_record_local_repository.dart';
import '../services/local_storage_service.dart';
import '../widgets/items_category_chips.dart';
import '../widgets/items_header.dart';
import '../widgets/item_detail_sheet.dart';
import '../widgets/product_item_card.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  static const _categories = ['全部', '家電', '車輛', '房屋', '保固證件', '其他'];

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final ItemLocalRepository _itemRepository = ItemLocalRepository(
    LocalStorageService(),
  );
  final MaintenanceRecordLocalRepository _recordRepository =
      MaintenanceRecordLocalRepository(LocalStorageService());
  List<Item>? _localItems;
  List<MaintenanceRecord>? _localRecords;

  @override
  void initState() {
    super.initState();
    _loadLocalData();
  }

  @override
  void activate() {
    super.activate();
    _loadLocalData();
  }

  Future<void> _loadLocalData() async {
    final items = await _itemRepository.loadItems();
    final records = await _recordRepository.loadRecords();
    if (!mounted) {
      return;
    }

    setState(() {
      _localItems = items;
      _localRecords = records;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localItems = _localItems;
    final isUsingMockItems = localItems == null || localItems.isEmpty;
    final items = isUsingMockItems ? MockData.items : localItems;
    final localRecords = _localRecords;
    final records = isUsingMockItems
        ? MockData.maintenanceRecords
        : localRecords ?? <MaintenanceRecord>[];

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
              onTap: () {
                final itemRecords = records
                    .where((record) => record.itemId == item.id)
                    .toList();
                showItemDetailSheet(
                  context,
                  data: _itemDetailDataFor(item, itemRecords),
                );
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

ItemDetailData _itemDetailDataFor(Item item, List<MaintenanceRecord> records) {
  final sortedRecords = [...records]..sort((a, b) => b.date.compareTo(a.date));

  return ItemDetailData(
    title: '項目詳情',
    rows: [
      ItemDetailRow(label: '名稱', value: item.name),
      ItemDetailRow(label: '分類', value: _labelForCategory(item.category)),
      ItemDetailRow(label: '狀態', value: _labelForStatus(item.status)),
      ItemDetailRow(label: '位置', value: _nullableText(item.location) ?? '未設定'),
      ItemDetailRow(label: '建立日期', value: _formatDate(item.createdAt)),
      ItemDetailRow(
        label: '購買日期',
        value: _formatOptionalDate(item.purchaseDate),
      ),
      ItemDetailRow(
        label: '保固到期',
        value: _formatOptionalDate(item.warrantyEndDate),
      ),
      ItemDetailRow(
        label: '管理年限',
        value: item.expectedLifeYears == null
            ? '未設定'
            : '${item.expectedLifeYears} 年',
      ),
      ItemDetailRow(label: '備註', value: _nullableText(item.note) ?? '未設定'),
    ],
    maintenanceRecords: [
      for (final record in sortedRecords)
        ItemDetailMaintenanceRecord(
          date: _formatDate(record.date),
          title: record.title,
          recordType: _labelForRecordType(record.recordType),
          result: _nullableText(record.result) ?? '已記錄',
        ),
    ],
  );
}

String _labelForRecordType(RecordType type) {
  return switch (type) {
    RecordType.regularMaintenance => '保養',
    RecordType.failure => '故障',
    RecordType.repair => '維修',
    RecordType.partsReplacement => '更換',
    RecordType.expiryHandled => '到期提醒',
    RecordType.construction => '施工',
    RecordType.other => '其他',
  };
}

String _formatOptionalDate(DateTime? date) {
  return date == null ? '未設定' : _formatDate(date);
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}/$month/$day';
}

String? _nullableText(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }

  return trimmed;
}
