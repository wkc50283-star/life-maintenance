import 'package:flutter/material.dart';

class AddScreen extends StatelessWidget {
  const AddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: const [
        SizedBox(height: 8),
        Text(
          '你想記住什麼？',
          style: TextStyle(
            color: Color(0xFF263746),
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        SizedBox(height: 8),
        Text(
          '先把生活裡需要維護的事建立入口，下一版再接上實際新增流程。',
          style: TextStyle(color: Color(0xFF687887), fontSize: 15, height: 1.5),
        ),
        SizedBox(height: 20),
        _AddEntryCard(
          icon: Icons.add_a_photo_outlined,
          title: '新增物品',
          description: '拍照建立物品，設定保養提醒。',
        ),
        _AddEntryCard(
          icon: Icons.construction_outlined,
          title: '新增保養/維修紀錄',
          description: '記下修過什麼、換過什麼、花多少錢。',
        ),
        _AddEntryCard(
          icon: Icons.event_available_outlined,
          title: '新增到期提醒',
          description: '保固、證件、保險、合約到期前提醒。',
        ),
      ],
    );
  }
}

class _AddEntryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _AddEntryCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('此功能下一版開放'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: const Color(0xFF5D7893)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF263746),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF687887),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Color(0xFF8FA4B8)),
            ],
          ),
        ),
      ),
    );
  }
}
