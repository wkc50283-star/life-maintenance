import 'package:flutter/material.dart';

/// Static, review-only prototypes.
///
/// These widgets are intentionally not connected to navigation, repositories,
/// persistence, or production actions. They exist only to review information
/// hierarchy and visual direction before production UI work begins.
class HomeVisualPrototype extends StatelessWidget {
  const HomeVisualPrototype({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PrototypeScaffold(
      title: '生活管理',
      child: _HomePrototypeBody(),
    );
  }
}

class ItemDetailVisualPrototype extends StatelessWidget {
  const ItemDetailVisualPrototype({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PrototypeScaffold(
      title: '生活項目詳情',
      child: _ItemDetailPrototypeBody(),
    );
  }
}

class _PrototypeScaffold extends StatelessWidget {
  const _PrototypeScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F1E8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF476C63),
          surface: const Color(0xFFFFFCF6),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          centerTitle: false,
          backgroundColor: const Color(0xFFF5F1E8),
          surfaceTintColor: Colors.transparent,
        ),
        body: child,
      ),
    );
  }
}

class _HomePrototypeBody extends StatelessWidget {
  const _HomePrototypeBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
      children: const [
        _GreetingHero(),
        SizedBox(height: 18),
        _SectionTitle(title: '現在需要處理', trailing: '3 件'),
        SizedBox(height: 10),
        _AttentionCard(
          icon: Icons.water_damage_outlined,
          eyebrow: '突發事項｜進行中',
          title: '浴室牆面持續滲水',
          detail: '已聯絡師傅，等待週三到場檢查',
          meta: '最後更新：今天 09:40',
          accent: Color(0xFFB86B4B),
        ),
        SizedBox(height: 12),
        _AttentionCard(
          icon: Icons.event_available_outlined,
          eyebrow: '今日提醒',
          title: '確認汽車保險續約內容',
          detail: '比較保費、保障範圍與道路救援',
          meta: '今天',
          accent: Color(0xFF567B70),
        ),
        SizedBox(height: 20),
        _SectionTitle(title: '進行中的案件', trailing: '查看全部'),
        SizedBox(height: 10),
        _CaseTimelineCard(),
        SizedBox(height: 20),
        _SectionTitle(title: '階段性重點與大修', trailing: '2 項'),
        SizedBox(height: 10),
        _MilestoneCard(),
        SizedBox(height: 20),
        _SectionTitle(title: '最近完成', trailing: '史略'),
        SizedBox(height: 10),
        _RecentHistoryCard(),
      ],
    );
  }
}

class _GreetingHero extends StatelessWidget {
  const _GreetingHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF365E55), Color(0xFF64877C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '今天的生活狀態',
            style: TextStyle(color: Color(0xFFDDEBE5), fontSize: 15),
          ),
          SizedBox(height: 8),
          Text(
            '有 2 件需要留意，\n1 件正在等待處理。',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              height: 1.25,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroPill(icon: Icons.today_outlined, label: '今日 1'),
              _HeroPill(icon: Icons.build_outlined, label: '案件 1'),
              _HeroPill(icon: Icons.flag_outlined, label: '重點 2'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF243B36),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          trailing,
          style: const TextStyle(
            color: Color(0xFF6E7F79),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.detail,
    required this.meta,
    required this.accent,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String detail;
  final String meta;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3DED3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF263A35),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  detail,
                  style: const TextStyle(
                    color: Color(0xFF596963),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  meta,
                  style: const TextStyle(
                    color: Color(0xFF87928E),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CaseTimelineCard extends StatelessWidget {
  const _CaseTimelineCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF2F4742),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('冷氣異音檢查', style: _darkCardTitleStyle),
          SizedBox(height: 5),
          Text('客廳冷氣｜等待零件', style: _darkCardMetaStyle),
          SizedBox(height: 18),
          _TimelineRow(done: true, label: '已完成到府檢查'),
          _TimelineRow(done: true, label: '確認風扇馬達異常'),
          _TimelineRow(done: false, label: '等待零件到貨與更換'),
        ],
      ),
    );
  }
}

