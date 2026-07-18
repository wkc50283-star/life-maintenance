import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/models/enums.dart';
import 'package:life_maintenance/models/maintenance_plan.dart';
import 'package:life_maintenance/models/maintenance_plan_enums.dart';
import 'package:life_maintenance/models/maintenance_plan_step.dart';

void main() {
  group('MaintenancePlan', () {
    test('round trips a template-based plan with immutable ordered steps', () {
      final createdAt = DateTime(2026, 7, 18, 8);
      final updatedAt = DateTime(2026, 7, 18, 9);
      final plan = MaintenancePlan(
        id: 'plan-1',
        itemId: 'item-aircon',
        templateCardId: 'card-aircon-filter-cleaning',
        title: '客廳冷氣濾網清洗',
        planType: MaintenancePlanType.cleaning,
        description: '定期清洗客廳冷氣濾網',
        riskLevel: RiskLevel.low,
        estimatedMinutes: 20,
        requiredPhotos: true,
        requiredNote: false,
        safetyNotice: '清潔前先關閉電源。',
        createdAt: createdAt,
        updatedAt: updatedAt,
        steps: const [
          MaintenancePlanStep(
            id: 'step-2',
            order: 2,
            title: '清洗並晾乾',
            description: '以清水沖洗，完全晾乾後裝回。',
          ),
          MaintenancePlanStep(
            id: 'step-1',
            order: 1,
            title: '關閉電源',
            description: '清潔前先關閉冷氣電源。',
            photoRequired: true,
          ),
        ],
      );

      final decoded = MaintenancePlan.fromJson(plan.toJson());

      expect(decoded.schemaVersion, MaintenancePlan.currentSchemaVersion);
      expect(decoded.id, 'plan-1');
      expect(decoded.itemId, 'item-aircon');
      expect(decoded.templateCardId, 'card-aircon-filter-cleaning');
      expect(decoded.planType, MaintenancePlanType.cleaning);
      expect(decoded.riskLevel, RiskLevel.low);
      expect(decoded.estimatedMinutes, 20);
      expect(decoded.requiredPhotos, isTrue);
      expect(decoded.createdAt, createdAt);
      expect(decoded.updatedAt, updatedAt);
      expect(decoded.steps.map((step) => step.id), ['step-1', 'step-2']);
      expect(
        () => decoded.steps.add(
          const MaintenancePlanStep(
            id: 'step-3',
            order: 3,
            title: '不應新增',
            description: '',
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('manual plans do not require a template source', () {
      final now = DateTime(2026, 7, 18);
      final plan = MaintenancePlan(
        id: 'plan-manual',
        itemId: 'item-house',
        title: '每半年檢查陽台排水',
        planType: MaintenancePlanType.inspection,
        riskLevel: RiskLevel.low,
        createdAt: now,
        updatedAt: now,
      );

      expect(plan.templateCardId, isNull);
      expect(plan.isActive, isTrue);
      expect(plan.isArchived, isFalse);
    });

    test('unknown enum values and missing fields use safe defaults', () {
      final createdAt = DateTime(2026, 7, 18, 10);
      final decoded = MaintenancePlan.fromJson({
        'id': 'plan-future',
        'itemId': 'item-1',
        'title': '未知格式保養項目',
        'planType': 'futurePlanType',
        'riskLevel': 'futureRisk',
        'status': 'futureStatus',
        'estimatedMinutes': 0,
        'createdAt': createdAt.toIso8601String(),
      });

      expect(decoded.schemaVersion, MaintenancePlan.currentSchemaVersion);
      expect(decoded.planType, MaintenancePlanType.custom);
      expect(decoded.riskLevel, RiskLevel.unknown);
      expect(decoded.status, MaintenancePlanStatus.active);
      expect(decoded.estimatedMinutes, isNull);
      expect(decoded.updatedAt, createdAt);
      expect(decoded.steps, isEmpty);
    });

    test('one malformed step does not destroy the whole plan', () {
      final decoded = MaintenancePlan.fromJson({
        'id': 'plan-partial',
        'itemId': 'item-1',
        'title': '部分可讀保養項目',
        'planType': 'inspection',
        'riskLevel': 'low',
        'status': 'active',
        'createdAt': '2026-07-18T11:00:00.000',
        'steps': [
          {
            'id': 'good-step',
            'order': 1,
            'title': '可讀步驟',
            'description': '保留這一筆',
          },
          {
            'id': 'bad-step',
            'order': 'not-a-number',
            'title': '壞步驟',
          },
        ],
      });

      expect(decoded.steps, hasLength(1));
      expect(decoded.steps.single.id, 'good-step');
    });

    test('archived plans preserve archivedAt and status', () {
      final now = DateTime(2026, 7, 18);
      final archivedAt = DateTime(2026, 8, 1);
      final plan = MaintenancePlan(
        id: 'plan-archived',
        itemId: 'item-old',
        title: '已停止的保養項目',
        planType: MaintenancePlanType.custom,
        riskLevel: RiskLevel.unknown,
        status: MaintenancePlanStatus.archived,
        createdAt: now,
        updatedAt: archivedAt,
        archivedAt: archivedAt,
      );

      final decoded = MaintenancePlan.fromJson(plan.toJson());

      expect(decoded.isArchived, isTrue);
      expect(decoded.isActive, isFalse);
      expect(decoded.archivedAt, archivedAt);
    });

    test('copyWith supports explicit nullable field clearing', () {
      final now = DateTime(2026, 7, 18);
      final plan = MaintenancePlan(
        id: 'plan-copy',
        itemId: 'item-1',
        templateCardId: 'template-1',
        title: '原保養項目',
        planType: MaintenancePlanType.routineService,
        description: '原說明',
        riskLevel: RiskLevel.medium,
        estimatedMinutes: 60,
        safetyNotice: '原安全提示',
        createdAt: now,
        updatedAt: now,
      );

      final cleared = plan.copyWith(
        templateCardId: null,
        description: null,
        estimatedMinutes: null,
        safetyNotice: null,
        archivedAt: null,
      );

      expect(cleared.templateCardId, isNull);
      expect(cleared.description, isNull);
      expect(cleared.estimatedMinutes, isNull);
      expect(cleared.safetyNotice, isNull);
      expect(cleared.archivedAt, isNull);
    });
  });
}
