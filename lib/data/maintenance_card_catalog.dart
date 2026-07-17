import '../models/enums.dart';
import '../models/maintenance_card.dart';

class MaintenanceCardCatalog {
  const MaintenanceCardCatalog._();

  static final List<MaintenanceCard> _templates = [
    MaintenanceCard(
      id: 'card-aircon-filter-cleaning',
      itemId: '',
      title: '冷氣濾網清洗',
      type: MaintenanceType.cleaning,
      riskLevel: RiskLevel.low,
      cycleType: CycleType.monthly,
      estimatedMinutes: 20,
      requiredPhotos: true,
      requiredNote: false,
      createdAt: DateTime(2026, 7, 3),
      steps: const [
        MaintenanceStep(
          id: 'step-aircon-1',
          cardId: 'card-aircon-filter-cleaning',
          order: 1,
          title: '關閉電源',
          description: '清潔前先關閉冷氣電源。',
          isRequired: true,
        ),
        MaintenanceStep(
          id: 'step-aircon-2',
          cardId: 'card-aircon-filter-cleaning',
          order: 2,
          title: '取出濾網',
          description: '打開面板後取出濾網。',
          isRequired: true,
          photoRequired: true,
        ),
        MaintenanceStep(
          id: 'step-aircon-3',
          cardId: 'card-aircon-filter-cleaning',
          order: 3,
          title: '清洗並晾乾',
          description: '以清水沖洗濾網，完全晾乾後裝回。',
          isRequired: true,
        ),
      ],
    ),
    MaintenanceCard(
      id: 'card-scooter-tire-pressure',
      itemId: '',
      title: '機車胎壓檢查',
      type: MaintenanceType.inspection,
      riskLevel: RiskLevel.low,
      cycleType: CycleType.weekly,
      estimatedMinutes: 5,
      requiredPhotos: false,
      requiredNote: false,
      createdAt: DateTime(2026, 7, 3),
      steps: const [
        MaintenanceStep(
          id: 'step-scooter-pressure-1',
          cardId: 'card-scooter-tire-pressure',
          order: 1,
          title: '確認前後輪胎壓',
          description: '使用胎壓計確認前後輪胎壓是否在建議範圍。',
          isRequired: true,
        ),
        MaintenanceStep(
          id: 'step-scooter-pressure-2',
          cardId: 'card-scooter-tire-pressure',
          order: 2,
          title: '查看輪胎外觀',
          description: '檢查是否有明顯異物、裂痕或異常磨耗。',
          isRequired: true,
        ),
      ],
    ),
    MaintenanceCard(
      id: 'card-rental-contract-expiry',
      itemId: '',
      title: '租屋合約到期提醒',
      type: MaintenanceType.expiryReminder,
      riskLevel: RiskLevel.low,
      cycleType: CycleType.yearly,
      estimatedMinutes: 10,
      requiredPhotos: false,
      requiredNote: true,
      createdAt: DateTime(2026, 7, 3),
      steps: const [
        MaintenanceStep(
          id: 'step-contract-1',
          cardId: 'card-rental-contract-expiry',
          order: 1,
          title: '確認合約到期日',
          description: '檢查租屋合約日期與續約需求。',
          isRequired: true,
          noteRequired: true,
        ),
        MaintenanceStep(
          id: 'step-contract-2',
          cardId: 'card-rental-contract-expiry',
          order: 2,
          title: '確認續約或搬遷安排',
          description: '記錄是否續約、通知房東或安排搬遷。',
          isRequired: true,
          noteRequired: true,
        ),
      ],
    ),
    MaintenanceCard(
      id: 'card-scooter-brake-unknown',
      itemId: '',
      title: '機車煞車異音紀錄',
      type: MaintenanceType.repairRecord,
      riskLevel: RiskLevel.unknown,
      cycleType: CycleType.custom,
      estimatedMinutes: 5,
      requiredPhotos: true,
      requiredNote: true,
      safetyNotice: '煞車屬高風險項目，App 僅協助紀錄問題，請尋求合格專業人員檢查。',
      createdAt: DateTime(2026, 7, 3),
      steps: const [],
    ),
  ];

  static MaintenanceCard? resolve({
    required String cardId,
    required String itemId,
  }) {
    for (final template in _templates) {
      if (template.id == cardId) {
        return template.copyWith(itemId: itemId);
      }
    }

    return null;
  }
}