const _darkCardTitleStyle = TextStyle(
  color: Colors.white,
  fontSize: 19,
  fontWeight: FontWeight.w800,
);
const _darkCardMetaStyle = TextStyle(color: Color(0xFFCAD9D4));

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.done, required this.label});

  final bool done;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: done ? const Color(0xFFB8D9CC) : const Color(0xFFE9C187),
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE7E1D2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        children: [
          Icon(Icons.flag_outlined, color: Color(0xFF755D38), size: 34),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '機車第六年全面檢查',
                  style: TextStyle(
                    color: Color(0xFF453A27),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  '預計 2027 年 3 月進場，尚有 8 個月',
                  style: TextStyle(color: Color(0xFF6E624B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentHistoryCard extends StatelessWidget {
  const _RecentHistoryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3DED3)),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            backgroundColor: Color(0xFFDDE9E3),
            foregroundColor: Color(0xFF3F685D),
            child: Icon(Icons.check_rounded),
          ),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '飲水機濾芯已更換',
                  style: TextStyle(
                    color: Color(0xFF263A35),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text('昨天｜費用 1,250 元', style: TextStyle(color: Color(0xFF71807B))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemDetailPrototypeBody extends StatelessWidget {
  const _ItemDetailPrototypeBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
      children: const [
        _ItemIdentityCard(),
        SizedBox(height: 16),
        _SectionTitle(title: '需要注意', trailing: '2 項'),
        SizedBox(height: 10),
        _AttentionStrip(),
        SizedBox(height: 20),
        _SectionTitle(title: '保養項目', trailing: '3 項'),
        SizedBox(height: 10),
        _PlanCard(),
        SizedBox(height: 20),
        _SectionTitle(title: '提醒與排程', trailing: '固定週期'),
        SizedBox(height: 10),
        _ScheduleCard(),
        SizedBox(height: 20),
        _SectionTitle(title: '階段性重點與大修', trailing: '1 項'),
        SizedBox(height: 10),
        _MilestoneCard(),
        SizedBox(height: 20),
        _SectionTitle(title: '進行中案件', trailing: '1 件'),
        SizedBox(height: 10),
        _CaseTimelineCard(),
        SizedBox(height: 20),
        _SectionTitle(title: '史略', trailing: '最近 3 筆'),
        SizedBox(height: 10),
        _HistoryTimeline(),
        SizedBox(height: 20),
        _BasicInfoCard(),
      ],
    );
  }
}

class _ItemIdentityCard extends StatelessWidget {
  const _ItemIdentityCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF395E55),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xFFD9E8E2),
            foregroundColor: Color(0xFF355D53),
            child: Icon(Icons.two_wheeler_outlined, size: 30),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('我的機車', style: _darkCardTitleStyle),
                SizedBox(height: 5),
                Text('車輛與交通｜正常管理中', style: _darkCardMetaStyle),
                SizedBox(height: 9),
                Text('目前里程 18,420 km', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttentionStrip extends StatelessWidget {
  const _AttentionStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEDB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6C9A6)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '下週需更換機油',
            style: TextStyle(color: Color(0xFF704B28), fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 5),
          Text('另有第六年全面檢查正在規劃中', style: TextStyle(color: Color(0xFF7F6348))),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _lightCardDecoration,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PlanRow(icon: Icons.oil_barrel_outlined, title: '機油更換', meta: '每 1,000 公里'),
          Divider(height: 28),
          _PlanRow(icon: Icons.tire_repair_outlined, title: '輪胎與胎壓檢查', meta: '每月'),
          Divider(height: 28),
          _PlanRow(icon: Icons.battery_charging_full_outlined, title: '電瓶狀態確認', meta: '每半年'),
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.icon, required this.title, required this.meta});

  final IconData icon;
  final String title;
  final String meta;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF4F756B)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        Text(meta, style: const TextStyle(color: Color(0xFF71807B))),
      ],
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _lightCardDecoration,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('機油更換', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          SizedBox(height: 8),
          Text('下次：2026/07/25', style: TextStyle(color: Color(0xFF4F625C))),
          SizedBox(height: 5),
          Text('固定里程基準，不因延遲完成而漂移', style: TextStyle(color: Color(0xFF7A8782))),
        ],
      ),
    );
  }
}

class _HistoryTimeline extends StatelessWidget {
  const _HistoryTimeline();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _lightCardDecoration,
      child: const Column(
        children: [
          _HistoryRow(date: '06/12', title: '更換前後輪胎', meta: '完修｜4,800 元'),
          Divider(height: 26),
          _HistoryRow(date: '04/03', title: '定期保養與機油更換', meta: '完成｜850 元'),
          Divider(height: 26),
          _HistoryRow(date: '01/18', title: '電瓶檢測', meta: '正常｜0 元'),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.date, required this.title, required this.meta});

  final String date;
  final String title;
  final String meta;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 48,
          child: Text(date, style: const TextStyle(color: Color(0xFF72817C))),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(meta, style: const TextStyle(color: Color(0xFF72817C))),
            ],
          ),
        ),
      ],
    );
  }
}

class _BasicInfoCard extends StatelessWidget {
  const _BasicInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _lightCardDecoration,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('基本資料', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          SizedBox(height: 13),
          Text('購入日期　2021/03/16'),
          SizedBox(height: 8),
          Text('停放位置　住家一樓'),
          SizedBox(height: 8),
          Text('備註　　　原廠保養手冊放在車廂'),
        ],
      ),
    );
  }
}

final BoxDecoration _lightCardDecoration = BoxDecoration(
  color: const Color(0xFFFFFCF6),
  borderRadius: BorderRadius.circular(22),
  border: Border.all(color: const Color(0xFFE3DED3)),
);
