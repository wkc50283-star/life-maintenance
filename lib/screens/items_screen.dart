import 'package:flutter/material.dart';

class ItemsScreen extends StatelessWidget {
  const ItemsScreen({super.key});

  static const _categories = ['全部', '家電', '車輛', '房屋', '保固證件', '其他'];

  static const _items = [
    _ItemCardData(
      name: '客廳冷氣',
      category: '家電',
      nextTask: '下次提醒：清洗濾網',
      lastRecord: '最近紀錄：2026/07/03 建立保養提醒',
      status: '正常追蹤',
      icon: Icons.ac_unit_outlined,
    ),
    _ItemCardData(
      name: '機車',
      category: '車輛',
      nextTask: '下次提醒：胎壓檢查',
      lastRecord: '最近紀錄：2026/07/03 建立每週提醒',
      status: '本週到期',
      icon: Icons.two_wheeler_outlined,
    ),
    _ItemCardData(
      name: '租屋合約',
      category: '保固證件',
      nextTask: '下次提醒：合約到期前 30 天',
      lastRecord: '最近紀錄：2026/07/03 建立到期提醒',
      status: '到期追蹤',
      icon: Icons.description_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const _ItemsHeader(),
        const SizedBox(height: 18),
        const _CategoryChips(categories: _categories),
        const SizedBox(height: 18),
        for (final item in _items) _ProductItemCard(item: item),
      ],
    );
  }
}

class _ItemsHeader extends StatelessWidget {
  const _ItemsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4E0D8)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '我的物品',
            style: TextStyle(
              color: Color(0xFF263746),
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '一個物品，一組提醒，一份長期紀錄。',
            style: TextStyle(
              color: Color(0xFF687887),
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<String> categories;

  const _CategoryChips({required this.categories});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final category in categories) ...[
            _CategoryChip(label: category, selected: category == '全部'),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;

  const _CategoryChip({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFDCE8F2) : const Color(0xFFFFFCF6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? const Color(0xFFB8CBDC) : const Color(0xFFE4E0D8),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: selected ? const Color(0xFF263746) : const Color(0xFF687887),
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    );
  }
}

class _ProductItemCard extends StatelessWidget {
  final _ItemCardData item;

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
                  child: Icon(item.icon, color: const Color(0xFF5D7893)),
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
                      _InfoPill(label: item.category),
                    ],
                  ),
                ),
                _StatusTag(label: item.status),
              ],
            ),
            const SizedBox(height: 16),
            _ItemInfoRow(
              icon: Icons.notifications_active_outlined,
              text: item.nextTask,
            ),
            const SizedBox(height: 10),
            _ItemInfoRow(icon: Icons.history_outlined, text: item.lastRecord),
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

class _ItemCardData {
  final String name;
  final String category;
  final String nextTask;
  final String lastRecord;
  final String status;
  final IconData icon;

  const _ItemCardData({
    required this.name,
    required this.category,
    required this.nextTask,
    required this.lastRecord,
    required this.status,
    required this.icon,
  });
}
